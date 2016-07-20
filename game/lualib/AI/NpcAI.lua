local AIBase = require "AI.AIBase"
local NpcAI = class(AIBase)

function NpcAI.ctor(entity)
	self.source = entity
end
function NPCAI.Init()
	super:Init()
	self.Fsms["Idle"] = {["onEnter"] = self.onEnter_Idle, ["onExec"] = self.onExec_Idle,["onExit"] = self.onExit_Idle}
	self.Fsms["Chase"] = {["onEnter"] = self.onEnter_Chase, ["onExec"] = self.onExec_Chase,["onExit"] = self.onExit_Chase}
	self.mCurrentAIState = "Idle"
	self.mNextAIState = "Idle"
	self.mCurrFsm = self.Fsms[self.mCurrentAIState]
	self.mCurrFsm["onEnter"](self)
end
function NpcAI:update()
	super.update()
	
end
function NpcAI:onEnter_Idle()
	print("NpcAI:onEnter_Idle")
	
end

function NpcAI:onExec_Idle()
	print("NpcAI:onExec_Idle")
	if self.source.target == nil then
		--更新目标 查找仇恨列表
	end
end

function NpcAI:onExit_Idle()
	print("NpcAI:onExit_Idle")
end

function NpcAI:onEnter_Chase()
	print("NpcAI:onEnter_Chase")
end

function NpcAI:onExec_Chase()
	print("NpcAI:onExec_Chase")
end

function NpcAI:onExit_Chase()
	print("NpcAI:onExit_Chase")
end

