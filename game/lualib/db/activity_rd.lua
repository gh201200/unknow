local activity = {}
local connection_handler

function activity.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("activity:%s", name)
end

function activity.load (name)

	local unit = {}

	local connection, key = make_key (name)
	if not connection:exists (key) then
		return nil
	end
	
	unit.expire = tonumber(connection:hget (key, "expire"))
	unit.accountId = connection:hget (key, "accountId")
	unit.atype = tonumber(connection:hget (key, "atype"))
	unit.value = tonumber(connection:hget (key, "value"))

	return unit
end

function activity.add(uuid, activity)
	local connection, key = make_key( uuid )

	connection:hmset(key, 
		'accountId', activity['accountId'],
		'atype', activity['atype'],
		'value', activity['value']
		'expire', activity['expire']
	)
end

function activity:del( uuid )
	local connection, key = make_key( uuid )
	connection:del( key )	
end

function activity.update(uuid, activity, ...)
	local connection, key = make_key( uuid )
	connection:hmset(key, table.packdb(activity, ...))
end


return activity


