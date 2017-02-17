local skynet = require "skynet"
local syslog = require "syslog"
local uuid = require "uuid"

----------------cards func---------------------
local CardsMethod = 
{
	--
	initCard = function(_dataId)
		local cardDat = g_shareData.heroRepository[_dataId]
		local card = 
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
		local index = 0
		for k, v in pairs(Quest.AutoGainSkills) do
			local skillDat = g_shareData.skillRepository[v]
			if bit_and(cardDat.n32Camp, skillDat.n32Faction) ~= 0 then
				card["skill"..index] = Macro_GetSkillSerialId(v)
				index = index + 1
			end
		end
		return card
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
		if num == 0 then return end
		if not num then num = 1 end
		local serId = Macro_GetCardSerialId(dataId)
		local v = self:getCardBySerialId( serId )
		if v then	--already has the kind of card
			v.count = mClamp(v.count + g_shareData.heroRepository[dataId].n32CCardNum * num, 0, math.maxint32)
		else
			v = self.initCard(dataId)
			if Macro_GetCardColor(dataId) == 0 then
				v.count = mClamp(num * g_shareData.heroRepository[dataId].n32CCardNum, 0, math.maxint32)
			else
				v.count = mClamp((num-1) * g_shareData.heroRepository[dataId].n32CCardNum, 0, math.maxint32)
			end
			self.units[v.uuid] =  v
		end
		self:sendCardData( v )
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards", "update", self.account_id, v)
	
		--推进任务
		agentPlayer.missions:AdvanceMission(Quest.MissionContent.GetCard)	
		--log record
		syslog.logmy("card", {opt=op,account=self.account_id,cardId=dataId,cardNum=num,uuid=v.uuid})
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
		syslog.logmy("card", {opt=op,account=self.account_id,cardId=dataId,cardNum=num,uuid=v.uuid})
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
		syslog.logmy("card", {opt=op,account=self.account_id,cardId=v.dataId,cardNum=num,uuid=v.uuid})
	end;
	--
	updateDataId = function(self, op, uuid, _dataId)
		local v = self:getCardByUuid(uuid)
		local oldDataId = v.dataId
		v.dataId = _dataId
		
		self:sendCardData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "cards", "update", self.account_id, v, "dataId")
		
		--推进任务
		agentPlayer.missions:AdvanceMission(Quest.MissionContent.GetCard)	
		--log record
		syslog.logmy("card", {opt=op,account=self.account_id,cardId=v.dataId,cardNum=v.dataNum,uuid=v.uuid})
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
	end;
}

return CardsMethod
