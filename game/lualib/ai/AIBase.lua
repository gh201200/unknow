local AIFsm = require "ai.AIFsm"
local AIBase = class("AIBase", AIFsm)

function AIBase:ctor(entity)
	print('AIBase:ctor')
	AIBase.super.ctor(self, entity)
	self.source = entity
	self.target = nil	
	self.followLen = 0
end

function AIBase:update(dt)
	AIBase.super.update(self, dt)
end

return AIBase

