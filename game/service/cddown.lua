local skynet = require "skynet"
local coroutine = require "skynet.coroutine"
local Time = require "time"
local Quest = require "quest.quest"
local snax = require "snax"

local database = nil
local units = {}

local ResetCardPowerTime = {{hour=9, min=0, sec = 0}}	--重置卡牌体力时间
local RefreshShopCardCD = 8*60*60			--刷新商城卡牌CD

local function calcUid(name, atype)
	return name .. '$' .. atype
end

local function calcNameType(uid)
	return string.split(uid, '$')
end

local function create_cd(uid, aid, atype, val)
	return {uid=uid, accountId=aid, atype=atype, value=val}
end

local function loadSystem()
	database = skynet.uniqueservice("database")
	for k, v in pairs(CoolDownSysType) do
		local uid = calcUid('system', v)
		local unit  = skynet.call (database, "lua", "cooldown_rd", "load", uid)
		if unit and unit.value > os.time() then
			unit.uid  = uid
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
		units[uid] = create_cd(uid, name, atype, now + time)
		skynet.call(database, "lua", "cooldown_rd", "update", units[uid], 'accountId', 'atype', 'value')
	else
		-- exist
		if units[uid].value < now + time then
			units[uid].value = now + time
			skynet.call(database, "lua", "cooldown_rd", "update", units[uid], 'value')
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
		units[uid] = create_cd(uid, name, atype, time)
		skynet.call(database, "lua", "cooldown_rd", "update", units[uid], 'accountId', 'atype', 'value')
	elseif units[uid].value < time then
		-- exist
		units[uid].value = time
		skynet.call(database, "lua", "cooldown_rd", "update", units[uid], 'value')
	end
end

local function isTimeout(name)
	if units[name] then return units[name].value < os.time() end
	return true
end

local function ResetCardPowertime_TimeOut()

end

local function RefreshShopCard()
	local activity = snax.queryservice 'activity'
	local val = activity.req.getValue('system', ActivitySysType.RefreshShopCard)
	val = (val + 1) % table.size(Quest.RefreshCardIds)

	activity.req.setValue('RefreshShopCard', 'system', ActivitySysType.RefreshShopCard, val)
end

local function cooldown_updatesys()

	if isTimeout(calcUid('system', CoolDownSysType.ResetCardPower)) then		--探索重置
		local r, r1  = pcall(ResetCardPowertime_TimeOut)
		if not r then
			error(r1)
		end
		setDate('system', CoolDownSysType.ResetCardPower, ResetCardPowerTime)
	end
	if isTimeout(calcUid('system', CoolDownSysType.RefreshShopCard)) then		--刷新卡牌商店	
		local r, r1  = pcall(RefreshShopCard)
		if not r then
			error(r1)
		end

		setTime('system', CoolDownSysType.RefreshShopCard, RefreshShopCardCD)
	end
	skynet.timeout(100,  cooldown_updatesys)
end

function response.getRemainingTime(uid)
	if isTimeout( uid ) then
		return 0
	end
	if units[uid] then 
		return units[uid].value - os.time()
	end
	return 0
end

function response.getSysValue(atype)
	local uid = calcUid('system', atype)
	if units[uid] then 
		return units[uid].value
	end
	return 0
end

function response.getValue(name, atype)
	local uid = calcUid(name, atype)
	if units[uid] then 
		return units[uid].value
	end
	return 0
end

function response.getValueByUid( uid )
	if units[uid] then 
		return units[uid].value
	end
	return 0
end

function response.getCDDatas()
	return units
end

------------------------------------------------
--POST
function accept.loadAccount( aid )
	for k, v in pairs(CoolDownAccountType) do
		local uid = calcUid(aid, v)
		local unit  = skynet.call (database, "lua", "cooldown_rd", "load", uid)
		if unit then
			unit.uid  = uid
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
