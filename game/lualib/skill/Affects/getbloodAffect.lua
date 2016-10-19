local Affect = require "skill.Affects.Affect"
local getbloodAffect = class("getbloodAffect",Affect)

function getbloodAffect:ctor(owner,source,data)
	self.super.ctor(self,owner,source,data)
	self.effectId = data[4] or 0
	self.mul = data[2] or 0
	self.val = data[3] or 0 
	local effectdata = g_shareData.effectRepository[self.effectId] 
	self.effectTime = 0
	if effectdata ~= nil then
		self.effectTime = effectdata.n32time
	end
end

function getbloodAffect:onEnter()
	self.super.onEnter(self)
	print("getbloodAffect:onEnter")
	local demage = self:calDemage()
	--扣血
	self.owner:addHp(demage, HpMpMask.SkillHp, self.source)
	--吸血
	self.source:addHp(-demage, HpMpMask.SkillHp, self.source)
end

function getbloodAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	self.owner.setTargetVar(self.source)
	if self.effectTime < 0 then
		self:onExit()
	end
end

function getbloodAffect:onExit()
	self.super.onExit(self)
end

function getbloodAffect:calDemage()
	local apDem = self.mul * self.source:getAttack() + self.val -  self.owner:getDefence() 
	if apDem < 0 then apDem  = 1 end
	return -apDem
end
return getbloodAffect
