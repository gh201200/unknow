local skynet = require "skynet"
local snax = require "snax"
local sprotoloader = require "sprotoloader"
local ip = "127.0.0.1" 	--服务器ip
local port =  8888		--服务器端口
local robotsNum = 5  		--要启动的机器人数量
skynet.start(function()
	math.randomseed(skynet.now())
	for i=1,robotsNum,1 do
		local a = skynet.newservice("robot")
		skynet.call(a,"lua","start",{account = "robot" .. i,ip = ip, port = port} )
	end
	--skynet.exit()
end)
