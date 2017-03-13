local Affect = require "skill.Affects.Affect"
local nodeadAffect = class("nodeadAffect",Affect)

function nodeadAffect:ctor(entity,source,data)
	self.super.ctor(self,entity,source,data)
	self.effectTime = self.data[2] or 0
	self.effectId = self.data[3]
	self.control = AffectState.NoDead 
end

function nodeadAffect:onEnter()
	self.super.onEnter(self)
	self.owner:addAffectState(self.control,1)
end

function nodeadAffect:onExec(dt)
	self.effectTime =  self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function nodeadAffect:onExit()
	self.super.onExit(self)
	self.owner:addAffectState(self.control,-1)
end

return nodeadAffect
