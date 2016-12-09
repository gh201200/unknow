local skynet = require "skynet"
local syslog = require "syslog"
local uuid = require "uuid"

----------------cards func---------------------
local CardsMethod = 
{
	--
	initCard = function(_dataId)
		return 
		{
			uuid = uuid.gen(), 
			dataId = _dataId, 
			count=0, 
			explore=0,
			skill0=0,
			skill1=0,
			skill2=0,
			skill3=0,
			skill4=0,
			skill5=0,
			skill6=0,
			skill7=0
		}
	end;
	--
	getCardBySerialId = function(self, _serId)
		for k, v in pairs(self.units) do
			if v and Macro_GetCardSerialId(v.dataId) == _serId then
				return v
			end
		end
		return nil
	end;
	--
	getCardByDataId = function(self, _dataId)
		for k, v in pairs(self.units) do
			if v and v.dataId == _dataId then
				return v
			end
		end
		return nil
	end;

	--
	getCardByUuid = function(self, _uuid)
		return self.units[_uuid]
	end;
	--
	addCard = function(self, op, dataId, num)
		if not num then num = 1 end
		local serId = Macro_GetCardSerialId(dataId)
		local v = self:getCardBySerialId( serId )
		if v then	--already has the kind of card
			v.count = mClamp(v.count + g_shareData.heroRepository[dataId].n32WCardNum * num, 0, math.maxinteger)
		else
			v = self.initCard(dataId)
			v.count = num * (g_shareData.heroRepository[dataId].n32WCardNum - 1)
			self.units[v.uuid] =  v
		end
		self:sendCardData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards", "addCard", self.account_id, v)
		
		--log record
		syslog.infof("op[%s]player[%s]:addCard:%d,%d", op, self.account_id, dataId, num)
	end;
	--
	delCardByDataId = function(self, op, dataId, num)
		if num == 0 then return end
		local v = self:getCardBySerialId(Macro_GetCardSerialId(dataId))
		if not v then return end
		if v.count < num then return end
		v.count = v.count - num

		self:sendCardData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards", "update", self.account_id, v, "count")
		
		--log record
		syslog.infof("op[%s]player[%s]:delCardByDataId:%d,%d", op, self.account_id, dataId, num)
	end;
	--
	delCardByUuid = function(self, op, uuid, num)
		if num == 0 then return end
		local v = self:getCardByUuid(uuid)
		if not v then return end
		if v.count < num then return end
		v.count = v.count - num

		self:sendCardData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards", "update", self.account_id, v, "count")
		
		--log record
		syslog.infof("op[%s]player[%s]:delCardByUuid:%s,%d:dataId[%d]", op, self.account_id, uuid, num, v.dataId)
	end;
	--
	updateDataId = function(self, op, uuid, _dataId)
		local v = self:getCardByUuid(uuid)
		local oldDataId = v.dataId
		v.dataId = _dataId
		
		self:sendCardData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards", "update", self.account_id, v, "dataId")
		
		--log record
		syslog.infof("op[%s]player[%s]:updateDataId:%s,dataId[%d][%d]", op, self.account_id, uuid, _dataId, oldDataId)
	end;
	--
	setExplore = function(self, uuid, _time)
		local v = self:getCardByUuid(uuid)
		if not v then return end
		v.explore = _time
		
		self:sendCardData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards", "update", self.account_id, v, "explore")
	end;
	--
	setSkill = function(self, op, uuid, slot, serId)
		print(op, uuid, slot, serId)
		if slot < 0 or slot > 7 then return end
		local v = self:getCardByUuid(uuid)
		if not v then return end

		v["skill"..slot] = serId

		self:sendCardData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards", "update", self.account_id, v, "skill"..slot)
		
		--log record
		syslog.infof("op[%s]player[%s]:setSkill:%s,%d,%d", op, self.account_id, uuid, slot, serId)
	end;
}

return CardsMethod
