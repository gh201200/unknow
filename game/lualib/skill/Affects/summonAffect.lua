local Affect = require "skill.Affects.Affect" 
local summonAffect = class("summonAffect",Affect)
local vector3 = require "vector3"
local Map = require "map.Map"
require "globalDefine"

function summonAffect:ctor(entity,source,data,skillId)
	self.super.ctor(self,entity,source,data) 
	self.petId = data[2] or 0
	self.petNum = data[3] or 0
	if self.petId == 0 then
		--召唤分身体
		self.petId = self.source.modelDat.id
	end
	self.effectId =  0
	self.effectTime = 0
end

function summonAffect:onEnter()
	self.super.onEnter(self)
	local isbody = 0
	if self.petId == self.source.modelDat.id then
		--召唤分身
		local pos = self:randomPos(self.source)
		self.source:onBlink(pos)
		isbody = 1
	end	

	for _k,_v in pairs(self.source.pets) do
		_v.lifeTime = -1 --杀死召唤怪物
	end
	self.source.pets = {}
	for i = 1,self.petNum,1 do
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
	if Map.legal(minx-1,master.pos.z) == true then
		minx = minx - 1
	end 	
	if Map.legal(maxx + 1,master.pos.z) == true then
		maxx =  maxx + 1
	end 
	if Map.legal(master.pos.x,minz-1) == true then
		minz = minz - 1
	end
	if Map.legal(master.pos.x,maxz+1) == true then
		maxz = maxz + 1
	end
	local rdx = math.random(math.ceil(minx*10000),math.ceil(maxx*10000)) / 10000
	local rdz = math.random(math.ceil(minz*10000),math.ceil(maxz*10000)) / 10000
	local pos = vector3.create(rdx,0,rdz)
	return pos
end

return summonAffect
