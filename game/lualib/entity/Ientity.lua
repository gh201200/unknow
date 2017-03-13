local skynet = require "skynet"
local vector3 = require "vector3"
local Rect = require "rect"
local spell =  require "skill.spell"
local passtiveSpell =  require "skill.passtiveSpell"
local cooldown = require "skill.cooldown"
local AffectTable = require "skill.Affects.AffectTable"
local Map = require "map.Map"
local transfrom = require "entity.transfrom"
local coroutine = require "skynet.coroutine"
local syslog = require "syslog"

local Ientity = class("Ientity" , transfrom)

local HP_MP_RECOVER_TIMELINE = 1000
local UI_Stats_Show = {
	Strength = true,
	Agility = true,
	Intelligence = true,
	HpMax = true,
	MpMax = true,
	Attack = true,
	Defence = true,
	ASpeed = true,
}

local function register_stats(t, name,dft)
	dft = dft or 0
	t['s_mid_'..name] = dft 
	t['addMid' .. name] = function(self, v)
		self['s_mid_'..name] = self['s_mid_'..name] + v
	end
	t['getMid'..name] = function(self)
		return t['s_mid_'..name]
	end
	t['s_'..name] = dft 
	t['set' .. name] = function (self, v)
		if v == self['s_'..name] then return end
		self['s_'..name] = v
		if UI_Stats_Show[name] then
			self.StatsChange = true
		end
	end
	t['get' .. name] = function(self)
		return self['s_'..name] 
	end
end


function Ientity:ctor(pos,dir)
	print("Ientity:ctor")
	Ientity.super.ctor(self,pos,dir)
	--entity world data about
	self.entityType = 0
	self.serverId = 0
	register_class_var(self, 'Level', 1)
	register_class_var(self, 'Gold', 0, self.onGold)
	register_class_var(self, 'Exp', 0, self.onExp)
	self.bornPos =  vector3.create()
	self.bbox = Rect.create()
	self.lastMoveDir =  vector3.create()
	self.camp = CampType.BAD  
	self.moveSpeed = 0
	self.lastMoveSpeed = 0
	self.curActionState = 0
	self.pathMove = nil
	self.pathNodeIndex = -1
	self.useAStar = false
	self.moveQuadrant = 0
	--event stamp handle about
	self.serverEventStamps = {}		--server event stamp
	self.newClientReq = {}		
	self.coroutine_pool = {}
	self.coroutine_response = {}
	--skynet about

	--att data
	self.attDat = nil
	self.modelDat = nil
	
	--技能相关----
	self.spell = spell.new(self)		 --技能
	self.affectTable = AffectTable.new(self) --效果表
	self.skillTable = {}	--可以释放的技能表
	self.CastSkillId = 0 	--正在释放技能的id
	self.ReadySkillId = 0	--准备释放技能的iastSkillId
	self.affectStateRefs = {} --状态计数
	
	self.triggerCast = true	 --是否触发技能
	self.targetPos = nil
	register_class_var(self, 'NewTarget', nil)
	self.attackNum = 0
	--stats about
	register_stats(self, 'Strength')
	register_stats(self, 'StrengthPc')
	register_stats(self, 'Agility')
	register_stats(self, 'AgilityPc')
	register_stats(self, 'Intelligence')
	register_stats(self, 'IntelligencePc')
	register_stats(self, 'Hp')
	register_stats(self, 'HpMax')
	register_stats(self, 'HpMaxPc')
	register_stats(self, 'Mp')
	register_stats(self, 'MpMax')
	register_stats(self, 'MpMaxPc')
	register_stats(self, 'Attack')
	register_stats(self, 'AttackPc')
	register_stats(self, 'AttackStrengthPc')
	register_stats(self, 'AttackAgilityPc')
	register_stats(self, 'AttackIntelligencePc')
	register_stats(self, 'Defence')
	register_stats(self, 'DefencePc')
	register_stats(self, 'ASpeed')
	register_stats(self, 'MSpeed')
	register_stats(self, 'MSpeedPc')
	register_stats(self, 'AttackRange')
	register_stats(self, 'AttackRangePc')
	register_stats(self, 'RecvHp')
	register_stats(self, 'RecvHpPc')
	register_stats(self, 'RecvMp')
	register_stats(self, 'RecvMpPc')
	register_stats(self, 'BaojiRate') 
	register_stats(self, 'BaojiTimes',1.0)
	register_stats(self, 'Hit',1.0)
	register_stats(self, 'Miss')
	register_stats(self, 'Shield')
	register_stats(self, 'Updamage',1.0)

	self.lastHp = 0

	self.recvTime = 0
	--cooldown
	self.cooldown = cooldown.new(self)
	self.maskHpMpChange = 0		--mask the reason why hp&mp changed 
	self.HpMpChange = false 	--just for merging the resp of hp&mp
	self.StatsChange = false	--just for merging the resp of stats
end

function Ientity:init()
	self.bbox.center:set(self.pos.x, self.pos.y, self.pos.z)
	self.bbox.width = self.modelDat.n32BSize
	self.bbox.height = self.modelDat.n32BSize
end

function Ientity:getType()
	return "Ientity"
end

function Ientity:clear_coroutine()
	--response to agent
	for k, v in pairs(self.coroutine_response) do
		for p, q in pairs(v) do
			q(true, nil)
		end
	end
	self.coroutine_response = {}
end

function Ientity:isKind(entity,_atk)
	if entity == nil then return true end
	if entity.camp == nil then return true end
	_atk = _atk or false
	if _atk == false then
		if entity:getType() == "IBuilding" then
		--	return true
		end		
	end
	if self.camp == CampType.KIND or entity.camp == CampType.KIND then
		return true
	end
	if self.camp == CampType.BAD or entity.camp == CampType.BAD then
		return false
	end
	return self.camp == entity.camp
