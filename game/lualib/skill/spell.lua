--local vector3 = require "vector3"
local skynet = require "skynet"
local spell = class("spell")
local transfrom = require "entity.transfrom"
local sheduleSpell = require "skill.sheduleSpell"
local passtiveSpell = require "skill.passtiveSpell"
require "globalDefine"

function spell:ctor(entity)
	--print("spell:ctor()")
	self.source = entity
	self.targets = {}
	self.status = SpellStatus.None
	self.skilldata = nil
	self.readyTime = 0 	 --施法前摇
	self.castTime = 0	 --施放中
	self.endTime = 0	 --施法后摇
	
	self.channelTime = 0	--持续施法	
	self.triggerTime = -1 
	self.effects = {}	--技能效果表
	self.targets = {}
	self.totalTime = 0
	self.sheduleSpells = {} --延迟效果
	self.isSheule = false
	self.passtiveSpells = {} --被动技能
--	self.dir = vector3.create(0,0,0)  
end

function spell:init(skilldata,skillTimes)
	self.skilldata = skilldata
	self.readyTime = skillTimes[1]
	self.castTime = skillTimes[2]
	self.endTime = skillTimes[3]
	self.totalTime = skillTimes[1] + skillTimes[2] + skillTimes[3]
	self.triggerTime = skilldata.n32TriggerTime * 1000 
	self.CTriggerTime = 0 --self.skilldata.n32AffectGap * 1000 
	if self.triggerTime == 0 then
		self.triggerTime = skillTimes["trigger"]
	end
	if self.triggerTime > 0 then
		self.isSheule = true
		self.triggerTime = self.triggerTime - self.readyTime
	end
	--持续施法
	if self.skilldata.n32NeedCasting ~= 0 then
		self.channelTime = self.skilldata.n32AffectTime * 1000
	end
end

function spell:canBreak(ms)
	if self:isSpellRunning() == false then return true end
	if self.skilldata.n32NeedCasting == 2 then return false end	--持续施法不能被打断
	if ms == ActionState.move and self.status == SpellStatus.Ready then
		self.source.cooldown:resetCd(self.skilldata.id,0) 	
		return true
	end
	if ms == ActionState.move and self.status == SpellStatus.End then 
		return true	
	end
	return false
end

function spell:enterChannel(time)
	--进入持续施法
	self.channelTime = time
	self.status = SpellStatus.ChannelCast
end
function spell:breakSpell()
	if self.status == SpellStatus.Ready then
		--技能准备阶段被打断 不计入cd
		self.source.cooldown:resetCd(self.skilldata.id,0)
	elseif self.status == SpellStatus.Cast then
		--释放过程被打断
			
	elseif self.status == SpellStatus.End then
		--释放收尾被打断
			
	end
	
	--打断后 进入站立状态
	self.source:OnStand()
	self.source:callBackSpellEnd()	
	self:clear()
end
function spell:isSpellRunning()
	return self.status ~= SpellStatus.None
end

function spell:updatesheduleSpell(dt)
	for i= #self.sheduleSpells,1,-1 do
		if self.sheduleSpells[i].isDead == true then
			table.remove(self.sheduleSpells,i)
		else
			self.sheduleSpells[i]:update(dt)
		end
	end 
end

function spell:updatePasstiveSpells(dt)
	for i= #self.passtiveSpells,1,-1 do
		if self.passtiveSpells[i].isDead == true then
			table.remove(self.passtiveSpells,i)
		else
			self.passtiveSpells[i]:update(dt)
		end
	end
end
function spell:update(dt)
	self:updatesheduleSpell(dt)
	self:updatePasstiveSpells(dt)
	if self:isSpellRunning() == false then return end --技能不推进
	if self.status == SpellStatus.Ready then
		self:onReady(dt)
	elseif self.status == SpellStatus.Cast then
		self:onCast(dt)
	elseif self.status == SpellStatus.ChannelCast then
		self:onChannelCast(dt)
	elseif self.status == SpellStatus.End then
		self:onEnd(dt)
	end
	--推进技能效果	
	self:advanceEffect(dt)
end

--触发被动技能
function spell:onTriggerPasstives(_cond)
	for _k,_v in pairs(self.passtiveSpells) do
		_v:trigger(_cond)	
	end
end

