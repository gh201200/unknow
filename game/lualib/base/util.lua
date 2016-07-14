local socketdriver = require "socketdriver"

function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socketdriver.send (fd, package)
end

function bit(n)
	return 1<<n
end

function bit_and(a, b)
	return a & b
end

function bit_or(a, b)
	return a | b
end

function bit_not(a)
	return ~a
end

local MAP_GRID_SIZE = 0.2
function POS_2_GRID(p)
	return math.floor(p/MAP_GRID_SIZE)
end

function GRID_2_POS(g)
	return G * MAP_GRID_SIZE
end

function IS_SAME_GRID(v1, v2)
	local g1_x = POS_2_GRID(v1.x)
	local g1_z = POS_2_GRID(v1.z)
	local g2_x = POS_2_GRID(v2.x)
	local g2_z = POS_2_GRID(v2.z)
	return g1_x==g2_x and g1_z==g2_z
end

function mClamp(a, min, max)
	if a < min then return min end
	if a > max then return max end
	return a
end

function Macro_GetBuffSeriesId(_id)
	return math.floor(_id/1000)
end

function Macro_GetBuffLevel(_id)
	return _id%1000
end
