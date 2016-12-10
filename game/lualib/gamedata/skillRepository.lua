#!/usr/bin/env lua
---Sample application to read a XML file and print it on the terminal.
--@author Manoel Campos da Silva Filho - http://manoelcampos.com
--dofile("../3rd/LuaXMLlib/xml.lua")
--dofile("../3rd/LuaXMLlib/handler.lua")

local lub    = require 'lub.init'
local lut    = require 'lut.init'
local xml    = require 'xml.init'
local data = xml.loadpath(lub.path('|./SkillDatas.xml'))
local t = {}
lub.search(data, function(node)
    --print("------------------")
    if node.xml == "item" then
    	--print("---------begin-------")
    	--print(node.id)
	local id = tonumber(node.id)
	t[id] = {}
	t[id].id = id
	for _k,_v in pairs(node) do
	--	print("=================")
		if _v.xml ~= nil then
			--t[node.id][_v.xml] 
			local v = xml.find(_v,_v.xml)[1]
			if tonumber(v) == nil then
				if  _v.xml == "szSelectRange" or _v.xml == "szAffectRange" or _v.xml == "szAffectTargetAffect" or _v.xml == "szSelectTargetAffect" or _v.xml == "szMyAffect" then
					if v ~= nil then
						t[id][_v.xml] = string.parserskillStr(v)
						if _v.xml == "szSelectRange" or _v.xml == "szAffectRange" then
							t[id][_v.xml] = t[id][_v.xml][1]
						end
					else
						t[id][_v.xml] = ""
					end
				else
					t[id][_v.xml] = v
				end
			else
				t[id][_v.xml] = tonumber(v)
				if _v.xml == "n32CD" then
					t[id][_v.xml] = t[id][_v.xml] * 1000
				end
			end
		end
	end
    end
end)
return t
