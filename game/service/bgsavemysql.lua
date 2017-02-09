local skynet = require "skynet"
local mysql = require "mysql"
local config = require "config.database"

local use_sqldb = false

local database = ...

local mysqldb
local CMD = {}
local dbcmd = { head = 1, tail = 1 }
local savenum
local savethread
local opevent = {}
local expiretime


local function push(v)
	dbcmd[dbcmd.tail] = v
	opevent[v.table..v.key] = v
	dbcmd.tail = dbcmd.tail + 1

	if dbcmd.tail-dbcmd.head > 10000 then
		print('队列大小 = '..dbcmd.tail-dbcmd.head)
	end
	print('队列大小 = ' .. (dbcmd.tail-dbcmd.head))
end

local function pop()
	
	if dbcmd.head == dbcmd.tail then
		return
	end
	local v = dbcmd[dbcmd.head]
	dbcmd[dbcmd.head] = nil
	opevent[v.table..v.key] = nil
	dbcmd.head = dbcmd.head + 1
	if dbcmd.head == dbcmd.tail then
		dbcmd.head = 1
		dbcmd.tail = 1
	end
	
	print('队列大小 = ' .. (dbcmd.tail-dbcmd.head))
	return v
end

local function tablename( name, key )
	--[[
	if name == "card" then
		 name = name .. (hash_num( key ) % config.mysql.ncard + 1)
	elseif name == "skill" then
		 name = name .. (hash_num( key ) % config.mysql.nskill + 1)
	end
	--]]
	return name
end

local serialize_one = {
	cards = true,
	skills = true,
	missions = true,
	mails = true,
}
local function formatsql( key, name, unit )
	local keys, values
	if serialize_one[name] then
		keys="blobdata"
		values = "\'" .. serialize(unit) .. "\'"
	elseif name == "fightrecords" then
		local st = {}
		for p, q in pairs(unit) do
			table.insert(st ,load(q)())	--先反序列化
		end
		keys="blobdata"
		values = "\'" .. serialize(st) .. "\'"
	else
		keys, values = table.packsql( unit )
	end
	return "replace into ".. tablename(name, key) .. " ( uuid,"..keys..") values('" .. key .."',".. values .. ")"
end

local function dealevent()
	while true do
		for i=1, savenum do
			local cmd = pop()
			if not cmd then break end
			if cmd.type == "R" then
				local unit = skynet.call(database, "lua", cmd.table, "load", cmd.key)
				local sql = formatsql( cmd.key, cmd.table, unit )
				local ret = db:query( sql )
				if ret.errno then
					print('sql = '..sql)
					print(ret)
				end
			elseif cmd.type == "D" then
				local ret = db:query("delete from " .. tablename(cmd.table, cmd.key) .. " where uuid = '" .. cmd.key.."'")
				if ret.errno then
					print('sql = '..sql)
					print(ret)
				end
			end
		end
		skynet.sleep(config.mysql.savecd*100)
	end
end

local function dispatcher()
	savenum = config.mysql.savenum
	savethread = skynet.fork(dealevent)
end

local function saveall()
	print('bgmysql save all')
	savenum = math.maxint32
	local res = skynet.response()
	skynet.fork(function()
		while true do
			if dbcmd.tail - dbcmd.head == 0 then
				break
			end
			skynet.sleep(100)
		end
		res(true)
	end)
end

function CMD.addevent(table, key, _type)
	local r = table .. key
	if opevent[r] then
		opevent[r].type = _type
		return
	end
	local ev = { table=table, key=key, type=_type }
	push( ev )
end

function CMD.isAccountexist( account_id )
	local res = db.query("select uid from account where uuid = '"..account_id.."'")
	return next(res)
end

local function loadAccount( account_id )
	local res = db.query("select * from account where udid = '"..account_id.."'")
	skynet.call(database, "lua", "account", "update", account_id, res)
end

local function loadCards( account_id )
	for i=1, config.mysql.ncard do
		local sql = "select * from cards"..i.."where account_id = "..account_id
		local res = db.query( sql )
		if next(res) then
			for k, v in pairs(res) do
				skynet.call(database, "lua", "card", "addCard", account_id, res)
			end
			break
		end
	end
end

local function loadExplore( account_id )
	local res = db:query("select * from explore where account_id = '"..account_id.."'")
	skynet.call(database, "lua", "explore", "update", account_id, res)
end

local function loadSkills( account_id )
	for i=1, config.mysql.nskill do
		local sql = "select * from skills"..i.."where account_id = "..account_id
		local res = db:query( sql )
		if next(res) then
			for k, v in pairs(res) do
				skynet.call(database, "lua", "skill", "addSkill", account_id, res)
			end
			break
		end
	end
end



