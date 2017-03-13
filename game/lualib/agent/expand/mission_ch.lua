local Mission = class("Mission")

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
	print( args )
	local unit = user.missions:getMissionByDataId( args.dataId )
	local dat = g_shareData.missionRepository[args.dataId]
	
	local errorCode = 0
	repeat
		if not dat or not unit then
			errorCode = -1	--不存在的任务
			break
		end
	
		if dat.n32Type == DEF.MissionType.daily then
			if user.missions.isMissionCompleted( unit ) == false then
				errorCode = 1	--任务未完成
				break
			end
			if unit.flag > 0 then
				errorCode = -1	--奖励已经领取过了
				break
			end
		elseif dat.n32Type == DEF.MissionType.achivement then
			if unit.flag > unit.dataId then
				errorCode = -1	--成就已完成
				break
			end
			
			if user.missions.isMissionCompleted( unit ) == false and unit.flag == unit.dataId then
				errorCode = 1	--任务未完成
				break
			end

		end
	until true
	
	if errorCode ~= 0 then
		return {errorCode = errorCode, dataId = args.dataId, ids = {}}
	end
	
	local ret = {errorCode = 0, dataId = args.dataId, ids = {}}
	--发送奖励
	local items = {}
	if dat.n32Type == DEF.MissionType.daily then
		items = usePackageItem( Quest.Arena[user.level].DailyReward, user.level )
		for k, v in pairs(items) do
			table.insert(ret.ids, {x=k, y=v})
		end
	elseif dat.n32Type == DEF.MissionType.achivement then
		local awardDat = g_shareData.missionRepository[unit.flag]
		local st = string.split(awardDat.szAwards, ",")
		items[tonumber(st[1])] = tonumber(st[2])
	end
	user.servicecmd.addItems("recvMissionAward", items)

	unit.flag = unit.flag + 1
	user.missions:updateMission("recvMissionAward", unit)
	return ret
end


return Mission.new()

