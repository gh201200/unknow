local skynet = require "skynet"
local syslog = require "syslog"

----------------skills func---------------------
local MailsMethod = 
{
	--
	sendMailData = function(self, unit)
		if unit then
			agentPlayer.send_request("sendMail", {mailsList = {unit}})	
		else
			agentPlayer.send_request("sendMail", {mailsList = self.units})	
		end
	end;
	--
	isDirtyMail = function(self, uuid)
		local unit = self.units[uuid]
		
		if bit_and(unit.flag, bit(0)) ~= 0 then	
			return false
		end
		if string.len(unit.items) > 0 and bit_and(unit.flag, bit(1)) == 0 then
			return false
		end
		return true
	end;
	--
	getMail = function(self, _uuid)
		return self.units[_uuid]
	end;
	--
	addMail = function(self, mail)
		self.units[mail.uuid] = mail
		self:sendMailData( mail )
		--log record
	end;
	--
	delMail = function(self, uuid)
		self.units[uuid].flag = bit(2)
		self:sendMailData( self.units[uuid] )
		self.units[uuid] = nil
		--log record
	end;
	--
	addFlag = function(self, uuid, flag)
		self.units[uuid].flag = bit_or(self.units[uuid].flag,flag)
		self:sendMailData( self.units[uuid] )
		
		local database = skynet.uniqueservice ("database")
		skynet.call (database, "lua", "mails", "update", self.account_id, self.units[uuid], "flag")
	
		--log record
	end;
}

return MailsMethod
