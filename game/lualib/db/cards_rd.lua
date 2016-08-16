local Quest = require "quest.quest"

local cards = {}
local connection_handler

function cards.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("cards:%s", name)
end

function cards.load (account_id)
	local cards = {account_id = account_id}
	local connection, key = make_key (account_id)
	
	if connection:exists (key) then
		local st = connection:smembers(key)
		for k, v in pairs(st) do
			cards[v]  = {uuid = v}	
			cards[v].dataId = tonumber(connection:hget (v, "dataId"))
			cards[v].power = tonumber(connection:hget (v, "power"))
			cards[v].count = tonumber(connection:hget (v, "count"))
		end
	end

	return cards
end

function cards.create(account_id, _uuid, dataId)
	
	local connection, key = make_key (account_id)
	
	connection:sadd(key, _uuid) 

	connection:hmset (_uuid, 
		"dataId", dataId, 
		"power", Quest.CARD_INIT_POWER, 
		"count", 0
	)
end

function cards.addCard (account_id, card)
	
	local connection, key = make_key (account_id)
	
	connection:sadd(key, card.uuid)

	connection:hmset (card.uuid, 
		"dataId", card.dataId, 
		"power", card.power, 
		"count", card.count
	)
end

function cards.delCard(acount_id, uuid)

	local connection, key = make_key (account_id)

	connection:srem(key, uuid)
	
	connection:del(uuid)
end

function cards.update(card, ...)
	
	local connection, key = make_key (card.account_id)

	local t = {}
	for k, v in pairs(...) do
		t[2*k - 1] = v
		t[2*k] = card[v]
	end

	connection:hmset(card.uuid, table.unpack(t))
end

return cards

