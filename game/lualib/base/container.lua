-----------------------------------------------------------------------------------------------------
-----各种容器
-----
-----------------------------------------------------------------------------------------------------

Queue = {};

--Queue
function Queue.new()
  return {first = 0, last = -1}
end

function Queue.pushQueue(list, value)
  local first = list.first - 1
  list.first   = first
  list[first]  = value
end

function Queue.popQueue(list)
  local last = list.last
  if list.first > last then logerror("list is empty") end
  local value = list[last]
  list[last] = nil   			-- to allow garbage collection
  list.last = last - 1
  return value
end

function Queue.count(list)
	return list.last - list.first + 1;
end

-----------------------------------------------------------------------------------------------------
-----List容器
-----------------------------------------------------------------------------------------------------
List  = {};

function List.new()
  return {first = 0, last = 0, size = 0};
end

function List.pushFront(list, value)--从前面插入值
  if (list.size == 0) then
    list[list.first] = {};	
    list[list.first]["v"] = value;
    list[list.first]["N"] = list.last;--保存下一个元素的Key
    list[list.first]["P"] = nil;--没有上一个值
  else
    local first = list.first;--保存当前第一个元素Key
    list.first = list.first + 1;--Key值加1
    list[list.first] = {};
    list[list.first]["v"] = value;
    list[list.first]["N"] = first;--保存当前元素为下一个元素的key
    list[list.first]["P"] = nil;

    list[first]["P"] = list.first;--保存当前第一个元素的上一个元素的key为新加值的KEY
    --list[list.last]["N"] = list.first;
  end
  list.size = list.size + 1;
end

function List.pushBack(list, value)--从后面插入值
  if (list.size == 0) then
    list[list.last] = {};
    list[list.last]["v"] = value;
    list[list.last]["P"] = list.first;
    list[list.last]["N"] = nil;--没有下一个值
    
  else
    local last = list.last;--保存当前最后一个元素key
    list.last   = list.last - 1;--key值减1
    list[list.last] = {};
    list[list.last]["v"] = value;
    list[list.last]["P"] = last;--保存当前元素为上一个元素的key
    list[list.last]["N"] = nil;
    
    --list[list.first]["L"] = list.last;
    list[last]["N"] = list.last;
  end
  list.size = list.size + 1;
end

function List.popFront(list)--pop掉列表的第一个值
  local firstValue = list[list.first]["v"];--保存第一个值的value

  if list.size == 1 then
  	list[list.first] = nil;--清空值
	list.first = 0;
	list.last = 0;
	list.size = 0;
	return firstValue;
  end

  local nextfirstkey = list[list.first]["N"];--获得被pop掉的下一个值的key
  list[list.first] = nil;--清空第一个值
  list.first = nextfirstkey;
  list[nextfirstkey]["P"] = nil;--清除痕迹，哼哼
  list.size = list.size - 1;
  return firstValue;
end

function List.popBack(list)
  local lastValue = list[list.last]["v"];--保存最后一个值的value

    if list.size == 1 then
	list[list.last] = nil;--清空值
	list.first = 0;
	list.last = 0;
	list.size = 0;
	return lastValue;
    end

  local prvlastkey = list[list.last]["P"];--获得被pop掉的上一个值的key
  list[list.last] = nil;--清空最后一个值
  list.last = prvlastkey;    
  list[prvlastkey]["N"] = nil;--清除痕迹，嘿嘿
  list.size = list.size - 1;
  return lastValue;
end

function List.erasebyvalue(list, value)
  if list.size == 0 then
	return;
  end
  local pos = list.first;
  local posvalue = list[pos]["v"];

  log("pos:"..tostring(pos));
  log("posvalue:"..tostring(posvalue));
  while posvalue ~= value do
	pos = list[pos]["N"];
	posvalue = list[pos]["v"];
	log("pos:"..tostring(pos));
	log("posvalue:"..tostring(posvalue));
	if pos == nil then
	     log("找完了没找到！");
	     return 0;
	end
  end
  log("找到了！！");
  if list.size == 1 then
	list[pos] = nil;--清空值
	list.first = 0;
	list.last = 0;
	list.size = 0;
	return 1;
  end

  local prevkey = list[pos]["P"];
  local nextkey = list[pos]["N"];
  if prevkey == nil then
	list[nextkey]["P"] = nil;
	list[pos] = nil;
	list.first = nextkey;
	list.size = list.size - 1;
	return 1;
  end
  if nextkey == nil then
	list[prevkey]["N"] = nil;
	list[pos] = nil;
	list.last = prevkey;
	list.size = list.size - 1;
	return 1;
  end
  list[prevkey]["N"] = nextkey;
  list[nextkey]["P"] = prevkey;
  list[pos] = nil;
  list.size = list.size - 1;
  return 1;
end

function List.erasebykey(list, key)
  if list.size == 0 then
	return;
  end
  local pos = list.first;

  log("pos:"..tostring(pos));

  while pos~= key do
	pos = list[pos]["N"];
	log("pos:"..tostring(pos));
	if pos == nil then
	     log("找完了没找到！");
	     return 0;
	end
  end
  log("找到了！！");
  if list.size == 1 then
	list[pos] = nil;--清空值
	list.first = 0;
	list.last = 0;
	list.size = 0;
	return 1;
  end

  local prevkey = list[pos]["P"];
  local nextkey = list[pos]["N"];
  if prevkey == nil then
	list[nextkey]["P"] = nil;
	list[pos] = nil;
	list.first = nextkey;
	list.size = list.size - 1;
	return 1;
  end
  if nextkey == nil then
	list[prevkey]["N"] = nil;
	list[pos] = nil;
	list.last = prevkey;
	list.size = list.size - 1;
	return 1;
  end
  list[prevkey]["N"] = nextkey;
  list[nextkey]["P"] = prevkey;
  list[pos] = nil;
  list.size = list.size - 1;
  return 1;
