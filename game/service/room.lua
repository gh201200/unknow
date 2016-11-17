local skynet = require "skynet"
local snax = require "snax"
local syslog = require "syslog"
local vector3 = require "vector3"
local syslog = require "syslog"
local EntityManager = require "entity.EntityManager"
local IMapPlayer = require "entity.IMapPlayer"
local IBuilding = require "entity.IBuilding"
local EventStampHandle = require "entity.EventStampHandle"
local SpawnNpcManager = require "entity.SpawnNpcManager"
local sharedata = require "sharedata"
local Map = require "map.Map"
local DropManager = require "drop.DropManager"
local traceback  = debug.traceback
local BattleOverManager = require "entity.BattleOverManager"


local last_update_time = nil
local room_id = 0

--dt is ms
local function updateMapEvent()
	local nt = skynet.now()
	EntityManager:update( (nt - last_update_time) * 10 )
	SpawnNpcManager:update( (nt - last_update_time) * 10 )
	BattleOverManager:update( (nt - last_update_time) * 10 )
	DropManager:update()
	last_update_time = nt
	skynet.timeout(2, updateMapEvent)
end

local function query_event_func(response,agent, account_id, args)
	local entity = EntityManager:getEntity( args.id )
	if not entity then
		response(true, nil)
		return
	end
	EventStampHandle.createHandleCoroutine(args.id, args.type, response)
	entity:checkeventStamp(args.type, args.stamp)
end

local CMD = {}

local function register_query_event_func()
	CMD.query_event_move = query_event_func
	CMD.query_event_stats = query_event_func
	CMD.query_event_hp_mp = query_event_func
end

function CMD.hijack_msg(response,agent)
	local ret = {}
	for k, v in pairs(CMD) do
		if type(v) == "function" then
			table.insert(ret, k)
		end
	end
	response(true, ret )
end

function CMD.disconnect(s,agent)
	EntityManager:disconnectAgent(agent)	
end

