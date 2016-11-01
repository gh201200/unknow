local skynet = require "skynet"
local syslog = require "syslog"

----------------account func------------------
local AccountMethod = 
{
	--
	setNickName = function(self, op, name)
		self.unit.nick = name
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self.unit, "nick")
		
		--log record
		syslog.infof("op[%s]player[%s]:setNickName:%s", op, self.account_id, name)
	end;
	--
	getNickName = function(self)
		return self.unit.nick
	end;
	--
	getGold = function(self)
		return self.unit.gold
	end;
	--
	addGold = function(self, op,  _gold)
		local nv = self.unit.gold + _gold
		if nv < 0 then return end
		self.unit.gold = nv
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self.unit, "gold")
		
		--log record
		syslog.infof("op[%s]player[%s]:addGold:%d:%d", op, self.account_id, _gold, nv)
	end;
	--
	addMoney = function(self, op, _money)
		local nv = self.unit.money + _money
		if nv < 0 then return end
		self.unit.money = nv

		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self.unit, "money")
		
		--log record
		syslog.infof("op[%s]player[%s]:addMoney:%d:%d", op,  self.account_id, _money, nv)
	end;
	--
	addExp = function(self, op,  _exp)
		local nv = self.unit.exp + _exp
		if nv < 0 then return end
		self.unit.exp = nv

		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self.unit, "exp")
		
		--log record
		syslog.infof("op[%s]player[%s]:addExp:%d:%d", op, self.account_id, _exp, nv)
	end;
	--
	setIcon = function(self, op, _icon)
		self.unit.icon = _icon		

		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self.unit, "icon")
		
		--log record
		syslog.infof("op[%s]player[%s]:setIcon:%s", op, self.account_id, _icon)
	end;
	--
	setFlag = function(self, op, _flag)
		self.unit.flag = _flag
	
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self.unit, "flag")
		
		--log record
		syslog.infof("op[%s]player[%s]:setFlag:%d", op, self.account_id, _flag)
	end;
	--
	addFlag = function(self, op, _flag)
		self.unit.flag = self.unit.flag | _flag
		self:setFlag(op, self.flag)
	end;
}

return AccountMethod