end

function List.View(list)
  if list.size == 0 then
	log("the list is empty");
	return;
  end
  local pos = list.first;

  log("pos:"..tostring(pos));

  while pos~= nil do
	local value = list[pos]["v"];
	local prevkey = list[pos]["P"];
	local nextkey = list[pos]["N"];
	log("key:"..tostring(pos).."|value:"..tostring(value).."|prevkey:"..tostring(prevkey).."|nextkey:"..tostring(nextkey));
	pos = list[pos]["N"];
  end
end

function List.Front(list)
  if list.size == 0 then
	return nil;
  end
  return list[list.first];
end

function List.back(list)
  if list.size == 0 then
	return nil;
  end
  return list[list.last];
end

function List.Size(list)
  return list.size;
end

-- ==============================================================================================
--			这里实现一个简单的数据缓存管理 simpleDataCache
-- ==============================================================================================
DataCache = { expireTime = 500, clearPos = 0, addPos = 1, maxCache = 10, maxCacheCount = 500, lastClearTime = 0,};

function DataCache:create(o, maxCache, maxCacheCount, expireTime)
	o = o or {};
	setmetatable(o, self);
	self.__index = self;
	o.maxCache = maxCache;
	o.maxCacheCount = maxCacheCount;
	o.expireTime = expireTime;
	o.dataCacheMap = o.dataCacheMap or {};
	o.dataCacheMap.UUID_CacheIDMap = o.dataCacheMap.UUID_CacheIDMap or {};

	for i=1,maxCache,1 do
		o.dataCacheMap[i] = o.dataCacheMap[i] or {};
		o.dataCacheMap[i].count = 0;
	end

	return o
end

-- 缓存操作函数
function DataCache:Add(UUID, dataTable)
	if UUID == nil and nil == dataTable then
		logerror("invalid Date UUID or dataTable!");
		return;
	end

	local NewData =
	{
		data = dataTable;
		lastUpdateTime = os.time();
	}

	local dataCacheId = self.dataCacheMap.UUID_CacheIDMap[UUID];
	if dataCacheId == nil then
		log("Data is not in Cache...");

		-- 这里使用循环推进检测	
		while true do
			slog("看看当前的插入点" .. self.addPos);
			if self.dataCacheMap[self.addPos].count < self.maxCacheCount then
				self.dataCacheMap[self.addPos][UUID] = NewData;
				self.dataCacheMap[self.addPos].count = self.dataCacheMap[self.addPos].count + 1;
				self.dataCacheMap.UUID_CacheIDMap[UUID] = self.addPos;
				break;
			elseif self.dataCacheMap[self.addPos].count >= self.maxCacheCount and self.addPos < self.maxCache then 
				log("当前数据缓存" .. self.addPos .. "已满，缓存到下一个...");
				self.addPos = self.addPos + 1;
			elseif self.addPos == self.maxCache then							
				log("数据缓存已满开始执行清理操作...");
				log("当前缓存的位置" .. self.clearPos);
				if self.clearPos == 0 then
					self.clearPos = 1;
				end
				self.addPos = self.clearPos;
				self:Clear();
			end
		end
	else
		log("Data Aready in Cache...");
		self.dataCacheMap[dataCacheId][UUID] = NewData;
	end
end

function DataCache:Load(UUID)
	if UUID == nil then
		logerror("invalid Date UUID...!");
		return;
	end

	local dataCacheId = self.dataCacheMap.UUID_CacheIDMap[UUID]
	if dataCacheId == nil then 
		logerror("the data you need is not in Cache!");
		return nil;
	end

	self.dataCacheMap[dataCacheId][UUID].lastUpdateTime = os.time();
	return self.dataCacheMap[dataCacheId][UUID].data;
end

function DataCache:Del(UUID)
	if UUID == nil then
		logerror("invalid Date UUID or dataTable!");
		return;
	end

	local dataCacheId = self.dataCacheMap.UUID_CacheIDMap[UUID]
	if nil == dataCacheId then 
		logerror("the data you need is not in Cache!");
		return;
	end

	self.dataCacheMap[dataCacheId][UUID] = nil;
	self.dataCacheMap[dataCacheId].count = self.dataCacheMap[dataCacheId].count - 1;
	self.dataCacheMap.UUID_CacheIDMap[UUID] = nil;
end

function DataCache:IsCached(UUID)
	return nil ~= self.dataCacheMap.UUID_CacheIDMap[UUID]
end

-- 建议这个函数放在定时器里面执行
-- 定时器可以在创建函数的时候执行
function DataCache:Clear()							
	if self.clearPos >= 1 and self.clearPos <= self.maxCache then
		slog("缓存[" .. self.clearPos .. "]清理开始...");
		local count = 0;
		local curTime = os.time();
		for i,v in pairs(self.dataCacheMap[self.clearPos]) do
			if i ~= "count" and curTime - v.lastUpdateTime > self.expireTime then
				slog(i);
				printTable(v);
				self.dataCacheMap.UUID_CacheIDMap[i] = nil;
				self.dataCacheMap[self.clearPos][i] = nil;
				self.dataCacheMap[self.clearPos].count = self.dataCacheMap[self.clearPos].count - 1;
				count = count + 1;
			end
		end
		slog("缓存[" .. self.clearPos .. "]清理结束，总共清理[" .. count .. "]条数据...");

		-- 更新状态
		self.lastClearTime = curTime
		if self.clearPos == self.maxCache then
			self.clearPos = 0;
		else
			self.clearPos = self.clearPos +1;
		end
	end
end

