local skynet = require "skynet"
local syslog = require "syslog"

local ExploreMethod =
{
	--
	setTime = function(self, _time)
		self.time = _time
		
		local database = skybet.uniqueservice("database")
		skynet.call(database, "lua", "explore_rd", "update", self, "time") 
		
		--log record
		syslog.infof("player[%s]:setTime:%d", self.account_id, _time)
	end;
	--
	setSlot = function(self, index, val)
		if index < 0 or index > 4 then return end 
		self["slot"..index] = val

		local database = skybet.uniqueservice("database")
		skynet.call(database, "lua", "explore_rd", "update", self, "slot"..index) 
		
		--log record
		syslog.infof("player[%s]:setSlot:%d,%s", self.account_id, index, val)
	end;

}

return ExploreMethod
