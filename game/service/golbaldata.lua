local skynet = require "skynet"
local sharedata = require "sharedata"
local skillRepository= require "skillRepository"
--local skillRead = require "skillRead"
skynet.start(function()
	sharedata.new("skillRepository",skillRepository)
--	sharedata.new("skillRepository",skillRead)
end
)

