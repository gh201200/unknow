--local vector3 = require "vector3"
local skynet = require "skynet"
local spell = class("spell")

local sheduleSpell = require "skill.sheduleSpell"

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
	self.errorCode = ErrorCode.None 
	self.castingTime = 0

	self.effects = {}	--技能效果表
	self.targets = {}
	self.totalTime = 0
	self.attachAffact = {}	--普攻附加效果
	self.sheduleSpells = {} --延迟效果
	
	self.isSheule = false
end

function spell:init(skilldata,skillTimes)
	self.skilldata = skilldata
	self.readyTime = skillTimes[1]
	self.castTime = skillTimes[2]
	self.channalTime = 0 --持续释放时间
	self.endTime = skillTimes[3]
	self.totalTime = skillTimes[1] + skillTimes[2] + skillTimes[3]
	self.triggerTime = skilldata.n32TriggerTime
	if self.triggerTime == 0 then
		self.triggerTime = skillTimes["trigger"]
	end
	if self.triggerTime > self.totalTime then
		self.isSheule = true
		self.triggerTime = self.triggerTime - self.readyTime
	end
	self.myEffectId = skilldata.n32MyEffect or 0  		 --自身绑定特效
	self.targetEffectId = skilldata.n32TargetEffect or 0  	 --目标位置特效
	self.targetEffectPos = nil				 --目标特效位置
end

function spell:canBreak(ms)
	if self:isSpellRunning() == false then return true end
	if ms == ActionState.move and self.status == SpellStatus.Ready then
		self.source.cooldown:resetCd(self.skilldata.id,0) 	
	--	return true
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
function spell:update(dt)
	self:updatesheduleSpell(dt)
	if self:isSpellRunning() == false then return end --技能不推进
	if self.status == SpellStatus.Ready then
		self.readyTime =  self.readyTime - dt
		self:onReady()
	elseif self.status == SpellStatus.Cast then
		self.castTime =  self.castTime - dt
		self:onCast()
	elseif self.status == SpellStatus.ChannelCast then
		self.channelTime = self.channelTime - dt
		self:onChannelCast()
	elseif self.status == SpellStatus.End then
		self.endTime =  self.endTime - dt
		self:onEnd()
	end
	--推进技能效果	
	self:advanceEffect(dt)
end
function spell:onTriggerSkillAffect(skilldata,source,srcTarget)
	if skilldata.n32Type == 35 then
		--产生可碰撞的飞行物
		 g_entityManager:createFlyObj(source,srcTarget,skilldata)
	end
	local selfEffects = skilldata.szMyAffect
	if selfEffects ~= "" then
		local targets = { source }
		self:trgggerAffect(selfEffects,targets,skilldata)
	end

	if skilldata.bCommonSkill == true then
		--普通攻击 触发普攻附加buff
		if  srcTarget:getMiss() > math.random(1,100) then
			--触发闪避
			local shanbiEffect = "[show:500,20052]"
			srcTarget.affectTable:buildAffects(source,shanbiEffect,skilldata.id)	
			return
		end
		source.affectTable:triggerAtkAffects(srcTarget,false,skilldata)
		if srcTarget and srcTarget:getType() ~= "transform" then 
			srcTarget.affectTable:triggerAtkAffects(source,true)	
		end
		return
	end

	if skilldata.n32Type ~= 35 and skilldata.n32Type ~= 36 then
		--目标效果
		if self.skilldata.szAtkBe == "" then
			local targetEffects = skilldata.szTargetAffect
			local targets = g_entityManager:getSkillAttackEntitys(source,srcTarget,skilldata)
			--self.targets = targets
			if targets ~= nil and #targets ~= 0 and targetEffects ~= "" then
				self:trgggerAffect(targetEffects,targets,skilldata)
			end
		else
			--在后续普攻过程中加成的效果
			local tmpTb = {}
			local tmpTb = string.split(skilldata.szAtkBe,",")
			local item = {}
			item.rate = tonumber(tmpTb[2])
			item.lifeTime = tonumber(tmpTb[3])
			item.affdata = skilldata.szTargetAffect
			item.skillId = skilldata.id
			if tonumber(tmpTb[1]) == 1 then
				table.insert(source.affectTable.AtkAffects,item)
			elseif tonumber(tmpTb[1]) == 0 then
				table.insert(source.affectTable.bAtkAffects,item)
			end 
		end
	end
