local AIBase = require "ai.AIBase"
local vector3 = require "vector3"
local Map = require "map.Map"
local PROTECT_DIS = 2 -- 保护距离
local hateR = 2 --仇恨范围
require "globalDefine"

local PVPAI = class("PVPAI", AIBase)
local function getTower(entity,isBad)
	for k, v in pairs( g_entityManager.entityList ) do
		if v:getType() == "IBuilding" then
			if isBad == true and entity.camp ~= v.camp then
				return v
			elseif isBad == false and entity.camp == v.camp then
				return v
			end
		end	
	end
	return nil
end
function PVPAI:ctor(entity)
	PVPAI.super.ctor(self,entity)
	self.Fsms["Idle"] = {["onEnter"] = self.onEnter_Idle, ["onExec"] = self.onExec_Idle,["onExit"] = self.onExit_Idle}
	self.Fsms["runAway"] = {["onEnter"] = self.onEnter_runAway, ["onExec"] = self.onExec_runAway,["onExit"] = self.onExit_runAway}
	self.Fsms["protect"] = {["onEnter"] = self.onEnter_protect, ["onExec"] = self.onExec_protect,["onExit"] = self.onExit_protect}
	self.Fsms["assist"] = {["onEnter"] = self.onEnter_assist, ["onExec"] = self.onExec_assist,["onExit"] = self.onExit_assist}
	self.Fsms["farm"] = {["onEnter"] = self.onEnter_farm, ["onExec"] = self.onExec_farm,["onExit"] = self.onExit_farm}
	self.Fsms["battle"] = {["onEnter"] = self.onEnter_battle, ["onExec"] = self.onExec_battle,["onExit"] = self.onExit_battle}
	self.mNextAIState = "Idle"
	self.mCurrentAIState = "Idle"
	self.mCurrFsm = self.Fsms[self.mCurrentAIState]
	self.mCurrFsm["onEnter"](self)
	self.blueTower = getTower(entity,false) 	--我方基地
	self.redTower = getTower(entity,true)	--敌方基地
end

function PVPAI:update(dt)
	PVPAI.super.update(self,dt)
	if self:isRunAway() and self.mCurrentAIState ~= "runAway" then
		self:setNextAiState("runAway") --逃跑状态
	elseif self:isProtect() == true and self.mCurrentAIState ~= "protect" then
		self:setNextAiState("protect")
	elseif self:getAssister() ~= nil and self.mCurrentAIState ~= "assist" then
		self:setNextAiState("assist")
	elseif self:isFarm() == true and self.mCurrentAIState ~= "farm" then
		self:setNextAiState("farm")
	else 
		if self:isFarm() == false and self.mCurrentAIState ~= "battle" then
			self:setNextAiState("battle")
		end
	end
end
function PVPAI:onEnter_Idle()
	print("PVPAI:onEnter_Idle")	
	self.source:stand()
	self.blueTower = getTower(self.source,false) 	--我方基地
	self.redTower = getTower(self.source,true)	--敌方基地
	self.source:setTarget(nil)
end


function PVPAI:onExec_Idle()
end

function PVPAI:onExit_Idle()
	print("onExit_Idle")
end

function PVPAI:onEnter_runAway()
	print("PVPAI:onEnter_runAway")
	self:backToHome()	
end


function PVPAI:onExec_runAway()
--	self:setNextAiState("Chase")
end

function PVPAI:onExit_runAway()
	print("onExit_runAway")
end

function PVPAI:onEnter_protect()
	print("PVPAI:onEnter_protect")	
	self:backToHome()	
end


function PVPAI:onExec_protect()
	self:autoProtectAttack()
end

function PVPAI:onExit_protect()

end

function PVPAI:onEnter_battle()
	print("PVPAI:onEnter_battle")
	self.source:stand()
end

function PVPAI:onExec_battle()
	local AttackR = 2
	local target = self.source:getTarget()
	if target ~= nil and self.source:getDistance(target) < AttackR then
		return
	end
	target = nil
	for k,v in pairs(g_entityManager.entityList) do
		if self.source:isKind(v,true) == false and v:getType() == "IMapPlayer" then
			if self.source:getDistance(v) < AttackR then
				target = v
				break
			end
		end
	end
	if target == nil then
		target = self.redTower
	end
	self.source:setTarget(target)
	self.source.ReadySkillId = self.source:getCommonSkill()
end

function PVPAI:onExit_battle()
	print("PVPAI:onExit_Battle")
end

function PVPAI:onEnter_farm()
	print("PVPAI:onEnter_farm")
end

