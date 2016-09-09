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
	player.color = arg.color 	--红方 蓝方 -1 -2 -3 和 1 2 3表示 以及出生位置
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
	
	print("IMapPlayer:ctor()")
end
function IMapPlayer:getType()
	return "IMapPlayer"
end
function IMapPlayer:update(dt)
	if self:getHp() <= 0 then return end
	
	--add code before this
	IMapPlayer.super.update(self,dt)
end


function IMapPlayer:init(modleid)
		
	self:setPos(5,0,5)
	modleid = 100000001
	--self.attDat =  g_shareData.heroRepository[100000001]
	self.attDat = g_shareData.heroRepository[modleid]
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

return IMapPlayer

