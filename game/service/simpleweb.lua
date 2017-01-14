local skynet = require "skynet"
local snax = require "snax"
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

funcs['gm_GET_opt'] = function (param)
	local gm = snax.queryservice 'gm'
	local r = gm.req[param['func']](param)
	local jt = json.encode(r)
	return jt
end;

funcs['gm_POST_opt'] = function (param)	
	local gm = snax.queryservice 'gm'
	gm.post[param['func']](param)
end;

skynet.start(function()
	g_shareData = sharedata.query "gdd"
	DEF = g_shareData.DEF
	Quest = g_shareData.Quest
	skynet.dispatch("lua", function (_,_,id)
		socket.start(id)
		-- limit request body size to 8192 (you can pass nil to unlimit)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
		print(code, url, method)		
		if code then
			if code ~= 200 then
				response(id, code)
			else
				local params = {}
				local path, query = urllib.parse(url)
				if query then
					local q = urllib.parse_query(query)
					for k, v in pairs(q) do
						params[k] = v
					end
				end
				local func = funcs['gm_' .. method .. '_opt']
				local res = func(params)
				print('res = ', res)
				response(id, code, res)
					
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
