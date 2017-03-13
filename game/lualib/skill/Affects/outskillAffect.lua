local Affect = require "skill.Affects.Affect"
local outskillAffect = class("outskillAffect",Affect)

function outskillAffect:ctor(entity,source,data)
	self.super.ctor(self,entity,source,data)
	self.effectTime = self.data[2] or 0
	self.effectId = self.data[3]
	self.control = AffectState.OutSkill 
end

function outskillAffect:onEnter()
	self.super.onEnter(self)
	self.owner:addAffectState(self.control,1) 
end

function outskillAffect:onExec(dt)
	self.effectTime =  self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function outskillAffect:onExit()
	self.super.onExit(self)
	self.owner:addAffectState(self.control,-1) 
end

return outskillAffect
