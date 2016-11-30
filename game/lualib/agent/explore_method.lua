local skynet = require "skynet"
local syslog = require "syslog"

local ExploreMethod =
{
	--
	getTime = function(self, index, val)
		return self.unit.time
	end;
	--
	setUuid = function(self, index, val)
		if index < 0 or index > 4 then return end 
		self.unit["uuid"..index] = val

		--local database = skybet.uniqueservice("database")
		--skynet.call(database, "lua", "explore_rd", "update", self, "slot"..index) 
		
		--log record
		--syslog.infof("player[%s]:setSlot:%d,%s", self.account_id, index, val)
	end;
	--
	getUuid = function(self, index)
		if index < 0 or index > 4 then return nil end 
		return self.unit["uuid"..index]
	end;
	--
	reset = function(self, rr)
		self.unit["con0"] = rr[1]
		self.unit["con1"] = rr[2]
		self.unit["con2"] = rr[3]
		self.unit["con3"] = rr[4]
		self.unit["con4"] = rr[5]
		self.unit["uuid0"] = ""
		self.unit["uuid1"] = ""
		self.unit["uuid3"] = ""
		self.unit["uuid3"] = ""
		self.unit["uuid4"] = ""
		self.unit.time = 0

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
	begin = function(self, uuid0, uuid1, uuid2, uuid3, uuid4)
		self.unit.time = os.time() + Quest.ExploreTime
		self.unit["uuid0"] = uuid0
		self.unit["uuid1"] = uuid1
		self.unit["uuid3"] = uuid2
		self.unit["uuid3"] = uuid3
		self.unit["uuid4"] = uuid4

		local database = skybet.uniqueservice("database")
		skynet.call(database, "lua", "explore_rd", "update", self.unit, self.account_id) 
		
		--log record
		syslog.infof("player[%s]:begin:%d,%s,%s,%s,%s,$s", self.account_id, self.unit.time, uuid0, uuid1, uuid2, uuid3, uuid4)
	end;
}

return ExploreMethod
