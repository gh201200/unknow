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
end

return IMapPlayer
