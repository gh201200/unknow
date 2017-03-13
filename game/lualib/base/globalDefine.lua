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
	pet				= 5,
	trap				= 6,
}

CampType = {
	BAD = 1, 	--全部敌对
	KIND = 2, 	--全部和平
	MONSTER = 3,	--怪物
	RED = 4,	--红方
	BLUE = 5, 	--蓝方
}

ActionState = {
	stand				= 0,
	move				= 1,
	attack				= 2,	-- 
	spell				= 5,	-- 
	charge				= 6,	--
	idle				= 7,	--controled by buff 
	blink				= 8,
	die				= 9,	--死亡
	--大于100都属于强制移动状态
	forcemove			= 100,	--强制移动
	repel				= 101,	--击退
	chargeing			= 102,   --冲锋中
	chargeed			= 103,	--冲锋结束
	loved				= 104,  --魅惑
}

HpMpMask = {
	SkillHp				= 1 << 0,
	BuffHp				= 1 << 1,
	TimeLineHp			= 1 << 2,
	RaiseHp				= 1 << 3,
	BuildingHp			= 1 << 4,
	BaojiHp				= 1 << 5,

	SkillMp				= 1 << 16,
	BuffMp				= 1 << 17,
	TimeLineMp			= 1 << 18,
	RaiseMp				= 1 << 19,
	BuildingMp			= 1 << 20,
	XuelanMp			= 1 << 21,
	UpgradeHp			= 1 << 22,
	UpgradeMp			= 1 << 23,  
}
AffectState = {
	NoMove				= 1 << 0, --不能移动
	NoAttack			= 1 << 1, --不能普攻
	NoSpell				= 1 << 2, --不能放技能
	Invincible			= 1 << 3, --无敌状态
	OutSkill			= 1 << 4, --魔免状态
	NoDead				= 1 << 5, --不死状态
	GoldBody			= 1 << 6, --金身状态
	Loved				= 1 << 7, --魅惑状态
	Crit				= 1 << 8, --暴击状态
}



SpellStatus = {
	None 		= 0,	--无
	Begin 		= 1, 	--开始
	Ready 		= 2,	--吟唱
	Cast 		= 3,	--释放
	ChannelCast 	= 4,	--持续施法
	End 		= 5,	--结束
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
	EC_Spell_Camp_Enemy		= 1009, --不能对敌方释放该技能
	EC_Spell_Camp_Friend		= 1010, --不能对友方释放该技能
	EC_Spell_NoBuilding		= 1011, --不能使用技能攻击建筑物
	EC_Spell_ForceMoving		= 1012, --强制移动中
	EC_Spell_Unkonw			= 1999, --技能未知错误
}

CardColor = {
	White = 1,
	Green = 2,
	Blue = 3,
	Purple = 4,
	Orange = 5,
}

Quest = nil				--策划配置数据全局定义
DEF = nil				--服务器全局宏定义
g_shareData = nil
g_entityManager = nil
GAMEPLAY_PERCENT = 10000
NOW_SERVER_VERSION = '1.0.0.1'		--服务器版本号(xx.xx.xx.xxxx)

ActivitySysType = 
{
	ShopCardId1                 	= 0,    --金币商城道具id1
	ShopCardId2                	= 1,    --金币商城道具id2
	ShopCardId3                	= 2,    --金币商城道具id3
}

ActivityAccountType = 
{
	BuyShopCard0			= 1001,	--金币商城购买1次数
	BuyShopCard1			= 1002,	--金币商城购买2次数
	BuyShopCard2			= 1003,	--金币商城购买3次数
	PvpTimes			= 2001, --pvp参加场次
	PvpWinTimes			= 2002,	--pvp胜利场次
	RefreshExplore			= 3001,	--刷新探索次数
	BaoXiang0			= 4001, --宝箱1购买次数
	BaoXiang1			= 4002, --宝箱2购买次数
	BaoXiang2			= 4003, --宝箱3购买次数
	BaoXiang3			= 4004, --宝箱4购买次数
}

CoolDownSysType = 
{
	RefreshShopCard			= 1,	--刷新卡牌商店
}

CoolDownAccountType = 
{
	TimeLimitSale			= 1001, --限时特惠商品
}


