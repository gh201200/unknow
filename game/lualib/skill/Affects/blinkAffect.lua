local Affect = require "skill.Affects.Affect"
local blinkAffect = class("blinkAffect",Affect)

function blinkAffect:ctor(entity,source,data)
	self.super.ctor(self,entity,source,data)
	self.distance = self.data[2] or 0
	self.effectId = self.data[3]
	self.effectTime = 1000
	
	self.effectId = 100002
	self.distance = 1
end

function blinkAffect:onEnter()
	--强制设置目标位置
	self.super.onEnter(self)	
	local distance  = 2 --闪现距离
	local vec = self.owner.dir:return_mul_num(distance)
	local  des = self.owner.target.pos--self.owner.pos:return_add(vec)
	self.owner:onForceMove(des)
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
