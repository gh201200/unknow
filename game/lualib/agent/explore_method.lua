local skynet = require "skynet"
local syslog = require "syslog"

local ExploreMethod =
{
	--
	setTime = function(self, _time)
		self.unit.time = _time
		
		local database = skybet.uniqueservice("database")
		skynet.call(database, "lua", "explore_rd", "update", self) 
		
		--log record
		syslog.infof("player[%s]:setTime:%d", self.account_id, _time)
	end;
	--
	getTime = function(self)
		return self.unit.time
	end;
	--
	setSlot = function(self, index, val)
		if index < 0 or index > 4 then return end 
		self.unit["slot"..index] = val

		--local database = skybet.uniqueservice("database")
		--skynet.call(database, "lua", "explore_rd", "update", self, "slot"..index) 
		
		--log record
		--syslog.infof("player[%s]:setSlot:%d,%s", self.account_id, index, val)
	end;
	--
	getSlot = function(self, index)
		if index < 0 or index > 4 then return nil end 
		return self.unit["slot"..index]
	end;
	--
	resetExplore = function(self, val0, val1, val2, val3, val4)
		self.unit["con0"] = val0
		self.unit["con1"] = val1
		self.unit["con2"] = val2
		self.unit["con3"] = val3
		self.unit["con4"] = val4
		self.unit["slot0"] = ""
		self.unit["slot1"] = ""
		self.unit["slot3"] = ""
		self.unit["slot3"] = ""
		self.unit["slot4"] = ""

		local database = skybet.uniqueservice("database")
		skynet.call(database, "lua", "explore_rd", "reset", self) 
		
		--log record
		syslog.infof("player[%s]:resetExplore:%d,%d,%d,%d,%d", self.account_id, val0, val1, val2, val3, val4)
	end;
	--
	getCon = function(self, index)
		if index < 0 or index > 4 then return nil end 
		return self.unit["con"..index]
	end;
	--
}

return ExploreMethod
