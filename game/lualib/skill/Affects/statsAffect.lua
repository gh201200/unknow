local Affect = require "skill.Affect.Affect"

local StrengthEffect = { 50,0,2,0,0,0,1,0, }
local MinjieEffect = { 0,0,2,0.5,0.05,1.2,0,0,}
local ZhiliEffect = { 0,30,2,0,0,0,0,1, }


local StatsAffect = class(StatsAffect ,Affect)

function StatsAffect:calcHpMax()
	self.owner:setHpMax(math.floor(
		self.owner.attDat.n32Hp * (1.0 + self.owner:getMidHpMaxPc()/GAMEPLAY_PERCENT)) 
		+ self.owner:getMidHpMax() 
		+ self.owner:getStrength() * StrengthEffect[1]
		+ self.owner:getZhili() * ZhiliEffect[1]
		+ self.owner:getMinjie() * MinjieEffect[1]
	)
end

function StatsAffect:calcMpMax()
	self.owner:setMpMax(math.floor(
		self.owner.attDat.n32Mp * (1.0 + self.owner:getMidMpMaxPc()/GAMEPLAY_PERCENT)) 
		+ self.owner:getMidMpMax() 
		+ self.owner:getStrength() * StrengthEffect[2]
		+ self.owner:getZhili() * ZhiliEffect[2]
		+ self.owner:getMinjie() * MinjieEffect[2]
	)
end

function StatsAffect:calcAttack()
	self.owner:setAttack(math.floor(
		self.owner.attDat.n32Attack * (1.0 + self.owner:getMidAttackPc()/GAMEPLAY_PERCENT)) 
		+ self.owner:getMidAttack() 
		+ self.owner:getStrength() * StrengthEffect[3]
		+ self.owner:getZhili() * ZhiliEffect[3]
		+ self.owner:getMinjie() * MinjieEffect[3]
	)
end

function StatsAffect:calcDefence()
	self.owner:setDefence(math.floor(
		self.owner.attDat.n32Defence * (1.0 + self.owner:getMidDefencePc()/GAMEPLAY_PERCENT)) 
		+ self.owner:getMidDefence() 
		+ self.owner:getStrength() * StrengthEffect[4]
		+ self.owner:getZhili() * ZhiliEffect[4]
		+ self.owner:getMinjie() * MinjieEffect[4]
	)
end

function StatsAffect:calcASpeed()
	self.owner:setASpeed(
		self.owner.attDat.n32ASpeed 
		+ self.owner:getMidASpeed() 
		+ self.owner:getStrength() * StrengthEffect[5]
		+ self.owner:getZhili() * ZhiliEffect[5]
		+ self.owner:getMinjie() * MinjieEffect[5]
	)
end

function StatsAffect:calcMSpeed()
	self.owner:setMSpeed(math.floor(
		self.owner.attDat.n32MSpeed * (1.0 + self.owner:getMSpeedPc()/GAMEPLAY_PERCENT))
		+ self.owner:getMidMSpeed() 
		+ self.owner:getStrength() * StrengthEffect[6]
		+ self.owner:getZhili() * ZhiliEffect[6]
		+ self.owner:getMinjie() * MinjieEffect[6]
	)
end

function StatsAffect:calcRecvHp()
	self.owner:setRecvHp(math.floor(
		self.owner.attDat.n32RecvHp * (1.0 + self.owner:getMidRecvHp()/GAMEPLAY_PERCENT))
		+ self.owner:getMidRecvHp()
		+ self.owner:getStrength() * StrengthEffect[7]
		+ self.owner:getZhili() * ZhiliEffect[7]
		+ self.owner:getMinjie() * MinjieEffect[7]
	)
end

function StatsAffect:calcRecvMp()
	self.owner:setRecvMp(math.floor(
		self.owner.attDat.n32RecvMp * (1.0 + self.owner:getMidRecvMp()/GAMEPLAY_PERCENT))
		+ self.owner:getMidRecvMp()
		+ self.owner:getStrength() * StrengthEffect[8]
		+ self.owner:getZhili() * ZhiliEffect[8]
		+ self.owner:getMinjie() * MinjieEffect[8]
	)
end

