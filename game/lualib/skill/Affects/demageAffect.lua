local Affect = require "skill.Affects.Affect"
local demageAffect = class("demageAffect",Affect)

function demageAffect:ctor(entity,source,data,skillId)
	self.super.ctor(self,entity,source,data,skillId)
	self.triggerTime = data[4] or 0 
	self.leftTime = data[5] or 0
	self.effectId = data[6] or 0
	self.effectTime = data[5] or 0
	
	self.projectId = skillId * 100000 + self.effectId
end
function demageAffect:onEnter()	
	--推送客户端开始效果1:类型  2:属性百分比 3：属性固定值 4：间隔时间 5：持续时间 6：特效id
	self.super.onEnter(self)
	local demage = self:calDemage()
	self.owner:addHp(demage, HpMpMask.SkillHp, self.source)
	if self.data[4] == nil or self.data[5] == nil or self.data[5] == 0 then
		--瞬发伤害
		self:onExit()
		return
	end
	
end
function demageAffect:onExec(dt)
	self.leftTime = self.leftTime -  dt
	if self.leftTime <= 0 then
		self:onExit()		
		return
	end
	self.triggerTime = self.triggerTime - dt
	if self.triggerTime <= 0 then
		self.triggerTime = self.data[4]
		local demage = self:calDemage()
		self.owner:addHp(demage, HpMpMask.SkillHp, self.source)
	end
end

function demageAffect:onExit()
	self.super.onExit(self)
end

function demageAffect:calDemage()
	--计算伤害
	local ap_pc,ap_val,str_pc,cure_pc,inte_pc =  0,0,0,0,0
	if self.data[1] == "ap" then
		ap_pc = self.data[2]
		ap_val = self.data[3]
	elseif self.data[1] == "str" then
		str_pc = self.data[2]
	elseif self.data[1] == "dex" then
		dex_pc = self.data[2]
	elseif self.data[1] == "inte" then
		inte_pc = self.data[2]
	end
	local apDem = ap_pc * self.source:getAttack() + ap_val -  self.owner:getDefence()	
	local strDem =  self.source:getStrength() * str_pc
	local intDem =  self.source:getZhili() * inte_pc
	local cureDem =  self.source:getMinjie() * cure_pc
	local demage = apDem + strDem + intDem + cureDem
	if demage <= 0 then demage = 1 end
	if self.data[1] == "ap" and ap_pc == 0  then
		if demage < ap_val then
			demage = ap_val
		end
	end
	return -demage
end

return demageAffect
