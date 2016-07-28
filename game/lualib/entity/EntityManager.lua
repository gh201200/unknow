require "globalDefine"
local IMapPlayer = require "entity.IMapPlayer"
local Imonster = require "entity.Imonster"
local vector3 = require "vector3"

local EntityManager = class("EntityManager")


function EntityManager:ctor(p)
	--if you want to remove a entity, please set the entity's hp to 0
	--do not use table.remove or set nil
	self.entityList = {}
	g_entityManager = self
end

function EntityManager:update(dt)
	for i=#self.entityList, 1, -1 do
		local v = self.entityList[i]
		if v.update then
			v:update(dt)		
			if v:getHp() <= 0 then		--dead, remove it
				table.remove(self.entityList, i)	
			end
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

function EntityManager:createMonster(serverId, mt)
	local monster = Imonster.new()
	monster.serverId = serverId
	monster.batch = mt.batch
	monster:init(mt)

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

function EntityManager:getMonsterCountByBatch(batch)
	local cnt = 0
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.monster and v.batch == batch then
			cnt = cnt + 1	
		end
	end
	return cnt
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


