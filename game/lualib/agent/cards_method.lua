local skynet = require "skynet"
local syslog = require "syslog"
local uuid = require "uuid"

----------------cards func---------------------
local CardsMethod = 
{
	--
	initCard = function(_dataId)
		return {uuid = uuid.gen(), dataId = _dataId, power=100, count=0, buyNum=0,}
	end;
	--
	geCardBySerialId = function(self, _serId)
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
	addCard = function(self, op, dataId, num, buyNum)
		if not num then num = 1 end
		if not buyNum then buyNum = 0 end
		local v = self:getCardByDataId( dataId )
		if v then	--already has the kind of card
			v.count = mClamp(v.count + g_shareData.heroRepository[dataId].n32WCardNum * num, 0, math.maxinteger)
			v.buyNum = mClamp(v.buyNum + buyNum, 0, math.maxinteger)
		else
			
			v = self.initCard(dataId)
			v.count = num * g_shareData.heroRepository[dataId].n32WCardNum - 1
			v.buyNum = buyNum
			self.units[v.uuid] =  v
		end
		self:sendCardData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards_rd", "addCard", self.account_id, v)
		
		--log record
		syslog.infof("op[%s]player[%s]:addCard:%d,%d,%d", op, self.account_id, dataId, num, buyNum)
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
		skynet.call (database, "lua", "cards_rd", "update", self.account_id, v, "count")
		
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
		skynet.call (database, "lua", "cards_rd", "update", self.account_id, v, "count")
		
		--log record
		syslog.infof("op[%s]player[%s]:delCardByUuid:%s,%d:dataId[%d]", op, self.account_id, uuid, num, v.dataId)
	end;
	--
	addPower = function(self, op, uuid, _power)
		if _power == 0 then return end
		local v = self:getCardByUuid(uuid)
		if not v then return end
		v.power = v.power + _power
		if v.power < 0 then
			v.power = 0
		end

		self:sendCardData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards_rd", "update", self.account_id, v, "power")
		
		--log record
		syslog.infof("op[%s]player[%s]:addPower:%s,%d:dataId[%d]", op, self.account_id, uuid, _power, v.dataId)
	end;
	--
	updateDataId = function(self, op, uuid, _dataId)
		local v = self:getCardByUuid(uuid)
		local oldDataId = v.dataId
		v.dataId = _dataId
		
		self:sendCardData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards_rd", "update", self.account_id, v, "dataId")
		
		--log record
		syslog.infof("op[%s]player[%s]:updateDataId:%s,dataId[%d][%d]", op, self.account_id, uuid, _dataId, oldDataId)
	end;
	--
	getBuyNum = function(self, uuid)
		local v = self:getCardByUuid(uuid)
		if v then return v.buyNum end
		return 0
	end;
	--
	addBuyNum = function(self, op, uuid, num)
		local v = self:getCardByUuid(uuid)
		v.buyNum = mClamp(v.buyNum+num, 0, math.maxinteger)
		
		self:sendCardData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards_rd", "update", self.account_id, v, "buyNum")
		
		--log record
		syslog.infof("op[%s]player[%s]:addBuyNum:%s,%d:%d", op, self.account_id, uuid, num, v.buyNum)
	
	end;
}

return CardsMethod
