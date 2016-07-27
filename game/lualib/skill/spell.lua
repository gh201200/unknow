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
	 --self.skillId = 0
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
	self.targets = {}
end
function spell:init(skilldata,skillTimes)
	self.skilldata = skilldata
	self.readyTime = skillTimes[1]
	self.castTime = skillTimes[2]
	self.endTime = skillTimes[3]
	self.triggerTime = skilldata.n32TriggerTime
	self.myEffectId = skilldata.n32MyEffect or 0  		 --自身绑定特效
	self.targetEffectId = skilldata.n32TargetEffect or 0  	 --目标位置特效
	self.targetEffectPos = nil				 --目标特效位置
end

function spell:canBreak(ms)
	if self:isSpellRunning() == false then return true end
	print("spell:canBreak")
	if ms == ActionState.move and self.status == SpellStatus.Ready then
		print("branking successful")
		self.source.cooldown:resetCd(self.skilldata.id,0) 	
		return true
	end
	if ms == ActionState.move and self.status == SpellStatus.End then 
		return true	
	end
	return false
end

function spell:breakSpell()
	if self.status == SpellStatus.Ready then
		--技能准备阶段被打断 不计入cd
		self.source.cooldown:resetCd(self.skilldata.id,0)
	elseif self.status == SpellStatus.Cast then
		--释放过程被打断
			
	elseif self.status == SpellStatus.End then
		--释放收尾被打断
			
	end
	
	--打断后 进入站立状态
	self.source:stand()
	self:clear()
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

--更新技能效果
function spell:advanceEffect(dt)
	if self.triggerTime >= 0  then 
		self.triggerTime = self.triggerTime - dt
		if self.triggerTime < 0 then
			--扣除蓝消耗
			--self.source:addMp(self.skilldata.n32MpCost,HpMpMask.SkillMp)
		--	触发目标效果
			local selfEffects = self.skilldata.szMyAffect
			if selfEffects ~= ""  then
				local targets = { self.source }
				self:trgggerAffect(selfEffects,targets)
			end
			
			local targetEffects = self.skilldata.szTargetAffect
			local targets = g_entityManager:getSkillAttackEntitys(self.source,self.skilldata)
			self.targets = targets
			if #targets ~= 0 and targetEffects ~= "" then
				self:trgggerAffect(targetEffects,targets)
			end
		end
		return
	end
end
--触发目标效果
function spell:trgggerAffect(datastr,targets)
	for _k,_v in pairs(targets) do
		_v.affectTable:buildAffects(self.source,datastr)
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
	--正在触发中 移除目标技能效果
	self.triggerTime = 0
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
