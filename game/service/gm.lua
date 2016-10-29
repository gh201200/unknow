local skynet = require "skynet"
local syslog = require "syslog"
local WATCHDOG

function init( watchdog )
	WATCHDOG = watch	
end

function exit()

end

function response.add_money(account_id, money, gold)
	local ret = skynet.call(WATCHDOG, "lua", "gm_cmd", account_id, add_money, {money=money,gold=gold})
	--说明玩家是离线状态，这里直接操作数据库
	if not ret then
		local db = skynet.uniqueservice 'database'
		local account = skynet.call(db, "lua", "account_rd","load", account_id)
		account.money = mClamp(account.money + add_money, 0, math.maxinteger)
		account.gold = mClamp(account.gold + add_gold, 0, math.maxinteger)
		skynet.call(db, "lua", "account_rd","update", account, "money", "gold")

		syslog.infof("GM[%s]:add_money:%d:%d", account_id, money, gold)
	end
end
