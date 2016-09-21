local Ientity = require "entity.Ientity"
local vector3 =require "vector3"
local HateList = require "ai.HateList" 
local NpcAI = require "ai.NpcAI"
local EntityManager = require "entity.EntityManager"
local Map = require "map.Map"
local DropManager = require "drop.DropManager"


local IMonster = class("IMonster", Ientity)

function IMonster.create(serverId, mt)
	local monster = IMonster.new()
	
	monster.serverId = serverId
	monster.batch = mt.batch

	monster:init(mt)

	return monster
end


function IMonster:ctor()
	IMonster.super.ctor(self)
	self.entityType = EntityType.monster	
	self.hateList = HateList.new(self)
	self.ai = NpcAI.new(self)
	self.skillCD = 0

	register_class_var(self, "PreSkillData", nil)

end

function IMonster:getType()
         return "IMonster"
end
function IMonster:init(mt)
	self.attDat = g_shareData.monsterRepository[mt.id]
	self.modelDat = g_shareData.heroModelRepository[self.attDat.n32ModelId]
	self:setPos(mt.px, 0, mt.pz)
	self.bornPos:set(mt.px, 0, mt.pz)
	self:calcStats()
	self:setHp(self:getHpMax())
	self:setMp(self:getMpMax())
	self.HpMpChange = true
	self.StatsChange = true
end


function IMonster:update(dt)
	if self:getHp() <= 0 then return end
	self.ai:update(dt)
	
	self.skillCD  = self.skillCD - dt
	--add code before this
	IMonster.super.update(self, dt)
end

function IMonster:calcStats()
	--仅仅是为了和player保持一样
	self.attDat.n32LStrength = 0
	self.attDat.n32LZhili = 0
	self.attDat.n32LMinjie = 0
	
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

function IMonster:onDead()
	IMonster.super.onDead(self)	
	
	--make drop
	local sid = self.hateList:getTopHate()
	local player = EntityManager:getEntity( sid )
	player:addGold( self.attDat.n32Gold )
	player:addExp( self.attDat.n32Exp )
	DropManager:makeDrop(self)
	
	--tell the clients
	EntityManager:sendToAllPlayers("killEntity", {sid=self.serverId})

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

function IMonster:preCastSkill()
	local castSkill = self.attDat.n32CommonSkill
	if self.skillCD < 0 then
		local skills = {}
		local sumPercent = 0
		for k, v in pairs(self.attDat.szSkill) do
			if self.cooldown:getCdTime(v.skillId) <= 0 then
				sumPercent = sumPercent + v.percent
				table.insert(skills, {skillId=v.skillId, percent=sumPercent})
			end
		end
		if sumPercent > 0 then
			local rd = math.random(1, sumPercent)
			for k, v in pairs(skills) do
				if rd <= v.percent then
					castSkill = v.skillId
					break
				end
			end
		end
	end
	self:setPreSkillData(g_shareData.skillRepository[castSkill])
end

function IMonster:clearPreCastSkill()
	self:setPreSkillData(nil)
end

function IMonster:addHp(_hp, mask, source)
	if self:getHp()+_hp <= 0 then                                             
                self.hateList:addHate(source, self:getHp() + math.floor(self:getHpMax() * 0.2))
     	else                                                                  
                if _hp < 0 then                                               
			if self:getHp() == self:getHpMax() then                
				self.hateList:addHate(source, -_hp + math.floor(self:getHpMax()* 0.1))             
	else                                                  
                        	self.hateList:addHate(source, -_hp)           
                        end                                                   
		end                                                           
        end
    
	IMonster.super.addHp(self, _hp, mask, source)
end

return IMonster
