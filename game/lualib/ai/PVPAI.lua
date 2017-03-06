local AIBase = require "ai.AIBase"
local vector3 = require "vector3"
local Map = require "map.Map"
local DropManager = require "drop.DropManager"
local TowerHpR = 1 		--回血范围
local TownerProtectR = 2 	--保护塔的范围
local hateR = 2 		--仇恨范围(自动攻击的范围)
local assistR = 3       	 --援助范围
local run_RateA = 10	 	--逃跑系数A
local run_RateB = 10	 	--逃跑系数B

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
local stateLevel = {}
stateLevel["runAway"] = 6
stateLevel["protect"] = 5
stateLevel["assist"] = 4
stateLevel["getskill"] = 3
stateLevel["farm"] = 2
stateLevel["battle"] = 1
stateLevel["Idle"] = 0

function PVPAI:ctor(entity)
	PVPAI.super.ctor(self,entity)
	self.Fsms["Idle"] = {["onEnter"] = self.onEnter_Idle, ["onExec"] = self.onExec_Idle,["onExit"] = self.onExit_Idle}
	self.Fsms["runAway"] = {["onEnter"] = self.onEnter_runAway, ["onExec"] = self.onExec_runAway,["onExit"] = self.onExit_runAway}
	self.Fsms["protect"] = {["onEnter"] = self.onEnter_protect, ["onExec"] = self.onExec_protect,["onExit"] = self.onExit_protect}
	self.Fsms["assist"] = {["onEnter"] = self.onEnter_assist, ["onExec"] = self.onExec_assist,["onExit"] = self.onExit_assist}
	self.Fsms["getskill"] = {["onEnter"] = self.onEnter_getskill, ["onExec"] = self.onExec_getskill,["onExit"] = self.onExit_getskill}
	self.Fsms["farm"] = {["onEnter"] = self.onEnter_farm, ["onExec"] = self.onExec_farm,["onExit"] = self.onExit_farm}
	self.Fsms["battle"] = {["onEnter"] = self.onEnter_battle, ["onExec"] = self.onExec_battle,["onExit"] = self.onExit_battle}
	self.mNextAIState = "Idle"
	self.mCurrentAIState = "Idle"
	self.mCurrFsm = self.Fsms[self.mCurrentAIState]
	self.mCurrFsm["onEnter"](self)
	self.blueTower = getTower(entity,false) 	--我方基地
	self.redTower = getTower(entity,true)	--敌方基地
	self.assister = nil
end

function PVPAI:reset()
	self:setNextAiState("Idle")
	self.source:setTarget(nil)
end
function PVPAI:update(dt)
	PVPAI.super.update(self,dt)
	--print("PVPAI update self.source=",self.source.serverId,self.mCurrentAIState)
	if self:isRunAway() then
		if  self.mCurrentAIState ~= "runAway" then
			self:setNextAiState("runAway") --逃跑状态
		end
	elseif self:isProtect() == true then 
		if self.mCurrentAIState ~= "protect" and  stateLevel["protect"] > stateLevel[self.mCurrentAIState] then
			self:setNextAiState("protect")
		end
	elseif self:isAssist() == true then
		if self.mCurrentAIState ~= "assist" and stateLevel["assist"] > stateLevel[self.mCurrentAIState] then
			self:setNextAiState("assist")
		end
	elseif self:isGetSkill() == true then
		if self.mCurrentAIState ~= "getskill" and stateLevel["getskill"] > stateLevel[self.mCurrentAIState] then
			self:setNextAiState("getskill")
		end
	elseif self:isFarm() == true then 
		if self.mCurrentAIState ~= "farm" and stateLevel["farm"] > stateLevel[self.mCurrentAIState] then
			self:setNextAiState("farm")
		end
	else 
		if self:isFarm() == false then 
			if self.mCurrentAIState ~= "battle" and stateLevel["battle"] > stateLevel[self.mCurrentAIState]  then
				self:setNextAiState("battle")
			end
		end
	end
	--判断是否有技能可以学习
	for k,v in pairs(self.source.pickItems) do
		local skillNum = 0
		for sk,sv in pairs(self.source.skillTable) do
			skillNum = skillNum + 1
		end
		if skillNum < 6 then
			--学习技能
		--	print("====ai study skill",self.source.serverId)
			
		end
	end	
