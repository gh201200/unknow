local vector3 = require "vector3"

local transform = class("transform")

function transform:ctor(pos, dir)
	self.pos = pos or vector3.create()
	self.dir = dir or vector3.create()
	register_class_var(self, 'TargetVar', nil)	--选中目标实体
	register_class_var(self, 'AttackTarget', nil) --普攻锁定目标
end
function transform:getType()
	return "transform"
end

function transform:getDistance(target)
	if not target then return math.maxinteger end
	local dis = vector3.len(self.pos, target.pos)
	return dis
end

function transform:getTarget()
	return self:getTargetVar()
end
return transform
