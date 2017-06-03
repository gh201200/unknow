local Time = require "time"

local account = {}
local connection_handler

function account.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("account:%s", name)
end

function account.load (account_id, ...)

	local acc = {}

	local connection, key = make_key (account_id)
	if connection:exists (key) then
		local connset = connection_handler("accountlist")
		connset:zadd("accountlist", os.time(), account_id)
		
		local n = select('#', ...)
		if n == 0 then
			acc.nick = connection:hget (key, "nick")
			acc.password = connection:hget (key, "password")
			acc.gold = tonumber(connection:hget (key, "gold"))
			acc.money = tonumber(connection:hget (key, "money"))
			acc.exp = tonumber(connection:hget (key, "exp"))
			acc.topexp = tonumber(connection:hget (key, "topexp"))
			acc.star = tonumber(connection:hget (key, "star"))
			acc.icon = connection:hget (key, "icon")
			acc.flag = tonumber(connection:hget (key, "flag"))
			acc.version = connection:hget (key, "version")
			acc.expire = tonumber(connset:zscore("accountlist", account_id))
			acc.aexp = tonumber(connection:hget (key, "aexp"))
			acc.exploretimes = tonumber(connection:hget (key, "exploretimes") or 20)
			acc.buyboxtimes = tonumber(connection:hget (key, "buyboxtimes") or 20)
			acc.refreshtime = tonumber(connection:hget (key, "refreshtime") or Time.tomorrow())
		else
			acc = connection:hmget(key, ...)
		end
	end
	return acc
end

function account.loadlist()
	local connset = connection_handler("accountlist")
	return connset:zrange("accountlist", os.time()-ACCOUNT_KEEPTIME, os.time())
end

function account.create (account_id, password, nick, icon)
	assert (account_id and #account_id < 24 and password and #password < 24, "invalid argument")
	
	if not nick then nick = account_id  end
	if not icon then icon = '1000.icon' end

	local connection, key = make_key (account_id)
	assert (connection:hsetnx (key, "account_id", account_id) ~= 0, "create account failed")

	--local salt, verifier = srp.create_verifier (name, password)
	local connset = connection_handler("accountlist")
	connset:zadd("accountlist", os.time(), account_id)
	
	connection:hmset (key, 
		"nick", nick, 
		"password", password, 
		"gold", 0, 
		"money", 0,
		"exp", 0,
		"topexp", 0,
		"icon", icon,
		"flag", 0,
		"star", 0,
		"aexp", 0,
		"exploretimes", 20,
		"buyboxtimes", 20,
		"refreshtime", Time.tomorrow(),
		"version", NOW_SERVER_VERSION
	)

	--bgsave
	sendBgevent("account", account_id, "R")
end

--only for mysql
function account.add(account)
	local connection, key = make_key (account.uuid)
	assert (connection:hsetnx (key, "account_id", account.uuid) ~= 0, "create account failed")
	
	local connset = connection_handler("accountlist")
	connset:zadd("accountlist", account.expire, account.uuid)
	
	account.uuid = nil
	account.expire = nil
	
	connection:hmset(key, table.packdb(account))
end

function account.update(account_id, account, ...)
	local connection, key = make_key (account_id)
	connection:hmset(key, table.packdb(account, ...))
	
	--bgsave
	sendBgevent("account", account_id, "R")
end

function account.hincrby(account_id, field, inc)
	local connection, key = make_key (account_id)
	connection:hincrby(key, field, inc)
	
	--bgsave
	sendBgevent("account", account_id, "R")
end


return account