--触发效果
function spell:onTrigger(skilldata,source,srcTarget)
	local skillTgt = srcTarget
	--普通攻击
	if skilldata.n32SkillType == 0 then
		if skilldata.n32BulletType == 0 then
			--攻击概率出发
			self:onTriggerPasstives(1)
			--攻击次数触发
			self:onTriggerPasstives(2)
			if srcTarget then
				--受击概率触发
				srcTarget.spell:onTriggerPasstives(3)
				--受击概率触发
				srcTarget.spell:onTriggerPasstives(4)
			end
		end
	else
		if skilldata.n32Active == 0 then
			self:onTriggerPasstives(5)
		end
	end
	local selects = g_entityManager:getSkillSelectsEntitys(source,srcTarget,skilldata)
	if skilldata.szSelectTargetAffect ~= "" then
		self:trgggerAffect(skilldata.szSelectTargetAffect,selects,skilldata)
	end
	local targets = {}
	if skilldata.szMyAffect ~= "" then
		self:trgggerAffect(skilldata.szMyAffect,targets,skilldata,true)
		if skilldata.szMyAffect[1] ~= nil and skilldata.szMyAffect[1][1] == "charge" then
			return
		end
	end
	if skilldata.n32BulletType ~= 0 then
		if(skilldata.n32SkillTargetType == 6 or skilldata.n32SkillTargetType == 4) and skilldata.n32BulletType ~= 2 then
			g_entityManager:createFlyObj(source,srcTarget,skilldata)
		else	
			for _k,_v in pairs(selects) do
				g_entityManager:createFlyObj(source,_v,skilldata)
			end
		end
	else
		targets = g_entityManager:getSkillAffectEntitys(source,selects,skilldata)
		if #targets ~= 0 and skilldata.szAffectTargetAffect ~= ""then
			self:trgggerAffect(skilldata.szAffectTargetAffect,targets,skilldata)
		end
	end

end

--推进技能效果
function spell:advanceEffect(dt)
	if self.triggerTime >= 0  then 
		self.triggerTime = self.triggerTime - dt
		if self.triggerTime < 0 then
			if self.isSheule ~= true then
				self:synSpell(self.source,self.srcTarget,self.skilldata,self.status,self.totalTime)
				self:onTrigger(self.skilldata,self.source,self.srcTarget)
			end
		end
	end
end

--触发目标效果
function spell:trgggerAffect(datas,targets,skilldata,isSelf)
	isSelf = isSelf or false
	if isSelf == true then
		--self.source.affectTable:buildAffects(targets[1],datas,skilldata.id)
		self.source.affectTable:buildAffects(self.source,datas,skilldata.id)
	else
		if skilldata.n32SkillType == 0 and self.source:getHit()*100 < math.random(0,100) then
			--未命中
			self.source:dumpStats()	
			print("can not hit")
			return
		end	
		for _k,_v in pairs(targets) do
				if _v:isAffectState(AffectState.Invincible) and self.source ~= _v then
					--无敌状态下
					print("无敌状态")
				elseif _v:isAffectState(AffectState.OutSkill) and skilldata.n32SkillType == 0 then
					--普攻 魔免状态
				else
					if skilldata.n32SkillType == 0 and _v:getMiss()*100 > math.random(0,100) then
						--闪避
			         		local r = {acceperId = _v.serverId,producerId = self.source.serverId,effectId = 31005,effectTime = 0,flag = 0}
         					g_entityManager:sendToAllPlayers("pushEffect",r)		
					else
						if skilldata.n32BulletType ~= 0 and skilldata.n32SkillType == 0 then
							self:onTriggerPasstives(1)
							self:onTriggerPasstives(2)	
						end
						_v.affectTable:buildAffects(self.source,datas,skilldata.id)
					end
				end
		end
	end
end

function spell:onBegin()
	self.status = SpellStatus.Ready
	self.srcTarget = self.source:getTarget()
	--方向性技
	if self.skilldata.n32SkillTargetType == 6 then
		local pos = self.source.pos:return_add(self.source.dir)
		self.srcTarget = transfrom.new(pos,nil)
	end
	self:synSpell(self.source,self.srcTarget,self.skilldata,self.status,self.totalTime)
	self.source:callBackSpellBegin()	
	if self.skilldata.n32SkillType == 0 then
		self.source.attackNum = self.source.attackNum + 1
	end
end

--红蓝消耗是否足够
function spell:canCost(skilldata)
	local MpCost,HpCost = 0,0
	if skilldata.n32MpCost ~= 0 or skilldata.n32MpCostPercent ~= 0 then
		MpCost = skilldata.n32MpCostPercent / 100 * self.source:getMp() + skilldata.n32MpCost
		if MpCost > self.source:getMp() then 
			return false
		end
	end
	if skilldata.n32HpCost ~= 0 or skilldata.n32HpCostPercent ~= 0 then
		HpCost = skilldata.n32HpCostPercent / 100 * self.source:getHp() + skilldata.n32HpCost
		if HpCost > self.source:getHp() then 
			return false
		end
	end
	return true
end

