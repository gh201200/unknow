local skynet = require "skynet"
local snax = require "snax"
local syslog = require "syslog"
local handler = require "agent.handler"
local CardsMethod = require "agent.cards_method"
local AccountMethod = require "agent.account_method"
local ExploreMethod = require "agent.explore_method"
local ExploreCharacter = require "agent.expand.explore_ch"
local CardCharacter = require "agent.expand.card_ch"

local REQUEST = {}
handler = handler.new (REQUEST)
handler:add( ExploreCharacter )		--探索系统
handler:add( CardCharacter )		--英雄系统

local user
local database

handler:init (function (u)
	user = u
	ExploreCharacter:init( user )
	CardCharacter:init( user )
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
	
	--tell watchdog
	skynet.call(user.watchdog, "lua", "userEnter", user.account.account_id, user.fd)

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

function REQUEST.heart_beat_time()
	return {}
end


return handler

