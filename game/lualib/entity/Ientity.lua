local skynet = require "skynet"
local vector3 = require "vector3"
local spell =  require "skill.spell"
local cooldown = require "skill.cooldown"
local AffectTable = require "skill.Affects.AffectTable"
local Map = require "map.Map"
local transfrom = require "entity.transfrom"
--local EntityManager = require "entity.EntityManager"
local coroutine = require "skynet.coroutine"
local syslog = require "syslog"

local Ientity = class("Ientity" , transfrom)

local HP_MP_RECOVER_TIMELINE = 1000
local UI_Stats_Show = {
	Strength = true,
	Minjie = true,
	Zhili = true,
	HpMax = true,
	MpMax = true,
	Attack = true,
	Defence = true,
	ASpeed = true,
}

local function register_stats(t, name)
	t['s_mid_'..name] = 0
	t['addMid' .. name] = function(self, v)
		self['s_mid_'..name] = self['s_mid_'..name] + v
	end
	t['getMid'..name] = function(self)
		return t['s_mid_'..name]
	end
	t['s_'..name] = 0
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
	self.bornPos =  vector3.create()
	
	self.camp = CampType.BAD  
	self.moveSpeed = 0
	self.curActionState = 0
	self.pathMove = nil
	self.pathNodeIndex = -1
	self.useAStar = false
	--event stamp handle about
	self.serverEventStamps = {}		--server event stamp
	self.newClientReq = {}		
	self.coroutine_pool = {}
	self.coroutine_response = {}
	--skynet about

	--att data
	self.attDat = nil
	self.modelDat = nil
	register_class_var(self, 'ShapeSize', 1)
	
	--技能相关----
	self.spell = spell.new(self)		 --技能
	self.affectTable = AffectTable.new(self) --效果表
	self.skillTable = {}	--可以释放的技能表
	self.CastSkillId = 0 	--正在释放技能的id
	self.ReadySkillId = 0	--准备释放技能的iastSkillId
	self.affectState = 0
	self.triggerCast = true	 --是否触发技能
	self.targetPos = nil
	--stats about
	register_stats(self, 'Strength')
	register_stats(self, 'StrengthPc')
	register_stats(self, 'Minjie')
	register_stats(self, 'MinjiePc')
	register_stats(self, 'Zhili')
	register_stats(self, 'ZhiliPc')
	register_stats(self, 'Hp')
	register_stats(self, 'HpMax')
	register_stats(self, 'HpMaxPc')
	register_stats(self, 'Mp')
	register_stats(self, 'MpMax')
	register_stats(self, 'MpMaxPc')
	register_stats(self, 'Attack')
	register_stats(self, 'AttackPc')
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
	register_stats(self, 'BaojiTimes')
	register_stats(self, 'Hit')
	register_stats(self, 'Miss')
	self.lastHp = 0

	self.recvTime = 0
	--cooldown
	self.cooldown = cooldown.new(self)
	self.maskHpMpChange = 0		--mask the reason why hp&mp changed 
	self.HpMpChange = false 	--just for merging the resp of hp&mp
	self.StatsChange = false	--just for merging the resp of stats
end

function Ientity:getType()
	return "Ientity"
end

function Ientity:isKind(entity,_atk)
	if entity == nil then return true end
	if entity.camp == nil then return true end
	_atk = _atk or false
	if _atk == false then
		if entity:getType() == "IBuilding" then
			return true
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
	self:advanceEventStamp(EventStampType.Move)
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
end

function Ientity:clearPath()
	self.pathNodeIndex = -1
	self.useAStar = false
	self.pathMove = nil
end

function Ientity:pathFind(dx, dz)
	self.pathMove = Map:find(self.pos.x, self.pos.z, dx, dz)
	self.pathNodeIndex = 3
	self.useAStar = #self.pathMove > self.pathNodeIndex
	print(self.pathMove)
	return self.useAStar
end

