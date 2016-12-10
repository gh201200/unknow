local skynet = require "skynet"
local snax = require "snax"
local syslog = require "syslog"
local handler = require "agent.handler"
local CardsMethod = require "agent.cards_method"
local AccountMethod = require "agent.account_method"
local ExploreMethod = require "agent.explore_method"
local SkillsMethod = require "agent.skills_method"
local ExploreCharacter = require "agent.expand.explore_ch"
local SystemCharacter = require "agent.expand.system_ch"
local GM = require "agent.expand.gm_ch"
local Quest = require "quest.quest"

local REQUEST = {}
handler = handler.new (REQUEST)
handler:add( ExploreCharacter )		--探索系统
handler:add( SystemCharacter )		--子系统功能[卡牌升级，商城购买，]
handler:add( GM )			--GM功能接口

local user
local database

handler:init (function (u)
	user = u
	ExploreCharacter:init( user )
	SystemCharacter:init( user )
	GM:init( user )
end)

AccountMethod.sendAccountData = function(self)
	user.send_request("sendAccount", user.account.unit)
end;

CardsMethod.sendCardData = function(self, unit)
	if unit then
		local p = table.clone( unit )
		p.explore = p.explore - os.time()
		user.send_request("sendHero", {cardsList = {p}})
	else
		local cardsList = {}
		for k, v in pairs(user.cards.units) do
			local p = table.clone( v )
			p.explore = p.explore - os.time()
			table.insert( cardsList, p )
		end
		user.send_request("sendHero", {cardsList = cardsList})
	end
end;

SkillsMethod.sendSkillData = function(self, unit)
	if unit then
		user.send_request("sendSkill", {skillsList = {unit}})
	else
		user.send_request("sendSkill", {skillsList = user.skills.units})
	end
end;

ExploreMethod.sendExploreData = function(self)
	local explore = table.clone( user.explore.unit )
	if explore.time ~= 0 then
		explore.time = explore.time - os.time()
	end
	user.send_request("sendExplore", explore)
end;

local function sendCDTimeData(key)
	local cds = snax.queryservice "cddown"
	local nowTime = os.time()
	local r = { cds = {} }
	if key then
		local val = cds.req.getRemainingTime( key )
		table.insert(r.cds,  {key=key, val=val-nowTime} )
	else
		local datas = cds.req.getCDDatas()
		for k, v in pairs(datas) do
			table.insert(r.cds, {key=k, val=v-nowTime})
		end
	end
	user.send_request("sendCDTime", r)
end

local function sendActivityData( atype )
	local activity = snax.queryservice 'activity'
	local r = { activitys = {} }
	if atype then
		local unit = activity.req.getValue(user.account.account_id, atype)
		if unit then
			table.insert(r.activitys, unit)
		end
	else
		--系统活动
		r.activitys = activity.req.getAllSystem()
		--个人活动

	end
	if next(r.activitys) then
		user.send_request("sendActivity", r)
	end
end


local function onEnterGame()
	--tell watchdog
	skynet.call(user.watchdog, "lua", "userEnter", user.account.account_id, user.fd)

	user.account:sendAccountData()
	user.cards:sendCardData()
	user.explore:sendExploreData()
	user.skills:sendSkillData()

	--here, decide whether he is still in room 
	local sm = snax.uniqueservice("servermanager")
	local map = sm.req.getroomad( user.account.account_id )
	local r = {isin=false}
	if map then
		local offLinetime = skynet.call(map, "lua", "getOffLineTime", {id=user.account.account_id})
		if offLinetime < 90 then
			r.isin = true
		end
	end
	r.isin = false
	user.send_request('reEnterRoom', r)
end

function REQUEST.enterGame(args)
	
	database = skynet.uniqueservice ("database")

	--玩家数据加载
	local account_id = args.account_id
	user.account = { account_id = account_id }
	user.account.unit = skynet.call(database, "lua", "account", "load", account_id)	
	setmetatable(user.account, {__index = AccountMethod})
	user.cards = { account_id = account_id }
	user.cards.units =  skynet.call (database, "lua", "cards", "load",account_id) --玩家拥有的卡牌
	setmetatable(user.cards, {__index = CardsMethod})
	user.skills = { account_id = account_id }
	user.skills.units =  skynet.call (database, "lua", "skills", "load",account_id) --玩家拥有的技能
	setmetatable(user.skills, {__index = SkillsMethod})
	user.explore = { account_id = account_id }
	user.explore.unit = skynet.call (database, "lua", "explore", "load", account_id, ExploreCharacter.randcon()) --explore
	setmetatable(user.explore, {__index = ExploreMethod})
	local activity = snax.queryservice 'activity'
	activity.post.loadAccount( account_id )
	local cooldown = snax.queryservice 'cddown'
	cooldown.post.loadAccount( account_id )
	
	onEnterGame()
end

function REQUEST.character_list ()
	local character = create_character ()
	return { character = character }
end



function REQUEST.heart_beat_time()
	user.heartBeatTime = os.time()
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


return handler

