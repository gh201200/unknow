local skynet = require "skynet"
local netpack = require "netpack"

local CMD = {}
local SOCKET = {}
local gate
local agentfd = {}
local agentPools = {}

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
	if #agentPools == 0 then
		agentfd[fd] = skynet.newservice ("agent")
		syslog.noticef ("pool is empty, new agent(%d),fd(%d) created", agentfd[fd], fd)
	else
		agentfd[fd] = table.remove (agentPools, 1)
		syslog.debugf ("agent(%d),fd(%d) assigned, %d remain in pool", agentfd[fd], fd, #agentPools)
	end
	skynet.call(agentfd[fd], "lua", "Start", { gate = gate, client = fd, watchdog = skynet.self() })
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
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.call(a, "lua", "disconnect")
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
end

function CMD.start(conf)
	create_agents(conf.agent_pool)

	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
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
