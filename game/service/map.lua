local skynet = require "skynet"
local snax = require "snax"
local vector3 = require "vector3"
local EntityManager = require "entity.EntityManager"
local EventStampHandle = require "entity.EventStampHandle"
local coroutine = require "skynet.coroutine"



local coroutine_pool = {}


local max_number = 4
local roomid
local gate


function accept.move(playerId, args)
	print("playerId = "..playerId)
	local player = EntityManager:getPlayerByPlayerId(playerId)
	player:setTargetPos(args)
end



function accept.respClientEventStamp(event, serverId)
	coroutine.resume(coroutine_pool[event], serverId)
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------


function response.getEventStampHandle()
	return EventStampHandle
end

function response.query_event_status(playerId, args)
	if not coroutine_pool[args.event_type] then
		local co = coroutine.create(function(...)
			repeat
				local f = EventStampHandle[args.event_type]
				if f then
					f(...)	
				else
					syslog.errf("no %d handle defined", event)	
				end
				coroutine.yield()
			until false
		end)
		coroutine_pool[args.event_type] = co

	end
	local player = EntityManager:getPlayerByPlayerId(playerId)
	local stamp = player:checkeventStamp(args.event_type, args.event_stamp)
	if stamp < 0 then 
		return nil 
	end
	coroutine.resume(coroutine_pool[args.event_type], player.serverId)	--resp client
	return {event_type = args.event_type, event_stamp = stamp}
end

function response.join(fd)
	EntityManager:createPlayer(fd, 500001)
end

function response.leave(session)
	
end

function response.query(session)
	
end

function init()
	EventStampHandle:init(EntityManager)
	EntityManager:createPlayer(fd, 500001)
	EntityManager:createPlayer(fd, 500002)
end

function exit()
	
end