end
function PVPAI:onEnter_Idle()
	print("AIState:",self.mCurrentAIState,self.source.serverId)	
	self.source:stand()
	--self.blueTower = getTower(self.source,false) 	--我方基地
	--self.redTower = getTower(self.source,true)	--敌方基地
	self.source:setTarget(nil)
end


function PVPAI:onExec_Idle()
end

function PVPAI:onExit_Idle()
	print("onExit_Idle")
end

function PVPAI:onEnter_runAway()
	print("AIState:",self.mCurrentAIState,self.source.serverId)	
	if self.source:getDistance(self.blueTower) >= TowerHpR then 
		self.source:setTarget(self.blueTower)
	end
end


function PVPAI:onExec_runAway()
	if self.source:getDistance(self.blueTower) > TowerHpR then
		self:setNextAiState("runAway")
		return
	end
	self:autoProtectAttack(TowerHpR)	
	local HpPre = self.source:getHp() / self.source:getHpMax() * 100
	if HpPre >= 100 then
		print("=========1111")
		self:setNextAiState("Idle")
	end	
end

function PVPAI:onExit_runAway()
	print("onExit_runAway")
end

function PVPAI:onEnter_protect()
	print("AIState:",self.mCurrentAIState,self.source.serverId)	
--	self:backToHome()	
	self.source:setTarget(self.blueTower)
end


function PVPAI:onExec_protect()
	if self.source:getDistance(self.blueTower) < TownerProtectR then
		self:autoProtectAttack(TownerProtectR)
	end
end

function PVPAI:onExit_protect()

end

function PVPAI:onEnter_battle()
	print("AIState:",self.mCurrentAIState,self.source.serverId)	
	self.source:stand()
end

function PVPAI:onExec_battle()
	local target = self.source:getTarget()
	if target ~= nil and self:canAttackPlayer(target) and self.source:getDistance(target) < hateR then
		return
	end
	target = nil
	for k,v in pairs(g_entityManager.entityList) do
		--if self.source:isKind(v,true) == false and v:getType() == "IMapPlayer" then
		if self:canAttackPlayer(v) then
			if self.source:getDistance(v) < hateR then
				target = v
				break
			end
		end
	end
	if target == nil then
		target = self.redTower
	end
	self.source:aiCastSkill(target)
end

function PVPAI:onExit_battle()
	print("PVPAI:onExit_Battle")
end
function PVPAI:onEnter_getskill()
	print("AIState:",self.mCurrentAIState,self.source.serverId)	
end

function PVPAI:onExec_getskill()
	local dis,point = DropManager:getNearestDrop(self.source)
	if dis < 5 then
		self.source:setTargetPos(point)	
	else
		self:setNextAiState("Idle")	
	end	
end

function PVPAI:onExit_getskill()

end

function PVPAI:onEnter_farm()
	print("AIState:",self.mCurrentAIState,self.source.serverId)	
end

function PVPAI:onExec_farm()
	local target =  self.source:getTarget()
	if target ~= nil and target:getType() ~= "transform" and self.source:getDistance(target) < hateR and target:getHp() > 0 then
	--	print("onExec_farm",self.source.serverId,target.serverId)	
		return 
	end
	target = nil 
	local att = 0 
	if self.source:isRed() then
		att = 1 
	end
	for k,v in pairs(g_entityManager.entityList) do
		if v:getType() == "IMonster" and v:getHp() > 0 and  (v.attach == att or v.attach == 2) then
			if self.source:getDistance(v) <= hateR then
				target = v
				break
			else	
				if v.attach == att then	
					target = v
				elseif v.attach == 2 and target == nil then
					target = v
				end
			end
		end
	end
	if target ~= nil then
		self.source:aiCastSkill(target)
	else
		self:setNextAiState("Idle")	
	end	
end

function PVPAI:onExit_farm()
	
end
--援助
function PVPAI:onEnter_assist()
	print("PVPAI:onEnter_assist")
	self.assister = self:getAssister()
end

