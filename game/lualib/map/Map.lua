local pf = require "pathfinding"
local vector3 = require "vector3"
local Map = class("Map")

--width 6.8 = 17*0.4
--height 15.6 = 39*0.4

local MAP_XGRID_NUM = 68
local MAP_ZGRID_NUM = 158
Map.MAP_GRID_SIZE = 0.1

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


function Map.POS_2_GRID(p)
	return math.floor(p/Map.MAP_GRID_SIZE)

end

function Map.GRID_2_POS(g)
	return g * Map.MAP_GRID_SIZE + Map.MAP_GRID_SIZE / 2 
end

function Map.IS_SAME_GRID(v1, v2)
	local g1_x = Map.POS_2_GRID(v1.x)
	local g1_z = Map.POS_2_GRID(v1.z)
	local g2_x = Map.POS_2_GRID(v2.x)
	local g2_z = Map.POS_2_GRID(v2.z)
	return g1_x==g2_x and g1_z==g2_z
end

function Map.IS_NEIGHBOUR_GRID(v1, v2)
	local g1_x = Map.POS_2_GRID(v1.x)
	local g1_z = Map.POS_2_GRID(v1.z)
	local g2_x = Map.POS_2_GRID(v2.x)
	local g2_z = Map.POS_2_GRID(v2.z)
	return math.abs(g1_x-g2_x) <= 1 and math.abs(g1_z-g2_z) <= 1
end

function Map:ctor(terrain)
	self.width = MAP_XGRID_NUM  * Map.MAP_GRID_SIZE
	self.height = MAP_ZGRID_NUM * Map.MAP_GRID_SIZE
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

	--self:dump()
end

function Map:dump()
	print('map data==================================')
	local str = ''
	for j=MAP_ZGRID_NUM-1,0,-1 do
		str = ''
		for i=0, MAP_XGRID_NUM-1 do
			local a = pf.block(self.m, i, j)
			if a ~= 0 then a = 1 end
			str = str .. a
		end
		print(str)
	end  
	print('map data----------------------------------')
end

function Map.legal(gx, gz)
	if gz < 0 or gz >= MAP_ZGRID_NUM then return false end
	if gx < 0 or gx >= MAP_XGRID_NUM then return false end
	return true
end

function Map:isWall(x, z)
	local gx = Map.POS_2_GRID(x)
	local gz = Map.POS_2_GRID(z)
	if not Map.legal(gx, gz) then return true end
	local w = pf.block(self.m, gx, gz)
	if w == 255 then
		return true
	else
		return false
	end
end

function Map:isBlock(x, z)
	local gx = Map.POS_2_GRID(x)
	local gz = Map.POS_2_GRID(z)
	return self:block(gx, gz) > 0
end

function Map:block(gx, gz)
	if not Map.legal(gx, gz) then return 255 end
	local w = pf.block(self.m, gx, gz)
	return w
end

function Map:get(x, z)
	local gx = Map.POS_2_GRID(x)
	local gz = Map.POS_2_GRID(z)
	if not Map.legal(gx, gz) then return 255 end
	local w = pf.block(self.m, gx, gz)
	return w
end

function Map:add(x, z, v, s)
	local gx = Map.POS_2_GRID(x)
	local gz = Map.POS_2_GRID(z)

	if not Map.legal(gx, gz) then return 255 end
	pf.add(self.m, gx, gz, v)
	
	if not s or s <= 1 then return end
	s = math.floor( s / 2 )

	for i=-s, s do
		for j=-s, s do
			if i ~= 0 or j ~= 0 then
				if Map.legal(gx+i, gz+j) then
					pf.add(self.m, gx+i, gz+j, v)
				end
			end
		end
	end
end



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

function Map:find(s_px, s_pz, e_px, e_pz, bsize)
	local gsx = Map.POS_2_GRID(s_px)
	local gsz = Map.POS_2_GRID(s_pz)
	local gex = Map.POS_2_GRID(e_px)
	local gez = Map.POS_2_GRID(e_pz)

	if not Map.legal(gsx, gsz) then 
		print('非法寻经：', gsx, gsz, gex, gez)
		return {} 
	end
	if not Map.legal(gex, gez) then 
		print('非法寻经：', gsx, gsz, gex, gez)
		return {} 
	end
	bsize = math.floor( bsize / 2 )
	local path = { pf.path(self.m, gsx, gsz, gex, gez, bsize) }	
	return path
end

function Map:lineTest(sp, ep)
	local dir = vector3.create()
	local dst = vector3.create()
	dir:set(sp.x, sp.y, sp.z)
	dir:sub( ep )
	dir:normalize()
	local set = 0.5
	local step = 0
	repeat
		step = step + 1
		if step > 20 then break end
		dst:set(dir.x, dir.y, dir.z)
		dst:mul_num( set * Map.MAP_GRID_SIZE  )
		dst:add( ep )
		ep.x = dst.x
		ep.z = dst.z
		if self:isBlock( dst.x, dst.z ) == false then
			break
		end
		set = set + 0.2
	until false
end

function Map:quadrantTest( pos )
	if pos.x > self.width / 2 then
		if pos.z > self.height / 2 then
			return 1
		else
			return 4
		end	
	else
		if pos.z > self.height / 2 then
			return 2
		else
			return 3
		end	
	end
end


return Map.new()
