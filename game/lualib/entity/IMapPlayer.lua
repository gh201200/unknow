local skynet = require "skynet"
local Ientity = require "entity.Ientity"
local vector3 = require "vector3"
local EntityManager = require "entity.EntityManager"
local BattleOverManager = require "entity.BattleOverManager"
local passtiveSpell =  require "skill.passtiveSpell"
local PVPAI = require "ai.PVPAI" 
local Map = require "map.Map"
local IMapPlayer = class("IMapPlayer", Ientity)
local syslog = require "syslog"

function IMapPlayer.create(arg)
	local player = IMapPlayer.new()
	player.serverId = assin_server_id() 
	player.account_id = arg.account
	player.agent = arg.agent
	player.nickName = arg.nickname
	player.color = arg.color 	--红方 蓝方 1 2 3 和 4 5 6表示 以及出生位置
	player.bornPos:set(arg.bornPos[1]/GAMEPLAY_PERCENT, 0, arg.bornPos[2]/GAMEPLAY_PERCENT)
	if player:isRed() then
		player.camp = CampType.RED
		player.dir:set(0,0,1)
	else
		player.camp = CampType.BLUE
		player.dir:set(0,0,-1)
	end
	player.isAI = arg.isAI
	player:init(arg.pickedheroid)
	player.accountLevel = arg.level
	player.accountExp = arg.eloValue
	player.bindSkills = skynet.call(player.agent, "lua", "getBindSkills", arg.pickedheroid)
	return player
end	

function IMapPlayer:ctor()
	IMapPlayer.super.ctor(self)

	self.account_id = ''		--same with user.account.account_id
	self.entityType = EntityType.player
	self.agent = 0
	self.nickName = ''
	self.color = 0
	self.camp = 0
	self.pets = {}
	self.isAI = false
	self.ai = nil
	self.useAutoAttack = true
	self.hater = nil
	self.hateTime = 0 
	self.HonorData = {0,0,0,0,0,0,0} -- 输出伤害 承受伤害 助攻数 击杀数量 死亡数量
	self.bAttackPlayers = {} --被攻击的玩家
	self.accountLevel = 0
	register_class_var(self, 'LoadProgress', 0)
	register_class_var(self, 'RaiseTime', 0)
	
	register_class_var(self, 'GodSkill', 0, self.onGodSkill)
	register_class_var(self, 'CommonSkill', 0, self.onCommonSkill)

	register_class_var(self, 'ReplaceSkillTimes', 0)
	
	register_class_var(self, 'OffLineTime', 0)
	
	self.bindSkills = nil
	self.pickItems = {}
	
	self.GoldExpMask = false
end


function IMapPlayer:addHp(_hp, mask, source)
	if self:getHp() <= 0 and _hp <= 0 then return end
	IMapPlayer.super.addHp(self,_hp,mask,source)
	if _hp < 0 and source then
		if source:getType() == "IMapPlayer" or source:getType() == "IBuilding"  or source:getType() == "IPet" then
			self.hater = source
			self.hateTime = 2000 --2秒cd
		end
	end
	if self:getHp() <= 0 then
		self.HonorData[5] = self.HonorData[5] + 1
		if source ~= nil and source:getType() == "IMapPlayer" then
			source.HonorData[4] = source.HonorData[4] + 1
			if source:isRed() then
				BattleOverManager.RedKillNum = BattleOverManager.RedKillNum + 1
			else
				BattleOverManager.BlueKillNum = BattleOverManager.BlueKillNum + 1
			end
		end
	end
end
function IMapPlayer:getType()
	return "IMapPlayer"
end

function IMapPlayer:isRed()
	return self.color < 4
end

function IMapPlayer:isSameCamp( v )
	return (self.color < 4 and v.color < 4) or (self.color > 3 and v.color > 3)
end

function IMapPlayer:update(dt)
	if self:isDead() == false then
		if self.ai then
			if self.curActionState < ActionState.forcemove then
			--	self.ai:update(dt)
			end
		else
			if self.useAutoAttack == true then
				self:autoAttack()		
			end	
		end
	end
	self.hateTime =  self.hateTime - dt	
	if self.hateTime <= 0 then
		self.hater = nil
	end
	if self:getRaiseTime() > 0 then
		self:setRaiseTime( self:getRaiseTime() - dt )
		if self:getRaiseTime() <= 0 then
			self:onRaise()
		end
	end	
--[[
	if self.GoldExpMask then
		local msg = { gold = self:getGold(), exp = self:getExp(), level = self:getLevel(), sid = self.serverId}
		EntityManager:sendToAllPlayers("addGoldExp", msg)
		self.GoldExpMask = false
	end	
--]]
	--add code before this
	IMapPlayer.super.update(self,dt)
