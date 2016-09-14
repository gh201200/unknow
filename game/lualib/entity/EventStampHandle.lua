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
					local s, r = pcall(f, ...)
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
	local player = EntityManager:getEntity(serverId)
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		pos = {x=math.ceil(player.pos.x*GAMEPLAY_PERCENT), y=0,z=math.ceil(player.pos.z*GAMEPLAY_PERCENT)}, 
		dir = {x=math.ceil(player.dir.x*GAMEPLAY_PERCENT), y=0, z=math.ceil(player.dir.z*GAMEPLAY_PERCENT)},			
		action = player.curActionState,	
		speed = math.ceil(player.moveSpeed * GAMEPLAY_PERCENT),
	}
	return r
end
EventStampHandle[EventStampType.CastSkill] = function (serverId, event)
	local player = EntityManager:getEntity(serverId)
	local skillid = player.CastSkillId
	local targetId = 0
	if player.target ~= nil and player.target:getType() ~= "transform" then
		targetId = player.target.serverId
	end
	local errorCode = player.spell.errorCode
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		skillId = skillid,
		targetId = targetId,
		errorCode = errorCode 
}
	return r
end

EventStampHandle[EventStampType.Stats] = function (serverId, event)
	local player = EntityManager:getEntity(serverId)
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		stats = {
			Strength = math.floor(player:getStrength()),
			StrengthPc = math.floor(player:getStrengthPc()),
			Minjie = math.floor(player:getMinjie()),
			MinjiePc = math.floor(player:getMinjiePc()),
			Zhili = math.floor(player:getZhili()),
			ZhiliPc = math.floor(player:getZhiliPc()),
			HpMax = math.floor(player:getHpMax()),
			HpMaxPc = math.floor(player:getHpMaxPc()),
			MpMax = math.floor(player:getMpMax()),
			MpMaxPc = math.floor(player:getMpMaxPc()),
			Attack = math.floor(player:getAttack()),
			AttackPc = math.floor(player:getAttackPc()),
			Defence = math.floor(player:getDefence()),
			DefencePc = math.floor(player:getDefencePc()),
			ASpeed = math.floor(player:getASpeed()),
			MSpeed = math.floor(player:getMSpeed()),
			MSpeedPc = math.floor(player:getMSpeedPc()),
			AttackRange = math.floor(player:getAttackRange()),
			AttackRangePc = math.floor(player:getAttackRangePc()),
			RecvHp = math.floor(player:getRecvHp()),
			RecvHpPc = math.floor(player:getRecvHpPc()),
			RecvMp = math.floor(player:getRecvMp()),
			RecvMpPc = math.floor(player:getRecvMpPc()),
			BaojiRate = math.floor(player:getBaojiRate()),
			BaojiTimes = math.floor(player:getBaojiTimes()),
			Hit = math.floor(player:getHit()),
			Miss = math.floor(player:getMiss()),
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
		mask = player.maskHpMpChange,
	}
	return r
end

EventStampHandle[EventStampType.Affect] = function (serverId, event)
	local player = EntityManager:getEntity(serverId)
	local r = {
		event_stamp = {id = serverId, type=event, stamp=player.serverEventStamps[event]},
		affectList = { }	 
	}
	for i=#player.affectTable.affects,1,-1 do
		local v = player.affectTable.affects[i]
		assert(v and v.effectId)
		table.insert(r.affectList, {effectId = v.effectId , projectId = v.projectId,effectTime = v.effectTime })
	end
	return r
end

return EventStampHandle
