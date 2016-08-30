local skynet = require "skynet"
local vector3 = require "vector3"
local spell =  require "skill.spell"
local AttackSpell = require "skill.AttackSpell"
local cooldown = require "skill.cooldown"
local AffectTable = require "skill.Affects.AffectTable"
local Map = require "map.Map"
local transfrom = require "entity.transfrom"

local coroutine = require "skynet.coroutine"

local Ientity = class("Ientity" , transfrom)

local StrengthEffect = { 50,0,2,0,0,0,1,0, }
local MinjieEffect = { 0,0,2,0.5,0.05,1.2,0,0,}
local ZhiliEffect = { 0,30,2,0,0,0,0,1, }
local HP_MP_RECOVER_TIMELINE = 1000

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
		--self.StatsChange = true
	end
	t['get' .. name] = function(self)
		return self['s_'..name] 
	end
end


function Ientity:ctor(pos,dir)
	--print("Ientity:ctor")
	print("Ientity:ctor")
	Ientity.super.ctor(self,pos,dir)
	--entity world data about
	self.entityType = 0
	self.serverId = 0
	register_class_var(self, 'Level', 1)
	self.modolId = 8888	--模型id	
	
	self.target =  nil --选中目标实体
	self.moveSpeed = 0
	self.curActionState = 0 
	--event stamp handle about
	self.serverEventStamps = {}		--server event stamp
	self.newClientReq = {}		
	self.coroutine_pool = {}
	self.coroutine_response = {}
	--skynet about

	--att data
	self.attDat = nil
	
	--技能相关----
	self.spell = spell.new(self)		 --技能
	self.attackSpell = AttackSpell.new(self) --普攻技能
	self.affectTable = AffectTable.new(self) --效果表

	self.CastSkillId = 0 	--正在释放技能的id
	self.ReadySkillId = 0	--准备释放技能的iastSkillId
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
	if event == EventStampType.HP_Mp then
		self.maskHpMpChange = 0
	end
end


function Ientity:stand()
	self.moveSpeed  = 0
	self.curActionState = ActionState.stand
	self.state = "idle" --idle walk spell
end

function Ientity:setTarget(target)
	if self.affectTable:canControl() == false then return end		--不受控制状态
	if self.spell:canBreak(ActionState.move) == false then return end	--技能释放状态=
	if self.attackSpell:canBreak(ActionState.move) == false then return end	
	--if Map:get(target.pos.x, target.pos.z) == false then return end	
	self.target = target
	self.moveSpeed = self:getMSpeed() / GAMEPLAY_PERCENT

	self.curActionState = ActionState.move
end

function Ientity:getTarget()
	return self.target
end

function Ientity:setTargetPos(target)
	target.x = target.x/GAMEPLAY_PERCENT
	target.z = target.z/GAMEPLAY_PERCENT
	--self.target:set(target.x, 0, target.z)
	local pos = vector3.create(target.x,0,target.z)
	self:setTarget(transfrom.new(pos,nil))
end

function Ientity:update(dt)
	self.spell:update(dt)
	self.attackSpell:update(dt)
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
		self:move(dt)
	elseif self.curActionState == ActionState.stand then
		--站立状态
		
	end
	--技能相关
	if self.ReadySkillId ~= 0 then	
		if self:canCast(self.ReadySkillId) == 0 then
			self:castSkill(self.ReadySkillId)
		end
	end
end

function Ientity:move(dt)
	dt = dt / 1000		--second
	if self.moveSpeed <= 0 then return end
	self.dir:set(self.target.pos.x, self.target.pos.y, self.target.pos.z)
	self.dir:sub(self.pos)
	self.dir:normalize(self.moveSpeed * dt)
	local dst = self.pos:return_add(self.dir)
	repeat
		--check iegal
		if IS_SAME_GRID(self.pos, dst) == false then
			if Map:get(dst.x, dst.z) == false then
				--self:stand()
				--break
			end
			-- mark the map
			Map:set(self.pos.x, self.pos.z, true)
			Map:set(dst.x, dst.z, false)
		end	

		--move
		self.pos:set(dst.x, dst.y, dst.z)
		if IS_SAME_GRID(self.target.pos,  dst) then
			self:stand()
			break
		end
	until true

	--advance move event stamp
	self:advanceEventStamp(EventStampType.Move)
end