end
function Ientity:advanceEventStamp(event)
	if not self.serverEventStamps[event] then
		self.serverEventStamps[event] = 0
	end

	self.serverEventStamps[event] = self.serverEventStamps[event] + 1

	if self.newClientReq[event] then 
		self.newClientReq[event] = false				
		respClientEventStamp(self.coroutine_pool[event], self.serverId, event)
		self:onRespClientEventStamp(event)
	end
end

function Ientity:checkeventStamp(event, stamp)
	--print("checkeventStamp",event,self.serverEventStamps[event],stamp) 
	if not self.serverEventStamps[event] then
		self.serverEventStamps[event] = 0
	end

	if  self.serverEventStamps[event] > stamp then 
		self.newClientReq[event] = false				
		respClientEventStamp(self.coroutine_pool[event], self.serverId, event)
		self:onRespClientEventStamp(event)
	else
		self.newClientReq[event] = true				--mark need be resp
	end
end

function Ientity:onRespClientEventStamp(event)
	if event == EventStampType.Hp_Mp then
		self.maskHpMpChange = 0
	end
end

function Ientity:setActionState(_speed, _action)
	self.moveSpeed = _speed
	self.curActionState = _action
	if _action < ActionState.forcemove then 
		self:advanceEventStamp(EventStampType.Move)
	end
end

function Ientity:canStand()
	if self:getHp() <= 0 then
		return false
	end
	return true
end

function Ientity:stand()
	if self:canStand() == false then return end
	self:setActionState(0, ActionState.stand)
	self:clearPath()
	self.moveQuadrant = 0
end

function Ientity:clearPath()
	self.pathNodeIndex = -1
	self.useAStar = false
	self.pathMove = nil
end

function Ientity:pathFind(dx, dz)
	Map:add(self.pos.x, self.pos.z, 0, self.modelDat.n32BSize)
	if self:getTarget():getType() ~= "transform" then	--目标是物体
		Map:add(self:getTarget().pos.x, self:getTarget().pos.z, 0, self:getTarget().modelDat.n32BSize)
	end

	self.pathMove = Map:find(self.pos.x, self.pos.z, dx, dz, self.modelDat.n32BSize)
	
	Map:add(self.pos.x, self.pos.z, 1, self.modelDat.n32BSize)
	if self:getTarget():getType() ~= "transform" then	--目标是物体
		Map:add(self:getTarget().pos.x, self:getTarget().pos.z, 1, self:getTarget().modelDat.n32BSize)
	end
	
	self.pathNodeIndex = 3
	self.useAStar = #self.pathMove > self.pathNodeIndex
	if not self.useAStar then
		print(Map.POS_2_GRID(self.pos.x),Map.POS_2_GRID(self.pos.z),Map.POS_2_GRID(dx),Map.POS_2_GRID(dz))
	end
	print(self.pathMove)
	return self.useAStar
end

function Ientity:setTarget(target)
	if not target then
		self:stand()
		self:setTargetVar( nil ) 
		return 
	end
	
	if self:isDead() then return end
	--打断技能
	if target ~= self:getTarget() and self.spell:isSpellRunning() ==  true and self.spell:canBreak(ActionState.move) == true then
		self.spell:breakSpell()
	end

	if self:canMove()  == 0 then	
		self:setTargetVar( target )
	else
		self:setNewTarget(target)
	end
	if self:canMove() == 0 then
		if self.ReadySkillId ~= 0 and self:canCast(self.ReadySkillId) == 0 then
			self:castSkill(self.ReadySkillId)
		else
			local skilldata = g_shareData.skillRepository[self.ReadySkillId]
			if skilldata ~= nil and skilldata.n32SkillType == 0 and self:getTarget() ~= nil and self:getTarget():getType() ~= "transform" then
				local dis = self:getDistance(self:getTarget())
				if dis > skilldata.n32Range then
					self:setActionState( self:getMSpeed(), ActionState.move)
				end	
			else	
				self:setActionState( self:getMSpeed(), ActionState.move)
			end
		
		end
	end
end


function Ientity:clearTarget(mask)
	if self:getTarget() == nil then return end
	--清除目标，mask控制类型
	mask = mask or 1
	if bit_and(mask,1) ~= 0 and self:getTarget():getType() == "transform" then
		self:setTarget(nil)
	end
end

function Ientity:setTargetPos(target)
	if self:isDead() then return end
	if target == nil then return end
	self.moveQuadrant = 0
	local pos = vector3.create(target.x,0,target.z)
	
	if Map:isBlock( pos.x, pos.z ) then
		Map:lineTest(self.pos, pos)
	end
	if self:canMove() == 0 then
		self:setTarget(transfrom.new(pos,nil))
	else
		self:setNewTarget(transfrom.new(pos,nil))
	end
end
function Ientity:update(dt)
	if self:isDead() == false then
		self.spell:update(dt)
		self.cooldown:update(dt)
		self.affectTable:update(dt)	
	end
	if self:getNewTarget() ~= nil and self:canMove() == 0 and  self:getNewTarget() ~= self:getTarget() then
		self:setTarget(self:getNewTarget())
		self:setNewTarget(nil)
	end
	self:recvHpMp(dt)
	--add code before this
	if self.HpMpChange then
		self:advanceEventStamp(EventStampType.Hp_Mp)
		self.HpMpChange = false
	end
	
	if self.StatsChange then
		self:advanceEventStamp(EventStampType.Stats)
		self.StatsChange = false
	end
	if self:isDead() == false and self.entityType ~= EntityType.building and self.entityType ~= EntityType.trap then
		if self.curActionState == ActionState.move and self:canMove() == 0 then
			self:onMove2(dt)
		elseif self.curActionState == ActionState.stand then
			--站立状态
		elseif self.curActionState >= ActionState.forcemove then
			--强制移动
			self:onForceMove(dt)	
		end
	end
	if self.ReadySkillId ~= 0  then	
		local err = self:canCast(self.ReadySkillId)
		if err == 0 then
			self:castSkill(self.ReadySkillId)
		end
	end

