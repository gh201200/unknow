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
		speed = player.moveSpeed * GAMEPLAY_PERCENT
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
			n32Strength = player.Stats.n32Strength,
			n32Strength_Pc = player.Stats.n32Strength_Pc,
			n32Agile =  player.Stats.n32Agile,
			n32Agile_Pc = player.Stats.n32Agile_Pc,
			n32Intelg = player.Stats.n32Intelg,
			n32Intelg_Pc = player.Stats.n32Intelg_Pc,
			n32AttackPhy = player.Stats.n32AttackPhy,
			n32AttackPhy_Pc = player.Stats.n32AttackPhy_Pc,
			n32DefencePhy = player.Stats.n32DefencePhy,
			n32DefencePhy_Pc = player.Stats.n32DefencePhy_Pc,
			n32AttackSpeed = player.Stats.n32AttackSpeed,
			n32AttackSpeed_Pc = player.Stats.n32AttackSpeed_Pc,
			n32MoveSpeed = player.Stats.n32MoveSpeed,
			n32MoveSpeed_Pc = player.Stats.n32MoveSpeed_Pc,
			n32AttackRange_Pc = player.Stats.n32AttackRange_Pc,
			n32MaxHp = player.Stats.n32MaxHp,
			n32Hp_Pc = player.Stats.n32Hp_Pc,
			n32MaxMp = player.Stats.n32MaxMp,
			n32Mp_Pc = player.Stats.n32Mp_Pc,
			n32RecvHp = player.Stats.n32RecvHp,
			n32RecvHp_Pc = player.Stats.n32RecvHp_Pc,
			n32RecvMp = player.Stats.n32RecvMp,
			n32RecvMp_Pc = player.Stats.n32RecvMp_Pc,
		}
	}
	return r
end

EventStampHandle[EventStampType.Hp_Mp] = function (serverId, event)
	print("EventStampHandle : EventStampType.Hp_Mp")
	local player = EntityManager:getEntity(serverId)
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},

		n32Hp = player.Stats.n32Hp,
		n32Mp = player.Stats.n32Mp,
		mask = player.maskHpMPChange,
	}
	return r
end
EventStampHandle[EventStampType.Buff] = function (serverId, event)
	print("EventStampHandle : EventStampType.Buff")
	local player = EntityManager:getEntity(serverId)
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		buffLists = { }
	}
	for i=#player.buffList, 1, -1 do
		local v = player.buffList[i]
		table.insert( r.buffLists, { buffId = v.buffId, count = v.Count, remainTime = v.remainTime } )  
	end
	return r
end

EventStampHandle[EventStampType.SkillAffect] = function (serverId, event)
	print("EventStampHandle : EventStampType.SkillAffect")
	local player = EntityManager:getEntity(serverId)
	local r = {
		 event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		 AffectList = { }	 
	}
	
	for i=#player.AffectList,1,-1 do
		local v = player.AffectList[i]
		table.insert(r.AffectList, {effectId = v.effectId , AffectType = v.AffectType ,AffectValue = v.AffectValue ,AffectTime = v.AffectTime })
	end
end
return EventStampHandle
