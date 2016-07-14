local skynet = require "skynet"
local sharedata = require "sharedata"
local gdd  = {
	skillRepository = require "skillRepository",	
	buffRep = require "buffRepository",
}
skynet.start(function()
	sharedata.new("gdd",gdd)
end
)

