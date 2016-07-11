local socketdriver = require "socketdriver"

function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socketdriver.send (fd, package)
end

function bit(n)
	return 1<<n
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
