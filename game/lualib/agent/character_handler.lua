local skynet = require "skynet"

local syslog = require "syslog"
local handler = require "agent.handler"

local uuid = require "uuid"


local REQUEST = {}
handler = handler.new (REQUEST, nil, nil)

local user


handler:init (function (u)
	user = u
end)

local function create_character (name, race, class)
	syslog.noticef ("recv client data (account )")

	local general {
		name = name,
		race = race,
		class = class,
		map = 'Asian',
	}
	local attribute {
		health = 100,
		level = 60,
		exp = 32767
		health_max = 100,
		strength = 98,
		stamina = 32,
		attack_power = 50,
	}
	local position {
		x = 87,
		y = 0,
		z = 334,
		o = 0,
	}
	local movement {
		pos = position
	}


	local character = {
		general = general,
		attribute = attribute
		movement = movement
	}
	
	return character
end

function REQUEST.character_list ()
	local character = create_character ()
	return { character = character }
end


function REQUEST.character_create (args)
	for k, v in pairs (args) do print (k, v) end
	local c = args.character or error ("invalid argument")

	local character = create_character (c.name, c.race, c.class)
	local id =  uuid.gen (),
	character.id = id

	return { character = character }
end

function REQUEST.character_pick (args)
	local id = args.id or error ()
	assert (check_character (user.account, id))

	local c = skynet.call (database, "lua", "character", "load", id) or error ()
	local character = dbpacker.unpack (c)
	user.character = character

	local world = skynet.uniqueservice ("world")
	skynet.call (world, "lua", "character_enter", id)

	return { character = character }
end

attribute_string = {
	"health",
	"strength",
	"stamina",
}

return handler

