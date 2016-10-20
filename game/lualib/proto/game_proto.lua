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
	projectId 0 : string
	effectId 1 : integer
	effectTime 2 : integer
	srcServerId 3 : integer 
}
.Matcher {
	account 0 : string
	nickname 1 : string	
}

.card {
	dataId 0 : integer
	uuid 1 : string
	count 2 : integer
	power 3 : integer
}

.spawn {
	monsterId 0 : integer
	serverId 1 : integer
	posx 2 : integer
	posz 3 : integer

}

.LoadHero {
	serverId 0 : integer
	heroId 1 : integer
	name 2 : string
	color 3 : integer
}

.DropItem {
	itemId 0 : integer
	itemNum 1 : integer
	px 2 : integer
	pz 3 : integer
	sid 4 : integer
}
.CdItem {
	skillId 0 : integer
	time	1 : integer
}
]]

local c2s = [[

query_event_move 1 {		#query event stamp
	request {
		id 0 : integer
		type 1 : integer
		stamp 2 : integer
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
query_event_stats 4 {
	request {
		id 0 : integer
		type 1 : integer
		stamp 2 : integer
	}
	response {
		event_stamp 0 : EventStamp
		stats 1 : Stats
	}
}

query_event_hp_mp 5 {
	request {
		id 0 : integer
		type 1 : integer
		stamp 2 : integer
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
		id 0 : integer
		type 1 : integer
		stamp 2 : integer
	}
	response {
		event_stamp 0 : EventStamp
		buffLists 1 : *Buff
	}
}

query_event_affect 7 {
	request {
		id 0 : integer
		type 1 : integer
		stamp 2 : integer
	}
	response {
		event_stamp 0 : EventStamp
		affectList 1 : *Affect
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

loadingRes 112 {
	request {
		percent 0 : integer
	}
}

heart_beat_time 200{			#heartbeat,also for estimate ping time
	response {
	}
}

move 201 {			#client move
	request {
		x 0 : integer
		y 1 : integer
		z 2 : integer
	}
}

requestCastSkill 202 {
	request {
		skillid 0 : integer
	}
	response {
		errorcode 0 :integer
	}
}
lockTarget 203 {
	request {
		serverid 0 : integer
	}
	response {
		errorcode 0 : integer
	}
 }

usePickItem 204 {
	request {
		sid 0 : integer
	}
	response {
		errorCode 0 : integer
		sid 1 : integer
	}
}

upgradeSkill 205 {
	request {
		skillId 0 : integer
	}
	response {
		errorCode 0 : integer
		skillId 1 : integer
		level 2 : integer
	}
}

explore_goFight 300 {
	request {
		uuid 0 : string
		index 1 : integer
	}
	response {
		errorCode 0 :integer
	}
}

]]

local s2c = [[
enter_room 1 {
	request {
		server_id 0 : integer
	}
}
#下发卡牌数据
sendHero 2 {
	request {
		cardsList 0 : *card(uuid)
	}
}
#下发账户数据
sendAccount 3 {
	request {
		nick 0 : string
		gold 1 : integer
		money 2 : integer
		exp 3 : integer
		icon 4 : string
		flag 5 : integer
	}
}

#下发探索数据
sendExplore 4 {
	request {
		time 0 : integer
		uuid0 1 : string
		uuid1 2 : string
		uuid2 3 : string
		uuid3 4 : string
		uuid4 5 : string
	}
}

#下发CD数据
sendCDTime 5 {
	request {
		ResetCardPowertime 0 : integer
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
		roomId 0 : integer
		heroInfoList 1 : *LoadHero
		rb_sid 2 : integer
		bb_sid 3 : integer
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



#战斗相关消息定义
spawnMonsters 2001 {
	request {
		spawnList 0 : *spawn
	}
}

fightBegin 2002 {
}
addGoldExp 2003 {
	request {
		gold 0 : integer
		exp 1 : integer
		level 2 : integer
	}
}

makeDropItem 2004 {
	request {
		items 0 : *DropItem
	}
}

emitFlyObj 2005 {
	request {
		serverId 0 : integer
		effectId 1 : integer
		dirx 2  : string 
		dirz 3  : string
	}
}

pickDropItem 2006 {
	request {
		items 0 : *string
	}
}

killEntity 2007 {
	request {
		sid 0 : integer
	}
}

addSkill 2008 {
	request {
		skillId 0 : integer
		level 1 : integer
	}
}

makeSkillCds 2009 {
	request {
		items 0 : *CdItem
	}
}

raiseHero 2010 {
        request {
		sid 0 : integer
        }
}

delPickItem 2011 {
	request {
		item_sid 0 : integer
		user_sid 1 : integer
        }
}

CastingSkill 3001 {
	request {
		srcId 0 : integer
		skillId 1 : integer
		state	2 : integer
		actionTime 3 : integer
		targetId 4 : integer
		targetPos 5 : Vector3 
	}
}
]]

game_proto.types = sparser.parse (types)
game_proto.c2s = sparser.parse (types .. c2s)
game_proto.s2c = sparser.parse (types .. s2c)

return game_proto
