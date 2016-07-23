local Affect = require "skill.Affects.Affect"
local recoverAffect = class("recoverAffect",Affect)
 
function recoverAffect:ctor(entity,source,data)
	super:ctor(entity,source,data)
	self.triggerTime = 0
	self.leftime = data[5] or 0
	self.effectId = data[6] or 0
	self.effectTime = data[5] or 0	
end

function recoverAffect:onEnter()
	super.onEnter()
	if self.data[4] == nil or self.data[5] == nil or self.data[5] == 0 then
	--瞬发效果
		self:calRecover()
		self:onExit()
                return		
	end
end

function recoverAffect:onExec(dt)
	self.lefttime  = self.lefttime - dt
	self.effectTime = self.lefttime
	if self.lefttime <= 0 then
		self:onExit()
		return
	end
	self.triggerTime = self.triggerTime - dt
	if self.triggerTime <= 0 then
		self.triggerTime = self.data[3]
		self:calRecover()
	end
end

function recoverAffect:onExit()
	super.onExit()
end

function recoverAffect:calRecover()
	assert(data and data[1])
	local rateA = self.data[2] or 0
	local rateB = self.data[3] or 0
	local val = rateA * self.source.Status.n32AttackPhy + rateB * self.source.Status.n32Intelg
	if data[1] == "cure_hp" then
		self.owner.addHP(val)
	elseif data[1] == "cure_mp" then
		self.owner.addMP(val)
	end
end
