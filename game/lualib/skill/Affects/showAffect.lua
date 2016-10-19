local Affect = require "skill.Affects.Affect" 
local showAffect = class("showAffect",Affect)

function showAffect:ctor(entity,source,data)
	self.super.ctor(self,entity,source,data) 
	self.effectTime = data[2] or 0
	self.effectId = data[3] or 0 
	self.leftTime = self.effectTime
end

function showAffect:onEnter()
	self.super.onEnter(self)
end

function showAffect:onExec(dt)
	self.leftTime = self.leftTime - dt
	if self.leftTime <= 0 then
		self:onExit()
	end
end

function showAffect:onExit()
	self.super.onExit(self)
end

return showAffect
