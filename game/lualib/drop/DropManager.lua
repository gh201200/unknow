local skynet = require "skynet"
local syslog = require "syslog"
local Map = require "map.Map"
local vector3 = require "vector3"
local EntityManager = require "entity.EntityManager"
local dropVec = vector3.create()
local Quest = require "quest.quest"


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
				if vector3.len(v.pos, dropVec) < 0.3 then
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
	--local pindex = math.random(0, 7)
	local items = {}
	local offset = 8000
	if entity.attDat.n32Type == 1 then
		offset = 20000
	end
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
			for i=1, itemNum do
				local item = {
					itemId = itemId,
					itemNum = 1,
				}
				local loop = 0
				repeat
					--dropVec:set(entity.dir.x, entity.dir.y, entity.dir.z)
					--dropVec:rot(rotate[pindex])
					--dropVec:mul_num(offset)
					--local sp = math.random_ext(1, 360)
					local sr_x = math.random(-offset, offset) / 10000
					local sr_z = math.random(-offset, offset) / 10000
					dropVec:set(entity.pos.x+sr_x, entity.pos.y, entity.pos.z+sr_z)
					--pindex = pindex + 1
					--if pindex > 7 then pindex = 0 end
					if Map.legal(Map.POS_2_GRID(dropVec.x), Map.POS_2_GRID(dropVec.z)) then
						break
					end
					loop = loop + 1
				until loop >= 7

				if loop == 8 then
					dropVec:set(entity.pos.x, entity.pos.y, entity.pos.z)
				end
				item.px = math.floor(dropVec.x * GAMEPLAY_PERCENT)
				item.pz = math.floor(dropVec.z * GAMEPLAY_PERCENT)
				item.sid = assin_server_id()
				table.insert(self.drops, item)
				table.insert(items, item)
			end
		else
			syslog.errf("make drop failed: package[%d], rd[%d]", v, rd)
		end
	end
	if #items > 0 then
		print(items)
		EntityManager:sendToAllPlayers("makeDropItem", {items = items})
	end
end


function DropManager:useItem(player, sid)
	local tb = self.blueItems
	if player:isRed() then
		tb = self.redItems
	end
	local item = nil
	for k, v in pairs(tb) do
		if v.sid == sid then
			item = v
			break
		end
	end
	local errorCode = 0
	local itemData = g_shareData.itemRepository[item.itemId]
	repeat
		if not item then
			errorCode = 1	--已被使用
			break
		end
		local skillId = itemData.n32Retain1
		
		if itemData.n32Type == 1 then
			skillId = player:getGodSkill()
		end
		
		if itemData.n32Type == 0 or itemData.n32Type == 1 then
			if player.skillTable[skillId] == Quest.SkillMaxLevel then
				errorCode = 2	--已达最高等级
				break
			end
			if not player.skillTable[skillId] and table.size(player.skillTable) == Quest.SkillMaxNum then
				errorCode = 3
			end
		end
		
	until true
	if errorCode ~= 0 then
		return errorCode
	end
	--使用道具
	if itemData.n32Type == 0 then
		player:addSkill(itemData.n32Retain1, true)
	elseif itemData.n32Type == 1 then
		player:addSkill(player:getGodSkill(), true)
	elseif itemData.n32Type == 2 then
		player.affectTable:buildEffect(player, itemData.szRetain3) 
	end

	--tell all teamers, inclue player self
	EntityManager:sendToAllPlayersByCamp("delPickItem", {item_sid = sid, user_sid = player.serverId}, player)
	
	return errorCode
end

return DropManager.new()
