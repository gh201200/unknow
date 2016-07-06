local skynet = require "skynet"
local snax = require "snax"
local vector3 = require "vector3"
local EntityManager = require "entity.EntityManager"
local EventStampHandle = require "entity.EventStampHandle"


local last_update_time = nil
local function updateMapEvent()
	local nt = skynet.now()
	EntityManager:update(nt - last_update_time)
	last_update_time = nt
	skynet.timeout(3, function() updateMapEvent() end)
end


function accept.entity_enter(agent)
	local player = EntityManager:getPlayerByPlayerId(500001)
	player.agent = agent
end


function accept.move(playerId, args)
	print("playerId = "..playerId)
	local player = EntityManager:getPlayerByPlayerId(playerId)
	player:setTargetPos(args)
end


--------------------------------------------------------------------------
--------------------------------------------------------------------------


function response.query_event_status(playerId, args)
	EventStampHandle.createHandleCoroutine(args.event_type)
	local player = EntityManager:getPlayerByPlayerId(playerId)
	local stamp = player:checkeventStamp(args.event_type, args.event_stamp)
	if stamp < 0 then 
		return nil 
	end
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
	--every 0.03s update entity
	skynet.timeout(3, function() updateMapEvent() end)
	last_update_time = skynet.now()

	EntityManager:createPlayer(fd, 500001)
	EntityManager:createPlayer(fd, 500002)
end

function exit()
	
end


