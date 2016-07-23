local account = {}
local connection_handler

function account.init (ch)
	connection_handler = ch
end

local function make_key (name)
	return connection_handler (name), string.format ("user:%s", name)
end

function account.load (name)
	assert (name)

	local acc = { name = name }

	local connection, key = make_key (name)
	if connection:exists (key) then
		acc.id = connection:hget (key, "account")
		acc.password = connection:hget (key, "password")
	end

	return acc
end

function account.create (id, name, password)
	assert (id and name and #name < 24 and password and #password < 24, "invalid argument")
	
	local connection, key = make_key (name)
	assert (connection:hsetnx (key, "account", id) ~= 0, "create account failed")

	--local salt, verifier = srp.create_verifier (name, password)
	--assert (connection:hmset (key, "salt", salt, "verifier", verifier) ~= 0, "save account verifier failed")

	return id
end

return account

