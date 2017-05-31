local Ientity = require "entity.Ientity"
local vector3 =require "vector3"
local EntityManager = require "entity.EntityManager"
local Map = require "map.Map"
local HateList = require "ai.HateList" 
local NpcAI = require "ai.NpcAI"
local passtiveSpell = require "skill.passtiveSpell"
local IBuilding = class("IBuilding", Ientity)

function IBuilding.create(camp, mapDat)
	local monster = IBuilding.new()
	
	monster.serverId = assin_server_id()
	monster.camp = camp

	monster:init(mapDat)

	return monster
end


function IBuilding:ctor()
	IBuilding.super.ctor(self)
	self.entityType = EntityType.building	
	self.heroTable = {}
	self.recvHpMpCD = {}
	self.ai = NpcAI.new(self)
	register_class_var(self, "PreSkillData", nil)
end

function IBuilding:getType()
         return "IBuilding"
end

function IBuilding:init(mapDat)
	local aid = mapDat.n32RedMonsterId
	if self.camp == CampType.BLUE then
		aid = mapDat.n32BlueMonsterId
	end
	self.attDat = g_shareData.monsterRepository[aid]
	self.modelDat = g_shareData.heroModelRepository[self.attDat.n32ModelId]
	self:calcStats()
	self:setHp(self:getHpMax())
	self:setMp(self:getMpMax())
	self.HpMpChange = true
	self.StatsChange = true
	
	IBuilding.super.init(self)
	for _k,_v in pairs(self.attDat.szSkill) do
		local skilldata = g_shareData.skillRepository[_v]
		if skilldata and skilldata.n32Active == 1 then
			self.cooldown:addItem(_v) 
			for i=#(self.spell.passtiveSpells),1,-1 do
				local v = self.spell.passtiveSpells[i]
				if v.skilldata.n32SeriId == skilldata.n32SeriId then
					--移除旧的被动技能
					v:onDead()
					table.remove(self.spell.passtiveSpells,i)
				end
			end
		end
		local ps = passtiveSpell.new(self,skilldata,math.maxinteger)
		table.insert(self.spell.passtiveSpells,ps)
	end
	if self.camp == CampType.BLUE then
		self:setPos(mapDat.szBlueHomePos[1]/GAMEPLAY_PERCENT, 0, mapDat.szBlueHomePos[2]/GAMEPLAY_PERCENT)
	else
		self:setPos(mapDat.szRedHomePos[1]/GAMEPLAY_PERCENT, 0, mapDat.szRedHomePos[2]/GAMEPLAY_PERCENT)
	end

end

function IBuilding:insertHero(entity)
	table.insert(self.heroTable, entity)
	self.recvHpMpCD[entity.serverId] = 0
end

function IBuilding:update(dt)
	--self.ai:update(dt)
	for k, v in pairs(self.heroTable) do
		if not v:isDead() and v:getDistance( self ) <= self.attDat.n32AttackRange then
			if self.recvHpMpCD[v.serverId] <= 0 then
				v:addHp(v:getLevel() * Quest.BuildingRecvHp, HpMpMask.BuildingHp)
				v:addMp(v:getLevel() * Quest.BuildingRecvMp, HpMpMask.BuildingMp)
				self.recvHpMpCD[v.serverId] = 1000
			end
			self.recvHpMpCD[v.serverId] = self.recvHpMpCD[v.serverId] - dt
		end 
	end
	local target = nil
	for k,v in pairs(g_entityManager.entityList) do
		--if self:isKind(v,true) == false and (v:getType() == "IMapPlayer" or  v:getType() == "IPet") and v:getHp() > 0 then
		  if self:canAttack(v) then
			if  v:getDistance( self ) <= self.attDat.n32AttackRange then
				target = v		
				break
			end
		end
	end
	if target ~= nil and self.spell:isSpellRunning() == false then
		self:setReadySkillId(self.attDat["n32CommonSkill"]) 
		self:setTarget(target)
	end
	--add code before this
	IBuilding.super.update(self, dt)
end

function IBuilding:canAttack(v)
	if v and v:getType() == "IMapPlayer" and self:isKind(v,true) == false and v:getHp() > 0  then
		return true
	end
	
	if v and v:getType() == "IPet" and self:isKind(v,true) == false and v:getHp() > 0 and v.pt.n32Type ~= 4 then
		return true
	end
	return false
end
function IBuilding:calcStats()
	--仅仅是为了和player保持一样
	self.attDat.n32LStrength = 0
	self.attDat.n32LIntelligence = 0
	self.attDat.n32LAgility = 0
	self.attDat.n32Strength = 0
	self.attDat.n32Intelligence = 0
	self.attDat.n32Agility = 0

	self:calcHpMax()
	self:calcMpMax()
	self:calcAttack()
	self:calcDefence()
	self:calcASpeed()
	self:calcMSpeed()
	self:calcAttackRange()
	self:calcRecvHp()
	self:calcRecvMp()
end
function IBuilding:preCastSkill()
	local castSkill = self.attDat.n32CommonSkill
	self:setPreSkillData(g_shareData.skillRepository[castSkill])
end
function IBuilding:clearPreCastSkill()
	self:setPreSkillData(nil)
end

function IBuilding:onDead()
	IBuilding.super.onDead(self)	
	
end

return IBuilding
