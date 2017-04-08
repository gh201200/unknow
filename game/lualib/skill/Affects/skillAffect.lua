local Affect = require "skill.Affects.Affect"
local skillAffect = class("skillAffect",Affect)

function skillAffect:ctor(entity,source,data,skillId)
	self.super.ctor(self,entity,source,data,skillId)
	self.triggerTime = data[5] or 0 
	self.leftTime = data[6] or 0
	if self.triggerTime ~= 0 then
		--持续触发
		self.triggerTime = -1
	end
	--self.triggerTime * 1000
	self.leftTime = self.leftTime * 1000
	self.effectId = data[7] or 0
	self.effectTime = self.leftTime
	--self.projectId = skillId * 100000 + self.effectId
end
function skillAffect:onEnter()	
	self.super.onEnter(self)
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
		self.triggerTime = self.data[5] * 1000
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
			self.source:resetBaoji()	
		end
		demage = self.owner:getUpdamage() * demage 
		--伤害计算 分身特殊处理
		if self.owner:getType() == "IPet" and self.owner.pt.n32Type == 3 then
			demage = demage * self.owner.pt.HurtPc
		end
		if self.source:getType() == "IPet" and self.source.pt.n32Type == 3 then
			demage = demage * self.source.pt.DamagePc 
		end
		local shieldValue = self.owner:getShield()
		if shieldValue > demage then
			self.owner:addMidShield(-demage)
		else
			self.owner:addMidShield(-shieldValue)
			demage = demage - shieldValue
		end
		self.owner:calShield()
		if demage > self.owner:getHp() and self.owner:getType() == "IMapPlayer" then
			--复活
			self.owner.spell:onTriggerPasstives(6)
		end
		self.owner:addHp(-demage,HpMpMask.SkillHp, self.source)	
	elseif self.data[1] == "curehp" then
		self.owner:addHp(r,HpMpMask.SkillHp, self.source)
	elseif self.data[1] == "curemp" then	
		self.owner:addMp(r,HpMpMask.SkillMp, self.source)
	elseif self.data[1] == "burnmp" then	
		self.owner:addMp(-r,HpMpMask.SkillMp, self.source)
	end
end

return skillAffect
