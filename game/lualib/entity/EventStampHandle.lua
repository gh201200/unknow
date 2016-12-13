local skynet = require "skynet"
local coroutine = require "skynet.coroutine"
local EntityManager = require "entity.EntityManager"


local coroutine_pool = {}
local coroutine_response = {}

local EventStampHandle = {}

function EventStampHandle.createHandleCoroutine(serverId, event, response)
	local entity = EntityManager:getEntity( serverId )
	if not entity then
		print('createHandleCoroutine entity id null ,server id = ',serverId)
		EntityManager:dump()
	end
	if not entity.coroutine_pool[event] then
		local co = coroutine.create(function(...)
			repeat
				local f = EventStampHandle[event]
				if f then
					local s, r = pcall(f, ...)
					if not s then
						print(r)
						--r = nil
					end
					for k, v in pairs(entity.coroutine_response[event]) do
						v (true, r)
					end
					entity.coroutine_response[event] = {}
				else
					syslog.errf("no %d handle defined", event)	
				end
				coroutine.yield()
			until false
		end)
		entity.coroutine_pool[event] =  co
	end
	if not entity.coroutine_response[event] then
		entity.coroutine_response[event] = {}
	end
	table.insert(entity.coroutine_response[event], response)
end
function respClientEventStamp(co, serverId, event)
	coroutine.resume(co, serverId, event)
end

--------------------------------------------------------------------------------------------
----
EventStampHandle[EventStampType.Move] = function (serverId, event)
	local player = EntityManager:getEntity(serverId)
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		pos = {x=math.ceil(player.pos.x*GAMEPLAY_PERCENT), y= math.ceil(player.pos.y*GAMEPLAY_PERCENT),z=math.ceil(player.pos.z*GAMEPLAY_PERCENT)}, 
		dir = {x=math.ceil(player.dir.x*GAMEPLAY_PERCENT), y=0, z=math.ceil(player.dir.z*GAMEPLAY_PERCENT)},			
		action = player.curActionState,	
		speed = math.ceil(player.moveSpeed * GAMEPLAY_PERCENT),
	}
	return r
end

EventStampHandle[EventStampType.Stats] = function (serverId, event)
	local player = EntityManager:getEntity(serverId)
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		stats = {
			Strength = math.floor(player:getStrength()),
			Agility = math.floor(player:getAgility()),
			Intelligence = math.floor(player:getIntelligence()),
			HpMax = math.floor(player:getHpMax()),
			MpMax = math.floor(player:getMpMax()),
			Attack = math.floor(player:getAttack()),
			Defence = math.floor(player:getDefence()),
			ASpeed = math.floor(player:getASpeed()*GAMEPLAY_PERCENT),
			exp = player:getExp(),
			gold = player:getGold(),
			level = player:getLevel(),
		}
	}	
	return r
end

EventStampHandle[EventStampType.Hp_Mp] = function (serverId, event)
	local player = EntityManager:getEntity(serverId)
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},

		n32Hp = math.floor(player:getHp()),
		n32Mp = math.floor(player:getMp()),
		n32Shield = math.floor(player:getShield()),
		mask = player.maskHpMpChange
	}
	return r
end


return EventStampHandle
