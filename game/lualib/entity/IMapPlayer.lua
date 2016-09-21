local skynet = require "skynet"
local Ientity = require "entity.Ientity"
local vector3 = require "vector3"


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
	return player
end	

function IMapPlayer:ctor()
	IMapPlayer.super.ctor(self)

	self.account_id = ''		--same with user.account.account_id
	self.entityType = EntityType.player
	self.agent = 0
	self.nickName = ''
	self.color = 0
	
	register_class_var(self, 'LoadProgress', 0)
	
	register_class_var(self, 'Gold', 0, self.onGold)
	register_class_var(self, 'Exp', 0, self.onExp)
	
	self.GoldExpMask = false
end

function IMapPlayer:getType()
	return "IMapPlayer"
end

function IMapPlayer:update(dt)
	
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

end

function IMapPlayer:onDead()
	IMapPlayer.super.onDead(self)
	print('IMapPlayer:onDead')
end

function IMapPlayer:onGold()
	self.GoldExpMask = true
end

function IMapPlayer:onExp()
	self.GoldExpMask = true
	local lv = 1
	for k, v in pairs(g_shareData.heroLevel) do
		if self:getExp() < v.n32Exp then
			lv = k
			break
		end
	end

	self:setLevel(lv)
end


return IMapPlayer

