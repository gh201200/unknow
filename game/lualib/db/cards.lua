local cards = {}
local connection_handler

function cards.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("cards:%s", name)
end

function cards.load (name)
	assert (name)
	local connection, key = make_key (name)
	local tb = nil
	if connection:exists (key) then
		local length = connection:llen(key)
		tb = connection:lrange(key,0,length)	
	end
	return tb
end

--添加卡牌
function cards.addCard(name,id,num)
	assert(name and id)
	num  = num or 1
	local connection,key = make_key(name)
	if connection:exists (key)  then
		conneciton:zincrby(key,num,id)
	else
		conneciton:zadd(key,num,id)
	end
end

--删除卡牌
function cards.delCard(name,id,num)
	assert(name and id)
	num  =  num or 1
	num  = - num
	if connection:exists (key)  then
		conneciton:zincrby(key,num,id)
	end
end

return cards

