local skynet = require "skynet"
--local netpack = require "netpack"
--local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local socket = require "clientsocket"
local proto = require "proto.game_proto"
local CMD = {}
local REQUEST = {}
local RESPONSE = {}
local fd
local host
local request


local req_sessionToFun = {}
local resp_sessionToFun = {}

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.send(fd, package)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end
local session = 0

local function send_request(name, args)
	session = session + 1
	local str = request(name, args, session)
	send_package(fd, str)
	if RESPONSE[name] ~= nil then 
		resp_sessionToFun[session] = RESPONSE[name]
	end
	print("Request:", session,name)
end

local last = ""

local function handle_request(name, args)
	print("REQUEST", name)
	if REQUEST[name] ~= nil then
		print("333333")
		REQUEST[name](args)
	end
	--[[
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
	]]
end

local function handle_response(session, args)
	if resp_sessionToFun[session] ~= nil then
		resp_sessionToFun[session](args)
	end
	--[[	
	print("RESPONSE", session)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
	]]--
end

local function handle_package(t, ...)
	if t == "REQUEST" then
		handle_request(...)
	else
		assert(t == "RESPONSE")
		handle_response(...)
	end
end
-------------------消息的请求处理---------------------
REQUEST.reEnterRoom = function(...)
	print("REQUEST.reEnterRoom")
	local t = ...
	print(t)
	if t.isin == false then
		print("玩家进入游戏 准备匹配")
		send_request("requestMatch")
	end
end
-------------------消息的回复处理----------------------
RESPONSE.login = function(...)
	print("RESPONSE.login")
	--开始匹配
	send_request("enterGame")
end

local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end
		handle_package(host:dispatch(v))
	end
end

function CMD.start(conf)
	fd = assert(socket.connect("192.168.0.150", 8888))
	host = sproto.new(proto.s2c):host "package"	
	request = host:attach(sproto.new(proto.c2s)) 
	skynet.fork(function()
		while true do
			dispatch_package()	
			skynet.sleep(500)
		end
	end)
	send_request("login", {name = conf.account ,client_pub = "123456"})	
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
