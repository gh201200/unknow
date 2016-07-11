local skynet = require "skynet"
local sprotoloader = require "sprotoloader"

local game_config = require "config.gameserver"

local max_client = 64

skynet.start(function()
	skynet.error("Server start")
	skynet.uniqueservice("protod")
	local console = skynet.newservice("console")
	skynet.newservice("debug_console",8000)
	skynet.uniqueservice("golbaldata")

	skynet.uniqueservice("map")
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", game_config)
	skynet.exit()
end)
