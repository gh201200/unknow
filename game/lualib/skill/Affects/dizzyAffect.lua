local Affect = require "skill.Affects.Affect"
local dizzyAffect = class("dizzyAffec",Affect)

function dizzyAffect:ctor( entity,source,data )
	self.super.ctor(self,entity,source,data)
	self.dizzyTime = self.data[3] or 0 
	self.intevalTime =  0
	self.lastTime = self.data[4] or 0
	self.effectId = self.data[5] or 0
	self.effectTime = self.dizzyTime
end

function dizzyAffect:onEnter()
	self.super.onEnter(self)
end

function dizzyAffect:onExec(dt)
	self.lastTime = self.lastTime - dt
	if self.lastTime < 0 then
		self:onExit()
		return
	end
	if self.dizzyTime > 0 then
		self.dizzyTime =  self.dizzyTime - dt
		self.effectTime = self.dizzyTime
		--眩晕状态保持站立不动
		self.owner:stand()
		self.affectState = AffectState.dizzy 
		if self.dizzyTime <= 0 then
			 self.effectTime = 0	
		end
	else	
		self.intevalTime =  self.intevalTime - dt
		if self.intevalTime <= 0 then
			self.intervalTime = self.data[3] or 0
			self.dizzyTiem = self.data[2] or 0
			self.dizzyTime = self.data[3] or 0
		end
	end
end

function dizzyAffect:onExit()
	self.super.onExit(self)
end

return dizzyAffect
