--local vector3 = require "vector3"
local spell = class("spell")

local SpellStatus = {
	None 		= 0,	--无
	Begin 		= 1, 	--开始
	Ready 		= 2,	--吟唱
	Cast 		= 3,	--释放
	ChannelCast 	= 4,	--持续施法
	End 		= 5,	--结束
}
function spell:ctor()
	print("spell:ctor()")
	self.skillId = 0
	self.source = nil
	self.target = nil
	self.status = SpellStatus.None
	self.skilldata = {}	
	--全局data
	self.gdd = nil

	self.beginTime = 0
	self.readyTime = 0
	self.castTime = 0
	self.endTime = 0
	self.demageTime = 0
end


function spell:isSpellRunning()
	return self.status ~= SpellStatus.None
end

function spell:update(dt)
	--print("spell:update")
	if self.status == SpellStatus.None then
	
	elseif self.status == SpellStatus.Ready then
		self.readyTime =  self.readyTime - dt
		self.onReady()
	elseif self.status == SpellStatus.Cast then
		self.readyTime =  self.readyTime - dt
		self.onCast()
	elseif self.status == SpellStatus.ChannelCast then
		self.onChannelCast()
	elseif self.status == SpellStatus.End then
		self.readyTime =  self.readyTime - dt
		self.onEnd()
	end
	--计算伤害
	
end

function spell:onBegin()
	print("onBegin")
	self.readyTime = 1
	self.castTime = 1
	self.demageTime = 0
	if self.readyTime > 0 then
		self.status = SpellStatus.Ready
	else
		self.status = SpellStatus.Cast
	end
end
function spell:onReady()
	if self.readyTime < 0 then
		self.status = SpellStatus.Cast
	end

end
function spell:onCast()
	if self.castTime < 0 then
		self.status = SpellStatus.End
	end
end

function spell:onChannelCast()
	
end
function spell:onEnd()
	if self.endTime < 0 then
		self.status = SpellStatus.None
	end

end
function spell:Cast(skillid,target,pos)
	self.skilldata = self.gdd.skillRepository[skillid]
	if self.skilldata and self.isSpellRunning() then
		self.onBegin()
	end
end
return spell
