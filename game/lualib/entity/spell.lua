--local vector3 = require "vector3"
local skynet = require "skynet"
local spell = class("spell")

require "globalDefine"

local SpellStatus = {
	None 		= 0,	--无
	Begin 		= 1, 	--开始
	Ready 		= 2,	--吟唱
	Cast 		= 3,	--释放
	ChannelCast 	= 4,	--持续施法
	End 		= 5,	--结束
}
local SpellDemageStatus = {
	None		= 0,	--
	Trigger		= 1,	--伤害触发状态
	End		= 2,	--伤害结束状态
}

function spell:ctor(entity)
	print("spell:ctor()")
	self.skillId = 0
	self.source = entity
	self.target = nil
	self.status = SpellStatus.None
	self.skilldata = {}	

	self.readyTime = 0 	 --施法前摇
	self.castTime = 0	 --施放中
	self.endTime = 0	 --施法后摇
	
	self.triggerTime = -1 
	self.errorCode = ErrorCode.None 
	self.castingTime = 0
end
function spell:init(skilldata)
	self.triggerTime = skilldata.n32DemageTime
end
function spell:Breaking(ms)
	print("spell:breaking")
	--ready状态可以被主动被动打断，打算后不计入cd和消耗
	--cast状态 主动不可打断 被动打断，依然计入cd和消耗
	--end 主动和被动打断后 依然生效
	if ms == ActionState.move and self.status == SpellStatus.Ready then
		self.status = SpellStatus.None
		print("branking successful")
		self.source.cooldown.resetCd(self.skillId,0) 	
		return true
	end
	if ms == ActionState.move and self.status == SpellStatus.End then 
		self.status = SpellStatus.None
		return true	
	end
	
	return false
end
function spell:isSpellRunning()
	return self.status ~= SpellStatus.None
end
function spell:update(dt)
	if self.status == SpellStatus.None then
	
	elseif self.status == SpellStatus.Ready then
		self.readyTime =  self.readyTime - dt
		self:onReady()
	elseif self.status == SpellStatus.Cast then
		self.castTime =  self.castTime - dt
		self:onCast()
	elseif self.status == SpellStatus.ChannelCast then
		self:onChannelCast()
	elseif self.status == SpellStatus.End then
		self.endTime =  self.endTime - dt
		self:onEnd()
	end
	self:onTrigger(dt)
end
function spell:onTrigger(dt)
	if self.triggerTime < 0 then return end
	--计算伤害
	if self.triggerTime >= 0 and (self.triggerTime - dt) < 0 then
		--触发伤害
		print("on Trigger Demage")
		self.triggerTime = self.triggerTime - dt
	else
	  self.triggerTime = self.triggerTime - dt	
	end
end
function spell:onBegin()
	print("onBegin",skynet.now(),self.readyTime,self.castTime,self.endTime)
	--self.readyTime = 200
	--self.castTime = 100
	--self.triggerTime = 0
	if self.readyTime > 0 then
		print("onReady",skynet.now())
		self.status = SpellStatus.Ready
	else
		self.status = SpellStatus.Cast
	end
end
function spell:onReady()
	if self.readyTime < 0 then
		print("onCast",skynet.now())
		self.status = SpellStatus.Cast
	end

end
function spell:clear()
	self.status = SpellStatus.None
	self.errorCode = ErrorCode.None
	self.readyTime = 0
	self.castTime = 0
	self.endTime = 0 
end
function spell:onCast()
	if self.castTime < 0 then
		print("onEnd",skynet.now())
		self.status = SpellStatus.End
	end
end

function spell:onChannelCast()
	
end
function spell:onEnd()
	if self.endTime < 0 then
		print("onNone",skynet.now())
		self.status = SpellStatus.None
	end

end
function spell:Cast(skillid,target,pos)
	self.skilldata = g_shareData.skillRepository[skillid]
	if self.skilldata and self:isSpellRunning() == false then
		self:onBegin()
	end
end
return spell
