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

.Vector2 {
	x 0 : integer
	y 1 : integer
}

.EventStamp {
	id 0 : integer
	type 1 : integer
	stamp 2 : integer 
}

.Stats {
	Strength 0 : integer
 	Agility 1 : integer
  	Intelligence 2 : integer
	HpMax 3 : integer
	MpMax 4 : integer
  	Attack 5 : integer
  	Defence 6 : integer
  	ASpeed 7 : integer
	exp 8 : integer
	gold 9 : integer
	level 10 : integer
}

.Buff {
	buffId 0 : integer
	count 1 : integer
	remainTime 2 : integer 
}

.effect {
	effectId 0 : integer
	effectTime 1 : integer
	srcServerId 2 : integer 
	mask 3 : integer
}
.Matcher {
	account 0 : string
	nickname 1 : string	
	color 2 : integer
}

.card {
	dataId 0 : integer
	uuid 1 : string
	count 2 : integer
	explore 3 : integer
	skill0 4 : integer
	skill1 5 : integer
	skill2 6 : integer
	skill3 7 : integer
	skill4 8 : integer
	skill5 9 : integer
	skill6 10 : integer
	skill7 11 : integer
}

.Skill {
	dataId 0 : integer
	uuid 1 : string
	count 2 : integer
}

.Mission {
	dataId 0 : integer
	progress 1 : integer                                                                                
    	flag 2 : integer
	time 3 : integer
}

.spawn {
	monsterId 0 : integer
	serverId 1 : integer
	posx 2 : integer
	posz 3 : integer

}

