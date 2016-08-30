local AIFsm = class("AIFsm")

function AIFsm:ctor(entity)
	self.mCurrentAIState = ""
	self.mNextAIState = ""
	self.mCurrFsm = {}
	self.Fsms = {}
end

function AIFsm:update(dt)
	if self.mCurrentAIState ~= self.mNextAIState then
		if self.mCurrFsm ~= nil then
			self.mCurrFsm['onExit'](self)
			self.mCurrFsm = self.Fsms[self.mNextAIState]
			self.mCurrentAIState = self.mNextAIState
			self.mCurrFsm['onEnter'](self)
		end
	else
		if self.mCurrFsm ~= nil  then
			self.mCurrFsm['onExec'](self)
		end
	end
end

function AIFsm:setNextAiState(_next)
	self.mNextAIState  = _next
end

return AIFsm
