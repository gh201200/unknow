local skynet = require "skynet"
local traceback  = debug.traceback
local syslog = require "syslog"
local CMD = {}
local players = {}
local max_pickTime = 30

local function enterMap()
	local mapserver = skynet.newservice ("room")
	for _agent,_v in pairs(players) do
		skynet.call(_agent,"lua","enterMap",mapserver,_v)
	end
	--退出服务
	skynet.exit()		
end

function CMD.hijack_msg(response)
	local ret = {}
	for k, v in pairs(CMD) do
		if type(v) == "function" then
			table.insert(ret, k)
		end
	end
	response(true, ret )
end

function CMD.init(response,playerTb)
	for _k,_v in pairs(playerTb) do
		players[_v.agent] = { agent = _v.agent, account = _v.account, nickname = _v.nickname, lockedheroid = 0 ,pickedheroid = 0 ,color = 1 }
	end
	response(true,nil)
end

--选择英雄
function CMD.pickHero(response, agent, account ,arg)
	local ret = {errorcode = 0}
	response(true,ret )

	if ret.errorcode == 0 then
		local t = {account = account,heroid = arg.heroid}
		for _agent,_v in pairs(players) do
			skynet.call(_agent,"lua","sendRequest","pickedhero",t)
		end
		enterMap()
	end
end

--锁定英雄
function CMD.lockHero(response,agent,account,arg)
	local ret = { errorcode = 0 }
	response(true,ret)
	players[agent].lockedheroid = arg.heroid
	if ret.errorcode == 0 then
		local t = { account = account, heroid = arg.heroid }
		for _agent,_v in pairs(players) do
			skynet.call(_agent,"lua","sendRequest","lockedHero",t)
		end
	end
end


local function update()
	if max_pickTime < 0 then	
		enterMap()
		return		
	end
	max_pickTime = max_pickTime - 1
	skynet.timeout(100,update)
	for _agent,_v in pairs(players) do
		skynet.call(_agent,"lua","sendRequest","picked",t)
	end
end

skynet.start(function ()
	skynet.dispatch("lua", function (_, _, command, ...)
		local f = CMD[command]
		if not f then
			syslog.warningf("match service unhandled message[%s]", command)	
			return skynet.ret()
		end
		local ok, ret = xpcall(f, traceback,  skynet.response(), ...)
		if not ok then
			syslog.warningf("match service handle message[%s] failed : %s", commond, ret)		
			return skynet.ret()
		end
	end)
end)

