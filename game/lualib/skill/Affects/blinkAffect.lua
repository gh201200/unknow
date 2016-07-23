local Affect = require "skill.Affects.Affect"
local blinkAffect = class("blinkAffect",Affect)

function blinkAffect:ctor(entity,source,data)
	super.ctor(self,entity,source,data)
end

function blinkAffect:onEnter()
	--强制设置目标位置
	--
	self.owner.curActionState = ActionState.stand 
end

function blinkAffect:onExec(dt)

end

function blinkAffect:onExit()
	
end
