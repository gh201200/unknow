local vector3 = require "vector3" 
local Affect = require "skill.Affects.Affect"
local profitAffect = class("profitAffect",Affect)
function profitAffect:ctor(owner,source,data,skillId)
	self.super.ctor(self,owner,source,data)
	local skilldata = g_shareData.skillRepository[skillId]
	self.radius = skilldata.n32Radius / GAMEPLAY_PERCENT
	self.affectdata = skilldata.szTargetAffect
	self.skillId = skillId
	self.effectId = self.data[3]
	self.effectTime = self.data[2]
	self.tgts = {}
	self.tgtType = GET_SkillTgtType(skilldata)
end


function profitAffect:onEnter()
	self.super.onEnter(self)
end

function profitAffect:onExec(dt)
	self.effectTime = self.effectTime -  dt
	if self.effectTime <= 0 then
		self:onExit()
	end
	for i=#g_entityManager.entityList, 1, -1 do
		local v = g_entityManager.entityList[i] 
		if self.tgtType == 2 and self.owner:isKind(v) == true then
			self:trigger(v)
		elseif self.tgtType == 3 and self.owner:isKind(v) == false then
			self:trigger(v)
		end
	end
end

function profitAffect:trigger(v)
	local dis = self.owner:getDistance(v)
	if dis <= self.radius then
		if self.tgts[v.serverId] == nil then
		--print("add trigger",self.affectdata,v.serverId)	
		local proIds = v.affectTable:buildAffects(self.owner,self.affectdata,self.skillId)
			self.tgts[v.serverId] = proIds
		end
	else
		if self.tgts[v.serverId] ~= nil then
			--移除增益buff
			local proIds = self.tgts[v.serverId]
			for _k,_id in pairs (proIds) do 
				v.affectTable:removeById(_id)
			end
			self.tgts[v.serverId] = nil
		end
	end
end
function profitAffect:onExit()
	print("profitAffect:onExit")
	self.super.onExit(self)
end

return profitAffect

