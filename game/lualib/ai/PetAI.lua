local AIBase = require "ai.AIBase"
local vector3 = require "vector3"
local Map = require "map.Map"
require "globalDefine"

local PetAI = class("PetAI", AIBase)

function PetAI:ctor(entity,master)
	PetAI.super.ctor(self,entity)
	self.master = master
	self.Fsms["Idle"] = {["onEnter"] = self.onEnter_Idle, ["onExec"] = self.onExec_Idle,["onExit"] = self.onExit_Idle}
	self.Fsms["Chase"] = {["onEnter"] = self.onEnter_Chase, ["onExec"] = self.onExec_Chase,["onExit"] = self.onExit_Chase}
	self.Fsms["Battle"] = {["onEnter"] = self.onEnter_Battle, ["onExec"] = self.onExec_Battle,["onExit"] = self.onExit_Battle}
	self.mCurrentAIState = "Idle"
	self.mNextAIState = "Idle"
	self.mCurrFsm = self.Fsms[self.mCurrentAIState]
	self.mCurrFsm["onEnter"](self)
end

function PetAI:update(dt)
	PetAI.super.update(self,dt)
end
function PetAI:onEnter_Idle()
	print("PetAI:onEnter_Idle")	
	self.source:stand()
	self.source:setTarget(nil)
end


function PetAI:onExec_Idle()
	if self:canChase() == true then
		--普通生物
		self:setNextAiState("Chase")
	end
end

function PetAI:onExit_Idle()
	print("onExit_Idle")
end


function PetAI:onEnter_Chase()
	print("PetAI:onEnter_Chase")	
end

function PetAI:onExec_Chase()
	if self.source.spell:isSpellRunning() then return end
	self.source.ReadySkillId = self.source.pt["n32CommonSkill"]
	local t = self.source:getTarget()
	if t == nil then
		self:setNextAiState("Idle")
		self.source:setTargetVar(nil)
		return	
	end
	if self.source:getDistance(t) >= self.source.pt["n32HateRange"] then
		self:setNextAiState("Idle")
		self.source:setTargetVar(nil)
		return 
	end
end

function PetAI:onExit_Chase()
end

function PetAI:onEnter_Battle()
	print("PetAI:onEnter_Battle")
	self.source:stand()
end

function PetAI:onExec_Battle()
	
end

function PetAI:onExit_Battle()
	print("PetAI:onExit_Battle")
	
end

function PetAI:canChase()
	print("canChase")
	for k, v in pairs( g_entityManager.entityList ) do 
		if self.master:isKind(v,true) == false then
			if self.source:getDistance(v) <= self.source.pt["n32HateRange"] then
				self.source:setTarget(v)
				return true
			end	
		end	
	end
	return false
end

return PetAI

