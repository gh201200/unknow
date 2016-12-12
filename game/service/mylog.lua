local skynet = require "skynet"
local Time = require "time"
local json = require "cjson"


local accountfile = "account"
local accountHandler

function init()
	local tm = Time.GetCurTableTime()
	local timeStr = tm.year.."-"..tm.month.."-"..tm.day
	accountfile = accountfile .. timeStr .. ".log"
	
	accountHandler = io.open(accountfile, "a+")
end

function exit()
	io.close( accountHandler )
end

local function writeAccount( txt )
	accountHandler.write( txt )
end

---------------------------------------------------
--REQUEST

---------------------------------------------------
--POST
function accept.log( name, args )
	local jt = json.encode( args )
	if name == "account" then
		writeAccount( jt )
	end
end
