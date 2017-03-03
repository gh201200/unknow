local Affect = require "skill.Affects.Affect"
local StatsAffect = class("StatsAffect" ,Affect)
function StatsAffect:ctor(entity,source,data,skillId)
        self.super.ctor(self,entity,source,data,skillId)
	if self.data[1] == 'ctrl' then
		self.effectTime = self.data[5] or 0
		self.effectId = self.data[6] or 0
	else
		self.effectTime = self.data[6] or 0
		self.effectId = self.data[7] or 0
	end
	if self.effectTime == -1 then
		self.effectTime = 99999
	end
	self.effectTime = self.effectTime * 1000
end

function StatsAffect:onTrigger(_add)
	if _add ~= 1 and _add ~= -1 then return end
	repeat
		local lzm = false
		if self.data[1] == 'ctrl' then
			if _add == 1 then
				self.owner.affectState = bit_or(self.owner.affectState, self.data[2]) -- 控制类型
			else
				self.owner.affectState = bit_and(self.owner.affectState, bit_not(self.data[2]))
			end
		end
		if self.data[1] == 'upstr' then
			if self.data[2] == 0 then
				self.owner:addMidStrengthPc(_add * self.data[3])
				self.owner:addMidStrength(_add * self.data[4])
			else
				local r = self:getBaseAttributeValue(self.data)
				self.owner:addMidStrength(_add * r)
			end	
			self.owner:calcStrength()
			lzm = true
		end
		if self.data[1] == 'updex' then
			if self.data[2] == 0 then
				self.owner:addMidAgilityPc(_add * self.data[3])
				self.owner:addMidAgility(_add * self.data[4])
			else
				local r = self:getBaseAttributeValue(self.data)
				self.owner:addMidAgility(_add * r)
			end
			self.owner:calcAgility()
			lzm = true
		end
		if self.data[1] == 'upinte' then
			if self.data[2] == 0 then
				self.owner:addMidIntelligencePc(_add * self.data[3])
				self.owner:addMidIntelligence(_add * self.data[4])
			else
				local r = self:getBaseAttributeValue(self.data)
				self.owner:addMidIntelligence(_add * r)
			end		
			self.owner:calcIntelligence()
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
			if self.data[2] == 0 then
				self.owner:addMidHpMax(_add * (self.data[3] * self.owner:getHpMax() + self.data[4]))
			else
				local r = self:getBaseAttributeValue(self.data)
				self.owner:addMidHpMax(_add * r)
			end			
			self.owner:calcHpMax()
			break
		end

		if self.data[1] == 'mp' then
			if self.data[2] == 0 then
				self.owner:addMidMpMaxPc(_add * self.data[3])
				self.owner:addMidMpMax(_add * self.data[4])
			else
				local r = self:getBaseAttributeValue(self.data)
				self.owner:addMidMpMax(_add * r)
			end		 
			self.owner:calcMpMax()
			break
		end
		
		if self.data[1] == 'atk' then
			if self.data[2] == 0 then
				self.owner:addMidAttackPc(_add * self.data[3])
				self.owner:addMidAttack(_add * self.data[4])
			else
				local r = self:getBaseAttributeValue(self.data)
				self.owner:addMidAttack(_add * r)
			end	
			self.owner:calcAttack()
			break
		end
		
		if self.data[1] == 'def' then
			if self.data[2] == 0 then
				self.owner:addMidDefencePc(_add * self.data[3])
				self.owner:addMidDefence(_add * self.data[4])
			else
				local r = self:getBaseAttributeValue(self.data)
				self.owner:addMidDefence(_add * r)
			end		
			self.owner:calcDefence()
			break
		end
		
		if self.data[1] == 'wsp' then
			if self.data[2] == 0 then
				self.owner:addMidASpeed(_add * self.data[4])
			else
				local r = self:getBaseAttributeValue(self.data)
				self.owner:addMidASpeed(_add * r)
			end		
			self.owner:calcASpeed()
			break
		end
	
		if self.data[1] == 'mov' then
			if self.data[2] == 0 then
				self.owner:addMidMSpeedPc(_add * self.data[3])
				self.owner:addMidMSpeed(_add * self.data[4])
			else
				local r = self:getBaseAttributeValue(self.data)
				self.owner:addMidMSpeed(_add * r)
			end
			self.owner:calcMSpeed()
			break
		end
		
		if self.data[1] == 'rehp' then
			if self.data[2] == 0 then
				self.owner:addMidRecvHpPc(_add * self.data[3])
				self.owner:addMidRecvHp(_add * self.data[4])
			else
				local r = self:getBaseAttributeValue(self.data)
				self.owner:addMidRecvHp(_add * r)
			end
			self.owner:calcRecvHp()
			break
		end
		
		if self.data[1] == 'remp' then
			if self.data[2] == 0 then
				self.owner:addMidRecvMpPc(_add * self.data[3])
				self.owner:addMidRecvMp(_add * self.data[4])
			else
				local r = self:getBaseAttributeValue(self.data)
				self.owner:addMidRecvMp(_add * r)
			end
			self.owner:calcRecvMp()
			break
		end
		
		if self.data[1] == 'critrate' then
			self.owner:addMidBaojiRate(_add * self.data[3])
			self.owner:addMidBaojiTimes(_add * self.data[4])
			if _add == 1 then
				self.owner:calcBaoji()
			end
			break
		end

		if self.data[1] == 'hitrate' then
			self.owner:addMidHit(_add * self.data[3])
			self.owner:calcHit()
			break
		end
	
		if self.data[1] == 'dodrate' then
			self.owner:addMidMiss(_add * self.data[3])
			self.owner:calcMiss()
			break
		end
		
		if self.data[1] == "updamage" then
			self.owner:addMidUpdamage(_add * self.data[3])
			break
		end
		
		if self.data[1] == "shield" then
			local r = self:getAttributeValue(self.data)
			if _add == -1 then
				if self.owner:getShield() < r then
					self.owner:addMidShield(-1 * self.owner:getShield())
				else
					self.owner:addMidShield(-1 * _add)
				end
			else
				self.owner:addMidShield(1 * _add)
			end
		end
	until true

end

function StatsAffect:onEnter()
	self.super.onEnter(self)
	self:onTrigger(1)
end

function StatsAffect:onExec(dt)
	self.effectTime = self.effectTime -  dt
	if self.effectTime <= 0 then
		self:onExit()		
		return
	end
	if self.data[1] == "shield" and self.owner:getShield() <= 0 then
		self:onExit()
	end
end

function StatsAffect:onExit()
	self.super.onExit(self)
	self:onTrigger(-1)
end

return StatsAffect
