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
			agentPlayer.send_request("sendMail", {mailsList = units})	
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
	addMail = function(self, op, mail)
		self.units[mail.uuid] = mail
		self:sendMailData( mail )
		--log record
	end;
	--
	delMail = function(self, op, uuid)
		self.units[uuid].flag = bit(2)
		self:sendMailData( self.units[uuid] )
		self.units[uuid] = nil
		--log record
	end;
	--
	setFlag = function(self, op, uuid, flag)
		self.units[uuid].flag = flag
		self:sendMailData( self.units[uuid] )
		--log record
	end;
}

return MailsMethod
