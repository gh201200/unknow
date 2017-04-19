local Affect = require "skill.Affects.Affect"
local changeatkAffect = class("addskilAffect",Affect)

function changeatkAffect:ctor(owner,source,data,skillId)
	self.super.ctor(self,owner,source,data,skillId)
	self.newCommonId = data[2]
	self.effectTime = data[3] * 1000
	self.effectId = data[4] or 0
	self.oldCommonSkill = self.owner:getCommonSkill()
end

function changeatkAffect:onEnter()
	self.super.onEnter(self)
	self.owner:setCommonSkill(self.newCommonId)
end

function changeatkAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end	
end


function changeatkAffect:onExit()
	self.owner:setCommonSkill(self.oldCommonSkill)
	if  self.owner:getReadySkillId() == self.newCommonId then
		self.owner:setReadySkillId(self.oldCommonSkill)
	end
	self.super.onExit(self)
end

return changeatkAffect
