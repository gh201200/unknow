EventStampType = {
	Move				= 0,
	CastSkill			= 1,
}


EntityType = {
	player				= 1,
	monster				= 2,
	building			= 3,
}


ActionState = {
	stand				= 0,
	move				= 1,
	attack1				= 2,	--普攻第一段 
	attack2				= 3,	--普攻第二段 
	attack3				= 4,	--普攻第三段 	
	spell1				= 5,	--技能第一段 
	spell2				= 6,	--技能第二段
}

g_shareData = {}
GAMEPLAY_PERCENT = 10000
