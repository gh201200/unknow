local skynet = require "skynet"
local netpack = require "netpack"
local syslog = require "syslog"
local socket = require "socket"
local protoloader = require "proto.protoloader"
local host, proto_request = protoloader.load (protoloader.GAME)

local CMD = {}
local SOCKET = {}
local gate
local agentfd = {}
local agentPools = {}
local agentAccount = {}
local pid = 500001 

local function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socket.write (fd, package)
end


function SOCKET.open(fd, addr)
	print("New client from : " .. addr)
	if #agentPools == 0 then
		agentfd[fd] = skynet.newservice ("agent")
		syslog.noticef ("pool is empty, new agent(%d),fd(%d) created", agentfd[fd], fd)
	else
		agentfd[fd] = table.remove (agentPools, 1)
		syslog.debugf ("agent(%d),fd(%d) assigned, %d remain in pool", agentfd[fd], fd, #agentPools)
	end
	print("SOCET.open",fd)
	skynet.call(agentfd[fd], "lua", "Start", { gate = gate, client = fd, watchdog = skynet.self() })
--	pid = pid + 1
end


local function create_agents(num)	
	print("agentPools num = " .. #agentPools)
	--every five minites to check agent pools
	skynet.timeout(30000, function() create_agents(100) end)

	if #agentPools > 100 then return end

	for i = 1, num do
		table.insert (agentPools, skynet.newservice ("agent"))
	end
end


local function close_agent(fd)
	local a = agentfd[fd]
	agentfd[fd] = nil
	agentAccount[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

local function timeout(t)
	if #agentPools > 100 then return end
	print(t)
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

function CMD.start(conf)
	create_agents(conf.agent_pool)
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

function CMD.userEnter( accountId, fd )
	print('user enter ', accountId, fd)
	for k, v in pairs(agentAccount) do
		if v and v == accountId then	
			close_agent( k )
		end
	end
	agentAccount[fd] = accountId
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
