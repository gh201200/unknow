local vector3 = require "vector3"
local skynet =  require "skynet"
local transform = class("transform")

function transform:ctor(pos, dir)
	self.pos = pos or vector3.create()
	self.dir = dir or vector3.create()
	--register_class_var(self, 'TargetVar', nil)	--选中目标实体
	self.TargetVar = nil
	self.targetTime = 0
	register_class_var(self, 'AttackTarget', nil) --普攻锁定目标
	self.lockTarget = nil
end
function transform:getType()
	return "transform"
end

function transform:getTargetVar()
	return self.TargetVar
end

function transform:setTargetVar(t)
	self.TargetVar =  t
	self.targetTime = skynet.now()
end

function transform:getLockTarget()
	return self.lockTarget
end
function transform:setLockTarget(t)
	self.lockTarget = t
	self:setTargetVar(t)
end
function transform:getDistance(target)
	if not target then return math.maxinteger end
	local dis = vector3.len(self.pos, target.pos)
	return dis
end

function transform:getTarget()
	if self.lockTarget ~= nil then
		return self.lockTarget
	end
	return self:getTargetVar()
end

function transform:getTargetTime()
	return self.targetTime
end

function transform:getHp()
	return 0
end
return transform
