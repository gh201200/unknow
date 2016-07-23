local demageAffect = require "skill.Affects.demageAffect"
local AffectTable = class("AffectTable")

function AffectTable:ctor(entity)
	self.owner = entity
	self.affects = {}
end

function AffectTable:update(dt)
	for i=#self.affects,1,-1 do
		if self.affects[i].status == "exec" then
			self.affects[i]:onExec()
		elseif self.affects[i].status == "enter" then
			self.affects[i].status = "exec"
			self.affects[i]:onEnter()			
		elseif self.affects[i].status == "exit" then
			table.remove(self.affects,i)
		end
	end
end

function AffectTable:addAffect(source,data)
	local aff = nil
	if data[1] == "ap" or data[1] == "str" or data[1] == "dex" or data[1] == "inte" then
		aff = demageAffect.new(self.owner,source,data)
	end
	if aff ~= nil then table.insert(self.affects,aff) end
end

function AffectTable:buildAffects(source,dataStr)
	local tb = {}
	for v in string.gmatch(dataStr,"%[(.-)%]") do
		local data = {}
		for tp,vals in string.gmatch(v,"(%a+)%:(.+)") do
			vals = vals .. "," 
			table.insert(data,tp)
			for val in string.gmatch(vals,"(%d+)%,") do
				table.insert(data,val)
			end 
		end
		self:addAffect(source,data) 
	end	
end


return AffectTable

