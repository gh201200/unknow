local cooldown = {}
local connection_handler

function cooldown.init (ch)
	connection_handler = ch
end

local function make_key (bl)
	return connection_handler (bl), string.format ("cooldown:%s", bl)
end

function cooldown.load (bl, tb)

	local CD = {}
	
	local connection, key = make_key (bl)
	
	if connection:exists (key) then
		for k, v in pairs(tb) do
			CD[v] = tonumber(connection:hget (key, v))
		end
	end

	return CD
end

function cooldown.add (bl, name, time)
	
	local connection, key = make_key (bl)

	connection:hmset (key, 
		name, time
	)
end

function cooldown.update(bl, ...)
	
	local connection, key = make_key (bl)
	local t = {}
	for k, v in pairs(...) do
		t[2*k - 1] = v
		t[2*k] = account[v]
	end
	connection:hmset(key, table.unpack(t))
end

return cooldown

