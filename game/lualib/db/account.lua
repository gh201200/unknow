local account = {}
local connection_handler

function account.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("user:%s", name)
end

function account.load (account)
	assert (account)

	local acc = { account_id = account }

	local connection, key = make_key (account)
	if connection:exists (key) then
		acc.nick = connection:hget (key, "nick")
		acc.password = connection:hget (key, "password")
		acc.gold = connection:hget (key, "gold")
		acc.money = connection:hget (key, "money")
		acc.exp = connection:hget (key, "exp")
		acc.icon = connection:hget (key, "icon")
	end

	return acc
end

function account.create (account, password, nick, icon)
	assert (account and #account < 24 and password and #password < 24, "invalid argument")
	
	if not nick then nick = 'three hero' end
	if not icon then icon = '1000.icon' end

	local connection, key = make_key (account)
	assert (connection:hsetnx (key, "account_id", account) ~= 0, "create account failed")

	--local salt, verifier = srp.create_verifier (name, password)
	assert (connection:hmset (key, 
		"nick", nick, 
		"passsword", password, 
		"gold", 0, 
		"money", 0,
		"exp", 0,
		"icon", icon
		) ~= 0, "save account verifier failed")

	return account
end

return account

