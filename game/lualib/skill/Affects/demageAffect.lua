local demageAffect = class("Affect")

function demageAffect:ctor(entity,sourcei,data)
	super.ctor(self,entity,source,data)
	--self.n32AttackPhy = 1.0
	--self.n32AttackPhy_Pc = 1.0
	self.triggerTime = 100
	self.leftime = 2000
	self.effectId = 10000

end
function demageAffect:onEnter()
	--推送客户端开始效果1:类型  2:属性百分比 3：属性固定值 4：间隔时间 5：持续时间 6：特效id
	super.onEnter()
	if self.data[6] ~= nil then
		--推送效果
	end
	if self.data[4] == nil or self.data[5] == nil or self.data[5] == 0 then
		--瞬发伤害
		local demage = self:calDemage()
		self.owner.addHp(demage)
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
		self.owner.addHp(demage)
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
	
	local apDem = ap_pc * self.source.Stats.n32AttackPhy + ap_val - 2 * self.owner.Stats.n32DefencePhy 
	if apDem < 0 then apDem = 0 end
	local strDem =  self.source.Stats.n32Strength * str_pc
	local intDem =  self.source.Stats.n32Intelg * int_pc
	local cureDem =  self.source.Stats.n32Agile * cure_pc
	local demage = apDem + strDem + intDem + cureDem
	return -demage
end

return demageAffect
