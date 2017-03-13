local Affect = require "skill.Affects.Affect"
local vector3 = require "vector3"
local blinkAffect = class("blinkAffect",Affect)

function blinkAffect:ctor(entity,source,data,skillId)
	self.super.ctor(self,entity,source,data,skillId)
 --	self.distance = self.data[2] or 0
	self.effectTime = self.data[3] or 0
	self.effectId = self.data[4] or 0
	self.target = self.owner.targetPos 
	if self.target ~= nil then
		local pos = vector3.create(self.target.pos.x,0,self.target.pos.z)
		print("Pos:",pos.x,pos.z)
		print("owner.pos:",self.owner.pos.x,self.owner.pos.z)
		self.owner:onBlink(pos)
	end
end

function blinkAffect:onEnter()
	--强制设置目标位置
	self.super.onEnter(self)
end

function blinkAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function blinkAffect:onExit()
	self.owner:stand()
	self.super.onExit(self)
end

return blinkAffect
