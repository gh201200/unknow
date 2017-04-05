local skillAffect = require "skill.Affects.skillAffect"
local blinkAffect = require "skill.Affects.blinkAffect"
local invincibleAffect = require "skill.Affects.invincibleAffect"
local outskillAffect = require "skill.Affects.outskillAffect"
local changeModAffect = require "skill.Affects.changeModAffect"
local statsAffect = require "skill.Affects.statsAffect"
local getnewAffect =  require "skill.Affects.getnewAffect"
local repelAffect = require "skill.Affects.repelAffect"
local loveAffect = require "skill.Affects.loveAffect"
local getbloodAffect = require "skill.Affects.getbloodAffect"
local chargeAffect = require "skill.Affects.chargeAffect"
local showAffect =  require "skill.Affects.showAffect"
local nodeadAffect = require "skill.Affects.nodeadAffect"
local summonAffect =  require "skill.Affects.summonAffect"
local addskillAffect = require "skill.Affects.addskillAffect"
local changeatkAffect = require "skill.Affects.changeatkAffect"
local AffectTable = class("AffectTable")

function AffectTable:ctor(entity)
	self.owner = entity
	self.affects = {}
	self.AtkAffects = {}
	self.bAtkAffects = {} 
end

function AffectTable:update(dt)
--	print("AffectTable:update",self.owner.serverId,self.owner:getHp(),#self.affects)
	for i=#self.affects,1,-1 do
	--	if self.affects[i] ~= nil then
			if self.affects[i].status == "exec" then
				self.affects[i]:onExec(dt)
			elseif self.affects[i].status == "enter" then
				--self.affects[i].status = "exec"
				self.affects[i]:onEnter()			
			elseif self.affects[i].status == "exit" then
				table.remove(self.affects,i)
			end
	--	end
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
function AffectTable:triggerAtkAffects(tgt,bAtk,skilldata)
	local affs = nil
	if bAtk == true then
	--触发被攻击效果
		affs = self.bAtkAffects
	else
		tgt.affectTable:buildAffects(self.owner,skilldata.szTargetAffect,skilldata.id)		
		affs = self.AtkAffects
	end
	if tgt:getType() == "IBuilding"  then
		return 
	end
	for i = #affs,1,-1 do
		local rdm = math.random(1,100)
		if affs[i].rate >= rdm then
			tgt.affectTable:buildAffects(self.owner,affs[i].affdata,affs[i].skillId)	
		end 
	end
	
end

function AffectTable:addAffect(source,data,skillId,extra)
	local aff = nil
	if data[1] == "curehp" or data[1] == "curemp" or data[1] == "damage" or data[1] == "shield" or data[1] == "burnmp" then
		aff = skillAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "blink" then
		aff = blinkAffect.new(self.owner,source,data,skillId,extra)
	elseif data[1] == "invincible" then
		aff = invincibleAffect.new(self.owner,source,data),skillId
	elseif data[1] == "outskill" then
		aff = outskillAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "noskill" then
		aff = noskillAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "repel" then
		aff = repelAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "charge" then
		aff = chargeAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "love" then
		aff = loveAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "getblood" then
		aff = getbloodAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "changeMod" then
		aff = changeModAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "show" then
		aff = showAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "nodead" then
		aff = nodeadAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "ctrl" or data[1] == "upstr" or data[1] == "updex" or data[1] == "upinte" or data[1] == "hp" or data[1] == "mp"  or 
	       data[1] == "atk" or data[1] == "def" or data[1] == "wsp" or data[1] == "mov" or data[1] == "rng" or 
	       data[1] == "rehp" or data[1] == "remp" or data[1] == "critrate" or data[1] == "hitrate" or data[1] == "dodrate" or data[1] == "updamage" then
		aff = statsAffect.new(self.owner,source,data,skillId)
		
	elseif data[1] == "getnew" then
		aff = getnewAffect.new(self.owner,source,data,skillId)  
	elseif data[1] == "summon" then
		aff = summonAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "addskill" then
		aff = addskillAffect.new(self.owner,source,data,skillId) 
	elseif data[1] == "changeatk" then
		aff = changeatkAffect.new(self.owner,source,data,skillId)
	elseif data[1] == "suicide" then
		--移除自己 特殊处理
		source:onDead()
	end
	if not aff then
		print('data = ',data)
		print('skillid = ',skillId)
		return nil
	end
	aff:onEnter()
	return self:replaceAdd(aff)
end

function AffectTable:replaceAdd(aff)
	for i=#self.affects,1,-1 do
		--print("replaceAdd===",self.affects[i].data[1],aff.data[1])
		if self.affects[i].data[1] == aff.data[1] and self.affects[i].source == aff.source then
			if self.affects[i].skillId == aff.skillId and aff.effectTime > 0 then
			--	aff.projectId = self.affects[i].projectId
				self.affects[i]:onExit()
				table.remove(self.affects,i)
			end
		end 
	end
	
	self:synClient(aff)
	table.insert(self.affects,aff)
	return aff.projectId
end

function AffectTable:addAffectSyn(aff)
	--table.insert(self.affects,aff)
	self:replaceAdd(aff)
end

function AffectTable:removeById(id)
	for i=#self.affects,1,-1 do 
		if self.affects[i].projectId == id then
			self:synClient(self.affects[i],1)	
			self.affects[i]:onExit() --清除处理
			table.remove(self.affects,i)
		end
	end
end
function AffectTable:clear()
	for i=#self.affects,1,-1 do
		self.affects[i]:onExit() 
		--table.remove(self.affects,i)
	end
	self.affects = {}
	self.bAtkAffects = {}
	self.AtkAffects = {}
	
end
function AffectTable:removeBySkillId(skillId)
	for i=#self.affects,1,-1 do 
		if self.affects[i].skillId == skillId then
			self:synClient(self.affects[i],1)
			self.affects[i]:onExit()
			table.remove(self.affects,i)
		end
	end
	for i=#self.bAtkAffects,1,-1 do
		if self.bAtkAffects[i].skillId == skillId then
			table.remove(self.bAtkAffects,i)
		end
	end
	for i=#self.AtkAffects,1,-1 do
		if self.AtkAffects[i].skillId == skillId then
			table.remove(self.AtkAffects,i)
		end
	end
end


function AffectTable:buildAffects(source,datas,skillId,extra)
	local projectids = {}
	for _k,_v in pairs(datas) do
		local proId = self:addAffect(source,_v,skillId,extra)
		table.insert(projectids,proId)
	end
	
	return projectids		
end

function AffectTable:synClient(aff,_remove)
	_remove  = _remove or 0
	local srcId = 0
	if aff.source ~= nil   and aff.source.serverId ~= nil then
		srcId = aff.source.serverId
	end
	local r = {acceperId = self.owner.serverId,producerId = srcId,effectId = aff.effectId,effectTime = aff.effectTime,flag = _remove}
	g_entityManager:sendToAllPlayers("pushEffect",r)
end
return AffectTable

