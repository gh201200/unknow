local IAgentPlayer = class("IAgentPlayer")

function IAgentPlayer.create(...)
	return IAgentPlayer.new(...)
end


function IAgentPlayer:ctor(playerId)
	self.playerId = playerId
end



return IAgentPlayer
