local Quest = {
	
	--初始赠送的英雄
	AutoGainCards = {
		110001,
		110101,
		120001,
		120101,
		130001,
		130101,
		210001,
		210101,
		220001,
		220101,
		230001,
		230101,
		310001,
		310101,
		320001,
		320101,
		330001,
		330101,
	},
	
	--初始赠送的技能
	AutoGainSkills = {
		10001001,
		10002001,
		10003001,
		10004001,
		10101001,
		10102001,
		11001001,
		11101001,
		20001001,
		20002001,
		20101001,
		20102001,
		20103001,
		20104001,
		22001001,
		22101001,
		30001001,
		30002001,
		30003001,
		30004001,
		30101001,
		30102001,
		31001001,
		31003001,
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
	RaiseTime = 1000,

	--英雄在基地恢复HP系数
	BuildingRecvHp = 20,
	
	--英雄在基地恢复MP系数
	BuildingRecvMp = 20,

	--可替换技能次数
	MaxReplaceSkillTimes = 3,

	--免费刷新探索次数
	RefreshExploreTimes = 3,
	
	--探索花费钻石
	RefreshExploreCost = 20,
	
	--每日任务初始id
	DailyMissionId = 10001001,
	
	--成就初始系列id
	AchivementsId = {
		20002,
		20013,
		21001,
		21018,
	},
	
	--任务内容
	MissionContent = {
		WinFight 			= 1001,		--累计获得x局胜利
		GetCard				= 1002,		--累计收集大于某个品质的英雄x个（条件1品质，目标个数）
		GetSkill			= 1003,		--累计收集某个星级的技能x个（条件1星级，目标个数）
		UpgradeSkill		= 1004,		--升级某个星级的技能到x阶（条件1星级，目标阶数）
		WinWithHero			= 1005,		--使用指定英雄获胜x次（条件1英雄系列id，目标次数）
		Kills				= 1006,		--累计完成x次击杀
		Deads				= 1007,		--累计完成x次死亡
	},
	
	--刷新商城卡牌CD(s)
	RefreshShopCardCD = 60,
	
	--排行榜类型
	RankType = {
		Exp					= 1001,		--竞技场积分
	},
	
	--收集数据
	CollectionData = {
		Hero = 18,	--英雄收集上限
		Skill = 78,	--技能收集上限
	},
	
	--碎片经验产出
	ChipsExp = {
		Card = 10,	--英雄碎片
		Skill1 = 2, --1星技能
		Skill2 = 10, --2星技能
		Skill3 = 50, --3星技能
	},

	--说明文字
	IllustrationContent = {
		HeroQuality = {
			[1] = "普通",
			[2] = "稀有",
			[3] = "罕见",
			[4] = "史诗",
			[5] = "传奇",
		}, 
		HeroCamp = {
			[1] = "赫里斯教会", 
			[2] = "珀尔瑟联盟",  
			[4] = "克鲁格财团", 
		}, 
	},
	--竞技场数据
	Arena = {
		[1] = {
			Name = "一阶竞技场",			--竞技场名称
			EloLimit = 0,					--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundName = "漫雾雨林",--地图名称
			BattleGroundPreview = "UI/Textures/Arenas/Arena001.png",		--竞技场预览图资源地址
			GoldReward = 50,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62001,			--每场战斗胜利之后的对应道具ID
			VictoryRewardInfo = {1,0,2,},	--战斗胜利宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62002,			--每日任务完成之后的对应道具ID
			DailyRewardInfo = {5,0,8,},		--每日任务宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			HeroPiecePackage = 60001,		--商城英雄碎片宝箱的对应道具ID
			HeroPiecePInfo = {30,0,0,},		--英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvHeroPiecePackage = 60002,	--商城高阶英雄碎片宝箱的对应道具ID
			AdvHeroPiecePInfo = {150,0,0,},	--高阶英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SkillCardPackage = 61001,		--商城技能卡牌宝箱的对应道具ID
			SkillCardPInfo = {0,5,43,},		--技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvSkillCardPackage = 61002,	--商城高阶技能卡牌宝箱的对应道具ID
			AdvSkillCardPInfo = {0,32,256,},	--高阶技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SpecialOffer = 50001,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {120001, 230101, 310001,}, --解锁的英雄
			UnlockSkill = {12001001, 13001001, 21101001, 23001001, 31001001, 32001001, 12101001, 13002001, 23002001, 31101001, 32101001,}, --解锁的技能
		}, 
		[2] = {
			Name = "二阶竞技场",			--竞技场名称
			EloLimit = 400,					--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundName = "废弃矿井",	--地图名称
			BattleGroundPreview = "UI/Textures/Arenas/Arena002.png",		--竞技场预览图资源地址
			GoldReward = 60,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62011,			--每场战斗胜利之后的对应道具ID
			VictoryRewardInfo = {2,0,2,},	--战斗胜利宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62012,			--每日任务完成之后的对应道具ID
			DailyRewardInfo = {7,0,9,},		--每日任务宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			HeroPiecePackage = 60011,		--商城英雄碎片宝箱的对应道具ID
			HeroPiecePInfo = {42,0,0,},		--英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvHeroPiecePackage = 60012,	--商城高阶英雄碎片宝箱的对应道具ID
			AdvHeroPiecePInfo = {210,0,0,},	--高阶英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SkillCardPackage = 61011,		--商城技能卡牌宝箱的对应道具ID
			SkillCardPInfo = {0,6,48,},		--技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvSkillCardPackage = 61012,	--商城高阶技能卡牌宝箱的对应道具ID
			AdvSkillCardPInfo = {0,40,284,},	--高阶技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SpecialOffer = 50011,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {130001, 210101, 320101,}, --解锁的英雄
			UnlockSkill = {12102001, 13003001, 21002001, 22002001, 31002001, 11002001, 23003001, 32002001,}, --解锁的技能
		}, 
		[3] = {
			Name = "三阶竞技场",			--竞技场名称
			EloLimit = 800,					--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundName = "熔炉车间",	--地图名称
			BattleGroundPreview = "UI/Textures/Arenas/Arena003.png",		--竞技场预览图资源地址
			GoldReward = 75,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62021,			--每场战斗胜利之后的对应道具ID
			VictoryRewardInfo = {2,0,2,},	--战斗胜利宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62022,			--每日任务完成之后的对应道具ID
			DailyRewardInfo = {8,0,10,},	--每日任务宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			HeroPiecePackage = 60021,		--商城英雄碎片宝箱的对应道具ID
			HeroPiecePInfo = {48,0,0,},		--英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvHeroPiecePackage = 60022,	--商城高阶英雄碎片宝箱的对应道具ID
			AdvHeroPiecePInfo = {240,0,0,},	--高阶英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SkillCardPackage = 61021,		--商城技能卡牌宝箱的对应道具ID
			SkillCardPInfo = {0,7,53,},		--技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvSkillCardPackage = 61022,	--商城高阶技能卡牌宝箱的对应道具ID
			AdvSkillCardPInfo = {0,46,314,},	--高阶技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SpecialOffer = 50021,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {120101, 230001, 310101,}, --解锁的英雄
			UnlockSkill = {10004001, 10104001, 20104001, 30103001,}, --解锁的技能
		}, 
		[4] = {
			Name = "四阶竞技场",			--竞技场名称
			EloLimit = 1200,				--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundName = "极地冰原",	--地图名称
			BattleGroundPreview = "UI/Textures/Arenas/Arena004.png",		--竞技场预览图资源地址
			GoldReward = 100,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62031,			--每场战斗胜利之后的对应道具ID
			VictoryRewardInfo = {2,0,3,},	--战斗胜利宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62032,			--每日任务完成之后的对应道具ID
			DailyRewardInfo = {9,0,11,},	--每日任务宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			HeroPiecePackage = 60031,		--商城英雄碎片宝箱的对应道具ID
			HeroPiecePInfo = {54,0,0,},		--英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvHeroPiecePackage = 60032,	--商城高阶英雄碎片宝箱的对应道具ID
			AdvHeroPiecePInfo = {270,0,0,},	--高阶英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SkillCardPackage = 61031,		--商城技能卡牌宝箱的对应道具ID
			SkillCardPInfo = {0,8,58,},		--技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvSkillCardPackage = 61032,	--商城高阶技能卡牌宝箱的对应道具ID
			AdvSkillCardPInfo = {0,52,344,},	--高阶技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SpecialOffer = 50031,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {110101, 220101, 330101,}, --解锁的英雄
			UnlockSkill = {11003001, 13004001, 22102001, 23004001, 31003001, 32102001, 12103001, 21003001, 33002001,}, --解锁的技能
		}, 
		[5] = {
			Name = "五阶竞技场",			--竞技场名称
			EloLimit = 1600,				--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundName = "发射台旧址",	--地图名称
			BattleGroundPreview = "UI/Textures/Arenas/Arena005.png",		--竞技场预览图资源地址
			GoldReward = 150,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62041,			--每场战斗胜利之后的对应道具ID
			VictoryRewardInfo = {3,0,3,},	--战斗胜利宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62042,			--每日任务完成之后的对应道具ID
			DailyRewardInfo = {10,0,13,},	--每日任务宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			HeroPiecePackage = 60041,		--商城英雄碎片宝箱的对应道具ID
			HeroPiecePInfo = {60,0,0,},		--英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvHeroPiecePackage = 60042,	--商城高阶英雄碎片宝箱的对应道具ID
			AdvHeroPiecePInfo = {300,0,0,},	--高阶英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SkillCardPackage = 61041,		--商城技能卡牌宝箱的对应道具ID
			SkillCardPInfo = {0,9,69,},		--技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvSkillCardPackage = 61042,	--商城高阶技能卡牌宝箱的对应道具ID
			AdvSkillCardPInfo = {0,62,402,},	--高阶技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SpecialOffer = 50041,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {130101, 210101, 320001,}, --解锁的英雄
			UnlockSkill = {11004001, 12002001, 21004001, 23005001, 13005001, 31004001,}, --解锁的技能
		}, 
		[6] = {
			Name = "六阶竞技场",			--竞技场名称
			EloLimit = 2000,				--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundName = "中心体育馆",	--地图名称
			BattleGroundPreview = "UI/Textures/Arenas/Arena006.png",		--竞技场预览图资源地址
			GoldReward = 250,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62051,			--每场战斗胜利之后的对应道具ID
			VictoryRewardInfo = {3,0,4,},	--战斗胜利宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62052,			--每日任务完成之后的对应道具ID
			DailyRewardInfo = {11,0,15,},	--每日任务宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			HeroPiecePackage = 60051,		--商城英雄碎片宝箱的对应道具ID
			HeroPiecePInfo = {66,0,0,},		--英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvHeroPiecePackage = 60052,	--商城高阶英雄碎片宝箱的对应道具ID
			AdvHeroPiecePInfo = {330,0,0,},	--高阶英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SkillCardPackage = 61051,		--商城技能卡牌宝箱的对应道具ID
			SkillCardPInfo = {0,10,80,},		--技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvSkillCardPackage = 61052,	--商城高阶技能卡牌宝箱的对应道具ID
			AdvSkillCardPInfo = {0,72,468,},	--高阶技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SpecialOffer = 50051,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {}, --解锁的英雄
			UnlockSkill = {22003001, 23006001, 31005001, 32003001, 32004001, 33003001, 11005001, 12104001, 33101001, 13006001,}, --解锁的技能
		}, 
		[7] = {
			Name = "七阶竞技场",			--竞技场名称
			EloLimit = 2400,				--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundName = "列沃德广场",	--地图名称
			BattleGroundPreview = "UI/Textures/Arenas/Arena007.png",		--竞技场预览图资源地址
			GoldReward = 400,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62051,			--每场战斗胜利之后的对应道具ID
			VictoryRewardInfo = {3,0,4,},	--战斗胜利宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62052,			--每日任务完成之后的对应道具ID
			DailyRewardInfo = {12,0,17,},	--每日任务宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			HeroPiecePackage = 60051,		--商城英雄碎片宝箱的对应道具ID
			HeroPiecePInfo = {72,0,0,},		--英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvHeroPiecePackage = 60052,	--商城高阶英雄碎片宝箱的对应道具ID
			AdvHeroPiecePInfo = {360,0,0,},	--高阶英雄碎片宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SkillCardPackage = 61051,		--商城技能卡牌宝箱的对应道具ID
			SkillCardPInfo = {0,12,90,},		--技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			AdvSkillCardPackage = 61052,	--商城高阶技能卡牌宝箱的对应道具ID
			AdvSkillCardPInfo = {0,84,528,},	--高阶技能卡牌宝箱对应的奖励内容{英雄碎片数,2星技能数,1星技能数}
			SpecialOffer = 50061,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {}, --解锁的英雄
			UnlockSkill = {}, --解锁的技能
		}, 
	}
}

return Quest
