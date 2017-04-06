local vector3 = require "vector3"
local Affect = require "skill.Affects.Affect"
local repelAffect = class("repelAffect",Affect)
local transfrom = require "entity.transfrom"

function repelAffect:ctor(owner,source,data)
	self.super.ctor(self,owner,source,data)
	self.effectId = data[3] or 0
	self.distance = data[2] or 0
	self.speed = 6 
	self.effectTime = math.floor(1000 * self.distance / self.speed)
	if self.source == nil then
		self.source = self.owner
	end 
end

function repelAffect:onEnter()
	self.super.onEnter(self)
	if self.owner:getHp() <= 0 then
		self:onExit()
		return
	end
	self.owner:setActionState(self.speed, ActionState.repel)
	local dir = vector3.create()
	print("repel.onEnter",self.owner.serverId,self.source.serverId)
	if self.owner == self.source then
		dir:set(-self.owner.dir.x,0,-self.owner.dir.z)
	else
		dir:set(self.owner.pos.x,0,self.owner.pos.z)
		dir:sub(self.source.pos)
	end
	dir:normalize()
	dir:mul_num(self.distance)	
	local dst = vector3.create()
	dst:set(self.owner.pos.x,0,self.owner.pos.z)
	dst:add(dir)
	print("dst==",dst.x,dst.z)
	print("ownerpos ==",self.owner.pos.x,self.owner.pos.z)
	
         local r = {id = self.owner.serverId,action = 0,dstX = math.floor(dst.x * 10000),
         dstZ = math.floor(dst.z * 10000) ,dirX = math.floor(dir.x * 10000) ,dirZ = math.floor(dir.z * 10000),speed = math.floor(self.speed * 10000)}
	g_entityManager:sendToAllPlayers("pushForceMove",r)  
	self.owner.targetPos = transfrom.new(dst,nil)  
	self.owner:setActionState(self.speed, ActionState.chargeing) --冲锋状态
end

function repelAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function repelAffect:onExit()
	--self.owner:stand()
	self.super.onExit(self)
end

return repelAffect
