local EntityManager = require "entity.EntityManager"


local SpawnNpcManager = class("SpawnNpcManager")

function SpawnNpcManager:ctor()
	self.groups = {}
	self.batch = 0
end

function SpawnNpcManager:init(mapId)
	local resp = g_shareData.spawnMonsterResp
	for k, v in pairs(resp) do
		if v.n32MapId == mapId then
			table.insert(self.groups, {dat = v, remainTime = 0, batch = 0})
		end
	end
end

local spawnOver
function SpawnNpcManager:update(dt)
	if EntityManager:getMonsterCountByBatch(self.batch) > 0 then return end 
	spawnOver = false
	for k ,v in pairs(self.groups) do
		if v.batch == self.batch then
			spawnOver = false
			v.remainTime = v.remainTime - dt
			if v.remainTime <= 0 then
				print("begin spawn the monster: "..v.dat.id)
				v.batch = v.batch + 1
				for p, q in pairs(v.dat.szMonsterIds) do
					EntityManager:createMonster(assin_server_id(), {
						id = q, 
						px = v.dat.szPosition[p].x/10, 
						pz = v.dat.szPosition[p].z/10,
						v.batch,			
					})
					
				end
				v.remaintime = v.dat.n32CDtime
				v.dat = g_shareData.spawnMonsterResp[v.dat.n32NextBatch]
				spawnOvrer = true
			end
		end
	end
	if spawnOver then
		self.batch = self.batch + 1
	end
	
end


return SpawnNpcManager.new()
