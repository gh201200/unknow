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
	self.isbody = 0
	self.petType = 0--召唤物类型
	IPet.super.init(self)
	for i=1,3,1 do
		local skillId = pt["n32Skill0" .. i]
		if skillId ~= 0 then
			local skilldata = g_shareData.skillRepository[skillId]	
			if skilldata.n32Active == 1 then
				for i=#(self.spell.passtiveSpells),1,-1 do
				local v = self.spell.passtiveSpells[i]
				if v.skilldata.n32SeriId == skilldata.n32SeriId then
					--移除旧的被动技能
					v:onDead()
					table.remove(self.spell.passtiveSpells,i)
				end
			end	
			local ps = passtiveSpell.new(self,skilldata)
			table.insert(self.spell.passtiveSpells,ps)
		end
	end
end

function IPet:getType()
	return "IPet"
end

function IPet:calcStats()
	self.attDat.n32Hp = self.pt["HpMax"] 
	self.attDat.n32Mp = self.pt["MpMax"]
	self.attDat.n32Attack = self.pt["Attack"]
	self.attDat.n32Defence = self.pt["Defence"]
	self.attDat.n32ASpeed = self.pt["Aspeed"]
	self.attDat.n32MSpeed = self.pt["Mspeed"]
	self.attDat.n32AttackRange = 0	
	self.attDat.n32LStrength =  0 
	self.attDat.n32LIntelligence = 0
	self.attDat.n32LAgility = 0
	self.attDat.n32MainAtt = 0
	self.attDat.n32Strength = self.master:getStrength() * self.pt["StrPc"] + self.pt["Str"]  
	self.attDat.n32Intelligence = self.master:getIntelligence() * self.pt["IntPc"] + self.pt["Int"]
	self.attDat.n32Agility = self.master:getAgility() * self.pt["AglPc"] + self.pt["Agl"]
		
	self:calcStrength()
	self:calcIntelligence()
	self:calcAgility()
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
	Map:add(self.pos.x, self.pos.z, 0, self.modelDat.n32BSize)
end
return IPet
