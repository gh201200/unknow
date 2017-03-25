local Affect = require "skill.Affects.Affect"
local addskillAffect = class("addskilAffect",Affect)

function addskillAffect:ctor(owner,source,data,skillId)
	print("addskillAffect:ctor==")
	self.super.ctor(self,owner,source,data,skillId)
	self.newSkillId = data[2]
	self.effectTime = data[3] * 1000
	self.effectId = data[4] or 0
end

function addskillAffect:onEnter()
	self.super.onEnter(self)
	self.owner:addSkill(self.newSkillId,self.effectTime,false)
end

function addskillAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end	
end


function addskillAffect:onExit()
	self.super.onExit(self)
end

return addskillAffect