function PVPAI:onExec_assist()
	if self.assister == nil then
		self:setNextAiState("Idle")
		return
	end
	local num = 0
	local targets = {}
	for k,v in pairs(g_entityManager.entityList) do
		if self:canAttackPlayer(v) then
			if self.assister:getDistance(v) <=  assistR then
				num = num + 1 
				targets[num] = v
				--target = v	
			end
		end
	end
	if #targets == 0 then
		self.assister = nil 
		self:setNextAiState("Idle")
		return
	else
		local target =  self.source:getTarget()
		local hit = false
		for k,v in pairs(targets) do
			--if target ~= nil and target:getType() == "IMapPlayer" and  target:getHp() > 0  and v.serverId == target.serverId then
			if self:canAttackPlayer(target) and  v.serverId == target.serverId then
				hit = true
				break	
			end
		end
		if hit == false then
			self.source:aiCastSkill(targets[1])
		end
	end
end

function PVPAI:onExit_assist()
	
end

--回家
function PVPAI:backToHome()
	local tpos = self.blueTower.pos 
	local pos = vector3.create(tpos.x,0,tpos.z)
	local rs = {[1] = {x=2,z=0},[2] ={x=-2,z=0},[3] = {x=0,z=2},[4] ={x = 0,z= -2} }
	local i = math.random(1,4)
	pos.x = pos.x + rs[i].x 
	pos.z = pos.y + rs[i].z
	self.source:setTargetPos(pos)
end

--自动保卫攻击
function PVPAI:autoProtectAttack(protectR)
	--local protectR = 3 --保卫半径
	if self.source:getDistance(self.blueTower) > protectR then
		self.source:setTarget(self.blueTower)
		return
	end
	local target = self.source:getTarget()
	--if target and target:getType() == "IMapPlayer" then
	if self:canAttackPlayer(target) then
		if self.source:getDistance(target) < protectR then
			return 
		end
	end
	target = nil
	for k,v in pairs(g_entityManager.entityList) do
		--if self.source:isKind(v,true) == false and v:getType() == "IMapPlayer" then
		if self:canAttackPlayer(v) then
			if self.source:getDistance(v) < protectR then
				target = v
				break
			end
		end
	end
	if target ~= nil then
		self.source:setTarget(target)
	--else
	--	self:setNextAiState("Idle")	
	end
end

--逃生
function PVPAI:isRunAway()
	local HpPre = self.source:getHp() / self.source:getHpMax() * 100
	local enemyNum = 0
	local monsterNum = 0
	local run_SearchDis = 3 
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
			if self.blueTower:getDistance(v) <= TownerProtectR then
				if self.source:isKind(v,true) == false then
					enemyNum = enemyNum + 1
				else
					friendNum = friendNum + 1
				end
			end
		end
	end
	if enemyNum > friendNum then
		--print("isProtect true",enemyNum,friendNum)
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
		if v:getType() == "IMapPlayer" or v:getType() == "IPet" and self.source:isKind(v,true) == true then
			if v.hater ~= nil then
				--hateTime = v.hateTime
				target = v
			end
		end
	end
	return target
end

function PVPAI:isAssist()
	if self.assister ~= nil then
		return true
	end
	local assister = self:getAssister()
	if assister ~= nil then return true end
	return false
end

function PVPAI:isGetSkill()
	local dis,vector = DropManager:getNearestDrop(self.source)
	if dis < 5 then
		return true
	else
		return false	
	end	
end
--打野
function PVPAI:isFarm()
	local att = 0 
	if self.source:isRed() then
		att = 1
	end
	for k,v in pairs(g_entityManager.entityList) do
		if v:getType() == "IMapPlayer" or v:getType() == "IPet" and self.source:isKind(v,true) == true then
			if v.hater ~= nil then
				return false
			end
		end 
	end

	for k,v in pairs(g_entityManager.entityList) do
		if v:getType() == "IMonster" and v.attach == 2 or v.attach == att then
			return true		
		end
	end
	return false
end
--攻击
function PVPAI:isAttack()
	
end

function PVPAI:canAttackPlayer(v)
	if self.source:isKind(v,true) == false and (v:getType() == "IMapPlayer" or v:getType() == "IPet") and v:getHp() > 0 then 
		return true
	else
		return false
	end
end
return PVPAI