end


function IMapPlayer:init(heroId)
	if self.isAI == true then
		self.ai = PVPAI.new(self)
	end
	self.attDat = g_shareData.heroRepository[heroId]
	if not self.attDat then
		syslog.err("IMapPlayer:init: attDat is nil "..heroId)
	end
	self:setGodSkill( self.attDat.n32GodSkillId)
	self:setCommonSkill( self.attDat.n32CommonSkillId )
	self.skillTable[self.attDat.n32GodSkillId] = 0 	--无限次数
	--self.skillTable[self.attDat.n32CommonSkillId] = -1  	--无限次数

	self.modelDat = g_shareData.heroModelRepository[self.attDat.n32ModelId]
	self:calcStats()
	self:setHp(self:getHpMax())
	self:setMp(self:getMpMax())
	self.HpMpChange = true
	self.StatsChange = true
	self:setPos(self.bornPos.x, 0, self.bornPos.z)
	--self:dumpStats()

	IMapPlayer.super.init(self)
end

function IMapPlayer:setTarget(target) 
	--if target == self:getTarget() and self.curActionState == ActionState.move then return end
	if target == self:getTarget() then return end
	IMapPlayer.super.setTarget(self,target)
end

function IMapPlayer:calcStats()
	self:calcStrength()
	self:calcIntelligence()
	self:calcAgility()
	self:calcHpMax()
	self:calcMpMax()
	self:calcAttack()
	self:calcDefence()
	self:calcASpeed()
	self:calcMSpeed()
	self:calcRecvHp()
	self:calcRecvMp()
	self:calcAttackRange()
	self:calcBaoji()
	self:calcHit()
	self:calcMiss()
	self:calUpdamage()
	self:calShield()	

	--print(self.nickName .. ' 计算属性')
	--self:dumpStats()

end

function IMapPlayer:onDead()
	IMapPlayer.super.onDead(self)
	print('IMapPlayer:onDead')
	for _k,_v in pairs(self.bAttackPlayers) do
		_v.HonorData[3] = _v.HonorData[3] + 1	
	end
	self.bAttackPlayers = {}
	self:setRaiseTime(self:getLevel() * Quest.RaiseTime)
	if self:isRed() then
		BattleOverManager.BlueKillNum = BattleOverManager.BlueKillNum + 1
	else
		BattleOverManager.RedKillNum = BattleOverManager.RedKillNum + 1
	end
	if self.hater and (self.hater:getType() == "IMapPlayer" or  self.hater:getType() == "IBuilding") then
		for k,v in pairs(EntityManager.entityList) do
			if v.entityType == EntityType.player then
				if v:isKind( self ) == false then
					local exp = g_shareData.heroLevel[self:getLevel()]
					v:addExp( math.floor(exp["n32Reward"]))
				end
			end
		end
	end
	Map:add(self.pos.x, self.pos.z, 0, self.modelDat.n32BSize)
	local msg = {blueDeadNum = BattleOverManager.RedKillNum,redDeadNum = BattleOverManager.BlueKillNum }
	EntityManager:sendToAllPlayers("onPlayerDead" ,msg)
end

function IMapPlayer:onRaise()
	IMapPlayer.super.onRaise(self)
	print('IMapPlayer:onRaise',self.serverId)
	if self.ai then
		self.ai:reset()
	end
	self:setPos(self.bornPos.x, self.bornPos.y, self.bornPos.z)
	local msg = { sid = self.serverId }
	EntityManager:sendToAllPlayers("raiseHero" ,msg)
	
	Map:add(self.pos.x, self.pos.z, 1, self.modelDat.n32BSize)
end

function IMapPlayer:onGold()
	self.StatsChange = true
	--self.GoldExpMask = true
end

function IMapPlayer:onExp()
	self.StatsChange = true
	--self.GoldExpMask = true
	local lv = 0
	local sz = #g_shareData.heroLevel
	for i=2, sz do
		if self:getExp() < g_shareData.heroLevel[i].n32Exp then
			lv = i 
			break
		end
	end
	if lv == 0 then
		lv = sz + 1
	end
	local oldLv = self:getLevel()
	self:setLevel(lv - 1)

	if oldLv ~= self:getLevel() then
		self:calcStats()
	end
end


function IMapPlayer:castSkill()
	if self:getHp() >= 0 then
		IMapPlayer.super.castSkill(self)
	end
end

function IMapPlayer:SynSkillCds(id)
	local msg = self.cooldown:getCdsMsg(id)
	skynet.call(self.agent,"lua","sendRequest","makeSkillCds",msg)	
end

