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


local function push(v)
	dbcmd[dbcmd.tail] = v
	dbcmd.tail = dbcmd.tail + 1

	print('队列大小 = ' .. (dbcmd.tail-dbcmd.head))
end

local function pop()
	
	if dbcmd.head == dbcmd.tail then
		return
	end
	local v = dbcmd[dbcmd.head]
	dbcmd[dbcmd.head] = nil
	dbcmd.head = dbcmd.head + 1
	if dbcmd.head == dbcmd.tail then
		dbcmd.head = 1
		dbcmd.tail = 1
	end
	
	print('队列大小 = ' .. (dbcmd.tail-dbcmd.head))
	return v
end

local function tablename( name, key )
	if name == "card" then
		 name = name .. (hash_num( key ) % config.mysql.ncard + 1)
	elseif name == "skill" then
		 name = name .. (hash_num( key ) % config.mysql.nskill + 1)
	end
	return name
end

local function formatsql( key, name, unit )
	local keys, values = table.packsql( unit )
	return "replace into ".. tablename(name, key) .. " ( uuid,"..keys..") values('" .. key .."',".. values .. ")"
end

local function dealevent()
	while true do
		skynet.sleep(config.mysql.savecd*100)
		for i=1, savenum do
			local cmd = pop()
			if not cmd then break end
			if cmd.type == "R" then
				local unit = skynet.call(database, "lua", cmd.table, "load", cmd.key)
				local sql = formatsql( cmd.key, cmd.table, unit )
				print( sql )
				db:query( sql )
			elseif cmd.type == "D" then
				db:query("delete from " .. tablename(cmd.table, cmd.key) .. " where uid = " .. cmd.key)
			end
		end
	end
end

local function dispatcher()
	savenum = config.mysql.savenum
	savethread = skynet.fork(dealevent)
end

local function saveall()
	savethread = nil
	savenum = math.maxinteger
	dealevent()
end


function CMD.addevent(table, key, _type)
	for i = dbcmd.head, dbcmd.tail-1 do
		if dbcmd[i].table==table and dbcmd.key==key then
			dbcmd[i].type = _type
			return
		end
	end
	local ev = { table=table, key=key, type=_type }
	push( ev )
end

function CMD.isAccountexist( account_id )
	local res = db.query("select uid from account where uuid = "..account_id)
	return next(res)
end

local function loadAccount( account_id )
	local res = db.query("select * from account where udid = "..account_id)
	skynet.call(database, "lua", "account", "update", account_id, res)
end

local function loadCards( account_id )
	for i=1, config.mysql.ncard do
		local sql = "select * from card"..i.."where account_id = "..account_id
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
	local res = db.query("select * from explore where account_id = "..account_id)
	skynet.call(database, "lua", "explore", "update", account_id, res)
end

local function loadSkills( account_id )
	for i=1, config.mysql.nskill do
		local sql = "select * from skill"..i.."where account_id = "..account_id
		local res = db.query( sql )
		if next(res) then
			for k, v in pairs(res) do
				skynet.call(database, "lua", "skill", "addSkill", account_id, res)
			end
			break
		end
	end
end

local function loadAllAccount()
	local res = db:query("select * from account where expire < "..(os.time()-config.mysql.expire))
	print('account ',res)
	for k, v in pairs(res) do
		skynet.call(database, "lua", "account", "update", v.uuid, v)
	end
end

local function loadAllCards()
	for i=1, config.mysql.ncard do
		local sql = "select a.* from card"..i.." as a, account as b where a.account_id=b.uuid and b.expire < "..(os.time()-config.mysql.expire)

		local res = db:query( sql )
		print('cards ',res)
		for k, v in pairs(res) do
			skynet.call(database, "lua", "card", "addCard", v.account_id, v)
		end
	end
end

local function loadAllSkills()
	for i=1, config.mysql.nskill do
		local sql = "select a.* from skill"..i.." as a, account as b where a.account_id=b.uuid and b.expire < "..(os.time()-config.mysql.expire)
		local res = db:query( sql )
		for k, v in pairs(res) do
			skynet.call(database, "lua", "card", "addSkill", v.account_id, v)
		end
	end
end

local function loadAllCooldown()
	local res = db:query("select a.* from cooldown as a, account as b where a.account_id=b.uuid or a.account_id=\'system\'")
	for k, v in pairs(res) do
		skynet.call(database, "lua", "cooldown", "add", v)
	end
end

local function loadAllActivity()
	local res = db:query("select a.* from activity as a, account as b where a.account_id=b.uuid or a.account_id=\'system\'")
	for k, v in pairs(res) do
		skynet.call(database, "lua", "activity", "add", v)
	end
end

function CMD.loadAccountdata( account_id )
	loadAccount(account_id)
	loadCards( account_id )
	loadExplore( account_id )
	loadSkills( account_id )
end

local function loadAllDatas()
	
	--玩家数据
	loadAllAccount()
	loadAllCards()
	loadAllSkills()
	

	--系统数据
	loadAllCooldown()
	loadAllActivity()
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
	
	skynet.dispatch("error", function (address, source, command, ...)
		print('数据保存服务退出')
		saveall()	
	end)

	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)

	init()
	
	--db:disconnect()
	--skynet.exit()
end)

