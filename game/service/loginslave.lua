local skynet = require "skynet"
local socket = require "socket"

local syslog = require "syslog"
local protoloader = require "proto.protoloader"

local traceback = debug.traceback


local master
local database
local host
local auth_timeout
local session_expire_time
local session_expire_time_in_second
local connection = {}
local saved_session = {}

local slaved = {}

local CMD = {}

function CMD.init (m, id, conf)
	master = m
--	database = skynet.uniqueservice ("database")
	host = protoloader.load (protoloader.GAME)
	auth_timeout = conf.auth_timeout * 100
	session_expire_time = conf.session_expire_time * 100
	session_expire_time_in_second = conf.session_expire_time
end

local function close (fd)
	if connection[fd] then
		socket.close (fd)
		connection[fd] = nil
	end
end

local function read (fd, size)
	return socket.read (fd, size) or error ()
end

local function read_msg (fd)
	local s = read (fd, 2)
	local size = s:byte(1) * 256 + s:byte(2)
	local msg = read (fd, size)
	return host:dispatch (msg, size)
end

local function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socket.write (fd, package)
end

function CMD.auth (fd, addr)
	connection[fd] = addr
	skynet.timeout (auth_timeout, function ()
		if connection[fd] == addr then
			syslog.warningf ("connection %d from %s auth timeout!", fd, addr)
			close (fd)
		end
	end)

	socket.start (fd)
	socket.limit (fd, 8192)

	local type, name, args, response = read_msg (fd)
	assert (type == "REQUEST")
	print("auth",type,name,args)
	if name == "login" then
		assert (args and args.name and args.client_pub, "invalid handshake request")

		local account = {} --skynet.call (database, "lua", "account", "load", args.name) or error ("load account " .. args.name .. " failed")

	--	local session_key, _, pkey = srp.create_server_session_key (account.verifier, args.client_pub)
	--	local challenge = srp.random ()
		
		local msg = response {
					user_exists = (account.id ~= nil),
					gameserver_port = 8888
				}
		send_msg (fd, msg)
	end

	close (fd)
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local function pret (ok, ...)
			if not ok then 
				syslog.warningf (...)
				skynet.ret ()
			else
				skynet.retpack (...)
			end
		end

		local f = assert (CMD[command])
		pret (xpcall (f, traceback, ...))
	end)
end)

