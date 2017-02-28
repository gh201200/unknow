local skynet = require "skynet"
require "skynet.manager"	-- import skynet.monitor
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
		if v.agent then
			skynet.call(_agent,"lua","quitPick")
		end
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
	local monitor = skynet.monitor "simplemonitor"
	for _k,_v in pairs(playerTb) do
		players[_v.agent] = { agent = _v.agent, account = _v.account, nickname = _v.nickname, pickedheroid = 0,confirmheroid = 0,
		color = _v.color, level = _v.fightLevel, eloValue=_v.eloValue,isAI = _v.isAI}
		skynet.call(monitor, "lua", "watch", _v.agent)
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
			if _v.agent then
				skynet.call(_v.agent,"lua","sendRequest","pickedhero",t)
			end
		end
	end
end

--确定英雄
function CMD.confirmHero(response,agent,account,arg)
	local ret = { errorcode = 0 }
	local confirmid = players[agent].pickedheroid
	repeat
		if confirmid == 0 then
			ret.errorcode = -1
			break
		end
		local bind = skynet.call(agent,"lua","isBindSkills", confirmid)
		if not bind then
			ret.errorcode = 1
			break
		end
		for _agent,_v in pairs (players) do
			if _agent ~= agent and Macro_GetCardSerialId(confirmid) == Macro_GetCardSerialId(_v.pickedheroid) then
				ret.errorcode = 2
				break
			end
		end
	until true
	response(true,ret)
	if ret.errorcode == 0 then
		players[agent].confirmheroid = confirmid 
		local t = { account = account, heroid = confirmid }
		for _agent,_v in pairs(players) do
			if _v.agent then
				skynet.call(_agent,"lua","sendRequest","confirmedHero",t)
			end
		end
		--enterMap()
	end
	local isReady = true
	for _agent,_v in pairs(players) do
		if players[_agent].confirmheroid == 0 then
			isReady	= false
		end
	end
	if isReady == true then
		--全部选中英雄
		max_pickTime =  -1
	end
end

local function aiPickHero(v)
	--[[
	local roles = {
		110001,
		110101,
		120001,
		120101,
		130001,
		130101,
		210001,
		210101,
		220001	
	}]]
	local roles = {110001,120001,130001,130101}
	--roles = {110001}
	local selects = {}
	for _agent,_v in pairs(players) do
		if _v.pickedheroid ~= 0 then
			selects[_v.pickedheroid] = _v.agent
		end	
	end
	local lefts = {}
	for k, v in pairs(roles) do
		if selects[v] == nil then
			table.insert(lefts,v)
		end
	end
	local index = math.random(1,#lefts)
	CMD.pickHero(function(...)end,v.agent,v.account,{heroid = lefts[index]} )
	CMD.confirmHero(function(...)end,v.agent,v.account,{heroid = lefts[index]} )	
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
	--AI 选角色
	local roles = {110001,120001,130001,130101}
--	local i = 1;
	for _agent,_v in pairs(players) do
		if _v.isAI == true and _v.pickedheroid == 0 then
			print("选择机器人")
			--CMD.pickHero(function(...)end,_agent,_v.account,{heroid = roles[i]} )	
			--CMD.confirmHero(function(...)end,_agent,_v.account,{heroid = roles[i]} )	
			--i = i + 1
			aiPickHero(_v)
		end
	end

	max_pickTime = max_pickTime - 1
	skynet.timeout(100,update)
end

local function init()
	skynet.timeout(100, update)
end

skynet.start(function ()
	init()
	skynet.dispatch("error", function (address, source, command, ...)
		for _agent,_v in pairs (players) do
			if _agent == source then
				_v.agent = nil
			end
		end
	end)
	skynet.dispatch("lua", function (_, _, command, ...)
		local f = CMD[command]
		if not f then
			f = REQUEST[command]
		end
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

