local coroutine = require "skynet.coroutine"


local coroutine_pool = {}

local EventStampHandle = {}

function EventStampHandle.createHandleCoroutine(event)
	if not coroutine_pool[event] then
		local co = coroutine.create(function(...)
			repeat
				local f = EventStampHandle[event]
				if f then
					f(...)	
				else
					syslog.errf("no %d handle defined", event)	
				end
				coroutine.yield()
			until false
		end)
		coroutine_pool[event] = co
	end
end



function EventStampHandle.respClientEventStamp(event, serverId)
	coroutine.resume(coroutine_pool[event], serverId)
end




EventStampHandle[EventStampType.Move] = function (serverId)
	--local player = entityManager:getEntity(serverId)
	print("EventStampHandle : EventStampType.Move")
	
end

return EventStampHandle
