local skynet = require "skynet"

local ShopCh = class("ShopCh")

local user
local REQUEST = {}

function ShopCh:ctor()
	self.request = REQUEST
end

function ShopCh:init( u )
	user = u
end

function REQUEST.upgradeCardColorLevel( args )
	local errorCode = 0
	local card = user.cards:getCardByUuid(args.uuid)
	repeat                                                                                 
        	if not card then                                                                                                                                       
			errorCode = -1
			break                                                                                                                               
        	end
		local cardDat = g_shareData.heroRepository[card.dataId]
        	if cardDat.n32WCardNum > card.count then
			errorCode = 1	--碎片数量不足
			break
		end
		if cardDat.n32GoldNum > user.account:getGold() then
			errorCode = 2	--金币不足
			break
		end
	
		if not g_shareData.heroRepository[cardDat.id+1] then
			errorCode = 3	--已到最高品质
			break
		end
		
		---------开始升级
		--扣除金币
		user.account:addGold("upgradeCardColorLevel", -cardDat.n32GoldNum)
		--扣除碎片
		user.cards:delCardByUuid("upgradeCardColorLevel", args.uuid, cardDat.n32WCardNum)
		--开始升级
		user.cards:updateDataId("upgradeCardColorLevel", args.uuid, cardDat.id+1)
	until true
	
	return {errorCode = errorCode, uuid = args.uuid}
end

return ShopCh.new()
