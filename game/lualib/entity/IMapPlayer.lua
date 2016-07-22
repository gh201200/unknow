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
--	self:recvHpMp()
	--add code before this
	IMapPlayer.super.update(self,dt)
end


function IMapPlayer:init()
end

return IMapPlayer

