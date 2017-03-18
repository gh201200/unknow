local skynet = require "skynet"
local syslog = require "syslog"
local Map = require "map.Map"
local vector3 = require "vector3"
local EntityManager = require "entity.EntityManager"
local dropVec = vector3.create()


local DropManager = class("DropManager")

function DropManager:ctor()
	self.drops = {}
end


local function givePlayerItem( player, drop )
	local itemData = g_shareData.itemRepository[drop.itemId]
	local picks = {}
	if itemData.n32Type == 1 then
		player.pickItems[drop.sid] = {itemId = drop.itemId, skillId = 0}
		local godSkill = player:getGodSkill()
		if player.skillTable[godSkill] < Quest.SkillMaxLevel then
			player:addSkill(godSkill,1,true)	
		end
	else
		for k, v in pairs(EntityManager.entityList) do
			if v.entityType == EntityType.player and v:isSameCamp(player) then
				local reSkills = player:getRegularSkills()
				local skillId
				if #reSkills < 4 then
					skillId = v.bindSkills[math.random(1, 8)]
				else
					local index = math.random(1, 4)
					skillId = reSkills[index]
				end
				v:addSkill(skillId,1,true)
			end
		end
	end
	EntityManager:sendToAllPlayers("pickDropItem", {sid = drop.sid})
end
	
function DropManager:update()
	for k, v in pairs(EntityManager.entityList) do
		if v.entityType == EntityType.player then
			for i=#self.drops , 1, -1 do
				local q = self.drops[i]
				dropVec:set(q.px/GAMEPLAY_PERCENT,0,q.pz/GAMEPLAY_PERCENT)
				if vector3.len(v.pos, dropVec) < 0.5 then
					givePlayerItem( v, q )
					table.remove(self.drops, i)	
				end
			end
		end
	end
end

function DropManager:getNearestDrop(entity)
	local dis = 999
	local point = vector3.create() 
	for i=#self.drops , 1, -1 do 
		local q = self.drops[i]
		dropVec:set(q.px/GAMEPLAY_PERCENT,0,q.pz/GAMEPLAY_PERCENT)
		local len = vector3.len(entity.pos, dropVec)
		if len <= dis then
			point:set(q.px/GAMEPLAY_PERCENT,0,q.pz/GAMEPLAY_PERCENT)
			dis = len
		end
	end
	return dis,point
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
	local pkgs = usePackageItem( entity.attDat.n32Drop )
	for k, v in pairs(pkgs) do
		local itemId = k
		local itemNum = v
		for i=1, itemNum do
			local item = {
				itemId = itemId,
				itemNum = 1,
				belong = 0,
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
				if Map:isWall(dropVec.x,dropVec.z) == false then
				--if Map.legal(Map.POS_2_GRID(dropVec.x), Map.POS_2_GRID(dropVec.z)) then
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
	end
	if #items > 0 then
		EntityManager:sendToAllPlayers("makeDropItem", {items = items})
	end
end


return DropManager.new()