function IMapPlayer:aiCastSkill(target)
	if target:getHp() <= 0 then 
		self:setTarget(nil) 
		return 
	end
	local skills = {}
	for skillId,level in pairs(self.skillTable) do
		local skilldata = g_shareData.skillRepository[skillId + level - 1] 
		if skilldata and skilldata.n32Active == 0 and skilldata.n32SelectTargetType == 3 and skilldata.n32SkillType ~= 0 then
				if self:canSetCastSkill(skilldata.id) == 0 then
					table.insert(skills,skilldata.id)
				end
			end
		end						
	local skillId = self:getCommonSkill() 
	if #skills ~= 0 then
		local index = math.random(1,#skills)
		skillId = skills[index]
	end
	self:setReadySkillId(skillId) 
	self:setTarget(target)
end

--释放方向或者地点技能
function IMapPlayer:castPosDirSkill()
	local skilldata = g_shareData.skillRepository[self:getReadySkillId()]
	if skilldata then
		--方向或者地点技能
		if skilldata.n32SkillTargetType == 4 or skilldata.n32SkillTargetType == 5 then
				
		end
	end
end

function IMapPlayer:setCastSkillId(id)
	local skilldata = g_shareData.skillRepository[id]
	if skilldata.n32SkillType == 1 then	
		if self.skillTable[id] == nil or self.skillTable[id] <= 0 then
			return ErrorCode.EC_Spell_NumLow	
		end
	end
	return IMapPlayer.super.setCastSkillId(self,id) 	
end

function IMapPlayer:castSkill(id)
	local skilldata = g_shareData.skillRepository[id]
	if skilldata.n32SkillType == 1 then	
		self.skillTable[id] = self.skillTable[id] - 1
		local msg = {
			skillId = id,
			level = self.skillTable[id] 
		}
		skynet.call(self.agent, "lua", "sendRequest", "addSkill", msg)
	end
	IMapPlayer.super.castSkill(self,id)
end
function IMapPlayer:replaceSkill(id)
	local skilldata = g_shareData.skillRepository[id]
	local nSkillId = 0
	local num = 0
	if skilldata.n32SkillType == 1 and  self.skillTable[id] ~= nil then
		num = self.skillTable[id] - 1
		local randSkills = {}
		for k,bSkillId in pairs(self.bindSkills) do
			local bexit = false
			for eSkillId,v in pairs(self.skillTable) do
				if v~= nil and v >=0 and eSkillId == bSkillId then
					bexit = true
					break
				end
			end
			if bexit == false then
				table.insert(randSkills,bSkillId)
			end
		end
		self.skillTable[id] = nil 	
		nSkillId = randSkills[math.random(1,#randSkills)]
		--self:addSkill(nSkillId,num,true)	
	end
	return 0,nSkillId,num
end
--获取普攻范围内敌人
function IMapPlayer:autoAttack()
	if self:getReadySkillId() ~= 0 and self:getReadySkillId() ~= self:getCommonSkill() then
		return
	end
	if self:getTarget() ~= nil then 
		self:setReadySkillId(self:getCommonSkill())
		return 
	end
	local target = self:getAttackTarget()
	local newSearch = true 
	if target ~= nil and self:isKind(target) == false and target:getHp() > 0 then
		local disLen = self:getDistance(target)
		if disLen <= 2 then
			newSearch = false
		else
			 self:setAttackTarget(nil)
		end
	end
	if newSearch == true then
		local newTarget = nil
		local hplowest = 9999
		for k,v in pairs(EntityManager.entityList) do 
			if v ~= nil and  self:isKind(v) == false and v:getHp() > 0 then
				local disLen = self:getDistance(v)
				if disLen <= 2 then
					if newTarget == nil then
						newTarget = v
						hplowest = v:getHp()
					else
						if newTarget:getType() ~= "IMapPlayer" and v:getType() == "IMapPlayer" then
							newTarget = v
							hplowest = v:getHp()
						elseif newTarget:getType() == "IMapPlayer" and v:getType() == "IMapPlayer" then
							if v:getHp() < hplowest then
								newTarget = v
								hplowest = v:getHp()
							end
						elseif newTarget:getType() ~= "IMapPlayer" and v:getType() ~= "IMapPlayer" then
							if v:getHp() < hplowest then
								newTarget = v
								hplowest = v:getHp()
							end
						end
					end 
				end
			end
		end
		if newTarget ~= nil then
			if self.spell:isSpellRunning() == false then
				self:setAttackTarget(newTarget)
			end	
		end
	end
	if self:getTarget() == nil then
		local atkTarget = self:getAttackTarget()
		self:setTarget(atkTarget)
		self:setReadySkillId(self:getCommonSkill())
	end
	
	return nil
end

return IMapPlayer

