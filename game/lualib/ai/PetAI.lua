local AIBase = require "ai.AIBase"
--local EntityManager = require "entity.EntityManager"
local vector3 = require "vector3"
local Map = require "map.Map"

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
	self.source:stand()
end


function PetAI:onExec_Idle()
	if self:canChase() == true then
		self:setNextAiState("Chase")
	end
end

function PetAI:onExit_Idle()
	print("onExit_Idle")
end


function PetAI:onEnter_Chase()
	self.source:setTarget(self.master:getTarget())
end

function PetAI:onExec_Chase()
	if self.source:getTarget() == nil then
		self:setNextAiState("Idle")
		return
	end
	if self.source:getTarget():getType() ~= "transform" and bit_and(self.source:getTarget().affectState,AffectState.Invincible) ~= 0  then
		self:setNextAiState("Idle")
		self.source:setTargetVar(nil)
		return	
	end
	if self:canChase() == true then
		self.source:setTarget(self.master:getTarget())
	end
	if self.source:getTarget() ~= nil and  self.source:getTarget():getType() ~= "transform" then
		self.source:preCast()
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
	if self.source.spell:isSpellRunning() then return end
	
end

function PetAI:canChase()
	local petTgt = self.source:getTarget()
	local masterTgt = self.master:getTarget()
	if petTgt == nil and masterTgt ~= nil then return true end
	if petTgt ~= nil and petTgt:getType() == "transform" then return true end
	if petTgt ~= nil and petTgt:getType() ~= "transform" and self.master:isKind(masterTgt,true) == false then
		return true 
	end
	return false
end

return PetAI

