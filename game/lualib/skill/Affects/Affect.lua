local Affect = class "Affect"
function Affect:ctor(entity,source,data)
	self.status = "enter"
        self.owner =  entity  	--效果接受者
        self.source =  source	--效果来源
	self.data = table.copy(data)
end

function Affect:onEnter()
	self.status = "exec"
end

function Affect:onExec()
	
end

function Affect:onExit()
	self.status = "end"
end

return Affect