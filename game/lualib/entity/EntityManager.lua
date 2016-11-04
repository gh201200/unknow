local skynet = require "skynet"
require "globalDefine"
local vector3 = require "vector3"
local IflyObj = require "entity.IflyObj"
local EntityManager = class("EntityManager")
local IPet = require "entity.Ipet"
function EntityManager:sendToAllPlayers(msg, val, except)
	if not except then except = "" end
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.player and  string.find(except, v.serverId)==nil  then
			skynet.call(v.agent, "lua", "sendRequest", msg, val)
		end
	end
end

function EntityManager:sendToAllPlayersByCamp(msg, val, entity, except)
	if not except then except = "" end
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.player and  string.find(except, v.serverId)==nil  then
			if v:isKind( entity ) then
				skynet.call(v.agent, "lua", "sendRequest", msg, val)
			end
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
			if v.entityType == EntityType.monster or v.entityType == EntityType.pet  then
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

function EntityManager:createPet(id,master,pos,isbody)
	isbody = isbody or 0
	local dir = vector3.create(0,0,0)
	local pet = IPet.new(pos,dir)
	g_entityManager:addEntity(pet)
	local pt = g_shareData.petRepository[id]
	pet.serverId = assin_server_id()	
	pet:init(pt,master)
	local _pet = {petId = id,serverId = pet.serverId,posx = 0,posz = 0,isbody = isbody}
	_pet.posx = math.ceil(pos.x * GAMEPLAY_PERCENT)
	_pet.posz = math.ceil(pos.z * GAMEPLAY_PERCENT)
	g_entityManager:sendToAllPlayers("summonPet",{pet = _pet } )
end

function EntityManager:getSkillAttackEntitys(source,target,skilldata)
	local type_range = GET_SkillTgtRange(skilldata)   -- 1:单体 2:自身点的圆形区域 3:自身点的矩形区域 4:目标点的圆形区域 5:飞行物碰撞 
	local type_target = GET_SkillTgtType(skilldata)  -- 1:自身 2:友方 3:敌方
	local tmpTb = {}
	if type_range == 1 then
		if source:getTarget() ~= nil and source:getTarget():getType() ~= "transform" then
			if skilldata.bCommonSkill ~= true and source:getTarget():getType() == "IBuilding" then
			
			else
				table.insert(tmpTb,source:getTarget())
			end
			return tmpTb
		end
	end
	--根据势力筛选出目标对象
	for _k,_v in pairs(self.entityList) do
		if type_target == 1 then
			table.insert(tmpTb,source)
			break
		elseif type_target == 2 then
			if _v.camp == source.camp then
				table.insert(tmpTb,_v)
			end
		elseif type_target == 3 then
			if _v.camp ~= source.camp and _v:getType() ~= "IBuilding" then
				table.insert(tmpTb,_v)
			end
		end
	end
	local getRangeEntitys = function(tab,basepos,range)
		local ret = {}
		for _k,_v  in pairs(tab) do
			local disVec = _v.pos:return_sub(basepos)
			local disLen = disVec:length()	
			if disLen <= range then
				table.insert(ret,_v)
			end
		end
		return ret
	end
	local getEntityRectange = function(tab,basepos,tgtpos,range)
		print("getEntityRectange",range)
		local w = range[1] 
		local h = range[2]
		local ret = {}
		--basepos = vector3.create(0,0,0)
		--tgtpos = vector3.create(1,0,0)
		local dir1 = tgtpos:return_sub(basepos)
		dir1:normalize()
		local dir2 = vector3.create(dir1.z,0,-dir1.x)
		local dot = {}
		dot[0] = basepos:return_add( dir2:return_mul_num(w) )
		dot[3] = basepos:return_sub( dir2:return_mul_num(w))
		local basepos2 = basepos:return_add( dir1:return_mul_num(h))
		dot[1] = basepos2:return_add( dir2:return_mul_num(w) )
		dot[2] = basepos2:return_sub( dir2:return_mul_num(w))
	--	for _k,_v in pairs(dot) do
	--		print("dot",_k,_v.x,_v.y,_v.z)	
	--	end
		for _k,_v in pairs(tab) do
			local isIn = ptInRect(_v.pos,dot) 
			if isIn == true then
				table.insert(ret,_v)		
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
		retTb = getEntityRectange(tmpTb,source.pos,target.pos,skilldata.n32Radius)
	elseif type_range == 4 then
		if source:getTarget() ~= nil then
			--print("gettarget is nil")
			retTb = getRangeEntitys(tmpTb,source:getTarget().pos,skilldata.n32Radius / 10000)	
		end
	elseif type_rang == 5 then	
	
	end
	return retTb
end

return EntityManager.new()


