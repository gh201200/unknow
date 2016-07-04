local snax = require "snax"
local skynet = require "skynet"

local EventStampHandle = class("EventStampHandle")

local entityManager = nil

function EventStampHandle:ctor()
end


function EventStampHandle:init(em)
	entityManager = em
end


EventStampHandle[EventStampType.Move] = function (serverId)
	local player = entityManager:getEntity(serverId)
	print("EventStampHandle : EventStampType.Move")
	
end

return EventStampHandle.new()
