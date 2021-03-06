local Ientity = require "entity.Ientity"
local PetAI = require "ai.PetAI"
local Map = require "map.Map"
local passtiveSpell =  require "skill.passtiveSpell"
local IPet = class("IPet", Ientity)
require "globalDefine"
function IPet:ctor(pos,dir)
	IPet.super.ctor(self,pos,dir)
end


function IPet:init(pt,master)
	self.pt = pt 
	self.master = master
	self.entityType = EntityType.pet
	if pt.n32Type == 2 then
		self.entityType = EntityType.building
	end
	if pt.n32Type ==  3 then
		self.pt.n32CommonSkill = master.attDat.n32CommonSkillId 
		self.pt.modolId = master.modelDat.id
	end
	if pt.n32Type == 4 then
		self.entityType = EntityType.trap
	end
	self.ai = PetAI.new(self,master)
	self.camp =  master.camp
	self.lifeTime = 0
	self.bornPos:set(self.pos.x, 0, self.pos.z)
	self.attDat = {}
        self:calcStats()
	if pt.n32Type == 3 then
	 	self:setHp(math.floor(self:getHpMax() * self.master:getHp() / self.master:getHpMax()))
	 	self:setMp(math.floor(self:getMpMax() * self.master:getMp() / self.master:getMpMax()))
	else
        	self:setHp(self:getHpMax())
        	self:setMp(self:getMpMax())
	end
        self.HpMpChange = true
        self.StatsChange = true
	self.modelDat = g_shareData.heroModelRepository[self.pt.modolId]
	self.lifeTime = self.pt.n32LifeTime * 1000 --存活时间
	self.isbody = 0
	IPet.super.init(self)
	self:setPos(self.pos.x,0,self.pos.z)
	for i=1,3,1 do
		local skillId = pt["n32Skill0" .. i]
		if skillId ~= 0 then
			local skilldata = g_shareData.skillRepository[skillId]	
			if skilldata.n32Active == 1 then
				self.cooldown:addItem(skillId)
				for i=#(self.spell.passtiveSpells),1,-1 do
					local v = self.spell.passtiveSpells[i]
					if v.skilldata.n32SeriId == skilldata.n32SeriId then
						--移除旧的被动技能
						v:onDead()
						table.remove(self.spell.passtiveSpells,i)
					end
				end
			end	
			local ps = passtiveSpell.new(self,skilldata,self.lifeTime)
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
	self.attDat.n32RecvHp = 0
	self.attDat.n32RecvMp = 0
	
	if self.pt.n32Type == 3 then
		self.attDat.n32MainAtt = self.master.attDat.n32MainAtt
	end
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
			self:setReadySkillId(skillId)
			return
		end	
	end
	if attackId ~= 0 then
		local cd =  self.cooldown:getCdTime(attackId)
		if cd <= 0 then
			self:setReadySkillId(attackId)
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
	g_entityManager:sendToAllPlayers("killEntity", {sid=self.serverId})
	for i=#(self.spell.passtiveSpells),1,-1 do
		local v = self.spell.passtiveSpells[i]
		v:onDead()
		table.remove(self.spell.passtiveSpells,i)
	end
	IPet.super.onDead(self)
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
