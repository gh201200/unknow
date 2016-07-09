local IAgentPlayer = class("IAgentPlayer")

function IAgentPlayer.create()
	return IAgentPlayer.new()
end

local playerId = 500001

function IAgentPlayer:ctor()
	self.playerId = playerId
	playerId = playerId + 1
end



return IAgentPlayer
