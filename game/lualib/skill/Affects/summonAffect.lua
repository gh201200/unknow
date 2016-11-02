local Affect = require "skill.Affects.Affect" 
local summonAffect = class("summonAffect",Affect)
require "globalDefine"

function summonAffect:ctor(entity,source,data)
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
	
	for _k,_v in pairs(self.source.pets) do
		_v.lifeTime = -1 --杀死召唤怪物
	end
	self.source.pets = {}
	for i = 1,self.petNum,1 do
		g_entityManager:createPet(self.petId,self.source)	
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

return summonAffect
