local Affect = require "skill.Affects.Affect"
local changeModAffect = class("changeModAffect",Affect)
function changeModAffect:ctor( entity,source,data )
	self.super.ctor(self,entity,source,data)
	self.effectTime = self.data[2] or 0 
	self.effectId = self.data[3] or 0
	self.control = bit_or(AffectState.NoMove,AffectState.NoSpell)
end

function changeModAffect:onEnter()
	self.super.onEnter(self)
	self.owner.affectState = bit_or(self.owner.affectState,self.control)
end

function changeModAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
		return
	end
end

function changeModAffect:onExit()
	self.super.onExit(self)
	self.owner.affectState = bit_and(self.owner.affectState,bit_not(self.control))
end

return changeModAffect
