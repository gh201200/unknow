local skynet = require "skynet"
local Ientity = require "entity.Ientity"
local vector3 = require "vector3"

local IMapPlayer = class("IMapPlayer", Ientity)


function IMapPlayer:ctor()
	IMapPlayer.super.ctor(self)

	self.playerId = 500001		--same with IAgentPlayer.playerId
	self.serverId = 1001
	self.pos.x = 0
	self.pos.y = 0
	self.pos.z = 0
	self.dir:set(0, -1, 0)
	self.moveSpeed = 0
	self.entityType = EntityType.player
	self.agent = 0

	print("IMapPlayer:ctor()")
end

function IMapPlayer:update(dt)
	self:move(dt)
	
end

function IMapPlayer:move(dt)
	if self.moveSpeed <= 0 then return end

	self.dir:set(self.targetPos.x, self.targetPos.y, self.targetPos.z)
	self.dir:sub(self.pos)
	self.dir:normalize(self.moveSpeed * dt/100)
	

	local dst = self.pos:return_add(self.dir)
	--check iegal
	
	--move
	print("dst = ", dst.x, dst.y, dst.z)
	self.pos:set(dst.x, dst.y, dst.z)
	print("pos = ", self.pos.x, self.pos.y,self.pos.z)
	if math.abs(self.targetPos.x - dst.x) < 0.01 and math.abs(self.targetPos.z - dst.z) < 0.01 then
		self.moveSpeed = 0
	end

	--advance move event stamp
	self:advanceEventStamp(EventStampType.Move)
end



return IMapPlayer
