local Stats = require "skill.Stats"
local Buff = require "skill.Buff"
local Repository = require "Repository"
local syslog = require "syslog"

local BuffTable = class("buffTable")
function BuffTable:ctor()
	
	self.srcEntity = nil
	self.Refresh = false
	self.fixedBuffList = {}			--fixed buff
	self.buffList = {}			--skill buff,system buff; need be advanced
	self.Stats = Stats.new()		--final stats
	self.Summation = Stats.new()		--all stats, not plus done
end

function BuffTable:dump()
	print("dump fix buff list are: ")
	for i=#self.fixedBuffList, 1, -1 do
		print(i .. " : buff id = "..self.fixedBuffList[i].buffData.id) 
	end
	print("dump buff list are : ")
	for i=#self.buffList, 1, -1 do
		print(i .. " : buff id = "..self.buffList[i].buffData.id .. ", remain time = " .. self.buffList[i].remainTime .. ", remain times =" .. self.buffList[i].remainTimes)
	end
end

function BuffTable:addBuffById(buffId, cnt, src, origin)
	if cnt < 0 then
		self:removeBuffById(buffId, -cnt, src)
		return 
	end
	local buffdata =  Repository.getData("buffRep", buffId)
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
			if not bit_and(buffdata.n32Flags, Buff.Flags.ReplaceUpper) and v.buffData.level > buffdata.level  then
				return false
			end
			if bit_and(buffdata.n32Flags , Buff.Flags.StopReplaceSame) then
				return false
			end
			local oldCount = v.Count 
			v.Count = mClamp(v.Count + cnt, 0, buffdata.n32LimitCount)
			self.Summation.add(v.Stats, v.Count-oldCount)
			
			if not bit_and(buffdata.n32Flags , Buff.Flags.NotRefresh) then
				v.remainTimes = buffdata.n32LimitTimes
				v.remainTime = buffdata.n32LimitTime
			end		
			self.Refresh = true
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

	self.Refresh = true
end

function BuffTable:removeBuffByIndex(index, cnt, src)
	local v = self.buffList[index]
	if not v then
		syslog.warningf("removeBuffByInDex[%d][%d] is nil", index, cnt)
		return
	end
	local reminCnt = v.Count - cnt
	if reminCnt > 0 then
		self.Summation:add(v.Stats, -cnt)	
		v.Count = reminCnt
	else
		self.Summation:add(v.Stats, -v.Count)
		table.remove(self.buffList, index)
		
		self:onTriggerRemove(v, src)
	end
	self.Refresh = true
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
	for i = #self.buffList, 1, -1 do 
		local v = self.buffList[i]
		local ret = v:process(self.srcEntity, dt)
		if not ret then
			self:removeBuffByIndex(i, v.Count)
		end
	end
	self:calculateStats()
end

function BuffTable:onTriggerAdd(buff, src, origin)
end

function BuffTable:onTriggerRemove(buff, src)
end
local hp_r, mp_r
function BuffTable:calculateStats(isCalcStats)
	if isCalcStats then
		self.Summation:plusDone()
		self.Stats:init(self.Summation)
	elseif self.Refresh then
		hp_r = self.Stats.n32Hp
		mp_r = self.Stats.n32Mp
		self.Stats:Calc(self.Summation)
		self.Stats.n32Hp = hp_r
		self.Stats.n32Mp = mp_r
	end
	self.Refresh = false
end

return BuffTable
