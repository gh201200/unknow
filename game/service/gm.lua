local skynet = require "skynet"
local snax = require "snax"
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
	DEF = g_shareData.DEF
	Quest = g_shareData.Quest
	database = skynet.uniqueservice 'database'
end

function exit()

end
local CONSOLE = {}
function CONSOLE.sendmail(who, title, content, sender, stitem)
	local mail = snax.uniqueservice("centermail")
	mail.post.sendmail({who}, title, content, sender, items)
end

-------------------------------------------------------
--POST
function accept.console_cmd( cmd, ... )
	local cmd = CONSOLE[cmd]
	if cmd then
		pcall(cmd, ...)
	else
		print("Invalid gm cmd: " .. cmd)
	end
end

function accept.add_money( param )
	local account_id, add_money, add_gold = param['id'], tonumber(param['money']), tonumber(param['gold'])
	local ret = skynet.call(WATCHDOG, "lua", "gm_cmd", account_id, 'add_money', {money=add_money,gold=add_gold})
	--说明玩家是离线状态，这里直接操作数据库
	if not ret then
		local account = skynet.call(database, "lua", "account","load", account_id)
		account.money = mClamp(account.money + add_money, 0, math.maxinteger)
		account.gold = mClamp(account.gold + add_gold, 0, math.maxinteger)
		skynet.call(database, "lua", "account","update", account, "money", "gold")

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
		local card = skynet.call(database, "lua", "cards", "loadBySerialId", v.account_id, _serId) 
		if not card then
			card = CardMethod.initCard( itemDat.n32Retain1 )
			if Macro_GetCardColor( itemDat.n32Retain1 ) == 0 then 
				card.count = mClamp(q.itemNum * g_shareData.heroRepository[itemDat.n32Retain1].n32CCardNum, 0, math.maxint32)
			else
				card.count = mClamp((q.itemNum-1) * g_shareData.heroRepository[itemDat.n32Retain1].n32CCardNum, 0, math.maxint32)
			end
		else
			card.count = mClamp(card.count + q.itemNum *  g_shareData.heroRepository[itemDat.n32Retain1].n32CCardNum, 0, math.maxint32) 
		end
		
		skynet.call(database, "lua", "cards","addCard", account_id, card)

		syslog.infof("GM[%s]:add_card:%d, %d", account_id, dataId, cardNum)
	end
end

function accept.addItems( param )
	print("gm add items ", param)

	local items = param['items']
	local account_id = param['account_id']
	for p, q in pairs(items) do
		local itemDat = g_shareData.itemRepository[q.itemId]
		if itemDat.n32Type == 3 then
			local _serId = Macro_GetCardSerialId( itemDat.n32Retain1 )
			local card = skynet.call(database, "lua", "cards", "loadBySerialId", account_id, _serId) 
			if not card then
				card = CardMethod.initCard( itemDat.n32Retain1 )
				if Macro_GetCardColor( itemDat.n32Retain1 ) == 0 then 
					card.count = mClamp(q.itemNum * g_shareData.heroRepository[itemDat.n32Retain1].n32CCardNum, 0, math.maxint32)
				else
					card.count = mClamp((q.itemNum-1) * g_shareData.heroRepository[itemDat.n32Retain1].n32CCardNum, 0, math.maxint32)
				end
			else
				card.count = mClamp(card.count + q.itemNum *  g_shareData.heroRepository[itemDat.n32Retain1].n32CCardNum, 0, math.maxint32) 
			end
			skynet.call(database, "lua", "cards","addCard", account_id, card)
		elseif itemDat.n32Type == 4 then
			syslog.err("gm addItems: can not add packages["..q.itemId.."]")
		elseif itemDat.n32Type == 5 then
			account.gold = mClamp(account.gold + itemDat.n32Retain1*q.itemNum, 0, math.maxinteger)
			skynet.call (database, "lua", "account", "update", account, "gold")
		elseif itemDat.n32Type == 6 then
			account.money = mClamp(account.money + itemDat.n32Retain1*q.itemNum, 0, math.maxinteger)
			skynet.call (database, "lua", "account", "update", account, "money")
		elseif itemDat.n32Type == 7 then
			local _serId = Macro_GetSkillSerialId( itemDat.n32Retain1 )
			local skill = skynet.call(database, "lua", "skills", "loadBySerialId", account_id, _serId) 
 	                if skill then       --already has the kind of skill
  	                        skill.count = mClamp(v.count + q.itemNum, 0, math.maxint32)
			else
 				skill = SkillMethod.initSkill( itemDat.n32Retain1 )
 	                        skill.count = q.itemNum
                  	end
			skynet.call(database, "lua", "skills","addskill", account_id, skill)
		end
	end
end

function accept.exit()
	local list = skynet.call(".launcher", "lua", "LIST")
	print(list)
	for k, v in pairs(list) do
		skynet.call(".launcher", "lua", "KILL", k)
	end
end

function accept.sendMail( param )
	print("gm send mail", param)
	local who = param["who"]
	local title = param["title"]
	local content = param["content"]
	local sender =  param["sender"]
	local stitems = param["stitems"]
	local centermail = snax.uniqueservice("centermail")
	local recver = string.split(who, ",")
	centermail.post.sendmail(recver, title, content, sender, stitems)
end

-----------------------------------------------------
--GET
function response.getAccountInfo( param )
	local account = skynet.call(database, "lua", "account","load",param["id"])
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
	local cards = skynet.call(database, "lua", "cards","load",param["id"])
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
