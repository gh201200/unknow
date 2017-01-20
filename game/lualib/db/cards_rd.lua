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
			cards[v].explore = tonumber(connection:hget (v, "explore"))
			for i=0, 7 do
				cards[v]["skill"..i] = tonumber(connection:hget (v, "skill"..i))
			end
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
			if serId == Macro_GetCardSerialId(dataId) then
				card  = {uuid = v}	
				card.dataId = dataId
				card.count = tonumber(connection:hget (v, "count"))
				card.explore = tonumber(connection:hget (v, "explore"))
				for i=0, 7 do
					cards["skill"..i] = tonumber(connection:hget (v, "skill"..i))
				end
				break
			end
		end
	end

	return card
end


function cards.update(account_id, card, ...)
	local connection, key = make_key (account_id)
	connection:sadd(key, card.uuid)
	connection:hmset(card.uuid, table.packdb(card, ...))

	--bgsave
	if not card.doNotSavebg then
		sendBgevent("cards", account_id, "R")
	end
end

return cards
