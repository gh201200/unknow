local coroutine = require "skynet.coroutine"
local EntityManager = require "entity.EntityManager"


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



function respClientEventStamp(event, serverId)
	coroutine.resume(coroutine_pool[event], serverId)
end




EventStampHandle[EventStampType.Move] = function (serverId)
	local player = EntityManager:getEntity(serverId)
	print("EventStampHandle : EventStampType.Move")
	local r = { pos = {player.pos.x, player.pos.y, player.pos.z}, dir = {player.dir.x, player.dir.y, player.dir.z} }
	skynet.send (player.agent, "lua", "sendRequest", r)
end

return EventStampHandle