function Ientity:setTarget(target)
	if not target then self:setTargetVar( nil ) return end
	if target == self:getTarget() then 
		return 
	end	
	if self:isDead() then return end
	self:setTargetVar( target )
	if self.spell:isSpellRunning() == true and self.spell:canBreak(ActionState.move) == false then	
			return 
	else		
		if self.spell:isSpellRunning() == true then
			self.spell:breakSpell()
		end
		self.userAStar = false
		self.triggerCast = true
		if target:getType() == "transform" then 
			if self.ReadySkillId == 0 then
				self.triggerCast = false
			end
		else
			if self.ReadySkillId ~= 0 and self.triggerCast == true then	
				local err = self:canCast(self.ReadySkillId)
				if err == 0 then
					return
				end
			end
		end

		if self:canMove() == 0 then
			if self.ReadySkillId ~= 0 and self:canCast(self.ReadySkillId) == 0 then
				
			else
				self:setActionState( self:getMSpeed() / GAMEPLAY_PERCENT, ActionState.move)
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
	local pos = vector3.create(target.x,0,target.z)
	self:setTarget(transfrom.new(pos,nil))
end

function Ientity:update(dt)
	self.spell:update(dt)
	self.cooldown:update(dt)
	self.affectTable:update(dt)
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

	if self.curActionState == ActionState.move then
		if not self:getTarget() then 
			self:stand()
		else
			if self:canMove() == 0 then
				self:onMove(dt)
			else
				self:clearTarget(1)
				self:stand()
			end
		end
	elseif self.curActionState == ActionState.stand then
		--站立状态
	elseif self.curActionState >= ActionState.forcemove then
		--强制移动
		self:onForceMove(dt)		
	end
	--技能相关
	if self.ReadySkillId ~= 0  and self.triggerCast == true then	
		local err = self:canCast(self.ReadySkillId)
		if err == 0 then
			self:castSkill(self.ReadySkillId)
		end
	end

end


--注意：修改entity位置，一律用此函数
function Ientity:setPos(x, y, z, r)
	--print('set pos = ',x, y, z)
	Map:add(self.pos.x, self.pos.z, -1, r)
	Map:add(x, z, 1, r)
	self.pos:set(x, y, z)
end

local mv_dst = vector3.create()
local mv_slep_dir = vector3.create()
local legal_pos = false
--进入移动状态
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
				repeat
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

				until angle > 150
				
				if not nearBy and not doNotUseAstar then
					print('use a star to find a path')
					nearBy = self:pathFind(self:getTarget().pos.x, self:getTarget().pos.z)
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
--强制移动（魅惑 嘲讽 冲锋等）
function Ientity:onForceMove(dt)
	dt = dt / 1000
	local fSpeed = self.moveSpeed
	local mv_dst = vector3.create()
	if Map.IS_SAME_GRID(self.pos,self.targetPos.pos) then
		self:stand()
	end
	self.dir:set(self.targetPos.pos.x, 0, self.targetPos.pos.z)
	self.dir:sub(self.pos)
	self.dir:normalize()
	mv_dst:set(self.dir.x, self.dir.y, self.dir.z)
	mv_dst:mul_num(fSpeed * dt)
	mv_dst:add(self.pos)
	self:setPos(mv_dst.x, 0, mv_dst.z)

	local len  = vector3.len(self.pos,self.targetPos.pos)
	if len >= 0.001 then 
		self:advanceEventStamp(EventStampType.Move)
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
	self:setActionState(0, ActionState.die)
	for k, v in pairs(g_entityManager.entityList) do
		if v:getTarget() == self then
			v:setTarget(nil)
		end
		if v.entityType == EntityType.monster then
			v.hateList:removeHate( self )
		end
	end
	self.affectTable:clear() --清除所有的buff
end

function Ientity:onRaise()
	self:addHp(self:getHpMax(), HpMpMask.RaiseHp)
	self:addMp(self:getMpMax(), HpMpMask.RaiseMp)
	--学习被动技能
	for _k,_v in pairs(self.skillTable) do
		local id = _k + _v - 1
		local skilldata = g_shareData.skillRepository[id]	
		if skilldata ~= nil and skilldata.bActive == false then
			self.spell:onStudyPasstiveSkill(skilldata)	
		end
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
	if self.affectState == AffectState.NoDead then
		if self:getHp() <= 0 then
			self:setHp(1)
		end
	end
	if self.lastHp ~= self:getHp() then	
		self.maskHpMpChange = self.maskHpMpChange | mask
		--self.HpMpChange = true
		self:advanceEventStamp(EventStampType.Hp_Mp)
	end
	if self:getHp() <= 0 then
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
 		self:addHp(math.floor(self:getRecvHp() * cnt / GAMEPLAY_PERCENT), HpMpMask.TimeLineHp)
 		self:addMp(math.floor(self:getRecvMp() * cnt / GAMEPLAY_PERCENT), HpMpMask.TimeLineMp)
 	end
