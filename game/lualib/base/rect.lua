local vector3 = require "vector3"

local rect = class("rect")

function rect:ctor()
	self.center = vector3.create()
	self.width = 0
	self.height = 0
end

function rect:isCrossRect( r )
	local x = math.abs(self.center.x - r.center.x) < self.width + r.width 
	local z = math.abs(self.center.z - r.center.z) < self.height + r.height
	return x and z
end

function rect.create()
	return rect.new()
end


return rect
