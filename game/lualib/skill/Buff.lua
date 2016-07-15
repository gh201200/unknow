local Stats = require "skill.Stats"


local Buff = class("Buff") 

Buff.Flags = {
	ReplaceUpper = bit(0),	--lower lv can replace higer lv
	StopReplaceSame = bit(1),	--cannot replace same knid of buff
	NotRefresh = bit(2),	--donot refresh remaintime
	Damage = bit(3),	--make damage about hp&mp
	Infinity = bit(4),	--loop forever
	CalcStats = bit(5),	--should calc stats again
}

Buff.Effect=  {

}

Buff.Origin = {
	Equip = 1,
	Skill = 2,
	Buff = 3,
	Sys = 4,
}

function Buff:ctor()
	self.buffData = nil
	self.srcEntity = nil
	self.Count = 0
	self.Stats = Stats.new()
	self.remainTime = 0
	self.remainTimes = 0
end

function Buff:process(entity, dt)
	local tickTimes = 0
	while dt > 0 do
		if self.remainTime <= dt then
			tickTimes = tickTimes + self.remainTimes
			if bit_and(self.buffData.n32Flags, Buff.Flags.Infinity) > 0 then
				dt = dt - self.remainTime
				self.remainTime = self.buffData.n32LimitTime
				self.remainTimes = self.buffData.n32LimitTimes
			else
				dt = 0
				self.remainTime  = 0
				self.remainTimes = 0
			end
		else
			self.remainTime = self.remainTime - dt
			tickTimes = tickTimes + self.remainTimes - math.ceil(self.remainTime/self.buffData.n32LimitTime*self.buffData.n32LimitTimes)
			dt = 0
		end
	end
	local trigger = false
	while tickTimes > 0 do
		self:processTick(entity)
		tickTimes = tickTimes - 1
		self.remainTimes = self.remainTimes - 1
		trigger  = true
	end
	if trigger then
		self:onTrigger(entity)
	end
	return self.remainTime > 0
	
end

function Buff:onTrigger(entity)
	if bit_and(self.buffDta.n32Flags,Buff.Flags.Damage) > 0 then
		if self.buffData.n32RecvHp ~= 0 then
			entity:addHp(self.buffData.n32RecvHp, HpMpMask.BuffHp)
		end
		if self.buffData.n32RecvMp ~= 0 then
			entity:addMp(self.buffData.n32RecvMp, HpMpMask.BuffMp)
		end
	end
end


return Buff
