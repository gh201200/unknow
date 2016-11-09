--local transfrom = require "entity.transfrom"
local vector3 = require "vector3"
local transfrom = require "entity.transfrom"
local IflyObj = class("IflyObj" , transfrom)
local Map = require "map.Map"
require "globalDefine"

function IflyObj.create(...)
	return  IflyObj.new(...)
end

function IflyObj:ctor(src,tgtPos,skilldata)
	self.source = src
	self.target = tgtPos
	--print("IflyObj pos",src.pos.x,src.pos.z)
	self.pos = vector3.new(0,0,0)
	self.pos:set(src.pos.x,0,src.pos.z)
	self.skilldata = skilldata	
	local effectdata = g_shareData.effectRepository[skilldata.n32CubeEffect]
--	self.radius = effectdata.n32Redius / 10000.0
	self.radius = skilldata.n32Radius / 10000.0
	self.dir = vector3.new(0,0,0)
	self.dir:set(self.target.pos.x, 0, self.target.pos.z)
        self.dir:sub(self.pos)
        self.dir:normalize()
	self.moveSpeed = effectdata.n32speed
	self.targets = {}
	self.lifeTime = effectdata.n32time / 1000.0
	self.entityType = EntityType.flyObj 
	self.maxAtkNum = 3 --最大攻击数量
	local t = {effectId = skilldata.n32CubeEffect,serverId = src.serverId,dirx = self.dir.x,dirz = self.dir.z}
	g_entityManager:sendToAllPlayers("emitFlyObj",t)	
end
local dst = vector3.new(0,0,0)	
function IflyObj:update(dt)
	dt = dt / 1000.0
	self.lifeTime = self.lifeTime - dt
	dst:set(self.dir.x, self.dir.y, self.dir.z)
        dst:mul_num(self.moveSpeed * dt)
        dst:add(self.pos)
--	print("update",self.moveSpeed,dt,dst.x,dst.z,Map:get(dst.x, dst.z))
	self.pos:set(dst.x, 0, dst.z)
	--print("--------------------------begin-------------------------------------------------")
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
	
end
return IflyObj
