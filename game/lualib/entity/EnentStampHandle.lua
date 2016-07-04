
local EventStampHandle = {
	entityManager = nil
}


local function event_stamp_move(serverId)
	local player = entityManager:getEntity(serverId)
	
end
EventStampHandle[EventStampType.Move] = event_stamp_move

return EventStampHandle