function StatsAffect:calcAttackRange()
	self.owner:setAttackRange(math.floor(
		self.owner.attDat.n32AttackRange * (1.0 +self.owner:getMidAttackRange()/GAMEPLAY_PERCENT))
		+ self.owner:getMidAttackRange()
	)
end

function StatsAffect:calcBaoji()
	self.owner:setBaojiRate(self.owner:getMidBaojiRate())
	self.owner:setBaojiTimes(self.owner:getMidBaojiTimes())
end

function StatsAffect:calcHit()
	self.owner:setHit(self.owner:getMidHit())
end

function StatsAffect:calcMiss()
	self.owner:setMiss(self.owner:getMidMiss())
end

function StatsAffect:onEnter()
	repeat
		local lzm = false
		if data[1] == 'up_str' then
			self.owner:addMidStrengthPc(data[2])
			self.owner:addMidStrength(data[3])
			self.effectTime = data[5]
			--calc strength again
			self.owner:setStrength(math.floor(
				math.floor((self.owner.attDat.n32Strength + self.owner.attDat.n32LStrength/GAMEPLAY_PERCENT * self.owner:getLevel()) 
				* (1.0 + self:getMidStrengthPc()/GAMEPLAY_PERCENT)) 
				+ self:getMidStrength())
			)
			lzm = true
		end
		if data[1] == 'up_dex' then
			self.owner:addMidMinjiePc(data[2])
			self.owner:addMidMinjie(data[3])
			self.effectTime = data[5]
			--calc minjie again
			self.owner:setMinjie(math.floor(
				math.floor((self.owner.attDat.n32Minjie + self.owner.attDat.n32LMinjie/GAMEPLAY_PERCENT * self.owner:getLevel()) 
				* (1.0 + self:getMidMinjiePc()/GAMEPLAY_PERCENT)) 
				+ self:getMidMinjie())
			)
			lzm = true
		end
		if data[1] == 'up_inte' then
			self.owner:addMidZhiliPc(data[2])
			self.owner:addMidZhiLi(data[3])
			self.effectTime = data[5]
			--calc zhili again
			self.owner:setZhili(math.floor(
				math.floor((self.owner.attDat.n32Zhili + self.owner.attDat.n32LZhili/GAMEPLAY_PERCENT * self.owner:getLevel()) 
				* (1.0 + self:getMidZhiliPc()/GAMEPLAY_PERCENT)) 
				+ self:getMidZhili())
			)
			lzm = true
		end
		if lzm then	
			--effect other stats
			self:calcHpMax()
			self:calcMpMax()
			self:calcAttack()
			self:calcDefence()
			self:calcASpeed()
			self:calcMSpeed()
			self:calcRecvHp()
			self:calcRecvMp()
			break
		end
		if data[1] == 'hp' then
			self.owner:addMidHpMaxPc(data[2])
			self.owner:addMidHpMax(data[3])
			self.effectTime = data[5]	
			self:calcHpMax()
			break
		end

		if data[1] == 'mp' then
			self.owner:addMidMpMaxPc(data[2])
			self.owner:addMidMpMax(data[3])
			self.effectTime = data[5]
			self:calcMpMax()
			break
		end
		
		if data[1] == 'atk' then
			self.owner:addMidAttackPc(data[2])
			self.owner:addMidAttack(data[3])
			self.effectTime = data[5]
			self:calcAttack()
			break
		end
		
		if data[1] == 'def' then
			self.owner:addMidDefencePc(data[2])
			self.owner:addMidDefence(data[3])
			self.effectTime = data[5]
			self:calcDefence()
			break
		end
		
		if data[1] == 'wsp' then
			self.owner:addMidASpeed(data[2])
			self.effectTime = data[4]
			self:calcASpeed()
			break
		end
	
		if data[1] == 'mov' then
			self.owner:addMidMSpeedPc(data[2])
			self.owner:addMidMSpeed(data[3])
			self.effectTime = data[5]
			self:calcMSpeed()
			break
		end
		
		if data[1] == 'rng' then
			self.owner:addMidAttackRangePc(data[2])
			self.owner:addMidAttackRange(data[3])
			self.effectTime = data[5]
			self:calcAttackRange()
			break
		end
		
		if data[1] == 're_hp' then
			self.owner:addMidRecvHpPc(data[2])
			self.owner:addMidRecvHp(data[3])
			self.effectTime = data[5]
			self:calcRecvHp()
			break
		end
		
		if data[1] == 're_mp' then
			self.owner:addMidRecvMpPc(data[2])
			self.owner:addMidRecvMp(data[3])
			self.effectTime = data[5]
			self:calcRecvMp()
			break
		end
		
		if data[1] == 'crit_rate' then
			self.owner:addMidBaojiRate(data[2])
			self.owner:addMidBaojiTimes(data[3])
			self.effectTime = data[5]
			self:calcBaoji()
			break
		end

		if data[1] == 'hit_rate' then
			self.owner:addMidHit(data[2])
			self.effectTime = data[4]
			self:calcHit()
			break
		end
	
		if data[1] == 'dod_rate' then
			self.owner:addMidMiss(data[2])
			self.effectTime = data[4]
			self:calcMiss()
			break
		end
	until true
	
	self.leftTime =  self.effectTime
