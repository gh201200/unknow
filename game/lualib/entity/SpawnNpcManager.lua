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
local test = 0
local spawnOver = false
function SpawnNpcManager:update(dt)
	if spawnOver then return end
	test = test + dt
	if test < 1000 then return end
	if EntityManager:getMonsterCountByBatch(self.batch) > 0 then return end 
	spawnOver = false
	for k ,v in pairs(self.groups) do
		if v.batch == self.batch then
			spawnOver = false
			v.remainTime = v.remainTime - dt
			if v.remainTime <= 0 then
				print("begin spawn the monster: "..v.dat.id)
				v.batch = v.batch + 1
				local ret = {}
				
				for p, q in pairs(v.dat.szMonsterIds) do
					local sid = assin_server_id()
					EntityManager:createMonster(sid, {
						id = q, 
						px = v.dat.szPosition[p].x/GAMEPLAY_PERCENT, 
						pz = v.dat.szPosition[p].z/GAMEPLAY_PERCENT,
						v.batch,			
					})
					local m = {
						monsterId = q,
						serverId = sid,
						posx = v.dat.szPosition[p].x,
						posz = v.dat.szPosition[p].z,
					}
					table.insert(ret, m)
				end
					
				--tell the clients
				EntityManager:sendToAllPlayers("spawnMonsters", {spawnList = ret})
				
				v.remaintime = v.dat.n32CDtime
				v.dat = g_shareData.spawnMonsterResp[v.dat.n32NextBatch]
				spawnOvrer = true
				break
			end
		end
	end
	if spawnOver then
		self.batch = self.batch + 1
	end
	
end


return SpawnNpcManager.new()
