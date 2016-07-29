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

local MAP_GRID_SIZE = 0.5
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

--------common func to register get set-----------
function register_class_var(t, name, iv)
	t['m_'..name] = iv
	t['set'..name] = function(self, v)
		t['m_'..name] = v
	end
	t['get'..name] = function(self)
		return t['m_'..name]
	end
end

local server_id = 0
function assin_server_id()
	server_id = server_id + 1
	return server_id
end
