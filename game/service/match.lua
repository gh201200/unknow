local skynet = require "skynet"
local coroutine = require "skynet.coroutine"
local syslog = require "syslog"
local traceback  = debug.traceback
local uuid = require "uuid"

local CMD = {}
local requestMatchers = {}
local reverseMatchers = {}
local database

local baseRate = 10000 --同一分数匹配人数不超过一万人
local account_cors = {}
local s_pickHeros = { } --选角色服务

function CMD.hijack_msg(response)
	local ret = {}
	for k, v in pairs(CMD) do
		if type(v) == "function" then
			table.insert(ret, k)
		end
	end
	response(true, ret )
end


--请求匹配 arg = {agent = ,account = ,modelid = ,nickname= ,score = ,time = ,range = }
function CMD.requestMatch(response,agent)
	print("CMD.requestMatch")
	local arg = skynet.call(agent,"lua","getmatchinfo")
	print("arg",arg)
	if reverseMatchers[arg.account] ~= nil then
		print(arg.account,"already in match list")
		return
	end
	local hash_key = arg.score * baseRate
	for i = hash_key,hash_key + baseRate,1 do
		if requestMatchers[i] == nil then
			requestMatchers[i] = arg
			reverseMatchers[arg.account] = i 
			break
		end
	end
	account_cors[arg.account] = coroutine.create(function(ret)
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


--处理匹配到的人 account nickname agent
local function handleMatch(t)
	--分配队组
	local colors = {1,4,2,5,3,6}
	local i = 1
	for _k,_v in pairs(t) do
		i = i + 1
		_v.color = colors[i]
		i = i + 1
	end
	--返回 分组信息
	local s_pickHero =  skynet.newservice "pickHero"
	table.insert(s_pickHeros,s_pickHero)
	skynet.call(s_pickHero,"lua","init",t)
	local ret = { errorcode = 0 ,matcherNum = 0,matcherList = {} }
	for _k,_v in pairs(t) do
		ret.matcherNum = ret.matcherNum + 1
		local tmp = { account = _v.account,nickname = _v.nickname,color = _v.color }
		table.insert(ret.matcherList,tmp)
		skynet.call(_v.agent,"lua","enterPickHero",s_pickHero)
	end
	for _k,_v in pairs(t) do
		coroutine.resume(account_cors[_v.account],ret)
	end
end
CMD.MATCH_NUM = 1 
local function update()
	skynet.timeout(100, update) 
	local dt = 1 
	--{agent = ,account = ,modelid = ,nickname= ,score = ,time = ,range = }
	--print(requestMatchers)
        for _k,_v in pairs(requestMatchers) do
                _v.time = _v.time + dt
                --_v. =  math.floor(_v.time/10000)* 10 + 10
        end 
        for _k,_v in pairs(requestMatchers) do
                if _v ~= nil then
                        local _nk,_nv = _k,_v
                        local key = _nk
                        local maxRange = _nv.range
                        local matchTb = {}
                        matchTb[_nk] = _nv
                        for i=1,CMD.MATCH_NUM -1,1 do
                                _nk,_nv = next(requestMatchers,_nk)
                                if _nk == nil then
                                        break
                                end
                                matchTb[_nk] = _nv
                                if _nv.range > maxRange then
                                        key = _nk
                                        maxRange = _nv.range
                                end
                        end
                        if _nk ~= nil then
                                --if maxRange*baseRate + key >= _nk and key - maxRange*baseRate <= _k then
                                        for _i,_ in pairs(matchTb) do
						local account = requestMatchers[_i].account 
                                                reverseMatchers[account] = nil
						requestMatchers[_i] = nil
                                        end             
                                        handleMatch(matchTb)
                                --end
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

