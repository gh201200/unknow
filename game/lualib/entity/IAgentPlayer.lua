local IAgentPlayer = class("IAgentPlayer")

function IAgentPlayer.create(...)
	return IAgentPlayer.new(...)
end


function IAgentPlayer:ctor(account_id)
	self.account_id = account_id
end



return IAgentPlayer
