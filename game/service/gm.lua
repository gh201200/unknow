local skynet = require "skynet"
local syslog = require "syslog"
local uuid = require "uuid"
local sharedata = require "sharedata"

local WATCHDOG
local FUNCS_POST = {}
local FUNCS_GET = {}

function init( watchdog )
	WATCHDOG = watchdog
	g_shareData  = sharedata.query "gdd"
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
		local db = skynet.uniqueservice 'database'
		local account = skynet.call(db, "lua", "account_rd","load", account_id)
		account.money = mClamp(account.money + add_money, 0, math.maxinteger)
		account.gold = mClamp(account.gold + add_gold, 0, math.maxinteger)
		skynet.call(db, "lua", "account_rd","update", account, "money", "gold")

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
		local db = skynet.uniqueservice 'database'
		local cards = skynet.call(db, "lua", "cards_rd","load", account_id)
		local card = nil
		local _serId = Macro_GetCardSerialId( dataId )
		for k, v in pairs(cards) do
			if Macro_GetCardSerialId(v.dataId) == _serId then
				card = v
				break
			end
		end
		if card then
			card.count = mClamp(card.count + cardNum * g_shareData.heroRepository[dataId].n32WCardNum, 0, math.maxinteger)
		else
			card = {uuid = uuid.gen(), dataId = dataId, power = 100, count = cardNum}
		end
		skynet.call(db, "lua", "cards_rd","addCard", account_id, card)

		syslog.infof("GM[%s]:add_card:%d, %d", account_id, dataId, cardNum)
	end
end

-----------------------------------------------------
--GET
function response.getAccountInfo( param )
	local db = skynet.uniqueservice 'database'
	local account = skynet.call(db, "lua", "account_rd","load",param["id"])
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
	local db = skynet.uniqueservice 'database'
	local cards = skynet.call(db, "lua", "cards_rd","load",param["id"])
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
