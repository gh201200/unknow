local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string
local sharedata = require "sharedata"
local json = require "cjson"


local mode = ...

if mode == "agent" then

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

local funcs = {}

funcs['getAccountInfo'] = function (param)
	local db = skynet.uniqueservice 'database'
	local account = skynet.call(db, "lua", "account_rd","load",param["id"])
	if not account.nick then return "" end
	local r = {
		nick = account.nick,
		password = account.password,
		gold = account.gold,
		money = account.money,
		exp = account.exp,
		icon = account.icon,
		flag = account.flag	
	}
	local jt = json.encode(r)
	return jt
end;

funcs['getCardsInfo'] = function (param)
	local db = skynet.uniqueservice 'database'
	print(param)
	local cards = skynet.call(db, "lua", "cards_rd","load",param["id"])
	print(cards)
	local jt = json.encode(cards)
	return jt
end;

funcs['getHero'] = function (param)
	local attDat = g_shareData.heroRepository[tonumber(param['id'])]
	if not attDaat then return "" end
	local r = {
		id = attDat.id,
		name = attDat.szName,
		attack = attDat.n32Attack,
	}
	local jt = json.encode(r)
	return jt
end;

skynet.start(function()
	g_shareData = sharedata.query "gdd"
	skynet.dispatch("lua", function (_,_,id)
		socket.start(id)
		-- limit request body size to 8192 (you can pass nil to unlimit)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
			
		if code then
			if method ~= "GET" then
				skynet.error("only support get method")
			elseif code ~= 200 then
				response(id, code)
			else
				local func = nil
				local params = {}
				local path, query = urllib.parse(url)
				if query then
					local q = urllib.parse_query(query)
					for k, v in pairs(q) do
						if k=='func' then
							func = funcs[v]
						else
							params[k] = v
						end
					end
				end
				if func then
					local res = func(params)
					print(res)
					response(id, code, res)
				else
					
					response(id, code)
				end
			end
		else
			if url == sockethelper.socket_error then
				skynet.error("socket closed")
			else
				skynet.error(url)
			end
		end
		socket.close(id)
	end)
end)

else

skynet.start(function()
	local agent = {}
	for i= 1, 20 do
		agent[i] = skynet.newservice(SERVICE_NAME, "agent")
	end
	local balance = 1
	local id = socket.listen("0.0.0.0", 8001)
	skynet.error("Listen web port 8001")
	socket.start(id , function(id, addr)
		skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
		skynet.send(agent[balance], "lua", id)
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)
end)

end
