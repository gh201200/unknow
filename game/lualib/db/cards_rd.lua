local cards = {}
local connection_handler

function cards.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("cards:%s", name)
end

function cards.load (account_id)
	local cards = {}
	local connection, key = make_key (account_id)
	
	if connection:exists (key) then
		local st = connection:smembers(key)
		for k, v in pairs(st) do
			cards[v]  = {uuid = v}	
			cards[v].dataId = tonumber(connection:hget (v, "dataId"))
			cards[v].count = tonumber(connection:hget (v, "count"))
		end
	end

	return cards
end

function cards.loadBySerialId (account_id, serId)
	local card = nil
	local connection, key = make_key (account_id)
	
	if connection:exists (key) then
		local st = connection:smembers(key)
		for k, v in pairs(st) do
			local dataId = tonumber(connection:hget (v, "dataId"))
			if serId == Macro_GetCardSerialId(card.dataId) then
				card  = {uuid = v}	
				card.dataId = dataId
				card.count = tonumber(connection:hget (v, "count"))
				break
			end
		end
	end

	return card
end


function cards.create(account_id, _uuid, dataId)
	
	local connection, key = make_key (account_id)
	
	connection:sadd(key, _uuid) 

	connection:hmset (_uuid, 
		"dataId", dataId, 
		"count", 0
	)
end

function cards.addCard (account_id, card)
	
	local connection, key = make_key (account_id)
	
	connection:sadd(key, card.uuid)

	connection:hmset (card.uuid, 
		"dataId", card.dataId, 
		"count", card.count
	)
end

function cards.delCard(account_id, uuid)

	local connection, key = make_key (account_id)

	connection:srem(key, uuid)
	
	connection:del(uuid)
end

function cards.update(account_id, card, ...)

	local connection, key = make_key (account_id)
	local p = { ... }

	local t = {}
	for k, v in pairs(p) do
		t[2*k - 1] = v
		t[2*k] = card[v]
	end

	connection:hmset(card.uuid, table.unpack(t))
end

return cards

