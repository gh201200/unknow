local vector3 = class("vector3")

local function vector3_length(v)
	return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z )
end

vector3.normal_x = {x=1.0,y=0,z=0}
vector3.normal_y = {x=0,y=1.0,z=0}
vector3.normal_z = {x=0,y=0,z=1.0}

function vector3.create(x, y, z)
	local o = vector3.new()
	o.x = x or 0
	o.y = y or 0
	o.z = z or 0
	assert(type(o.x) == "number")
	assert(type(o.y) == "number")
	assert(type(o.z) == "number")
	return o
end

function vector3.len(a, b)
	return math.sqrt((a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y) + (a.z-b.z)*(a.z-b.z))
end

function vector3.len_2(a, b)
	return (a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y) + (a.z-b.z)*(a.z-b.z)
end


function vector3.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z;
end

function vector3:return_cross(a, b)
	local x = a.y * b.z - a.z * b.y;
	local y = a.z * b.x - a.x * b.z;
	local z = a.x * b.y - a.y * b.x;

	local v = vector3.create(x, y, z);

	return v;
end

function vector3:cross(b)
	local x = self.y * b.z - self.z * b.y;
	local y = self.z * b.x - self.x * b.z;
	local z = self.x * b.y - self.y * b.x;
	self:set(x, y, z)
end

function vector3:set(x, y ,z)
	self.x = x
	self.y = y
	self.z = z
	assert(type(x) == "number")
	assert(type(y) == "number")
	assert(type(z) == "number")
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
	local v3 = vector3.create(self.x + v.x, self.y + v.y,  self.z + v.z)
	return v3
end

function vector3:return_sub(v)
	local v3 = vector3.create(self.x - v.x, self.y - v.y,  self.z - v.z)
	return v3
end

function vector3:sub(v)
	self.x = self.x - v.x
	self.y = self.y - v.y
	self.z = self.z - v.z
end

function vector3:normalize(n)
	if not n then n = 1 end
	local len = vector3_length(self)
	--assert(len > 0,len .. " len is 000000000000000000000")
	if len <= 0 then 
		invLen = 0 
	else
		invLen = 1.0 / len
	end
	self.x = self.x * invLen * n
	self.y = self.y * invLen * n
	self.z = self.z * invLen * n
end

function vector3:rot(a)
	local x = math.cos(math.rad(a))*self.x - self.z*math.sin(math.rad(a))
	local z = math.sin(math.rad(a))*self.x + self.z*math.cos(math.rad(a))
	self.x = x
	self.z = z
end


return vector3


































