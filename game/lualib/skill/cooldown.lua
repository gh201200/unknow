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
	if self.chargeCountTable[skillid] == nil then
		self.chargeCountTable[skillid] = 0
	end
end

function cooldown:update(dt)
	for _k,_v in pairs(self.coolDownTable) do
		if  self.coolDownTable[_k] ~= 0 then
			if self.entity:getType() == "IMapPlayer" and self.coolDownTable[_k] > 0 and (self.coolDownTable[_k] - dt) <= 0 then
				self:addChargeCount(_k,false)
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
	return self.chargeCountTable[id] or 0
end

function cooldown:addChargeCount(id,isReduce)
	local skilldata = g_shareData.skillRepository[id]
	id = math.floor(id / 10) * 10 + 1
	if skilldata.n32SkillType == 2 then 
		if self.entity.skillTable[id] >= 2 then
			--大招
			local newId = id + self.entity.skillTable[id] - 1
			skilldata = g_shareData.skillRepository[newId]
			assert(skilldata)
		end
	end
	local isUpdate = false
	if isReduce == false then
		if self.chargeCountTable[id] and self.chargeCountTable[id] < skilldata.n32ChargeCount then
			self.chargeCountTable[id] = self.chargeCountTable[id] + 1
			isUpdate = true
		end
	else
		if self.chargeCountTable[id] > 0 then
			self.chargeCountTable[id] = self.chargeCountTable[id] - 1
			isUpdate = true
		end
	end
	if isUpdate == true then
		--重置技能cd
		self:addItem(id)	
		self.entity:SynSkillCds(id)
		local msg = {skillId = id,chargeCount = self.chargeCountTable[id] }
		g_entityManager:sendPlayer(self.entity,"sendChargeCount",msg)		
	end
end
function cooldown:getCdTime(id)
--	print("getCdtime",self)
	id = math.floor(id / 10) * 10 + 1
	return self.coolDownTable[id] or 0
end

function cooldown:resetCd(id,time)
	--print("cooldown:resetCd",id,time)
	id = math.floor(id / 10) * 10 + 1
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

function cooldown:getCdsMsg(id)
        --local skilldata = g_shareData.skillRepository[id]
	id = math.floor(id / 10) * 10 + 1
	local r = { items = {}}
	for _k,_v in pairs(self.coolDownTable) do
		if id == _k then
			local item = {skillId = _k,time = _v}
			table.insert(r.items,item)
			break
		end
	end	
	return r
end

return cooldown
