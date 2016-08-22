local skynet = require "skynet"
local snax = require "snax"
local sprotoloader = require "sprotoloader"

local game_config = require "config.gameserver"
local login_config = require "config.loginserver"
local max_client = 64

skynet.start(function()
			
	math.randomseed(skynet.now())

	skynet.uniqueservice("protod")
	local console = skynet.newservice("console")
	skynet.newservice("debug_console",8000)
	skynet.uniqueservice("globaldata")
	--启动数据库服务
	skynet.uniqueservice ("database")
	-----------------------------------------------------------
	------------
	skynet.uniqueservice("simpleweb")
	skynet.uniqueservice("match")
	snax.uniqueservice("cddown")
	local loginserver = skynet.newservice("loginserver")
	skynet.call(loginserver,"lua","open",login_config)
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", game_config)
	skynet.exit()
end)
