local skynet = require "skynet"
local snax = require "snax"
local syslog = require "syslog"

----------------account func------------------
local AccountMethod = 
{
	--
	setNickName = function(self, op, name)
		self.unit.nick = name
		
		self:sendAccountData()

		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account", "update", self.account_id, self.unit, "nick")
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
		if _gold == 0 then return end
		local nv = mClamp(self.unit.gold + _gold, 0, math.maxint32)
		
		self.unit.gold = nv
		
		self:sendAccountData()
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account", "update", self.account_id, self.unit, "gold")
		
		--log record
		syslog.logmy("account", {opt=op, account=self.account_id, atype=2, val=_gold})
	end;
	--
	getMoney = function(self)
		return self.unit.money
	end;
	--
	addMoney = function(self, op, _money)
		if _money == 0 then return end
		local nv = mClamp(self.unit.money + _money, 0, math.maxint32)
		self.unit.money = nv

		self:sendAccountData()
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account", "update", self.account_id, self.unit, "money")
		
		--log record
		syslog.logmy("account", {opt=op, account=self.account_id, atype=3, val=_money})
	end;
	--
	getExp = function(self)
		return self.unit.exp
	end;
	addExp = function(self, op,  _exp)
		if _exp == 0 then return end
		local nv = self.unit.exp + _exp
		
		nv = mClamp(nv, 0, math.maxint32)
		
		local toprank = snax.uniqueservice("toprank")
		toprank.post.add(Quest.RankType.Exp, nv, self.account_id)
			
		if self.unit.topexp < nv then
			self.unit.topexp = nv
		end
		self.unit.exp = nv

		self:onExp()

		self:sendAccountData()
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account", "update", self.account_id, self.unit, "exp", "topexp")
		
		--log record
		syslog.logmy("account", {opt=op, account=self.account_id, atype=1, val=_exp})
	end;
	--
	getAExp = function(self)
		return self.unit.aexp
	end;
	addAExp = function(self, op,  _exp)
		if _exp == 0 then return end
		local nv = self.unit.aexp + _exp
		
		nv = mClamp(nv, 0, math.maxint32)
		
		self.unit.aexp = nv

		self:sendAccountData()
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account", "update", self.account_id, self.unit, "aexp")
		
		--log record
		--syslog.logmy("account", {opt=op, account=self.account_id, atype=1, val=_exp})
	end;
	

	--
	setIcon = function(self, op, _icon)
		self.unit.icon = _icon		

		self:sendAccountData()
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account", "update", self.account_id, self.unit, "icon")
	end;
	--
	setFlag = function(self, op, _flag)
		self.unit.flag = _flag
	
		self:sendAccountData()
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account", "update", self.account_id, self.unit, "flag")
	end;
	--
	addFlag = function(self, op, _flag)
		self.unit.flag = self.unit.flag | _flag
		self:setFlag(op, self.flag)
	end;
	--
	getVersion = function(self)
		return self.unit.version
	end;
	--
	getStar = function(self)
		return self.unit.star
	end;
	--
	addStar = function(self, num)
		self.unit.star = self.unit.star + num
	end;
	
	
	--根据时间刷新 探索和宝箱购买次数
	refreshTimes = function(self)
		if self.unit.refreshtime < os.time() then
			self.unit.exploretimes = 20
			self.unit.buyboxtimes = 20
			self.unit.refreshtime = Time.tomorrow()
			
			self:sendAccountData()
			
			local database = skynet.uniqueservice("database")		
			skynet.call (database, "lua", "account", "update", self.account_id, self.unit, "exploretimes", "buyboxtimes")
			-- skynet.call (database, "lua", "account", "update", self.account_id, self.unit, "buyboxtimes")
		end
	end;
	
	getExploreTimes = function(self)
		self:refreshTimes()
		return self.unit.exploretimes
	end;
	haveExploreTimes = function(self)
		self:refreshTimes()
		return self.unit.exploretimes > 0 or self.unit.exploretimes == -1
	end;
	addExploreTimes = function(self, _time)
		if _time == 0 then return end
		self:refreshTimes()
		self.unit.exploretimes = self.unit.exploretimes + _time
		self:sendAccountData()
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account", "update", self.account_id, self.unit, "exploretimes")
	end;
	
	getBuyBoxTimes = function(self)
		self:refreshTimes()
		return self.unit.buyboxtimes
	end;
	haveBuyBoxTimes = function(self, time)
		self:refreshTimes()
		return self.unit.buyboxtimes >= time or self.unit.buyboxtimes == -1
	end;
	addBuyBoxTimes = function(self, _time)
		if _time == 0 then return end
		self:refreshTimes()
		self.unit.buyboxtimes = self.unit.buyboxtimes + _time
		self:sendAccountData()
		
		local database = skynet.uniqueservice("database")		
		skynet.call (database, "lua", "account", "update", self.account_id, self.unit, "buyboxtimes")
	end;
}

return AccountMethod