end

--是否与其他entity相交
function Ientity:isCrossWith( pos )
	local c = nil
	self.bbox.center:set(pos.x , pos.y, pos.z)
	for k, v in pairs( g_entityManager.entityList ) do
		if v.serverId ~= self.serverId then
			if self.bbox:isCrossRect( v.bbox ) then
				c = v
				break
			end
		end
	end
	self.bbox.center:set(self.pos.x , self.pos.y,self.pos.z)
	return c
end

function Ientity:isCrossWithEntity( entity )
	if vector3.len_2(self.pos, entity.pos) < math.pow2(self.modelDat.n32BSize + entity.modelDat.n32BSize) then
		return true
	end
	return false
end

function Ientity:isLegalGrid( pos )
	Map:add(self.pos.x, self.pos.z, 0, self.modelDat.n32BSize)
	local gx = Map.POS_2_GRID( pos.x )
	local gz = Map.POS_2_GRID( pos.z )

	local legal = true
	local s = math.floor(self.modelDat.n32BSize / 2)
	for i=-s, s do
		for j=-s, s do
			local w =  Map:block(gx+i, gz+j)
			if w > 0 then 
				legal = false 
				break 
			end
		end
		if not legal then break end
	end
	Map:add(self.pos.x, self.pos.z, 1, self.modelDat.n32BSize)
	--Map:dump()
	return legal
end

--注意：修改entity位置，一律用此函数
function Ientity:setPos(x, y, z, r)
	--print('set pos = ',x, y, z)
	if not self:isDead() then
		Map:add(self.pos.x, self.pos.z, 0, self.modelDat.n32BSize)
		Map:add(x, z, 1, self.modelDat.n32BSize)
	end
	self.pos:set(x, y, z)
	self.bbox.center:set(self.pos.x, self.pos.y, self.pos.z)
end

local mv_dst = vector3.create()
local mv_slep_dir = vector3.create()
local legal_pos = false
--进入移动状态
--[[
function Ientity:onMove(dt)
	dt = dt / 1000		--second
	if self.moveSpeed <= 0 then return end
	if self.useAStar then
		self.dir:set(Map.GRID_2_POS(self.pathMove[self.pathNodeIndex]), 0, Map.GRID_2_POS(self.pathMove[self.pathNodeIndex+1]))
	else
		self.dir:set(self:getTarget().pos.x, 0, self:getTarget().pos.z)
	end
	self.dir:sub(self.pos)
	self.dir:normalize()
	mv_dst:set(self.dir.x, self.dir.y, self.dir.z)
	mv_dst:mul_num(self.moveSpeed * dt)
	mv_dst:add(self.pos)
	
	repeat
		legal_pos = true
		if self.useAStar then break end
		--check iegal
		if Map.IS_SAME_GRID(self.pos, mv_dst) == false then
			if Map:get(mv_dst.x, mv_dst.z) > 0 then
				legal_pos = false
				local nearBy = false
				local doNotUseAstar = false
				local angle = 60
				--repeat
					if Map.IS_NEIGHBOUR_GRID(self.pos, self:getTarget().pos) then
						doNotUseAstar = true
						break
					end 
					mv_slep_dir:set(self.dir.x, self.dir.y, self.dir.z)
					mv_slep_dir:rot(angle)
					mv_dst:set(mv_slep_dir.x, mv_slep_dir.y, mv_slep_dir.z)
					mv_dst:mul_num(self.moveSpeed * dt)
					mv_dst:add(self.pos)
					if Map.IS_SAME_GRID(self.pos, mv_dst) or  Map:get(mv_dst.x, mv_dst.z) == 0 then
						nearBy = true
						self.dir:set(mv_slep_dir.x, mv_slep_dir.y, mv_slep_dir.z)
					end
					if nearBy then 
						legal_pos = true
						break 
					end
					angle = angle + 30

				--until angle > 150
				
				if not nearBy and not doNotUseAstar then
					print('use a star to find a path')
					--nearBy = self:pathFind(self:getTarget().pos.x, self:getTarget().pos.z)
				end
				if not nearBy then
					self:stand()
					break
				end
			end
		end
	until true
	
	if self.useAStar then
		--移动到下一节点
		if self.pathMove[self.pathNodeIndex] == Map.POS_2_GRID(mv_dst.x) and self.pathMove[self.pathNodeIndex+1] == Map.POS_2_GRID(mv_dst.z) then
			self.pathNodeIndex = self.pathNodeIndex + 2
		end
		if self.pathNodeIndex >= #self.pathMove then
			self:stand()
			self:clearTarget(1)
		end
	elseif self:getTarget() then
		if self:getTarget():getType() ~= "transform" then	--目标是物体
			if self:getDistance(self:getTarget()) <= (self:getShapeSize()+self:getTarget():getShapeSize())/2*Map.MAP_GRID_SIZE + 0.05 then
				self:stand()
			end
		else	
			--if Map.IS_SAME_GRID(self.pos, self:getTarget().pos) then	--目标是地面
			if math.abs(self.pos.x-self:getTarget().pos.x) < 0.02 and math.abs(self.pos.z-self:getTarget().pos.z) < 0.02 then
				self:stand()
				self:clearTarget(1)
			end
		end
	end

	if legal_pos then
		--move
		self:setPos(mv_dst.x, mv_dst.y, mv_dst.z)
		--advance move event stamp
		self:advanceEventStamp(EventStampType.Move)
	end
end
]]--

