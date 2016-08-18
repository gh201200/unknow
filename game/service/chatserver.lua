local skynet = require "skynet"
local mc = require "multicast"
local dc = require "datacenter"
local CMD = {}
local CHANNEL = {}
function CMD.init()
	CMD.createChannel("system_channel") --注册系统聊天频道
end

function CMD.publish(type,msg)
	local channelid = dc.get(type)
	local channel = CHANNEL[channelid]
	if channelid ~= nil and channel ~= nil then
		channel:publish(msg)		
	end
end
function CMD.createChannel(channelName)
	local channel = mc.new()
	dc.set(name,channel.channel)
	CHANNEL[channel.channel] = channel
end

skynet.start(function ()
	skynet.dispatch("lua", function (_, _, command, ...)
		local f = CMD[command]
		if not f then
			syslog.warningf("match service unhandled message[%s]", command)	
			return skynet.ret()
		end
		local ok, ret = xpcall(f, traceback,...)
		if not ok then
			syslog.warningf("match service handle message[%s] failed : %s", commond, ret)		
			return skynet.ret()
		end
	end)
end)

