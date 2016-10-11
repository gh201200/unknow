local transfrom = require "entity.transfrom"
local ItrapObj = class("ItrapObj",transfrom)

function ItrapObj:ctor(src,pos,skilldata)
	self.source = src
	self.pos = pos
	self.radius = 
	self.lifeTime = 	--陷阱存活时间
	self.effectTime = 	--陷阱效果时间 
	self.interTime = 	--陷阱效果间隔时间
	self.effectId = 	--陷阱特效id
	self.bActive = false
	self.bTrigger = true
	self.affectdata = 
end

function ItrapObj:update(dt)
	self.lifeTime = self.liftTime - dt
	if self.liftTime < 0 then
		--陷阱死亡
	end
	if self.bAcive == false then return end
	
	if self.delTime == self.interTime then
		self.bTrigger = true
	elseif self.delTime <= 0 then
		self.delTime = self.interTime
	else
		self.delTime = self.delTime - dt
	end

	if self.bTrigger == true then 
		for i=#g_entityManager.entityList, 1, -1 do
			local v = g_entityManager.entityList[i]
			if v:getType() ~= "transform" then
				if self.targets[v.serverId] == nil then
					local dis = self:getDistance(v) 
					if dis <= self.radius then
						--陷阱生效
						self.liftTime = self.effectTime
						v:buildAffects(self.source,self.affectdata)
					end		
				end
			end
		end
	end	
end

return ItrapObj
