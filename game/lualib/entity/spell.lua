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
end

function spell:isSpellRunning()
	return self.status ~= SpellStatus.None
end

function spell:update(dt)
	print("spell:update")
	if self.status == SpellStatus.None then
	
	elseif self.status == SpellStatus.Begin then
		self.onBegin()	
	elseif self.status == SpellStatus.Ready then
		self.onReady()
	elseif self.status == SpellStatus.Cast then
		self.onCast()
	elseif self.status == SpellStatus.ChannelCast then
		self.onChannelCast()
	elseif self.status == SpellStatus.End then
		self.onEnd()
	end
end
function spell:onBegin()
	print("onBegin")	
end
function spell:onReady()
	
end
function spell:onCast()
	
end

function spell:onChannelCast()
	
end
function spell:onEnd()
	
end
function spell:Cast(skillid,target,pos)
	
end
return spell
