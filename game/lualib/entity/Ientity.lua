local vector3 = require "vector3"
local spell =  require "skill.spell"
local cooldown = require "entity.cooldown"
local AffectTable = require "skill.Affects.AffectTable"
require "globalDefine"


local Ientity = class("Ientity")

local function register_stats(t, name)
	t['s_'..name] = 0
	t['add' .. name] = function(self, v)
		self['s_'..name] = self['s_'..name] + v
		self.StatsChange = true
	end
	t['set' .. name] = function (self, v)
		self['s_'..name] = v
		self.StatsChange = true
	end
	t['get' .. name] = function(self)
		return self['s_'..name] 
	end
end

function Ientity:ctor()
	
	self.serverId = 0		--it is socket fd

	--entity world data about
	self.entityType = 0
	self.serverId = 0

	self.pos = vector3.create()
	self.dir = vector3.create()
	self.targetPos = vector3.create()
	self.pos:set(0, 0, 0)
	self.dir:set(0, 0, 0)
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
	
	self.modolId = 8888	--模型id	
	--技能相关----
	self.spell = spell.new(self)
	self.affectTable = AffectTable.new(self) --效果表
	--stats about
	register_stats(self, 'Strength')
	register_stats(self, 'StrengthPc')
	register_stats(self, 'Minjie')
	register_stats(self, 'MinjiePc')
	register_stats(self, 'Zhili')
	register_stats(self, 'ZhiliPc')
	register_stats(self, 'HpMax')
	register_stats(self, 'HpMaxPc')
	register_stats(self, 'MpMax')
	register_stats(self, 'MpMaxPc')
	register_stats(self, 'Attack')
	register_stats(self, 'AttackPc')
	register_stats(self, 'Defence')
	register_stats(self, 'DefencePc')
	register_stats(self, 'ASpeed')
	register_stats(self, 'ASpeedPc') 
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
	register_stats(self, 'HitPc')
	register_stats(self, 'Miss')
	register_stats(self, 'MissPc')

        self.recvHp = 0
        self.recvMp = 0
        self.recvTime = 0	
	self.recvTime = 0
	--cooldown
	self.cooldown = cooldown.new(self)
	self.maskHpMpChange = 0		--mask the reason why hp&mp changed 
	self.HpMpChange = false 	--just for merging the resp of hp&mp
	self.StatsChange = true		--just for merging the resp of stats
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

function Ientity:setTargetPos(target)
	if self.spell:canBreak(ActionState.move) == false then return end
	
	self.targetPos:set(target.x/GAMEPLAY_PERCENT, target.y/GAMEPLAY_PERCENT, target.z/GAMEPLAY_PERCENT)
	self.moveSpeed = 1 --self.getMoveSpeed()
	self.curActionState = ActionState.move
end

function Ientity:update(dt)
	self.spell:update(dt)
	self.cooldown:update(dt)
	self.affectTable:update(dt)
	self:recvHpMp(dt)

	--add code before this
	if self.HpMpChange then
		self:advanceEventStamp(EventStampType.HP_Mp)
		self.HpMpChange = false
	end
	
	if self.curActionState == ActionState.move then
		self:move(dt)
	elseif self.curActionState == ActionState.stand then
		--站立状态
		
	end
end


function Ientity:move(dt)
	dt = dt / 1000		--second
	if self.moveSpeed <= 0 then return end

	self.dir:set(self.targetPos.x, self.targetPos.y, self.targetPos.z)
	self.dir:sub(self.pos)
	self.dir:normalize(self.moveSpeed * dt)
	

	local dst = self.pos:return_add(self.dir)
	--check iegal
	
	--move
	self.pos:set(dst.x, dst.y, dst.z)
	if IS_SAME_GRID(self.targetPos,  dst) then
		self:stand()
	end

	--advance move event stamp
	self:advanceEventStamp(EventStampType.Move)
	if self.StatsChange then
		self:advanceEventStamp(EventStampType.Stats)
		self.StatsChange = false
	end
end


function Ientity:addHp(_hp, mask)
	if _hp == 0 then return end
	if not mask then
		mask = HpMpMask.SkillHp
	end
	self.lastHp = self:getHp()
	self:setHp(mClamp(self.lastHp+_hp, 0, self.attDat.n32Hp * (1.0 + self:getHpMaxPc()/GAMEPLAY_PERCENT) + self:getHpMax()))
	if self.lastHp ~= self.getHp() then	
		self.maskHpMpChange = self.maskHpMpChange | mask
		self.HpMpChange = true
	end
