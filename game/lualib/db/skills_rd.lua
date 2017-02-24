local skills = {}
local connection_handler

function skills.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("skills:%s", name)
end

function skills.load (account_id)
	local units = {}
	local connection, key = make_key (account_id)
	
	if connection:exists (key) then
		local st = connection:smembers(key)
		for k, v in pairs(st) do
			units[v] = {uuid = v}
			units[v].dataId = tonumber(connection:hget (v, "dataId"))
			units[v].count = tonumber(connection:hget (v, "count"))
		end
	end

	return units
end

function skills.loadBySerialId (account_id, serId)
	local skill = nil
	local connection, key = make_key (account_id)
	
	if connection:exists (key) then
		local st = connection:smembers(key)
		for k, v in pairs(st) do
			local dataId = tonumber(connection:hget (v, "dataId"))
			if serId == Macro_GetSkillSerialId(dataId) then
				skill = {uuid = v}
				skill.dataId = dataId
				skill.count = tonumber(connection:hget (v, "count"))
				break
			end
		end
	end

	return skill
end

function skills.update(account_id, skill, ...)
	local connection, key = make_key (account_id)
	connection:sadd(key, skill.uuid)
	connection:hmset(skill.uuid, table.packdb(skill, ...))

	--bgsave
	if not skill.doNotSavebg then
		sendBgevent("skills", account_id, "R")
	end
end

return skills

