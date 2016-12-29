local skynet = require "skynet"
local socket = require "socket"
local Quest = require "quest.quest"
local syslog = require "syslog"
local protoloader = require "proto.protoloader"
local SkillsMethod = require "agent.skills_method"
local CardsMethod = require "agent.cards_method"
local traceback = debug.traceback
local snax = require "snax"

local master
local database
local host
local auth_timeout
local session_expire_time
local session_expire_time_in_second
local connection = {}
local saved_session = {}

local sharedata = require "sharedata"
local slaved = {}
local CMD = {}
local sm
function CMD.init (m, id, conf)
	master = m
	database = skynet.uniqueservice ("database")
	sm = snax.uniqueservice("servermanager") 
	host = protoloader.load (protoloader.GAME)
	auth_timeout = conf.auth_timeout * 100
	session_expire_time = conf.session_expire_time * 100
	session_expire_time_in_second = conf.session_expire_time
	g_shareData  = sharedata.query "gdd"
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

local function firstRegister(account_id)
	--添加默认赠送卡牌数据
	for k, v in pairs(Quest.AutoGainCards) do
		local card = CardsMethod.initCard( v )
		skynet.call(database, "lua", "cards", "addCard", account_id, card)
	end
	--添加默认赠送技能数据
	for k, v in pairs(Quest.AutoGainSkills) do 
		local skill = SkillsMethod.initSkill( v )
		skynet.call(database, "lua", "skills", "addSkill", account_id, skill)
	end
	--添加商城特惠数据
	for k, v in pairs(g_shareData.shopRepository) do
		if v.n32Type == 5 then
			if v.n32ArenaLvUpLimit == 1 then
				local cd = {accountId=account_id, atype=CoolDownAccountType.TimeLimitSale, value=v.n32Limit}
				print( cd )
				skynet.call(database, "lua", "cooldown", "add", cd)
                        	break
                        end
                 end
        end

end


function CMD.auth (fd, addr)
	connection[fd] = addr
	local isread = false
	skynet.timeout (auth_timeout, function ()
		if connection[fd] == addr then
			if isread == false then
				syslog.warningf ("connection %d from %s auth timeout!", fd, addr)
				close (fd)
			end
			
		end
	end)

	socket.start (fd)
	socket.limit (fd, 8192)
	local type, name, args, response = read_msg (fd)
	assert (type == "REQUEST")
	isread = true
	if name == "login" then
		assert (args and args.name and args.client_pub, "invalid handshake request")
		local account = skynet.call (database, "lua", "account", "load", args.name) or error ("load account " .. args.name .. " failed")
		account.account_id = args.name
		if account.nick == nil then
			--自动注册账号
			skynet.call (database, "lua", "account", "create", args.name,"123456")
			firstRegister(account.account_id)
		end
		local agent = sm.req.getAgent(account.account_id)
		local reconnect = true
		if agent == nil then
			reconnect = false
			agent = skynet.newservice ("agent")
		end
		skynet.call(master,"lua","agentEnter",agent,fd,account.account_id,reconnect)
		local msg = response {
			user_exists = false,
		}
		send_msg (fd, msg)
	end
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