function Ientity:onMove2(dt)
	dt = dt / 1000		--second
	if self.moveSpeed <= 0 then return end
	if self.useAStar then
		self.dir:set(Map.GRID_2_POS(self.pathMove[self.pathNodeIndex]), 0, Map.GRID_2_POS(self.pathMove[self.pathNodeIndex+1]))
	else
		if self:getTarget() == nil then
			self:stand()
			return
		end
		self.dir:set(self:getTarget().pos.x, 0, self:getTarget().pos.z)
	end
	self.dir:sub(self.pos)
	self.dir:normalize()
	mv_dst:set(self.dir.x, self.dir.y, self.dir.z)
	mv_dst:mul_num(self.moveSpeed * dt)
	mv_dst:add(self.pos)
	repeat
		legal_pos = true
		--check iegal
		
		if self.useAStar then
			if self:isLegalGrid( mv_dst ) == false then
				egal_pos = false
				print('use a star to find a path again 11',self.serverId)
				nearBy = self:pathFind(self:getTarget().pos.x, self:getTarget().pos.z)
				if not nearBy then
					self:stand()
					return
				end
			end
			break
		end
		
		if self:isLegalGrid( mv_dst ) == false then
			legal_pos = false
			local nearBy = false
			local doNotUseAstar = false
			local angle = 30
			--[[
			if self.moveQuadrant == 0 then	
				local quadrant = Map:quadrantTest( self.pos )
				if quadrant == 1 or quadrant == 4 then
					self.moveQuadrant = -1
				else
					self.moveQuadrant = 1
				end
			end
			--]]
			self.moveQuadrant = 1
			repeat
				if Map.IS_NEIGHBOUR_GRID(self.pos, self:getTarget().pos) then
					doNotUseAstar = true
					break
				end 
				mv_slep_dir:set(self.dir.x, self.dir.y, self.dir.z)
				mv_slep_dir:rot(angle*self.moveQuadrant)
				mv_dst:set(mv_slep_dir.x, mv_slep_dir.y, mv_slep_dir.z)
				mv_dst:mul_num(self.moveSpeed * dt)
				mv_dst:add(self.pos)
				if self:isLegalGrid( mv_dst ) then
					nearBy = true
					self.dir:set(mv_slep_dir.x, mv_slep_dir.y, mv_slep_dir.z)
				end
				if nearBy then 
					legal_pos = true
					break 
				end
				angle = angle + 30

			until angle > 150

			if not nearBy and not doNotUseAstar then
				print('use a star to find a path',self.serverId)
				nearBy = self:pathFind(self:getTarget().pos.x, self:getTarget().pos.z)	
				if not nearBy then
					--Map:dump()
					--print('use a star to find a path stand',self.serverId)
					self:stand()
					return
				end
			end
			if not nearBy then
				--print('use a star to find a path again i333',self.serverId)
				self:stand()
				break
			end
		end
	until true
	if self.useAStar then
		--移动到下一节点
		if self.pathMove[self.pathNodeIndex] == Map.POS_2_GRID(mv_dst.x) and self.pathMove[self.pathNodeIndex+1] == Map.POS_2_GRID(mv_dst.z) then
			self.pathNodeIndex = self.pathNodeIndex + 2
		end
		if self.pathNodeIndex >= #self.pathMove then
			self:stand()
			self:clearTarget(1)
		end
	elseif self:getTarget() then
		if self:getTarget():getType() == "transform" then	--目标是物体
			--if Map.IS_SAME_GRID(self.pos, self:getTarget().pos) then	--目标是地面
			if math.abs(self.pos.x-self:getTarget().pos.x) < 0.02 and math.abs(self.pos.z-self:getTarget().pos.z) < 0.02 then
				self:stand()
				self:clearTarget(1)
			end
		end
	end

	if legal_pos then
		--move
		self:setPos(mv_dst.x, mv_dst.y, mv_dst.z)
		local statechange = true
		local xx = 0
		local zz = 0
		repeat
			xx = math.ceil(self.dir.x * GAMEPLAY_PERCENT) 
			zz = math.ceil(self.dir.z * GAMEPLAY_PERCENT) 
			if self.lastMoveSpeed ~= self.moveSpeed then break end
			if self.lastMoveDir.x ~= xx then break end
			if self.lastMoveDir.z ~= zz then break end
			statechange = false
		until true
		if statechange then
			self.lastMoveDir:set(xx, 0, zz)
			self.lastMoveSpeed = self.moveSpeed
			--advance move event stamp
			self:advanceEventStamp(EventStampType.Move)
		end
	end
end

--强制移动（魅惑 嘲讽 冲锋等）
function Ientity:onForceMove(dt)
	dt = dt / 1000
	local fSpeed = self.moveSpeed
	local mv_dst = vector3.create()
	if Map.IS_SAME_GRID(self.pos,self.targetPos.pos) then
		--self:stand()
	end
	self.dir:set(self.targetPos.pos.x, 0, self.targetPos.pos.z)
	self.dir:sub(self.pos)
	self.dir:normalize()
	mv_dst:set(self.dir.x, self.dir.y, self.dir.z)
	mv_dst:mul_num(fSpeed * dt)
	mv_dst:add(self.pos)
	if Map:isWall(mv_dst.x ,mv_dst.z) == true then
		--self:stand()
		--return
	end
	self:setPos(mv_dst.x, 0, mv_dst.z)
	print("onForceMove self.pos:",self.pos.x,self.pos.z)	
	print("onForceMove self.targetPos:",self.targetPos.pos.x,self.targetPos.pos.z)	
	local len  = vector3.len(self.pos,self.targetPos.pos)
	if len <= 0.1 then
		self:OnStand()
	end	
