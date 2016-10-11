local Ientity = require "entity.Ientity"
local vector3 =require "vector3"
local EntityManager = require "entity.EntityManager"
local Map = require "map.Map"
local Quest = require "quest.quest"

local IBuilding = class("IBuilding", Ientity)

function IBuilding.create(camp, mapDat)
	local monster = IBuilding.new()
	
	monster.serverId = assin_server_id()
	monster.camp = camp	--0:red 1:blue

	monster:init(mapDat)

	return monster
end


function IBuilding:ctor()
	IBuilding.super.ctor(self)
	self.entityType = EntityType.building	
	self.heroTable = {}
	self.recvHpMpCD = {}
end

function IBuilding:getType()
         return "IBuilding"
end

function IBuilding:init(mapDat)
	local aid = mapDat.n32RedMonsterId
	self:setPos(mapDat.szRedHomePos[1]/GAMEPLAY_PERCENT, 0, mapDat.szRedHomePos[2]/GAMEPLAY_PERCENT)
	if self.camp == 1 then
		aid = mapDat.n32BlueMonsterId
		self:setPos(mapDat.szBlueHomePos[1]/GAMEPLAY_PERCENT, 0, mapDat.szBlueHomePos[2]/GAMEPLAY_PERCENT)
	end
	self.attDat = g_shareData.monsterRepository[aid]
	self.modelDat = g_shareData.heroModelRepository[self.attDat.n32ModelId]
	self:calcStats()
	self:setHp(self:getHpMax())
	self:setMp(self:getMpMax())
	self.HpMpChange = true
	self.StatsChange = true
end

function IBuilding:insertHero(entity)
	table.insert(self.heroTable, entity)
	self.recvHpMpCD[entity.serverId] = 0
end

function IBuilding:update(dt)

	for k, v in pairs(self.heroTable) do
		if v:getDistance( self ) <= self.attDat.n32AttackRange then
			if self.recvHpMpCD[v.serverId] <= 0 then
				v:addHp(v:getLevel() * Quest.BuildingRecvHp, HpMpMask.BuildingHp)
				v:addMp(v:getLevel() * Quest.BuildingRecvMp, HpMpMask.BuildingMp)
				self.recvHpMpCD[v.serverId] = 1000
			end
			self.recvHpMpCD[v.serverId] = self.recvHpMpCD[v.serverId] - dt
		end 
	end

	--add code before this
	IBuilding.super.update(self, dt)
end

function IBuilding:calcStats()
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

function IBuilding:onDead()
	IBuilding.super.onDead(self)	
	
end

return IBuilding
