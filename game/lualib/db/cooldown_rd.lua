local cooldown = {}
local connection_handler

function cooldown.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("cooldown:%s", name)
end

function cooldown.load (name)
	local unit = {}

	local connection, key = make_key (name)
	if not connection:exists (key) then
		return nil
	end

	unit.accountId = connection:hget (key, "accountId")
	unit.atype = tonumber(connection:hget (key, "atype"))
	unit.value = tonumber(connection:hget (key, "value"))

	return unit
end

function cooldown.add(cooldown)
	local connection, key = make_key( cooldown.uid )

	connection:hmset(key, 
		'accountId', cooldown['accountId'],
		'atype', cooldown['atype'],
		'value', cooldown['value']
	)
end

function cooldown.update(cooldown, ...)
	local connection, key = make_key( cooldown.uid )
	local r = table.packdb(key, cooldown, ...)
	connection:hmset( r )
end


return cooldown

