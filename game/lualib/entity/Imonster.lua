local Ientity = require "entity.Ientity"

local IMonster = class("IMonster", Ientity)


function IMonster:ctor()
	print('IMonster:ctor')
	IMonster.super.ctor(self)
	self.entityType = EntityType.monster	
end

function IMonster:init()
	self.attDat = g_shareData.monsterRepository[20001]
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
