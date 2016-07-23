local Affect = require "skill.Affect.Affect"

local StatsAffect = class(StatsAffect ,Affect)


function StatsAffect:onEnter()
	repeat
		local lzm = false
		if data[1] == 'up_str' then
			self.owner:addMidStrengthPc(data[2])
			self.owner:addMidStrength(data[3])
			self.effectTime = data[5]
			--calc strength again
			self.owner:calcStrength()
			lzm = true
		end
		if data[1] == 'up_dex' then
			self.owner:addMidMinjiePc(data[2])
			self.owner:addMidMinjie(data[3])
			self.effectTime = data[5]
			--calc minjie again
			self.owner:calcMinjie()
			lzm = true
		end
		if data[1] == 'up_inte' then
			self.owner:addMidZhiliPc(data[2])
			self.owner:addMidZhiLi(data[3])
			self.effectTime = data[5]
			--calc zhili again
			self.owner:calcZhili()
			lzm = true
		end
		if lzm then	
			--effect other stats
			self.owner:calcHpMax()
			self.owner:calcMpMax()
			self.owner:calcAttack()
			self.owner:calcDefence()
			self.owner:calcASpeed()
			self.owner:calcMSpeed()
			self.owner:calcRecvHp()
			self.owner:calcRecvMp()
			break
		end
		if data[1] == 'hp' then
			self.owner:addMidHpMaxPc(data[2])
			self.owner:addMidHpMax(data[3])
			self.effectTime = data[5]	
			self.owner:calcHpMax()
			break
		end

		if data[1] == 'mp' then
			self.owner:addMidMpMaxPc(data[2])
			self.owner:addMidMpMax(data[3])
			self.effectTime = data[5]
			self.owner:calcMpMax()
			break
		end
		
		if data[1] == 'atk' then
			self.owner:addMidAttackPc(data[2])
			self.owner:addMidAttack(data[3])
			self.effectTime = data[5]
			self.owner:calcAttack()
			break
		end
		
		if data[1] == 'def' then
			self.owner:addMidDefencePc(data[2])
			self.owner:addMidDefence(data[3])
			self.effectTime = data[5]
			self.owner:calcDefence()
			break
		end
		
		if data[1] == 'wsp' then
			self.owner:addMidASpeed(data[2])
			self.effectTime = data[4]
			self.owner:calcASpeed()
			break
		end
	
		if data[1] == 'mov' then
			self.owner:addMidMSpeedPc(data[2])
			self.owner:addMidMSpeed(data[3])
			self.effectTime = data[5]
			self.owner:calcMSpeed()
			break
		end
		
		if data[1] == 'rng' then
			self.owner:addMidAttackRangePc(data[2])
			self.owner:addMidAttackRange(data[3])
			self.effectTime = data[5]
			self.owner:calcAttackRange()
			break
		end
		
		if data[1] == 're_hp' then
			self.owner:addMidRecvHpPc(data[2])
			self.owner:addMidRecvHp(data[3])
			self.effectTime = data[5]
			self.owner:calcRecvHp()
			break
		end
		
		if data[1] == 're_mp' then
			self.owner:addMidRecvMpPc(data[2])
			self.owner:addMidRecvMp(data[3])
			self.effectTime = data[5]
			self.owner:calcRecvMp()
			break
		end
		
		if data[1] == 'crit_rate' then
			self.owner:addMidBaojiRate(data[2])
			self.owner:addMidBaojiTimes(data[3])
			self.effectTime = data[5]
			self.owner:calcBaoji()
			break
		end

		if data[1] == 'hit_rate' then
			self.owner:addMidHit(data[2])
			self.effectTime = data[4]
			self.owner:calcHit()
			break
		end
	
		if data[1] == 'dod_rate' then
			self.owner:addMidMiss(data[2])
			self.effectTime = data[4]
			self.owner:calcMiss()
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
			--calc strength again
			self.owner:calcStrength()
			lzm = true
			break
		end
		if data[1] == 'up_dex' then
			self.owner:addMidMinjiePc(-data[2])
			self.owner:addMidMinjie(-data[3])
			--calc minjie again
			self.owner:calcMinjie()
			lzm = true
			break
		end
		if data[1] == 'up_inte' then
			self.owner:addMidZhiliPc(-data[2])
			self.owner:addMidZhiLi(-data[3])
			--calc zhili again
			self.owner:calcZhili()
			lzm = true
			break
		end
		if lzm then	
			--effect other stats
			self.owner:calcHpMax()
			self.owner:calcMpMax()
			self.owner:calcAttack()
			self.owner:calcDefence()
			self.owner:calcASpeed()
			self.owner:calcMSpeed()
			self.owner:calcRecvHp()
			self.owner:calcRecvMp()
			break
		end

		if data[1] == 'hp' then
			self.owner:addMidHpMaxPc(-data[2])
			self.owner:addMidHpMax(-data[3])
			self.owner:calcHpMax()
			break
		end

		if data[1] == 'mp' then
			self.owner:addMidMpMaxPc(-data[2])
			self.owner:addMidMpMax(-data[3])
			self.owner:calcMpMax()
			break
		end
		
		if data[1] == 'atk' then
			self.owner:addMidAttackPc(-data[2])
			self.owner:addMidAttack(-data[3])
			self.owner:calcAttack()
			break
		end
		
		if data[1] == 'def' then
			self.owner:addMidDefencePc(-data[2])
			self.owner:addMidDefence(-data[3])
			self.owner:calcDefence()
			break
		end
		
		if data[1] == 'wsp' then
			self.owner:addMidASpeed(-data[2])
			self.owner:calcASpeed()
			break
		end
	
		if data[1] == 'mov' then
			self.owner:addMidMSpeedPc(-data[2])
			self.owner:addMidMSpeed(-data[3])
			self.owner:calcMSpeed()
			break
		end
		
		if data[1] == 'rng' then
			self.owner:addMidAttackRangePc(-data[2])
			self.owner:addMidAttackRange(-data[3])
			self.owner:calcAttackRange()
			break
		end
		
		if data[1] == 're_hp' then
			self.owner:addMidRecvHpPc(-data[2])
			self.owner:addMidRecvHp(-data[3])
			self.owner:calcRecvHp()
			break
		end
		
		if data[1] == 're_mp' then
			self.owner:addMidRecvMpPc(-data[2])
			self.owner:addMidRecvMp(-data[3])
			self.owner:calcRecvMp()
			break
		end
		
		if data[1] == 'crit_rate' then
			self.owner:addMidBaojiRate(-data[2])
			self.owner:addMidBaojiTimes(-data[3])
			self.owner:calcBaiji()
			break
		end

		if data[1] == 'hit_rate' then
			self.owner:addMidHit(-data[2])
			self.owner:calcHit()
			break
		end
	
		if data[1] == 'dod_rate' then
			self.owner:addMidMiss(-data[2])
			self.owner:calcMiss()
			break
		end
	until true

end


return StatsAffect
