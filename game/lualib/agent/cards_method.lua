local skynet = require "skynet"
local syslog = require "syslog"
local uuid = require "uuid"

----------------cards func---------------------
local CardsMethod = 
{
	--
	initCard = function(self, _dataId)
		return {uuid = uuid.gen(), dataId = _dataId, power=100, count=0,}
	end;
	--
	geCardBySerialId = function(self, _serId)
		for k, v in pairs(self.cards.units) do
			if v and Macro_GetCardSerialId(v.dataId) == _serId then
				return v
			end
		end
		return nil
	end;
	--
	getCardByUuid = function(self, _uuid)
		return self.cards.units[_uuid]
	end;
	--
	addCard = function(self, dataId, num)
		if not num then num = 1 end
		local v = self:getCardSerialId(Macro_GetCardSerialId(dataId))
		if v then	--already has the kind of card
			v.count = v.count + g_shareData.heroRepository[dataId].n32WCardNum * num
		else
			v = self.initCard(dataId)
			self.cards.units[v.uuid] =  v
		end
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards_rd", "addCard", self.account_id, v)
		
		--log record
		syslog.infof("player[%s]:addCard:%d", self.account_id, dataId)
	end;
	--
	delCardByDataId = function(self, dataId, num)
		if num == 0 then return end
		local v = self:getCardBySerialId(Macro_GetCardSerialId(dataId))
		if not v then return end
		if v.count < num then return end
		v.count = v.count - num

		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards_rd", "updateCard", self.account_id, v, "count")
		
		--log record
		syslog.infof("player[%s]:delCardByDataId:%d,%d", self.account_id, dataId, num)
	end;
	--
	delCardByUuid = function(self, uuid, num)
		if num == 0 then return end
		local v = self:getCardByUuid(uuid)
		if not v then return end
		if v.count < num then return end
		v.count = v.count - num

		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards_rd", "updateCard", self.account_id, v, "count")
		
		--log record
		syslog.infof("player[%s]:delCardByUuid:%s,%d:dataId[%d]", self.account_id, uuid, num, v.dataId)
	end;
	--
	addPower = function(self, uuid, _power)
		if _power == 0 then return end
		local v = self:getCardByUuid(uuid)
		if not v then return end
		v.power = v.power + _power
		if v.power < 0 then
			v.power = 0
		end

		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards_rd", "update", self.account_id, v, "power")
		
		--log record
		syslog.infof("player[%s]:addPower:%s,%d:dataId[%d]", self.account_id, uuid, _power, v.dataId)
	end;
}

return CardsMethod