local function loadAllAccount()
	local res = db:query("select * from account where expire > "..expiretime)
	for k, v in pairs(res) do
		skynet.call(database, "lua", "account", "add", v)
	end
end

local function loadAllCards()
	local sql = "select a.* from cards as a, account as b where a.uuid=b.uuid and b.expire > "..expiretime

	local res = db:query( sql )
	for k, v in pairs(res) do
		local unit = load(v['blobdata'])()
		for p, q in pairs(unit) do
			q.doNotSavebg = true
			skynet.call(database, "lua", "cards", "update", v.uuid, q)
		end
	end
end

local function loadAllSkills()
	local sql = "select a.* from skills as a, account as b where a.uuid=b.uuid and b.expire > "..expiretime

	local res = db:query( sql )
	for k, v in pairs(res) do
		local unit = load(v['blobdata'])()
		for p, q in pairs(unit) do
			q.doNotSavebg = true
			skynet.call(database, "lua", "skills", "update", v.uuid, q)
		end
	end
end

local function loadAllExplore()
	local sql = "select a.* from explore as a, account as b where a.uuid=b.uuid and b.expire > " ..expiretime

	local res = db:query( sql )
	for k, v in pairs(res) do
		v.doNotSavebg = true
		skynet.call(database, "lua", "explore", "update", v.uuid, v)
	end
end

local function loadAllCooldown()
	local res = db:query("select a.* from cooldown as a, account as b where a.accountId=\'system\' or" .." (a.accountId=b.uuid and b.expire > "..expiretime..")")
	for k, v in pairs(res) do
		v.doNotSavebg = 1
		skynet.call(database, "lua", "cooldown", "update", v.uuid, v)
	end
end

local function loadAllActivity()
	local res = db:query("select a.* from activity as a, account as b where a.accountId=\'system\' or" .." (a.accountId=b.uuid and b.expire > "..expiretime..")")
	for k, v in pairs(res) do
		v.doNotSavebg = 1
		skynet.call(database, "lua", "activity", "update", v.uuid, v)
	end
end

local function loadAllMissions()
	local sql = "select a.* from missions as a, account as b where a.uuid=b.uuid and b.expire > "..expiretime

	local res = db:query( sql )
	for k, v in pairs(res) do
		local unit = load(v['blobdata'])()
		for p, q in pairs(unit) do
			q.doNotSavebg = true
			skynet.call(database, "lua", "missions", "update", v.uuid, q)
		end
	end
end

local function loadAllMails()
	local sql = "select a.* from mails as a, account as b where a.uuid=b.uuid and b.expire > "..expiretime

	local res = db:query( sql )
	for k, v in pairs(res) do
		local unit = load(v['blobdata'])()
		for p, q in pairs(unit) do
			q.doNotSavebg = true
			skynet.call(database, "lua", "mails", "add", {v.uuid}, q)
		end
	end
end

local function loadAllFightrecords()
	local sql = "select a.* from fightrecords as a, account as b where a.uuid=b.uuid and b.expire > "..expiretime

	local res = db:query( sql )
	for k, v in pairs(res) do
		local unit = load(v['blobdata'])()
		for p, q in pairs(unit) do
			skynet.call(database, "lua", "fightrecords", "add", {q.uuid}, q, true)
		end
	end

end

function CMD.loadAccountdata( account_id )
	loadAccount(account_id)
	loadCards( account_id )
	loadExplore( account_id )
	loadSkills( account_id )
end

local function loadAllDatas()
	expiretime = os.time() - config.mysql.expire
	
	loadAllAccount()
	loadAllCards()
	loadAllSkills()
	loadAllExplore()
	loadAllCooldown()
	loadAllActivity()
	loadAllMissions()
	loadAllMails()
	loadAllFightrecords()

end

-----------------------------------------------------------
--
local function init()

	--清空redis
	skynet.call(database, "lua", "CMD", "flushdb")
	
	--加载数据
	loadAllDatas()

	dispatcher()
end

skynet.start(function()
	if not use_sqldb then
		print('未启用mysql save db')
		skynet.dispatch("lua", function(_,_, command, ...)
			skynet.retpack({})
		end)

		return 
	end

	local function on_connect(db)
		db:query("set charset utf8");
	end
	db=mysql.connect({
		host=config.mysql.host,
		port=config.mysql.port,
		database=config.mysql.database,
		user=config.mysql.user,
		password=config.mysql.password,
		max_packet_size = config.mysql.max_packet_size,
		on_connect = on_connect
	})
	if not db then
		print("failed to connect")
	end
	print("success to connect to mysql server")
	
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		if f then
			skynet.ret(skynet.pack(f(...)))
		elseif command == 'saveall' then
			saveall()
		else
			print('invalid command ', command)
			skynet.retpack()
		end
	end)

	init()
	
	--db:disconnect()
	--skynet.exit()
end)

