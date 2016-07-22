local Affect = require "skill.Affect.Affect"


local StatsAffect = class(StatsAffect ,Affect)

function StatsAffect:onEnter()
	repeat
		if data[1] == 'up_str' then
			self.owner:addStrengthPc(data[2])
			self.owner:addStrength(data[3])
			self.effectTime = data[5]
			break
		end
		if data[1] == 'up_dex' then
			self.owner:addMinjiePc(data[2])
			self.owner:addMinjie(data[3])
			self.effectTime = data[5]
			break
		end
		if data[1] == 'up_inte' then
			self.owner:addZhiliPc(data[2])
			self.owner:addZhiLi(data[3])
			self.effectTime = data[5]
			break
		end
		if data[1] == 'hp' then
			self.owner:addHpMaxPc(data[2])
			self.owner:addHpMax(data[3])
			self.effectTime = data[5]
			break
		end

		if data[1] == 'mp' then
			self.owner:addMpMaxPc(data[2])
			self.owner:addMpMax(data[3])
			self.effectTime = data[5]
			break
		end
		
		if data[1] == 'atk' then
			self.owner:addAttackPc(data[2])
			self.owner:addAttack(data[3])
			self.effectTime = data[5]
			break
		end
		
		if data[1] == 'def' then
			self.owner:addDefencePc(data[2])
			self.owner:addDefence(data[3])
			self.effectTime = data[5]
			break
		end
		
		if data[1] == 'wsp' then
			self.owner:addASpeed(data[2])
			self.effectTime = data[4]
			break
		end
	
		if data[1] == 'mov' then
			self.owner:addMSpeedPc(data[2])
			self.owner:addMSpeed(data[3])
			self.effectTime = data[5]
			break
		end
		
		if data[1] == 'rng' then
			self.owner:addAttackRangePc(data[2])
			self.owner:addAttackRange(data[3])
			self.effectTime = data[5]
			break
		end
		
		if data[1] == 're_hp' then
			self.owner:addRecvHpPc(data[2])
			self.owner:addRecvHp(data[3])
			self.effectTime = data[5]
			break
		end
		
		if data[1] == 're_mp' then
			self.owner:addRecvMpPc(data[2])
			self.owner:addRecvMp(data[3])
			self.effectTime = data[5]
			break
		end
		
		if data[1] == 'crit_rate' then
			self.owner:addBaojiRate(data[2])
			self.owner:addBaojiTimes(data[3])
			self.effectTime = data[5]
			break
		end

		if data[1] == 'hit_rate' then
			self.owner:addHit(data[2])
			self.effectTime = data[4]
			break
		end
	
		if data[1] == 'dod_rate' then
			self.owner:addMiss(data[2])
			self.effectTime = data[4]
			break
		end
	until true
	
	self.leftTime =  self.effectTime
end


function StatsAffect:onExit()
	repeat
		if data[1] == 'up_str' then
			self.owner:addStrengthPc(-data[2])
			self.owner:addStrength(-data[3])
			break
		end
		if data[1] == 'up_dex' then
			self.owner:addMinjiePc(-data[2])
			self.owner:addMinjie(-data[3])
			break
		end
		if data[1] == 'up_inte' then
			self.owner:addZhiliPc(-data[2])
			self.owner:addZhiLi(-data[3])
			break
		end
		if data[1] == 'hp' then
			self.owner:addHpMaxPc(-data[2])
			self.owner:addHpMax(-data[3])
			break
		end

		if data[1] == 'mp' then
			self.owner:addMpMaxPc(-data[2])
			self.owner:addMpMax(-data[3])
			break
		end
		
		if data[1] == 'atk' then
			self.owner:addAttackPc(-data[2])
			self.owner:addAttack(-data[3])
			break
		end
		
		if data[1] == 'def' then
			self.owner:addDefencePc(-data[2])
			self.owner:addDefence(-data[3])
			break
		end
		
		if data[1] == 'wsp' then
			self.owner:addASpeed(-data[2])
			break
		end
	
		if data[1] == 'mov' then
			self.owner:addMSpeedPc(-data[2])
			self.owner:addMSpeed(-data[3])
			break
		end
		
		if data[1] == 'rng' then
			self.owner:addAttackRangePc(-data[2])
			self.owner:addAttackRange(-data[3])
			break
		end
		
		if data[1] == 're_hp' then
			self.owner:addRecvHpPc(-data[2])
			self.owner:addRecvHp(-data[3])
			break
		end
		
		if data[1] == 're_mp' then
			self.owner:addRecvMpPc(-data[2])
			self.owner:addRecvMp(-data[3])
			break
		end
		
		if data[1] == 'crit_rate' then
			self.owner:addBaojiRate(-data[2])
			self.owner:addBaojiTimes(-data[3])
			break
		end

		if data[1] == 'hit_rate' then
			self.owner:addHit(-data[2])
			break
		end
	
		if data[1] == 'dod_rate' then
			self.owner:addMiss(data[2])
			break
		end
	until true

end


return StatsAffect
