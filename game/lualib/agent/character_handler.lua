local skynet = require "skynet"
local syslog = require "syslog"
local handler = require "agent.handler"
local CardsMethod = require "agent.cards_method"
local AccountMethod = require "agent.account_method"
local ExploreMethod = require "agent.explore_method"
local REQUEST = {}
handler = handler.new (REQUEST)

local user
local database

handler:init (function (u)
	user = u
end)

function REQUEST.enterGame(args)
	database = skynet.uniqueservice ("database")
	local account_id = args.account_id
	user.account = skynet.call(database, "lua", "account_rd", "load", account_id)	
	setmetatable(user.account, {__index = AccountMethod})
	user.cards =  skynet.call (database, "lua", "cards_rd", "load",account_id) --玩家拥有的卡牌
	setmetatable(user.cards, {__index = CardsMethod})
	user.explore = skynet.call (database, "lua", "explore_rd", "load", account_id) --explore
	setmetatable(user.explore, {__index = ExploreMethod})
end

function REQUEST.character_list ()
	local character = create_character ()
	return { character = character }
end



function REQUEST.heart_beat_time()
	return {}
end

----------------explore----------------------
local function begin_explore()
	user.explore.time = os.time()
	skynet.timeout(Quest.Explore.CD*100, explore_timeout)
end


local function explore_timeout()
	local gains = Quest.Explore.gains_num
	local stillHas = false
	for i=0, 4 do 
		if string.len(user.explore["slot"..i]) > 1 then
			stillHas = true
			local card = user.cards:getCardByUuid(user.explore["slot"..i])
			
			user.cards:addPower(user.explore["slot"..i], -Quest.Explore.CD)
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
		--the rule of 3 minites
		local dt = user.explore.time > 0 and nowTime - user.explore.time or 0
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
	if user.explore.time == 0 then
		begin_explore()
	end
	if string.len(user.explore["slot"..args.index]) > 1 then
		user.cards:addPower(user.explore["slot"..args.index], -(nowTime-user.explore.time))
	end
	user.explore["slot"..args.index] = args.uuid


function REQUEST.heart_beat_time()
	return {}
end


return handler

