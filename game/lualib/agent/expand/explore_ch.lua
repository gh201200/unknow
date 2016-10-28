local skynet = require "skynet"
local Quest = require "quest.quest"

local ExploreCh = class("ExploreCh")


local user
local REQUEST = {}

function ExploreCh:ctor()
	self.REQUEST = REQUEST
end

function ExploreCh:init( u )
	self.user = u
end

local function begin_explore()
	user.explore:setTime(os.time())
	skynet.timeout(Quest.Explore.CD*100, explore_timeout)
end


local function explore_timeout()
	local gains = Quest.Explore.gains_num
	local stillHas = false
	for i=0, 4 do 
		if string.len(user.explore:getSlot(i)) > 1 then
			stillHas = true
			local card = user.cards:getCardByUuid(user.explore:getSlot(i))
			
			user.cards:addPower(user.explore:getSlot(i), -Quest.Explore.CD)
			if card.power <= 0 then  
				user.explore:setSlot(i, "0")	
				stillHas = false
			end
			
			local dat = g_shareData.heroRepository[card.dataId]
			if dat.n32Color == CardColor.White then
				gains = gains + Quest.Explore.gains_num_wt
			elseif dat.n32Color == CardColor.Green then
				gains = gains + Quest.Explore.gains_num_gr
			elseif dat.n32Color == CardColor.Blue then
				gains = gains + Quest.Explore.gains_num_bl
			elseif dat.n32Color == CardColor.Purple then
				gains = gains + Quest.Explore.gains_num_pu
			elseif dat.n32Color == CardColor.Orange then
				gains = gains + Quest.Explore.gains_num_or
			end
		end
	end

	local allRates = {}
	local val = 0
	for k, v in pairs(Quest.Explore.gains_free) do
		allRates[v[1]] = val + v[2]*100
		val = allRates[v[1]]
	end
		
	for i=1, gains do
		local rd = math.random(1, val)
		for k, v in pairs(allRates) do
			if rd <= v then
				user.cards:addCard(k, 1)	
			end
		end
	end
	
	if stillHas then	--begin a new explore
		begin_explore()
	end
end

function REQUEST.explore_goFight(args)
	local nowTime = os.time()
	--check illegal
	local errorCode = 0
	repeat
		local card = user.cards:getCardByUuid(args.uuid)
		if not card then
			errorCode = -1
			break
		end
		if args.index < 0 or args.index > 4 then 
			errorCode = -1
			break
		end
		for i=0, 4 do
			if user.explore:getSlot(i) == args.uuid then
				errorCode = -1
				break
			end
		end
		if errorCode ~= 0 then break end

		--the rule of 3 minites
		local dt = user.explore:getTime() > 0 and nowTime - user.explore:getTime() or 0
		if dt > 180 then	
			errorCode = 1
			break
		end
		--has enough power
		if card.time < 0 then
			errorCode = 2
			break
		end 
	until true	
	if errorCode ~= 0 then
		return {errorCode = errorCode}
	end
	--ok
	if user.explore:getTime() == 0 then
		begin_explore()
	end
	if string.len(user.explore:getSlot(args.index)) > 1 then
		user.cards:addPower(user.explore:geSlot(args.index), -(nowTime-user.explore:getTime()))
	end
	user.explore:setSlot(args.index, args.uuid)
	
	return {errorCode = errorCode}
end


return ExploreCh.new()
