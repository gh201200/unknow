EventStampType = {
	Move				= 0,
	CastSkill			= 1,
	Stats				= 2,
	Buff				= 3,
	Hp_Mp				= 4,
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
	idle				= 7,	--controled by buff 
}

HpMpMask = {
	SkillHp				= 1 << 0,
	BuffHp				= 1 << 1,
	TimeLineHp			= 1 << 2,

	SkillMp				= 1 << 16,
	BuffMp				= 1 << 17,
	TimeLineMp			= 1 << 18,
}

g_shareData = {}
GAMEPLAY_PERCENT = 10000
