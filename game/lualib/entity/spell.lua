--local vector3 = require "vector3"
local skynet = require "skynet"
local spell = class("spell")

require "globalDefine"

local SpellStatus = {
	None 		= 0,	--无
	Begin 		= 1, 	--开始
	Ready 		= 2,	--吟唱
	Cast 		= 3,	--释放
	ChannelCast 	= 4,	--持续施法
	End 		= 5,	--结束
}

local SpellTriggerStatus = {
	None		= 0,	--
	Begin		= 1,	--触发开始
	Trigger		= 2,	--触发状态
	End		= 3,	--结束状态
}
local spellEffect = {
	["ap"] = {1.0,1000,100,1000,"effect1"}
}

function spell:ctor(entity)
	print("spell:ctor()")
	self.skillId = 0
	self.source = entity
	self.targets = {}
	self.status = SpellStatus.None
	self.triggerStatus = SpellTriggerStatus.None
	self.skilldata = {}	

	self.readyTime = 0 	 --施法前摇
	self.castTime = 0	 --施放中
	self.endTime = 0	 --施法后摇
	
	self.triggerTime = -1 
	self.errorCode = ErrorCode.None 
	self.castingTime = 0

	self.effects = {}	--技能效果表
end
function spell:init(skilldata)
	self.triggerTime = skilldata.n32DemageTime
end
function spell:Breaking(ms)
	print("spell:breaking")
	--ready状态可以被主动被动打断，打算后不计入cd和消耗
	--cast状态 主动不可打断 被动打断，依然计入cd和消耗
	--end 主动和被动打断后 依然生效
	if ms == ActionState.move and self.status == SpellStatus.Ready then
		self.status = SpellStatus.None
		print("branking successful")
		self.source.cooldown.resetCd(self.skillId,0) 	
		return true
	end
	if ms == ActionState.move and self.status == SpellStatus.End then 
		self.status = SpellStatus.None
		return true	
	end
	
	return false
end
function spell:isSpellRunning()
	return self.status ~= SpellStatus.None
end
function spell:update(dt)
	if self:isSpellRunning() == false then return end --技能不推进
	if self.status == SpellStatus.Ready then
		self.readyTime =  self.readyTime - dt
		self:onReady()
	elseif self.status == SpellStatus.Cast then
		self.castTime =  self.castTime - dt
		self:onCast()
	elseif self.status == SpellStatus.ChannelCast then
		self:onChannelCast()
	elseif self.status == SpellStatus.End then
		self.endTime =  self.endTime - dt
		self:onEnd()
	end
	--推进技能效果	
	self:advanceEffect(dt)
end
function spell:triggerEffect(type,effect)
	--计算触发的目标玩家
	local targets = g_entityManager:getSkillAttackEntitys(self.source,self.skilldata)	
	for _i,_target in pairs(targets) do
		if _type == "ap" then	
			local apdemValue = effect["rate"] * self.source.Stats.n32AttackPhy + effect["value"] - _target.Stats.n32DefencePhy
			print("triggerEffect",skynet.now,apdemValue)
		end
	end

end
--更新技能效果
function spell:advanceEffect(dt)
	if self.triggerTime >= 0  then 
		self.triggerTime = self.triggerTime - dt
		return
	end
	for _k,_v in pairs(self.effects) do
		if _v["lasttime"] ~= nil  then
			if _v["ticks"] == nil then _v["ticks"] = _v["inteval"] end
			if _v["runningTime"] == nil then _v["runningTime"] = _v["lasttime"]
				_v["ticks"] = _v["ticks"] - dt
				--触发效果
				self:triggerEffect(_k,_v)
				--判断最终时间
				_v["runningTime"] = _v["runningTime"] - dt
				if _v["runningTime"] <= 0 then self.effects[_k] = {} end
			end
		end
	end
end
function spell:onBegin()
	print("onBegin",skynet.now(),self.readyTime,self.castTime,self.endTime)
	if self.readyTime > 0 then
		print("onReady",skynet.now())
		self.status = SpellStatus.Ready
	else
		self.status = SpellStatus.Cast
	end
end
function spell:onReady()
	if self.readyTime < 0 then
		print("onCast",skynet.now())
		self.status = SpellStatus.Cast
	end

end
function spell:clear()
	self.status = SpellStatus.None
	self.errorCode = ErrorCode.None
	self.readyTime = 0
	self.castTime = 0
	self.endTime = 0 
end
function spell:onCast()
	if self.castTime < 0 then
		print("onEnd",skynet.now())
		self.status = SpellStatus.End
	end
end

function spell:onEnd()
	if self.endTime < 0 then
		print("onNone",skynet.now())
		self.status = SpellStatus.None
	end

end
function spell:Cast(skillid,target,pos)
	self.skilldata = g_shareData.skillRepository[skillid]
	assert(self.skilldata)
	self.targets = {} --清空目标列表
	if self.skilldata.bNeedTarget == true then
		target = target or self.source.target
		self.targets = {target}
	end
	self:onBegin()
end
return spell