--强制设置位置（闪现,击飞,回城等）
function Ientity:forcePosition(des)
	--先判定des位置是否超过地图范围
	--self:stand()
	self.pos:set(des.x,des.y,des.z)
	self.curActionState = 8--ActionState.blink
	--强制更新位置	
	self:advanceEventStamp(EventStampType.Move)
end
--进入待机状态
function Ientity:enterIdle()
	self:stand()
	--self.curActionState =  ActionState.stand
	self:advanceEventStamp(EventStampType.Move)
end
function Ientity:onDead()
	print('Ientity:onDead')
end

function Ientity:addHp(_hp, mask, source)
	if _hp < 0 then _hp = -1 end
	if _hp == 0 then return end
	assert(_hp > 0 or source, "you must set the source")
	if not mask then
		mask = HpMpMask.SkillHp
	end
	self.lastHp = self:getHp()
	self:setHp(mClamp(self.lastHp+_hp, 0, self:getHpMax()))
	if self.lastHp ~= self:getHp() then	
		self.maskHpMpChange = self.maskHpMpChange | mask
		self.HpMpChange = true
	end
	if self:getHp() <= 0 then
		self:onDead()
	end
end


function Ientity:addMp(_mp, mask, source)
	if _mp == 0 then return  end
	if not mask then
		mask = HpMpMask.SkillMp
	end
	self.lastMp = self.Stats.n32Mp
	self:setMp(mClamp(self.lastMp+_mp, 0, self:getMpMax()))
	if self.lastMp ~= self:getMp() then	
		self.maskHpMpChange = self.maskHpMpChange | mask
		self.HpMpChange = true
	end
end

function Ientity:recvHpMp()
	if true then return end
	if self:getRecvHp() <= 0 and self:getRecvMp() <= 0 then return end
	local curTime = skynet.now()
	if self.recvTime == 0 then
		self.recvTime = curTime
	end    
	if (curTime - self.recvTime) * 100  > HP_MP_RECOVER_TIMELINE then
		local cnt = math.ceil((curTime - self.recvTime) * 100 / HP_MP_RECOVER_TIMELINE)
		self.recvTime = curTime
 		self:addHp(self:getRecvHp() * cnt, HpMpMask.TimeLine)
 		self:addMp(self:getRecvMp() * cnt, HpMpMask.TimeLine)
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
		+ self.attDat.n32LStrength/GAMEPLAY_PERCENT * self:getLevel()) 
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
		+ self:getStrength() * StrengthEffect[1]
		+ self:getZhili() * ZhiliEffect[1]
		+ self:getMinjie() * MinjieEffect[1]
	)
end

function Ientity:calcMpMax()
	self:setMpMax(math.floor(
		self.attDat.n32Mp * (1.0 + self:getMidMpMaxPc()/GAMEPLAY_PERCENT)) 
		+ self:getMidMpMax() 
		+ self:getStrength() * StrengthEffect[2]
		+ self:getZhili() * ZhiliEffect[2]
		+ self:getMinjie() * MinjieEffect[2]
	)
end

function Ientity:calcAttack()
	self:setAttack(math.floor(
		self.attDat.n32Attack * (1.0 + self:getMidAttackPc()/GAMEPLAY_PERCENT)) 
		+ self:getMidAttack() 
		+ self:getStrength() * StrengthEffect[3]
		+ self:getZhili() * ZhiliEffect[3]
		+ self:getMinjie() * MinjieEffect[3]
	)
end

function Ientity:calcDefence()
	self:setDefence(math.floor(
		self.attDat.n32Defence * (1.0 + self:getMidDefencePc()/GAMEPLAY_PERCENT)) 
		+ self:getMidDefence() 
		+ self:getStrength() * StrengthEffect[4]
		+ self:getZhili() * ZhiliEffect[4]
		+ self:getMinjie() * MinjieEffect[4]
	)
end

function Ientity:calcASpeed()
	self:setASpeed(
		self.attDat.n32ASpeed 
		+ self:getMidASpeed() 
		+ self:getStrength() * StrengthEffect[5]
		+ self:getZhili() * ZhiliEffect[5]
		+ self:getMinjie() * MinjieEffect[5]
	)
end

function Ientity:calcMSpeed()
	self:setMSpeed(math.floor(
		self.attDat.n32MSpeed * (1.0 + self:getMSpeedPc()/GAMEPLAY_PERCENT))
		+ self:getMidMSpeed() 
		+ self:getStrength() * StrengthEffect[6]
		+ self:getZhili() * ZhiliEffect[6]
		+ self:getMinjie() * MinjieEffect[6]
	)
