local skynet = require "skynet"
local sharedata = require "sharedata"
local gdd  = {
	skillRepository = require "skillRepository",	
	heroModolRepository = require "heroModolRepository",
	heroRepository = require "heroRepository",
	monsterRepository = require "monsterRepository",
}
skynet.start(function()
	sharedata.new("gdd",gdd)
end
)

