local vector3 = require "vector3"

local Ientity = class("Ientity")

function Ientity:ctor()
	
	self.serverId = 0		--it is socket fd

	--entity world data
	self.pos = vector3.create()
	self.dir = vector3.create()
end

return Ientity
