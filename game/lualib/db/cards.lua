local syslog = require "syslog"
local cards = {}
local connection_handler

function cards.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("cards:%s", name)
end

function cards.load (account)
	local connection, key = make_key (account)
	local tb = {}
	if connection:exists (key) then
		local st = connection:smembers(key)
		for k, v in pairs(st) do
			table.insert(tb, load(v)())
		end
	end
	return tb
end

--添加卡牌
function cards.addCard(account, tb)
	assert(account and tb)
	local connection,key = make_key(account)
	connection:sadd(key, serialize_table(tb))
end

--删除卡牌
function cards.delCard(account, tb)
	assert(account and tb)
	local connection,key = make_key(account)
	print(serialize_table(tb))
	connection:srem(key, serialize_table(tb))
end

return cards

