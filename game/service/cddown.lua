local skynet = require "skynet"
local coroutine = require "skynet.coroutine"
local Time = require "time"
local Quest = require "quest.quest"

local database = nil
local CD = nil

local ResetCardPowertime = {{hour=9, min=0, sec = 0}}

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
local function setTime(name, time)
	if not time or time < 1 then return false end
	local now = os.time()
	if not CD[name] then
		-- not exist
		CD[name] = now + time
		skynet.call(database, "lua", "cooldown_rd", "add", 'system', name, time)
	else
		-- exist
		if CD[name] < now + time then
			CD[name] = now + time
			skynet.call(database, "lua", "cooldown_rd", "update", 'system', name, time)
		end
	end
	return true
end

local function setDate(name, date)
	local time = calcNextTime(date)
	if not time then return false end
	if not CD[name] then
		-- not exist
		CD[name] = time
		skynet.call(database, "lua", "cooldown_rd", "add", 'system', name, time)
	elseif CD[name] < time then
		-- exist
		CD[name] = time
		skynet.call(database, "lua", "cooldown_rd", "update", 'system', name, time)
	end
	return true

end

local function isTimeout(name)
	if CD[name] then return CD[name] < os.time() end
	return true
end

local function ResetCardPowertime_TimeOut()

end

local function cooldown_updatesys()

	if isTimeout('ResetCardPowertime') then		--探索重置
		local r, r1  = pcall(ResetCardPowertime_TimeOut)
		if not r then
			error(r1)
		end
		setDate('ResetCardPowertime', ResetCardPowertime)
	end

	if isTimeout('RefreshShopCard') then		--刷新卡牌商店
		setTime('RefreshShopCard', Quest.ShopCardCD)
	end

	skynet.timeout(100,  cooldown_updatesys)
end

function response.getRemainingTime(name)
	return CD[name]
end

function response.getCDDatas()
	return CD
end

function init()
	database = skynet.uniqueservice("database")
	CD  = skynet.call(database, "lua", "cooldown_rd", "load", 'system', 
		{"ResetCardPowertime", }
	)
	cooldown_updatesys()
end

function exit()

end
