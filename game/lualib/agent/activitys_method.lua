local skynet = require "skynet"
local syslog = require "syslog"
local uuid = require "uuid"
local database

----------------cards func---------------------
local ActivitysMethod = 
{
	--
	calcUid = function (name, atype)
		return name .. '$' .. atype
	end;
	
	--
	calcNameType = function (uid)
		local t =  string.split(uid, '$')
		return t[1], tonumber(t[2])
	end;

	--
	initActivity = function(aid, atype, val, expire)
		local unit = {
			accountId=aid, 
			atype=atype, 
			value=val, 
			expire=expire,
		}
		return unit
	end;

	loadSystem = function(self)
		database = skynet.uniqueservice("database")
		self.units = {}
		for k, v in pairs(ActivitySysType) do
			local uid = self.calcUid(self.account_id, v)
			local unit  = skynet.call (database, "lua", "activity", "load", uid)
			if unit then
				self.units[uid] = unit
			end
		end
	end;
	
	--
	loadAccount = function(self)
		database = skynet.uniqueservice ("database")
		self.units = {}
		for k, v in pairs(ActivityAccountType) do
			local uid = self.calcUid(self.account_id, v)
			local unit  = skynet.call (database, "lua", "activity", "load", uid)
			if unit and unit.expire > os.time() then
				self.units[uid] = unit
			end
		end
	end;

	--
	getValue = function(self, atype)
		local uid = self.calcUid(self.account_id, atype)
		if self.units[uid] and self.units[uid].expire > os.time() then
			return self.units[uid].value
		end
		return 0
	end;
	
	--
	getValueByUid = function(self, uid)
		if self.units[uid] and self.units[uid].expire > os.time() then 
			return self.units[uid]
		end
		return nil
	end;

	--
	addValue = function(self, op, atype, val, expire)
		print(op, self.account_id, atype, val, expire)
		local uid = self.calcUid(self.account_id, atype)
		if not expire then
			expire = math.maxinteger
		end
		if self.units[uid] then
			if self.units[uid].expire <= os.time() then
				self.units[uid].value = 0
			end
			self.units[uid].value = self.units[uid].value + val
			self.units[uid].expire = expire
		
			skynet.call (database, "lua", "activity", "update", uid, self.units[uid], 'value')
		else
			self.units[uid] = self.initActivity(self.account_id, atype, val, expire)
			skynet.call (database, "lua", "activity", "update", uid, self.units[uid])
		end
	end;

	--
	setValue = function (self, op, atype, val, expire)
		local uid = self.calcUid(self.account_id, atype)	
		if not expire then
			expire = math.maxint32
		end
		if self.units[uid] then
			self.units[uid].value = val
			self.units[uid].expire = expire
			skynet.call (database, "lua", "activity", "update", uid, self.units[uid], 'value', 'expire')
		else
			self.units[uid] = self.initActivity(self.account_id, atype, val, expire)
			skynet.call (database, "lua", "activity", "update", uid, self.units[uid])
		end
	end;
}

return ActivitysMethod