end

---------------------------------------stats about---------------------------------
function Ientity:dumpStats()
	print('Strength = '..self:getStrength())
	print('Minjie = '..self:getMinjie())
	print('Zhili = '..self:getZhili())
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
	print('Mid Minjie = '..self:getMidMinjie ())
	print('Mid MinjiePc = '..self:getMidMinjiePc ())
	print('Mid Zhili = '..self:getMidZhili ())
	print('Mid ZhiliPc = '..self:getMidZhiliPc ())
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
		+ self.attDat.n32Strength/GAMEPLAY_PERCENT * self:getLevel()) 
		* (1.0 + self:getMidStrengthPc()/GAMEPLAY_PERCENT)) 
		+ self:getMidStrength())
	)
end

function Ientity:calcMinjie()
	self:setMinjie(math.floor(
		math.floor((self.attDat.n32Minjie 
		+ self.attDat.n32LMinjie/GAMEPLAY_PERCENT * self:getLevel()) 
		* (1.0 + self:getMidMinjiePc()/GAMEPLAY_PERCENT)) 
		+ self:getMidMinjie())
	)
end

function Ientity:calcZhili()
	self:setZhili(math.floor(
		math.floor((self.attDat.n32Zhili 
		+ self.attDat.n32LZhili/GAMEPLAY_PERCENT * self:getLevel()) 
		* (1.0 + self:getMidZhiliPc()/GAMEPLAY_PERCENT)) 
		+ self:getMidZhili())
	)
end

function Ientity:calcHpMax()
	self:setHpMax(math.floor(
		self.attDat.n32Hp * (1.0 + self:getMidHpMaxPc()/GAMEPLAY_PERCENT)) 
		+ self:getMidHpMax() 
		+ math.floor(self.attDat.n32LStrength/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[1].n32Hp)
		+ math.floor(self.attDat.n32LMinjie/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[2].n32Hp)
		+ math.floor(self.attDat.n32LZhili/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[3].n32Hp)
	)
end

function Ientity:calcMpMax()
	self:setMpMax(math.floor(
		self.attDat.n32Mp * (1.0 + self:getMidMpMaxPc()/GAMEPLAY_PERCENT)) 
		+ self:getMidMpMax() 
		+ math.floor(self.attDat.n32LStrength/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[1].n32Mp)
		+ math.floor(self.attDat.n32LMinjie/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[2].n32Mp)
		+ math.floor(self.attDat.n32LZhili/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[3].n32Mp)
	)
end

function Ientity:calcAttack()
	local addVal = 0
	if self.attDat.n32MainAtt==1 then
		addVal = math.floor(self.attDat.n32LStrength/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[1].n32Attack)
	elseif self.attDat.n32MainAtt==2 then
		addVal =  math.floor(self.attDat.n32LMinjie/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[2].n32Attack)
	elseif self.attDat.n32MainAtt==3 then
		addVal =  math.floor(self.attDat.n32LZhili/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[3].n32Attack)
	end
	self:setAttack(math.floor(
		self.attDat.n32Attack * (1.0 + self:getMidAttackPc()/GAMEPLAY_PERCENT)) 
		+ self:getMidAttack() /GAMEPLAY_PERCENT 
		+ addVal
	)
end

function Ientity:calcDefence()
	self:setDefence(math.floor((
		math.floor(self.attDat.n32Defence * (1.0 + self:getMidDefencePc()/GAMEPLAY_PERCENT)) 
		+ self:getMidDefence() 
		+ math.floor(self.attDat.n32LStrength/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[1].n32Defence)
		+ math.floor(self.attDat.n32LMinjie/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[2].n32Defence)
		+ math.floor(self.attDat.n32LZhili/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[3].n32Defence)
		)/GAMEPLAY_PERCENT)
	)
