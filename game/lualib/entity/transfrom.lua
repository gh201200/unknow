local vector3 = require "vector3"

local transform = class("transform")

function transform:ctor(pos, dir)
	self.pos = pos or vector3.create()
	self.dir = dir or vector3.create()
end
function transform:getType()
	return "transform"
end

function transform:getDistance(target)
	if not target then return math.maxinteger end
	local dis = vector3.len(self.pos, target.pos)
	return dis
end

return transform
