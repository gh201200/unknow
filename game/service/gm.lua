local skynet = require "skynet"
local syslog = require "syslog"
local WATCHDOG
local FUNCS_POST = {}
local FUNCS_GET = {}

function init( watchdog )
	WATCHDOG = watchdog
end

function exit()

end

-------------------------------------------------------
--POST
function accept.add_money( param )
	local account_id, add_money, add_gold = param['id'], param['money'], param['gold']
	local ret = skynet.call(WATCHDOG, "lua", "gm_cmd", account_id, 'add_money', {money=money,gold=gold})
	--说明玩家是离线状态，这里直接操作数据库
	if not ret then
		local db = skynet.uniqueservice 'database'
		local account = skynet.call(db, "lua", "account_rd","load", account_id)
		account.money = mClamp(account.money + add_money, 0, math.maxinteger)
		account.gold = mClamp(account.gold + add_gold, 0, math.maxinteger)
		skynet.call(db, "lua", "account_rd","update", account, "money", "gold")

		syslog.infof("GM[%s]:add_money: money(%d) gold(%d)", account_id, add_money, add_gold)
	end
end

-----------------------------------------------------
--GET
function response.gm_get_opt(param)
	local func = param['dowhat']
	
end
