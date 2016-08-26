local skynet = require "skynet"
local snax = require "snax"
local syslog = require "syslog"
local vector3 = require "vector3"
local syslog = require "syslog"
local EntityManager = require "entity.EntityManager"
local EventStampHandle = require "entity.EventStampHandle"
local SpawnNpcManager = require "entity.SpawnNpcManager"
local sharedata = require "sharedata"
local traceback  = debug.traceback

local last_update_time = nil


--dt is ms
local function updateMapEvent()
	local nt = skynet.now()
	EntityManager:update( (nt - last_update_time) * 10)
	SpawnNpcManager:update( (nt - last_update_time) * 10)
	last_update_time = nt
	skynet.timeout(2, updateMapEvent)
end

local function query_event_func(response,agent, account_id, args)
	local entity = EntityManager:getEntity( args.event_stamp.id )
	if not entity then
		syslog.warningf("client[%s] query_event server obj[%d] is null, type[%d]", platyerId, args.event_stamp.id, args.event_stamp.type)
	end
	EventStampHandle.createHandleCoroutine(args.event_stamp.id, args.event_stamp.type, response)
	entity:checkeventStamp(args.event_stamp.type, args.event_stamp.stamp)
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

function CMD.entity_enter(response,agent,arg)
	print('entity_enter: ',arg)
	local p = EntityManager:createPlayer(agent,arg)
	response(true, nil)
end


function CMD.move(response, agent, account_id, args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	player:setTargetPos(args.target)
	response(true, nil)
end

function CMD.castskill(response,agent, account_id, args)
	print("CMD.castskill",args.skillid)	
	local player = EntityManager:getPlayerByPlayerId(account_id)
	local err = player:setCastSkillId(args.skillid)
	response(true, { errorcode =  err })
end

function CMD.lockTarget(response,agent, account_id, args)
	print("CMD.lockTarget",args)
	local player = EntityManager:getPlayerByPlayerId(account_id)
	local serverid = args.serverid
	local target = EntityManager:getEntity(serverid)
	if target ~= nil then 
		print("target is not nil")
		print(target.pos.x)	
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

local function init()
	--every 0.03s update entity
	skynet.timeout(3, updateMapEvent)
	last_update_time = skynet.now()
	register_query_event_func()
	g_shareData  = sharedata.query "gdd"
	SpawnNpcManager:init(1)
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

