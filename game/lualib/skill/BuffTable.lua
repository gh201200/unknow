local Stats = require "skill.Stats"
local Buff = require "skill.Buff"
local syslog = require "syslog"

local BuffTable = class("buffTable")
function BuffTable:ctor(src)
	
	self.srcEntity = src
	self.Refresh = false			--update stats
	self.RefreshSet = false			--update buff list
	self.fixedBuffList = {}			--fixed buff
	self.buffList = {}			--skill buff,system buff; need be advanced
	self.Stats = Stats.new()		--final stats
	self.Summation = Stats.new()		--all stats, not plus done
	self.effectMask = 0
end

function BuffTable:dump()
	print("begin dump buff table====================================")
	print("dump fix buff list are: ")
	for i=#self.fixedBuffList, 1, -1 do
		print(i .. " : buff id = "..self.fixedBuffList[i].buffData.id) 
	end
	print("dump buff list are : ")
	for i=#self.buffList, 1, -1 do
		print(i .. " : buff id = "..self.buffList[i].buffData.id .. ", remain time = " .. self.buffList[i].remainTime .. ", remain times =" .. self.buffList[i].remainTimes)
	end
	print("end dump buff table=======================================")
end

function BuffTable:addBuffById(buffId, cnt, src, origin)
	if cnt < 0 then
		self:removeBuffById(buffId, -cnt, src)
		return 
	end
	local buffdata = g_shareData["buffRep"][buffId]
	if not buffdata then
		syslog.warningf("add buff[%d] is null", buffId)
		return 
	end

	if not src then
		src = self.srcEntity
	end
	
	local witchTable = nil
	if origin then 
		if origin == Buff.Origin.Equip then
			witchTable = self.fixedBuffList
		elseif origin == Buff.Origin.Skill then
			witchTable = self.buffList
		end
	else
		 witchTable = self.buffList
	end
	if not witchTable then return nil end
	for i = #witchTable, 1, -1 do
		local v = witchTable[i]
		if v.buffData.seriesId == buffdata.seriesId then
			if not bit_and(buffdata.n32Flags, Buff.Flags.ReplaceUpper) > 0 and v.buffData.level > buffdata.level  then
				return false
			end
			if bit_and(buffdata.n32Flags , Buff.Flags.StopReplaceSame) > 0 then
				return false
			end
			local oldCount = v.Count 
			v.Count = mClamp(v.Count + cnt, 0, buffdata.n32LimitCount)
			if bit_and(buffdata.n32Flags, Buff.Flags.CalcStats) > 0 then
				self.Summation.add(v.Stats, v.Count-oldCount)
				self.Refresh = true
			end
			if bit_and(buffdata.n32Flags , Buff.Flags.NotRefresh) == 0 then
				v.remainTimes = buffdata.n32LimitTimes
				v.remainTime = buffdata.n32LimitTime
			end		
			self.RefreshSet = true
			return
		end
	end
	if cnt <= 0 then return end
	local buff = Buff.new()
	buff.buffData = buffdata
	buff.srcEntity = src
	buff.Count = cnt
	buff.Stats:init(buffdata)
	buff.remainTimes = buffdata.n32LimitTimes
	buff.remainTime = buffdata.n32LimitTime
	table.insert(witchTable, #witchTable+1, buff)

	self.Summation:add(buff.Stats, cnt)
	self:onTriggerAdd(buff, src, origin)

	self.RefreshSet = true
end

function BuffTable:removeBuffByIndex(index, cnt, src)
	local v = self.buffList[index]
	if not v then
		syslog.warningf("removeBuffByInDex[%d][%d] is nil", index, cnt)
		return
	end
	local reminCnt = v.Count - cnt
	if reminCnt > 0 then
		if bit_and(v.buffData.n32Flags, Buff.Flags.CalcStats) > 0 then
			self.Summation:add(v.Stats, -cnt)	
			self.Refresh = true
		end
		v.Count = reminCnt
	else
		if bit_and(v.buffData.n32Flags, Buff.Flags.CalcStats) > 0 then
			self.Summation:add(v.Stats, -v.Count)
			self.Refresh = true
		end
		table.remove(self.buffList, index)
		
		self:onTriggerRemove(v, src)
	end
	self.RefreshSet = true
end

function BuffTable:removeBuffById(buffId, cnt)
	for i=#self.buffList, 1, -1 do 
		local v = self.buffList[i]
		if v.id == buffId then
			self:removeBuffByIndex(i, cnt)
			break
		end
	end
end

function BuffTable:update(dt)
	self.effectMask = 0
	for i = #self.buffList, 1, -1 do 
		local v = self.buffList[i]
		local ret = v:process(self.srcEntity, dt)
		if not ret then
			self:removeBuffByIndex(i, v.Count)
		else
			self.effectMask = self.effectMask | v.buffData.n32Effect
		end
	end
	self:calculateStats()
end

function BuffTable:onTriggerAdd(buff, src, origin)
end

function BuffTable:onTriggerRemove(buff, src)
end

function BuffTable:calculateStats(isCalcStats)
	if isCalcStats then
		self.Summation:plusDone()
		self.Stats:copy(self.Summation)
	elseif self.Refresh then
		local hp_r = self.Stats.n32Hp
		local mp_r = self.Stats.n32Mp
		self.Stats:Calc(self.Summation)
		self.Stats.n32Hp = hp_r
		self.Stats.n32Mp = mp_r
	end
	if self.Refresh then
		self.srcEntity:advanceEventStamp(EventStampType.Stats)
		self.Refresh = false
	end
	if self.RefreshSet then 
		self.srcEntity:advanceEventStamp(EventStampType.Buff)
		self.RefreshSet = false
	end
end

return BuffTable
