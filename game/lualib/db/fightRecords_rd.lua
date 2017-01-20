local uuid = require "uuid"
local fightRecords = {}
local connection_handler
local expireTime = 30 * 24 * 60 * 60 
local maxRecordNum = 20
function fightRecords.init(ch)
	connection_handler = ch
end

local function make_key(name)
	return connection_handler (name), string.format ("fightRecord:%s", name)
end

function fightRecords.load(account_id)
	local records = {}
	local connection, key = make_key (account_id)
	if connection:exists (key) then
		local st = connection:zrevrange(key,0,20)
		return st
	end
	return {}	
end

function fightRecords.add(accounts,record, bgsave)
	local time = os.time()
	for k,account_id in pairs(accounts) do
		local connection, key = make_key (account_id)
		connection:zadd(key,time, serialize(record))
		connection:EXPIRE(key,expireTime)
		--bgsave
		if not bgsave then
			sendBgevent("fightrecords", account_id, "R")
		end
	end
	
end

return fightRecords
