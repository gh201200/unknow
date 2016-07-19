local skynet  = require "skynet"
local AIFsm = require "AI.AIFsm"
local AIBase = class(AIFsm)

function AIBase:ctor()
	self.source = nil
	self.target = nil	
end

