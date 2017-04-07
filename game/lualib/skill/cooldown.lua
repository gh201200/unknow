local skynet = require "skynet"
local cooldown = class("cooldown")
 
require "globalDefine"

function cooldown:ctor(entity)
--	print("cooldown:ctor")
	self.coolDownTable = {}
	self.entity = entity
	self.chargeCountTable = {} --充能表
end

function cooldown:addItem(skillid,cd)
	local skilldata = g_shareData.skillRepository[skillid]
	assert(skilldata)
	--local seriId = skilldata.n32SeriId
	local cdtime = cd or skilldata.n32CD 
	self.coolDownTable[skillid] = cdtime
	self.chargeCountTable[skillid] = 0
end

function cooldown:update(dt)
	for _k,_v in pairs(self.coolDownTable) do
		if  self.coolDownTable[_k] ~= 0 then
			local skilldata = g_shareData.skillRepository[_k]
			if self.coolDownTable[_k] > 0 and self.coolDownTable[_k] <= 0 then
				if self.chargeCountTable[_k] < skilldata.n32ChargeCount then
					self.chargeCountTable[_k] = self.chargeCountTable[_k] + 1
					--充能次数变化
					
				end
			end
			self.coolDownTable[_k] = self.coolDownTable[_k] - dt 
			if self.coolDownTable[_k] <= 0 then
				self.coolDownTable[_k] = 0
			end
		end
	end
end

--获取充能数目
function cooldown:getChargeCount(id)
	return self.coolDownTable[id]
end

function cooldown:getCdTime(id)
--	print("getCdtime",self)
	return self.coolDownTable[id] or 0
end

function cooldown:resetCd(id,time)
	--print("cooldown:resetCd",id,time)
        local skilldata = g_shareData.skillRepository[id]
	time = time or 0
	self.coolDownTable[id] = time
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
