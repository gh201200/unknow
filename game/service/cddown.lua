local skynet = require "skynet"
local coroutine = require "skynet.coroutine"
local Time = require "time"
local Quest = require "quest.quest"
local snax = require "snax"

local database = nil
local units = {}

--local ResetCardPowerTime = {{hour=14, min=0, sec = 0}}	--重置卡牌体力时间
local RefreshShopCardCD = 60				--刷新商城卡牌CD

local function calcUid(name, atype)
	return name .. '$' .. atype
end

local function calcNameType(uid)
	local t =  string.split(uid, '$')
	return t[1], tonumber(t[2])
end

local function create_cd(aid, atype, val)
	return {accountId=aid, atype=atype, value=val}
end

local function loadSystem()
	database = skynet.uniqueservice("database")
	for k, v in pairs(CoolDownSysType) do
		local uid = calcUid('system', v)
		local unit  = skynet.call (database, "lua", "cooldown", "load", uid)
		if unit and unit.value > os.time() then
			units[uid] = unit
		end
	end
end

local function calcNextTime(date)
	local ret = false
	for _,nextDate in pairs(date) do
		local target = false
		-- weak day or year day or month day
		if nextDate.wday then
			target = Time.nextWday(nextDate)
		elseif nextDate.yday then
			target = Time.nextYday(nextDate)
		else
			target = Time.nextDay(nextDate)
		end
		-- pick the near one
		if target then
			local nextRet = os.time(target)
			
			if not ret or ret > nextRet then ret = nextRet end
		end
	end
	return ret
end

-- 设置XX秒的冷却时间
local function setTime(name, atype, time)
	if not time or time < 1 then return false end
	local now = os.time()
	local uid = calcUid(name, atype)
	if not units[uid] then
		-- not exist
		units[uid] = create_cd(name, atype, now + time)
		skynet.call(database, "lua", "cooldown", "update", units[uid], 'accountId', 'atype', 'value')
	else
		-- exist
		if units[uid].value < now + time then
			units[uid].value = now + time
			skynet.call(database, "lua", "cooldown", "update", units[uid], 'value')
		end
	end
end

--设置下次过期时间
local function setDate(name, atype, date)
	local time = calcNextTime(date)
	if not time then return false end
	local uid = calcUid(name, atype)
	
	if not units[uid] then
		-- not exist
		units[uid] = create_cd(name, atype, time)
		skynet.call(database, "lua", "cooldown", "update",uid, units[uid], 'accountId', 'atype', 'value')
	elseif units[uid].value < time then
		-- exist
		units[uid].value = time
		skynet.call(database, "lua", "cooldown", "update", uid, units[uid], 'value')
	end
end

local function isTimeout(name)
	if units[name] then return units[name].value < os.time() end
	return true
end

local function RefreshShopCard()
	local activity = snax.queryservice 'activity'
	local val = activity.req.getValue('system', ActivitySysType.RefreshShopCard)
	val = (val + 1) % (table.size(Quest.RefreshCardIds)+1)
	if val == 0 then val = 1 end

	activity.req.setValue('RefreshShopCard', 'system', ActivitySysType.RefreshShopCard, val)
	local types = {
		ActivityAccountType.BuyShopCard1,
		ActivityAccountType.BuyShopCard2,
		ActivityAccountType.BuyShopCard3,
		ActivityAccountType.BuyShopCard4,
		ActivityAccountType.BuyShopCard5,
		ActivityAccountType.BuyShopCard6,
	}
	local uid = calcUid('system', CoolDownSysType.RefreshShopCard)
	activity.post.resetAccountValue('RefreshShopCard', types, units[uid].value)
end

local function cooldown_updatesys()

	if isTimeout(calcUid('system', CoolDownSysType.RefreshShopCard)) then		--刷新卡牌商店	
		setTime('system', CoolDownSysType.RefreshShopCard, RefreshShopCardCD)
		
		local r, r1  = pcall(RefreshShopCard)
		if not r then
			error(r1)
		end
	end
	skynet.timeout(100,  cooldown_updatesys)
end

function response.getRemainingTime(uid)
	if units[uid] and units[uid].value > os.time() then 
		return units[uid].value - os.time()
	end
	return 0
end

function response.getSysValue(atype)
	local uid = calcUid('system', atype)
	if units[uid] and units[uid].value > os.time() then 
		return units[uid].value
	end
	return 0
end

function response.getValue(name, atype)
	local uid = calcUid(name, atype)
	if units[uid] and units[uid].value > os.time() then 
		return units[uid].value
	end
	return 0
end

function response.getValueByUid( uid )
	if units[uid] and units[uid].value > os.time() then 
		return units[uid].value
	end
	return 0
end

function response.resetAccountValue( types, value )
	for k, v in pairs(units) do
		for p, q in pairs(types) do
			if v.atype == q then	
				v.value = value
			end
		end
	end
end

function response.getCDDatas()
	return units
end

------------------------------------------------
--POST
function accept.loadAccount( aid )
	for k, v in pairs(CoolDownAccountType) do
		local uid = calcUid(aid, v)
		local unit  = skynet.call (database, "lua", "cooldown", "load", uid)
		if unit then
			units[uid] = unit
		end
	end
end

function accept.Start()
	cooldown_updatesys()
end


---------------------------------------------------------------
------------------------

function init()
	loadSystem()
end

function exit()

end
