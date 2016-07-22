local skynet = require "skynet"
local Ientity = require "entity.Ientity"
local vector3 = require "vector3"


local IMapPlayer = class("IMapPlayer", Ientity)


function IMapPlayer:ctor()
	IMapPlayer.super.ctor(self)

	self.playerId = 0		--same with IAgentPlayer.playerId
	self.serverId = 0
	self.pos.x = 0
	self.pos.y = 0
	self.pos.z = 0
	self.dir:set(0, 0, 0)
	self.entityType = EntityType.player
	self.agent = 0
	self.castSkillId = 0
	
	print("IMapPlayer:ctor()")
end

function IMapPlayer:update(dt)
	self:move(dt)
	


	--add code before this
	IMapPlayer.super.update(self,dt)
end


function IMapPlayer:move(dt)
	dt = dt / 1000		--second
	if self.moveSpeed <= 0 then return end

	self.dir:set(self.targetPos.x, self.targetPos.y, self.targetPos.z)
	self.dir:sub(self.pos)
	
	self.dir:normalize(self:getBaseMSpeed() * dt)
	

	local dst = self.pos:return_add(self.dir)
	--check iegal
	
	--move
	self.pos:set(dst.x, dst.y, dst.z)
	if IS_SAME_GRID(self.targetPos,  dst) then
		self:stand()
	end

	--advance move event stamp
	self:advanceEventStamp(EventStampType.Move)
end

function IMapPlayer:init()
end

return IMapPlayer

