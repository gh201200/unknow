local AIBase = require "ai.AIBase"
local EntityManager = require "entity.EntityManager"
local vector3 = require "vector3"
local Map = require "map.Map"


local NpcAI = class("NpcAI", AIBase)

function NpcAI:ctor(entity)

	NpcAI.super.ctor(self, entity)

	self.refreshTarget = 0
	self.fightBackHate = 0


	self.Fsms["Idle"] = {["onEnter"] = self.onEnter_Idle, ["onExec"] = self.onExec_Idle,["onExit"] = self.onExit_Idle}
	self.Fsms["Chase"] = {["onEnter"] = self.onEnter_Chase, ["onExec"] = self.onExec_Chase,["onExit"] = self.onExit_Chase}
	self.Fsms["Battle"] = {["onEnter"] = self.onEnter_Battle, ["onExec"] = self.onExec_Battle,["onExit"] = self.onExit_Battle}
	self.Fsms["GoHome"] = {["onEnter"] = self.onEnter_GoHome, ["onExec"] = self.onExec_GoHome,["onExit"] = self.onExit_GoHome}
	self.Fsms["waitFBack"] = {["onEnter"] = self.onEnter_FightBack, ["onExec"] = self.onExec_FightBack,["onExit"] = self.onExit_FightBack}
	self.mCurrentAIState = "Idle"
	self.mNextAIState = "Idle"
	self.mCurrFsm = self.Fsms[self.mCurrentAIState]
	self.mCurrFsm["onEnter"](self)
end

function NpcAI:update(dt)
	NpcAI.super.update(self,dt)

	if self.refreshTarget >= 0 then
		self.refreshTarget = self.refreshTarget - dt
		if self.refreshTarget < 0 then
			local tId = self.source.hateList:getTopHate()
			if tId > 0 then
				self.source:setTarget(EntityManager:getEntity(tId))
			end
			self.refreashTarget = 2000
		end
	end
end

local dir = {
	[0] = {0,1},
	[1] = {1,1},
	[2] = {1,0},
	[3] = {1,-1},
	[4] = {0,-1},
	[5] = {-1,-1},
	[6] = {-1,0},
	[7] = {-1,1},
	[8] = {0,0}
}

function NpcAI:isInBornPlace()	
	local bx = Map.POS_2_GRID(self.source.bornPos.x)
	local bz = Map.POS_2_GRID(self.source.bornPos.z)
	for i=0, 8 do
		local x = Map.POS_2_GRID(self.source.pos.x)
		local z = Map.POS_2_GRID(self.source.pos.z)
		if x == bx+dir[i][1] and z == bz+dir[i][2] then
			return true
		end
	end
	return false
end

function NpcAI:updatePreCast()
	--decide whitch skill it will be cast
	self.source:preCastSkill()
	self.followLen = self.source:getPreSkillData().n32Range/GAMEPLAY_PERCENT - 0.05
end

function NpcAI:onEnter_Idle()
	self.source:stand()
end


function NpcAI:onExec_Idle()
	--更新目标 查找仇恨列表
	local tId = self.source.hateList:getTopHate()
	if tId > 0 then
		self.source:setTarget(EntityManager:getEntity(tId))
		self:setNextAiState("Chase")
		self.refreashTarget = 2000
	elseif self.source.attDat.n32VisionRange > 0 then
		local entity, len = EntityManager:getCloseEntityByType(self.source ,EntityType.player)
		if entity and len < self.source.attDat.n32VisionRange then
			self.source.hateList:addHate(entity, 1)
		end
	elseif not self:isInBornPlace() then
		self:setNextAiState("GoHome")
	end
end

function NpcAI:onExit_Idle()
end

function NpcAI:onEnter_Chase()
	self:updatePreCast()
	self.source:setTarget(self.source:getTarget())
end

function NpcAI:onExec_Chase()
	if self.source:getTarget() == nil or bit_and(self.source:getTarget().affectState,AffectState.Invincible) ~= 0  then
		self:setNextAiState("GoHome")
		return
	end
	local dis = vector3.len(self.source.pos, self.source.bornPos)
	if  self.source.attDat.n32HateRange>0 and dis > self.source.attDat.n32HateRange then
		self:setNextAiState("GoHome")
		return
	end

	if self.source.moveSpeed==0 then
		self.source:setTarget(self.source:getTarget())
	end
	

	if self.source:getDistance(self.source:getTarget()) <= self.followLen then
		self:setNextAiState("Battle")
	end
end

function NpcAI:onExit_Chase()
end

function NpcAI:onEnter_Battle()
	self.source:stand()
end

function NpcAI:onExec_Battle()
	if self.source.spell:isSpellRunning() then return end

	if self.source:getPreSkillData() == nil then
		self:updatePreCast()
	end

	if self.source:getTarget() == nil or bit_and(self.source:getTarget().affectState,AffectState.Invincible) ~= 0 then
		self:setNextAiState("Idle")
		return
	end

	if self.source:getDistance(self.source:getTarget()) <= self.followLen then
		self.source:setCastSkillId(self.source:getPreSkillData().id)
		self.source:clearPreCastSkill()
	else
		self:setNextAiState("Chase")
	end
end

function NpcAI:onExit_Battle()
end

function NpcAI:onEnter_GoHome()
	self.source:clearPreCastSkill()
	self.source:setTargetPos(self.source.bornPos)
end

function NpcAI:onExec_GoHome()
	if self.source.moveSpeed==0 then
		self.source:setTargetPos(self.source.bornPos)
	end
	if self:isInBornPlace() then
		local bx = Map.POS_2_GRID(self.source.bornPos.x)
		local bz = Map.POS_2_GRID(self.source.bornPos.z)
		if bx == Map.POS_2_GRID(self.source.pos.x) and bz == Map.POS_2_GRID(self.source.bornPos.z) then
			self:setNextAiState("waitFBack")
		elseif Map:get(bx, bz) > 0 then
			self:setNextAiState("waitFBack")
		end
	end
end

function NpcAI:onExit_GoHome()

end

function NpcAI:onEnter_FightBack()
	self.source:stand()
	self.fightBackHate = self.source.hateList:getTotalHate()
end

function NpcAI:onExec_FightBack()
	if self.fightBackHate ~= self.source.hateList:getTotalHate() then
		self:setNextAiState("Idle")
	end
end

function NpcAI:onExit_FightBack()
end


return NpcAI


