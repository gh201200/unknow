local Map = class("Map")

local MAP_XGRID_NUM = 20-1
local MAP_ZGRID_NUM = 20-1


function Map:ctor()
	self.grid = {}
	--init the map
	for i=0, MAP_XGRID_NUM do
		self.grid[i] = {}
		for j=0, MAP_ZGRID_NUM do
			self.grid[i][j] = true
			if i == 12 and j > 10  then
				self.grid[i][j] = false
			end
		end
	end
	--build the wall
	for i=0, MAP_XGRID_NUM do
		self.grid[i][0] = false
		self.grid[i][MAP_ZGRID_NUM] = false
	end
	for j=0, MAP_ZGRID_NUM do
		self.grid[0][j] = false
		self.grid[MAP_XGRID_NUM][j] = false 
	end
end

function Map:get(x, z)
	print("Map:get",x,z)
	local gx = POS_2_GRID(x)
	local gz = POS_2_GRID(z)
	if gz < 0 or gz > MAP_ZGRID_NUM then return false end
	if gx < 0 or gx > MAP_XGRID_NUM then return false end
	return self.grid[gx][gz]
end

function Map:set(x, z, v)
	local gx = POS_2_GRID(x)
	local gz = POS_2_GRID(z)
	if gz < 0 or gz > MAP_ZGRID_NUM then return end
	if gx < 0 or gx > MAP_XGRID_NUM then return end
	self.grid[gx][gz] = v
end

return Map.new()
