local skynet = require "skynet"
local HateList = class("HateList")

local EntityManager = require "entity.EntityManager"

function HateList:ctor(entity)
	self.source = entity
	self.hateList = {}
	self.topHateId = 0
	
	
end 

function HateList:getTopHate()
	return self.topHateId
end


function HateList:getHate(id)
	if self.hateList[id] then
		return self.hateList[id].val
	end
	return 0
end


function HateList:addHate(entity,hateValue)
	assert(entity)
	if self.hateList[entity.serverId] == nil then
		self.hateList[entity.serverId] = { val = hateValue,upTime = skynet.now() }
	else
		self.hateList[entity.serverId].val = self.hateList[entity.serverId].val + hateValue
		self.hateList[entity.serverId].upTime = skynet.now()
	end
	--record the top hate
	if self.hateList[self.topHateId] then
		if self.hateList[self.topHateId].val <= self.hateList[entity.serverId].val then
			self.topHateId = entity.serverId
		end
	else
		self.topHateId = entity.serverId
	end

	--link the hate
	for k, v in pairs(self.source.attDat.szLink) do
		local lt = EntityManager:getMonsterById(v)
		for p, v in pairs(lt) do
			if v.hateList:getHate(entity.serverId) == 0 then
				v.hateList:addHate(entity, 1)
			end 
		end
	end
end

function HateList:removeHate(entity)
	self.hateList[entity.serverId] = nil
	if self.topHateId == entity.serverId then
		for k, v in pairs(self.hateList) do
			if v then
				if self.hateList[self.topHateId].val < v.val then
					self.topHateId = k
				elseif self.hateList[self.topHateId].val == v.val then
					if self.hateList[self.topHateId].upTime < v.upTime then
						self.topHateId = k
					end
				end
			end
		end
	end
end


return HateList
