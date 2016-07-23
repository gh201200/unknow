local pathfinding = require "pathfinding"
local terrain = class("terrain")
function terrain:ctor()
	self.width = 100
	self.height = 100	
	self.map = pathfinding.new {
        width = self.width,
        height = self.height,
        --{ x=1,y=1,size=2 },
        --{ x=3,y=2,size=3 },
        --{ x=7,y=1,size=3 },
        wall = { 
        }   
}

end

function terrain:addEntity(entity)
	local x,y,size = 2,3,2
	pathfinding.addbuilding(x,y,size)
end

function terrain:removeEntity(entity)
	local x,y,size = 2,3,2
	pathfinding.removebuilding(x,y,size)
end

function terrain:clear()
	pathfinding.clear()
end

function terrain:update(dt)
	
end


