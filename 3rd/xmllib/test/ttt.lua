package.path  = './?.lua;'..package.path
package.cpath = './?.so;' ..package.cpath

local lub    = require 'lub'
local lut    = require 'lut'
local xml    = require 'xml'
print(os.clock())
local data = xml.loadpath(lub.path('|./SkillDatas.xml'))
local t = {}
lub.search(data, function(node)
    --print("------------------")
    if node.xml == "item" then
    	--print("---------begin-------")
    	--print(node.id)
	t[node.id] = {}
	for _k,_v in pairs(node) do
	--	print("=================")
		if _v.xml ~= nil then
			t[node.id][_v.xml] = xml.find(_v,_v.xml)[1]
		end
		--print(_v.xml)
		--print(xml.find(_v,_v.xml)[1])	
	end
	--print("--------end-------")
	--table.insert(t,xml.find(node,"n32SeriId")[1])
    end
--[[
    if node.xml == 'MedlineCitation' and node.Status == 'In-Process' then
      table.insert(t, xml.find(node, 'PMID')[1])
    end
]]
end)
print(os.clock())
--[[
for _k,_v in pairs(t) do
	print("=======" .. _k .."=========")
	for k,v in pairs(_v) do
		print(k,v)
	end
end
]]--
