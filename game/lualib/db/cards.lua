local cards = {}
local connection_handler

function cards.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("cards:%s", name)
end

function cards.load (id)
	local connection, key = make_key (id)
	local tb = nil
	if connection:exists (key) then
		local length = connection:zcard(key) - 1
		tb = connection:zrange(key,0,length)	
	end
	return tb
end
function cards.createdefault(name)
	local connection,key = make_key(name)
	if connection:exists (key)  then assert(0) end
	--默认赠送的3张卡牌
	connection:zadd(key,1,9000001)
	connection:zadd(key,1,9000002)
	connection:zadd(key,1,9000003)
	
end
--添加卡牌
function cards.addCard(name,id,num)
	assert(name and id,"add card name or id error")
	num  = num or 1
	local connection,key = make_key(name)
	if connection:exists (key)  then
		connection:zincrby(key,num,id)
	else
		connection:zadd(key,num,id)
	end
end

--删除卡牌
function cards.delCard(name,id,num)
	assert(name and id,"del card name or id error")
	num  =  num or 1
	num  = - num
	if connection:exists (key)  then
		connection:zincrby(key,num,id)
	end
end

return cards

