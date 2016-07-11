local vector3 = require "vector3"
local spell =  require "entity.spell"
local Ientity = class("Ientity")
local sharedata = require "sharedata"



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
	self.clientEventStamps = {}		--now this table has no means
	self.newClientReq = {}			--whether
	self.coroutine_pool = {}
	self.coroutine_response = {}
	--skynet about
	
	--技能相关----
	self.spell = spell.new()
end


function Ientity:advanceEventStamp(event)
	if not self.serverEventStamps[event] then
		self.serverEventStamps[event] = 0
	end
	if not self.clientEventStamps[event] then
		self.clientEventStamps[event] = 0
	end

	self.serverEventStamps[event] = self.serverEventStamps[event] + 1

	if self.newClientReq[event] and self.serverEventStamps[event] > self.clientEventStamps[event] then 
		self.clientEventStamps[event] = self.serverEventStamps[event]
		self.newClientReq[event] = false				
		respClientEventStamp(self.coroutine_pool[event], self.serverId, event)
	end
end

function Ientity:checkeventStamp(event, stamp)
	print("checkeventStamp",event,self.serverEventStamps[event],stamp) 
	if not self.serverEventStamps[event] then
		self.serverEventStamps[event] = 0
	end
	if not self.clientEventStamps[event] then
		self.clientEventStamps[event] = 0
	end

	if  self.serverEventStamps[event] > stamp then 
		self.clientEventStamps[event] = self.serverEventStamps[event]
		self.newClientReq[event] = false				
		respClientEventStamp(self.coroutine_pool[event], self.serverId, event)
	else
		self.clientEventStamps[event] = stamp
		self.newClientReq[event] = true				--mark need be resp
		return nil
	end
end


function Ientity:stand()
	print("stand")
	self.moveSpeed  = 0
	self.curActionState = ActionState.stand
end

function Ientity:setTargetPos(target)
	print("setTargetPos")
	self.targetPos:set(target.x/GAMEPLAY_PERCENT, target.y/GAMEPLAY_PERCENT, target.z/GAMEPLAY_PERCENT)
	self.moveSpeed = 1
	self.curActionState = ActionState.move
end

function Ientity:update(dt)
--	print("Ientity:update",self.testvalue)
	if self.spell ~= nil then
		self.spell:update(dt)
	end
end
---------------------------------------------------技能相关-------------------------------------
function Ientity:canCast(skilldata,target,pos)
	return true
end


function Ientity:setCastSkillId(id)
         print("Ientity:setCastSkillId",id,EventStampType.CastSkill)
         for _k,_v in pairs(self.gdd.skillRepository) do
		print(_k,_v)
	 end
	 self.castSkillId = id
	 self:advanceEventStamp(EventStampType.CastSkill)
end
return Ientity










































