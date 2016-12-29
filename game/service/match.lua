local skynet = require "skynet"
require "skynet.manager"	-- import skynet.monitor
local coroutine = require "skynet.coroutine"
local syslog = require "syslog"
local traceback  = debug.traceback
local uuid = require "uuid"

local CMD = {}
local requestMatchers = {}
local database
local account_cors = {}
local s_pickHeros = { } --选角色服务


CMD.MATCH_NUM = 6 

local keep_list = {} 	--保持队列
local strict_list = {}	--严格队列
local loose_list = {}	--宽松队列
local listTimeoutConfig = {
	[1] = {["playerNum"] = 20,["keep"] = 4 * 1000,["strict"] = 20 * 1000,["loose"] = 2 * 60 * 1000,["keepStep"] = 1000,["strictStep"] = 1000,["looseStep"] = 1000},
	[2] = {["playerNum"] = 50,["keep"] = 30 * 1000,["strict"] = 15 * 1000,["loose"] = 2 * 60 * 1000,["keepStep"] = 1000,["strictStep"] = 1000,["looseStep"] = 1000},
	[3] = {["playerNum"] = 100,["keep"] = 20 * 1000,["strict"] = 10 * 1000,["loose"] = 2 * 60 * 1000,["keepStep"] = 1000,["strictStep"] = 1000,["looseStep"] = 1000},
	[3] = {["playerNum"] = math.maxinteger,["keep"] = 10 * 1000,["strict"] = 5 * 1000,["loose"] = 2 * 60 * 1000,["keepStep"] = 1000,["strictStep"] = 1000,["looseStep"] = 1000}
}
local listTimeouts = listTimeoutConfig[1] --超时时长

local matchConfig = {["eloStrict"] = 500,["eloLoose"] = 500,["eloStep"] = 10} --匹配配置
function CMD.hijack_msg(response)
	local ret = {}
	for k, v in pairs(CMD) do
		if type(v) == "function" then
			table.insert(ret, k)
		end
	end
	response(true, ret )
end


