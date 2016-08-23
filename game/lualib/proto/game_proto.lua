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
	Strength 0 : integer
  	StrengthPc 1 : integer
 	Minjie 2 : integer
  	MinjiePc 3 : integer
  	Zhili 4 : integer
  	ZhiliPc 5 : integer
	HpMax 6 : integer
	HpMaxPc 7 : integer
	MpMax 8 : integer
	MpMaxPc 9 : integer
  	Attack 10 : integer
  	AttackPc 11 : integer
  	Defence 12 : integer
  	DefencePc 13 : integer
  	ASpeed 14 : integer
  	MSpeed 15 : integer
  	MSpeedPc 16 : integer
  	AttackRange 17 : integer
  	AttackRangePc 18 : integer
  	RecvHp 19 : integer
  	RecvHpPc 20 : integer
  	RecvMp 21 : integer
  	RecvMpPc 22 : integer
  	BaojiRate 23 : integer
  	BaojiTimes 24 : integer
  	Hit 25 : integer
  	Miss 26 : integer
}

.Buff {
	buffId 0 : integer
	count 1 : integer
	remainTime 2 : integer 
}

.Affect {
	effectId 0 : integer
	effectTime 1 : integer 
}
.Matcher {
	account 0 : string
	nickname 1 : string	
}

.card {
	dataId 0 : integer
	uuid 1 : string
	power 2 : integer
	count 3 : integer
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

query_event_affect 7 {
	request {
		event_stamp 0 : EventStamp
	}
	response {
		event_stamp 0 : EventStamp
		affectNum 1 : integer
		affectLists 22 : *Affect
	}
}
login 101 {
         request {
                 name 0 : string    
                 client_pub 1 : string         
         }
         response {
		 user_exists 0 : boolean
                 account_id 1 : string
                 gameserver_port 2 : integer
         }
}

enterGame 102 {
	request {
		account_id 0 : string
	}
}

requestMatch 103 {
	request {
	}
	response {
		errorcode 0 : integer
		matcherNum 1 : integer
		matcherList 2 : *Matcher
	}
}

cancelMatch 104 {
	request {
	}
	response {
		errorcode 0 : integer
	}
}
pickHero 110 {
	request {
		heroid 0 : integer
	}
	response {
		errorcode 0 : integer
	}
}

confirmHero 111 {
	request {
	}
	response {
		errorcode 0 : integer
	}
}

getCardsDatas 112 {
	response {
		cardNum 0 : integer
		cardsList 1 : *card
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
pickedhero 100 {
	request {
		account 0 : string
		heroid 1 : integer
	}
}
beginEnterPvpMap 101 {
	request {
	}
}
synPickTime 102 {
	request {
		leftTime 0 : integer	 
	}
}
confirmedHero 103 {
	request {
		account 0 : string
		heroid 1 : integer
	}
}
quitPick 104 {
	request {
	}
}


]]

game_proto.types = sparser.parse (types)
game_proto.c2s = sparser.parse (types .. c2s)
game_proto.s2c = sparser.parse (types .. s2c)

return game_proto
