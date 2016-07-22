local skynet = require "skynet"
local sharedata = require "sharedata"
local gdd  = {
	skillRepository = require "skillRepository",	
	heroModolRepository = require "heroModolRepository",
	heroRepository = require "heroRepository"
}
skynet.start(function()
	sharedata.new("gdd",gdd)
end
)

