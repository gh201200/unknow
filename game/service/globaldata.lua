local skynet = require "skynet"
local sharedata = require "sharedata"
local gdd  = {
	DEF = require "vardefine",
	Quest = require "quest",
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
	exploreRepository = require "exploreRepository",
	dropPackage = require "dropPackage",
	missionRepository = require "missionRepository",
}
skynet.start(function()
	sharedata.new("gdd",gdd)
end
)

