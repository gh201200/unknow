--local transfrom = require "entity.transfrom"
local vector3 = require "vector3"
local transfrom = require "entity.transfrom"
local IflyObj = class("IflyObj" , transfrom)
local Map = require "map.Map"
require "globalDefine"

function IflyObj.create(...)
	return  IflyObj.new(...)
end

function IflyObj:ctor(src,tgt,skilldata,extra1,extra2)
	self.source = src
	self.target = tgt

	IflyObj.super.ctor(self,nil,nil)
	self.pos = vector3.new(0,0,0)
	self.pos:set(src.pos.x,0,src.pos.z)
	self.skilldata = skilldata	
	self.effectdata = g_shareData.effectRepository[skilldata.n32BulletId]
	self.dir = vector3.new(0,0,0)
	self.dir:set(self.target.pos.x, 0, self.target.pos.z)
        self.dir:sub(self.pos)
        self.dir:normalize()
	self.moveSpeed = self.effectdata.n32speed
	self.targets = {}
	self.lifeTime = self.effectdata.n32time
	self.entityType = EntityType.flyObj 
	self.radius = self.effectdata.n32Redius
	self.isDead = false
	self.flyDistance = 0    --飞行距离
	self.flyTime = 0
	--链式弹道
	if self.skilldata.n32BulletType == 2 then
		self.lifeTime = 1 --链式弹道检测一次
		if extra1 == nil and extra2 == nil then
			self.linkIndex = 1
			self.caster = src
			self.parent = nil
		else
			self.caster = extra1 --施法者
			self.parent = extra2 --父弹道
			self.linkIndex = self.parent.linkIndex + 1
			--print("linkIndex==",self.linkIndex)
		end
		local dis = self.source:getDistance(self.target)
		if self.moveSpeed == -1 then
			self.flyTime = 0
		else
			self.flyTime = dis * 1000 / self.moveSpeed
		end
	elseif self.skilldata.n32BulletType == 5 then
	end
	local r = {acceperId = 0,producerId = self.source.serverId,effectId = self.skilldata.n32BulletId,effectTime = 0,flag = 0}
	r.posX = tostring(self.pos.x)
	r.posZ = tostring(self.pos.z)
	r.dirX = tostring(self.dir.x)
	r.dirZ = tostring(self.dir.z)
	if self.target:getType() ~= "transform" and self.skilldata.n32BulletType ~= 3 and self.skilldata.n32BulletType ~= 4  and self.skilldata.n32BulletType ~= 5 then
		r.acceperId = self.target.serverId
	end
	if self.skilldata.n32BulletType == 5 then
		local dis = self:getDistance(self.target)
		r.effectTime = math.floor(1000 * dis / self.moveSpeed) 
	end
	g_entityManager:sendToAllPlayers("pushEffect",r)

end
local dst = vector3.new(0,0,0)	

function IflyObj:getTarget()
	return self.target
end

function IflyObj:setTarget(t)
	self.target = t
end
function IflyObj:update(dt)
	--普通弹道
	if self.skilldata.n32BulletType == 1 then
		self:updateTarget(dt)
	--链式弹道
	elseif self.skilldata.n32BulletType == 2 then
		self:updateLink(dt)	
	--碰撞体弹道
	elseif self.skilldata.n32BulletType == 4 then
		self:updateCollider(dt)
	--指定地点爆炸类型
	elseif self.skilldata.n32BulletType == 5 then
		self:updateTargetBoom(dt)
	else
		self:updateNoTarget(dt)
	end
end

local function isInParentLinkTarget(_link,tgt)
	if _link.target == tgt then return true end
	if _link.parent and isInParentLinkTarget(_link.parent,tgt) == true then return true end
	return false
end
local function deadParentLink(_link)
	if _link ~= nil then
		print("deadParentLink")
		_link.isDead =  true
		deadParentLink(_link.parent)
	end
end
--链式弹道
function IflyObj:updateLink(dt)
	--推送给客户端特效
	self.flyTime = self.flyTime - dt
	if self.flyTime >= 0 then return end --未生效
	if self.lifeTime <= 0 then return end
	self.lifeTime = -1 --self.lifeTime - dt
	--print("updateLink",self.skilldata.szAffectRange)
	local tgt = nil
	if self.linkIndex < self.skilldata.szAffectRange[3] then
	   for i=#g_entityManager.entityList, 1, -1 do
		local v = g_entityManager.entityList[i]
		if v:getType() ~= "transform" then
			if (self.skilldata.n32AffectTargetType == 3 and self.caster:isKind(v) == false) or 
			(self.skilldata.n32AffectTargetType == 1 and self.caster:isKind(v) == true) then
				local dis = self.target:getDistance(v)
				if isInParentLinkTarget(self,v) == false and self.skilldata.szAffectRange[2] >= dis then
					tgt = v
					break
				end
			end
		end
	    end	
	end
	if tgt ~= nil then
		g_entityManager:createFlyObj(self.target,tgt,self.skilldata,self.caster,self)
	else
		--清除所有的父节点
		deadParentLink(self)	
	end
	local targets = {self.target}
	self.caster.spell:trgggerAffect(self.skilldata.szAffectTargetAffect,targets,self.skilldata)
