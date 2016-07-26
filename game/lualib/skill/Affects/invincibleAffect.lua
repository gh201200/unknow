local Affect = require "skill.Affects.Affect"
local invincibleAffect = class("invincibleAffect",Affect)

function invincibleAffect:ctor(entity,source,data)
	self.super.ctor(self,entity,source,data)
	self.effectTime = self.data[2] or 0
	self.effectId = self.data[3]
end

function invincibleAffect:onEnter()
	self.super.onEnter(self)
end

function invincibleAffect:onExec(dt)
	self.effectTime =  self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function invincibleAffect:onExit()
	self.super.onExit(self)
end

return invincibleAffect
