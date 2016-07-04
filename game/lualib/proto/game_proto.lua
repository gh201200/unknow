local sparser = require "sprotoparser"

local game_proto = {}

local types = [[

.package {
	type 0 : integer
	session 1 : integer
}

.Vector3 {
	x 0 : integer
	y 1 : integer
	z 2 : integer
}
]]

local c2s = [[

query_event_status 0 {		--query event stamp
	request {
		event_type 0 : integer
		event_stamp 1 : integer
	}
	response {
		event_type 0 : integer
		event_stamp 1 : integer
	}
}


map_delat_time 200{			--for estimate ping time
	response {
	}
}

move 201 {		--client move
	request {
		target 0 : Vector3
		dir 1 : Vector3
	}
}


]]

local s2c = [[
move 0 {
	request {
		pos 0 : Vector3
		dir 1 : Vector3
	}
}
]]

game_proto.types = sparser.parse (types)
game_proto.c2s = sparser.parse (types .. c2s)
game_proto.s2c = sparser.parse (types .. s2c)

return game_proto
