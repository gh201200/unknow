local vector3 = require "vector3"
local Affect = require "skill.Affects.Affect"
local chargeAffect = class("chargeAffect",Affect)
local transfrom = require "entity.transfrom"
require "globalDefine" 

function chargeAffect:ctor(owner,source,data,skillId)
	print("chargeAffect",data)
	self.super.ctor(self,owner,source,data)
	self.effectId = data[3] or 0
	--self.distance = data[2] or 0
	self.speed = 9 -- 冲锋速度
	--self.skilldata = self.owner.spell.skilldata
	local tgt = self.source
	self.distance = self.owner:getDistance(tgt) 
	self.effectTime = math.floor(1000 * self.distance / self.speed) 
	self.tgtPos = vector3.create(tgt.pos.x,0,tgt.pos.z)
	self.radius = 0.1 --self.skilldata.n32Radius / 10000
	--self.tgtBuff = self.skilldata.szTargetAffect
	self.target = tgt
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
	--self.owner.spell:enterChannel(self.effectTime)
	self.owner:setActionState(self.speed, ActionState.chargeing) --冲锋状态
end

function chargeAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
	--[[
	print("chargeAffect exec",dt)
	for i=#g_entityManager.entityList, 1, -1 do
		local v = g_entityManager.entityList[i]
		if self.targets[v.serverId] == nil and v.serverId ~= self.source.serverId then
			--if self.owner:isKind(v) == false then
			local dis = self.owner:getDistance(v)
			if dis <= self.radius and v.serverId ~= nil then
				self.targets[v.serverId] = 1
				v.affectTable:buildAffects(self.owner,self.tgtBuff,self.skillId)
			end	
			--end
		end	 
	end
	]]--
end

function chargeAffect:onExit()
	--self.owner:stand()
	
	self.super.onExit(self)
end

return chargeAffect
