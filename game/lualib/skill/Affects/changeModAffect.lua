local Affect = require "skill.Affects.Affect"
local changeModAffect = class("changeModAffect",Affect)
function changeModAffect:ctor( entity,source,data )
	self.super.ctor(self,entity,source,data)
	self.effectTime = self.data[2] or 0 
	self.effectId = self.data[3] or 0
	self.control = bit_or(ControledState.NoMove,ControledState.NoSpell)
end

function changeModAffect:onEnter()
	self.super.onEnter(self)
	self.owner.controledState = bit_or(self.owner.controledState,self.control)
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
	self.owner.controledState = bit_and(self.owner.controledState,bit_not(self.control))
end

return changeModAffect
