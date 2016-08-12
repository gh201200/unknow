local skynet = require "skynet"
local coroutine = require "skynet.coroutine"
local syslog = require "syslog"
local traceback  = debug.traceback

local CMD = {}
local requestMatchers = {}
local reverseMatchers = {}
local database

local baseRate = 10000 --同一分数匹配人数不超过一万人
local account_cors = {}


function CMD.hijack_msg(response)
	local ret = {}
	for k, v in pairs(CMD) do
		if type(v) == "function" then
			table.insert(ret, k)
		end
	end
	response(true, ret )
end


--请求匹配 arg = {agent = ,account = ,modelid = ,username= ,score = ,time = ,range = }
function CMD.requestMatch(response,agent)
	print("CMD.requestMatch")
	local arg = skynet.call(agent,"lua","getmatchinfo")
	if reverseMatchers[arg.account] ~= nil then
		print(arg.account,"already in match list")
		return
	end
	local hash_key = arg.score * baseRate
	for i = hash_key,hash_key + baseRate,1 do
		if requestMatchers[i] == nil then
			requestMatchers[i] = arg
			reverseMatchers[arg.account] = i --反向表 便于查找
			break
		end
	end
	account_cors[arg.account] = coroutine.create(function(ret)
		print("account_cosrs")
		response(true,ret)
	end)
end

--取消匹配
function CMD.cancelMatch(response,account)
	local hashkey = reverseMatchers[account]
	if hashkey ~= nil then
		table.remove(reverseMatchers,account)
		table.remove(requestMatchers,hashkey)
		table.remove(account_cors,account)
	end
	local ret = { errorcode = 0 }
	response(true,ret)
end


--处理匹配到的人
local function handleMatch(t)
	--启动地图服务
	print("handleMatch")
	local mapserver = skynet.newservice ("room")
	local ret = { errorcode = 0 ,matcherNum = #(t),matcherList = {} }
	
	for _k,_v in pairs(t) do
		skynet.call(_v.agent, "lua", "enterMap", mapserver)	
		table.insert(ret.matcherList,{ account = _v.account, modleid = _v.modeleid, username = _v.username })
		coroutine.resume(account_cors[_v.account],ret)
	end
end

local function update()
	skynet.timeout(100, update)  
	dt = 1
	---begin test-----
	if next(requestMatchers) ~= nil then
		handleMatch(requestMatchers)
		requestMatchers = {}	
	end
	if true then return end
	---end   test-----
         for _k,_v in pairs(requestMatchers) do
                 _v[4]  = _v[4] + dt
                 _v[5] =  math.floor(_v[4]/10000)* 10 + 10
         end 
         for _k,_v in pairs(requestMatchers) do
                 if _v ~= nil then
                         local _nk,_nv = _k,_v
                         local key = _nk
                         local maxRange = _nv[5]
                         local matchTb = {}
                         matchTb[_nk] = _nv
                         for i=1,5,1 do
                                 _nk,_nv = next(requestMatchers,_k)
                                 matchTb[_nk] = _nv
                                 if _nk == nil then
                                         break
                                 end
                                 if _nv[5] > maxRange then
                                         key = _nk
                                         maxRange = _nv[5]
                                 end
                         end
                         if _nk ~= nil then
                                 if maxRange*baseRate + key >= _nk and key - maxRange*baseRate <= _k then
                                         for _i,_ in pairs(matchTb) do 
                                                 requestMatchers[_i] = nil
                                         end             
                                         handleMatch(matchTb)
                                 end
                         end
                 end
	end
end		
local function init()
	--every 1s update entity
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

