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
	fuseSkillRepository = require "fuseSkillRepository",
}

local CMD = {}

function CMD.newdata(key, data)
	sharedata.new(key, data)
end

skynet.start(function()
	sharedata.new("gdd",gdd)
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		f(...)
	end)
end
)

