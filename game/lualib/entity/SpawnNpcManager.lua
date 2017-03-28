local EntityManager = require "entity.EntityManager"
local Imonster = require "entity.Imonster"

local SpawnNpcManager = class("SpawnNpcManager")

function SpawnNpcManager:ctor()
	self.groups = {}
end

function SpawnNpcManager:init(mapId)
	local resp = g_shareData.spawnMonsterResp
	for k, v in pairs(resp) do
		if v.n32MapId == mapId then
			table.insert(self.groups, {dat = v,nextdat = v, remainTime = 0, batch = 0})
		end
	end
end
local spawnNum = 0
function SpawnNpcManager:update(dt)
	--if true then return end
	
	for i=#self.groups,1,-1 do
		local v = self.groups[i]
		local gid = v.dat.id
		if EntityManager:getMonsterCountByGroupId(gid) == 0 then
			if v.remainTime <= 0 then
				--直接刷新
				local ret = {}
				local links = {}	
				for p, q in pairs(v.nextdat.szMonsterIds) do
					local sid = assin_server_id()
					local monster = Imonster.create(sid, {
						id = q, 
						px = v.dat.szPosition[p].x/GAMEPLAY_PERCENT, 
						pz = v.dat.szPosition[p].z/GAMEPLAY_PERCENT,
						batch = gid,
						attach = v.dat.n32Attach,			
						})
					links[sid] = monster
					EntityManager:addEntity(monster)
					local m = {
						monsterId = q,
						serverId = sid,
						posx = v.dat.szPosition[p].x,
						posz = v.dat.szPosition[p].z,
					}
					table.insert(ret, m)
				end
				v.remainTime = v.dat.n32CDTime * 1000
				--v.dat = 
				v.nextdat = g_shareData.spawnMonsterResp[v.dat.n32NextBatch]
				local lt = {}
				for _k,_v in pairs(links) do
					table.insert(lt,_k)
				end
				for _k,_v in pairs(links) do
					_v.szLink = lt 
				end
				--tell the clients
				EntityManager:sendToAllPlayers("spawnMonsters", {spawnList = ret})
			else
				v.remainTime = v.remainTime - dt
			end
		end
	end	
end


return SpawnNpcManager.new()
