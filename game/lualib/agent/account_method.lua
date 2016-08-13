local skynet = require "skynet"
local syslog = require "syslog"

----------------account func------------------
local AccountMethod = 
{
	--
	setNickName = function(self, name)
		self.nick = name
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self, "nick")
		
		--log record
		syslog.infof("player[%s]:setNickName:%s", self.account_id, name)
	end;
	--
	addGold = function(self, _gold)
		local nv = self.gold + _gold
		if nv < 0 then return end
		self.gold = nv
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self, "gold")
		
		--log record
		syslog.infof("player[%s]:addGold:%d:%d", self.account_id, _gold, nv)
	end;
	--
	addMoney = function(self, _money)
		local nv = self.money + _money
		if nv < 0 then return end
		self.money = nv

		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self, "money")
		
		--log record
		syslog.infof("player[%s]:addMoney:%d:%d", self.account_id, _money, nv)
	end;
	--
	addExp = function(self, _exp)
		local nv = self.exp + _exp
		if nv < 0 then return end
		self.exp = nv

		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self, "exp")
		
		--log record
		syslog.infof("player[%s]:addExp:%d:%d", self.account_id, _exp, nv)
	end;
	--
	setIcon = function(self, _icon)
		self.icon = _icon		

		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self, "icon")
		
		--log record
		syslog.infof("player[%s]:setIcon:%s", self.account_id, _icon)
	end;
	--
	setFlag = function(self, _flag)
		self.flag = _flag
	
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account_rd", "update", self, "flag")
		
		--log record
		syslog.infof("player[%s]:setFlag:%d", self.account_id, _flag)
	end;
	--
	addFlag = function(self, _flag)
		self.flag = self.flag | _flag
		self:setFlag(self.flag)
	end;
}

return AccountMethod