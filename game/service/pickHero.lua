local skynet = require "skynet"
local traceback  = debug.traceback
local syslog = require "syslog"

local CMD = {}
local players = {}
local max_pickTime = 30000

local function enterMap()
	local mapserver = skynet.newservice ("room")
	skynet.call(mapserver, "lua", "start", players)
	skynet.exit()
end

local function quitPick()
	for _agent,_v in pairs(players) do
		skynet.call(_agent,"lua","quitPick")
	end
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
	local i = 0
	local colors = {1,4,2,5,3,6}
	for _k,_v in pairs(playerTb) do
		i = i + 1
		players[_v.agent] = { agent = _v.agent, account = _v.account, nickname = _v.nickname, pickedheroid = 0,confirmheroid = 0,color = colors[i]}
	end
	response(true,nil)
end

--选择英雄
function CMD.pickHero(response, agent, account ,arg)
	local ret = {errorcode = 0}
	for _agent,_v in pairs(players) do
		if math.floor(arg.heroid / 10) == math.floor(_v.pickedheroid / 10) then
			ret.errorcode = 1 
			break
		end
	end
	response(true,ret)
	if ret.errorcode == 0 then
		players[agent].pickedheroid = arg.heroid
		local t = {account = account,heroid = arg.heroid}
		for _agent,_v in pairs(players) do
			skynet.call(_agent,"lua","sendRequest","pickedhero",t)
		end
	end
end

--确定英雄
function CMD.confirmHero(response,agent,account,arg)
	local ret = { errorcode = 0 }
	local confirmid = players[agent].pickedheroid
	for _agent,_v in pairs (players) do
		if _agent ~= agent and confirmid / 10 == _v.pickhedheroid then
			ret.errorcode = 1
		end
	end
	if confirmid == 0 then
		ret.errorcode = 2
	end
	response(true,ret)
	if ret.errorcode == 0 then
		players[agent].confirmheroid = confirmid 
		local t = { account = account, heroid = confirmid }
		for _agent,_v in pairs(players) do
			skynet.call(_agent,"lua","sendRequest","confirmedHero",t)
		end
		--enterMap()
	end
	print("====pick",players)
	local isReady = true
	for _agent,_v in pairs(players) do
		if players[_agent].confirmheroid == 0 then
			isReady	= false
		end
	end
	if isReady == true then
		--全部选中英雄
		max_pickTime =  -1
		print("=========max_pickTime",max_pickTime)
	end
end


local function update()
	if max_pickTime < 0 then
		
		for _agent,_v in pairs(players) do
			if _v.confirmheroid == 0 and _v.pickheroid == 0 then
				quitPick()
				return
			elseif _v.confirmheroid == 0 and _v.pickheroid ~= 0 then
				_v.confirmheroid = _v.pickheroid
			end		
		end
		enterMap()
		return		
	end
	max_pickTime = max_pickTime - 1
	skynet.timeout(100,update)
	for _agent,_v in pairs(players) do
		skynet.call(_agent,"lua","sendRequest","synPickTime",{ leftTime = max_pickTime } ) 
	end
end
local function init()
	skynet.timeout(100, update)
end
skynet.start(function ()
	init()
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

