local vector3 = require "vector3"
local spell =  require "entity.spell"
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
	
	--技能相关----
	self.spell = spell.new()

	--buff about
	self.buffTable = BuffTable.new(self)
	self.Stats = self.buffTable.Stats
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
	print("checkeventStamp",event,self.serverEventStamps[event],stamp) 
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
	if event == tEventStampType.HP_Mp then
		self.maskHpMpChange = 0
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
	self.Stats.n32Mp = mClamp(self.Stats.n32Mp + _hp, 0, self.Stats.n32MaxMp)
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
	return true
end


function Ientity:setCastSkillId(id)
         print("Ientity:setCastSkillId",id,EventStampType.CastSkill)
        -- for _k,_v in pairs(g_shareData.skillRepository) do
	--	print(_k,_v)
	-- end
	 local skilldata = g_shareData.skillRepository[id]
	 if self:canCast(skilldata,id) == true then
	 	self.castSkillId = id
		self.spell:Cast(id,target,pos)
		self:advanceEventStamp(EventStampType.CastSkill)
		
	 end
end
return Ientity










































