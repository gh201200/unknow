local skynet = require "skynet"
local syslog = require "syslog"
local uuid = require "uuid"
local Time = require "time"
local database

----------------cards func---------------------
local CoolDownsMethod = 
{
	--
	calcNextTime  = function(date)
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
	end;

	--
	calcUid = function (name, atype)
		return name .. '$' .. atype
	end;
	
	--
	calcNameType = function (uid)
		local t =  string.split(uid, '$')
		return t[1], tonumber(t[2])
	end;

	initCD = function(aid, atype, val)
		local unit = {
			accountId=aid, 
			atype=atype, 
			value=val, 
		}
		return unit
	end;

	--
	loadSystem = function(self)
		database = skynet.uniqueservice("database")
		self.units = {}
		for k, v in pairs(CoolDownSysType) do
			local uid = self.calcUid('system', v)
			local unit  = skynet.call (database, "lua", "cooldown", "load", uid)
			if unit and unit.value > os.time() then
				self.units[uid] = unit
			end
		end
	end;
	
	--
	loadAccount = function(self)
		database = skynet.uniqueservice ("database")
		self.units = {}
		for k, v in pairs(CoolDownAccountType) do
			local uid = self.calcUid(self.account_id, v)
			local unit  = skynet.call (database, "lua", "cooldown", "load", uid)
			if unit and unit.value > os.time() then
				self.units[uid] = unit
			end
		end
	end;
	
	--
	getRemainingTime = function(self, atype)
		local uid = self.calcUid(self.account_id, atype)
		if self.units[uid] and self.units[uid].value > os.time() then 
			return self.units[uid].value - os.time()
		end
		return 0
	end;
	
	--
	getValue = function(self, atype)
		local uid = self.calcUid(self.account_id, atype)
		if self.units[uid] and self.units[uid].value > os.time() then
			return self.units[uid].value
		end
		return 0
	end;
	
	--
	getValueByUid = function(self, uid)
		if self.units[uid] and self.units[uid].value > os.time() then 
			return self.units[uid]
		end
		return nil
	end;
	
	-- 设置XX秒的冷却时间
	setTime = function(self, atype, time)
		if not time or time < 1 then return false end
		local now = os.time()
		local uid = self.calcUid(self.account_id, atype)
		if not self.units[uid] then
			-- not exist
			self.units[uid] = self.initCD(self.account_id, atype, now + time)
			skynet.call(database, "lua", "cooldown", "update", uid, self.units[uid])
		else
			-- exist
			if self.units[uid].value < now + time then
				self.units[uid].value = now + time
				skynet.call(database, "lua", "cooldown", "update", uid, self.units[uid], 'value')
			end
		end
	end;

	--设置下次过期时间
	setDate = function(self, atype, date)
		local time = self.calcNextTime(date)
		if not time then return false end
		local uid = self.calcUid(self.account_id, atype)
	
		if not self.units[uid] then
			-- not exist
			self.units[uid] = self.initCD(self.account_id, atype, time)
			skynet.call(database, "lua", "cooldown", "update",uid, self.units[uid])
		elseif self.units[uid].value < time then
			-- exist
			self.units[uid].value = time
			skynet.call(database, "lua", "cooldown", "update", uid, self.units[uid], 'value')
		end
	end;

	--
	isTimeout = function (self,  atype)
		local name = self.calcUid(self.account_id, atype)
		if self.units[name] then return self.units[name].value < os.time() end
		return true
	end;


	--
	setValue = function (self, op, atype, val)
		print("cooldown setValue ", op, atype, val)
		self:setTime(atype, val)
	end;

}

return CoolDownsMethod
