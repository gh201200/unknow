local explore = {}
local connection_handler

function explore.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("explore:%s", name)
end

function explore.load (account_id)

	local acc = {}

	local connection, key = make_key (account_id)
	if not connection:exists (key) then
		connection:hmset (key, 
			"time", 0, 
			"slot0", "", 
			"slot1", "", 
			"slot2", "",
			"slot3", "",
			"slot4", ""
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
	
	local t = table.packdb(key, explore, ...)	

	connection:hmset(key, t)
end


return explore

