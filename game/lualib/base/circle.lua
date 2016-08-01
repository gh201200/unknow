local vector3 = require "vector3"

local Circle = class("Circle")

function Circle:ctor(x,y,z,r)
	self.dot = vector3.create(x,y,z)
	self.radius = r
end

local function disSeg2Pt(pt, pt1, pt2)
	local cross = (pt2.x - pt1.x) * (pt.x - pt1.x1) + (pt2.y - pt1.y) * (pt.y - pt1.y)
	if cross <= 0 then
		return math.sqrt((pt.x - pt1.x) * (pt.x - pt1.x) + (pt.y - pt1.y) * (pt.y - pt1.y)) 
	end
	
	local d2 = = (pt2.x - pt1.x) * (pt2.x - pt1.x) + (pt2.y - pt1.y) * (pt2.y - pt1.y)
	if cross >= d2 then 
		return math.sqrt((pt.x - pt2.x) * (pt.x - pt2.x) + (pt.y - pt2.y) * (pt.y - pt2.y))  
   	end

	local r = cross / d2  
	local px = pt1.x + (pt2.x - pt1.x) * r  
	local py = pt1.y + (pt2.y - pt1.y) * r  
	return math.sqrt((pt.x - px) * (pt.x - px) + (py - pt1.y) * (py - pt1.y)) 
end

function Circle:isCrossRect(rect)
	if vector3.len(rect.a, self.dot) < self.radius then
		return true
	end
	if vector3.len(rect.b, self.dot) < self.radius then
		return true
	end
	if vector3.len(rect.c, self.dot) < self.radius then
		return true
	end
	if vector3.len(rect.d, self.dot) < self.radius then
		return true
	end
	if disSeg2Pt(self.dot, rect.a, rect.b) < self.radius then
		return true
	end
	if disSeg2Pt(self.dot, rect.b, rect.c) < self.radius then
		return true
	end
	if disSeg2Pt(self.dot, rect.c, rect.d) < self.radius then
		return true
	end
	if disSeg2Pt(self.dot, rect.a, rect.b) < self.radius then
		return true
	end
	if disSeg2Pt(self.dot, rect.d, rect.a) < self.radius then
		return true
	end
	return false
end


return Circle
