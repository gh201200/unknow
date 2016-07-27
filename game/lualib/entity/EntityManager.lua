require "globalDefine"
local IMapPlayer = require "entity.IMapPlayer"
local Imonster = require "entity.Imonster"
local vector3 = require "vector3"

local EntityManager = class("EntityManager")


function EntityManager:ctor(p)
	self.entityList = {}
	g_entityManager = self
end

function EntityManager:update(dt)
	for k, v in pairs(self.entityList) do
		if v.update then
			v:update(dt)		
		end	
	end
end

function EntityManager:createPlayer(agent, playerId, serverId)
	
	local player = IMapPlayer.new()
	player.serverId = serverId
	player.playerId = playerId
	player.agent = agent
	player:init()

	table.insert(self.entityList, player)
	return player
end

function EntityManager:createMonster(serverId)
	local monster = Imonster.new()
	monster.serverId = serverId
	monster:init()

	table.insert(self.entityList, monster)
	return monster
end

function EntityManager:getEntity(serverId)
	for k, v in pairs(self.entityList) do 
		if v.serverId == serverId then
			return v		
		end
	end
	return nil
end

function EntityManager:getPlayerByPlayerId(playerId)
	for k, v in pairs(self.entityList) do 
		if v.entityType == EntityType.player and v.playerId == playerId then
			return v		
		end
	end
	return nil
end

function EntityManager:getSkillAttackEntitys(source,skilldata)
	local targets = {}
	if skilldata.bNeedTarget == true then
		assert(source.target)
		local disVec = source.target.pos:sub(source.pos)	
		local disLen = disVec:length()
		if disLen >= n32range then
			table.insert(targets,source.target)
			return targets
		else 
			--返回技能查询错误 返回
			return {}
		end 
	end
	for _k,_v in pairs(self.entityList) do
		if _v.serverId ~= _v.serverId then
			local disVec = _v.pos:sub(source.pos)	
			local disLen = disVec:length()
			if disLen >= n32range then
				table.insert(targets,_v)
			end
		end
	end
	return targets
end
return EntityManager.new()


