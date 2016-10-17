local skynet = require "skynet"
local Ientity = require "entity.Ientity"
local vector3 = require "vector3"
local Quest = require "quest.quest"
local EntityManager = require "entity.EntityManager"

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
	register_class_var(self, 'LoadProgress', 0)

	register_class_var(self, 'RaiseTime', 0)
	
	register_class_var(self, 'Gold', 0, self.onGold)
	register_class_var(self, 'Exp', 0, self.onExp)
	
	register_class_var(self, 'GodSkill', 0, self.onGodSkill)
	register_class_var(self, 'CommonSkill', 0, self.onCommonSkill)

	self.GoldExpMask = false
end

function IMapPlayer:getType()
	return "IMapPlayer"
end

function IMapPlayer:isRed()
	return self.color < 4
end

function IMapPlayer:update(dt)
	
	if self:getRaiseTime() > 0 then
		self:setRaiseTime( self:getRaiseTime() - dt )
		if self:getRaiseTime() <= 0 then
			self:onRaise()
		end
	end	

	if self.GoldExpMask then
		local msg = { gold = self:getGold(), exp = self:getExp(), level = self:getLevel()}
		skynet.call(self.agent, "lua", "sendRequest", "addGoldExp", msg)
		self.GoldExpMask = false
	end	
	--add code before this
	IMapPlayer.super.update(self,dt)
end


function IMapPlayer:init(heroId)
	self.attDat = g_shareData.heroRepository[heroId]
	self:setGodSkill( self.attDat.n32GodSkillId )
	self:setCommonSkill( self.attDat.n32CommonSkillId )
	self.skillTable[self.attDat.n32GodSkillId] = 1
	self.skillTable[self.attDat.n32CommonSkillId] = 1
	self.modelDat = g_shareData.heroModelRepository[self.attDat.n32ModelId]
	self:setPos(self.bornPos.x, 0, self.bornPos.z)
	self:calcStats()
	self:setHp(self:getHpMax())
	self:setMp(self:getMpMax())
	self.HpMpChange = true
	self.StatsChange = true
	self:dumpStats()
end

function IMapPlayer:calcStats()
	self:calcStrength()
	self:calcZhili()
	self:calcMinjie()
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

	print(self.attDat)
	print('+++++++++++++++++++')
	print(g_shareData.lzmRepository)
end

function IMapPlayer:onDead()
	IMapPlayer.super.onDead(self)
	print('IMapPlayer:onDead')
	
	self:setRaiseTime(self:getLevel() * Quest.RaiseTime)
end

function IMapPlayer:onRaise()
	IMapPlayer.super.onRaise(self)
	print('IMapPlayer:onRaise')
	
	self:setPos(self.bornPos.x, self.bornPos.y, self.bornPos.z)
	local msg = { sid = self.serverId }
	EntityManager:sendToAllPlayers("raiseHero" ,msg)
end

function IMapPlayer:onGold()
	self.GoldExpMask = true
end

function IMapPlayer:onExp()
	self.GoldExpMask = true
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

	self:setLevel(lv - 1)
end

function IMapPlayer:addSkill(skillId)
	if self.skillTable[skillId] then
		self.skillTable[skillId] = self.skillTable[skillId] + 1
	else
		self.skillTable[skillId] = 1
	end
	
	local msg = {
		skillId = skillId,
		level = self.skillTable[skillId],
	}
	skynet.call(self.agent, "lua", "sendRequest", "addSkill", msg)
end

function IMapPlayer:castSkill()
	IMapPlayer.super.castSkill(self) 
	self:SynSkillCds()
end

function IMapPlayer:SynSkillCds()
	local msg = self.cooldown:getCdsMsg()	
	skynet.call(self.agent,"lua","sendRequest","makeSkillCds",msg)	
end
	
function IMapPlayer:upgradeSkill(skillId)
	if self.skillTable[skillId] == nil then
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
	self.skillTable[skillId] = self.skillTable[skillId] + 1
	return 0, self.skillTable[skillId]
end

return IMapPlayer

