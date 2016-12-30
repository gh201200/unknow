local skynet = require "skynet"
local Time = require "time"
local json = require "cjson"

local enable = true

local WRITE_NUM = 2
local SAVE_NUM = 10

local accountfile = "../logdb/account"
local accountHandler
local accountLogNum = 0

local cardfile = "../logdb/card"
local cardHandler
local cardLogNum = 0

function init()
	if enable then return end
	local timeStr = os.date("%Y-%m-%d-%H-%M")
	
	accountfile = accountfile .."_" .. timeStr .. ".log"
	accountHandler = io.open(accountfile, "a+")
	
	cardfile = cardfile .. "_" .. timeStr .. ".log"
	cardHandler = io.open(cardfile, "a+")
end

function exit()
	io.close( accountHandler )
	io.close( cardHandler )
end

local function writeAccount( txt )
	accountHandler:write( string.format("[:%08x] %s\n", accountLogNum, txt))
	accountLogNum = accountLogNum + 1 
	if accountLogNum >= SAVE_NUM then
		io.close( accountHandler )
		local timeStr = os.date("%Y-%m-%d-%H-%M")
		accountfile = accountfile .."_" .. timeStr .. ".log"
		accountHandler = io.open(accountfile, "a+")
		accountLogNum = 0
	elseif accountLogNum % WRITE_NUM == 0 then
		accountHandler:flush()
	end
end

local function writeCard( txt )
	cardHandler:write( txt .. "\n" )
	cardLogNum = cardLogNum + 1
	if cardLogNum >= SAVE_NUM then
		io.close( cardHandler )
		local timeStr = os.date("%Y-%m-%d-%H-%M")
		cardfile = cardfile .. "_" .. timeStr .. ".log"
		cardHandler = io.open(cardfile, "a+")
		cardLogNum = 0
	elseif cardLogNum % WRITE_NUM == 0 then
		cardHandler:flush()
	end

end

---------------------------------------------------
--REQUEST

---------------------------------------------------
--POST
function accept.log( name, args )
	args.time = Time.GetCurStringTime()
	local jt = json.encode( args )
	print( jt )
	if enable then return end
	if name == "account" then
		writeAccount( jt )
	elseif name == "card" then
		writeCard( jt )
	end
end


