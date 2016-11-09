local skynet = require "skynet"

local SystemCh = class("SystemCh")

local user
local REQUEST = {}

function SystemCh:ctor()
	self.request = REQUEST
end

function SystemCh:init( u )
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

local function openPackage( itemId )
	local itemDat = g_shareData.itemRepository[itemId]
	if itemDat.n32Type ~= 4 then
		return {}
	end

	local pkgIds = string.split(itemDat.szRetain3, ',')
	local items = {}
	for k, v in pairs(pkgIds) do
		local drop = g_shareData.itemDropPackage[v]
		local rd = math.random(1, drop.totalRate)
		local r = nil
		for p, q in pairs(drop) do
			if type(q) == "table" then
				if q.n32Rate >= rd then
					r = q
					break
				end
			end
		end
		if r then
			local itemId = r.n32ItemId
			local itemNum = math.random(r.n32MinNum, r.n32MaxNum)
			local item = g_shareData.itemRepository[itemId]
			if item.n32Type == 3 then
				self.cards:addCard("buyShopItem-openPackage", item.n32Retain1, itemNum)
			elseif item.n32Type == 4 then
				self.account:addGold("buyShopItem-openPackage", item.n32Retain1 * itemNum)
			elseif item.n32Type == 5 then
				self.account:addMoney("buyShopItem-openPackage", item.n32Retain1 * itemNum)
			end
		
			table.insert(items, {itemId = itemId, itemNum = itemNum})
		end
	end
	return items
end


function REQUEST.buyShopItem( args )
	local errorCode = 0
	local costMoney = 0
	local card = nil
	local ids = {}
	local shopDat = g_shareData.shopRepository[args.id]
	repeat
		if not shopDat then
			errorCode = -1
			break
		end
		if shopDat.n32MoneyType == 1 then	--金币
			if user.account:getGold() < shopDat.n32Price then
				errorCode = 1	--金币不足
				break
			end
		elseif shopDat.n32MoneyType == 2 then	--钻石
			if user.account:getMoney() < shopDat.n32Price then
				errorCode  = 2	--钻石不足
				break
			end
		end
		if shopDat.n32Limit > 0 then
			card = user.cards:getCardByDataId( args.id )
			if card and card.buyNum >= shopDat.n32Limit then
				errorCode = 3	--购买数量限制
			 	break
			end
		end
	
		-------------开始购买
		--扣除货币
		if shopDat.n32MoneyType == 1 then	--金币
			user.account:addGold("buyShopItem", -shopDat.n32Price)
		elseif shopDat.n32MpneyType == 2 then	--钻石
			user.account:addMoney("buyShopItem", -shopDat.n32Price)
		end
		--开始购买
		if shopDat.n32Type == 2	then --金币
			user.account:addGold("buyShopItem", shopDat.n32Count)
		elseif shopDat.n32Type == 3 then	--宝箱
			local items = openPackage( args.n32GoodsID )
			for k, v in pairs(items) do
				ids[k] = v.itemId
				ids[k+1] = v.itemNum
			end
			 
		elseif shopDat.n32Type == 4 then	--卡牌
			user.cards:addCard("buyShopItem", shopdat.n32GoodsID, shopDat.n32Count, shopDat.n32Count)
		end

	until true
	
	return {errorCode = errorCode, shopId = args.id, ids = ids}
end

return SystemCh.new()
