local skynet = require "skynet"
local sharedata = require "sharedata"
local gdd  = {
	skillRepository = require "skillRepository",	
	heroModelRepository = require "heroModelRepository",
	heroRepository = require "heroRepository",
	monsterRepository = require "monsterRepository",
	spawnMonsterResp = require "spawnMonsterRepository",
	mapRepository = require "mapRepository",
	effectRepository = require "effectRepository"	
}
skynet.start(function()
	sharedata.new("gdd",gdd)
end
)

