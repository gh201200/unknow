local skynet = require "skynet"
local coroutine = require "skynet.coroutine"
local EntityManager = require "entity.EntityManager"


local coroutine_pool = {}
local coroutine_response = {}

local EventStampHandle = {}

function EventStampHandle.createHandleCoroutine(serverId, event, response)
	local entity = EntityManager:getEntity( serverId )
	if not entity.coroutine_pool[event] then
		local co = coroutine.create(function(...)
			repeat
				local f = EventStampHandle[event]
				if f then
					local r = f(...)
					for k, v in pairs(entity.coroutine_response[event]) do
						v (true,  r)
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
--	print("EventStampHandle : EventStampType.Move")
	local player = EntityManager:getEntity(serverId)
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		
		pos = {x=math.ceil(player.pos.x*GAMEPLAY_PERCENT), y=0,z=math.ceil(player.pos.z*GAMEPLAY_PERCENT)}, 
		dir = {x=math.ceil(player.dir.x*GAMEPLAY_PERCENT), y=0, z=math.ceil(player.dir.z*GAMEPLAY_PERCENT)},			
		action = player.curActionState,	
		speed = player.moveSpeed * GAMEPLAY_PERCENT,
	}
	return r
end
EventStampHandle[EventStampType.CastSkill] = function (serverId, event)
	local player = EntityManager:getEntity(serverId)
--	print("EventStampType.CastSkill",serverId,player.castSkillId)
	local skillid = player.castSkillId
	local errorCode = player.spell.errorCode
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		skillId = skillid,
		errorCode = errorCode 
}
	return r
end

EventStampHandle[EventStampType.Stats] = function (serverId, event)
	print("EventStampHandle : EventStampType.Stats")
	local player = EntityManager:getEntity(serverId)
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		stats = {
			Strength = player:getStrength(),
			StrengthPc = player:getStrengthPc(),
			Minjie =  player:getMinjie(),
			MinjiePc = player:getMinjiePc(),
			Zhili = player:getZhili(),
			ZhiliPc = player:getZhiliPc(),
			HpMax = player:getHpMax(),
			HpMaxPc = player:getHpMaxPc(),
			MpMax = player:getMpMax(),
			MpMaxPc = player:getMpMaxPc(),
			Attack = player:getAttack(),
			AttackPc = player:getAttackPc(),
			Defence = player:getDefence(),
			DefencePc = player:getDefencePc(),
			ASpeed = player:getASpeed(),
			MSpeed = player:getMSpeed(),
			MSpeedPc = player:getMSpeedPc(),
			AttackRange = player:getAttackRange(),
			AttackRangePc = player:getAttackRangePc(),
			RecvHp = player:getRecvHp(),
			RecvHpPc = player:getRecvHpPc(),
			RecvMp = player:getRecvMp(),
			RecvMpPc = player:getRecvMpPc(),
			BaojiRate = player:getBaojiRate(),
			BaojiTimes = player:getBaojiTimes(),
			Hit = player:getHit(),
			Miss = player:getMiss(),
		}
	}	
	return r
end

EventStampHandle[EventStampType.Hp_Mp] = function (serverId, event)
	print("EventStampHandle : EventStampType.Hp_Mp")
	local player = EntityManager:getEntity(serverId)
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},

		n32Hp = player:getHp(),
		n32Mp = player:getMp(),
		mask = player.maskHpMpChange,
	}
	return r
end

EventStampHandle[EventStampType.Affect] = function (serverId, event)
	print("EventStampHandle : EventStampType.Affect")
	local player = EntityManager:getEntity(serverId)
	local r = {
		 event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		affectNum = 0,  
		affectList = { }	 
	}
	r.affectNum = #player.AffectTable.affects
	for i=#player.AffectTable.affects,1,-1 do
		local v = player.AffectTable.affects[i]
		assert(v and v.effectId)
		table.insert(r.affectList, {effectId = v.effectId , effectTime = v.effectTime })
	end
	return r
end

return EventStampHandle
