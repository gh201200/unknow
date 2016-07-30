local AIFsm = class("AIFsm")

function AIFsm:ctor()
	self.mCurrentAIState = ""
	self.mNextAIState = ""
	self.mCurrFsm = {}
	self.Fsms = {}
end

function AIFsm:update()
	if self.mCurrentAIState ~= self.mNextAIState then
		if self.mCurrFsm ~= nil then
			self.mCurrFsm:onExit()
			self.mCurrFsm = self.Fsms[self.mNextAIState]
			self.mCurrentAIState = self.mNextAIState
			self.mCurrFsm:onEnter()
		end
	else
		if self.mCurrFsm ~= nil  then
			self.mCurrFsm:onExec()
		end
	end
end

function AIFsm:Init()
	print("AIFsm:Init")
end

function AIFsm:setNextAiState(_next)
	self.mNextAIState  = _next
end

return AIFsm
