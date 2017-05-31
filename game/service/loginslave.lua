local skynet = require "skynet"
local socket = require "socket"
local syslog = require "syslog"
local protoloader = require "proto.protoloader"
local SkillsMethod = require "agent.skills_method"
local CardsMethod = require "agent.cards_method"
local MissionsMethod = require "agent.missions_method"
local ExploreMethod = require "agent.explore_method"
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
	DEf = g_shareData.DEF
	Quest = g_shareData.Quest
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
		skynet.call(database, "lua", "cards", "update", account_id, card)
	end
	--添加默认赠送技能数据
	for k, v in pairs(Quest.AutoGainSkills) do 
		local skill = SkillsMethod.initSkill( v )
		skynet.call(database, "lua", "skills", "update", account_id, skill)
	end
	--添加商城特惠数据
	for k, v in pairs(g_shareData.shopRepository) do
		if v.n32Type == 5 then
			if v.n32ArenaLvUpLimit == 1 then
				local cd = {accountId=account_id, atype=CoolDownAccountType.TimeLimitSale, value=os.time()+v.n32Limit}
				skynet.call(database, "lua", "cooldown", "update", cd.accountId..'$'..cd.atype, cd)
                        	break
                        end
                 end
        end
	--添加任务数据
	local mission = MissionsMethod.initMission( Quest.DailyMissionId )
	skynet.call(database, "lua", "missions", "update", account_id, mission)
	for i=Quest.AchivementsId[1], Quest.AchivementsId[2] do
		local id = Macro_GetMissionDataId( i, 1 )
		local mission = MissionsMethod.initMission( id )
		mission.flag = id
		skynet.call(database, "lua", "missions", "update", account_id, mission)
	end
	for i=Quest.AchivementsId[3], Quest.AchivementsId[4] do
		local id = Macro_GetMissionDataId( i, 1 )
		local mission = MissionsMethod.initMission( id )
		mission.flag = id
		skynet.call(database, "lua", "missions", "update", account_id, mission)
	end
	--添加探索数据
	local explores = ExploreMethod.initExplore(1, 3)
	for k, v in pairs(explores) do
		skynet.call(database, "lua", "explores", "update", account_id, v)
	end
end

function CMD.authAi(name)
	--
	print("添加pvp机器人 name:",name)
	local account = skynet.call (database, "lua", "account", "load", name) or error ("load account " .. name .. " failed")
	account.account_id = name
	if account.nick == nil then
		--自动注册账号
		skynet.call (database, "lua", "account", "create", name,"123456")
		firstRegister(account.account_id)
	end
	agent = skynet.newservice ("agent")
 	skynet.call(master,"lua","agentEnter",agent,fd,account.account_id,false)	
	return agent
end
function CMD.auth (fd, addr)
	print("loginslave auth",fd)
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
	print("auth",type,name,args)
	isread = true
	local error_id = 0
	if name == "login" then
		assert (args and args.name and args.client_pub, "invalid handshake request")
		local account = skynet.call (database, "lua", "account", "load", args.name) or error ("load account " .. args.name .. " failed")
		account.account_id = args.name
		if account.nick == nil then
			--帐号不存在
			-- skynet.call (database, "lua", "account", "create", args.name,)
			-- firstRegister(account.account_id)
			error_id = 1
		elseif args.client_pub ~= account.password then
			--密码错误
			error_id = 2
		else
			local agent = sm.req.getAgent(account.account_id)
			local reconnect = true
			if agent == nil then
				reconnect = false
				agent = skynet.newservice ("agent")
			end
			skynet.call(master,"lua","agentEnter",agent,fd,account.account_id,reconnect)
		end
		local msg = response {
			error_id = error_id,
		}
		send_msg (fd, msg)
	elseif name == "create" then
		assert (args and args.name and args.client_pub, "invalid handshake request")
		local account = skynet.call (database, "lua", "account", "load", args.name) or error ("load account " .. args.name .. " failed")
		account.account_id = args.name
		if account.nick ~= nil then
			--帐号不存在
			-- skynet.call (database, "lua", "account", "create", args.name,)
			-- firstRegister(account.account_id)
			error_id = 1
		else
			skynet.call (database, "lua", "account", "create", args.name, args.client_pub)
			firstRegister(account.account_id)
			
			local agent = sm.req.getAgent(account.account_id)
			local reconnect = true
			if agent == nil then
				reconnect = false
				agent = skynet.newservice ("agent")
			end
			skynet.call(master,"lua","agentEnter",agent,fd,account.account_id,reconnect)
		end
		local msg = response {
			error_id = error_id,
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

