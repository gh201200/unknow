local explore = {}
local connection_handler

function explore.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("explore:%s", name)
end

function explore.load (account_id, rr)

	local acc = {}

	local connection, key = make_key (account_id)
	
	if not connection:exists (key) then
		connection:hset( key, "time", 0)
		connection:hset( key, "uuid0", "")
		connection:hset( key, "uuid1", "")
		connection:hset( key, "uuid2", "")
		connection:hset( key, "uuid3", "")
		connection:hset( key, "uuid4", "")
		connection:hset( key, "con0", rr[1])
		connection:hset( key, "con1", rr[2])
		connection:hset( key, "con2", rr[3])
		connection:hset( key, "con3", rr[4])
		connection:hset( key, "con4", rr[5])
	end
	acc.time = tonumber(connection:hget (key, "time"))
	acc.uuid0 = connection:hget (key, "uuid0")
	acc.uuid1 = connection:hget (key, "uuid1")
	acc.uuid2 = connection:hget (key, "uuid2")
	acc.uuid3 = connection:hget (key, "uuid3")
	acc.uuid4 = connection:hget (key, "uuid4")
	acc.con0 = tonumber(connection:hget (key, "con0"))
	acc.con1 = tonumber(connection:hget (key, "con1"))
	acc.con2 = tonumber(connection:hget (key, "con2"))
	acc.con3 = tonumber(connection:hget (key, "con3"))
	acc.con4 = tonumber(connection:hget (key, "con4"))

	return acc
end

function explore.update(account_id, explore, ...)
	local connection, key = make_key (account_id)
	connection:hmset(key, table.packdb(explore, ...))
end


return explore

