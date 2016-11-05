local Quest = {
	
	--初始赠送英雄
	AutoGainCards = {
		12011,
		11021,
		13031,
		13051,
		14051,
		14021,
	},
	
	--英雄体力（分钟）
	CARD_INIT_POWER = 600,	

	--探索配置表
	Explore = {
		CD = 3600,
		gains_num = 3,
		gains_num_wt = 0,
		gains_num_gr = 1,
		gains_num_bl = 2,
		gains_num_pu = 3,
		gains_num_or = 4,
		gains_num_money = 5,
		cost_money = 500,
		gains_free = {{10001, 1000},{10002, 2000},},
		gains_money = {{10001, 1000}, {10002, 2000},},
		power = 28800,
	},
	
	--金币升级技能表
	GoldSkillLv = {
		[1] = 200,
		[2] = 300,
		[3] = 400,
	},

		
	--技能最高等级
	SkillMaxLevel = 4,

	--英雄技能数量
	SkillMaxNum = 5,

	--同阵营金币分享百分比
	ShareGoldPercent = 0.4,
	
	--同阵营经验分享百分比
	ShareExpPercent = 0.67,

	--英雄复活时间系数(ms)
	RaiseTime = 3000,

	--英雄在基地恢复HP系数
	BuildingRecvHp = 20,
	
	--英雄在基地恢复MP系数
	BuildingRecvMp = 20,

	--可替换技能次数
	MaxReplaceSkillTimes = 3,

	--商城卡牌刷新CD(s)
	ShopCardCD = 8*60*60,
}





return Quest
