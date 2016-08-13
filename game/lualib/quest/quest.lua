local Quest = {
	
	--初始赠送英雄
	AutoGainCards = {
		10001,
		10002,
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
}





return Quest
