local skynet = require "skynet"
local syslog = require "syslog"
local Map = require "map.Map"
local vector3 = require "vector3"
local EntityManager = require "entity.EntityManager"
local dropVec = vector3.create()

local DropManager = class("DropManager")

function DropManager:ctor()
	self.drops = {}
	self.redItems = {}
	self.blueItems = {}
end

local picks = {}
function DropManager:update()
	picks = {}
	for k, v in pairs(EntityManager.entityList) do
		if v.entityType == EntityType.player then
			for i=#self.drops , 1, -1 do
				local q = self.drops[i]
				dropVec:set(q.px/GAMEPLAY_PERCENT,0,q.pz/GAMEPLAY_PERCENT)
				if vector3.len(v.pos, dropVec) < 0.5 then
					if v:isRed() then 	
						table.insert(self.redItems, q)
					else
						table.insert(self.blueItems, q)
					end
					table.insert(picks, q.sid..','..v.serverId)
					table.remove(self.drops, i)	
				end
			end
		end
	end
	if #picks > 0 then
		EntityManager:sendToAllPlayers("pickDropItem", {items = picks})
	end
end

local rotate = {
	[0] = 0,
	[1] = 90,
	[2] = 180,
	[3] = 270,
	[4] = 45,
	[5] = 135,
	[6] = 225,
	[7] = 315,
}

function DropManager:makeDrop(entity)
	local pindex = 0
	local items = {}
	for k, v in pairs(entity.attDat.szDrop) do
		local drop = g_shareData.itemDropPackage[v]
		local rd = math.random(1, drop.totalRate)
		local r = nil
		for p, q in pairs(drop) do
			if type(q) == "table" then
				if q.n32Rate >= rd then
					r = q
					break
				end
			end
		end
		if r then
			local itemId = r.n32ItemId
			local itemNum = math.random(r.n32MinNum, r.n32MaxNum)
			local item = {
				itemId = itemId,
				itemNum = itemNum,
			}
			local loop = 0
			repeat
				dropVec:set(entity.dir.x, entity.dir.y, entity.dir.z)
				dropVec:rot(rotate[pindex])
				dropVec:mul_num(1.5)
				dropVec:add(entity.pos)
				pindex = pindex + 1
				if pindex > 8 then pindex = 0 end
				if Map.legal(Map.POS_2_GRID(dropVec.x), Map.POS_2_GRID(dropVec.z)) then
					break
				end
				loop = loop + 1
			until loop >= 8
			if loop == 8 then
				dropVec:set(entity.pos.x, entity.pos.y, entity.pos.z)
			end
			item.px = math.floor(dropVec.x * GAMEPLAY_PERCENT)
			item.pz = math.floor(dropVec.z * GAMEPLAY_PERCENT)
			item.sid = assin_server_id()
			table.insert(self.drops, item)
			table.insert(items, item)
		else
			syslog.errf("make drop failed: package[%d], rd[%d]", v, rd)
		end
	end
	if #items > 0 then
		EntityManager:sendToAllPlayers("makeDropItem", {items = items})
	end
end


return DropManager.new()
