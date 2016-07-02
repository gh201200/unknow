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


map_delat_time 200{		
	response {
	}
}

move 201{
	request {       
		dir 0 : Vector3		# move direction
	}
	response {
		pos 0 : Vector3		# entity position
		dir 1 : Vector3		# entity direction
	} 
}

]]

local s2c = [[

]]

game_proto.types = sparser.parse (types)
game_proto.c2s = sparser.parse (types .. c2s)
game_proto.s2c = sparser.parse (types .. s2c)

return game_proto
