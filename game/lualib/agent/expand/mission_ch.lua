local Mission = class("Mission")

local MissionType = {
	daily 		= 0,
	achivement 	= 1,
}

local GoalCon = {
	greater 	= bit(0),
	equal 		= bit(1),
	less		= bit(2)	 	
}

local user
local REQUEST = {}

function Mission:ctor()
	self.request = REQUEST
end

function Mission:init( u )
	user = u
end

function REQUEST.updateMissionData( args )
	local mission = user.missions:getMissionByDataId( args.dataId )
	user.missions:sendMissionData( mission )
end

function REQUEST.recvMissionAward( args )
	local unit = user.missions:getMissionByDataId( args.dataId )
	local dat = g_shareData.missionRepository[unit.id]
	
	local errorCode = 0
	repeat
		if not dat or not unit then
			errorCode = -1	--不存在的任务
			break
		end
		if user.missions.isMissionCompleted( unit ) == false then
			errorCode = 1	--任务未完成
			break
		end
		if dat.n32Type == MissionType.daily then
			if unit.flag > 0 then
				errorCode = -1	--奖励已经领取过了
				break
			end
		elseif dat.n32Type == MissionType.achivement then
			if unit.flag > unit.id then
				errorCode = -1	--成就已完成
				break
			end
		end
	until true
	
	if errorCode ~= 0 then
		return {errorCode = errorCode, dataId = args.dataId, ids = {}}
	end
	
	local ret = {errorCode = 0, dataId = args.dataId, ids = {}}
	--发送奖励
	unit.flag = unit.flag + 1
	user.missions:updateMission("recvMissionAward", unit)
	local items = {}
	if dat.n32Type == MissionType.daily then
		items = usePackageItem( Quest.Arena[user.level].DailyReward, user.level )
		for k, v in pairs(items) do
			table.insert(ret.ids, {x=k, y=v})
		end
	elseif dat.n32Type == MissionType.achivement then
		local st = string.split(dat.szAwards, ",")
		items[tonumber(st[1])] = tonumber(st[2])
	end
	user.servicecmd:addItems("recvMissionAward", items)

	return ret
end


return Mission.new()
