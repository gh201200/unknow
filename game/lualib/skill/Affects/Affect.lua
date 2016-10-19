local Affect = class "Affect"
local uuid = require "uuid"
function Affect:ctor(entity,source,data,skillId)
	self.status = "enter"
        self.owner =  entity  	--效果接受者
        self.source =  source	--效果来源
	self.data = table.copy(data)
	self.affectState = 0
	self.projectId = uuid.gen()
	self.skillId = skillId
end

function Affect:onEnter()
	--print("Affect:onEnter")
	self.status = "exec"
end

function Affect:onExec()
	
end

function Affect:onExit()
	--print("Affect:onExit")
	self.status = "exit"
end

return Affect
