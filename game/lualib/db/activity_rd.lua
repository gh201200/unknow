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

function activity.add(activity)
	local connection, key = make_key( activity.uid )

	connection:hmset(key, 
		'accountId', activity['accountId'],
		'atype', activity['atype'],
		'value', activity['value']
		'expire', activity['expire']
	)
end

function activity:del( uid )
	local connection, key = make_key( uid )
	connection:del( key )	
end

function activity.update(activity, ...)
	
	local connection, key = make_key( activity.uid )
	local p = { ... }	

	local t = {}
	for k, v in pairs(p) do
		t[2*k - 1] = v
		t[2*k] = activity[v]
	end

	connection:hmset(key, table.unpack(t))
end


return activity

