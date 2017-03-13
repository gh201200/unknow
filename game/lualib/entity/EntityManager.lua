local skynet = require "skynet"
require "globalDefine"
local vector3 = require "vector3"
local IflyObj = require "entity.IflyObj"
local EntityManager = class("EntityManager")
local IPet = require "entity.Ipet"
function EntityManager:sendToAllPlayers(msg, val, except)
	if not except then except = "" end
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.player and  string.find(except, v.serverId)==nil and v.agent ~= nil  then
			skynet.call(v.agent, "lua", "sendRequest", msg, val)
		end
	end
end

function EntityManager:sendPlayer(player, msg, val)
	if player.agent then
		skynet.call(player.agent, "lua", "sendRequest", msg, val)
	end
end

function EntityManager:callAllAgents(msg, ...)
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.player and v.agent then
			skynet.call(v.agent, "lua", msg, ...)
		end
	end
end


function EntityManager:disconnectAgent(agent)
	for k, v in pairs(self.entityList) do
		if v.agent == agent then
			v.agent = nil
		end
	end
end

function EntityManager:sendToAllPlayersByCamp(msg, val, entity, except)
	if not except then except = "" end
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.player and  string.find(except, v.serverId)==nil  then
			if v:isSameCamp( entity ) then
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
				if v.isDead == true then
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

function EntityManager:createFlyObj(srcObj,target,skilldata,extra1,extra2)
	local obj = IflyObj.create(srcObj,target,skilldata,extra1,extra2)	
	self:addEntity(obj)
end

function EntityManager:createPet(id,master,pos)
	local dir = vector3.create(0,0,0)
	local pt = g_shareData.petRepository[id]
	local limitNum = pt.n32SummonLimit
	local pets = master.pets
	for i=#(pets),1,-1 do
		local v = pets[i]
		if v.pt.Serid == pt.Serid then
			limitNum = limitNum - 1
			if limitNum <= 0 then
				v.lifeTime = -1
			end
		end
	end
	local pet = IPet.new(pos,dir)
	g_entityManager:addEntity(pet)
	pet.serverId = assin_server_id()	
	pet:init(pt,master)
	table.insert(master.pets,pet)	
	local _pet = {petId = id,serverId = pet.serverId,posx = 0,posz = 0,camp = master.camp,masterId = master.serverId}
	_pet.posx = math.ceil(pos.x * GAMEPLAY_PERCENT)
	_pet.posz = math.ceil(pos.z * GAMEPLAY_PERCENT)
	g_entityManager:sendToAllPlayers("summonPet",{pet = _pet } )
end
function EntityManager:getTypeEntitys(source,skilldata,isSelect)
	local _type = "n32SelectTargetType" 
	if isSelect == false then
		_type = "n32AffectTargetType" 
	end
	local typeTargets = {}
	if skilldata[_type] == 0 then
		 table.insert(typeTargets,source)
		return typeTargets
	end
	for _ek,_ev in pairs(self.entityList) do
		if _ev ~= nil and (_ev:getType() == "IMapPlayer" or _ev:getType() == "IPet" or _ev:getType() == "IMonster" or  _ev:getType() == "IBuilding") then
			if _ev:getHp() > 0 and ((_ev.entityType == EntityType.building and skilldata.n32SkillType == 0) or _ev.entityType ~= EntityType.building)  then
				--友方（包含自己）
				if skilldata[_type]  == 1 and source:isKind(_ev) == true then
					table.insert(typeTargets,_ev)
				--友方（除掉自己）
				elseif skilldata[_type]  == 2 and source:isKind(_ev) == true and source ~= _ev then
					table.insert(typeTargets,_ev)
				--敌方
				elseif skilldata[_type]  == 3 and source:isKind(_ev) == false then	
					table.insert(typeTargets,_ev)
				--除自己所有人
				elseif skilldata[_type]  == 4 and source ~= _ev then
					table.insert(typeTargets,_ev)
				--所有人
				elseif skilldata[_type]  == 5 then
					table.insert(typeTargets,_ev)
				end
			end
		end
	end
	return typeTargets

