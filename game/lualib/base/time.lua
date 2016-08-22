local Time = {}

------------------------------------------------------------------------------------
--系统时间相关全局函数
--08/20/13 22:12:34
function Time.GetCurStringTime()
	local time = os.date();
	return time;
end
--1377007957
function Time.GetCurIntegerTime()
	local time = os.time();
	return time;
end

--time.year--->2013年
--time.month--->8月
--time.day--->20日
--time.hour--->22时
--time.min--->6分
--time.sec--->18秒
--time.wday--->3（星期几，周日为1周六为7）
--time.yday--->232(年内天数)
--time.isdst--->false（日光节约时间）
function Time.GetCurTableTime()
	local time = os.date("*t",os.time());
	return time;
end

--查看是否过期
--nbegintime 开始时间
--freshtime  保质期(天)
--difftime   比较时间
--比如 一个牛奶 生产日期 9月1号 保质期 7 天 比较日期 9月10号
--那么这个牛奶在9月10号就过期了
function Time.IsTimeOverdueforDay(nbegintime,freshtime,difftime)
	 
	 local tt1 = os.date("*t", nbegintime);
	 local tt2 = os.date("*t", difftime);

	 --printTable(tt1);
	 --log("-----------")
	 --printTable(tt2);
	 AddDateDay(tt1, freshtime);
	 --log("-----------")
	 --printTable(tt1);
	 nbegintime = os.time(tt1);

	 --log("%d,%d",nbegintime,difftime)
	 if nbegintime <= difftime then
	 --	log("过期");
		return true;

	 else
--		log("未过期");
		return false;
	 end
end

function Time.GetTimeZone()
	local now = os.time()
	return os.difftime(now, os.time(os.date("!*t", now)))
end

function Time.IsLeapYear(year)
	return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

function Time.GetDaysInMonth(year, month)
	return month == 2 and IsLeapYear(year) and 29 or("\31\28\31\30\31\30\31\31\30\31\30\31"):byte(month)
end

function Time.AddDateYear(dt, year)
	dt.year = dt.year + year
end

function Time.AddDateMonth(dt, month, clampDays)
	dt.month = dt.month + month
	if dt.month > 12 then
		local y = math.floor(dt.month / 12)
		dt.month = dt.month % 12
		AddDateYear(dt, 1)
	end
	-- clamp days
	if clampDays ~= false then
		dt.day = getMin(dt.day, Time.GetDaysInMonth(dt.year, dt.month))
	end
end

function Time.AddDateDay(dt, day)
	dt.day = dt.day + day
	while true do
		local maxDay = Time.GetDaysInMonth(dt.year, dt.month)
		if dt.day > maxDay then
			dt.day = dt.day - maxDay
			Time.AddDateMonth(dt, 1, false)
		else
			break
		end
	end
end

function Time.AddDateHour(dt, h)
	dt.hour = dt.hour + h
	if dt.hour > 24 then
		local day = math.floor(dt.hour / 24)
		dt.hour = dt.hour % 24
		-- tail call
		return AddDateHour(dt, day)
	end
end

function Time.AddDateMin(dt, min)
	dt.min = dt.min + min
	if dt.min > 60 then
		local h = math.floor(dt.min / 60)
		dt.min = dt.min % 60
		-- tail call
		return AddDateHour(dt, h)
	end
end

function Time.AddDateSec(dt, sec)
	dt.sec = dt.sec + sec
	if dt.sec > 60 then
		local min = math.floor(dt.sec / 60)
		dt.sec = dt.sec % 60
		-- tail call
		return AddDateMin(dt, min)
	end
end

function Time.AddDate(dt, add)
	if add.year then Time.AddDateYear(dt, add.year) end
	if add.month then Time.AddDateMonth(dt, add.month) end
	if add.day then Time.AddDateDay(dt, add.day) end
	if add.hour then Time.AddDateHour(dt, add.hour) end
	if add.min then Time.AddDateMin(dt, add.min) end
	if add.sec then Time.AddDateYear(dt, add.sec) end
end

local DateDay = {"sec", "min", "hour", "day", "month", "year"}
function Time.nextDay(nextDate)
	local now = os.time()
	-- calc
	local target = {}
	local valid = 0
	while true do
		if not nextDate[DateDay[valid+1]] then break end
		valid = valid + 1
		target[DateDay[valid]] = nextDate[DateDay[valid]]
	end
	-- invalid input
	if 0 == valid then return false end
	if 6 == valid then
		if now > os.time(target) then
			return false
		else
			return target
		end
	end
	-- get next
	local dt = os.date("*t", now)
	local isCarry = false
	for i=valid,1,-1 do
		if target[DateDay[i]] > dt[DateDay[i]] then
			isCarry = false
			break
		elseif target[DateDay[i]] < dt[DateDay[i]] then
			isCarry = true
			break
		end
	end
	for i=valid+1,6 do
		target[DateDay[i]] = dt[DateDay[i]]
	end
	if isCarry then Time.AddDate(target, {[DateDay[valid+1]] = 1}) end
	return target
end

local DateWday = {"sec", "min", "hour", "wday"}
function Time.nextWday(nextDate)
	if not nextDate.wday then return false end
	-- default with 0
	local target = {}
	for i=1,4 do
		target[DateWday[i]] = nextDate[DateWday[i]] or 0
	end
	-- carry?
	local now = os.time()
	local dt = os.date("*/AddDatet", now)
	local isCarry = false
	for i=4,1,-1 do
		if target[DateWday[i]] > dt[DateWday[i]] then
			isCarry = false
			break
		elseif target[DateWday[i]] < dt[DateWday[i]] then
			isCarry = true
			break
		end
	end
	-- get next
	target.day = dt.day
	target.month = dt.month
	target.year = dt.year
	local addtion = isCarry and 7 or 0
	Time.AddDate(target, {day = (target.wday - dt.wday + addtion)})
	return target
end

local DateYday = {"sec", "min", "hour", "yday", "year"}
function Time.nextYday(nextDate)
	if not nextDate.yday then return false end
	local now = os.time()
	local dt = os.date("*t", now)
	-- default with 0
	local target = {}
	for i=1,4 do
		target[DateYday[i]] = nextDate[DateYday[i]] or 0
	end
	target.year = nextDate.year or dt.year
	-- carry?
	local isCarry = false
	for i=5,1,-1 do
		if target[DateYday[i]] > dt[DateYday[i]] then
			isCarry = false
			break
		elseif target[DateYday[i]] < dt[DateYday[i]] then
			isCarry = true
			break
		end
	end
	-- get next
	if isCarry then
		if nextDate.year then return false end
		Time.AddDate(target, {year = 1})
	end
	-- just in case
	target.yday = getMin(target.yday, (IsLeapYear(target.year) and 366 or 365))
	-- convert to month day
	target.month = 1
	target.day = target.yday
	while target.day > Time.GetDaysInMonth(target.year, target.month) do
		target.day = target.day - Time.GetDaysInMonth(target.year, target.month)
		target.month = target.month + 1
	end
	return target
end

--获得y年m月d天是星期几(蔡勒公式)
--0-星期日，1-星期一，2-星期二，3-星期三，4-星期四，5-星期五，6-星期六
function Time.getWeekDay_Zeller(y, m, d)
	local c = math.floor(y/100)
	y = y % 100
	if m==1 or m==2 then
		y = y - 1
		m = 12 + m
	end
	local w = math.floor(c/4)-2*c+y+math.floor(y/4)+math.floor((m+1)*13/5)+d-1
	w = w % 7
	return w
end

return Time