end
--碰撞弹道
function IflyObj:updateCollider(dt)
	dt = dt / 1000.0
	self.flyDistance  = self.flyDistance + self.moveSpeed * dt
	dst:set(self.dir.x, self.dir.y, self.dir.z)
	dst:mul_num(self.moveSpeed * dt)
	dst:add(self.pos)
	self.pos:set(dst.x,0,dst.z)
	local _kind = true
	local _bomb = false
	if self.skilldata.n32BulletTarget == 0 then _kind = false end --敌方
	
	if self.flyDistance >= self.skilldata.n32BulletRange then
		print("outof distance===")
		_bomb = true	
	end
	local tgt = nil
	if _bomb == false then
		for i=#g_entityManager.entityList, 1, -1 do
			local v = g_entityManager.entityList[i]
			if v:getType() ~= "transform" then
				if self.source:isKind(v) == _kind then
					local dis  = self:getDistance(v)
					if dis <= self.radius then
						_bomb = true
						tgt = v
						break
					end
				end
			end
		end
	end
	if _bomb == true  then
		local d = {acceperId = 0,producerId = self.source.serverId,effectId = self.skilldata.n32BulletId,effectTime = 0,flag = 1}
		g_entityManager:sendToAllPlayers("pushEffect",d)

		if self.skilldata.n32BulletBombId ~= nil then
			--推送爆炸特效	
			local r = {acceperId = 0,producerId = self.source.serverId,effectId = self.skilldata.n32BulletBombId,effectTime = 0,flag = 0}
			r.posX = tostring(self.pos.x)
			r.posZ = tostring(self.pos.z)
			r.dirX = tostring(self.dir.x)
			r.dirZ = tostring(self.dir.z)
			g_entityManager:sendToAllPlayers("pushEffect",r)
		end
                local selects = { tgt }
                local targets = g_entityManager:getSkillAffectEntitys(self.source,selects,self.skilldata,self.dir)
                self.source.spell:trgggerAffect(self.skilldata.szAffectTargetAffect,targets,self.skilldata)	
		self.isDead = true
	end
	
end

function IflyObj:updateNoTarget(dt)
	if self.lifeTime <= 0 then
		self.isDead = true
		return
	end
	dt = dt / 1000
	self.lifeTime = self.lifeTime - dt
	dst:set(self.dir.x, self.dir.y, self.dir.z)
        dst:mul_num(self.moveSpeed * dt)
        dst:add(self.pos)
	self.pos:set(dst.x, 0, dst.z)
	for i=#g_entityManager.entityList, 1, -1 do
                local v = g_entityManager.entityList[i]
		if v:getType() ~= "transform" then
			if self.targets[v.serverId] == nil and v.serverId ~= self.source.serverId and v.camp ~= self.source.camp then
				local dis = self:getDistance(v)
				if dis <= self.radius  then	
					--添加buff
					self.targets[v.serverId] = 1
					v.affectTable:buildAffects(self.source,self.skilldata.szAffectTargetAffect,self.skilldata.id)	
				end
			end				
		end
	end
	--print("--------------------------end-------------------------------------------------")
end
--指定地点爆炸
function IflyObj:updateTargetBoom(dt)
	dt = dt / 1000.0
	self.dir:set(self.target.pos.x, 0, self.target.pos.z)
	self.dir:sub(self.pos)
        self.dir:normalize()
	dst:set(self.dir.x, self.dir.y, self.dir.z)
        dst:mul_num(self.moveSpeed * dt)
	dst:add(self.pos)
	self.pos:set(dst.x,0,dst.z)
	local dis = self:getDistance(self.target)
	if dis <= 0.2 then
		local d = {acceperId = 0,producerId = self.source.serverId,effectId = self.skilldata.n32BulletId,effectTime = 0,flag = 1}
		g_entityManager:sendToAllPlayers("pushEffect",d)
		if self.skilldata.n32BulletBombId ~= nil then
			--推送爆炸特效	
			local r = {acceperId = 0,producerId = self.source.serverId,effectId = self.skilldata.n32BulletBombId,effectTime = 0,flag = 0}
			r.posX = tostring(self.pos.x)
			r.posZ = tostring(self.pos.z)
			r.dirX = tostring(self.dir.x)
			r.dirZ = tostring(self.dir.z)
			g_entityManager:sendToAllPlayers("pushEffect",r)
		end
                local selects = { self.target }
                local targets = g_entityManager:getSkillAffectEntitys(self.source,selects,self.skilldata,self.dir)
                self.source.spell:trgggerAffect(self.skilldata.szAffectTargetAffect,targets,self.skilldata)	
		self.isDead = true
	end

end
function IflyObj:updateTarget(dt)
	dt = dt / 1000.0
	if self.target == nil  then 
		self.isDead = true
		return 
	end
	self.dir:set(self.target.pos.x, 0, self.target.pos.z)
	self.dir:sub(self.pos)
        self.dir:normalize()
	dst:set(self.dir.x, self.dir.y, self.dir.z)
        dst:mul_num(self.moveSpeed * dt)
	dst:add(self.pos)
	self.pos:set(dst.x,0,dst.z)
	local dis = self:getDistance(self.target)
	if dis <= 0.2 then
		--触发效果
		local selects = {self.target}
		local targets = g_entityManager:getSkillAffectEntitys(self.source,selects,self.skilldata)
		self.source.spell:trgggerAffect(self.skilldata.szAffectTargetAffect,targets,self.skilldata)
		self.isDead = true
	end
end
return IflyObj
