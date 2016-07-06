local IinstantSpell = class("IinstantSpell")
local g_skillRepository = require "skillRepository"
local entityType = require "Ientity"

function instantSpell:ctor()
	self.skilldata = 0;
	self.source = entityType.create()
	self.target = entityType.create()
end
function instantSpell:create(skillid,source,target)
	local skilldata = g_skillRepository.getskill(skillid)
	self.skilldata = skilldata
	self.source = source
	self.target = target
end
function instantSpell:onBegin()

end

function instantSpell:onChannelCast()
	
end

function instantSpell:onEnd()

end

function instantSpell:Advance(dt)

end

function instantSpell:cast(skillid)
	
end
