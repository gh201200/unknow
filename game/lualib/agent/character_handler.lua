local skynet = require "skynet"
local snax = require "snax"
local syslog = require "syslog"
local handler = require "agent.handler"
local CardsMethod = require "agent.cards_method"
local AccountMethod = require "agent.account_method"
local ExploreMethod = require "agent.explore_method"
local Quest = require "quest.quest"

local REQUEST = {}
handler = handler.new (REQUEST)

local user
local database

handler:init (function (u)
	user = u
end)

local function sendAccountData()
	user.send_request("sendAccount", user.account.unit)
end

local function sendHeroData()
	user.send_request("sendHero", {cardsList = user.cards.units})
end

local function sendExploreData()
	print(user.explore:getTime())
	local r = {
		time = Quest.Explore.CD - (os.time() - user.explore:getTime()),
		uuid0 = user.explore:getSlot(0),
		uuid1 = user.explore:getSlot(1),
		uuid2 = user.explore:getSlot(2),
		uuid3 = user.explore:getSlot(3),
		uuid4 = user.explore:getSlot(4),
	}
	user.send_request("sendExplore", r)
end

local function sendCDTimeData()
	local cds = snax.queryservice "cddown"
	local r = {
		ResetCardPowertime = cds.req.getRemainingTime("ResetCardPowertime") - os.time()
	}
	user.send_request("sendCDTime", r)
end


local function onEnterGame()
	
	sendAccountData()
	sendHeroData()
	sendExploreData()
	sendCDTimeData()
end

function REQUEST.enterGame(args)
	database = skynet.uniqueservice ("database")
	local account_id = args.account_id
	user.account = { account_id = account_id }
	user.account.unit = skynet.call(database, "lua", "account_rd", "load", account_id)	
	setmetatable(user.account, {__index = AccountMethod})
	user.cards = {}
	user.cards.units =  skynet.call (database, "lua", "cards_rd", "load",account_id) --玩家拥有的卡牌
	setmetatable(user.cards, {__index = CardsMethod})
	user.explore = {}
	user.explore.unit = skynet.call (database, "lua", "explore_rd", "load", account_id) --explore
	setmetatable(user.explore, {__index = ExploreMethod})

	onEnterGame()
end

function REQUEST.character_list ()
	local character = create_character ()
	return { character = character }
end



function REQUEST.heart_beat_time()
	return {}
end

function REQUEST.getCardsDatas()
	print("REQUEST.getCardsDatas")
	local  cardsList = {}
	local cardNum = 0
	print(user.cards)
	for _k,_v in pairs(user.cards) do
		if _v.uuid ~= nil then
			cardNum = cardNum + 1
			table.insert(cardsList,_v)
		end
	end	
	return {cardNum = cardNum ,cardsList = cardsList }
end
----------------explore----------------------
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

function REQUEST.heart_beat_time()
	return {}
end


return handler

