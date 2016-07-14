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

ErrorCode = {
	EC_None				= 0,	--没有错误
---------------技能-----------------
	EC_Spell_MpLow 			= 1000, --蓝量不够
	EC_Spell_SkillIdNotExit		= 1001, --技能id不存在
		
	EC_Spell_Unkonw			= 1999, --技能未知错误

}
g_shareData = {}
GAMEPLAY_PERCENT = 10000
