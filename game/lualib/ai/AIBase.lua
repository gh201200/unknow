local AIFsm = require "ai.AIFsm"
local AIBase = class("AIBase", AIFsm)

function AIBase:ctor()
	self.source = nil
	self.target = nil	
	self.followLen = 0
end

function AIBase:update(dt)
	AIBase.super.update(self, dt)
end

return AIBase

