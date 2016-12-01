local Affect = require "skill.Affects.Affect"
local vector3 = require "vector3"
local blinkAffect = class("blinkAffect",Affect)

function blinkAffect:ctor(entity,source,data,skillId)
	self.super.ctor(self,entity,source,data,skillId)
 --	self.distance = self.data[2] or 0
	self.effectTime = self.data[3] or 0
	self.effectId = self.data[4] or 0
	self.target = source 
	print("self.owner:",self.owner.serverId)
	print("self.target:",self.target.serverId)
end

function blinkAffect:onEnter()
	--强制设置目标位置
	self.super.onEnter(self)
	--local distance  = self.distance --闪现距离
	--local vec_len = self.owner.pos:return_sub(self.target.pos)
	--local len = vec_len:length()
	--if len <= distance then
	--print("pos===",self.target.pos.x,self.target.pos.z)
	local pos = vector3.create(self.target.pos.x,0,self.target.pos.z)
	self.owner:onBlink(pos)
	--return
	--end
	--vec_len:normalize()
	--local vec = vec_len:return_mul_num(-distance)
	--local  des = self.owner.pos:return_add(vec)
	--self.owner:onBlink(des)
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
