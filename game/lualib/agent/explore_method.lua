local skynet = require "skynet"
local syslog = require "syslog"
local Quest = require "quest.quest"

local ExploreMethod =
{
	--
	getTime = function(self)
		return self.unit.time
	end;
	--
	setUuid = function(self, index, val)
		if index < 0 or index > 4 then return end 
		self.unit["uuid"..index] = val

		--local database = skybet.uniqueservice("database")
		--skynet.call(database, "lua", "explore", "update", self, "slot"..index) 
		
		--log record
		--syslog.infof("player[%s]:setSlot:%d,%s", self.account_id, index, val)
	end;
	--
	getUuid = function(self, index)
		if index < 0 or index > 4 then return nil end 
		return self.unit["uuid"..index]
	end;
	--
	resetExplore = function(self, op, rr)
		self.unit["con0"] = rr[1]
		self.unit["con1"] = rr[2]
		self.unit["con2"] = rr[3]
		self.unit["con3"] = rr[4]
		self.unit["con4"] = rr[5]
		self.unit["uuid0"] = ""
		self.unit["uuid1"] = ""
		self.unit["uuid2"] = ""
		self.unit["uuid3"] = ""
		self.unit["uuid4"] = ""
		self.unit.time = 0

		self:sendExploreData()
		
		local database = skynet.uniqueservice("database")
		skynet.call(database, "lua", "explore", "update", self.account_id, self.unit) 
		
		--log record
		syslog.infof("op[%s]player[%s]:resetExplore:%d,%d,%d,%d,%d", op, self.account_id, rr[1], rr[2], rr[3], rr[4], rr[5])
	end;
	--
	getCon = function(self, index)
		if index < 0 or index > 4 then return nil end 
		return self.unit["con"..index]
	end;
	--
	beginExplore = function(self, op, uuid0, uuid1, uuid2, uuid3, uuid4)
		self.unit.time = os.time() + Quest.ExploreTime
		self.unit["uuid0"] = uuid0
		self.unit["uuid1"] = uuid1
		self.unit["uuid2"] = uuid2
		self.unit["uuid3"] = uuid3
		self.unit["uuid4"] = uuid4

		self:sendExploreData()

		local database = skynet.uniqueservice("database")
		skynet.call(database, "lua", "explore", "update", self.account_id, self.unit, "time", "uuid0", "uuid1", "uuid2", "uuid3", "uuid4") 
		
		--log record
		syslog.infof("op[%s]player[%s]:beginExplore:%d,%s,%s,%s,%s,$s",op, self.account_id, self.unit.time, uuid0, uuid1, uuid2, uuid3, uuid4)
	end;
}

return ExploreMethod
