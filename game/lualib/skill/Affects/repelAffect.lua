local vector3 = require "vector3"
local Affect = require "skill.Affects.Affect"
local repelAffect = class("repelAffect",Affect)
local transfrom = require "entity.transfrom"

function repelAffect:ctor(owner,source,data)
	print("repelAffect")
	self.super.ctor(self,owner,source,data)
	self.effectId = data[3] or 0
	self.distance = data[2] or 0
	self.speed = 6 
	self.effectTime = math.floor(1000 * self.distance / self.speed) 
	print("self.effectTime",self.effectTime)
end

function repelAffect:onEnter()
	self.super.onEnter(self)
	self.owner:setActionState(self.speed, ActionState.repel)
	local dir = vector3.create()
	--print("repel.onEnter",self.owner.serverId,self.source.serverId)
	dir:set(self.owner.pos.x,0,self.owner.pos.z)
	dir:sub(self.source.pos)
	--dir:set(self.source.pos.x,0,self.source.pos.z)
	--dir:sub(self.owner.pos)
	dir:normalize()
	dir:mul_num(self.distance)	
	local dst = vector3.create()
	dst:set(self.owner.pos.x,0,self.owner.pos.z)
	dst:add(dir)
	--print("dst==",dst.x,dst.z)
	--print("ownerpos ==",self.owner.pos.x,self.owner.pos.z)
        self.owner.targetPos = transfrom.new(dst,nil)  
end

function repelAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function repelAffect:onExit()
	print("repelAffect:onExit")
	self.owner:stand()
	self.super.onExit(self)
end

return repelAffect
