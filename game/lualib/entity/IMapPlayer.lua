local skynet = require "skynet"
local Ientity = require "entity.Ientity"
local vector3 = require "vector3"
local Quest = require "quest.quest"
local EntityManager = require "entity.EntityManager"
local BattleOverManager = require "entity.BattleOverManager"
local passtiveSpell =  require "skill.passtiveSpell"
local IMapPlayer = class("IMapPlayer", Ientity)

function IMapPlayer.create(arg)

	local player = IMapPlayer.new()
	player.serverId = assin_server_id() 
	player.account_id = arg.account
	player.agent = arg.agent
	player.nickName = arg.nickname
	player.color = arg.color 	--红方 蓝方 1 2 3 和 4 5 6表示 以及出生位置
	player.bornPos:set(arg.bornPos[1]/GAMEPLAY_PERCENT, 0, arg.bornPos[2]/GAMEPLAY_PERCENT)
	player:init(arg.pickedheroid)
	player.accountLevel = getAccountLevel( arg.score )
	if player:isRed() then
		player.camp = CampType.RED
	else
		player.camp = CampType.BLUE
	end
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
	self.HonorData = {0,0,0,0,0,0,0} -- 输出伤害 承受伤害 助攻数 击杀数量 死亡数量
	self.bAttackPlayers = {} --被攻击的玩家
	self.accountLevel = 0
	register_class_var(self, 'LoadProgress', 0)
	register_class_var(self, 'RaiseTime', 0)
	
	
	register_class_var(self, 'GodSkill', 0, self.onGodSkill)
	register_class_var(self, 'CommonSkill', 0, self.onCommonSkill)

	register_class_var(self, 'ReplaceSkillTimes', 0)
	
	register_class_var(self, 'OffLineTime', 0)
	
	self.GoldExpMask = false
end


function IMapPlayer:addHp(_hp, mask, source)
	IMapPlayer.super.addHp(self,_hp,mask,source)
	if self:getHp() <= 0 then
		self.HonorData[5] = self.HonorData[5] + 1
		if source ~= nil and source:getType() == "IMapPlayer" then
			source.HonorData[4] = source.HonorData[4] + 1
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
	return (self.color < 4 and c.color < 4) or (self.color > 3 and self.color > 3)
end

function IMapPlayer:update(dt)
	
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
	self.attDat = g_shareData.heroRepository[heroId]
	self:setGodSkill( self.attDat.n32GodSkillId )
	self:setCommonSkill( self.attDat.n32CommonSkillId )
	self.skillTable[self.attDat.n32GodSkillId] = 0
	self.skillTable[self.attDat.n32CommonSkillId] = 1
	self.modelDat = g_shareData.heroModelRepository[self.attDat.n32ModelId]
	self:setPos(self.bornPos.x, 0, self.bornPos.z)
	self:calcStats()
	self:setHp(self:getHpMax())
	self:setMp(self:getMpMax())
	self.HpMpChange = true
	self.StatsChange = true
	self:dumpStats()

	IMapPlayer.super.init(self)
end

function IMapPlayer:setTarget(target) 
	if target == self:getTarget() then return end
	IMapPlayer.super.setTarget(self,target)
end

function IMapPlayer:getCommonSkillId()
	for _k,_v in pairs(self.skillTable) do
		local id = _k + _v - 1
		local skilldata = g_shareData.skillRepository[id]
		if skilldata and skilldata.bCommonSkill == true then
			return id
		end	
	end
	return 0
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
end

function IMapPlayer:onRaise()
	IMapPlayer.super.onRaise(self)
	print('IMapPlayer:onRaise')
	
	self:setPos(self.bornPos.x, self.bornPos.y, self.bornPos.z)
	local msg = { sid = self.serverId }
	EntityManager:sendToAllPlayers("raiseHero" ,msg)
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

function IMapPlayer:addSkill(skillId, updateToClient)
	
	if self.skillTable[skillId]  == nil then
		self.skillTable[skillId] = 1
	else
		self.skillTable[skillId] = self.skillTable[skillId] + 1
	end
	
	local skilldata = g_shareData.skillRepository[skillId + self.skillTable[skillId] - 1]	
	--被动技能
	if skilldata.n32Active == 1 then	
		--local oldSkillId = skillId + self.skillTable[skillId] - 2
		--移除旧技能带的buff效果
		--self.affectTable:removeBySkillId(oldSkillId)
		self.spell.passtiveSpells[skilldata.n32SeriId] = passtiveSpell.new(self,skilldata)
	end
	
	if updateToClient then
		local msg = {
			skillId = skillId,
			level = self.skillTable[skillId] 
		}
		skynet.call(self.agent, "lua", "sendRequest", "addSkill", msg)
	end
end

function IMapPlayer:removeSkill(skillId)
	--移除旧技能带的buff效果
	self.affectTable:removeBySkillId(skillId)
	
	self.skillTable[skillId] = nil
end

function IMapPlayer:castSkill()
	if self:getHp() >= 0 then
		IMapPlayer.super.castSkill(self)
	end
end

function IMapPlayer:SynSkillCds(id)
	local msg = self.cooldown:getCdsMsg()	
	skynet.call(self.agent,"lua","sendRequest","makeSkillCds",msg)	
end
	
function IMapPlayer:upgradeSkill(skillId)
	if self.skillTable[skillId] == nil or self.skillTable[skillId] == 0 then
		return -1, 0
	end
	if self.skillTable[skillId] == Quest.SkillMaxLevel then
		return -1, 0
	end
	local costGold = Quest.GoldSkillLv[self.skillTable[skillId]]
	if costGold > self:getGold() then
		return -1, 0
	end
	--开始升级
	--扣除金币
	self:addGold(-costGold)
	self:addSkill(skillId, false)
	return 0, self.skillTable[skillId]
end
	
return IMapPlayer

