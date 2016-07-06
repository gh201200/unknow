local spell = class("spell")
local g_skillRepository = require "skillRepository"
local entity = require "Ientity"
function spell:ctor()
	self.source = nil
	self.target = nil
	self.skilldata = nil
end
function spell:cast(skillid)
	local skilldata = g_skillRepository.getskilldata(skillid)
	assert (skilldata)
	self.skilldata = skilldata
	self.onBegin()	
end

function spell:setSource(s)
	self.source = s
end

function spell:onBegin()
	--告诉客户端释放技能
	--
	
end

function spell:onChannelCast()

end

function spell:onEnd()
	
end
