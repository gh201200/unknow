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
			local mission = load( v )()
			missions[Macro_GetMissionSerialId(mission.id)] = mission
		end
	end
	return missions
end

function missions.add (account_id, mission)
	
	local connection, key = make_key (account_id)
	
	connection:sadd(key, serialize(mission))

	--bgsave
	if not mission.doNotSavebg  then
		sendBgevent("missions", account_id, "R")
	end

end

return missions

