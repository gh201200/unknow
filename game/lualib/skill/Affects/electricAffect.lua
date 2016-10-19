local Affect = require "skill.Affects.Affect"
local electricAffect = class("elecricAffect",Affect)

function electricAffect:ctor(entity,source,data,root,index)
	self.super.ctor(self,entity,source,data)
	print("electricAffect:ctor",self.owner.serverId,self.source.serverId)
	print("data",self.data)
	self.atkMul = {}
	self.atkMul[1] = self.data[2] or 0
	self.atkMul[2] = self.data[3] or 0
	self.atkMul[3] = self.data[4] or 0
	self.tgts = {}
	self.triggerTime = self.data[5] or 0
	self.radius = 3
	self.effectTime = self.data[6] or 0
	self.effectId = self.data[7] or 0
	self.root = root 
	if self.root == nil then
		self.root = self.source
	end
	self.index = index or 1 
end

function electricAffect:onEnter()
	self.super.onEnter(self)
	if self.root == self.source then
		local src = self.owner
		self.tgts[self.owner.serverId] = 1
		for i=1,2,1 do
			local tgt = self:findNearTgt(src)
			if tgt == nil then break end
			self.tgts[tgt.serverId] = 1
			local aff = electricAffect.new(tgt,src,self.data,self.root,i+1)
			tgt.affectTable:addAffectSyn(aff)
			src =  tgt
		end
	end
	local dem = self.atkMul[self.index] * self.root:getAttack()  -  self.owner:getDefence() 
	if dem <= 0 then dem = 1 end
	self.owner:addHp(-dem,HpMpMask.SkillHp, self.root)
end
function electricAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function electricAffect:onExit()
	self.super.onExit(self)
end

function electricAffect:findNearTgt(src)
	for i=#g_entityManager.entityList, 1, -1 do
		local v = g_entityManager.entityList[i]
		if v:isKind(self.root) == false and  self.tgts[v.serverId] == nil then
		 	local dis = self.owner:getDistance(v)
			if self.radius >= dis then
				return v
			end
		end
	end
	return nil
end
return electricAffect
