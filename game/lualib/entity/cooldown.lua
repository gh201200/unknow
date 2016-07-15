local skynet = require "skynet"
local cooldown = class("cooldown")
 
require "globalDefine"

function cooldown:ctor(entity)
	print("cooldown:ctor")
	self.coolDownTable = {}
	self.entity = entity
end

function cooldown:addItem(skillid,cd)
	local skilldata = g_shareData.skillRepository[skillid]
	assert(skilldata)
	local cdtime = cd or skilldata.n32CD  
	self.coolDownTable[skillid] = cdtime
end

function cooldown:update(dt)
	for _k,_v in pairs(self.coolDownTable) do
		if  self.coolDownTable[_k] ~= 0 then
			self.coolDownTable[_k] = self.coolDownTable[_k] - dt 
			if self.coolDownTable[_k] <= 0 then
				self.coolDownTable[_k] = 0
			end
		end
	end
end

function cooldown:getCdTime(id)
--	print("getCdtime",self)
	return self.coolDownTable[id] or 0
end
function cooldown:resetCd(id,time)
	time = time or 0
	assert(self.coolDownTable[id])
	self.coolDownTable[id] = time
end
return cooldown
