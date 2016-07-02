local vector3 = class("vector3")


function vector3.create(x, y, z)
	local o = vector3.new()
	o.x = x or 0
	o.y = y or 0
	o.z = z or 0
	return o
end

function vector3.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z;
end

function vector3.cross(a, b)
	local x = a.y * b.z - a.z * b.y;
	local y = a.z * b.x - a.x * b.z;
	local z = a.x * b.y - a.y * b.x;

	local v = vector3.create(x, y, z);

	return v;
end

function vector3:set(x, y ,z)
	self.x = x
	self.y = y
	self.z = z
end

return vector3
