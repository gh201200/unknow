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

local last_update_time = nil
local room_id = 0

--dt is ms
local function updateMapEvent()
	local nt = skynet.now()
	EntityManager:update( (nt - last_update_time) * 10)
	SpawnNpcManager:update( (nt - last_update_time) * 10)
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
	CMD.query_event_CastSkill = query_event_func
	CMD.query_event_affect = query_event_func
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

function CMD.move(response, agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	args.x = args.x / GAMEPLAY_PERCENT
	args.z = args.z / GAMEPLAY_PERCENT
	player:setTargetPos(args)
	response(true, nil)
end

function CMD.requestCastSkill(response,agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	local err = player:setCastSkillId(args.skillid)
	response(true, { errorcode =  err })
end

function CMD.lockTarget(response,agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	local serverid = args.serverid
	local target = EntityManager:getEntity(serverid)
	if player.ReadySkillId == 0 then
		--默认设置普攻
		player.ReadySkillId = 30001
	end
	player:setTarget(target)
	local err = 0
	response(true, { errorcode =  err })
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
	response(true, {errorCode = errorCode, sid = args.sid})
end

function CMD.upgradeSkill(response, agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	local errorCode, lv = player:upgradeSkill(args.skillId)
	response(true, {errorCode = errorCode, skillId = args.skillId, level = lv})
end

function CMD.start(response, args)
	response(true, nil)
	
	local roomId = 1
	local mapDat = g_shareData.mapRepository[roomId]

	room_id = roomId

	--加载地图
	Map:load("./lualib/map/" .. mapDat.szScene)

	--创建基地
	local redBuilding = IBuilding.create(0, mapDat)
	EntityManager:addEntity(redBuilding)
	local blueBuilding = IBuilding.create(1, mapDat)
	EntityManager:addEntity(blueBuilding)
	
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


skynet.start(function ()
	init()
	skynet.dispatch("lua", function (_, _, command, ...)
		local f = CMD[command]
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

