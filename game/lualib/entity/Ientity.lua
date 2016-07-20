local vector3 = require "vector3"
local spell =  require "entity.spell"
local cooldown = require "entity.cooldown"
local BuffTable = require "skill.BuffTable"
local AffectTable = require "skill.Affects.AffectTable"

local Ientity = class("Ientity")

require "globalDefine"

function Ientity:ctor()
	
	self.serverId = 0		--it is socket fd

	--entity world data about
	self.entityType = 0
	self.serverId = 0

	self.pos = vector3.create()
	self.dir = vector3.create()
	self.targetPos = vector3.create()
	self.moveSpeed = 0
	self.curActionState = 0 
		
	--event stamp handle about
	self.serverEventStamps = {}		--server event stamp
	self.newClientReq = {}		
	self.coroutine_pool = {}
	self.coroutine_response = {}
	--skynet about

	self.modolId = 8888	--模型id	
	--技能相关----
	self.spell = spell.new(self)
	self.affectTable = AffectTable.new(self) --效果表
	--buff about
	self.buffTable = BuffTable.new(self)
	self.Stats = self.buffTable.Stats
	--cooldown
	self.cooldown = cooldown.new(self)
	self.maskHpMpChange = 0		--mask the reason why hp&mp changed 
	self.HpMpChange = false 	--just for merging the resp of hp&mp
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
end

function Ientity:setTargetPos(target)
	if self.spell:canBreak(ActionState.move) == false then return end
	
	self.targetPos:set(target.x/GAMEPLAY_PERCENT, target.y/GAMEPLAY_PERCENT, target.z/GAMEPLAY_PERCENT)
	self.moveSpeed = self.Stats.n32MoveSpeed
	self.curActionState = ActionState.move
end

function Ientity:update(dt)
	self.spell:update(dt)
	self.buffTable:update(dt)
	self.cooldown:update(dt)
	self.affectTable:update(dt)

	--add code before this
	if self.HpMpChange then
		self:advanceEventStamp(EventStampType.HP_Mp)
		self.HpMpChange = false
	end
end


function Ientity:addHp(_hp, mask)
	if _hp == 0 then return  end
	if not mask then
		mask = HpMpMask.SkillHp
	end
	self.lastHp = self.Stats.n32Hp
	self.Stats.n32Hp = mClamp(self.Stats.n32Hp + _hp, 0, self.Stats.n32MaxHp)
	if self.lastHp ~= self.Stats.n32Hp then	
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
	self.Stats.n32Mp = mClamp(self.Stats.n32Mp + _mp, 0, self.Stats.n32MaxMp)
	if self.lastMp ~= self.Stats.n32Mp then	
		self.maskHpMpChange = self.maskHpMpChange | mask
		self.HpMpChange = true
	end
end
---------------------------------------------------技能相关-------------------------------------
function Ientity:addBuff(_id, cnt, src, origin)
	self.buffTable:addBuffById(_id, cnt, src, origin)
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
	if skilldata.n32MpCost > self.Stats.n32Mp then return ErrorCode.EC_Spell_MpLow	end --蓝量不够
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
	self:advanceEventStamp(EventStampType.CastSkill)
	return 0
end

function Ientity:addSkillAffect(tb)
	table.insert(self.AffectList,{effectId = tb.effectId , AffectType = tb.AffectType ,AffectValue = tb.AffectValue ,AffectTime = tb.AffectTime} )
end
return Ientity










