end

function Ientity:calcASpeed()
	self:setASpeed(
		math.floor(self.attDat.n32ASpeed / ( 
			1 + self:getMidASpeed() / GAMEPLAY_PERCENT 
			+ self.attDat.n32LStrength/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[1].n32ASpeed /GAMEPLAY_PERCENT
			+ self.attDat.n32LMinjie/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[2].n32ASpeed /GAMEPLAY_PERCENT
			+ self.attDat.n32LZhili/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[3].n32ASpeed /GAMEPLAY_PERCENT
		)
		)
	)
end

function Ientity:calcMSpeed()
	self:setMSpeed(math.floor(
		self.attDat.n32MSpeed * (1.0 + self:getMidMSpeedPc()/GAMEPLAY_PERCENT))
		+ self:getMidMSpeed() 
	)
	self.moveSpeed = self:getMSpeed() / GAMEPLAY_PERCENT
end

function Ientity:calcRecvHp()
	self:setRecvHp(math.floor(
		self.attDat.n32RecvHp * (1.0 + self:getMidRecvHpPc()/GAMEPLAY_PERCENT))
		+ self:getMidRecvHp()
		+ math.floor(self.attDat.n32LStrength/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[1].n32RecvHp)
		+ math.floor(self.attDat.n32LMinjie/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[2].n32RecvHp)
		+ math.floor(self.attDat.n32LZhili/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[3].n32RecvHp)
	)
end

function Ientity:calcRecvMp()
	self:setRecvMp(math.floor(
		self.attDat.n32RecvMp * (1.0 + self:getMidRecvMpPc()/GAMEPLAY_PERCENT))
		+ self:getMidRecvMp()
		+ math.floor(self.attDat.n32LStrength/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[1].n32RecvMp)
		+ math.floor(self.attDat.n32LMinjie/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[2].n32RecvMp)
		+ math.floor(self.attDat.n32LZhili/GAMEPLAY_PERCENT * self:getLevel() * g_shareData.lzmRepository[3].n32RecvMp)
	)
end

function Ientity:calcAttackRange()
	self:setAttackRange(math.floor(
		self.attDat.n32AttackRange * (1.0 +self:getMidAttackRangePc()/GAMEPLAY_PERCENT))
		+ self:getMidAttackRange()
	)
end

function Ientity:calcBaoji()
	self:setBaojiRate(self:getMidBaojiRate())
	self:setBaojiTimes(self:getMidBaojiTimes())
end

function Ientity:calcHit()
	self:setHit(self:getMidHit())
end

function Ientity:calcMiss()
	self:setMiss(self:getMidMiss() / GAMEPLAY_PERCENT)
end


---------------------------------------------------------------------------------技能相关------------------------------------------------------------------------------------------------------------------

function Ientity:callBackSpellBegin()

end

function Ientity:callBackSpellEnd()
	if self.entityType ~= EntityType.player	then
		self.ReadySkillId = 0
		return
	end

	if self:canMove() == 0 and self:getTarget() ~= nil  then
		if self:canCast(self.ReadySkillId)  == 0 then
		else
			self:setActionState( self:getMSpeed() / GAMEPLAY_PERCENT, ActionState.move)
		end
	end
	local data = g_shareData.skillRepository[self.ReadySkillId]
	if data ~= nil and data.bCommonSkill == false and self.spell.skilldata.id == self.ReadySkillId then
			self.ReadySkillId = 0
	end
end
--设置人物状态
function Ientity:setState(state)
	self.state = state
end

function Ientity:canMove()
	if bit_and(self.affectState,AffectState.NoMove) ~= 0 then
		return ErrorCode.EC_Spell_Controled
	end
	if self:getTarget() and  Map:get(self:getTarget().pos.x, self:getTarget().pos.z) > 0 then
		if Map.IS_NEIGHBOUR_GRID(self.pos, self:getTarget().pos) then
			return 1001
		end
	end

	if self.spell.status == SpellStatus.Cast then return ErrorCode.EC_Spell_SkillIsRunning end
	return 0
end

