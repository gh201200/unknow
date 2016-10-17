local demageAffect = require "skill.Affects.demageAffect"
local recoverAffect = require "skill.Affects.recoverAffect"
local dizzyAffect = require "skill.Affects.dizzyAffect"
local blinkAffect = require "skill.Affects.blinkAffect"
local invincibleAffect = require "skill.Affects.invincibleAffect"
local outskillAffect = require "skill.Affects.outskillAffect"
local changeModAffect = require "skill.Affects.changeModAffect"
local statsAffect = require "skill.Affects.statsAffect"
local getnewAffect =  require "skill.Affects.getnewAffect"
local flyAffect = require "skill.Affects.flyAffect"
local repelAffect = require "skill.Affects.repelAffect"
local loveAffect = require "skill.Affects.loveAffect"
local getbloodAffect = require "skill.Affects.getbloodAffect"
local chargeAffect = require "skill.Affects.chargeAffect"
local electricAffect  = require "skill.Affects.electricAffect"
local AffectTable = class("AffectTable")

function AffectTable:ctor(entity)
	self.owner = entity
	self.affects = {}
	self.affectStates = 0
	self.AtkAffects = {}
	self.bAtkAffects = {}
end

function AffectTable:update(dt)
	self.affectStates = 0
	for i=#self.affects,1,-1 do
		if self.affects[i].status == "exec" then
			self.affects[i]:onExec(dt)
		elseif self.affects[i].status == "enter" then
			--self.affects[i].status = "exec"
			self.affects[i]:onEnter()			
		elseif self.affects[i].status == "exit" then
			table.remove(self.affects,i)
		end
	end
	for i=#self.AtkAffects,1,-1 do
		self.AtkAffects[i].lifeTime = self.AtkAffects[i].lifeTime - dt
		if self.AtkAffects[i].lifeTime < 0 then
			table.remove(self.AtkAffects,i)
		end
	end
	
	for i = #self.bAtkAffects,1,-1 do
		self.bAtkAffects[i].lifeTime = self.bAtkAffects[i].lifeTime - dt
		if self.bAtkAffects[i].lifeTime < 0 then
			table.remove(self,bAtkAffects,i)
		end
	end
end
--触发普攻攻击和被攻击效果
function AffectTable:triggerAtkAffects(tgt,bAtk)
	local affs = nil
	if bAtk == true then
	--触发被攻击效果
		affs = self.bAtkAffects
	else
		affs = self.AtkAffects
	end
	for i = #affs,1,-1 do
		local rdm = math.random_ext(1,100)
		if affs[i].rate >= rdm then
			tgt.affectTable:buildAffects(self.owner,affs[i].affdata)	
		end 
	end
end

function AffectTable:addAffect(source,data)
	--print("addAffect",data)
	local aff = nil
	if data[1] == "ap" or data[1] == "str" or data[1] == "dex" or data[1] == "inte" then
		aff = demageAffect.new(self.owner,source,data)
	elseif data[1] == "curehp" or data[1] == "curemp" then
		aff = recoverAffect.new(self.owner,source,data)
	elseif data[1] == "dizzy" then
		aff = dizzyAffect.new(self.owner,source,data)
	elseif data[1] == "blink" then
		aff = blinkAffect.new(self.owner,source,data)
	elseif data[1] == "invincible" then
		aff = invincibleAffect.new(self.owner,source,data)
	elseif data[1] == "outskill" then
		aff = outskillAffect.new(self.owner,source,data)
	elseif data[1] == "noskill" then
		aff = noskillAffect.new(self.owner,source,data)
	elseif data[1] == "fly" then
		aff = flyAffect.new(self.owner,source,data)
	elseif data[1] == "repel" then
		aff = repelAffect.new(self.owner,source,data)
	elseif data[1] == "charge" then
		aff = chargeAffect.new(self.owner,source,data)
	elseif data[1] == "love" then
		aff = loveAffect.new(self.owner,source,data)
	elseif data[1] == "getblood" then
		aff = getbloodAffect.new(self.owner,source,data)
	elseif data[1] == "changeMod" then
		aff = changeModAffect.new(self.owner,source,data)
	elseif data[1] == "electric" then
		aff = electricAffect.new(self.owner,source,data)
	elseif data[1] == "ctrl" or data[1] == "up_str" or data[1] == "up_dex" or data[1] == "up_inte" or data[1] == "hp" or data[1] == "mp"  or 
	       data[1] == "atk" or data[1] == "def" or data[1] == "wsp" or data[1] == "mov" or data[1] == "rng" or 
	       data[1] == "re_hp" or data[1] == "re_mp" or data[1] == "crit_rate" or data[1] == "hit_rate" or data[1] == "dod_rate" then
		aff = statsAffect.new(self.owner,source,data)
	elseif data[1] == "getnew" then
		aff = getnewAffect.new(self.owner,source,data)  
	end
	if aff ~= nil then 
		if data[1] == "dizzy" or data[1] == "invincible" or data[1] == "repel" then
			--特殊效果 覆盖
			for i=#self.affects,1,-1 do
				if self.affects[i].data[1] == data[1] then
					self.affects[i]:onExit()
					table.remove(self.affects,i)
				end
			end
		end
		table.insert(self.affects,aff)
	end
end

function AffectTable:addAffectSyn(aff)
	table.insert(self.affects,aff)
	self.owner:advanceEventStamp(EventStampType.Affect)
end

function AffectTable:buildAffects(source,dataStr)
	local tb = {}
	--print("affectTable dataStr",dataStr)
	for v in string.gmatch(dataStr,"%[(.-)%]") do
		local data = {}
		for tp,vals in string.gmatch(v,"(%a+)%:(.+)") do
			vals = vals .. "," 
			table.insert(data,tp)
			local valtb = string.split(vals,",")
			for _,val in pairs(valtb) do
				if val ~= "" then
					table.insert(data,tonumber(val))
				end
			end 
		end
		self:addAffect(source,data) 
	end
	self.owner:advanceEventStamp(EventStampType.Affect)		
end


return AffectTable