end
--获取施法目标的范围的目标
function EntityManager:getSkillSelectsEntitys(source,target,skilldata,extra)
	extra = extra or source.dir
	local tgt = target 
	if skilldata.n32SkillTargetType == 0 then
		tgt = source
	end
	local typeTargets = self:getTypeEntitys(source,skilldata,true)
	local selects = {}
	if skilldata.szSelectRange[1] == 'single' then
		if (tgt:getType() ~= "transform" and tgt:getHp() > 0) or tgt:getType() == "transform"  then
			table.insert(selects,tgt)
		end
	elseif skilldata.szSelectRange[1] == 'circle' then
		local radius = 	skilldata.szSelectRange[2]
		local target_uplimit = skilldata.szSelectRange[3]
		local select_mod = skilldata.szSelectRange[4]
		local tSelects = {}
		local tNum = 0
		for _k,_v in pairs(typeTargets) do
			local disVec = tgt.pos:return_sub(_v.pos)
			local disLen = disVec:length()
			if disLen <= radius then
				tNum = tNum + 1
				--tSelects[int_disLen] = _v
				table.insert(tSelects,{key = disLen,value = _v})
			end
		end
		if select_mod == 1 then
			table.sort(tSelects,function(a,b) return a.key >= b.key end)
		else
			table.sort(tSelects,function(a,b) return a.key < b.key end)
		end
		local num  = 1 
		for _k,_v in pairs(tSelects) do
			if num <= target_uplimit or target_uplimit == -1 then
				table.insert(selects,_v.value)
				num  =  num + 1
			end
		end		
	elseif skilldata.szSelectRange[1] == 'sector' then
		for _k,_v in pairs(typeTargets) do
			local center = source.pos
			local uDir = extra --附加参数方向
			local r = skilldata.szSelectRange[2]
			local theta = skilldata.szSelectRange[3]
			if ptInSector(_v.pos,center,uDir,r,theta) then
				table.insert(selects,_v)
			end
		end		
	elseif skilldata.szSelectRange[1] == 'rectangle' then
		local w = skilldata.szSelectRange[3]
		local h = skilldata.szSelectRange[2]
		local ret = {}
		local dir1 = target.pos:return_sub(source.pos)
		dir1:normalize()
		local dir2 = vector3.create(dir1.z,0,-dir1.x)
		local dot = {}
		dot[0] = source.pos:return_add( dir2:return_mul_num(w) )
		dot[3] = source.pos:return_sub( dir2:return_mul_num(w))
		local pos2 = source.pos:return_add( dir1:return_mul_num(h))
		dot[1] = pos2:return_add( dir2:return_mul_num(w) )
		dot[2] = pos2:return_sub( dir2:return_mul_num(w))
		for _k,_v in pairs(typeTargets) do
			local isIn = ptInRect(_v.pos,dot) 
			if isIn == true then
				table.insert(selects,_v)		
			end	
		end
	end
	return selects
end

--获取效果范围的目标
function EntityManager:getSkillAffectEntitys(source,selects,skilldata,extra)
	local affects = {}
	local isAttack = (skilldata.n32SkillType == 0)
	if skilldata.n32AffectTargetType == 0 then
		table.insert(affects,source)
		return affects
	end
	local typeTargets = self:getTypeEntitys(source,skilldata,false)
	--print("#typeTargets",#typeTargets)
	for _tk,_tv in pairs(typeTargets) do
		for _sk,_sv in pairs(selects) do
		--	print("sv:",_sv.serverId,"tv",_tv.serverId)
			if skilldata.szAffectRange[1] == "single" and _sv == _tv then
				table.insert(affects,_tv)
			elseif skilldata.szAffectRange[1] == "circle" then
				local disVec = _tv.pos:return_sub(_sv.pos)
				local disLen = disVec:length()
				if disLen <= skilldata.szAffectRange[2] then
					table.insert(affects,_tv)
				end
			elseif skilldata.szAffectRange[1] == "sector" then
			--	print("get secotr",_sv.pos.x,_sv.pos.z)
				local center = _sv.pos
				local uDir = extra --附加参数方向
				local r = skilldata.szAffectRange[2]
				local theta = skilldata.szAffectRange[3]
				if ptInSector(_tv.pos,_sv.pos,uDir,r,theta) then
					table.insert(affects,_tv)
				end	
			end
		end 
	end
	return affects
end
return EntityManager.new()


