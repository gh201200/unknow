local skynet = require "skynet"
local mysql = require "mysql"

local config = require "config.database"

local database = ...

local mysqldb
local CMD = {}
local dbcmd = { head = 1, tail = 1 }
local savenum
local savethread

local function push(v)
	dbcmd[dbcmd.tail] = v
	dbcmd.tail = dbcmd.tail + 1
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
	return v
end

local function tablename( table )
	if table == "card" then
		 table = table .. hash_num( table ) % config.mysql.ncard
	end
	return table
end

local function formatsql( uid, table, unit )
	local keys, values = table.packsql( unit )
	if table == "account" then
		keys = keys .. ",expire"
		values = values .. ","..os.time()
	end
	return "replace into ".. tablename(table) .. " ( uid,"..keys..") values(" .. key ..",".. values .. ")"
end

local function dealevent()
	while true do
		skynet.sleep(config.mysql.savecd*100)
		for i=1, savenum do
			local cmd = pop()
			if not cmd then break end
			if cmd.type == "R" then
				local unit = skynet.call(database, "lua", cmd.table, "load", cmd.key)
				local sql = formatsql( cmd.key, cmd,table, unit )
				print( sql )
				db:query( sql )
			elseif cmd.type == "D" then
				db:query("delete from " .. tablename(table) .. " where uid = " .. cmd.key)
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


function CMD.addevent( ev )
	push( ev )
end

function CMD.isAccountexist( account_id )
	local res = db.query("select account_id from account where account_id = "..account_id)
	return next(res)
end

local function loadAccount( account_id )
	local res = db.query("select * from account where account_id = "..account_id)
	res.account_id = nil
	skynet.call(database, "lua", "account_rd", "update", account_id, res)
end

local function loadCards( account_id )
	local res = db.query("select * from card where account_id = "..account_id)
	for k, v in pairs(res) do
		skynet.call(database, "lua", "cards_rd", "addCard", account_id, res)
	end
end

local function loadExplore( account_id )
	local res = db.query("select * from explore where account_id = "..account_id)
	res.account_id = nil
	skynet.call(database, "lua", "explore_rd", "update", account_id, res)
end

local function loadAllCooldown()
	local res = db.query("select * from cooldown")
	for k, v in pairs(res) do
		skynet.call(database, "lua", "cooldown_rd", "add", v)
	end
end

local function loadAllActivity()
	local res = db.query("select * from activity")
	for k, v in pairs(res) do
		skynet.call(database, "lua", "activity_rd", "add", v)
	end
end

function CMD.loadAccountdata( account_id )
	loadAccount(account_id)
	loadCards( account_id )
	loadExplore( account_id )
end

-----------------------------------------------------------
--
local function init()
	loadAllCooldown()
	loadAllActivity()

	dispatcher()
end

skynet.start(function()

	local function on_connect(db)
		db:query("set charset utf8");
	end
	mysqldb=mysql.connect({
		host=config.mysql.host,
		port=config.mysql.port,
		database=config.mysql.database,
		user=config.mysql.user,
		password=config.mysql.password,
		max_packet_size = config.mysql.max_packet_size,
		on_connect = on_connect
	})
	if not mysqldb then
		print("failed to connect")
	end
	print("success to connect to mysql server")
	
	skynet.dispatch("error", function (address, source, command, ...)
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