end


function Ientity:addMp(_mp, mask)
	if _mp == 0 then return  end
	if not mask then
		mask = HpMpMask.SkillMp
	end
	self.lastMp = self.Stats.n32Mp
	self:setMp(mClamp(self.lastMp+_mp, 0, self.attDat.n32Mp * (1.0 + self:getMpMaxPc()/GAMEPLAY_PERCENT) + self:getMpMax()))
	if self.lastMp ~= self:getMp() then	
		self.maskHpMpChange = self.maskHpMpChange | mask
		self.HpMpChange = true
	end
end

function Ientity:recvHpMp()
	if self.recvHp <= 0 and self.recvMp <= 0 then return end
	local curTime = skynet.now()
	if self.recvTime == 0 then
		self.recvTime = curTime
	end    
	if (curTime - self.recvTime) * 100  > HP_MP_RECOVER_TIMELINE then
		local cnt = math.ceil((curTime - self.recvTime) * 100 / HP_MP_RECOVER_TIMELINE)
		self.recvTime = curTime
 		self:addHp((self:getBaseRecvHp() * (1.0 + self:getRecvHpPc() / GAMEPLAY_PERCENT) + self:getRecvHp()) * cnt, HpMpMask.TimeLine)
 		self:addMp((self:getBaseRecvMp() * (1.0 + self:getRecvMpPc() / GAMEPLAY_PERCENT) + self:getRecvMp()) * cnt, HpMpMask.TimeLine)
 	end
end


---------------------------------------------------------------------------------技能相关------------------------------------------------------------------------------------------------------------------
--设置人物状态
function Ientity:setState(state)
	self.state = state
end

function Ientity:canCast(skilldata,target,pos)
	--print(ErrorCode)
	if self.cooldown:getCdTime(skilldata.id) > 0 then 
		print("spell is cding",skilldata.id)
		return ErrorCode.EC_Spell_SkillIsInCd
	end
	if self.spell:isSpellRunning() and self.spell.skillId == skilldata.id then 
		print("spell is running",skilldata.id)
		return ErrorCode.EC_Spell_SkillIsRunning 
	end
	--如果是有目标类型
	if skilldata.bNeedTarget == true then
		if self.target == nil then return ErrorCode.EC_Spell_NoTarget end					--目标不存在
		if self.getDistance(target) > skilldata.n32range then return ErrorCode.EC_Spell_TargetOutDistance end	--目标距离过远
	end
	--if skilldata.n32MpCost > self.getMp() then return ErrorCode.EC_Spell_MpLow	end --蓝量不够
	return 0
end

function Ientity:getDistance(target)
	assert(target)
	local disVec = self.pos:sub(target.pos)
        local disLen = disVec:length()
	return disLen
end

function Ientity:castSkill(id)
        print("Ientity:castSkillId",id,EventStampType.CastSkill)
	local skilldata = g_shareData.skillRepository[id]
	local modoldata = g_shareData.heroModolRepository[self.modolId]
	assert(skilldata)
	assert(modoldata)
	local errorcode = self:canCast(skilldata,id) 
	print("castskill error",errorcode)
	if errorcode ~= 0 then return errorcode end
	
	self.spell:init(skilldata)
	if string.find(skilldata.szAction,"skill") then
		self.spell.readyTime 	= skilldata.n32ActionTime * (modoldata["n32Skill1" .. "Time1"] or 0 ) / 1000 
		self.spell.castTime 	= skilldata.n32ActionTime * (modoldata["n32Skill1" .. "Time2"] or  0 ) / 1000
		self.spell.endTime 	= skilldata.n32ActionTime * (modoldata["n32Skill1" .. "Time3"] or 0 ) / 1000
	else
		--普通攻击
		self.spell.readyTime =  modoldata["n32Attack" .. "Time1"] or 0
		self.spell.castTime = modoldata["n32Attack" .. "Time2"] or  0
		self.spell.endTime = modoldata["n32Attack" .. "Time3"] or 0
	end
	print("spellTime",self.spell.readyTime,self.spell.castTime,self.spell.endTime)
	self.castSkillId = id
	self.cooldown:addItem(id) --加入cd
	self.spell:Cast(id,target,pos)
	self:stand()
	self:advanceEventStamp(EventStampType.CastSkill)
	return 0
end

function Ientity:addSkillAffect(tb)
	table.insert(self.AffectList,{effectId = tb.effectId , AffectType = tb.AffectType ,AffectValue = tb.AffectValue ,AffectTime = tb.AffectTime} )
end
return Ientity










































