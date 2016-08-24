local skynet = require "skynet"
local syslog = require "syslog"

local ExploreMethod =
{
	--
	setTime = function(self, _time)
		self.unit.time = _time
		
		local database = skybet.uniqueservice("database")
		skynet.call(database, "lua", "explore_rd", "update", self, "time") 
		
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

		local database = skybet.uniqueservice("database")
		skynet.call(database, "lua", "explore_rd", "update", self, "slot"..index) 
		
		--log record
		syslog.infof("player[%s]:setSlot:%d,%s", self.account_id, index, val)
	end;
	--
	getSlot = function(self, index)
		if index < 0 or index > 4 then return nil end 
		return self.unit["slot"..index]
	end;

}

return ExploreMethod
