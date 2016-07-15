local vector3 = require "vector3"
local spell =  require "entity.spell"
local cooldown = require "entity.cooldown"
local BuffTable = require "skill.BuffTable"
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

	--buff about
	self.buffTable = BuffTable.new()
	self.Stats = self.buffTable.Stats

	--cooldown
	self.cooldown = cooldown.new(self)
end


function Ientity:advanceEventStamp(event)
	if not self.serverEventStamps[event] then
		self.serverEventStamps[event] = 0
	end

	self.serverEventStamps[event] = self.serverEventStamps[event] + 1

	if self.newClientReq[event] then 
		self.newClientReq[event] = false				
		respClientEventStamp(self.coroutine_pool[event], self.serverId, event)
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
	else
		self.newClientReq[event] = true				--mark need be resp
	end
end


function Ientity:stand()
	self.moveSpeed  = 0
	self.curActionState = ActionState.stand
end

function Ientity:setTargetPos(target)
--	if self.spell:Breaking(ActionState.move) == false then return end
	
	self.targetPos:set(target.x/GAMEPLAY_PERCENT, target.y/GAMEPLAY_PERCENT, target.z/GAMEPLAY_PERCENT)
	self.moveSpeed = self.Stats.n32MoveSpeed
	self.curActionState = ActionState.move
end

function Ientity:update(dt)
	self.spell:update(dt)
	self.buffTable:update(dt)
	self.cooldown:update(dt)
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
	return 0
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
return Ientity










































