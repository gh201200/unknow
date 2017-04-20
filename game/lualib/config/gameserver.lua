local config = {
	name = "gameserver",
	port = 7777,
	maxclient = 10000,
	agent_pool = 10,
}

config.debug_port = 9333
config.web_port = 8001
config.log_level = 2 -- 1:debug 2:info 3:notice 4:warning 5:error

return config
