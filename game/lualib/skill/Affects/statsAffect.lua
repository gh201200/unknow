local Affect = require "skill.Affects.Affect"
local StatsAffect = class("StatsAffect" ,Affect)
function StatsAffect:ctor(entity,source,data)
        self.super.ctor(self,entity,source,data)
	self.effectId = self.data[5] or 0
	self.effectTime = self.data[4] or 0
end
function StatsAffect:onEnter()
	self.super.onEnter(self)
	repeat
		local lzm = false
		if self.data[1] == 'ctrl' then
			self.owner.controledState = bit_or(self.owner.controledState, self.data[2]) -- 控制类型
		end
		if self.data[1] == 'up_str' then
			self.owner:addMidStrengthPc(self.data[2])
			self.owner:addMidStrength(self.data[3])
			self.effectTime = self.data[4]
			--calc strength again
			self.owner:calcStrength()
			lzm = true
		end
		if self.data[1] == 'up_dex' then
			self.owner:addMidMinjiePc(self.data[2])
			self.owner:addMidMinjie(self.data[3])
			self.effectTime = self.data[4]
			--calc minjie again
			self.owner:calcMinjie()
			lzm = true
		end
		if self.data[1] == 'up_inte' then
			self.owner:addMidZhiliPc(self.data[2])
			self.owner:addMidZhiLi(self.data[3])
			self.effectTime = self.data[4]
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
		if self.data[1] == 'hp' then
			self.owner:addMidHpMaxPc(self.data[2])
			self.owner:addMidHpMax(self.data[3])
			self.effectTime = self.data[4]	
			self.owner:calcHpMax()
			break
		end

		if self.data[1] == 'mp' then
			self.owner:addMidMpMaxPc(self.data[2])
			self.owner:addMidMpMax(self.data[3])
			self.effectTime = self.data[4]
			self.owner:calcMpMax()
			break
		end
		
		if self.data[1] == 'atk' then
			self.owner:addMidAttackPc(self.data[2])
			self.owner:addMidAttack(self.data[3])
			self.effectTime = self.data[4]
			self.owner:calcAttack()
			break
		end
		
		if self.data[1] == 'def' then
			self.owner:addMidDefencePc(self.data[2])
			self.owner:addMidDefence(self.data[3])
			self.effectTime = self.data[4]
			self.owner:calcDefence()
			break
		end
		
		if self.data[1] == 'wsp' then
			self.owner:addMidASpeed(self.data[2])
			self.effectTime = self.data[4]
			self.owner:calcASpeed()
			break
		end
	
		if self.data[1] == 'mov' then
			self.owner:addMidMSpeedPc(self.data[2])
			self.owner:addMidMSpeed(self.data[3])
			self.effectTime = self.data[4]
			self.owner:calcMSpeed()
			break
		end
		
		if self.data[1] == 'rng' then
			self.owner:addMidAttackRangePc(self.data[2])
			self.owner:addMidAttackRange(self.data[3])
			self.effectTime = self.data[4]
			self.owner:calcAttackRange()
			break
		end
		
		if self.data[1] == 're_hp' then
			self.owner:addMidRecvHpPc(self.data[2])
			self.owner:addMidRecvHp(self.data[3])
			self.effectTime = self.data[4]
			self.owner:calcRecvHp()
			break
		end
		
		if self.data[1] == 're_mp' then
			self.owner:addMidRecvMpPc(self.data[2])
			self.owner:addMidRecvMp(self.data[3])
			self.effectTime = self.data[4]
			self.owner:calcRecvMp()
			break
		end
		
		if self.data[1] == 'crit_rate' then
			self.owner:addMidBaojiRate(self.data[2])
			self.owner:addMidBaojiTimes(self.data[3])
			self.effectTime = self.data[4]
			self.owner:calcBaoji()
			break
		end

		if self.data[1] == 'hit_rate' then
			self.owner:addMidHit(self.data[2])
			self.effectTime = self.data[4]
			self.owner:calcHit()
			break
		end
	
		if self.data[1] == 'dod_rate' then
			self.owner:addMidMiss(self.data[2])
			self.effectTime = self.data[4]
			self.owner:calcMiss()
			break
		end
	until true
	self.leftTime =  self.effectTime
