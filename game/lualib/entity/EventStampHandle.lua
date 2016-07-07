local skynet = require "skynet"
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
	local r = {  
		pos = {x=math.ceil(player.pos.x*GAMEPLAY_PERCENT), y=0,z=math.ceil(player.pos.z*GAMEPLAY_PERCENT)}, 
		dir = {x=math.ceil(player.dir.x*GAMEPLAY_PERCENT), y=0, z=math.ceil(player.dir.z*GAMEPLAY_PERCENT)}, 
		action = player.actionStatek 
		
		}
	
	skynet.send (player.agent, "lua", "sendRequest", "move" ,r)
end

return EventStampHandle
