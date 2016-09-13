local pf = require "pathfinding"
local Map = class("Map")

--width 6.8 = 17*0.4
--height 15.6 = 39*0.4

local MAP_XGRID_NUM = 17
local MAP_ZGRID_NUM = 39
local MAP_GRID_SIZE = 0.4

function Map.POS_2_GRID(p)
	return math.floor(p/MAP_GRID_SIZE)

end

function Map.GRID_2_POS(g)
	return g * MAP_GRID_SIZE + MAP_GRID_SIZE / 2 
end

function Map.IS_SAME_GRID(v1, v2)
	local g1_x = Map.POS_2_GRID(v1.x)
	local g1_z = Map.POS_2_GRID(v1.z)
	local g2_x = Map.POS_2_GRID(v2.x)
	local g2_z = Map.POS_2_GRID(v2.z)
	return g1_x==g2_x and g1_z==g2_z
end

function Map:ctor(terrain)
	self.m = nil
end

function Map:load(terrain)
	--init the map
	local obstacle = {}
	local n = 0
	for line in io.lines(terrain) do
		table.insert(obstacle, line)
		n = n + 1
		if n >= MAP_ZGRID_NUM  then
			break
		end
	end
	self.m = pf.new {
		width = MAP_XGRID_NUM,
         	height = MAP_ZGRID_NUM,
         	obstacle = obstacle,
 	}
end

function Map:dump()
	local str = ''
	for j=MAP_ZGRID_NUM-1,0,-1 do
		str = ''
		for i=0, MAP_XGRID_NUM-1 do
			str = str .. ' ' .. pf.block(self.m, i, j)
		end
		print(str)
	end  
end

function Map.legal(gx, gz)
	if gz < 0 or gz >= MAP_ZGRID_NUM then return false end
	if gx < 0 or gx >= MAP_XGRID_NUM then return false end
	return true
end

function Map:get(x, z)
	local gx = Map.POS_2_GRID(x)
	local gz = Map.POS_2_GRID(z)
	if not Map.legal(gx, gz) then return 255 end
	local w = pf.block(self.m, gx, gz)
	return w
end

function Map:add(x, z, v)
	local gx = Map.POS_2_GRID(x)
	local gz = Map.POS_2_GRID(z)
	if not Map.legal(gx, gz) then return 255 end
	local w = pf.add(self.m, gx, gz, v)
	return w
end

local dir = {
	[0] = {0,1},
	[1] = {1,1},
	[2] = {1,0},
	[3] = {1,-1},
	[4] = {0,-1},
	[5] = {-1,-1},
	[6] = {-1,0},
	[7] = {-1,1}
}

function Map:emptyTest(s_px, s_pz, e_px, e_pz)
	local gx = Map.POS_2_GRID(s_px)
	local gz = Map.POS_2_GRID(s_pz)
	for i=0,7 do
		if Map.legal(gx+dir[i][0], gz+dir[i][1]) then
			local w = pf.block(self.m, gx, gz)
			if w > 0 then
				return false
			end
		end
	end
	return true
end

function Map:find(s_px, s_pz, e_px, e_pz)
	local gsx = Map.POS_2_GRID(s_px)
	local gsz = Map.POS_2_GRID(s_pz)
	local gex = Map.POS_2_GRID(e_px)
	local gez = Map.POS_2_GRID(e_pz)
	local path = { pf.path(self.m, gsx, gsz, gex, gez) }	
	return path
end

return Map.new()
