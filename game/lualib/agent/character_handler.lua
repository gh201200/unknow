local skynet = require "skynet"
local snax = require "snax"
local syslog = require "syslog"
local handler = require "agent.handler"
local CardsMethod = require "agent.cards_method"
local AccountMethod = require "agent.account_method"
local ExploreMethod = require "agent.explore_method"
local SkillsMethod = require "agent.skills_method"
local MissionsMethod = require "agent.missions_method"
local MailsMethod = require "agent.mails_method"
local ExploreCharacter = require "agent.expand.explore_ch"
local SystemCharacter = require "agent.expand.system_ch"
local MissionCharacter = require "agent.expand.mission_ch"
local GM = require "agent.expand.gm_ch"

local REQUEST = {}
handler = handler.new (REQUEST)
handler:add( ExploreCharacter )		--探索系统
handler:add( SystemCharacter )		--子系统功能[卡牌升级，商城购买，]
handler:add( MissionCharacter )		--任务系统
handler:add( GM )			--GM功能接口

local user
local database

local function getAccountLevel( _exp )
	for k, v in pairs( Quest.Arena ) do
		if v.EloLimit > _exp then
			return k - 1
		end
	end
	return #Quest.Arena
end

handler:init (function (u)
	user = u
	ExploreCharacter:init( user )
	SystemCharacter:init( user )
	MissionCharacter:init( user )
	GM:init( user )
end)

AccountMethod.sendAccountData = function(self)
	user.send_request("sendAccount", user.account.unit)
end;

AccountMethod.onExp = function(self)
	local lv = getAccountLevel( self.unit.exp )
	if user.level ~= lv then
		local cd = snax.queryservice 'cddown'
		for k, v in pairs(g_shareData.shopRepository) do
			if v.n32Type == 5 then
				if v.n32ArenaLvUpLimit == lv then
					cd.post.setValue( user.account.account_id, CoolDownAccountType.TimeLimitSale, os.time() + v.n32Limit) 
					break
				end
			end
		end
		user.level = lv
	end
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


local function onDataLoadCompleted()
	--计算竞技场等级
	user.level = getAccountLevel( user.account:getExp() )
	--判断每日任务重置
	user.missions:getDailyMission()
	--新的成就
	local num = user.missions:getAchivementsNum()
	if num < (Quest.AchivementsId[2] - Quest.AchivementsId[1])/1000 + 1 then
		for i=Quest.AchivementsId[1], Quest.AchivementsId[2] do
			local serId = Macro_GetMissionSerialId( i )
			local unit = user.missions:getMissionBySerialId( serId )
			if not unit then
				user.missions:addMission("onDataLoadCompleted", i)	
			end 
		end
	end
end

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

	user.account:refreshTimes()
	user.account:sendAccountData()
	user.cards:sendCardData()
	user.explore:sendExploreData()
	user.skills:sendSkillData()
	user.missions:sendMissionData()
	user.mails:sendMailData()

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
	--r.isin = false
	user.send_request('reEnterRoom', r)
end

local function loadAccountData()
	--玩家数据加载
	local account_id = user.account.account_id 
	user.account.unit = skynet.call(database, "lua", "account", "load", account_id)	
	setmetatable(user.account, {__index = AccountMethod})
	local dbVersion = calcVersionCode( user.account:getVersion() )
	local nowVersion = calcVersionCode( NOW_SERVER_VERSION )
	print('version code = ', dbVersion, nowVersion)
	if dbVersion < nowVersion then	--处理版本升级数据一致性问题
	
	end

	user.cards = { account_id = account_id }
	user.cards.units =  skynet.call (database, "lua", "cards", "load",account_id) --玩家拥有的卡牌
	setmetatable(user.cards, {__index = CardsMethod})

	user.skills = { account_id = account_id }
	user.skills.units =  skynet.call (database, "lua", "skills", "load",account_id) --玩家拥有的技能
	setmetatable(user.skills, {__index = SkillsMethod})

	user.missions = { account_id = account_id }
	user.missions.units =  skynet.call (database, "lua", "missions", "load",account_id) --玩家拥有的任务
	setmetatable(user.missions, {__index = MissionsMethod})

	user.explore = { account_id = account_id }
	user.explore.units = skynet.call (database, "lua", "explores", "load", account_id) --explore
	setmetatable(user.explore, {__index = ExploreMethod})

	user.mails = { account_id = account_id }
	user.mails.units =  skynet.call (database, "lua", "mails", "load", account_id) --玩家拥有的邮件
	setmetatable(user.mails, {__index = MailsMethod})

	local activity = snax.queryservice 'activity'
	activity.post.loadAccount( account_id )
	local cooldown = snax.queryservice 'cddown'
	cooldown.post.loadAccount( account_id )
	
	onDataLoadCompleted()

end

function REQUEST.enterGame(args)
	if not database then
		database = skynet.uniqueservice ("database")
		loadAccountData()
		onDataLoadCompleted()
	end
	if user.isAi == false then
		onEnterGame()
	end
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

function REQUEST.requestFightRecords()
	local str = skynet.call(database, "lua", "fightrecords", "load",user.account.account_id)	
	return {records = str}
end


return handler