end
--更新技能效果
function spell:advanceEffect(dt)
	if self.triggerTime >= 0  then 
		self.triggerTime = self.triggerTime - dt
		if self.triggerTime < 0 then
			if self.isSheule ~= true then
				self:synSpell(self.source,self.srcTarget,self.skilldata,self.status,self.totalTime)
				self:onTriggerSkillAffect(self.skilldata,self.source,self.srcTarget)
			end
		end
	end
end

--释放被动技能
function spell:onStudyPasstiveSkill(skilldata)
	if skilldata.bActive == false then
		--自身效果
		local selfEffects = skilldata.szMyAffect
		if selfEffects ~= ""  and selfEffects ~= nil then
			local targets = { self.source }
			self:trgggerAffect(selfEffects,targets,skilldata)
		end
		--目标效果
		if skilldata.szAtkBe ~= "" and  skilldata.szAtkBe ~= nil then
			--在后续普攻过程中加成的效果
			local tmpTb = {}
			local tmpTb = string.split(skilldata.szAtkBe,",")
			local item = {}
			item.rate = tonumber(tmpTb[2])
			item.lifeTime = tonumber(tmpTb[3])
			item.affdata = skilldata.szTargetAffect
			item.skillId = skilldata.id 
			if tonumber(tmpTb[1]) == 1 then
				table.insert(self.source.affectTable.AtkAffects,item)
			elseif tonumber(tmpTb[1]) == 0 then
				table.insert(self.source.affectTable.bAtkAffects,item)
			end 
		end
	end
end

--触发目标效果
function spell:trgggerAffect(datastr,targets,skilldata)
	for _k,_v in pairs(targets) do
		if bit_and(_v.affectState,AffectState.Invincible) ~= 0  then
			--无敌状态下
		elseif bit_and(_v.affectState,AffectState.OutSkill) ~= 0 and self.skilldata.bCommonSkill ~= true then
			--普攻 魔免状态
		else
			_v.affectTable:buildAffects(self.source,datastr,skilldata.id)
		end
	end
end
function spell:onBegin()
	self.status = SpellStatus.Ready
	self.srcTarget = self.source:getTarget()
	self:synSpell(self.source,self.srcTarget,self.skilldata,self.status,self.totalTime)
	self.source:callBackSpellBegin()
end

function spell:onReady()
	if self.readyTime < 0 then
		if self.isSheule == true then
			local ss = sheduleSpell.new(self.source,self.srcTarget,self.skilldata,self.triggerTime)
			table.insert(self.sheduleSpells,ss)
		end
		--扣篮消耗

		self.source:addMp(-self.skilldata.n32MpCost,HpMpMask.SkillMp)
		self.source.cooldown:addItem(self.skilldata.id) --加入cd
		if self.source:getType() == "IMapPlayer" then
			self.source:SynSkillCds(self.skilldata.id)
		end
		self.status = SpellStatus.Cast
	end
end

--同步技能状态到客户端
function spell:synSpell(source,srcTarget,skilldata,state,actionTime)
	actionTime = actionTime or 0
	local t = { srcId = source.serverId,skillId = skilldata.id ,state = state, actionTime = actionTime,targetId = 0,targetPos = nil}
	t.targetPos = {x= 0,y=0,z=0} 
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
	self.errorCode = ErrorCode.None
	self.readyTime = 0
	self.castTime = 0
	self.endTime = 0
end

function spell:onCast()
	--self.source.curActionState = ActionState.attack2
	if self.castTime < 0 then
		self.status = SpellStatus.End
	end
end
function spell:onChannelCast()
	if self.channelTime < 0 then
		self.status = SpellStatus.End
	end
end
function spell:onEnd()
	--self.source.curActionState = ActionState.attack3
	if self.endTime < 0 then
		self.status = SpellStatus.None	
		self.source.CastSkillId = 0
		self.source:OnStand()
		self.source:callBackSpellEnd()
		if self.source:getTarget() ~= nil and self.source:getTarget():getType() == "transform" then
			if self.source:getTarget() == self.srcTarget then
				self.source:setTarget( nil )
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
