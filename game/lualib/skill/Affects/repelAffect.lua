local Affect = require "skill.Affects.Affect"
local repelAffect = class("repelAffect",Affect)

function repelAffect:ctor(entity,source,data)
	super.ctor(self,entity,source,data)
end

function repelAffect:onEnter()
	super:onEnter()
	self.effectId = self.data[3]
	self.distance = self.data[2] or 0
	self.speed = 2
	self.effectTime = self.distance / self.speed 
	--人物速度增加
	
end

function repelAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function repelAffect:onExit()
	--人物速度移除
	super:onExit()
end

