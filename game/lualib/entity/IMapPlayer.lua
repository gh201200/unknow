local skynet = require "skynet"
local Ientity = require "entity.Ientity"
local vector3 = require "vector3"

local IMapPlayer = class("IMapPlayer", Ientity)

function IMapPlayer.create()
	return IMapPlayer.new()
end


function IMapPlayer:ctor()
	IMapPlayer.super.ctor(self)

	self.playerId = 500001		--same with IAgentPlayer.playerId
	self.serverId = 1001
	self.pos.x = 10
	self.pos.y = 0
	self.pos.z = 10
	self.dir:set(0, -1, 0)
	self.moveTime = 0
	self.moveSpeed = 0
	self.entityType = EntityType.player
end

function IMapPlayer:update()
	IMapPlayer.super.update(self)
	self:move()
	
end

function IMapPlayer:move()
	if self.moveSpeed <= 0 then return end

	local timeDiff = (skynet.now() - self.moveTime) / 100
	local moveVec = self.dir:return_mul_num(self.moveSpeed * timeDiff)
	local dst = self.pos:return_add(moveVec)
	--check iegal
	
	--move
	self.pos:set(dst.x, dst,y, dst.z)

	--advance move event stamp
	self:advanceEventStamp(EventStampType.Move)
end



return IMapPlayer
