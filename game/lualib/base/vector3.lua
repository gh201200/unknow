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

function vector3:mul_num(num)
	self.x = self.x * num
	self.y = self.y * num
	self.z = self.z * num
end

function vector3:return_mul_num(num)
	local v3 = vector3.create(self.x*num, self.y*num, self.z*num)
	return v3
end

function vector3:length()
	return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z );
end

function vector3:length_square()
	return self.x * self.x + self.y * self.y + self.z * self.z;
end

function vector3:add(v)
	self.x = self.x + v.x
	self.y = self.y + v.y
	self.z = self.z + v.z
end

function vector3:return_add(v)
	self.x = self.x + v.x
	self.y = self.y + v.y
	self.z = self.z + v.z
end

return vector3


































