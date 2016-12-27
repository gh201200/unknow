local skynet = require "skynet"
local snax = require "snax"
local sprotoloader = require "sprotoloader"

local game_config = require "config.gameserver"
local max_client = 24 
local robots = {}
skynet.start(function()
			
	math.randomseed(skynet.now())
	for i=1,2,1 do
		local a = skynet.newservice("robot")
		skynet.call(a,"lua","start",{account = "test" .. i} )
	end
	--skynet.exit()
end)