--请求匹配 arg = {agent = ,account = ,modelid = ,nickname= ,time = 
--eloValue stepTime fightLevel failNum
function CMD.requestMatch(response,agent)
	local p = skynet.call(agent,"lua","getmatchinfo")
	addtoKeeplist(p)
	response(true)
	--[[
	account_cors[p.account] = coroutine.create(function(ret)
		response(true,ret)
	end)
	]]--

end

--取消匹配
function CMD.cancelMatch(response,account)
	local bHit = false
	for i = #requestMatchers,1,-1 do
		if requestMatchers[i].account == account then
			table.remove(requestMatchers,i)
			table.remove(account_cors,account)
			break
		end
	end
	local ret = { errorcode = 0 }
	response(true,ret)
end


--处理匹配到的人 account nickname agent
function handleMatch(t)
	--分配队组
	local function comp_elo(a,b) 
		if a.eloValue >= b.eloValue then
			return true
		end
		return false
	end
	--table.sort(t,comp_elo)
	local colors = {1,4,5,2,3,6}
	local i = 1
	for _k,_v in pairs(t) do
		_v.src_list = nil
		_v.color = colors[i]
		i = i + 1
	end
	--返回 分组信息
	local s_pickHero =  skynet.newservice ("pickHero")
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
		skynet.call(_v.agent,"lua","sendRequest","requestPickHero",ret)
	end
end

--更新保持队列
function updateKeeplist(dt)
	local relist = {}
	for i=#(keep_list),1,-1 do
		local p = keep_list[i]
		p.time = p.time + dt
		if p.time > listTimeouts["keep"] then
			print("玩家" .. p.account .. "在保持队列超时")
			p.time = 0
			p.failNum = 0
			table.remove(keep_list,i)   --移除保持队列
			table.insert(relist,p)
		end 
	end 
	for k,v in ipairs(relist) do
		if v.src_list ~= nil then
			for i=#keep_list,1,-1 do
				if keep_list[i].account == v.account then
					print("玩家" .. v.account .. "从严格队列删除")
					table.remove(keep_list,i)
				end
			end
			addtoStictlist(v)
		end			
	end
end
-- 添加到保持队列
function addtoKeeplist(p)
	print("玩家" .. p.account .. "加入保持队列")
	if #strict_list == 0 then
		table.insert(keep_list,p)
		p.src_list = keep_list
		p.index_list = #keep_list
	else
		addtoStictlist(p)
	end
end
--更新严格队列
function updateStictlist(dt)
	local relist = {}
	for i = #strict_list,1,-1 do
		local p = strict_list[i]
		p.time =  p.time + dt
		p.stepTime = p.stepTime +  dt
		if p.time > listTimeouts["strict"] then
			print("玩家" .. p.account .. "在严格队列超时")
			p.failNum = 0
			p.time = 0
			addtoLooselist(p)
			table.remove(strict_list,i)   --移除严格队列
		else
			if p.stepTime > listTimeouts["strictStep"] then
				print("玩家" .. p.account .. "在严格列表超过步长时间,准备重新插入")
				table.insert(relist,p)	
			end
		end
	end
	for k,v in pairs(relist) do
		if v.src_list ~= nil then
			for i=#strict_list,1,-1 do
				if strict_list[i].account == v.account then
					print("玩家" .. v.account .. "从严格队列删除")
					table.remove(strict_list,i)
				end
			end
			addtoStictlist(v)
		end		
	end
end

--添加到严格队列列表
function addtoStictlist(p)
	print("玩家" .. p.account .. "加入严格队列")
	local range = p.failNum * matchConfig["eloStep"] + matchConfig["eloStrict"]
	local up = p.eloValue + range
	local down = p.eloValue - range 
	local tmp = {}
	for i=1,#(strict_list),1 do
		local v = strict_list[i]
		if v.eloValue >= down and v.eloValue <= up then
			v.src_list = strict_list
			v.index_list = i
			if v.fightLevel == p.fightLevel then
				table.insert(tmp,1,v)
			else
				table.insert(tmp,v)
			end
		end	
	end
	for i=1,#(keep_list),1 do
		local v = keep_list[i]
		if v.eloValue >= down and v.eloValue <= up then
			v.src_list = keep_list
			v.index_list = i
			if v.fightLevel == p.fightLevel then
				table.insert(tmp,1,v)
			else
				table.insert(tmp,v)
			end
		end	
	end
	for i=1,#(loose_list),1 do
		local v = loose_list[i]
		if v.eloValue >= down and v.eloValue <= up then
			v.src_list = strict_list
			v.index_list = i
			if v.fightLevel == p.fightLevel then
				table.insert(tmp,1,v)
			else
				table.insert(tmp,v)
			end
		end	
	end
	local searchNum = CMD.MATCH_NUM	- 1
	if #tmp < searchNum then
		--匹配失败
		p.failNum = p.failNum + 1
		p.stepTime = 0
		p.src_list = strict_list
		print("玩家" .. p.account .. "严格队列里匹配失败,失败次数" .. p.failNum)	
		table.insert(strict_list,p)
		p.index_list =  #strict_list
	else
		print("玩家" .. p.account .. "严格队列里匹配成功")
		local matchers = {}
		for i=1,#tmp,1 do
			if i <= searchNum then
				table.insert(matchers,tmp[i])
			else
				break
			end
		end
		local function indexCmp(a,b)
			if a.index_list > b.index_list then
				return true
			end
			return false
		end
		table.sort(matchers,indexCmp)
		for k,v in ipairs(matchers) do
			table.remove(v.src_list,v.index_list)
		end
		table.insert(matchers,p)	
		handleMatch(matchers)		
	end	
end
--添加到宽松队列
function addtoLooselist(p) 
	print("玩家" .. p.account .. "加入宽松队列")
	local range = p.failNum * matchConfig["eloStep"] + matchConfig["eloLoose"]
	local up = p.eloValue + range
	local down = p.eloValue - range 
	local tmp = {}
	for i=1,#(loose_list),1 do
		local v = loose_list[i]
		if v.eloValue >= down and v.eloValue <= up then
			v.src_list = loose_list
			v.index_list = i
			if v.fightLevel == p.fightLevel then
				table.insert(tmp,1,v)
			else
				table.insert(tmp,v)
			end
		end	
	end
	local searchNum = CMD.MATCH_NUM	- 1
	if #tmp < searchNum then
		--匹配失败
		p.failNum = p.failNum + 1
		p.stepTime = 0
		p.src_list = loose_list
		print("玩家" .. p.account .. "宽松队列里匹配失败,失败次数" .. p.failNum)	
		table.insert(loose_list,p)
		p.index_list = #loose_list
	else
		print("玩家" .. p.account .. "宽松队列里匹配成功")	
		local matchers = {}
		for i=1,#tmp,1 do
			if i <= searchNum then
				table.insert(matchers,tmp[i])
			else
				break
			end
		end
		for k,v in pairs(matchers) do
			--v.src_list = nil
			--v.index_list = nil
			table.remove(v.src_list,v.index_list)
		end
		table.insert(mathers,p)	
		handleMatch(matchers)
	end	
end
function updateLooselist(dt)
	local relist = {}
	for i = #loose_list,1,-1 do
		local p = loose_list[i]
		p.time =  p.time + dt
		p.stepTime = p.stepTime +  dt
		if p.time > listTimeouts["loose"] then
			if p.time <= (listTimeouts["loose"] + dt) then
				print("玩家" .. p.account .."宽松队列里超时，彻底匹配失败")
			else
				
			end
		else
			if p.stepTime >= listTimeouts["looseStep"] then
				print("玩家" .. p.account .."在宽松队列超过步长时间,准备重新插入")
				table.insert(relist,p)	
			end
		end
	end
	for k,v in pairs(relist) do
		if v.src_list ~= nil then
			for i=#loose_list,1,-1 do
				if loose_list[i].account == v.account then
					print("玩家"  .. v.account .. "从宽松队列移除")	
					table.remove(loose_list,i)
				end
			end
			addtoLooselist(v)
		end		
	end
end

local function update()
	skynet.timeout(20, update) 
	local dt = 200 
	updateKeeplist(dt)
	updateStictlist(dt)
	updateLooselist(dt)
end
local function updateListTimeout()
	skynet.timeout(100 * 10 * 60, updateListTimeout)
	local playerNum = #loose_list + #strict_list + #keep_list 
	for k,v in ipairs(listTimeoutConfig) do
		if v["playerNum"] > playerNum then
			listTimeouts = v
			break
		end
	end 
end
local function init()
	--every 1s update entity
	skynet.timeout(100, update)
	skynet.timeout(100 * 10 * 60, updateListTimeout)
end

local REQUEST = {}
skynet.start(function ()
	init()	
	skynet.dispatch("error", function (address, source, command, ...)
		--[[
		for i= #requestMatchers,1,-1 do
			if requestMatchers[i] ~= nil and requestMatchers[i].agent == source then
				table.remove(requestMatchers,i)
				break
			end
		end
		]]--
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