--扣除蓝耗
function spell:costMpHp(skilldata)
	--蓝消耗
	local MpCost,HpCost = 0,0
	MpCost = skilldata.n32MpCostPercent / 100 * self.source:getMp() + skilldata.n32MpCost
	HpCost = skilldata.n32HpCostPercent / 100 * self.source:getHp() + skilldata.n32HpCost
	if MpCost ~= 0 then self.source:addMp(-MpCost,HpMpMask.SkillMp,self.source) end
	if HpCost ~= 0 then self.source:addHp(-HpCost,HpMpMask.SkillHp,self.source) end
end

function spell:onReady(dt)
	self.readyTime =  self.readyTime - dt
	if self.readyTime < 0 then
		--扣除消耗
		if self:canCost(self.skilldata) == false then
			self:breakSpell()
			return 
		end
		self:costMpHp(self.skilldata)
		if self.isSheule == true then
			local ss = sheduleSpell.new(self.source,self.srcTarget,self.skilldata,self.triggerTime)
			table.insert(self.sheduleSpells,ss)
		end
		if self.skilldata.n32SkillType == 0 then
			--普通攻击
			local time = self.castTime + self.endTime
			self.source.cooldown:addItem(self.skilldata.id,time)
		else
			self.source.cooldown:addItem(self.skilldata.id) --加入cd
		end
		if self.source:getType() == "IMapPlayer" and self.skilldata.n32SkillType ~= 0 then
			self.source:SynSkillCds(self.skilldata.id)
		end
		if self.skilldata.n32NeedCasting == 0 then
			self.status = SpellStatus.Cast
		elseif self.skilldata.n32NeedCasting == 2 then
			self.status = SpellStatus.ChannelCast
		elseif self.skilldata.n32NeedCasting == 1 then
			self.status = SpellStatus.ChannelCast
		end
	end
end

--同步技能状态到客户端
function spell:synSpell(source,srcTarget,skilldata,state,actionTime)
	actionTime = actionTime or 0
	local t = { srcId = source.serverId,skillId = skilldata.id ,state = state,attackNum = source.attackNum, actionTime = actionTime,targetId = 0,targetPos = nil}
	t.targetPos = { x = math.ceil(source.pos.x * GAMEPLAY_PERCENT) ,y = 0 , z = math.ceil(source.pos.z*GAMEPLAY_PERCENT) } 
	if srcTarget ~= nil then
		t.targetPos = {x = math.ceil(srcTarget.pos.x * GAMEPLAY_PERCENT) ,y = 0 , z = math.ceil(srcTarget.pos.z*GAMEPLAY_PERCENT) }
		if srcTarget:getType() ~= "transform" then
			t.targetId = srcTarget.serverId
		end
	end
	g_entityManager:sendToAllPlayers("CastingSkill",t)
end

function spell:clear()
	--正在触发中 移除目标技能效果
	self.triggerTime = 0
	self.status = SpellStatus.None
	self.readyTime = 0
	self.castTime = 0
	self.endTime = 0
end

function spell:onCast(dt)
	self.castTime =  self.castTime - dt
	--self.source.curActionState = ActionState.attack2
	if self.castTime < 0 then
		self.status = SpellStatus.End
	end
end

function spell:onChannelCast(dt)
	self.channelTime = self.channelTime - dt
	if self.channelTime < 0 then
		self.status = SpellStatus.End
		print("持续 ---结束")
		return
	end
	--持续施法中
	self.CTriggerTime = self.CTriggerTime - dt
	if self.CTriggerTime <= 0 then
		self.CTriggerTime = self.skilldata.n32AffectGap  * 1000--间隔时间
		self:onTrigger(self.skilldata,self.source,self.srcTarget)
	end
end

function spell:onEnd(dt)
	self.endTime =  self.endTime - dt
	if self.source:getTarget() ~= nil and self.srcTarget ~= nil and self.source:getTarget() ~= self.srcTarget  then
		--切换目标打断后摇
		self.endTime = -1
	end
	if self.endTime < 0 then
		self.status = SpellStatus.None	
		self.source.CastSkillId = 0
		self.source:callBackSpellEnd()
		if self.source:getTarget() ~= nil and self.source:getTarget():getType() == "transform" then
			if self.source:getTarget() == self.srcTarget then
				if self.source:getType() == "IMapPlayer" then 
					self.source:setTarget( nil )
				end
			end
		end
	end
end

function spell:Cast(skillid,target,pos)
	self.skilldata = g_shareData.skillRepository[skillid]
	assert(self.skilldata)
	self.targets = {} --清空目标列表
	if self.skilldata.bNeedTarget == true then
		target = target or self.source:getTarget()
		self.targets = {target}
	end
	self:onBegin()
end
return spell
