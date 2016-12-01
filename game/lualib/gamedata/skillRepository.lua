#!/usr/bin/env lua
---Sample application to read a XML file and print it on the terminal.
--@author Manoel Campos da Silva Filho - http://manoelcampos.com
dofile("../3rd/LuaXMLlib/xml.lua")
dofile("../3rd/LuaXMLlib/handler.lua")
local filename = "./lualib/gamedata/SkillDatas.xml"
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

local skillTable = {}
for k, p in pairs(xmlhandler.root.info.item) do
	local tmpTb = {}
	for _i,_v in pairs(p)do
		if _i == "_attr" then
			tmpTb.id = tonumber(_v.id)
		else
			if tonumber(_v) == nil then
				if _i == "szSelectRange" or _i == "szAffectRange" or _i == "szAffectTargetAffect" or _i == "szSelectTargetAffect" or _i == "szMyAffect" then
					if _v ~= "" then
						tmpTb[_i] = string.parserskillStr(_v)
						if _i == "szSelectRange" or _i == "szAffectRange" then
							tmpTb[_i] = tmpTb[_i][1]
						end
					else 
						tmpTb[_i] = ""
					end
				else
					tmpTb[_i] = _v	
				end
			else
				tmpTb[_i] = tonumber(_v)	
			end
		end
	end
	skillTable[tmpTb.id] = tmpTb
end


--print("skillTable",skillTable)
return skillTable
