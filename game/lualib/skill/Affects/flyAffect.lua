local Affect = require "skill.Affects.Affect"
local flyAffect = class(Affect,"flyAffect")

function flyAffect:ctor(owner,source,data)
	super.ctor(self,owner,source,data)
	self.height = data[2] or 0
	self.floatingTime = data[3] or 0
	self.inteTime = data[4] or 0
	self.leftTime = data[5] or 0
	self.effectTime = data[5] or 0
	self.effectId = data[6] or 0
	self.speedY = 1.0
end
function flyAffect:onEnter()	
	self.super.onEnter(self)
end
function flyAffect:onExec(dt)
	self.leftTime = self.leftTime - dt
	if self.leftTime <= 0 then
		self:onExit(0)
	end
	self.speedY
end	

function flyAffect:onExit()
	self.super.onExit(self)
end
