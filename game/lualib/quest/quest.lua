local Quest = {
	
	--初始赠送的英雄
	AutoGainCards = {
		110001,
		120001,
		130001,
		130101,
		220001,
		230101,
		310001,
		210101,
		220101,
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

	--探索CD(s)
	ExploreTime = 2*60,

	--竞技场数据
	Arena = {
		[1] = {
			EloLimit = 0,					--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundPreview = "",		--竞技场预览图资源地址
			GoldReward = 50,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62001,			--每场战斗胜利之后的对应道具ID
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62002,			--每日任务完成之后的对应道具ID
			HeroPiecePackage = 60001,		--商城英雄碎片宝箱的对应道具ID
			AdvHeroPiecePackage = 60002,	--商城高阶英雄碎片宝箱的对应道具ID
			SkillCardPackage = 61001,		--商城技能卡牌宝箱的对应道具ID
			AdvSkillCardPackage = 61002,	--商城技能卡牌碎片宝箱的对应道具ID
			SpecialOffer = 50001,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {1120001, 1230101, 1310001,}, --解锁的英雄
			UnlockSkill = {12001001, 13001001, 21101001, 23001001, 31001001, 32001001, 12101001, 13002001, 23002001, 31101001, 32101001,}, --解锁的技能
		}, 
		[2] = {
			EloLimit = 400,					--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundPreview = "",		--竞技场预览图资源地址
			GoldReward = 60,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62011,			--每场战斗胜利之后的对应道具ID
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62012,			--每日任务完成之后的对应道具ID
			HeroPiecePackage = 60011,		--商城英雄碎片宝箱的对应道具ID
			AdvHeroPiecePackage = 60012,	--商城高阶英雄碎片宝箱的对应道具ID
			SkillCardPackage = 61011,		--商城技能卡牌宝箱的对应道具ID
			AdvSkillCardPackage = 61012,	--商城技能卡牌碎片宝箱的对应道具ID
			SpecialOffer = 50011,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {1130001, 1210101, 1320101,}, --解锁的英雄
			UnlockSkill = {12102001, 13003001, 21002001, 22002001, 31002001, 11002001, 23003001, 32002001,}, --解锁的技能
		}, 
		[3] = {
			EloLimit = 800,					--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundPreview = "",		--竞技场预览图资源地址
			GoldReward = 75,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62021,			--每场战斗胜利之后的对应道具ID
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62022,			--每日任务完成之后的对应道具ID
			HeroPiecePackage = 60021,		--商城英雄碎片宝箱的对应道具ID
			AdvHeroPiecePackage = 60022,	--商城高阶英雄碎片宝箱的对应道具ID
			SkillCardPackage = 61021,		--商城技能卡牌宝箱的对应道具ID
			AdvSkillCardPackage = 61022,	--商城技能卡牌碎片宝箱的对应道具ID
			SpecialOffer = 50021,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {1120101, 1230001, 1310101,}, --解锁的英雄
			UnlockSkill = {10004001, 10104001, 20104001, 30103001,}, --解锁的技能
		}, 
		[4] = {
			EloLimit = 1200,				--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundPreview = "",		--竞技场预览图资源地址
			GoldReward = 100,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62031,			--每场战斗胜利之后的对应道具ID
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62032,			--每日任务完成之后的对应道具ID
			HeroPiecePackage = 60031,		--商城英雄碎片宝箱的对应道具ID
			AdvHeroPiecePackage = 60032,	--商城高阶英雄碎片宝箱的对应道具ID
			SkillCardPackage = 61031,		--商城技能卡牌宝箱的对应道具ID
			AdvSkillCardPackage = 61032,	--商城技能卡牌碎片宝箱的对应道具ID
			SpecialOffer = 50031,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {1110101, 1220101, 1330101,}, --解锁的英雄
			UnlockSkill = {11003001, 13004001, 22102001, 23004001, 31003001, 32102001, 12103001, 21003001, 33002001,}, --解锁的技能
		}, 
		[5] = {
			EloLimit = 1600,				--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundPreview = "",		--竞技场预览图资源地址
			GoldReward = 150,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62041,			--每场战斗胜利之后的对应道具ID
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62042,			--每日任务完成之后的对应道具ID
			HeroPiecePackage = 60041,		--商城英雄碎片宝箱的对应道具ID
			AdvHeroPiecePackage = 60042,	--商城高阶英雄碎片宝箱的对应道具ID
			SkillCardPackage = 61041,		--商城技能卡牌宝箱的对应道具ID
			AdvSkillCardPackage = 61042,	--商城技能卡牌碎片宝箱的对应道具ID
			SpecialOffer = 50041,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {1130101, 1210101, 1320001,}, --解锁的英雄
			UnlockSkill = {11004001, 12002001, 21004001, 23005001, 13005001, 31004001,}, --解锁的技能
		}, 
		[6] = {
			EloLimit = 2000,				--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundPreview = "",		--竞技场预览图资源地址
			GoldReward = 250,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62051,			--每场战斗胜利之后的对应道具ID
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62052,			--每日任务完成之后的对应道具ID
			HeroPiecePackage = 60051,		--商城英雄碎片宝箱的对应道具ID
			AdvHeroPiecePackage = 60052,	--商城高阶英雄碎片宝箱的对应道具ID
			SkillCardPackage = 61051,		--商城技能卡牌宝箱的对应道具ID
			AdvSkillCardPackage = 61052,	--商城技能卡牌碎片宝箱的对应道具ID
			SpecialOffer = 50051,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {}, --解锁的英雄
			UnlockSkill = {22003001, 23006001, 31005001, 32003001, 32004001, 33003001, 11005001, 12104001, 33101001, 13006001,}, --解锁的技能
		}, 
		[7] = {
			EloLimit = 2400,				--分数下限
			BattleGroundID = 1,				--地图id
			BattleGroundPreview = "",		--竞技场预览图资源地址
			GoldReward = 400,				--每场战斗（无论输赢）之后的金币奖励
			GoldRewardLimit = 20,			--每日战斗获得金币奖励的次数上限
			VictoryReward = 62061,			--每场战斗胜利之后的对应道具ID
			VictoryRewardLimit = 15,		--每日战斗胜利获得道具奖励的次数上限
			DailyReward = 62062,			--每日任务完成之后的对应道具ID
			HeroPiecePackage = 60061,		--商城英雄碎片宝箱的对应道具ID
			AdvHeroPiecePackage = 60062,	--商城高阶英雄碎片宝箱的对应道具ID
			SkillCardPackage = 61061,		--商城技能卡牌宝箱的对应道具ID
			AdvSkillCardPackage = 61062,	--商城技能卡牌碎片宝箱的对应道具ID
			SpecialOffer = 50061,			--升级进入该竞技场之后，商城开启的特惠内容
			UnlockHero = {}, --解锁的英雄
			UnlockSkill = {}, --解锁的技能
		}, 
	}
}

return Quest
