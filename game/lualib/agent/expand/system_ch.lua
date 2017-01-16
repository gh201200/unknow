local skynet = require "skynet"
local snax = require "snax"

local SystemCh = class("SystemCh")

local user
local REQUEST = {}
local CMD = {}
function SystemCh:ctor()
	self.request = REQUEST
	self.cmd = CMD
end

function SystemCh:init( u )
	user = u
end

function CMD.isBindSkills( heroId )
	local v = user.cards:getCardByDataId( heroId )
	if not v then return false end
	for i=0,7 do
		if v['skill'..i] == 0 then
			return false
		end
	end
	return true
end

function CMD.getBindSkills( heroId )
	local r = {}
	local v = user.cards:getCardByDataId( heroId )
	for i=1, 8 do
		local skill = user.skills:getSkillBySerialId( v["skill"..(i-1)] )
		r[i] = skill.dataId
	end
	return r
end

function CMD.givePlayerStar()
	user.account:addStar( 1 )
end

function CMD.newmails( mail )
	user.mails:addMail( mail)
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
		local nextCardDat = g_shareData.heroRepository[card.dataId+1]	
		
		if not nextCardDat then
			errorCode = 3	--已到最高品质
			break
		end
	
        	if cardDat.n32WCardNum > card.count then
			errorCode = 1	--碎片数量不足
			break
		end
		
		if cardDat.n32GoldNum > user.account:getGold() then
			errorCode = 2	--金币不足
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

function REQUEST.buyShopItem( args )
	local errorCode = 0
	local costMoney = 0
	local card = nil
	local ids = {}
	local shopDat = g_shareData.shopRepository[args.id]
	local atype = 0
	local hasBuy = 0
	local activity = snax.queryservice 'activity'
	local cooldown = snax.queryservice 'cddown'
	local costPrice = 0
	print( args )
	repeat
		if not shopDat then
			errorCode = -1
			break
		end
		costPrice = shopDat.n32Price * args.num
	
		if shopDat.n32Type == 4 then	--材料
			atype = ActivityAccountType["BuyShopCard"..shopDat.n32Site]
			hasBuy = activity.req.getValue(user.account.account_id, atype) 
			costPrice = shopDat.n32Price *(1 + hasBuy) * args.num
		end
		if shopDat.n32MoneyType == 1 then	--金币
			if user.account:getGold() < costPrice then
				errorCode = 1	--金币不足
				break
			end
		elseif shopDat.n32MoneyType == 2 then	--钻石
			if user.account:getMoney() < costPrice then
				errorCode  = 2	--钻石不足
				break
			end
		end
		if shopDat.n32Limit > 0 then
			if shopDat.n32Type == 4 then	--材料
				if hasBuy + args.num > shopDat.n32Limit then
					errorCode = 3	--购买数量限制
			 		break
				end
			elseif shopDat.n32Type == 5 then	--特惠	
				local val = cooldown.req.getValue(user.account.account_id, CoolDownAccountType.TimeLimitSale)
				if val == 0 then
					errorCode = -1
					break
				end 
			end
		end
	
		-------------开始购买
		--扣除货币
		if shopDat.n32MoneyType == 1 then	--金币
			user.account:addGold("buyShopItem", -costPrice)
		elseif shopDat.n32MoneyType == 2 then	--钻石
			user.account:addMoney("buyShopItem", -costPrice)
		end
		--开始购买
		if shopDat.n32Type == 2	then --金币
			user.account:addGold("buyShopItem", shopDat.n32Count * args.num)
		elseif shopDat.n32Type == 3 then	--宝箱
			local items = usePackageItem( shopDat.n32GoodsID, user.level )
			user.servicecmd.addItems("buyShopItem", items)
			local index = 1
			for k, v in pairs(items) do
				ids[index] = k
				ids[index+1] = v
				index = index + 2
			end
		elseif shopDat.n32Type == 4 then	--材料
			local items = {}
			items[shopDat.n32GoodsID] = shopDat.n32Count * args.num
			user.servicecmd.addItems("buyShopItem", items)
			local expire = cooldown.req.getSysValue( CoolDownSysType.RefreshShopCard )
			activity.req.addValue('buyShopItem', user.account.account_id, atype, shopDat.n32Count * args.num, expire)
		elseif shopDat.n32Type == 5 then 	--特惠
			local items = usePackageItem( shopDat.n32GoodsID, user.level )
			user.servicecmd.addItems("buyShopItem", items)
			local index = 1
			for k, v in pairs(items) do
				ids[index] = k
				ids[index+1] = v
				index = index + 2
			end
			cooldown.post.setValue(user.account.account_id, CoolDownAccountType.TimeLimitSale, 0)
		end

	until true
	return {errorCode = errorCode, shopId = args.id, ids = ids}
