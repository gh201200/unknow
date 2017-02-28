local skynet = require "skynet"
local watchdog 
local CMD = {}

local match
local players = {}
function CMD.getPvpAIs(num)
	local AIs = {}
	local accouts = { "robot11" ,"robot22","robot33"}
	--accouts = { "robot1" }
	--accouts = {}
	for k, v in pairs(accouts) do
		local agent = skynet.call(watchdog,"lua","authAi",v)
		skynet.call(agent,"lua","Request","enterGame")
		--开始匹配
		local p = skynet.call(agent,"lua","getmatchinfo")
		p.isAI = true
		table.insert(AIs,p)
	end
	--print("======AIs",#AIs)
	return AIs		
end

function CMD.start(w)
	watchdog = w
end
skynet.start(function()
	skynet.dispatch("lua",function(_,_,command,...)
		local f = CMD[command]
		local r = f(...)
		return skynet.ret(skynet.pack(r))
	end)
end)
