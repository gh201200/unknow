local skynet = require "skynet"
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

local account		--玩家账号		
local cardList = {} 	--玩家卡牌列表
local matcherList = {}  --匹配玩家列表

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
		--error "Server closed"
		print("服务器socket 断开 自动关闭机器人" .. account)
		skynet.exit()
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
	--print("Request:", session,name)
end

local last = ""

local function handle_request(name, args)
	if REQUEST[name] ~= nil then
		REQUEST[name](args)
	end
end

local function handle_response(session, args)
	if resp_sessionToFun[session] ~= nil then
		resp_sessionToFun[session](args)
	end
end

local function handle_package(t, ...)
	if t == "REQUEST" then
		handle_request(...)
	else
		assert(t == "RESPONSE")
		handle_response(...)
	end
end
-------------------机器人逻辑------------------------
local Map = {}
Map.MAP_GRID_SIZE = 0.1
local MAP_XGRID_NUM = 68
local MAP_ZGRID_NUM = 156
local MAP_XPOS = Map.MAP_GRID_SIZE * MAP_XGRID_NUM
local MAP_ZPOS = Map.MAP_GRID_SIZE * MAP_ZGRID_NUM
function robot_update(dt)
	robot_moveTest()	
end

function robot_moveTest()
	local x = math.random(1,MAP_XPOS * 10000 )
	local z = math.random(1,MAP_ZPOS * 10000 )
	send_request("move",{x = x,y = 0,z = z})
end
-------------------消息的请求处理---------------------
REQUEST.reEnterRoom = function(...)
	local t = ...
	if t.isin == false then
		print(account .. "进入游戏 准备匹配")
		send_request("requestMatch")
	end
end

REQUEST.requestPickHero= function(arg)
	matcherList = arg.matcherList
	print(account .. "收到匹配列表")
	--print("matchlist:",matcherList)
	 for k,v in pairs(cardList) do
	 	if v.ispicked == nil or v.ispicked == false then
			send_request("pickHero",{heroid = v.dataId})
			break
		end
	 end
end

REQUEST.sendHero = function(arg)
	print(account .. "收到卡牌列表")
	cardList = arg["cardsList"]
end

REQUEST.pickedhero = function(arg)
	print(account .. "接受到" .. arg.account .. "选择英雄" .. arg.heroid)
	for k,v in pairs(cardList) do
		if v.dataId == arg.heroid then
			v.ispicked = true
		end
	end
end

REQUEST.confirmedHero = function(arg)
	print(account .. "接受到" .. arg.account .. "确认英雄" .. arg.heroid)
	for k,v in pairs(cardList) do
		if v.dataId == arg.heroid then
			v.isconfirmed = true
		end
	end
end
REQUEST.fightBegin = function(arg)
	print(account .. "开始进入地图,进入机器人主逻辑")
	skynet.fork(function()
		while true do
			robot_update()	
			skynet.sleep(500)
		end
	end)
end
-------------------消息的回复处理----------------------
RESPONSE.login = function(...)
	print(account .."登录校验成功")
	--开始匹配
	send_request("enterGame")
end

RESPONSE.pickHero = function(arg)
	print(account .. "收到选择英雄返回码:" .. arg.errorcode)
	if arg.errorcode == 0 then
		 print(account .. "确认选择的英雄")
		 send_request("confirmHero")
	else
		 print(account .. "重新选择英雄")
		 for k,v in pairs(cardList) do
			if v.ispicked == nil or v.ispicked == false then
				send_request("pickHero",{ heroid = v.dataId})
				break
			end
		 end
	end
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
	fd = assert(socket.connect(conf.ip, conf.port))
	host = sproto.new(proto.s2c):host "package"	
	request = host:attach(sproto.new(proto.c2s)) 
	skynet.fork(function()
		while true do
			dispatch_package()	
			skynet.sleep(500)
		end
	end)
	account = conf.account
	send_request("login", {name = account ,client_pub = "123456"})	
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
