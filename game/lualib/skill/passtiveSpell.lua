local passtiveSpell = class("passtiveSpell")
function passtiveSpell:ctor(src,skilldata,time)
	self.skilldata = skilldata
	self.source = src
	self.isDead = false
	self.lifeTime = time
	self.attackTicks = 0
	self.bAttackTicks = 0
	if self.skilldata.n32TriggerCondition == 7 or self.skilldata.n32TriggerCondition ==8 or self.skilldata.n32TriggerCondition == 9 then
		self.targets = {}
	end
	
	if self.skilldata.szSelectTargetAffect ~= ""  then
		--被动技能施法目标都是自己
		local adds = {}
		table.insert(adds,self.source)
		self.source.spell:trgggerAffect(self.skilldata.szSelectTargetAffect,adds,self.skilldata)
	end
end

function passtiveSpell:update(dt)
	self.lifeTime  = self.lifeTime - dt
	if self.lifeTime < 0 then
		self.isDead = true
		return
	end
	--碰撞触发
	if self.skilldata.n32TriggerCondition == 7 or self.skilldata.n32TriggerCondition == 8 then	
		local selects = g_entityManager:getSkillSelectsEntitys(self.source,nil,self.skilldata) 
		local targets = g_entityManager:getSkillAffectEntitys(self.source,selects,self.skilldata)
		local dels = {}
		local adds = {}
		for _nt,_nv in pairs(targets) do
			local hit = false
			for _k,_v in pairs(self.targets) do
				if _v.serverId == _nv.serverId then
					hit = true
				end
			end
			if hit == false then
				table.insert(adds,_nv)
			end
		end	
		for _t,_v in pairs(self.targets) do
			local hit = false
			for _nk,_nv in pairs(targets) do
				if _v.serverId == _nv.serverId then
					hit = true
				end
			end
			if hit == false then
				table.insert(dels,_v)
			end
		end
		--adds添加buff
		if #adds > 0 then
			print("adds",#adds)
			self.source.spell:trgggerAffect(self.skilldata.szAffectTargetAffect,adds,self.skilldata)
		end
		--dels移除buff
		if #dels > 0 then
			--local uuid = self.skilldata.n32SeriId * 100 + self.source.serverId
			print("移除buff")
			for _dk,_dv in pairs(dels) do
				if _dv.affectTable then
					--print("remove======",_dv.serverId,self.skilldata.n32SeriId)
					_dv.affectTable:removeBySkillId(self.skilldata.id)
				--	_dv.affectTable:removeById(uuid)
				end
			end	
		end 
		self.targets = targets	
	end
	if self.skilldata.n32TriggerCondition == 9 and self.source.cooldown:getCdTime(self.skilldata.id) <= 0 then
		--学习时候触发
		self:trigger(9)
	end

end

function passtiveSpell:onDead()
	if self.skilldata.n32TriggerCondition == 7 or self.skilldata.n32TriggerCondition == 8 or self.skilldata.n32TriggerCondition == 9 then
		local uuid = self.skilldata.n32SeriId * 100 + self.source.serverId
		for _dk,_dv in pairs(self.targets) do
			_dv.affectTable:removeBySkillId(self.skilldata.id)	
		end	
	end
end

function passtiveSpell:trigger(_cond)
	local isTrigger = false
	--攻击概率触发
	if self.skilldata.n32TriggerCondition == 1 and _cond == 1 then
		if math.random(0,100) <= self.skilldata.n32TriggerInfo then
			isTrigger =  true
		end
	--攻击次数触发
	elseif self.skilldata.n32TriggerCondition == 2 and _cond == 2 then
		print("222222")
		self.attackTicks = self.attackTicks + 1
		if self.attackTicks >= self.skilldata.n32TriggerInfo then
			isTrigger =  true
			self.attackTicks = 0
		end
	--受击概率触发
	elseif self.skilldata.n32TriggerCondition == 3 and _cond == 3 then
		if math.random(0,100) <= self.skilldata.n32TriggerInfo then
			isTrigger =  true
		end	
	--受击次数触发
	elseif self.skilldata.n32TriggerCondition == 4 and _cond == 4 then
		self.bAttackTicks = self.bAttackTicks + 1
		if self.attackTicks >= self.skilldata.n32TriggerInfo then
			isTrigger =  true
			self.bAttackTicks = 0
		end
	--施法触发	
	elseif self.skilldata.n32TriggerCondition == 5 and _cond == 5 then
		print("============trigger 5")
		isTrigger =  true
	--致命触发
	elseif self.skilldata.n32TriggerCondition == 6 and _cond == 6 then
		print("============trigger 666")
		isTrigger =  true
	--敌人碰撞触发
	elseif self.skilldata.n32TriggerCondition == 7 and _cond == 7 then
		isTrigger =  true
	--友方碰撞触发
	elseif self.skilldata.n32TriggerCondition == 8 and _cond == 8 then
		isTrigger =  true
	elseif self.skilldata.n32TriggerCondition == 9  and _cond == 9 then
		isTrigger = true
	end	
	if self.source.cooldown:getCdTime(self.skilldata.id) <= 0 then
		if isTrigger == true then
			local tgt = nil
			if self.skilldata.n32SkillTargetType == 0 then
				tgt = self.source
			else
				--if self.skilldata.n32SkillTargetType == 1 then
				tgt = self.source:getTarget()
			end
			if _cond == 9 then
				self.source.cooldown:resetCd(self.skilldata.id,math.maxinteger);
			else	
				self.source.cooldown:resetCd(self.skilldata.id,self.skilldata.n32CD)
			end
			print("=========study:",self.skilldata.id)
			local _type = self.skilldata.szSelectRange[1]
			self.source.spell:onTrigger(self.skilldata,self.source,tgt)
		end
	end
end




return passtiveSpell
