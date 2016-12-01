local skynet = require "skynet"
local syslog = require "syslog"
local uuid = require "uuid"
local sharedata = require "sharedata"
local CardMethod = require "agent.cards_method"

local database
local WATCHDOG
local FUNCS_POST = {}
local FUNCS_GET = {}

function init( watchdog )
	WATCHDOG = watchdog
	g_shareData  = sharedata.query "gdd"
	database = skynet.uniqueservice 'database'
end

function exit()

end

-------------------------------------------------------
--POST
function accept.add_money( param )
	local account_id, add_money, add_gold = param['id'], tonumber(param['money']), tonumber(param['gold'])
	local ret = skynet.call(WATCHDOG, "lua", "gm_cmd", account_id, 'add_money', {money=add_money,gold=add_gold})
	--说明玩家是离线状态，这里直接操作数据库
	if not ret then
		local account = skynet.call(database, "lua", "account_rd","load", account_id)
		account.money = mClamp(account.money + add_money, 0, math.maxinteger)
		account.gold = mClamp(account.gold + add_gold, 0, math.maxinteger)
		skynet.call(database, "lua", "account_rd","update", account, "money", "gold")

		syslog.infof("GM[%s]:add_money:%d,%d", account_id, add_money, add_gold)
	end
end

function accept.add_card( param )
	local account_id, dataId, cardNum = param['id'], tonumber(param['dataId']), tonumber(param['cardNum'])
	if not g_shareData.heroRepository[dataId] then
		print('data is nil', dataId)
		return
	end
	local ret = skynet.call(WATCHDOG, "lua", "gm_cmd", account_id, 'add_card', {dataId=dataId,cardNum=cardNum})
	--说明玩家是离线状态，这里直接操作数据库
	if not ret then
		local _serId = Macro_GetCardSerialId( itemDat.n32Retain1 )
		local card = skynet.call(database, "lua", "cards_rd", "loadBySerialId", v.account_id, _serId) 
		if not card then
			card = CardMethod.initCard( itemDat.n32Retain1 )
			card.count = (q-1) * g_shareData.heroRepository[itemDat.n32Retain1].n32WCardNum 
		else
			card.count = card.count + q *  g_shareData.heroRepository[itemDat.n32Retain1].n32WCardNum 
		end
		skynet.call(database, "lua", "cards_rd","addCard", account_id, card)

		syslog.infof("GM[%s]:add_card:%d, %d", account_id, dataId, cardNum)
	end
end

function accept.addItems( param )
	print("gm add items ", param)

	local items = param['items']
	local account_id = param['account_id']
	for p, q in pairs(items) do
		local itemDat = g_shareData.itemRepository[p]
		if itemDat.n32Type == 3 then	
			local _serId = Macro_GetCardSerialId( itemDat.n32Retain1 )
			local card = skynet.call(database, "lua", "cards_rd", "loadBySerialId", account_id, _serId) 
			if not card then
				card = CardMethod.initCard( itemDat.n32Retain1 )
				card.count = (q-1) * g_shareData.heroRepository[itemDat.n32Retain1].n32WCardNum 
			else
				card.count = card.count + q *  g_shareData.heroRepository[itemDat.n32Retain1].n32WCardNum 
			end
			skynet.call(database, "lua", "cards_rd","addCard", account_id, card)
		elseif itemDat.n32Type == 4 then
			syslog.err("gm addItems: can not add packages["..p.."]")
		elseif itemDat.n32Type == 5 then
			account.gold = mClamp(account.gold + itemDat.n32Retain1*q, 0, math.maxinteger)
			skynet.call (database, "lua", "account_rd", "update", account, "gold")
		elseif itemDat.n32Type == 6 then
			account.money = mClamp(account.money + itemDat.n32Retain1*q, 0, math.maxinteger)
			skynet.call (database, "lua", "account_rd", "update", account, "money")
		elseif itemDat.n32Type == 7 then
			
		end
	end
end

-----------------------------------------------------
--GET
function response.getAccountInfo( param )
	local account = skynet.call(database, "lua", "account_rd","load",param["id"])
	if not account.nick then return "" end
	local r = {
		nick = account.nick,
		password = account.password,
		gold = account.gold,
		money = account.money,
		exp = account.exp,
		icon = account.icon,
		flag = account.flag	
	}
	return r
end

function response.getCardsInfo( param )
	local cards = skynet.call(database, "lua", "cards_rd","load",param["id"])
	return cards
end

function response.getHero( param )
	local attDat = g_shareData.heroRepository[tonumber(param['id'])]
	if not attDaat then return "" end
	local r = {
		id = attDat.id,
		name = attDat.szName,
		attack = attDat.n32Attack,
	}
	return r
end
