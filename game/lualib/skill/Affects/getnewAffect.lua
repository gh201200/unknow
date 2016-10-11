local Affect = require "skill.Affects.Affect" 
local getnewAffect = class("getnewAffect",Affect)

function getnewAffect:ctor(entity,source,data)
	self.super.ctor(self,entity,source,data) 
	self.effectId = data[2] or 0
	local effectdata = g_shareData.effectRepository[self.effectId] 
	self.effectTime = effectdata.n32time
	self.leftTime = self.effectTime
end

function getnewAffect:onEnter()
	self.super.onEnter(self)
	self.source.cooldown:resetAll(self.source.CastSkillId)
	self.source:SynSkillCds()
end

function getnewAffect:onExec(dt)
	self.leftTime = self.leftTime - dt
	if self.leftTime <= 0 then
		self:onExit()
	end
end

function getnewAffect:onExit()
	self.super.onExit(self)
end

return getnewAffect
