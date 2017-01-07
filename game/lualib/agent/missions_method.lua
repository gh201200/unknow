local skynet = require "skynet"
local Quest = require "quest.quest"
local Time = require "time"

MissionType = {
	daily           = 0,                               
        achivement      = 1,
}
   
GoalCon = {                                          
	greater         = bit(0),                          
        equal           = bit(1),
        less            = bit(2)                           
}


----------------skills func---------------------
local MissionsMethod = 
{
	--
	initMission = function(_dataId)
		return {id=_dataId, progress=0, flag=0,time=0,}
	end;
	--
	getMissionBySerialId = function(self, _serId)
		if self:isDailyMission( _serId ) then
			return self:getDailyMission()
		end
		return self.units[_serId]
	end;
	--
	getMissionByDataId = function(self, _dataId)
		local _serId = Macro_GetMissionSerialId(_dataId)
		return self:getMissionBySerialId( _serId )
	end;
	--
	getAchivementsNum = function(self)
		local cnt = 0
		for k, v in pairs(self.units) do
			if g_shareData.missionRepository[v.id].n32Type == MissionType.achivement then
				cnt = cnt + 1
			end
		end
		return cnt
	end;

	--
	addMission = function(self, op, _dataId)
		local v = self.initMission(_dataId)
		local _serId = Macro_GetMissionSerialId(_dataId)
		self.units[_serId] =  v
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "missions", "add", self.account_id, v)
	end;
	--
	updateMission = function(self, op, v)
		local dat = g_shareData.missionRepository[v.id]
		if dat.n32Type == MissionType.achivement then
			if self.isMissionCompleted( v ) then
				dat = g_shareData.missionRepository[v.id + 1]
				if dat then
					v.id = dat.id		
				end
			end
		end

		self:sendMissionData( v )	
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "missions", "add", self.account_id, v)
	end;
	--
	getDailyMission = function(self)
		local _serId = Macro_GetMissionSerialId(Quest.DailyMissionId)
		if self.units[_serId].time < os.time() then
			self:resetDailyMission() 
		end
		return self.units[_serId]
	end;
	--
	resetDailyMission = function(self)
		local _serId = Macro_GetMissionSerialId(Quest.DailyMissionId)
		local v = self.units[_serId]
		v.time = os.time(Time.nextDay(Quest.DailyResetTime))
		v.flag = 0
		v.progress = 0
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "missions", "add", self.account_id, v)
	end;
	--
	isDailyMission = function( _serId )
		return _serId == Macro_GetMissionSerialId( Quest.DailyMissionId )
	end;
	--
	isMissionCompleted = function( unit )
		local dat = g_shareData.missionRepository[unit.id]
		if dat.n32Type == MissionType.achivement then
			if unit.flag < unit.id then return true end
		end

		if dat.n32GoalCon ~= 0 then
			if bit_and(GoalCon.greater, dat.n32GoalCon) then
				if unit.progress > dat.n32Goal then return true end
			end
			if bit_and(GoalCon.equal, dat.n32GoalCon) then
				if unit.progress == dat.n32Goal then return true end
			end
			if bit_and(GoalCon.less, dat.n32GoalCon) then
				if unit.progress < dat.n32Goal then return true end
			end
		else
			if unit.progress == dat.n32Goal then return true end
		end
		return false
	end;
	--
	AdvanceMission = function(self, content, ...)
		local unit = nil
		for k, v in pairs(self.units) do
			if g_shareData.missionRepository[k].n32content == content then
				unit = v
				break
			end
		end
		if not unit then return end
		
		local ret = self[Advance.."_"..content](v, ...)
		if ret then
			self:updateMission("AdvanceMission", unit)
		end
	end;
	
}
--none
function MissionsMethod:Advance_1001(unit, ...)
	unit.progress = unit.progress + 1
	return true
end
--none
function MissionsMethod:Advance_1002(unit, ...)
	local missionDat = g_shareData.missionRepository[unit.id]
	local cnt = 0
	for k, v in pairs(agentPlayer.cards.units) do
		local color = Macro_GetCardColor( v.dataId )
		if color >= missionDat.n32Con1 then
			cnt = cnt + 1	
		end
	end
	if unit.progress ~= cnt then
		unit.progress = cnt
		return true
	end
	return false
end
--none
function MissionsMethod:Advance_1003(unit, ...)
	local missionDat = g_shareData.missionRepository[unit.id]
	local cnt = 0
	for k, v in pairs(agentPlayer.skills.units) do
		local grade = Macro_GetSkillGrade( v.dataId )
		if grade >= missionDat.n32Con1 then
			cnt = cnt + 1	
		end
	end
	if unit.progress ~= cnt then
		unit.progress = cnt
		return true
	end
	return false

end
--skill dataId
function MissionsMethod:Advance_1004(unit, ...)
	local dataId = ...
	local missionDat = g_shareData.missionRepository[unit.id]
	local dat = g_shareData.skillrepository[dataId]
	if dat.n32Quality == missionDat.n32Con1 then
		if dat.n32Upgrade >= missionDat.n32Goal then
			unit.progress = missionDat.n32Goal 
			return true
		end 
	end
	return false
end
--hero dataId
function MissionsMethod:Advance_1005(unit, ...)
	local dataId = ...
	local missionDat = g_shareData.missionRepository[unit.id]
	local serId = Macro_GetCardSerialId( dataId )
	if serId == missionDat.n32Con1 then
		unit.progress = unit.progress + 1
		return true
	end
	return false
end
--kill number
function MissionsMethod:Advance_1006(unit, ...)
	local num =  ...
	if num > 0 then
		unit.progress = unit.progress + num
		return true
	end
	return false
end
--die number
function MissionsMethod:Advance_1007(unit, ...)
	local num =  ...
	if num > 0 then
		unit.progress = unit.progress + num
		return true
	end
	return false
end

return MissionsMethod
