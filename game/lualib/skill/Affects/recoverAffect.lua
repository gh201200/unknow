local Affect = require "skill.Affects.Affect"
local recoverAffect = class("recoverAffect",Affect)
 
function recoverAffect:ctor(entity,source,data)
	self.super.ctor(self,entity,source,data)
	self.triggerTime = 0
	self.leftTime = data[5] or 0
	self.effectId = data[6] or 0
	self.effectTime = data[5] or 0	
end

function recoverAffect:onEnter()
	self.super.onEnter(self)
	if self.data[4] == nil or self.data[5] == nil or self.data[5] == 0 then
	--瞬发效果
		self:calRecover()
		self:onExit()
                return		
	end
end

function recoverAffect:onExec(dt)
	self.leftTime  = self.leftTime - dt
	self.effectTime = self.leftTime
	if self.leftTime <= 0 then
		self:onExit()
		return
	end
	self.triggerTime = self.triggerTime - dt
	if self.triggerTime <= 0 then
	--	self.triggerTime = self.data[3]
	--	self:calRecover()
	end
end

function recoverAffect:onExit()
	self.super.onExit(self)
end

function recoverAffect:calRecover()
	assert(self.data and self.data[1])
	local rateA = self.data[2] or 0
	local rateB = self.data[3] or 0
	local val = rateA * self.source:getAttack() + rateB * self.source:getZhili()
	
	if self.data[1] == "curehp" then
		self.owner:addHp(val,HpMpMask.SkillHp)
	elseif self.data[1] == "curemp" then
		self.owner:addMp(val,HpMpMask.SkillHp)
	end
end

return recoverAffect
