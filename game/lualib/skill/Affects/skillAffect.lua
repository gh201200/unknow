local Affect = require "skill.Affects.Affect"
local skillAffect = class("skillAffect",Affect)

function skillAffect:ctor(entity,source,data,skillId)
	self.super.ctor(self,entity,source,data,skillId)
	self.triggerTime = data[5] or 0 
	self.leftTime = data[6] or 0
	self.effectId = data[7] or 0
	self.effectTime = self.leftTime 
--	self.projectId = skillId * 100000 + self.effectId
end
function skillAffect:onEnter()	
	self.super.onEnter(self)
	self:calAffect()
	if self.triggerTime  == 0 then
		--瞬发伤害
		self:calAffect()
		self:onExit()
		return
	end
	
end
function skillAffect:onExec(dt)
	self.leftTime = self.leftTime -  dt
	if self.leftTime <= 0 then
		self:onExit()		
		return
	end
	self.triggerTime = self.triggerTime - dt
	if self.triggerTime <= 0 then
		self.triggerTime = self.data[5]
		self:calAffect()
	end
end

function skillAffect:onExit()
	self.super.onExit(self)
end

function skillAffect:calAffect()
	local r = self:getAttributeValue(self.data)
	if self.data[1] == "damage" then
		local demage = r - self.owner:getDefence()
		local skilldata = g_shareData.skillRepository[self.skillId]
		--普通攻击
		if skilldata.n32SkillType == 0 then	
			if math.random(0,100) < 100 * self.source:getBaojiRate() then
				demage = demage * self.source:getBaojiTimes()
			end
		end
		demage = self.owner:getUpdamage() * demage 
		local shieldValue = self.owner:getShield()
		if shieldValue > demage then
			self.owner:addMidShield(-demage)
		else
			self.owner:addMidShield(-shieldValue)
			demage = demage - shieldValue
		end
		self.owner:calShield()
		self.owner:addHp(-demage,HpMpMask.SkillHp, self.source)	
		
	elseif self.data[1] == "curehp" then
		self.owner:addHp(r,HpMpMask.SkillHp, self.source)
	elseif self.data[1] == "curemp" then	
		self.owner:addMp(r,HpMpMask.SkillMp, self.source)
	elseif self.data[1] == "burnmp" then	
		self.owner:addMp(r,HpMpMask.SkillMp, self.source)
	end
end

return skillAffect
