local AIBase = require "ai.AIBase"

local NpcAI = class("NpcAI", AIBase)

function NpcAI:ctor(entity)
	self.source = entity
	self.refreshTarget = 0
end

function NpcAI.Init()
	super:Init()
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
	if self.refreshTarget > 0 then
		self.refreshTarget = self.refreshTarget - dt
		if self.refreshTarget < 0 then
			local tId = self.source.hateList:getTopHate()
			if tId > 0 then
				self.source:setTarget(EntityManager:getEntity(tId))
				self.refreashTarget = 2000
			end
		end
	end
end

function NpcAI:updatePreCast()
	--decide whitch skill it will be cast
	self.source:preCastSkill()
	self.followLen = self.source:getPreSkillData().n32Range - 5
end

function NpcAI:onEnter_Idle()
	print("NpcAI:onEnter_Idle")
	
end


function NpcAI:onExec_Idle()
	print("NpcAI:onExec_Idle")
	--更新目标 查找仇恨列表
	local tId = self.source.hateList:getTopHate()
	if tId > 0 then
		self.source:setTarget(EntityManager:getEntity(tId))
		self:setNextAiState("Chase")
		self.refreashTarget = 2000
	elseif self.attDat.n32VisionRange > 0 then
		local entity = EntityManager:getCloseEntityByType(self.source ,EntityType.player)
		if entity then
			self.source.hateList:addHate(entity, 1)
		end
	end
end

function NpcAI:onExit_Idle()
end

function NpcAI:onEnter_Chase()
	print("NpcAI:onEnter_Chase")	
	self:updatePreCast()
end

function NpcAI:onExec_Chase()

	local dis = vector3.len(self.source.pos, self.bornPos)
	if disVec > self.source.attDat.n32HateRange then
		self:setNextAiState("GoHome")
		return
	end
	
	if self.source:getDistance(self.getTarget()) <= self.followLen then
		self:setNextAiState("Battle")
	end
end

function NpcAI:onExit_Chase()
	print("NpcAI:onExit_Chase")
end

function NpcAI:onEnter_Battle()
	print("NpcAI:onEnter_Battle")
end

function NpcAI:onExec_Battle()
	if self.source.spell:isSpellRunning() then return end

	if self.source:getPreSkillData() == nil then
		self:updatePreCast()
	end

	if self.source:getDistance(self.getTarget()) <= self.followLen then
		self.source:castSkill(self.source:getPreSkillData().id)
		self.source:clearPreCastSkill()
	else
		self:setNextAiState("Chase")
	end
end

function NpcAI:onExit_Battle()
	print("NpcAI:onExit_Battle")
end

function NpcAI:onEnter_GoHome()
	print("NpcAI:onEnter_GoHome")
	self.source:clearPreCastSkill()
end

function NpcAI:onExec_GoHome()
	self.source:setTargetPos(self.source.bornPos)
end

function NpcAI:onExit_GoHome()
	print("NpcAI:onExit_GoHome")
end

return NpcAI