end

function Ientity:calcRecvHp()
	self:setRecvHp(math.floor(
		self.attDat.n32RecvHp * (1.0 + self:getMidRecvHp()/GAMEPLAY_PERCENT))
		+ self:getMidRecvHp()
		+ self:getStrength() * StrengthEffect[7]
		+ self:getZhili() * ZhiliEffect[7]
		+ self:getMinjie() * MinjieEffect[7]
	)
end

function Ientity:calcRecvMp()
	self:setRecvMp(math.floor(
		self.attDat.n32RecvMp * (1.0 + self:getMidRecvMp()/GAMEPLAY_PERCENT))
		+ self:getMidRecvMp()
		+ self:getStrength() * StrengthEffect[8]
		+ self:getZhili() * ZhiliEffect[8]
		+ self:getMinjie() * MinjieEffect[8]
	)
end

function Ientity:calcAttackRange()
	self:setAttackRange(math.floor(
		self.attDat.n32AttackRange * (1.0 +self:getMidAttackRange()/GAMEPLAY_PERCENT))
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
	self:setMiss(self:getMidMiss())
end


---------------------------------------------------------------------------------技能相关------------------------------------------------------------------------------------------------------------------
--设置人物状态
function Ientity:setState(state)
	self.state = state
end


function Ientity:canCast(id)
	local skilldata = g_shareData.skillRepository[id]
	--如果是有目标类型
	if skilldata.bNeedTarget == true then
		if self.target == nil or self.target:getType() == "transform" then return ErrorCode.EC_Spell_NoTarget end					--目标不存在
		if self:getDistance(self.target) > skilldata.n32Range then return ErrorCode.EC_Spell_TargetOutDistance end	--目标距离过远
	end
	
	--if skilldata.n32MpCost > self.getMp() then return ErrorCode.EC_Spell_MpLow	end --蓝量不够
	return 0
end

function Ientity:getDistance(target)
	assert(target)
	local dis = vector3.len(self.pos, target.pos)
	return dis
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
	--被控制状态 
	return 0
end
function Ientity:setCastSkillId(id)
	self.ReadySkillId = id
	local skilldata = g_shareData.skillRepository[id]
	local errorcode = self:canSetCastSkill(id) 
        if errorcode ~= 0 then return errorcode end 
	local type_target = math.floor(skilldata.n32Type / 10)
	local type_range = math.floor(skilldata.n32Type % 10)
	if  type_range == 3 or type_range  == 4 then
		--立即释放
		errorcode = self.canCast(id)
		if errorcode ~= 0 then
			return errorcode
		end
		--self.castSkill()
	end
end
function Ientity:castSkill()
	self.CastSkillId = self.ReadySkillId
	self.ReadySkillId = 0
	local id = self.CastSkillId
	local skilldata = g_shareData.skillRepository[id]
	local modoldata = g_shareData.heroModolRepository[self.modolId]
	assert(skilldata and modoldata)
	local errorcode = self:canCast(id) 
	if errorcode ~= 0 then return errorcode end
	local skillTimes = {}	
	if skilldata.bCommonSkill == false then
		skillTimes[1] 	= modoldata["n32Skill1" .. "Time1"] or 0  
		skillTimes[2] 	= modoldata["n32Skill1" .. "Time2"] or  0 
		skillTimes[3] 	= modoldata["n32Skill1" .. "Time3"] or 0 
	else
		--普通攻击
		skillTimes[1] = modoldata["n32Attack" .. "Time1"] or 0
		skillTimes[2] = modoldata["n32Attack" .. "Time2"] or  0
		skillTimes[3] = modoldata["n32Attack" .. "Time3"] or 0
	end
	local tmpSpell = self.spell
	if skilldata.bCommonSkill == true then
		tmpSpell = self.attackSpell
	end
	tmpSpell:init(skilldata,skillTimes)
	self.cooldown:addItem(id) --加入cd
	tmpSpell:Cast(id,target,pos)
	self:stand()
	self:advanceEventStamp(EventStampType.CastSkill)
	return 0
end

function Ientity:addSkillAffect(tb)
	table.insert(self.AffectList,{effectId = tb.effectId , AffectType = tb.AffectType ,AffectValue = tb.AffectValue ,AffectTime = tb.AffectTime} )
end
return Ientity
