local skynet = require "skynet"
local queue = require "skynet.queue"
local sharemap = require "sharemap"
local snax = require "snax"
local socket = require "socket"


local syslog = require "syslog"
local protoloader = require "proto.protoloader"
local character_handler = require "agent.character_handler"

local IAgentplayer = require "entity.IAgentPlayer"

local hijack_msg = {}

--local map = tonumber (...)

local host, proto_request = protoloader.load (protoloader.GAME)

--[[
.user = { 
		fd = conf.client, 
		agentPlayer = Iplayer,
		REQUEST = {},
		RESPONSE = {},
		CMD = CMD,
		send_request = send_request,
	}
]]

local user

function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socket.write (fd, package)
end

local user_fd
local session = {}
local session_id = 0
local function send_request (name, args)
	session_id = session_id + 1
	local str = proto_request (name, args, session_id)
	send_msg (user_fd, str)
	session[session_id] = { name = name, args = args }
end

local function kick_self ()
	skynet.call (gamed, "lua", "kick", skynet.self (), user_fd)
end

local last_heartbeat_time
local HEARTBEAT_TIME_MAX = 0 -- 60 * 100
local function heartbeat_check ()
	if HEARTBEAT_TIME_MAX <= 0 or not user_fd then return end

	local t = last_heartbeat_time + HEARTBEAT_TIME_MAX - skynet.now ()
	if t <= 0 then
		syslog.warning ("heatbeat check failed")
		kick_self ()
	else
		skynet.timeout (t, heartbeat_check)
	end
end

local traceback = debug.traceback
local REQUEST
local function handle_request (name, args, response)
	if hijack_msg[name] then
		if response then
			local ret = hijack_msg[name].req[name](user.agentPlayer.playerId, args)
			if ret then
				send_msg (user_fd, response (ret))
			end
		else
			hijack_msg[name].post[name](user.agentPlayer.playerId, args)
		end
		return
	end

	local f = REQUEST[name]
	if f then
		local ok, ret = xpcall (f, traceback, args)
		if not ok then
			syslog.warningf ("handle message(%s) failed : %s", name, ret) 
			kick_self ()
		else
			last_heartbeat_time = skynet.now ()
			if response and ret then
				send_msg (user_fd, response (ret))
			end
		end
	else
		syslog.warningf ("unhandled message : %s", name)
		kick_self ()
	end
end

local RESPONSE
local function handle_response (id, args)
	local s = session[id]
	if not s then
		syslog.warningf ("session %d not found", id)
		kick_self ()
		return
	end

	local f = RESPONSE[s.name]
	if not f then
		syslog.warningf ("unhandled response : %s", s.name)
		kick_self ()
		return
	end

	local ok, ret = xpcall (f, traceback, s.args, args)
	if not ok then
		syslog.warningf ("handle response(%d-%s) failed : %s", id, s.name, ret) 
		kick_self ()
	end
end

local function request_hijack_msg(handle, name)
	local interface = snax.interface(name)
	for k, v in pairs(interface.accept) do
		hijack_msg[k] = handle
	end
	for k, v in pairs(interface.response) do
		assert(hijack_msg[k]==nil)
		hijack_msg[k] = handle
	end
end

local function request_release_msg(handle, name)
	local interface = snax.interface(name)
	for k, v in pairs(interface.accept) do
		hijack_msg[k] = nil
	end
	for k, v in pairs(interface.response) do
		hijack_msg[k] = nil
	end
end


skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch (msg, sz)
	end,
	dispatch = function (_, _, type, ...)
		if type == "REQUEST" then
			handle_request (...)
		elseif type == "RESPONSE" then
			handle_response (...)
		else
			syslog.warningf ("invalid message type : %s", type) 
			kick_self ()
		end
	end,
}

local CMD = {}

function CMD.Start (conf)
	local map = snax.newservice("map")
	request_hijack_msg(map, "map")
	
	--map.req.join(conf.client)

	syslog.debug ("agent Start")
	local gate = conf.gate

	user = { 
		fd = conf.client, 
		agentPlayer = IAgentplayer.create(),
		REQUEST = {},
		RESPONSE = {},
		CMD = CMD,
		MAP = map,
		send_request = send_request,
	}
	user_fd = user.fd
	REQUEST = user.REQUEST
	RESPONSE = user.RESPONSE

	--user.entity:init()

	character_handler:register (user)

	skynet.call(gate, "lua", "forward", user_fd)

	--last_heartbeat_time = skynet.now ()
	--heartbeat_check ()
end

function CMD.disconnect ()
	syslog.debug ("agent closed")
	
	if user then
		character_handler:unregister (user)
		request_release_msg(user.MAP, "map")
		user = nil
		user_fd = nil
		REQUEST = nil
	end
	
	--skynet.call (gamed, "lua", "close", skynet.self (), account)

end


skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local f = CMD[command]
		if not f then
			syslog.warningf ("unhandled message(%s)", command) 
			return skynet.ret ()
		end

		local ok, ret = xpcall (f, traceback, ...)
		if not ok then
			syslog.warningf ("handle message(%s) failed : %s", command, ret) 
			kick_self ()
			return skynet.ret ()
		end
		skynet.retpack (ret)
		--skynet.ret(skynet.pack(ret))
	end)
end)