end
--闪现
function Ientity:onBlink(des)
	if Map:get(des.x,des.z)	~= 0 then
		local gx =  Map.POS_2_GRID(des.x)
		local gz = Map.POS_2_GRID(des.z)
		local t = { {1,0},{-1,0},{0,1},{0,-1}}
		local lt = {}
		for _k,_v in pairs(t) do
			if Map.legal(gx+ _v[1], gz +  _v[2]) then
				table.insert(lt,_v)
			end
		end
		local i = math.random(1,#lt)
		gx = lt[i][1] + gx
		gz = lt[i][2] + gz
		des.x = Map.GRID_2_POS(gx)
		des.z = Map.GRID_2_POS(gz)	
	end
	self:setPos(des.x, des.y, des.z)
 		
	local r = {srcId = self.serverId,targetPos = {}}
	r.targetPos = {x=math.ceil(self.pos.x*GAMEPLAY_PERCENT), y= 0,z=math.ceil(self.pos.z*GAMEPLAY_PERCENT)}
	g_entityManager:sendToAllPlayers("setPosition",r)	
end

--进入站立状态
function Ientity:OnStand()
	self:stand()
end

function Ientity:isDead()
	return self:getHp() <= 0
end

function Ientity:onDead()
	print('Ientity:onDead', self.serverId)
	self.spell:breakSpell()
	--self:setActionState(0, ActionState.die)
	for k, v in pairs(g_entityManager.entityList) do
		if v:getTarget() == self then
			print("onDead===",v.serverId,self.serverId)
			v:setTarget(nil)
		end
		if v.entityType == EntityType.monster then
			v.hateList:removeHate( self )
		end
	end
	self.ReadySkillId = 0
	self.affectTable:clear() --清除所有的buff
	for k,v in pairs(self.spell.passtiveSpells) do
		v:onDead()
	end
	self.spell.passtiveSpells = {}
end

function Ientity:onRaise()
	self:addHp(self:getHpMax(), HpMpMask.RaiseHp)
	self:addMp(self:getMpMax(), HpMpMask.RaiseMp)
	
	--学习被动技能
	for _k,_v in pairs(self.skillTable) do
		local id = _k + _v - 1
		local skilldata = g_shareData.skillRepository[id]	
		if skilldata ~= nil and skilldata.n32Active == 1 then
			local ps = passtiveSpell.new(self,skilldata)
			table.insert(self.spell.passtiveSpells,ps)
		end
	end
end

function Ientity:isAffectState(state)
	if self.affectStateRefs[state] ~= nil and self.affectStateRefs[state] > 0 then 
		return true
	else
		return false
	end
end

function Ientity:addAffectState(argState,num)
	local states = {}
	for k,v in pairs(AffectState) do
		if bit_and(argState,v) ~= 0 then
			states[v] = 1
		end
	end
	for state,v in pairs(states) do
		if self.affectStateRefs[state] == nil then
			self.affectStateRefs[state] = 0 
		end
		if num == 1 and AffectState.NoMove == state then
			self:stand()
		end
		self.affectStateRefs[state] = self.affectStateRefs[state] + num
	end
end

function Ientity:addHp(_hp, mask, source)

	isDelay = isDelay or false 
	_hp = math.floor(_hp)
	if _hp == 0 then return end
	assert(_hp > 0 or source, "you must set the source")
	if not mask then
		mask = HpMpMask.SkillHp
	end
	self.lastHp = self:getHp()
	self:setHp(mClamp(self.lastHp+_hp, 0, self:getHpMax()))
	--不死状态
	if self:isAffectState(AffectState.NoDead) or self:isAffectState(AffectState.Invincible) then
		if self:getHp() <= 0 then
			self:setHp(1)
		end
	end
	if  self.lastHp ~= self:getHp() then	
		self.maskHpMpChange = self.maskHpMpChange | mask
		--self.HpMpChange = true
		self:advanceEventStamp(EventStampType.Hp_Mp)
	end
	if self.lastHp > 0 and self:getHp() <= 0 then
		self:onDead()
	end
end


function Ientity:addMp(_mp, mask, source)
	_mp = math.floor(_mp)
	if _mp == 0 then return  end
	if not mask then
		mask = HpMpMask.SkillMp
	end
	self.lastMp = self:getMp()
	self:setMp(mClamp(self.lastMp+_mp, 0, self:getMpMax()))
	if self.lastMp ~= self:getMp() then	
		self.maskHpMpChange = self.maskHpMpChange | mask
		self.HpMpChange = true
	end
end

function Ientity:recvHpMp()
	if self:getHp() <= 0 then return end
	if self:getRecvHp() <= 0 and self:getRecvMp() <= 0 then return end
	if self:getHp() == self:getHpMax() then return end
	local curTime = skynet.now()
	if self.recvTime == 0 then
		self.recvTime = curTime
	end    

	if (curTime - self.recvTime) * 10  > HP_MP_RECOVER_TIMELINE then
		local cnt = math.floor((curTime - self.recvTime) * 10 / HP_MP_RECOVER_TIMELINE)
		self.recvTime = curTime
 		self:addHp(self:getRecvHp() * cnt , HpMpMask.TimeLineHp)
 		self:addMp(self:getRecvMp() * cnt , HpMpMask.TimeLineMp)
 	end
end

---------------------------------------stats about---------------------------------
function Ientity:dumpStats()
	print('Strength = '..self:getStrength())
	print('Agility = '..self:getAgility())
	print('Intelligence = '..self:getIntelligence())
	print('Hp = '..self:getHp())
	print('HpMax = '..self:getHpMax())
	print('Mp = '..self:getMp())
	print('MpMax = '..self:getMpMax())
	print('Attack = '..self:getAttack())
	print('Defence = '..self:getDefence())
	print('ASpeed = '..self:getASpeed())
	print('MSpeed = '..self:getMSpeed())
	print('AttackRange = '..self:getAttackRange())
	print('RecvHp = '..self:getRecvHp())
	print('RecvMp = '..self:getRecvMp())
	print('BaojiRate = '..self:getBaojiRate()) 
	print('BaojiTimes = '..self:getBaojiTimes())
	print('Hit = '..self:getHit())
	print('Miss = '..self:getMiss())

end

function Ientity:dumpMidStats()
	print('Mid Strength = '..self:getMidStrength())
	print('Mid StrengthPc = '..self:getMidStrengthPc ())
	print('Mid Agility = '..self:getMidAgility ())
	print('Mid AgilityPc = '..self:getMidAgilityPc ())
	print('Mid Intelligence = '..self:getMidIntelligence ())
	print('Mid IntelligencePc = '..self:getMidIntelligencePc ())
	print('Mid Hp = '..self:getMidHp ())
	print('Mid HpMax = '..self:getMidHpMax ())
	print('Mid HpMaxPc = '..self:getMidHpMaxPc ())
	print('Mid Mp = '..self:getMidMp ())
	print('Mid MpMax = '..self:getMidMpMax ())
	print('Mid MpMaxPc = '..self:getMidMpMaxPc ())
	print('Mid Attack = '..self:getMidAttack ())
	print('Mid AttackPc = '..self:getMidAttackPc ())
	print('Mid Defence = '..self:getMidDefence ())
	print('Mid DefencePc = '..self:getMidDefencePc ())
	print('Mid ASpeed = '..self:getMidASpeed ())
	print('Mid MSpeed = '..self:getMidMSpeed ())
	print('Mid MSpeedPc = '..self:getMidMSpeedPc ())
	print('Mid AttackRange = '..self:getMidAttackRange ())
	print('Mid AttackRangePc = '..self:getMidAttackRangePc ())
	print('Mid RecvHp = '..self:getMidRecvHp ())
	print('Mid RecvHpPc = '..self:getMidRecvHpPc ())
	print('Mid RecvMp = '..self:getMidRecvMp ())
	print('Mid RecvMpPc = '..self:getMidRecvMpPc ())
	print('Mid BaojiRate = '..self:getMidBaojiRate ()) 
	print('Mid BaojiTimes = '..self:getMidBaojiTimes ())
	print('Mid Hit = '..self:getMidHit ())
	print('Mid Miss = '..self:getMidMiss ())
end

function Ientity:calcStrength()
	self:setStrength(math.floor(
		math.floor((self.attDat.n32Strength
		+ self.attDat.n32LStrength * (self:getLevel()-1)) 
		* (1.0 + self:getMidStrengthPc())) 
		+ self:getMidStrength())
	)
end

function Ientity:calcAgility()
	self:setAgility(math.floor(
		math.floor((self.attDat.n32Agility 
		+ self.attDat.n32LAgility * (self:getLevel() - 1)) 
		* (1.0 + self:getMidAgilityPc())) 
		+ self:getMidAgility())
	)
end

function Ientity:calcIntelligence()
	self:setIntelligence(math.floor(
		math.floor((self.attDat.n32Intelligence 
		+ self.attDat.n32LIntelligence * (self:getLevel() - 1)) 
		* (1.0 + self:getMidIntelligencePc())) 
		+ self:getMidIntelligence())
	)
end

function Ientity:calcHpMax()
	local pc = self:getHp() / self:getHpMax()
	self:setHpMax(math.floor(
		self.attDat.n32Hp * (1.0 + self:getMidHpMaxPc())) 
		+ self:getMidHpMax() 
		+ math.floor((self.attDat.n32Strength + self.attDat.n32LStrength * (self:getLevel() - 1)) * g_shareData.lzmRepository[1].n32Hp)
                + math.floor((self.attDat.n32Agility + self.attDat.n32LAgility * (self:getLevel() - 1 )) * g_shareData.lzmRepository[2].n32Hp)
                + math.floor((self.attDat.n32Intelligence + self.attDat.n32LIntelligence * (self:getLevel() - 1)) * g_shareData.lzmRepository[3].n32Hp)
		)

	self:addHp(math.floor(pc * self:getHpMax()) - self:getHp(),HpMpMask.UpgradeHp,self)
end

function Ientity:calcMpMax()
	local pc = self:getMp() / self:getMpMax()
	self:setMpMax(math.floor(
		self.attDat.n32Mp * (1.0 + self:getMidMpMaxPc())) 
		+ self:getMidMpMax() 
		+ math.floor((self.attDat.n32Strength + self.attDat.n32LStrength * (self:getLevel() - 1)) * g_shareData.lzmRepository[1].n32Mp)
		+ math.floor((self.attDat.n32Agility + self.attDat.n32LAgility * (self:getLevel() - 1 )) * g_shareData.lzmRepository[2].n32Mp)
		+ math.floor((self.attDat.n32Intelligence + self.attDat.n32LIntelligence * (self:getLevel() - 1)) * g_shareData.lzmRepository[3].n32Mp)
	)
	self:addMp(math.floor(pc * self:getMpMax()) - self:getMp(),HpMpMask.UpgradeMp,self)
end

function Ientity:calcAttack()
	local addVal = 0
	if self.attDat.n32MainAtt==1 then
		addVal = math.floor((self.attDat.n32Strength + self.attDat.n32LStrength * (self:getLevel()-1)) * g_shareData.lzmRepository[1].n32Attack)
	elseif self.attDat.n32MainAtt==2 then
		addVal =  math.floor((self.attDat.n32Agility + self.attDat.n32LAgility * (self:getLevel() - 1)) * g_shareData.lzmRepository[2].n32Attack)
	elseif self.attDat.n32MainAtt==3 then
		addVal =  math.floor((self.attDat.n32Intelligence + self.attDat.n32LIntelligence * (self:getLevel() - 1)) * g_shareData.lzmRepository[3].n32Attack)
	end
	local extra = self:getMidAttackStrengthPc() * self:getStrength() + self:getMidAttackAgilityPc() * self:getAgility() + self:getMidAttackIntelligencePc() * self:getIntelligence()
	self:setAttack(math.floor(
		(self.attDat.n32Attack  + addVal)* (1.0 + self:getMidAttackPc())) 
		+ self:getMidAttack() + extra
	)
end

function Ientity:calcDefence()
	self:setDefence(math.floor(
		math.floor(self.attDat.n32Defence * (1.0 + self:getMidDefencePc())) 
		+ self:getMidDefence() 
		+ math.floor((self.attDat.n32Strength + self.attDat.n32LStrength * (self:getLevel() - 1) ) * g_shareData.lzmRepository[1].n32Defence)
		+ math.floor((self.attDat.n32Agility + self.attDat.n32LAgility * (self:getLevel() - 1) ) * g_shareData.lzmRepository[2].n32Defence)
		+ math.floor((self.attDat.n32Intelligence + self.attDat.n32LIntelligence * (self:getLevel() - 1) ) * g_shareData.lzmRepository[3].n32Defence)
		)
	)
end

function Ientity:calcASpeed()
	self:setASpeed(
		self.attDat.n32ASpeed / ( 
			1 + self:getMidASpeed() 
                	+ (self.attDat.n32Strength + self.attDat.n32LStrength * (self:getLevel() - 1)) * g_shareData.lzmRepository[1].n32ASpeed
                	+ (self.attDat.n32Agility + self.attDat.n32LAgility * (self:getLevel() - 1 )) * g_shareData.lzmRepository[2].n32ASpeed
                	+ (self.attDat.n32Intelligence + self.attDat.n32LIntelligence * (self:getLevel() - 1)) * g_shareData.lzmRepository[3].n32ASpeed
		)
	)
end

function Ientity:calcMSpeed()
	self:setMSpeed(
		self.attDat.n32MSpeed * (1.0 + self:getMidMSpeedPc())
		+ self:getMidMSpeed() 
	)
	self.moveSpeed = self:getMSpeed()
end

function Ientity:calcRecvHp()
	self:setRecvHp(math.floor(
		self.attDat.n32RecvHp * (1.0 + self:getMidRecvHpPc()))
		+ self:getMidRecvHp()
                + math.floor((self.attDat.n32Strength + self.attDat.n32LStrength * (self:getLevel() - 1)) * g_shareData.lzmRepository[1].n32RecvHp)
                + math.floor((self.attDat.n32Agility + self.attDat.n32LAgility * (self:getLevel() - 1 )) * g_shareData.lzmRepository[2].n32RecvHp)
                + math.floor((self.attDat.n32Intelligence + self.attDat.n32LIntelligence * (self:getLevel() - 1)) * g_shareData.lzmRepository[3].n32RecvHp)
	)
end

function Ientity:calcRecvMp()
	self:setRecvMp(math.floor(
		self.attDat.n32RecvMp * (1.0 + self:getMidRecvMpPc()))
		+ self:getMidRecvMp()
                + math.floor((self.attDat.n32Strength + self.attDat.n32LStrength * (self:getLevel() - 1)) * g_shareData.lzmRepository[1].n32RecvMp)
                + math.floor((self.attDat.n32Agility + self.attDat.n32LAgility * (self:getLevel() - 1 )) * g_shareData.lzmRepository[2].n32RecvMp)
                + math.floor((self.attDat.n32Intelligence + self.attDat.n32LIntelligence * (self:getLevel() - 1)) * g_shareData.lzmRepository[3].n32RecvMp)	
	)
end

function Ientity:calcAttackRange()
	--[[
	self:setAttackRange(math.floor(
		self.attDat.n32AttackRange * (1.0 +self:getMidAttackRangePc()/GAMEPLAY_PERCENT))
		+ self:getMidAttackRange()
	)
	]]--
end

function Ientity:calcBaoji()
	self:setBaojiRate(self:getMidBaojiRate())
	self:setBaojiTimes(self:getMidBaojiTimes())
end

function Ientity:resetBaoji()
	self:setBaojiRate(0)
	self:setBaojiTimes(1)
end

function Ientity:calcHit()
	self:setHit(self:getMidHit())
end

function Ientity:calcMiss()
	self:setMiss(self:getMidMiss())
end

function Ientity:calUpdamage()
	self:setUpdamage(self:getMidUpdamage())
end

function Ientity:calShield()
	self:setShield(self:getMidShield())
end

---------------------------------------------------------------------------------技能相关------------------------------------------------------------------------------------------------------------------

function Ientity:callBackSpellBegin()

end

function Ientity:callBackSpellEnd()
	if self.entityType ~= EntityType.player	then
		self.ReadySkillId = 0
		return
	end

	local skilldata = g_shareData.skillRepository[self.ReadySkillId]
	if self:canMove() == 0 and self:getTarget() ~= nil  then
		if self:canCast(self.ReadySkillId)  == 0 then
		
		else
			if skilldata ~= nil and skilldata.n32SkillType == 0 and self:getTarget() ~= nil and self:getTarget():getType() ~= "transform" then
				local dis = self:getDistance(self:getTarget())
				if dis > skilldata.n32Range then
					self:setActionState( self:getMSpeed(), ActionState.move)
				end
			else
				self:setActionState( self:getMSpeed(), ActionState.move)
			end
		end
	end
	if skilldata ~= nil and skilldata.n32SkillType ~= 0 and self.spell.skilldata.id == self.ReadySkillId then
			self.ReadySkillId = self:getCommonSkill() 
	end
end
--设置人物状态
function Ientity:setState(state)
	self.state = state
end

function Ientity:canMove()
	if self:isAffectState(AffectState.NoMove) == true then
		return ErrorCode.EC_Spell_Controled
	end
	--[[
	if self:getTarget() and  Map:get(self:getTarget().pos.x, self:getTarget().pos.z) > 0 then
		if Map.IS_NEIGHBOUR_GRID(self.pos, self:getTarget().pos) then
			return 1001
		end
	end
	--]]
	if self.curActionState == ActionState.chargeing then
		return ErrorCode.EC_Spell_ForceMoving 
	end
	if self.spell.status == SpellStatus.ChannelCast and  self.spell.skilldata.n32NeedCasting == 2 then
		return ErrorCode.EC_Spell_SkillIsRunning 
	end
	if self.spell.status == SpellStatus.Cast and self.spell.skilldata.n32NeedCasting == 0 then return ErrorCode.EC_Spell_SkillIsRunning end
	return 0
end

function Ientity:canCast(id)
	if self.spell:isSpellRunning() == true then return ErrorCode.EC_Spell_SkillIsRunning end
	local skilldata = g_shareData.skillRepository[id]
	if skilldata == nil then return -1 end
	if self.cooldown:getCdTime(skilldata.id) > 0 then 
		return ErrorCode.EC_Spell_SkillIsInCd
	end

	--技能目标类型为敌方
	if skilldata.n32SkillTargetType == 3 then
		if self:getTarget() == nil or  self:getTarget():getType() == "transform" or self:isKind(self:getTarget()) == true or self:getTarget():getHp() <= 0 then
			return ErrorCode.EC_Spell_NoTarget
		end
	--目标类型为地点或者方向
	elseif skilldata.n32SkillTargetType == 4 or skilldata.n32SkillTargetType == 5 then
		if self:getTarget() == nil then
			return ErrorCode.EC_Spell_NoTarget
		end
	end
	
	if skilldata.n32Range ~= 0 then
		local dis = self:getDistance(self:getTarget())
		if dis > skilldata.n32Range then
			return ErrorCode.EC_Spell_TargetOutDistance
		end
	end
	--不是普攻
	if skilldata.n32SkillType ~= 0  then 
		if self:isAffectState(AffectState.NoSpell) then
			return ErrorCode.EC_Spell_Controled
		end
		
		if skilldata.n32SkillTargetType ~= 6 and skilldata.n32SkillTargetType ~= 0 then
			if self:getTarget() ~= nil and self:getTarget():getType() == "IBuilding" then
				return ErrorCode.EC_Spell_NoBuilding	
			end
		end
	end
	
	if self:getTarget() ~= nil and self:getTarget():getType() ~= "transform" and self:getTarget():isAffectState(AffectState.Invincible) then
		return ErrorCode.EC_Spell_Controled
	end
	if self:getHp() <= 0 then return ErrorCode.EC_Dead end
--	if skilldata.n32MpCost > self:getMp() then return ErrorCode.EC_Spell_MpLow end --蓝量不够
	if self.spell:canCost(skilldata) == false then return ErrorCode.EC_Spell_MpLow end 	
	return 0
end


--是否能选中技能
function Ientity:canSetCastSkill(id)
        local skilldata = g_shareData.skillRepository[id]
	--cd状态
	if self.cooldown:getCdTime(skilldata.id) > 0 then 
		return ErrorCode.EC_Spell_SkillIsInCd
	end
	--技能正在释放状态
	if self.spell:isSpellRunning() and self.spell.skillId == skilldata.id then
           return ErrorCode.EC_Spell_SkillIsRunning
        end
	--[[技能目标类型为敌方
	if skilldata.n32SkillTargetType == 3 then
	--目标类型为地点
	elseif skilldata.n32SkillTargetType == 4 or skilldata.n32SkillTargetType == 5 then
		if self:getTarget() == nil then
			return ErrorCode.EC_Spell_NoTarget
		end
	end]]--
	--蓝量不够 
	if skilldata.n32MpCost > self:getMp() then return ErrorCode.EC_Spell_MpLow end --蓝量不够
	return 0
end
function Ientity:setCastSkillId(id)
	print('set cast skill id = ', id)
	local skilldata = g_shareData.skillRepository[id]
	if not skilldata then
		syslog.warning( 'setCastSkillId failed ' .. id )
		return 1
	end
	if skilldata.bActive == false then	
		--测试使用
		self.ReadySkillId = 0
		self.spell:onStudyPasstiveSkill(skilldata)
		return 0
	end
	if self.ReadySkillId == id then
		--技能取消
		self.ReadySkillId = 0
		print("cancel skill id ")
		return 0
	end
	local errorcode = self:canSetCastSkill(id) 
	if errorcode ~= 0 then return errorcode end
	self.ReadySkillId = id
	--[[
	if   then
		--可以立即释放
		if self.spell:canBreak(ActionState.move) == false then
			print("can not break")	
		else
			if self.spell:isSpellRunning() == true then	
				self.spell:breakSpell()
			end
			self:castSkill()
			self.ReadySkillId = 0	
		end
	else
		--技能不是立即释放的
		return -1
	end]]
	return 0
end
function Ientity:castSkill()
	self.CastSkillId = self.ReadySkillId
	local id = self.CastSkillId
	local skilldata = g_shareData.skillRepository[id]
	local modoldata = self.modelDat 
	if skilldata == nil then
		return 
	end
	assert( modoldata)
	local errorcode = self:canCast(id) 
	if errorcode ~= 0 then return errorcode end
	local skillTimes = {}
	local action = ""
	if skilldata.n32ActionType == 1 then
		if (self.attackNum % 2)  == 0 then
			action = "attack01"
		else
			action = "attack02"
		end
	else
		action = skilldata.szAction
	end
	skillTimes[1] 	= modoldata["n32" .. action  .. "Time1"] or 0  
	skillTimes[2] 	= modoldata["n32" .. action .. "Time2"] or  0 
	skillTimes[3]   = modoldata["n32" .. action  .. "Time3"] or  0
	skillTimes["trigger"] = modoldata["n32".. action .. "TriTime"] or 0
	if skilldata.n32SkillType == 0 then --攻击动作
		local Aspeed = self:getASpeed()*1000 or 0
		local allTime = skillTimes[1] + skillTimes[2] + skillTimes[3]
		local pc =  Aspeed / allTime
		for i=1,3,1 do
			skillTimes[i] = math.floor(skillTimes[i] * pc)
		end
		skillTimes["trigger"] = math.floor(( skillTimes["trigger"] or 0)  * pc)
	end
	local tmpSpell = self.spell
	tmpSpell:init(skilldata,skillTimes)
	self:setActionState(0, ActionState.spell)
	tmpSpell:Cast(id,target,pos)
	return 0
end

function Ientity:addSkillAffect(tb)
	table.insert(self.AffectList,{effectId = tb.effectId , AffectType = tb.AffectType ,AffectValue = tb.AffectValue ,AffectTime = tb.AffectTime} )
end
return Ientity
