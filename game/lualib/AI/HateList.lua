local HateList = class("HateList")

function HateList:ctor(entity)
	self.updateTime = 1000
	self.hatelist = {}
	
end 

function HateList:update(dt)
		
end

function Hatelist:addHate(entity,hateValue,hateTime)
	assert(entity)
	if self.hatelist[entity.serverId] == nil then
		self.hatelist[entity.serverId] = { entity,hateValue,hateTime }
	else
		selfhatelist[entity.serverId][2] = hateValue
		selfhatelist[entity.serverId][3] = hateTime
	end
end

function HateList:removeHate(entity)
	self.hatelist[entity.serverId] = nil
end

function HateList:update(dt)
	self.updateTime = self.updateTime - dt
	if self.updateTime > 0 then return end
	self.updateTime = 1000
	for _k,_v in pairs do
		if _v ~= nil then
			_v[2] = _v[2] - 1
			_v[3] = _v[3] - 1000
			if _v[2] <= 0 or _v[3] <= 0 then
				_v = nil
			end  
		end
	end
end
