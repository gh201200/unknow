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
	local type_range = math.floor(skilldata.n32Type % 10)   -- 1:单体 2:自身点的圆形区域 3:自身点的矩形区域 4:目标点的圆形区域 5:目标点的矩形区域 
	local type_target = math.floor(skilldata.n32Type / 10)  -- 1:自身 2:友方 3:敌方
	local tmpTb = {}
	--筛选出目标群体
	for _k,_v in pairs(self.entityList) do
		if type_target == 1 then
			table.insert(tmpTb,source)
			break
		elseif type_target == 2 then
			if _v.camp == source.camp and _v ~= source then
				table.insert(tmpTb,_v)
			end
		elseif type_target == 3 then
			if _v.camp ~= source.camp then
				table.insert(tmpTb,_v)
			end
		end
	end
	local getRangeEntitys = function(tab,basepos,range,tp)
		tp = tp or "round" --默认圆形区域
		local ret = {}
		if tp == "round" then
			for _k,_v  in pairs(tab) do
				local disVec = _v.pos:return_sub(basepos)
				local disLen = disVec:length()	
				if disLen >= range then
					table.insert(ret,_v)
				end
			end
		end
	end
	local retTb = {}
	--筛选区域内群体
	if type_range  == 1 then
		--assert(#tmpTb == 1)
	elseif type_range  == 2 then
		retTb = getRangeEntitys(tmpTb,source.pos,skilldata.n32Radius)
	elseif type_range == 3 then
		
	elseif type_range == 4 then
		retTb = getRangeEntitys(tmpTb,source.targetpostion,skilldata.n32Radius)	
	elseif type_rang == 5 then	
	
	end
	return retTb
end
return EntityManager.new()


