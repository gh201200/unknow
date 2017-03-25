local Affect = require "skill.Affects.Affect"
local vector3 = require "vector3"
local blinkAffect = class("blinkAffect",Affect)

function blinkAffect:ctor(entity,source,data,skillId,extra)
	self.super.ctor(self,entity,source,data,skillId)
	--1目标点去闪 2敌人最近单位去闪
	self.distance = self.data[2] or 0
	self.effectTime = 1 
	self.effectId = self.data[4] or 0
	self.target = extra 
	if self.target ~= nil then
		local pos = vector3.create(self.target.pos.x,0,self.target.pos.z)
		local dis = self.owner:getDistance(self.target)
		if dis > self.distance then
			self.dir = vector3.create(self.target.pos.x,0,self.target.pos.z)
			self.dir:sub(self.owner.pos)
			self.dir:normalize()	
			self.dir:mul_num(self.distance)
			self.owner:onBlink(self.dir)
		else
			self.owner:onBlink(pos)
		end
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
