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
			if string.match(_i,"n32%a+") then
				if _i == "n32Radius" and tonumber(_v) == nil then
					local t = string.split(_v,",")	
					tmpTb[_i] = {}
					tmpTb[_i][1] = tonumber(t[1])	
					tmpTb[_i][2] = tonumber(t[2])	
				else
					tmpTb[_i] = tonumber(_v)
				end
			elseif string.match(_i,"b%a+") then
				if tonumber(_v) == 0 then
					tmpTb[_i] = false
				else
					tmpTb[_i] = true
				end
			else
				tmpTb[_i] = _v
			end 
		end
	end
	if tmpTb.bCommonSkill ==  true then
		tmpTb.demageData = tmpTb.szTargetAffect
	end
	skillTable[tmpTb.id] = tmpTb
end


--print("skillTable",skillTable)
return skillTable
