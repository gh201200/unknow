local skynet = require "skynet"
local uuid = require "uuid"

local database
local listeners = {}

local function newmail(title, content, sender, stitem)
	local mailitem = {
		uuid = uuid.gen(),
		title = title,
		content = content,
		sender = sender,
		items = stitem,
		flag = 1,
		time = os.time(),
	}
	return mailitem 
end

--------------------------------------------------------------------
--POST
function accept.sendmail(who, title, content, sender, stitem)
	local mail = newmail(title, content, sender, stitem)
	skynet.call(database, "lua", "mails", "add", who, mail)
	
	if #who == 0 then	--全服邮件
		for k, v in pairs(listeners) do
			skynet.call(listeners[v], "lua", "newmails", mail)
		end
	else
		for k, v in pairs(who) do
			if listeners[v] then
				skynet.call(listeners[v], "lua", "newmails", mail)
			end
		end
	end
end

function accept.listen( aid, agent, flag )
	if flag then
		listeners[aid] = agent
	else
		listeners[aid] = nil
	end
end

-----------------------------------------------
function init( db )
	database = db
end

function exit()
end
