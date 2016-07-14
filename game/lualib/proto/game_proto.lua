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
.EventStamp {
	id 0 : integer
	type 1 : integer
	stamp 2 : integer 
}
]]

local c2s = [[

query_event_move 1 {		#query event stamp
	request {
		event_stamp 0 : EventStamp
	}
	response {
		event_stamp 0 : EventStamp
		pos 1 : Vector3
		dir 2 : Vector3
		action 3 : integer
		speed 4 : integer
	}
}

query_server_id 2 {
	response {
		server_id 0 : integer
	}
}

query_event_CastSkill 3 {
	request {
		event_stamp 0 : EventStamp
	}
	response {
		event_stamp 0 : EventStamp
		skillId 1 : integer 
	}
}

login 101 {
         request {
                 name 0 : string    
                 client_pub 1 : string         
         }
         response {
                 user_exists 0 : boolean
                 gameserver_port 1 : integer
         }
}

heart_beat_time 200{			#heartbeat,also for estimate ping time
	response {
	}
}

move 201 {			#client move
	request {
		target 0 : Vector3
	}
}

castskill 202 {
	request {
		skillid 0 : integer
	}
}
]]

local s2c = [[
enter_room 1 {
	request {
		server_id 0 : integer
	}

}
]]

game_proto.types = sparser.parse (types)
game_proto.c2s = sparser.parse (types .. c2s)
game_proto.s2c = sparser.parse (types .. s2c)

return game_proto
