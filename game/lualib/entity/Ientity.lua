local vector3 = require "vector3"

local Ientity = class("Ientity")


function Ientity:ctor()
	
	self.serverId = 0		--it is socket fd

	--entity world data
	self.entityType = 0

	self.pos = vector3.create()
	self.dir = vector3.create()
	self.targetPos = vector3.create()

	self.serverEventStamps = {}
	self.clientEventStamps = {}
	self.dispatchEventFunc = {}
end

function Ientity:advanceEventStamp(event)
	if not slef.serverEventStamps[event] then
		slef.serverEventStamps[event] = 0
	end
	slef.serverEventStamps[event] = slef.serverEventStamps[event] + 1

	if self.serverEventStamps[event] > self.clientEventStamps[event] then		--should resp 
		local f = self.dispatchEventFunc[event]
		if f then
			f(self.serverId)		
		end
		self.clientEventStamps[event] = self.serverEventStamps[event]
	end
end

function Ientity:checkeventStamp(event, stamp)
	if not slef.serverEventStamps[event] then
		slef.serverEventStamps[event] = 0
	end
	self.clientEventStamps[event] = stamp
	if slef.serverEventStamps[event] > stamp then 
		return slef.serverEventStamps[event]
	else
		return -1
	end
end

function Ientity:setTargetPos(args)
	self.dir:set(args.dir.x, args.dir.y, args.dir.z)
	self.targetPos:set(args.target.x, args.target.y, args.target.z)
end

function Ientity:update()
	
end



return Ientity










































