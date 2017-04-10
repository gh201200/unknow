local Affect = require "skill.Affects.Affect"
local addskillAffect = class("addskilAffect",Affect)

function addskillAffect:ctor(owner,source,data,skillId)
	self.super.ctor(self,owner,source,data,skillId)
	self.newSkillId = data[2]
	if data[3] == -1 then
		self.effectTime = 99999999--math.maxinteger
	else
		self.effectTime = data[3] * 1000
	end
	self.effectId = data[4] or 0
end

function addskillAffect:onEnter()
	print("addskillAffect:onEnter")
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
	print("addskillAffect:onExit remove=",self.newSkillId)
	self.super.onExit(self)
	self.owner:removeSkill(self.newSkillId,false)
end

return addskillAffect
