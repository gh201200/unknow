local explores = {}
local connection_handler

function explores.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("explores:%s", name)
end

function explores.load (account_id)
	local units = {}
	local connection, key = make_key (account_id)
	
	if connection:exists (key) then
		local st = connection:smembers(key)
		for k, v in pairs(st) do
			units[v]  = {uuid = v}	
			units[v].dataId = tonumber(connection:hget (v, "dataId"))
			for i=0, 2 do
				units[v]["uuid"..i] = connection:hget (v, "uuid"..i)
				units[v]["att"..i] = tonumber(connection:hget (v, "att"..i))
				units[v]["cam"..i] = tonumber(connection:hget (v, "cam"..i))
			end
			units[v].time = tonumber(connection:hget (v, "time"))
		end
	end

	return units
end

function explores.update(account_id, explore, ...)
	local connection, key = make_key (account_id)
	connection:sadd(key, explore.uuid)
	connection:hmset(explore.uuid, table.packdb(explore, ...))
	
	--bgsave
	if not explore.doNotSavebg then
		sendBgevent("explores", account_id, "R")
	end
end


return explores

