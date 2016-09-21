local skynet = require "skynet"
local syslog = require "syslog"
local Map = require "map.Map"
local vector3 = require "vector3"
local EntityManager = require "entity.EntityManager"

local DropManager = class("DropManager")

function DropManager:ctor()
	self.drops = {}
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

local dropVec = vector3.create()
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
			self.drops[item.sid] = item
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
