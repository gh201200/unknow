local skynet = require "skynet"
local sharedata = require "sharedata"
local gdd  = {
	skillRepository = require "skillRepository",	
	heroModelRepository = require "heroModelRepository",
	heroRepository = require "heroRepository",
	monsterRepository = require "monsterRepository",
	spawnMonsterResp = require "spawnMonsterRepository",
	mapRepository = require "mapRepository",
	itemRepository = require "itemRepository",
	itemDropPackage = require "itemDropPackage",
	heroLevel = require "heroLevel",
	effectRepository = require "effectRepository",
	lzmRepository = require "lzmRepository",
	petRepository = require "petRepository",
	shopRepository = require "shopRepository",
	patternRepository = require "patternRepository",
}
skynet.start(function()
	sharedata.new("gdd",gdd)
end
)

