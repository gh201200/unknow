local Affect = require "skill.Affects.Affect"
local demageAffect = class("demageAffect",Affect)

function demageAffect:ctor(entity,source,data)
	super.ctor(self,entity,source,data)
	self.triggerTime = 0
	self.leftime = data[5] or 0
	self.effectId = data[6] or 0
	self.effectTime = data[5] or 0
end
function demageAffect:onEnter()
	--推送客户端开始效果1:类型  2:属性百分比 3：属性固定值 4：间隔时间 5：持续时间 6：特效id
	super.onEnter()
	if self.data[4] == nil or self.data[5] == nil or self.data[5] == 0 then
		--瞬发伤害
		local demage = self:calDemage()
		self.owner:addHp(demage)
		self:onExit()
		return
	end
	
end
function demageAffect:onExec(dt)
	self.leftTime = self.leftTime -  dt
	if self.leftTime <= 0 then
		self.status = "exit"
		return
	end
	if self.triggerTime <= 0 then
		self.triggerTime = self.data.triggerTime
		local demage = self:calDemage()
		self.owner:addHp(demage)
	end
end

function demageAffect:onExit()
	super:onExit()	
end

function demageAffect:calDemage()
	--计算伤害
	local ap_pc,ap_val,str_pc,dex_pc,inte_pc =  1,0,1,1
	if self.affectData[1] == "ap" then
		ap_pc = self.data[2]
		ap_val = self.data[3]
	elseif self.affectData[1] == "str" then
		str_pc = self.data[2]
	elseif self.affectData[1] == "dex" then
		dex_pc = self.data[2]
	elseif self.affectData[1] == "inte" then
		inte_pc = self.data[2]
	end
	
	local apDem = ap_pc * self.source.Stats.n32AttackPhy + ap_val -  self.owner.Stats.n32DefencePhy 
	if apDem < 0 then apDem = 1 end
	local strDem =  self.source.Stats.n32Strength * str_pc
	local intDem =  self.source.Stats.n32Intelg * int_pc
	local cureDem =  self.source.Stats.n32Agile * cure_pc
	local demage = apDem + strDem + intDem + cureDem
	return -demage
end

return demageAffect
