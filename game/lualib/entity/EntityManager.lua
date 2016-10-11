local skynet = require "skynet"
require "globalDefine"
local vector3 = require "vector3"
local IflyObj = require "entity.IflyObj"
local EntityManager = class("EntityManager")

function EntityManager:sendToAllPlayers(msg, val, except)
	--if true then return end
	if not except then except = "" end
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.player and  string.find(except, v.serverId)==nil  then
			skynet.call(v.agent, "lua", "sendRequest", msg, val)
		end
	end
end

function EntityManager:ctor(p)
	--if you want to remove a entity, please set the entity's hp to 0
	--do not use table.remove or set nil
	self.entityList = {}
	g_entityManager = self
end

function EntityManager:dump()
	for i=#self.entityList, 1, -1 do
		local v = self.entityList[i]
		print('server id = '.. v.serverId)
		print('entity type = '.. v.entityType)
	end
end

function EntityManager:update(dt)
	for i=#self.entityList, 1, -1 do
		local v = self.entityList[i]
		if v.update then
			v:update(dt)		
			if v.entityType == EntityType.monster then
				if v:getHp() <= 0 then		--dead, remove it
					table.remove(self.entityList, i)
				end
			elseif v.entityType == EntityType.flyObj then
				if v.lifeTime <= 0 then
					table.remove(self.entityList, i)
				end	
			end
		end	
	end
end

function EntityManager:addEntity(entity)
	table.insert(self.entityList, entity)
end

function EntityManager:getEntity(serverId)
	for k, v in pairs(self.entityList) do 
		if v.serverId == serverId then
			return v		
		end
	end
	return nil
end

function EntityManager:getPlayerByPlayerId(account_id)
	for k, v in pairs(self.entityList) do 
		if v.entityType == EntityType.player and v.account_id == account_id then
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

function EntityManager:getMonsterById(_id)
	local lt = {}
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.monster and v.attDat.id == _id then
			table.insert(lt, v)
		end
	end
	return lt
end

function EntityManager:getCloseEntityByType(source, _type)
	local et = nil
	local minLen = 0xffffffff
	for k, v in pairs(self.entityList) do
		if v.entityType == _type and v ~= source then
			local ln = vector3.len(source.pos, v.pos)
			if minLen > ln then
				minLen = ln
				et = v
			end
		end
	end
	return et, minLen
end
function EntityManager:createFlyObj(srcObj,targetPos,skilldata)
	local obj = IflyObj.create(srcObj,targetPos,skilldata)	
	self:addEntity(obj)
end
function EntityManager:getSkillAttackEntitys(source,skilldata)
	local type_range = math.floor(skilldata.n32Type % 10)   -- 1:单体 2:自身点的圆形区域 3:自身点的矩形区域 4:目标点的圆形区域 5:飞行物碰撞 
	local type_target = math.floor(skilldata.n32Type / 10)  -- 1:自身 2:友方 3:敌方
	local tmpTb = {}
	if type_range == 1 then
		if source:getTarget() ~= nil and source:getTarget():getType() ~= "transform" then
			table.insert(tmpTb,source:getTarget())
			return tmpTb
		end
	end
	--根据势力筛选出目标对象
	for _k,_v in pairs(self.entityList) do
		if type_target == 1 then
			table.insert(tmpTb,source)
			break
		elseif type_target == 2 then
			if _v.camp == source.camp and _v ~= source then
				table.insert(tmpTb,_v)
			end
		elseif type_target == 3 then
			--if _v.camp ~= source.camp then
			if _v ~= source  then
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
				if disLen <= range then
					table.insert(ret,_v)
				end
			end
		end
		return ret
	end
	local retTb = {}
	--筛选区域内对象
	if type_range  == 1 then
		--assert(#tmpTb == 1)
	elseif type_range  == 2 then
		retTb = getRangeEntitys(tmpTb,source.pos,skilldata.n32Radius / 10000 )
	elseif type_range == 3 then
		
	elseif type_range == 4 then
		retTb = getRangeEntitys(tmpTb,source:getTarget().pos,skilldata.n32Radius / 10000)	
	elseif type_rang == 5 then	
	
	end
	return retTb
end

return EntityManager.new()


