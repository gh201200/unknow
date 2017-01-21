local mails = {}
local connection_handler
local SHORT_SAVE_TIME = 7 * 24 * 60 * 60
local LONG_SAVE_TIME = 30 * 24 * 60 * 60

function mails.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("mails:%s", name)
end

function mails.load (account_id)
	local mails = {}
	print( "mail laod ", account_id)
	local connection, key = make_key (account_id)
	if connection:exists (key) then
		local st = connection:smembers(key)
		for k, v in pairs(st) do
			mails[v]  = {uuid = v}	
			mails[v].title = connection:hget (v, "title")
			mails[v].content = connection:hget (v, "content")
			mails[v].sender = connection:hget (v, "sender")
			mails[v].items = connection:hget (v, "items")
			mails[v].flag = tonumber(connection:hget (v, "flag"))
			mails[v].time = tonumber(connection:hget (v, "time"))
		end
	end
	return mails
end

function mails.add(who, mail)
	local accounts
	local conn = connection_handler("accountlist")
	if #who == 0 then
		accounts = conn:zrange("accountlist", 0, -1)
	else
		accounts = who
	end
	for k, v in pairs(accounts) do
		local connection, key = make_key(v)
		if not conn:zscore("accountlist", v) then
			print("send mail,but account not exist:"..v)
			return
		end
		connection:sadd(key, mail.uuid)
		connection:hmset(mail.uuid, table.packdb(mail))
		if string.len(mail.items) > 0 then
			connection:expire(key, LONG_SAVE_TIME)
			connection:expire(mail.uuid, LONG_SAVE_TIME)
		else
			connection:expire(key, SHORT_SAVE_TIME)
			connection:expire(mail.uuid, SHORT_SAVE_TIME)
		end
		--bgsave
		if not mail.doNotSavebg then
			sendBgevent("mails", v, "R")
		end
	end
end

function mails:del(account_id, uuid)
	local connection, key = make_key( account_id )
	connection:srem(key, uuid)
	connection:del( uuid )		
	
	--bgsave
	sendBgevent("mails", account_id, "R")
end

function mails.update(account_id, mail, ...)
	local connection, key = make_key( account_id )
	if connection:exists(mail.uuid) then
		connection:hmset(mail.uuid, table.packdb(mail, ...))
		--bgsave
		if not mail.doNotSavebg then
			sendBgevent("mails", account_id, "R")
		end
	end
end


return mails

