local skills = {}
local connection_handler

function skills.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("skills:%s", name)
end

function skills.load (account_id)
	local skills = {}
	local connection, key = make_key (account_id)
	
	if connection:exists (key) then
		local st = connection:smembers(key)
		for k, v in pairs(st) do
			skills[v] = {uuid = v}
			skills[v].dataId = tonumber(connection:hget (v, "dataId"))
			skills[v].count = tonumber(connection:hget (v, "count"))
		end
	end

	return skills
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

function skills.addSkill (account_id, skill)
	
	local connection, key = make_key (account_id)
	
	connection:sadd(key, skill.uuid)

	connection:hmset (skill.uuid, 
		"dataId", skill.dataId, 
		"count", skill.count
	)
	
	--bgsave
	if not skill.doNotSavebg  then
		sendBgevent("skills", account_id, "R")
	end

end

function skills.delSkill(account_id, uuid)

	local connection, key = make_key (account_id)

	connection:srem(key, uuid)
	
	connection:del(uuid)
	
	--bgsave
	if not skill.doNotSavebg  then
		sendBgevent("skills", account_id, "R")
	end
end

function skills.update(account_id, skill, ...)
	local connection, key = make_key (account_id)
	connection:hmset(skill.uuid, table.packdb(skill, ...))

	--bgsave
	if not skill.doNotSavebg  then
		sendBgevent("skills", account_id, "R")
	end
end

return skills

