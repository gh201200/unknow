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
		acc.slot0 = ""
		acc.slot1 = ""
		acc.slot2 = "" 
		acc.slot3 = ""
		acc.slot4 = ""
		acc.con0 = 0
		acc.con1 = 0
		acc.con2 = 0
		acc.con3 = 0
		acc.con4 = 0
	else
		acc.slot0 = connection:hget (key, "slot0")
		acc.slot1 = connection:hget (key, "slot1")
		acc.slot2 = connection:hget (key, "slot2")
		acc.slot3 = connection:hget (key, "slot3")
		acc.slot4 = connection:hget (key, "slot4")
		acc.con0 = tonumber(connection:hget (key, "con0"))
		acc.con1 = tonumber(connection:hget (key, "con1"))
		acc.con2 = tonumber(connection:hget (key, "con2"))
		acc.con3 = tonumber(connection:hget (key, "con3"))
		acc.con4 = tonumber(connection:hget (key, "con4"))
	end

	return acc
end


function explore.update(explore, ...)
	
	local connection, key = make_key (explore.account_id)
	
	local t = table.packdb(key, explore, ...)	

	connection:hmset(key, t)
end


return explore

