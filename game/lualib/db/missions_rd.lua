local missions = {}
local connection_handler

function missions.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("missions:%s", name)
end

function missions.load (account_id)
	local missions = {}
	local connection, key = make_key (account_id)
	
	if connection:exists (key) then
		local st = connection:smembers(key)
		for k, v in pairs(st) do
			local serid = tonumber(v)
			missions[serid] = {uuid = serid}
			missions[serid].dataId = tonumber(connection:hget (v, "dataId"))
			missions[serid].progress = tonumber(connection:hget (v, "progress"))
			missions[serid].flag = tonumber(connection:hget (v, "flag"))
			missions[serid].time = tonumber(connection:hget (v, "time"))

		end
	end
	return missions
end

function missions.update(account_id, mission, ...)
	local connection, key = make_key (account_id)
	connection:sadd(key, mission.uuid)
	connection:hmset(mission.uuid, table.packdb(mission, ...))
	
	--bgsave
	if not mission.savebg  then
		sendBgevent("missions", account_id, "R")
	end

end

return missions

