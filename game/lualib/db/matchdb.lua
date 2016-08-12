local matchdb = {}
local connection_handler

function matchdb.init (ch)
	connection_handler = ch
end
--name分为几个等级 比如 match100 match200 类似这样的 避免有序集合过大计算很慢
local function make_key (name)
	return connection_handler (name), string.format ("matchdb:%s", name)
end

function matchdb.load ()
	local connection, key = make_key (name)
	local tb = nil
	if connection:exists (key) then
		local length = connection:zcard(key) - 1
		tb = connection:zrange(key,0,length)	
	end
	return tb
end

--匹配产生6个玩家
function mathdb:math(name,accountname,score,range)
	range = range or 10 --默认为10
	matchdb.addmatcher(name,accountname,socre)
	local max,min = score + range,socre - range
	local connection, key = make_key (name)
	local items = connection:zrange(key,min,max)
	local count =  #items
	assert(count <= 6,"error:count is larger than 6")
	if count == 6 then
		--匹配成功 删除匹配列表中数据 返回
		connection:zremrangebyrank(key,min,max)
		return items
	end
	return nil
end

--添加匹配人物
function matchdb.addmatcher(name,accountname,score)
	assert(name and socre ,"add matcher name or score error")
	local connection,key = make_key(name)
	connection:zadd(key,score,accountname)
end

--删除匹配人物
function matchdb.delmatcher(accountname)
	assert(name ,"del matcher name or id error")
	local connection,key = make_key(name)
	if connection:exists (key)  then
		connection:zrem(key,accountname)
	end
end

return matchdb

