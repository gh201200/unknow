local Affect = require "skill.Affects.Affect"
local blinkAffect = class("blinkAffect",Affect)

function blinkAffect:ctor(entity,source,data)
	self.super.ctor(self,entity,source,data)
	self.distance = self.data[2] or 0
	self.effectTime = self.data[3] or 0
	self.effectId = self.data[4] or 0
	self.target = self.source:getTarget()
end

function blinkAffect:onEnter()
	--强制设置目标位置
	self.super.onEnter(self)
	local distance  = self.distance --闪现距离
	local vec = self.owner.dir:return_mul_num(distance)
	local  des = self.owner.pos:return_add(vec)
	self.owner:onBlink(des)
end

function blinkAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function blinkAffect:onExit()
	self.super.onExit(self)
end

return blinkAffect
