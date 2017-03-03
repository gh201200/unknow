local vector3 = require "vector3"
local Affect = require "skill.Affects.Affect"
local loveAffect = class("loveAffect",Affect)

function loveAffect:ctor(owner,source,data,skillId)
	self.super.ctor(self,owner,source,data,skillId)
	self.effectId = data[3] or 0
	self.effectTime = data[2] or 0
	--self.control = bit_or(AffectState.NoAttack,AffectState.NoSpell) 
	self.effectTime = self.effectTime * 1000
	self.speed = 1 
end

function loveAffect:onEnter()
	self.super.onEnter(self)
	self.tgtPos = self.source.pos
	self.owner.targetPos = self.source
	local dir = vector3.create()
	dir:set(self.source.pos.x,0,self.source.pos.z)
	dir:sub(self.owner.pos)
	dir:normalize()
	local len  = vector3.len(self.owner.pos,self.source.pos) 
	local movLen = self.effectTime / 1000.0 * self.speed
	if len >= movLen then
		len = movLen
	end
	local dst = vector3.create()
	dst:set(dir.x,dir.y,dir.z)
	dst:mul_num(len)
	dst:add(self.owner.pos)
	if self.owner:getType() == "IMapPlayer"  then
		self.owner.triggerCast = true
		self.owner.ReadySkillId = self.owner:getCommonSkillId()
	end
	print("self.owner.pos",self.owner.pos.x,self.owner.pos.z)
	print("dst pos",dst.x,dst.z)

	local r = {id = self.owner.serverId,action = 0,dstX = math.floor(dst.x * 10000),
	dstZ = math.floor(dst.z * 10000) ,dirX = math.floor(dir.x * 10000) ,dirZ = math.floor(dir.z * 10000),speed = math.floor(self.speed * 10000)}
	g_entityManager:sendToAllPlayers("pushForceMove",r)
	self.owner:setActionState(self.speed, ActionState.loved)
end

function loveAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function loveAffect:onExit()
	--self.owner.affectState = bit_and(self.owner.affectState,bit_not(self.control))
	self.owner:stand()	
	self.super.onExit(self)
end

return loveAffect
