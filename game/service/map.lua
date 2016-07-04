local skynet = require "skynet"
local snax = require "snax"
local vector3 = require "vector3"
local EntityManager = require "EntityManager"
local EventStampHandle = require "EventStampHandle"
local profile = require "profile"

local coroutine_resume = profile.resume
local coroutine_yield = profile.yield


local max_number = 4
local roomid
local gate


function accept.move(playerId, args)
	print("playerId = "..playerId)
	local player = EntityManager.getPlayerByPlayerId(playerId)
	player:setTargetPos(args)
end



--------------------------------------------------------------------------
--------------------------------------------------------------------------

function response.query_event_status(playerId, args)
	local player = EntityManager.getPlayerByPlayerId(playerId)
	local stamp = player:checkeventStamp(args.event_type, args.event_stamp)
	if stamp < 0 then return nil end
	return {event_type = args.event_type, event_stamp = stamp}
end

function response.join(fd)
	EntityManager.createPlayer(fd, 500001)
end

function response.leave(session)
	
end

function response.query(session)
	
end

function init()
	
end

function exit()
	
end


