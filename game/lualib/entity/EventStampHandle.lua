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
	local r = { pos = {x=math.ceil(player.pos.x*10000), y=math.ceil(player.pos.y*10000),z=math.ceil(player.pos.z*10000)}, dir = {x=math.ceil(player.dir.x*10000), y=math.ceil(player.dir.y*10000), z=math.ceil(player.dir.z*10000)} }
	print("agent = ", player.agent)
	skynet.send (player.agent, "lua", "sendRequest", "move" ,r)
end

return EventStampHandle