function CMD.move(response, agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	args.x = args.x / GAMEPLAY_PERCENT
	args.z = args.z / GAMEPLAY_PERCENT
	if Map:isWall( args.x, args.z ) then
		Map:lineTest(player.pos, args)
	end
	player:setTargetPos(args)
	response(true, nil)
end

function CMD.requestCastSkill(response,agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	local skillId = args.skillid + player.skillTable[args.skillid] - 1
	local err = player:setCastSkillId(skillId)
	response(true, { errorcode =  err ,skillid = args.skillid })
end

function CMD.lockTarget(response,agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	local serverid = args.serverid
	local target = EntityManager:getEntity(serverid)
	if player.ReadySkillId == 0 then
		--默认设置普攻
		player.ReadySkillId = player:getCommonSkill()
	end
	player:setTarget(target)
	response(true, nil)
end

function CMD.query_server_id(response,agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	response( true, { server_id = player.serverId } )
	
	local ret = { server_id = player.serverId }
	for k, v in pairs(EntityManager.entityList) do
		if v.entityType == EntityType.player and  v.serverId ~= player.serverId then
			skynet.call(v.agent, "lua", "sendRequest", "enter_room", ret) 
		end
	end
end

function CMD.loadingRes(response, agent, account_id, args)
	response( true, nil )
	local player = EntityManager:getPlayerByPlayerId(account_id)
	player:setLoadProgress(args.percent)
	
	local num = 0
	for k, v in pairs(EntityManager.entityList) do
		if v.entityType == EntityType.player  then
			if v:getLoadProgress() >= 100 then
				num = num + 1
			end
		end
	end

	--all players load completed
	if num == #EntityManager.entityList-2 then
		EntityManager:sendToAllPlayers("fightBegin")

		--every 0.03s update entity
		skynet.timeout(3, updateMapEvent)
		last_update_time = skynet.now()
	
		SpawnNpcManager:init(room_id)

	end
end

function CMD.usePickItem(response, agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	local errorCode = DropManager:useItem(player, args.sid)
	response(true, {errorCode = errorCode, x1=args.x1,y1=args.y1,x2=args.x2,y2=args.y2})
end

function CMD.upgradeSkill(response, agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	local errorCode, lv = player:upgradeSkill(args.skillId)
	response(true, {errorCode = errorCode, skillId = args.skillId, level = lv})
end

function CMD.replaceSkill(response, agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	local errorCode, skillId = DropManager:replaceSkill(player, args.sid, args.skillId)
	if not skillId then skillId = 0 end
	response(true, {errorCode = errorCode,skillId = skillId, beSkillId = args.skillId})
end


function CMD.start(response, args)
	response(true, nil)
	
	local match = skynet.uniqueservice 'match'
	skynet.call(match, "lua", "roomstart", skynet.self(), args)
	
	local roomId = 1
	local mapDat = g_shareData.mapRepository[roomId]
	
	BattleOverManager:init( mapDat )
	
	room_id = roomId

	--加载地图
	Map:load("./lualib/map/" .. mapDat.szScene)

	--创建基地
	local redBuilding = IBuilding.create(CampType.RED, mapDat)
	EntityManager:addEntity(redBuilding)
	BattleOverManager.RedHomeBuilding = redBuilding
	local blueBuilding = IBuilding.create(CampType.BLUE, mapDat)
	EntityManager:addEntity(blueBuilding)
	BattleOverManager.BlueHomeBuilding = blueBuilding
	
	--创建英雄
	for k, v in pairs (args) do
		v.bornPos = mapDat['szBornPos'..v.color]
		local player = IMapPlayer.create(v)
		if player:isRed() then
			redBuilding:insertHero(player)
		else
			blueBuilding:insertHero(player)
		end
		EntityManager:addEntity(player)
	end
	
	local heros = {}
	for k, v in pairs(EntityManager.entityList) do
		if v.entityType == EntityType.player  then
			local LoadHero = {
				serverId = v.serverId,
				heroId = v.attDat.id,
				name = v.nickName,
				color = v.color
			}
			table.insert(heros, LoadHero)
		end
	end

	
	local ret = {
		roomId = roomId,
		heroInfoList = heros,
		rb_sid = redBuilding.serverId,
		bb_sid = blueBuilding.serverId,
	}
	for k, v in pairs(EntityManager.entityList) do
		if v.entityType == EntityType.player  then
			skynet.call(v.agent, "lua", "enterMap", skynet.self(), ret)
		end
	end
end


local function init()
	register_query_event_func()
	g_shareData  = sharedata.query "gdd"
end

--REQUEST 接受非网络消息服务调用
local REQUEST = {}

function REQUEST.addgold(response, args )
	response(true, nil)
	local player = EntityManager:getPlayerByPlayerId( args.id )
	player:addGold( args.gold )
end

function REQUEST.addexp(response, args )
	response(true, nil)
	local player = EntityManager:getPlayerByPlayerId( args.id )
	player:addExp( args.exp )
end

function REQUEST.addskill(response, args )
	response(true, nil)
	local player = EntityManager:getPlayerByPlayerId( args.id )
	player:addSkill( args.skillId, true )
end

function REQUEST.addOffLineTime(response, args)
	response(true, nil)
	local player = EntityManager:getPlayerByPlayerId( args.id )
	player:addOffLineTime( args.time )
end

function REQUEST.getOffLineTime(response, args)
	local player = EntityManager:getPlayerByPlayerId( args.id )
	local time = player:getOffLineTime()
	response(true, time)
end


skynet.start(function ()
	init()
	skynet.dispatch("lua", function (_, _, command, ...)
		local f = CMD[command]
		if not f then
			f = REQUEST[command]
		end
		if not f then
			syslog.warningf("map service unhandled message[%s]", command)	
			return skynet.ret()
		end
		local ok, ret = xpcall(f, traceback,  skynet.response(), ...)
		if not ok then
			syslog.warningf("map service handle message[%s] failed : %s", commond, ret)		
			return skynet.ret()
		end
	end)
end)

