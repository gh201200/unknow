local Ientity = require "entity.Ientity"
local PetAI = require "ai.PetAI"
local Map = require "map.Map"
local IPet = class("IPet", Ientity)
require "globalDefine"
function IPet:ctor(pos,dir)
	IPet.super.ctor(self,pos,dir)
end


function IPet:init(pt,master)
	self.pt = pt 
	self.master = master
	table.insert(self.master.pets,self)
	self.entityType = EntityType.pet
	self.ai = PetAI.new(self,master)
	self.camp = master.camp
	self.lifeTime = 0
	self.bornPos:set(self.pos.x, 0, self.pos.z)
	self.attDat = {}
        self:calcStats()
        self:setHp(self:getHpMax())
        self:setMp(self:getMpMax())
        self.HpMpChange = true
        self.StatsChange = true
	self.modelDat = g_shareData.heroModelRepository[self.pt.modolId]
	self.lifeTime = 30*1000 --存活时间
end

function IPet:getType()
	return "IPet"
end

function IPet:calcStats()
	self.attDat.n32Hp = self.master:getHpMax()
	self.attDat.n32Mp = self.master:getMpMax()
	self.attDat.n32Attack = self.master:getAttack()
	self.attDat.n32Defence = self.master:getDefence()
	self.attDat.n32ASpeed = self.master:getASpeed()
	self.attDat.n32MSpeed = self.master:getMSpeed()
	self.attDat.n32AttackRange = self.master:getAttackRange()	
	self.attDat.n32LStrength = 0
	self.attDat.n32LZhili = 0
	self.attDat.n32LMinjie = 0
	self.attDat.n32MainAtt = 0
	
	local funs = {"HpMaxPc","HpMax","AttackPc","Attack","DefencePc","Defence","ASpeed","MSpeedPc","MSpeed","AttackRangePc","AttackRange"}
	for _k,_v in pairs(funs) do
		local f = self["add" .. _v]
		if f ~= nil then
			print("add" .. _v)
			f(self.pt[_v])
		end
	end
	
	self:calcHpMax()
	self:calcMpMax()
	self:calcAttack()
	self:calcDefence()
	self:calcASpeed()
	self:calcMSpeed()
	self:calcAttackRange()
end

function IPet:preCast()
	local tgt = self:getTarget()
	local skillId = 0
	local attackId = self.pt.n32CommonSkill
	if self.spell:isSpellRunning() == true then return end 
	if tgt:getType() ~= "IBuilding" and  skillId ~= 0 then
		local cd = self.cooldown:getCdTime(skillId)
		if cd <= 0 then
			--释放技能
			self.ReadySkillId = skillId
			return
		end	
	end
	if attackId ~= 0 then
		local cd =  self.cooldown:getCdTime(attackId)
		if cd <= 0 then
			self.ReadySkillId = attackId
		end
	end
end

function IPet:update(dt)
	if self:getHp() <= 0 then return end
	self.lifeTime = self.lifeTime - dt
	if self.lifeTime <= 0 then
		self:setHp(-1)
		self:onDead()
	end
	self.ai:update(dt)
	IPet.super.update(self,dt)

end
function IPet:onDead()
	IPet.super.onDead(self)
	g_entityManager:sendToAllPlayers("killEntity", {sid=self.serverId})
	
	--response to agent
	for k, v in pairs(self.coroutine_response) do
		for p, q in pairs(v) do
			q(true, nil)
		end
	end
	self.coroutine_response = {}

	--reset map
	Map:add(self.pos.x, self.pos.z, -1)
end
return IPet
