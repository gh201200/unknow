local Affect = require "skill.Affects.Affect"
local dizzyAffect = class("dizzyAffec",Affect)

function dizzyAffect:ctor( entity,source,data )
	super.ctor(self,entity,source,data)
end

function dizzyAffect:onEnter()
	super:onEnter()
	self.dizzyTime =  0
	self.intevalTime =  0
	self.lastTime = self.data[4] or 0
	self.effectId = self.data[5] or 0
	self.effectTime = self.dizzyTime
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
		if self.dizzyTime <= 0 then
			--人物移除眩晕状态
		end
	else	
		self.intevalTime =  self.intevalTime - dt
		if self.intevalTime <= 0 then
			self.intervalTime = self.data[3] or 0
			self.dizzyTiem = self.data[2] or 0
			--人物进入眩晕状态
		end
	end
end

function dizzyAffect:onExit()
	super:onExit()
end

