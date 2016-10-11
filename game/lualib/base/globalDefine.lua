EventStampType = {
	Move				= 0,
	CastSkill			= 1,
	Stats				= 2,
	Buff				= 3,
	Hp_Mp				= 4,
	Affect				= 5,
}


EntityType = {
	player				= 1,
	monster				= 2,
	building			= 3,
	flyObj				= 4,
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
	blink				= 8,
	forcemove			= 9,	--强制移动
}

HpMpMask = {
	SkillHp				= 1 << 0,
	BuffHp				= 1 << 1,
	TimeLineHp			= 1 << 2,
	RaiseHp				= 1 << 3,
	BuildingHp			= 1 << 4,

	SkillMp				= 1 << 16,
	BuffMp				= 1 << 17,
	TimeLineMp			= 1 << 18,
	RaiseMp				= 1 << 19,
	BuildingMp			= 1 << 20,
}
AffectState = {
	NoMove				= 1 << 0, --不能移动
	NoAttack			= 1 << 1, --不能普攻
	NoSpell				= 1 << 2, --不能放技能
	Invincible			= 1 << 3, --无敌状态
	OutSkill			= 1 << 4, --魔免状态
}
ErrorCode = {
	EC_None				= 0,	--没有错误
---------------技能-----------------
	EC_Spell_MpLow 			= 1000, --蓝量不够
	EC_Spell_SkillIdNotExit		= 1001, --技能id不存在
	EC_Spell_SkillIsRunning		= 1002, --技能正在释放
	EC_Spell_SkillIsInCd		= 1003, --技能在cd中
	EC_Spell_NoTarget		= 1005, --目标不存在
	EC_Spell_TargetOutDistance	= 1006, --目标距离过远
	EC_Spell_Controled		= 1007,	--被控制住了
	EC_Dead				= 1008,	--死亡
	EC_Spell_Unkonw			= 1999, --技能未知错误
}

CardColor = {
	White = 1,
	Green = 2,
	Blue = 3,
	Purple = 4,
	Orange = 5,
}

g_shareData = {}
g_entityManager = nil
GAMEPLAY_PERCENT = 10000

