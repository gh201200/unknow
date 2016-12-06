local skynet = require "skynet"
local syslog = require "syslog"
local uuid = require "uuid"

----------------skills func---------------------
local SkillsMethod = 
{
	--
	initSkill = function(_dataId)
		return {uuid = uuid.gen(), dataId = _dataId, count=0, flag=0,}
	end;
	--
	getSkillBySerialId = function(self, _serId)
		for k, v in pairs(self.units) do
			if v and Macro_GetSkillSerialId(v.dataId) == _serId then
				return v
			end
		end
		return nil
	end;
	--
	getSkillByDataId = function(self, _dataId)
		for k, v in pairs(self.units) do
			if v and v.dataId == _dataId then
				return v
			end
		end
		return nil
	end;

	--
	getSkillByUuid = function(self, _uuid)
		return self.units[_uuid]
	end;
	--
	addSkill = function(self, op, dataId, num)
		if not num then num = 1 end
		local serId = Macro_GetSkillSerialId(dataId)
		local v = self:getSkillBySerialId( serId )
		if v then	--already has the kind of skill
			v.count = mClamp(v.count + num, 0, math.maxinteger)
		else
			v = self.initSkill(dataId)
			v.count = num
			self.units[v.uuid] =  v
		end
		self:sendSkillData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "skills", "addSkill", self.account_id, v)
		
		--log record
		syslog.infof("op[%s]player[%s]:addSkill:%d,%d", op, self.account_id, dataId, num)
	end;
	--
	delSkillByDataId = function(self, op, dataId, num)
		if num == 0 then return end
		local v = self:getSkillBySerialId(Macro_GetSkillSerialId(dataId))
		if not v then return end
		if v.count < num then return end
		v.count = v.count - num

		self:sendSkillData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "skills", "update", self.account_id, v, "count")
		
		--log record
		syslog.infof("op[%s]player[%s]:delSkillByDataId:%d,%d", op, self.account_id, dataId, num)
	end;
	--
	delSkillByUuid = function(self, op, uuid, num)
		if num == 0 then return end
		local v = self:getSkillByUuid(uuid)
		if not v then return end
		if v.count < num then return end
		v.count = v.count - num

		self:sendSkillData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "skills", "update", self.account_id, v, "count")
		
		--log record
		syslog.infof("op[%s]player[%s]:delSkillByUuid:%s,%d:dataId[%d]", op, self.account_id, uuid, num, v.dataId)
	end;
	--
	updateDataId = function(self, op, uuid, _dataId)
		local v = self:getSkillByUuid(uuid)
		local oldDataId = v.dataId
		v.dataId = _dataId
		
		self:sendSkillData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "skills", "update", self.account_id, v, "dataId")
		
		--log record
		syslog.infof("op[%s]player[%s]:updateDataId:%s,dataId[%d][%d]", op, self.account_id, uuid, _dataId, oldDataId)
	end;
	--
	setSlot = function(self, uuid, _slot)
		local v = self:getSkillByUuid(uuid)
		if not v then return end
		v.slot = _slot
		
		self:sendSkillData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "skills", "update", self.account_id, v, "slot")
	end;
}

return SkillsMethod
