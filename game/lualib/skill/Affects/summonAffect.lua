local Affect = require "skill.Affects.Affect" 
local summonAffect = class("summonAffect",Affect)
local vector3 = require "vector3"
local Map = require "map.Map"
require "globalDefine"

function summonAffect:ctor(entity,source,data,skillId)
	self.super.ctor(self,entity,source,data) 
	self.petId = data[2] or 0
	self.petNum = data[3] or 0
	--if self.petId == 0 then
		--召唤分身体
	--	self.petId = self.source.modelDat.id
	--end
	self.effectId =  0
	self.effectTime = 0
end

function summonAffect:onEnter()
	self.super.onEnter(self)
	local isbody = 0
	for i = 1,self.petNum,1 do
		print("self.petNum",self.petNum)
		local pos = self:randomPos(self.source)
		g_entityManager:createPet(self.petId,self.source,pos,isbody)	
	end
end

function summonAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime <= 0 then
		self:onExit()
	end
end

function summonAffect:onExit()
	self.super.onExit(self)
end

function summonAffect:randomPos(master)
	local pts = {}
	local minx,maxx,minz,maxz = master.pos.x,master.pos.x,master.pos.z,master.pos.z
	local  dis = 1
	local t = {{dis,0},{-dis,0},{0,dis},{0,-dis},{dis,dis},{dis,-dis},{-dis,dis},{-dis,-dis}}
	local lt = {}
	local dstx = 0
	local dstz  = 0
	for _k,_v in pairs(t) do
		dstx = master.pos.x + _v[1]
		dstz = master.pos.z + _v[2]
		if Map:get(dstx,dstz) == 0 then
			table.insert(lt,_v)
		end
	end
	local i = math.random(1,#lt)
		
	local pos = vector3.create(master.pos.x + lt[i][1],0,master.pos.z + lt[i][2])
	return pos
end

return summonAffect
