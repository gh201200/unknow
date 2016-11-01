local explore = {}
local connection_handler

function explore.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("explore:%s", name)
end

function explore.load (account_id)

	local acc = { account_id = account_id }

	local connection, key = make_key (account_id)
	if not connection:exists (key) then
		connection:hmset (key, 
			"time", 0, 
			"slot0", "0", 
			"slot1", "0", 
			"slot2", "1",
			"slot3", "1",
			"slot4", "1"
		)
	end

	acc.time = tonumber(connection:hget (key, "time"))
	acc.slot0 = connection:hget (key, "slot0")
	acc.slot1 = connection:hget (key, "slot1")
	acc.slot2 = connection:hget (key, "slot2")
	acc.slot3 = connection:hget (key, "slot3")
	acc.slot4 = connection:hget (key, "slot4")

	return acc
end

function explore.update(explore, ...)
	
	local connection, key = make_key (explore.account_id)
	local p = { ... }	

	local t = {}
	for k, v in pairs(...) do
		t[2*k - 1] = v
		t[2*k] = explore[v]
	end

	connection:hmset(key, table.unpack(t))
end


return explore

