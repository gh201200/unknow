local Ientity = require "entity.Ientity"
local vector3 =require "vector3"
local HateList = require "ai.HateList" 
local NpcAI = require "ai.NpcAI"


local IMonster = class("IMonster", Ientity)


function IMonster:ctor()
	IMonster.super.ctor(self)
	self.entityType = EntityType.monster	
	self.hateList = HateList.new()
	self.ai = NpcAI.new(self)
	self.bornPos =  vector3.create()
	

	register_class_var(self, "PreSkillData", nil)
end

function IMonster:getType()
         return "IMonster"
end
function IMonster:init(mt)
	self.attDat = g_shareData.monsterRepository[mt.id]
	mt.px = 2
	mt.pz = 2
	self.pos:set(mt.px, 0, mt.pz)
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

	--add code before this
	IMonster.super.update(self, dt)
end

function IMonster:calcStats()
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
end

function IMonster:preCastSkill()
	self:setPreSkilldata(self.attDat.n32Skill)
end

function IMonster:clearPreCastSkill()
	self:setPreSkillData(nil)
end

function IMonster:addHp(_hp, mask, source)
	IMonster.super.addHp(self, _hp, mask, source)
	
	if self:getHp() <= 0 then                                             
                self.hateList:addHate(source, self.lstHp + math.floor(self:getHpMax() * 0.2))
     	else                                                                  
                if _hp < 0 then                                               
			if self.lastHp == self:getHpMax() then                
				self.hateList:addHate(source, -_hp + math.floor(self.getHpMax()
    * 0.1))             else                                                  
                        	self.hateList:addHate(source, -_hp)           
                        end                                                   
                 end                                                           
         end    
end

return IMonster