function Ientity:canCast(id)
	if self.spell:isSpellRunning() == true then return ErrorCode.EC_Spell_SkillIsRunning end
	local skilldata = g_shareData.skillRepository[id]
	--如果是有目标类型(4 针对自身立即释放)
	local tgtType = GET_SkillTgtType(skilldata)
	local tgtRange = GET_SkillTgtRange(skilldata)
	if tgtType ~= 4 and tgtRange ~= 2 and  tgtRange ~= 7 then
		if self:getTarget() == nil then return ErrorCode.EC_Spell_NoTarget end
		if skilldata.bNeedTarget == true then
			if self:getTarget():getType() == "transform" then return ErrorCode.EC_Spell_NoTarget end--目标不存在
			if tgtType == 3	and self:getTarget():isKind(self) == true then return ErrorCode.EC_Spell_Camp_Friend end --不能对友方施法该技能
			if tgtType == 2 and self:getTarget():isKind(self) == false then return ErrorCode.EC_Spell_Camp_Enemy end --不能对敌方施法该技能
		end
		local dis = self:getDistance(self:getTarget())
		local dataDis = skilldata.n32Range / 10000
		if dis > dataDis  then 
			return ErrorCode.EC_Spell_TargetOutDistance 
		end
	end
	if skilldata.bCommonSkill == false  then 
		if bit_and(self.affectState,AffectState.NoSpell) ~= 0 then
			return ErrorCode.EC_Spell_Controled
		end
		if self:getTarget() ~= nil and self:getTarget():getType() == "IBuilding" then
			return ErrorCode.EC_Spell_NoBuilding	
		end
	end

	if bit_and(self.affectState,AffectState.NoAttack) ~= 0 then 
		return ErrorCode.EC_Spell_Controled
	end
	if self:getHp() <= 0 then return ErrorCode.EC_Dead end
	--if skilldata.n32MpCost > self.getMp() then return ErrorCode.EC_Spell_MpLow	end --蓝量不够
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
	local tgtType = GET_SkillTgtType(skilldata)
	if self:getTarget() ~= nil and self:getTarget():getType() ~= "transform" then
		if skilldata.bNeedTarget == true then
			--单体目标施法技能
			if tgtType == 3 and self:getTarget():isKind(self) == true then return ErrorCode.EC_Spell.EC_Spell_Camp_Friend end
			if tgtType == 2 and self:getTarget():isKind(self) == false then return ErrorCode.EC_Spell.EC_Spell_Camp_Enemy end
		end
	end
	--被控制状态 
	return 0
end
function Ientity:setCastSkillId(id)
	--print('set cast skill id = ', id)
	local skilldata = g_shareData.skillRepository[id]
	if not skilldata then
		syslog.warning( 'setCastSkillId failed ' .. id )
		return
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
	local type_range = GET_SkillTgtRange(skilldata)
	local type_target = GET_SkillTgtType(skilldata)
	
	self.ReadySkillId = id
	if type_target == 4 or type_range == 2 or type_range == 7  then
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
	end
	return 0
end
function Ientity:castSkill()
	self.CastSkillId = self.ReadySkillId
	local id = self.CastSkillId
	local skilldata = g_shareData.skillRepository[id]
	local modoldata = self.modelDat 
	assert(skilldata and modoldata)
	local errorcode = self:canCast(id) 
	if errorcode ~= 0 then return errorcode end
	local skillTimes = {}
	local action = ""
	if skilldata.n32ActionType == 1 then
		action = "Attack"
	elseif skilldata.n32ActionType == 2 then
		action = "Skill1"
	elseif skilldata.n32ActionType == 3 then
		action = "Skill2"
	elseif skilldata.n32ActionType == 4 then
		action = "Skill3"
	end
	skillTimes[1] 	= modoldata["n32" .. action  .. "Time1"] or 0  
	skillTimes[2] 	= modoldata["n32" .. action .. "Time2"] or  0 
	skillTimes[3]   = modoldata["n32" .. action  .. "Time3"] or  0
	skillTimes["trigger"] = modoldata["n32".. action .. "TriTime"] or 0
	if skilldata.bCommonSkill == true then --攻击动作
		local Aspeed = self:getASpeed() or 0
		local allTime = skillTimes[1] + skillTimes[2] + skillTimes[3]
		local pc =  1 --Aspeed / allTime
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