function PVPAI:onExec_farm()
	local AttackR = 2
	local target = self.source:getTarget()
	if target ~= nil and self.source:getDistance(target) < AttackR then
		return 
	end
	target = nil 
	for k,v in pairs(g_entityManager.entityList) do
		if self.source:isKind(v,true) == false and v:getType() == "IMonster" then
			if self.source:getDistance(v) <= AttackR then
				if target ~= nil then
					if target.attDat.n32Type >= v.attDat.n32Type then
						target = v
					end	
				else
					target = v
				end
			end
		end
	end
	if target ~= nil then
		self.source:setTarget(target)
		self.source.ReadySkillId = self.source:getCommonSkill()
	end

end

function PVPAI:onExit_farm()
	
end
--援助
function PVPAI:onEnter_assist()
	print("PVPAI:onEnter_assist")
	local target = self:getAssister()
	local pos = vector3.create(target.x,0,target.z)
	self.source:setTargetPos(pos)
end

function PVPAI:onExec_assist()
	local target = self:getTarget()
	if target ~= nil and target:getType() == "IMapPlayer" then return end
	for k,v in pairs(g_entityManager.entityList) do
		if self.source:isKind(v,true) == false and v:getType() == "IMapPlayer" then
			if self.source:getDistance(v) <= hateR then
				self.source.ReadySkillId = self.source:getCommonSkill()
				self.source:setTarget(v)	
				return
			end
		end
	end
end

function PVPAI:onExit_assist()
	
end

--回家
function PVPAI:backToHome()
	local towerR = 2	
	local tpos = self.blueTower.pos 
	local pos = vector3.create(tpos.x,0,tpos.z)
	local rs = {[1] = {x=2,z=0},[2] ={x=-2,z=0},[3] = {x=0,z=2},[4] ={x = 0,z= -2} }
	local i = math.random(1,4)
	pos.x = pos.x + rs[i].x 
	pos.z = pos.y + rs[i].z
	self.source:setTargetPos(pos)
end

--自动保卫攻击
function PVPAI:autoProtectAttack()
	local protectR = 3 --保卫半径
	if self.source:getDistance(self.blueTower) > protectR then
		return
	end
	local target = self.source:getTarget()
	if target:getType() == "IMapPlayer" then
		if self.source:getDistance(target) < protectR then
			return 
		end
	end
	target = nil
	for k,v in pairs(g_entityManager.entityList) do
		if self.source:isKind(v,true) == false and v:getType() == "IMapPlayer" then
			if self.source:getDistance(v) < protectR then
				target = v
				break
			end
		end
	end
	self.source:setTarget(target)
end

--逃生
function PVPAI:isRunAway()
	local HpPre = self.source:getHp() / self.source:getHpMax() * 100
	local enemyNum = 0
	local monsterNum = 0
	local run_RateA = 10
	local run_RateB = 5
	local run_SearchDis = 2
	for k,v in pairs(g_entityManager.entityList) do
		if self.source:isKind(v,true) == false then
			if self.source:getDistance(v) < run_SearchDis then
				if v:getType() == "IMapPlayer" then
					enemyNum = enemyNum + 1	
				elseif v:getType() == "Imonster" then
					monsterNum = monsterNum + 1
				end
			end
		end
	end
	local maxPre = run_RateA * enemyNum + run_RateB * monsterNum
	if HpPre <= maxPre then
		return true
	end	
	return false
end

--回防
function PVPAI:isProtect()
	--一定范围
	local friendNum = 0
	local enemyNum = 0
	for k, v in pairs( g_entityManager.entityList ) do
		if v:getType() == "IMapPlayer" then
			if self.blueTower:getDistance(v) <= PROTECT_DIS then
				if self.source:isKind(v,true) == false then
					enemyNum = enemyNum + 1
				else
					friendNum = friendNum + 1
				end
			end
		end
	end
	if enemyNum > friendNum then
		print("isProtect true",enemyNum,friendNum)
		return true
	end
 	if self.redTower:getDistance(self.source) <= 2 then
		local redHpPre = self.redTower:getHp()  / self.redTower:getHpMax() * 100
		local blueHpPre = self.blueTower:getHp() / self.blueTower:getHpMax() * 100
		if redHpPre > 5 and redHpPre > blueHpPre then
			print("isProtect 2 true",redHpPre,blueHpPre)
			return true
		end
	end
	
	return false	
end
--帮助
function PVPAI:getAssister()
	local target = nil 
	local hateTime = 0 
	for k,v in pairs(g_entityManager.entityList) do
		if v:getType() == "IMapPlayer" then
			if v.hater ~= nil and v.hateTime > hateTime then
				hateTime = v.hateTime
				target = v
			end
		end
	end
	return target
end

--打野
function PVPAI:isFarm()
	for k,v in pairs(g_entityManager.entityList) do
		if v:getType() == "IMonster" then
			return true		
		end
	end
	return false
end
--攻击
function PVPAI:isAttack()
	
end
return PVPAI