.pet {
	petId 0 : integer
	serverId 1 : integer
	posx 2 : integer
	posz 3 : integer
	camp 4 : integer
	masterId 5 : integer
}
.LoadHero {
	serverId 0 : integer
	heroId 1 : integer
	name 2 : string
	color 3 : integer
	posx 4 : integer
	posz 5 : integer
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

.CoolDown {
	key 0 : string
	val 1 : integer
}

.Activity {
	accountId 0 : string
        atype 1 : integer
        value 2 : integer 
}

.RankItem {
	head 0 : string
	nick 1 : string
	factionicon 2 : string
	factionname 3 : string
	score 4 : integer
}

.BattleResult {
	result 0 : integer
	score 1 : integer
	beDamage 2 : integer
	damage 3 : integer
	kills 4 : integer
	deads 5 : integer
	helps 6 : integer
	items 7 : *Vector2
	gold 8 : integer
	accountid 9 : string
	serverid 10 : integer
	skills 11 : *Vector2
}

.MailItem {
	uuid 0 : string
	title 1 : string
	content	2 : string
	sender 3 :string
	items 4 : string
	flag 5 : integer
	time 6 : integer
}

.Explore {
	dataId 0 : integer
	uuid0 1 : string
	uuid1 2 : string
	uuid2 3 : string
	att0 4 : integer
	cam0 5 : integer
	att1 6 : integer
	cam1 7 : integer
	att2 8 : integer
	cam2 9 : integer
	time 10 : integer
	uuid  11 : string
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
		n32Shield 3 : integer
		mask 4 : integer
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

create 100 {
         request {
                 name 0 : string    
                 client_pub 1 : string         
         }
         response {
		 error_id 0 : integer
         }
}

login 101 {
         request {
                 name 0 : string    
                 client_pub 1 : string         
         }
         response {
		 error_id 0 : integer
         }
}

enterGame 102 {
	request {
	}
}

requestMatch 103 {
	request {
	}
}

cancelMatch 104 {
	request {
	}
	response {
		errorcode 0 : integer
	}
}

requestFightRecords 105 
{
	request {
	}
	response {
		records 0 : *string
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
		skillid 1 : integer
	}
}

lockTarget 203 {
	request {
		serverid 0 : integer
	}
}

usePickItem 204 {
	request {
		sid 0 : integer
		x1 1 : integer
		y1 2 : integer
		x2 3 : integer
		y2 4 : integer
	}
	response {
		errorCode 0 : integer
		x1 1 : integer
		y1 2 : integer
		x2 3 : integer
		y2 4 : integer
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

replaceSkill 206 {
	request {
		sid 0 : integer
		skillId 1 : integer
	}
	response {
		errorCode 0 : integer
		skillId 1 : integer
		beSkillId 2 : integer
	}
}

explore_goFight 300 {
	request {
		uuid 0 : string
		index 1 : integer
		expuuid 2 : string
	}
	response {
		errorCode 0 :integer
		uuid 1 : string
		index 2 : integer
		expuuid 3 : string
	}
}

upgradeCardColorLevel 301 {
	request {                                                             
		uuid 0 : string                                       
	}                                                                     
	response {                                                            
		errorCode 0 :integer
		uuid 1 : string
	}       
}

clientGMcmd 302 {
	request {                                                             
		gmcmd 0 : string
		params 1 : *string
	}                                                                        
}

buyShopItem 303 {
	request {                                                             
		id 0 : integer     
		num 1 : integer  
	}                                                                     
	response {                                                            
		errorCode 0 :integer
		shopId 1 : integer
		ids 2 : *integer
	} 
}

updateCDData 304 {
	request {                                                             
		uid 0 : string       
	}	
	response {                                                            
		uid 0 : string
       		value 1 : integer 
	}                                                                     
}

updateActivityData 305 {
	request {                                                             
		uid 0 : string       
	}                                                                     
	response {                                                            
		uid 0 : string
       		value 1 : integer 
		time 2 : integer
	} 
}

updateMissionData 306 {
	request {                                                             
		dataId 0 : integer       
	} 
}

recvMissionAward 307 {
	request {                                                             
		dataId 0 : integer
	}                                                                     
	response {                                                            
		errorCode 0 :integer
		dataId 1 : integer
		ids 2 : *Vector2
	} 
}

reEnterRoom 3006 {
	request { 
		isin 0 : boolean
	}
	response {                                                            
		errorCode 0 : integer
	}
}

exploreBegin 3007 {
	request {
		uuid 0 : string
		uuid0 1 : string
		uuid1 2 : string
		uuid2 3 : string
	}
	response {                                                            
		errorCode 0 : integer
		uuid 1 : string
	} 
}

exploreEnd 3008 {
	request {
		uuid 0 : string
	}
	response {                                                            
		errorCode 0 : integer
		uuid 1 : string
		items 2 : *Vector2
	} 
}

strengthSkill 3009 {
	request {                                                             
		uuid 0 : string                                       
	}                                                                     
	response {                                                            
		errorCode 0 :integer
		uuid 1 : string
	}
}

bindSkill 3010 {
	request {                                                             
		uuidcard 0 : string
		uuidskill 1 : string
		slot 2 : integer
	}                                                                     
	response {                                                            
		errorCode 0 :integer
		uuidcard 1 : string
		uuidskill 2 : string
		slot 3 : integer
	}
}

reqTopRank 3011 {
	request {      
		atype 0 : integer
		start 1 : integer
		num 2 : integer
	}
	response {     
		atype 0 : integer
		items 1 : *RankItem
	}
}

givePlayerStar 3012 {
	request {      
		accountid 0 : string
	}
}

readMail 3013 {
	request {      
		uuid 0 : string
	}
}


recvMailItems 3014 {
	request {      
		uuid 0 : string
	}
	response {    
		errorCode 0 : integer 
		uuid 1 : string
		items 2 : *Vector2
	}
}

exploreRefresh 3015 {
	request {
		uuid 0 : string
	}
	response {
		errorCode 0 : integer 
		uuid 1 : string
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
		topexp 6 : integer
		star 7 : integer
		aexp 8 : integer
		exploretimes 9 : integer
		buyboxtimes 10 : integer
		refreshtime 11 : integer
	}
}

#下发探索数据
sendExplore 4 {
	request {
		exploresList 0 : *Explore(uuid)
	}
}

#下发CD数据
sendCDTime 5 {
	request {
		cds 0 : *CoolDown
	}	
}

#下发活动数据
sendActivity 6 {
	request {
		activitys 0 : *Activity
	}
}

#下发技能数据
sendSkill 7 {
	request {
		skillsList 0 : *Skill(uuid)
	}
}

#下发任务数据                                                                                          
sendMission 8 {                                                                                          
	request {                                                                                      
        	missionsList 0 : *Mission                                                             
	}                                                                                              
}

#下发邮件数据                                                                                          
sendMail 9 {                                                                                          
	request {                                                                                      
        	mailsList 0 : *MailItem(uuid)                                                      
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

requestPickHero 105 {
	 request {
		errorcode 0 : integer
		matcherNum 1 : integer
		matcherList 2 : *Matcher
        }
}


#战斗相关消息定义
spawnMonsters 2001 {
	request {
		spawnList 0 : *spawn
	}
}

fightBegin 2002 {
	request {
		resttime 0 : integer 
	}
}
addGoldExp 2003 {
	request {
		gold 0 : integer
		exp 1 : integer
		level 2 : integer
		sid 3 : integer
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
		targetId 1 : integer
		effectId 2 : integer
		dirx 3  : string 
		dirz 4  : string
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
		attackNum 4 : integer
		targetId 5 : integer
		targetPos 6 : Vector3 
	}
}

setPosition 3002 {
	request {
		srcId 0: integer
		targetPos 1: Vector3
	}
}

summonPet 3003 {
	request {
		pet 0 : pet
	}
}

pushEffect 3004 {
	request {
		acceperId 0 : integer
		producerId 1 : integer
		effectId 2 : integer
		effectTime 3 : integer
		flag 4 : integer
		posX 5 : string
		posZ 6: string
		dirX 7 : string
		dirZ 8: string
	}
}

battleOver 3005 {
	request {
		accounts 0 : *BattleResult
	}
}

reEnterRoom 3006 {
	request { 
		isin 0 : boolean
	}
}

reSendSkills 3007 {
	request { 
		skills 0 : *Vector2
	}
}

reSendHaveItems 3008 {
	request { 
		items 0 : *Vector2
	}
}

pushForceMove 3009 {
	request {
		id 0 : integer
		action 1 : integer
		dstX 2 : integer
		dstZ 3 : integer
		dirX 4 : integer
		dirZ 5 : integer
		speed 6 : integer
	}
}
]]

game_proto.types = sparser.parse (types)
game_proto.c2s = sparser.parse (types .. c2s)
game_proto.s2c = sparser.parse (types .. s2c)

return game_proto
