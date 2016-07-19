local skynet = require "skynet"
local AIFsm = class("AIFsm")
function AIFsm:ctor()
	self.mCurrentAIState = ""
	self.mNextAIState = "" 
	self.mCurrFsm = {["onEnter"] = nil,["onExec"] = nil, ["onExit"] = nil}	--当前状态
	self.Fsms = {}	--所有状态
end

function AIFsm:update()
	if self.mCurrentAIState ~= self.mNextAIState then
		if next(self.mCurrFsm) ~= nil then
			self.mCurrFsm.onExit(self)
			self.mCurrFsm = self.Fsms[self.mNextAIState]
			self.mCurrentAIStat = self.mNextAIState
			self.mCurrFsm.onEnter()
		end
	else
		if next(self.mCurrFsm) ~= nil  then
			self.mCurrFsm.onExec(self)
		end
	end
end

function AIFsm:Init()
	print("AIFsm:Init")
end
