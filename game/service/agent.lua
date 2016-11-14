local skynet = require "skynet"
local queue = require "skynet.queue"
local sharemap = require "sharemap"
local snax = require "snax"
local socket = require "socket"
local mc = require "multicast"
local dc = require "datacenter"
local sharedata = require "sharedata"

local syslog = require "syslog"
local protoloader = require "proto.protoloader"
local character_handler = require "agent.character_handler"

local IAgentplayer = require "entity.IAgentPlayer"

local hijack_msg = {}
local hijack_msg_event_stamp = {}

local database
local WATCHDOG

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
local user_fd
local session = {}
local session_id = 0

local function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socket.write (fd, package)
end


local function send_request (name, args)
	session_id = session_id + 1
	local str = proto_request (name, args, session_id)
	send_msg (user_fd, str)
	session[session_id] = { name = name, args = args }
end

local function kick_self ()
	skynet.call (WATCHDOG, "lua", "close", user_fd)
end

local function registerToChatserver(name)
	--默认注册到系统频道
	local channelname = "system_channel"
	if name ~=  nil then
		channelname = name
	end	
	local channel = dc.get(channelname)
	if channel == nil then return end
	local c = mc.new {
	channel = channel ,
		dispatch = function (channel,  ...)
			--发给客户端
		end
	}
	c:subscribe()	
end
local HEARTBEAT_TIME_MAX = 3 * 100
local function heartbeat_check ()
	if not user_fd then return end

	local t = os.time() - user.heartBeatTime
	if t > 120 then
		print('client time out')
		kick_self ()
	else
		if t > 6 then		--掉线
			user.offLineTime = user.offLineTime + 3	
		end
		skynet.timeout (HEARTBEAT_TIME_MAX, heartbeat_check)
	end
end

local traceback = debug.traceback
local REQUEST

local function handle_request (name, args, response)
	if hijack_msg[name] then
		skynet.fork(function()
			local ret = skynet.call(hijack_msg[name], "lua", name, skynet.self(), user.account.account_id, args)
			if ret then
				if type(ret) ~= "table" then
					print(ret)
				end
				send_msg (user_fd, response(ret))
			end		
		end)
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
	end
}
local function request_hijack_msg(handle)
	local interface = skynet.call(handle, "lua", "hijack_msg")
	for k, v in pairs(interface) do
		hijack_msg[v] = handle
	end
end

local CMD = {}
function CMD.Start (conf)
	g_shareData = sharedata.query 'gdd'

	local gate = conf.gate
	WATCHDOG = conf.watchdog
	user = {
		watchdog = WATCHDOG,
		fd = conf.client, 
		REQUEST = {},
		RESPONSE = {},
		CMD = {},
		MAP = nil,
		send_request = send_request,
		cards = nil,
		account = nil,
		explore = nil,
		heartBeatTime = os.time(),
	}
	user_fd = user.fd
	REQUEST = user.REQUEST
	RESPONSE = user.RESPONSE
       
	heartbeat_check()

	--注册匹配服务
	local matchserver = skynet.queryservice "match"
	request_hijack_msg(matchserver)
	--user.MAP = map
	character_handler:register (user)
	skynet.call(gate, "lua", "forward", user_fd)
	--注册到聊天服务
	registerToChatserver()
end

function CMD.disconnect ()
	print("agent closed")
	
	if user then
		character_handler:unregister (user)
		--request_release_msg(user.MAP, "map")
		if user.MAP ~= nil then
			skynet.call (user.MAP, "lua", "disconnect",skynet.self())
		end
		user = nil
		user_fd = nil
		REQUEST = nil
	end

	-- todo: do something before exit
	skynet.exit()
end

function CMD.getmatchinfo()
	local tb = {agent = skynet.self(),account = user.account.account_id, score = 10, nickname = user.account:getNickName(),time = 0,range = 0}
	return tb
end

function CMD.sendRequest (name, args)
	send_request(name, args)
end
--进入选英雄服务
function CMD.enterPickHero(s_pickup)
	request_hijack_msg(s_pickup)
end

--进入地图
function CMD.enterMap(map,arg)
	print("CMD.enterMap")
	request_hijack_msg(map)
	user.MAP = map
	send_request("beginEnterPvpMap", arg) --开始准备切图
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local f = CMD[command]
		if not f and user then
			f = user.CMD[command]
		end
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

