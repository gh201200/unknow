--local transfrom = require "entity.transfrom"
local vector3 = require "vector3"
local transfrom = require "entity.transfrom"
local IflyObj = class("IflyObj" , transfrom)
local Map = require "map.Map"
require "globalDefine"

function IflyObj.create(...)
	return  IflyObj.new(...)
end

function IflyObj:ctor(src,tgt,skilldata)
	self.source = src
	self.target = tgt
	self.pos = vector3.new(0,0,0)
	self.pos:set(src.pos.x,0,src.pos.z)
	self.skilldata = skilldata	
	self.effectdata = g_shareData.effectRepository[skilldata.n32CubeEffect]
	self.radius = skilldata.n32Radius / 10000.0
	self.dir = vector3.new(0,0,0)
	self.dir:set(self.target.pos.x, 0, self.target.pos.z)
        self.dir:sub(self.pos)
        self.dir:normalize()
	self.moveSpeed = self.effectdata.n32speed
	self.targets = {}
	self.lifeTime = self.effectdata.n32time / 1000.0
	self.entityType = EntityType.flyObj 
	self.maxAtkNum = 3 --最大攻击数量
	--追人特效
	if self.effectdata.n32type == 4 then	
		self.lifeTime = 1
	end
	
	local t = {effectId = skilldata.n32CubeEffect,serverId = src.serverId,targetId = 0,dirx = self.dir.x,dirz = self.dir.z}
	if self.target:getType() ~= "transform" then
		t.targetId = self.target.serverId
	end
	g_entityManager:sendToAllPlayers("emitFlyObj",t)	
end
local dst = vector3.new(0,0,0)	

function IflyObj:getTarget()
	return self.target
end

function IflyObj:setTarget(t)
	self.target = t
end
function IflyObj:update(dt)
	dt = dt / 1000.0
	if self.effectdata.n32type == 4 then
		self:updateTarget(dt)
	else
		self:updateNoTarget(dt)
	end
end

function IflyObj:updateNoTarget(dt)
	self.lifeTime = self.lifeTime - dt
	dst:set(self.dir.x, self.dir.y, self.dir.z)
        dst:mul_num(self.moveSpeed * dt)
        dst:add(self.pos)
	self.pos:set(dst.x, 0, dst.z)
	for i=#g_entityManager.entityList, 1, -1 do
                local v = g_entityManager.entityList[i]
		if v:getType() ~= "transform" then
			if self.targets[v.serverId] == nil and v.serverId ~= self.source.serverId then
				local dis = self:getDistance(v)
				if dis <= self.radius  then	
					--添加buff
					self.targets[v.serverId] = 1
					v.affectTable:buildAffects(self.source,self.skilldata.szTargetAffect)	
				end
			end				
		end
	end
	--print("--------------------------end-------------------------------------------------")
end

function IflyObj:updateTarget(dt)
	if self.target == nil  then 
		self.lifeTime = -1
		return 
	end
	self.dir:set(self.target.pos.x, 0, self.target.pos.z)
	self.dir:sub(self.pos)
        self.dir:normalize()
	dst:set(self.dir.x, self.dir.y, self.dir.z)
        dst:mul_num(self.moveSpeed * dt)
	dst:add(self.pos)
	self.pos:set(dst.x,0,dst.z)
	local dis = self:getDistance(self.target)
	if dis <= self.radius then
		self.target.affectTable:buildAffects(self.source,self.skilldata.szTargetAffect,self.skilldata.id)
		self.lifeTime = -1
	end
end
return IflyObj