end


function StatsAffect:onExit()
	repeat
		local lzm = false
		if data[1] == 'up_str' then
			self.owner:addMidStrengthPc(-data[2])
			self.owner:addMidStrength(-data[3])
			lzm = true
			break
		end
		if data[1] == 'up_dex' then
			self.owner:addMidMinjiePc(-data[2])
			self.owner:addMidMinjie(-data[3])
			lzm = true
			break
		end
		if data[1] == 'up_inte' then
			self.owner:addMidZhiliPc(-data[2])
			self.owner:addMidZhiLi(-data[3])
			lzm = true
			break
		end
		if lzm then	
			--effect other stats
			self:calcHpMax()
			self:calcMpMax()
			self:calcAttack()
			self:calcDefence()
			self:calcASpeed()
			self:calcMSpeed()
			self:calcRecvHp()
			self:calcRecvMp()
			break
		end

		if data[1] == 'hp' then
			self.owner:addMidHpMaxPc(-data[2])
			self.owner:addMidHpMax(-data[3])
			self:calcHpMax()
			break
		end

		if data[1] == 'mp' then
			self.owner:addMidMpMaxPc(-data[2])
			self.owner:addMidMpMax(-data[3])
			self:calcMpMax()
			break
		end
		
		if data[1] == 'atk' then
			self.owner:addMidAttackPc(-data[2])
			self.owner:addMidAttack(-data[3])
			self:calcAttack()
			break
		end
		
		if data[1] == 'def' then
			self.owner:addMidDefencePc(-data[2])
			self.owner:addMidDefence(-data[3])
			self:calcDefence()
			break
		end
		
		if data[1] == 'wsp' then
			self.owner:addMidASpeed(-data[2])
			self:calcASpeed()
			break
		end
	
		if data[1] == 'mov' then
			self.owner:addMidMSpeedPc(-data[2])
			self.owner:addMidMSpeed(-data[3])
			self:calcMSpeed()
			break
		end
		
		if data[1] == 'rng' then
			self.owner:addMidAttackRangePc(-data[2])
			self.owner:addMidAttackRange(-data[3])
			self:calcAttackRange()
			break
		end
		
		if data[1] == 're_hp' then
			self.owner:addMidRecvHpPc(-data[2])
			self.owner:addMidRecvHp(-data[3])
			self:calcRecvHp()
			break
		end
		
		if data[1] == 're_mp' then
			self.owner:addMidRecvMpPc(-data[2])
			self.owner:addMidRecvMp(-data[3])
			self:calcRecvMp()
			break
		end
		
		if data[1] == 'crit_rate' then
			self.owner:addMidBaojiRate(-data[2])
			self.owner:addMidBaojiTimes(-data[3])
			self:calcBaiji()
			break
		end

		if data[1] == 'hit_rate' then
			self.owner:addMidHit(-data[2])
			self:calcHit()
			break
		end
	
		if data[1] == 'dod_rate' then
			self.owner:addMidMiss(-data[2])
			self:calcMiss()
			break
		end
	until true

end


return StatsAffect
