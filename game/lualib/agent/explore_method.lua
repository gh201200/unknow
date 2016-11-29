local skynet = require "skynet"
local syslog = require "syslog"

local ExploreMethod =
{
	--
	getTime = function(self, index, val)
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
	resetExplore = function(self, rr, _time)
		self.unit["con0"] = rr[1]
		self.unit["con1"] = rr[2]
		self.unit["con2"] = rr[3]
		self.unit["con3"] = rr[4]
		self.unit["con4"] = rr[5]
		self.unit["slot0"] = ""
		self.unit["slot1"] = ""
		self.unit["slot3"] = ""
		self.unit["slot3"] = ""
		self.unit["slot4"] = ""
		self.unit.time = _time

		local database = skybet.uniqueservice("database")
		skynet.call(database, "lua", "explore_rd", "update", self.unit, self.account_id) 
		
		--log record
		syslog.infof("player[%s]:resetExplore:%d,%d,%d,%d,%d", self.account_id, rr[1], rr[2], rr[3], rr[4], rr[5])
	end;
	--
	getCon = function(self, index)
		if index < 0 or index > 4 then return nil end 
		return self.unit["con"..index]
	end;
	--
}

return ExploreMethod
