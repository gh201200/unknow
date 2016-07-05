#!/usr/bin/env lua
---Sample application to read a XML file and print it on the terminal.
--@author Manoel Campos da Silva Filho - http://manoelcampos.com
dofile("../3rd/LuaXML/xml.lua")
dofile("../3rd/LuaXML/handler.lua")
local filename = "./lualib/gamedata/skill.xml"
local xmltext = ""
local f, e = io.open(filename, "r")
if f then
  xmltext = f:read("*a")
else
  error(e)
end
local xmlhandler = simpleTreeHandler()
local xmlparser = xmlParser(xmlhandler)
xmlparser:parse(xmltext)

local skillTable = {}
for k, p in pairs(xmlhandler.root.SkillCfgmanager.info) do
	local tmpTb = {}
	for _i,_v in pairs(p)do
		if(_i == "szName") then
			tmpTb.name = _v
		elseif(_i == "_attr") then
			tmpTb.id = _v.id		
		end
	end
	skillTable[tmpTb.id] = tmpTb
end

for _k,_v in pairs(skillTable) do
	print(_k,_v.id,_v.name)
end
--function skillTable:getskill(skillid)
--	return skillTable[skillid]
--end
return skillTable
