local Affect = require "skill.Affects.Affect"
local invincibleAffect = class("invincibleAffect",Affect)

function invincibleAffect:ctor(entity,source,data)
	print("invincibleAffect=====")
	self.super.ctor(self,entity,source,data)
	self.effectTime = self.data[2] or 0
	self.effectTime = self.effectTime * 1000
	self.effectId = self.data[3]
	self.control = AffectState.Invincible 
end

function invincibleAffect:onEnter()
	self.super.onEnter(self)
	self.owner:addAffectState(self.control,1)
end

function invincibleAffect:onExec(dt)
	self.effectTime =  self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function invincibleAffect:onExit()
	self.super.onExit(self)
	self.owner:addAffectState(self.control,-1)
end

return invincibleAffect
