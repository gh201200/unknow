local Ientity = require "entity.Ientity"

local IMonster = class("IMonster", Ientity)


function IMonster:ctor()
	print("IMonster:ctor")
	IMonster.super.ctor(self,nil,nil)
	self.entityType = EntityType.monster	
end

function IMonster:init(mt)
	self.attDat = g_shareData.monsterRepository[mt.id]
	self.pos:set(mt.px, 0, mt.py)
	self:calcStats()
	self:setHp(self:getHpMax())
	self:setMp(self:getMpMax())
	self.HpMpChange = true
	self.StatsChange = true
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

return IMonster
