local vector3 = require "vector3"

local Ientity = class("Ientity")



function Ientity:ctor()
	
	self.serverId = 0		--it is socket fd

	--entity world data about
	self.entityType = 0

	self.pos = vector3.create()
	self.dir = vector3.create()
	self.targetPos = vector3.create()

	--event stamp handle about
	self.serverEventStamps = {}
	self.clientEventStamps = {}		--now this table has no means
	self.newClientReq = false

	--skynet about
	
	
end


function Ientity:responseClientStamp(event)
	local f = eventHandle[event]
	if f then
		f(self.serverId)	
	else
		syslog.errf("no %d handle defined", event)	
	end
	self.newClientReq = false
end

function Ientity:advanceEventStamp(event)
	if not self.serverEventStamps[event] then
		self.serverEventStamps[event] = 0
	end
	self.serverEventStamps[event] = self.serverEventStamps[event] + 1

	if self.newClientReq and self.serverEventStamps[event] > self.clientEventStamps[event] then		--should resp now
		map.post.respClientEventStamp(event, self.playerId)
		self.newClientReq = false			--wait for another req
		self.clientEventStamps[event] = self.serverEventStamps[event]
	end
end

function Ientity:checkeventStamp(event, stamp)
	if not self.serverEventStamps[event] then
		self.serverEventStamps[event] = 0
	end
	self.clientEventStamps[event] = stamp

	if self.serverEventStamps[event] > stamp then 
		return self.serverEventStamps[event]
	else
		self.newClientReq = true		--mark need be resp
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










































