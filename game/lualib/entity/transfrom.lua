local vector3 = require "vector3"

local transform = class("transform")

function transform:ctor(pos, dir)
	self.pos = pos or vector3.create()
	self.dir = dir or vector3.create()
end
return transform