end

function REQUEST.updateCDData( args )
	local uid = args.uid
	local cooldown = snax.queryservice 'cddown'
	local val = cooldown.req.getRemainingTime( uid )
	return {uid=uid, value=val}
end

function REQUEST.updateActivityData( args )
	local uid = args.uid
	local activity = snax.queryservice 'activity'
	local val = activity.req.getValueByUid( uid )
	return {uid=uid, value=val}
end

function REQUEST.reEnterRoom( args )
	if args.isin then
		local sm = snax.uniqueservice("servermanager")
		local ret, room = sm.req.getroomif( user.account.account_id )
		if ret then
			user.servicecmd.enterMap(room, ret)
			return {errorCode = 0}
		else
			return {errorCode = -1}
		end
	end
end

function REQUEST.bindSkill( args )
	local errorCode = 0
	local card = user.cards:getCardByUuid( args.uuidcard )
	local skill = user.skills:getSkillByUuid( args.uuidskill )
	print( user.skills.units )
	repeat
		if not card then
			errorCode = -1
			break
		end
		if not skill then
			errorCode = -1
			break
		end
		if args.slot < 0 or args.slot > 7 then
			errorCode = -1
			break
		end
		local cardDat = g_shareData.heroRepository[card.dataId]
		local skillDat = g_shareData.skillRepository[skill.dataId]
		if bit_and(cardDat.n32Camp, skillDat.n32Faction) == 0 then
			errorCode = -1
			break
		end
		--
		user.cards:setSkill("bindSkill", args.uuidcard, args.slot, Macro_GetSkillSerialId(skill.dataId))
	until true
	return {errorCode=errorCode,uuidcard=args.uuidcard,uuidskill=args.uuidskill,slot=args.slot}
end


function REQUEST.strengthSkill( args )
	local errorCode = 0
	local skill = user.skills:getSkillByUuid(args.uuid)
	repeat                                                                                 
        	if not skill then
			errorCode = -1
			break
		end
		local skillDat = g_shareData.skillRepository[skill.dataId]
		local nextId = Macro_AddSkillGrade(skill.dataId, 1)
		local nextSkillDat = g_shareData.skillRepository[nextId]	
		if not nextSkillDat then
			errorCode = 3	--已到最高品质
			break
		end
	
        	if skillDat.n32NeedStuff > skill.count then
			errorCode = 1	--碎片数量不足
			break
		end
	
		---------开始升级
		--扣除碎片
		user.skills:delSkillByUuid("strengthSkill", args.uuid, skillDat.n32NeedStuff)
		--开始升级
		user.skills:updateDataId("strengthSkill", args.uuid, nextId)
	until true
	
	return {errorCode = errorCode, uuid = args.uuid}

end

function REQUEST.reqTopRank( args )
	local toprank = snax.uniqueservice("toprank")
	local items = toprank.req.load( args )
	return {items = items, atype = args.atype}
end

function REQUEST.givePlayerStar( args )
	local serverm = snax.uniqueservice("servermanager")
	local agent = serverm.req.getAgent( args.accountid )
	if agent == skynet.self() then 
		syslog.err('can not give star to self')
		return 
	end
	if agent then
		skynet.call(agent, "lua", "givePlayerStar")	
	else
		local database = skynet.uniqueservice ("database")
		skynet.call(database, "lua", "account", "hincrby", args.accountid, "star", 1)
	end
end

function REQUEST.recvMailItems( args )
	local mail = user.mails:getMail( args.uuid )
	local errorCode = 0
	print( mail )
	repeat
		if not mail then
			errorCode = -1
			break
		end
		if bit_and(mail.flag, bit(1)) ~= 0 then
			errorCode = -1
			break
		end
		if string.len(mail.items) == 0 then
			errorCode = -1
			break
		end
	until true
	if errorCode ~= 0 then
		return {errorCode=errorCode,uuid=args.uuid,items = {}}
	end
	--
	user.mails:addFlag(args.uuid, bit(1))
	local arr = string.split(mail.items, ",")
	local items = {}
	for i=1, #arr, 2 do
		items[tonumber(arr[i])] = tonumber(arr[i+1])
	end
	local rets = user.servicecmd.addItems("recv mails", items)
	local ret = {errorCode=errorCode,uuid=args.uuid,items = {}}
	for k, v in pairs(rets) do
		table.insert(ret.items, {x=k,y=v})
	end
	return ret
end

return SystemCh.new()
