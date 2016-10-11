local vector3 = require "vector3"
local Affect = require "skill.Affects.Affect"
local flyAffect = class("flyAffect",Affect)
local transfrom = require "entity.transfrom"

function flyAffect:ctor(owner,source,data)
	self.super.ctor(self,owner,source,data)
	self.height = data[2] or 0
	self.floatingTime = data[3] or 0
	self.inteTime = data[4] or 0
	self.leftTime = data[5] or 0
	self.effectTime = data[5] or 0
	self.effectId = data[6] or 0
	self.stateChange = true
	self.effectTime = 3000
	self.leftTime = 3000
	self.upTime =  1000
	self.floatTime = 1000
	self.downTime = 1000
end
function flyAffect:onEnter()	
	self.super.onEnter(self)
	self.owner.curActionState = ActionState.forcemove	
	local pos = vector3.create(self.owner.pos.x,2,self.owner.pos.z)
	self.owner.target = transfrom.new(pos,nil)
end
function flyAffect:onExec(dt)
	self.leftTime = self.leftTime - dt
	if self.leftTime <= 0 then
		self:onExit(0)
	end
	self.upTime = self.upTime - dt
	if self.upTime < 0 then
		self.floatTime = self.floatTime -  dt
		if self.floatTime < 0 then
			local pos = vector3.create(self.owner.pos.x,0,self.owner.pos.z)
			self.owner.target = transfrom.new(pos,nil)
			self.downTime =  self.downTime - dt	
		end
	end
end	

function flyAffect:onExit()
	self.owner.curActionState = ActionState.move	
	self.super.onExit(self)
end

return flyAffect
