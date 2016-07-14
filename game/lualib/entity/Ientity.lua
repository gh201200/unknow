local vector3 = require "vector3"
local spell =  require "entity.spell"
local Ientity = class("Ientity")
local sharedata = require "sharedata"

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

	self.modolId = 0	--模型id	
	--技能相关----
	self.spell = spell.new()
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
	print("stand")
	self.moveSpeed  = 0
	self.curActionState = ActionState.stand
end

function Ientity:setTargetPos(target)
	print("setTargetPos")
--	if self.spell:Breaking(ActionState.move) == false then return end
	
	self.targetPos:set(target.x/GAMEPLAY_PERCENT, target.y/GAMEPLAY_PERCENT, target.z/GAMEPLAY_PERCENT)
	self.moveSpeed = 1
	self.curActionState = ActionState.move
end

function Ientity:update(dt)
	self.spell:update(dt)
end
---------------------------------------------------技能相关-------------------------------------
function Ientity:canCast(skilldata,target,pos)
	return true
end


function Ientity:setCastSkillId(id)
         print("Ientity:setCastSkillId",id,EventStampType.CastSkill)
        -- for _k,_v in pairs(g_shareData.skillRepository) do
	--	print(_k,_v)
	-- end
	 local skilldata = g_shareData.skillRepository[id]
	 local modoldata = g_shareData.heroModolRepository[self.modolId]
	 if modoldata ~= nil and self:canCast(skilldata,id) == true then
		if string.find(skilldata.szAction,"skill") then
			self.spell.readyTime =  modoldata["n32Skill1" .. "Time1"] or 0
			self.spell.castTime = modoldata["n32Skill1" .. "Time2"] or  0
			self.spell.endTime = modoldata["n32Skill1" .. "Time3"] or 0
		else
		
		end
		self.castSkillId = id
		
		self.spell:Cast(id,target,pos)
		self:advanceEventStamp(EventStampType.CastSkill)
		
	 end
end
return Ientity










