end

function StatsAffect:onExec(dt)
	self.leftTime = self.leftTime -  dt
	if self.leftTime <= 0 then
		self:onExit()		
		return
	end
end

function StatsAffect:onExit()
	self.super.onExit(self)
	repeat
		local lzm = false
		if self.data[1] == 'ctrl' then
			-- 1: 不能移动 2:不能攻击 3:不能放技能
			self.owner.controledState = bit_and(self.owner.controledState, bit_not(self.data[2])) -- 控制类型
		end
		if self.data[1] == 'up_str' then
			self.owner:addMidStrengthPc(-self.data[2])
			self.owner:addMidStrength(-self.data[3])
			--calc strength again
			self.owner:calcStrength()
			lzm = true
			break
		end
		if self.data[1] == 'up_dex' then
			self.owner:addMidMinjiePc(-self.data[2])
			self.owner:addMidMinjie(-self.data[3])
			--calc minjie again
			self.owner:calcMinjie()
			lzm = true
			break
		end
		if self.data[1] == 'up_inte' then
			self.owner:addMidZhiliPc(-self.data[2])
			self.owner:addMidZhiLi(-self.data[3])
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

		if self.data[1] == 'hp' then
			self.owner:addMidHpMaxPc(-self.data[2])
			self.owner:addMidHpMax(-self.data[3])
			self.owner:calcHpMax()
			break
		end

		if self.data[1] == 'mp' then
			self.owner:addMidMpMaxPc(-self.data[2])
			self.owner:addMidMpMax(-self.data[3])
			self.owner:calcMpMax()
			break
		end
		
		if self.data[1] == 'atk' then
			self.owner:addMidAttackPc(-self.data[2])
			self.owner:addMidAttack(-self.data[3])
			self.owner:calcAttack()
			break
		end
		
		if self.data[1] == 'def' then
			self.owner:addMidDefencePc(-self.data[2])
			self.owner:addMidDefence(-self.data[3])
			self.owner:calcDefence()
			break
		end
		
		if self.data[1] == 'wsp' then
			self.owner:addMidASpeed(-self.data[2])
			self.owner:calcASpeed()
			break
		end
	
		if self.data[1] == 'mov' then
			self.owner:addMidMSpeedPc(-self.data[2])
			self.owner:addMidMSpeed(-self.data[3])
			self.owner:calcMSpeed()
			break
		end
		
		if self.data[1] == 'rng' then
			self.owner:addMidAttackRangePc(-self.data[2])
			self.owner:addMidAttackRange(-self.data[3])
			self.owner:calcAttackRange()
			break
		end
		
		if self.data[1] == 're_hp' then
			self.owner:addMidRecvHpPc(-self.data[2])
			self.owner:addMidRecvHp(-self.data[3])
			self.owner:calcRecvHp()
			break
		end
		
		if self.data[1] == 're_mp' then
			self.owner:addMidRecvMpPc(-self.data[2])
			self.owner:addMidRecvMp(-self.data[3])
			self.owner:calcRecvMp()
			break
		end
		
		if self.data[1] == 'crit_rate' then
			self.owner:addMidBaojiRate(-self.data[2])
			self.owner:addMidBaojiTimes(-self.data[3])
			self.owner:calcBaiji()
			break
		end

		if self.data[1] == 'hit_rate' then
			self.owner:addMidHit(-self.data[2])
			self.owner:calcHit()
			break
		end
	
		if self.data[1] == 'dod_rate' then
			self.owner:addMidMiss(-self.data[2])
			self.owner:calcMiss()
			break
		end
	until true

end


return StatsAffect
