local vector3 = require "vector3"
local Affect = require "skill.Affects.Affect"
local chargeAffect = class("chargeAffect",Affect)
local transfrom = require "entity.transfrom"
require "globalDefine" 

function chargeAffect:ctor(owner,source,data,skillId)
	print("chargeAffect",data)
	self.super.ctor(self,owner,source,data)
	self.effectId = data[3] or 0
	self.speed = 6 -- 冲锋速度
	self.skilldata = g_shareData.skillRepository[skillId] 
	local tgt = self.owner:getTarget()
	local dst = vector3.create()
	dst:set(tgt.pos.x,0,tgt.pos.z)
	local dst_tf = transfrom.new(dst,nil)
	self.distance = self.owner:getDistance(dst_tf) 
	self.effectTime = math.floor(1000 * self.distance / self.speed) 
	self.tgtPos = vector3.create(tgt.pos.x,0,tgt.pos.z)
	self.radius = 0.1 --self.skilldata.n32Radius / 10000
	self.targetId = tgt.serverId
end

function chargeAffect:onEnter()
	self.super.onEnter(self)
	local dir = vector3.create()
	dir:set(self.tgtPos.x,0,self.tgtPos.z)
	dir:sub(self.owner.pos)
	dir:normalize()
	dir:mul_num(self.distance)
	local dst = vector3.create()
	dst:set(self.owner.pos.x,0,self.owner.pos.z)
	dst:add(dir)
	print("self.owner.pos",self.owner.pos.x,self.owner.pos.z)
	print("dst pos",dst.x,dst.z)
		
	local tf = transfrom.new(dst,nil)
	self.owner.targetPos = tf
	--进入持续施法状态
	print("effectTime",self.effectTime)
	local r = {id = self.owner.serverId,action = 0,dstX = math.floor(self.tgtPos.x * 10000),
	dstZ = math.floor(self.tgtPos.z * 10000) ,dirX = math.floor(dir.x * 10000) ,dirZ = math.floor(dir.z * 10000),speed = math.floor(self.speed * 10000)}
	g_entityManager:sendToAllPlayers("pushForceMove",r)
	self.owner:setActionState(self.speed, ActionState.chargeing) --冲锋状态
end

function chargeAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end
function chargeAffect:onExit()
	local target = g_entityManager:getEntity(self.targetId)
	if target ~= nil and target:getHp() > 0 then
		local targets = {}
		table.insert(targets,target)
		self.source.spell:trgggerAffect(self.skilldata.szAffectTargetAffect,targets,self.skilldata)
	end
	self.super.onExit(self)
end

return chargeAffect
