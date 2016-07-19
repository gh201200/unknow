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

.Stats {
	n32Strength 0 : integer
     	n32Strength_Pc 1 : integer
     	n32Agile 2 : integer
     	n32Agile_Pc 3 : integer
     	n32Intelg 4 : integer
     	n32Intelg_Pc 5 : integer
     	n32AttackPhy 6 : integer
     	n32AttackPhy_Pc 7 : integer
     	n32DefencePhy 8 : integer
     	n32DefencePhy_Pc 9 : integer
     	n32AttackSpeed 10 : integer
     	n32AttackSpeed_Pc 11 : integer
     	n32MoveSpeed 12 : integer
     	n32MoveSpeed_Pc 13 : integer
     	n32AttackRange_Pc 14 : integer
	n32MaxHp 15 : integer
	n32Hp_Pc 16 : integer
	n32MaxMp 17 : integer
	n32Mp_Pc 18 : integer 
	n32RecvHp 19 : integer
	n32RecvHp_Pc 20 : integer
	n32RecvMp 21 : integer
	n32RecvMp_Pc 22 : integer
}

.Buff {
	buffId 0 : integer
	count 1 : integer
	remainTime 2 : integer 
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

query_event_stats 4 {
	request {
		event_stamp 0 : EventStamp
	}
	response {
		event_stamp 0 : EventStamp
		stats 1 : Stats
	}
}

query_event_hp_mp 5 {
	request {
		event_stamp 0 : EventStamp
	}
	response {
		event_stamp 0 : EventStamp
		n32Hp 1 : integer
		n32Mp 2 : integer
		mask 3 : integer
	}
}

query_event_buff 6 {
	request {
		event_stamp 0 : EventStamp
	}
	response {
		event_stamp 0 : EventStamp
		buffLists 1 : *Buff
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
	response {
		errorcode 0 :integer
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
