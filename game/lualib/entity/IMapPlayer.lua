local skynet = require "skynet"
local Ientity = require "entity.Ientity"
local vector3 = require "vector3"


local IMapPlayer = class("IMapPlayer", Ientity)


function IMapPlayer:ctor()
	IMapPlayer.super.ctor(self)

	self.playerId = 0		--same with IAgentPlayer.playerId
	self.entityType = EntityType.player
	self.agent = 0
	
	print("IMapPlayer:ctor()")
end

function IMapPlayer:update(dt)
	--add code before this
	IMapPlayer.super.update(self,dt)
end


function IMapPlayer:init()
	self.attDat =  g_shareData.heroRepository[100000001]
	self:calcStats()
end

function IMapPlayer:calcStats()
	self:calcStrength()
	self:calcZhili()
	self:calcMinjie()
	self:calcHpMax()
	self:calcMpMax()
	self:calcAttack()
	self:calcDefence()
	self:calcASpeed()
	self:calcMSpeed()
	self:calcRecvHp()
	self:calcRecvMp()
	self:calcAttackRange()
	self:calcBaoji()
	self:calcHit()
	self:calcMiss()
end

return IMapPlayer

