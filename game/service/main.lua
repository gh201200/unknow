local skynet = require "skynet"
local snax = require "snax"
require "skynet.manager"	-- import skynet.monitor
local sprotoloader = require "sprotoloader"

local game_config = require "config.gameserver"
--local login_config = require "config.loginserver"
local max_client = 24 

skynet.start(function()
			
	math.randomseed(skynet.now())
	local monitor = skynet.monitor "simplemonitor"
	local console = skynet.newservice("console")
	skynet.newservice("debug_console",8000)
	
	--启动mylog服务
	local mylog = snax.uniqueservice("mylog")
	skynet.call(monitor, "lua", "watch", mylog)
	
	skynet.uniqueservice("protod")
	skynet.uniqueservice("globaldata")
	--启动数据库服务
	local database = skynet.uniqueservice ("database")
	local bg = skynet.uniqueservice ("bgsavemysql", database)
	skynet.call(monitor, "lua", "watch", bg)
	-----------------------------------------------------------
	------------
	--启动web server 服务
	skynet.uniqueservice("simpleweb")
	skynet.uniqueservice("match")
	--启动聊天服务
	skynet.uniqueservice("chatserver")
	--启动CD时间服务
	local CD = snax.uniqueservice("cddown")
	--启动activity活动服务
	snax.uniqueservice("activity")
	--启动服务管理服务
	snax.uniqueservice("servermanager")

	--local loginserver = skynet.newservice("loginserver")
	--skynet.call(loginserver,"lua","open",login_config)
	
	--启动排行榜服务
	snax.uniqueservice("toprank")
	--启动邮件中心服务
	snax.uniqueservice("centermail", database)
	
	--开启网关
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", game_config)
	
	--启动GM服务
	snax.uniqueservice("gm", watchdog)

	--开启pvpAi服务
	local PvpAIServer = skynet.uniqueservice("PvpAIServer")
	skynet.call(PvpAIServer,"lua","start",watchdog)
	--CD开始计时
	CD.post.Start()
	
	skynet.exit()
end)
