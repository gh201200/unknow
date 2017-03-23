local skynet = require "skynet"
local cooldown = class("cooldown")
 
require "globalDefine"

function cooldown:ctor(entity)
--	print("cooldown:ctor")
	self.coolDownTable = {}
	self.entity = entity
end

function cooldown:addItem(skillid,cd)
	local skilldata = g_shareData.skillRepository[skillid]
	assert(skilldata)
	--local seriId = skilldata.n32SeriId
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
	--print("cooldown:resetCd",id,time)
        local skilldata = g_shareData.skillRepository[id]
	if skilldata.n32SkillType ~= 0 then
		time = time or 0
		self.coolDownTable[id] = time
	end
end

function cooldown:resetAll(except)
	for _k,_v in pairs(self.coolDownTable) do
		if _k ~= except then
			self.coolDownTable[_k] = 0
		end
	end
end

function cooldown:getCdsMsg()
	local r = { items = {}}
	for _k,_v in pairs(self.coolDownTable) do
		local item = {skillId = _k,time = _v}
		table.insert(r.items,item)
	end	
	return r
end

return cooldown
