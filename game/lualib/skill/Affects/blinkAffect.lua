local Affect = require "skill.Affects.Affect"
local blinkAffect = class("blinkAffect",Affect)

function blinkAffect:ctor(entity,source,data)
	super.ctor(self,entity,source,data)
end

function blinkAffect:onEnter()
	--强制设置目标位置
	local distance  = 2 --闪现距离
	local vec = self.owner.dir:return_mul_num(distance)
	local  des = self.owner.pos:return_add(vec)
	self.owner:forcePosition(des)
	--self.owner.curActionState = ActionState.stand 
end

function blinkAffect:onExec(dt)

end

function blinkAffect:onExit()
	
end
