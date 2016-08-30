local AIBase = require "ai.AIBase"
local EntityManager = require "entity.EntityManager"
local vector3 = require "vector3"


local NpcAI = class("NpcAI", AIBase)

function NpcAI:ctor(entity)

	NpcAI.super.ctor(self, entity)

	self.refreshTarget = 0

	self.Fsms["Idle"] = {["onEnter"] = self.onEnter_Idle, ["onExec"] = self.onExec_Idle,["onExit"] = self.onExit_Idle}
	self.Fsms["Chase"] = {["onEnter"] = self.onEnter_Chase, ["onExec"] = self.onExec_Chase,["onExit"] = self.onExit_Chase}
	self.Fsms["Battle"] = {["onEnter"] = self.onEnter_Battle, ["onExec"] = self.onExec_Battle,["onExit"] = self.onExit_Battle}
	self.Fsms["GoHome"] = {["onEnter"] = self.onEnter_GoHome, ["onExec"] = self.onExec_GoHome,["onExit"] = self.onExit_GoHome}
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

function NpcAI:updatePreCast()
	--decide whitch skill it will be cast
	self.source:preCastSkill()
	--self.followLen = self.source:getPreSkillData().n32Range
	self.followLen = 2
end

function NpcAI:onEnter_Idle()
	
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
	end
end

function NpcAI:onExit_Idle()
end

function NpcAI:onEnter_Chase()
	self:updatePreCast()
	self.source:setTarget(self.source:getTarget())
end

function NpcAI:onExec_Chase()
	local dis = vector3.len(self.source.pos, self.source.bornPos)
	if dis > self.source.attDat.n32HateRange then
		self:setNextAiState("GoHome")
		return
	end
	
	if self.source:getDistance(self.source:getTarget()) <= self.followLen then
		self:setNextAiState("Battle")
	end
end

function NpcAI:onExit_Chase()
end

function NpcAI:onEnter_Battle()
end

function NpcAI:onExec_Battle()
	if self.source.spell:isSpellRunning() then return end

	if self.source:getPreSkillData() == nil then
		self:updatePreCast()
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
end

function NpcAI:onExec_GoHome()
	self.source:setTargetPos(self.source.bornPos)
end

function NpcAI:onExit_GoHome()
end

return NpcAI


