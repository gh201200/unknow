local IAgentPlayer = class("IAgentPlayer")

function IAgentPlayer.create()
	return IAgentPlayer.new()
end

function IAgentPlayer:ctor()
	

	self.playerId = 500001
end



return IAgentPlayer
