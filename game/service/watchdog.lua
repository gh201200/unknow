local skynet = require "skynet"
local netpack = require "netpack"
local syslog = require "syslog"
local socket = require "socket"
local protoloader = require "proto.protoloader"
local host, proto_request = protoloader.load (protoloader.GAME)
local login_config = require "config.loginserver"
local snax = require "snax"

local CMD = {}
local SOCKET = {}
local gate
local agentfd = {}
local agentAccount = {}
local pid = 500001 
local slave = {}
local nslave
local balance = 1
local sm
local function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socket.write (fd, package)
end


function SOCKET.open(fd, addr)
	print("New client from : " .. addr)
	local s = slave[balance]
	balance = balance + 1
	if balance > nslave then balance = 1 end
	skynet.call (s, "lua", "auth", fd, addr)
end

local function close_agent(fd)
	print("close_agent")
	local a = agentfd[fd]
	local account = agentAccount[fd]
	agentfd[fd] = nil
	agentAccount[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		local ref = skynet.call(a, "lua", "addConnectRef",-1)
		if ref <= 0 then
			skynet.send(a, "lua", "disconnect",agent)
		else	
			print("agent还处于战斗服务中,agent继续保留")
		end
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
	print('socket data error = ',msg)
end

function CMD.authAi(name)
	local s = slave[balance]
	balance = balance + 1
	if balance > nslave then balance = 1 end
	return skynet.call (s, "lua", "authAi", name)
end 
function CMD.agentEnter(agent,fd,account,reconnect)
	print("CMD.agentEnter",agent,fd,account,reconnect)
	if fd ~= nil then
		agentfd[fd] = agent
	end
	if reconnect == true then
		--重连重置句柄值
		skynet.call(agent,"lua","reconnect",{ gate = gate, client = fd,account = account, watchdog = skynet.self() })
	else
		isAi = false
		if fd == nil then	
			isAi = true
		end
		skynet.call(agent, "lua", "Start", { gate = gate, client = fd,account = account, watchdog = skynet.self() ,isAi = isAi})
	end 
end

function CMD.start(conf)
	sm = snax.uniqueservice("servermanager")
	skynet.call(gate, "lua", "open" , conf)
	for i=1,login_config.slave,1 do
		local s = skynet.newservice ("loginslave")
		skynet.call (s, "lua", "init", skynet.self (), i, login_config)
		table.insert (slave, s)
	end
	nslave = #slave
end

function CMD.close(fd)
	print("CMD.close")
	close_agent(fd)
end

function CMD.userEnter( accountId, fd )
	print('user enter ', accountId, fd)
	for k, v in pairs(agentAccount) do
		if v and v == accountId then	
			print("111111111")
			close_agent( k )
		end
	end
	agentAccount[fd] = accountId
end

function CMD.getAgent(account)
	return 	
end

function CMD.gm_cmd( accountId, gmFunc, args )
	for k, v in pairs(agentAccount) do
		if v and v == accountId then
			skynet.call(agentfd[k], "lua", "gm_"..gmFunc, args)
			return true
		end
	end
	return false
end

local session_id = 0
function CMD.sendClients(name, args)
	session_id = session_id + 1
	local str = proto_request (name, args, session_id)
	for k, v in pairs(agentfd) do
		if v then
			send_msg (k, str)
		end
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)
	gate = skynet.newservice("gate")
end)
