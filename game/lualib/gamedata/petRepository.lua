#!/usr/bin/env lua
---Sample application to read a XML file and print it on the terminal.
--@author Manoel Campos da Silva Filho - http://manoelcampos.com
dofile("../3rd/LuaXMLlib/xml.lua")
dofile("../3rd/LuaXMLlib/handler.lua")
local filename = "./lualib/gamedata/PetRepository.xml"
local xmltext = ""
local f, e = io.open(filename, "r")
if f then
  xmltext = f:read("*a")
else
  error(e)
end
local xmlhandler = simpleTreeHandler()
xmlhandler.options = {noreduce={item=1}}
local xmlparser = xmlParser(xmlhandler)
xmlparser:parse(xmltext)

local petTable = {}
for k, p in pairs(xmlhandler.root.info.item) do
	local tmpTb = {}
	for _i,_v in pairs(p)do
		if _i == "_attr" then
			tmpTb.id = tonumber(_v.id)
		else
			if tonumber(_v) ~= nil then
				tmpTb[_i] = tonumber(_v)
			else
				tmpTb[_i] = _v
			end
		end
	end
	petTable[tmpTb.id] = tmpTb
end


return petTable
