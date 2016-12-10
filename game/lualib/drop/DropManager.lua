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
end


local function givePlayerItem( player, drop )
	local itemData = g_shareData.itemRepository[drop.itemId]
	local picks = {}
	if itemData.n32Type == 1 then
		v.pickItems[drop.sid] = {itemId = drop.itemId, skillId = 0}
		table.insert(picks, drop.sid..','..player.serverId..",0")
	else
		for k, v in pairs(EntityManager.entityList) do
			if v.entityType == EntityType.player and v:isSameCamp(player) then
				local skillId = v.bindSkills[math.random(1, 8)]
				v.pickItems[drop.sid] = {itemId = drop.itemId, skillId = skillId}
				table.insert(picks, drop.sid..','..v.serverId..","..skillId)
			end
		end
	end
	EntityManager:sendToAllPlayers("pickDropItem", {items = picks})
end
	
function DropManager:update()
	for k, v in pairs(EntityManager.entityList) do
		if v.entityType == EntityType.player then
			for i=#self.drops , 1, -1 do
				local q = self.drops[i]
				dropVec:set(q.px/GAMEPLAY_PERCENT,0,q.pz/GAMEPLAY_PERCENT)
				if vector3.len(v.pos, dropVec) < 0.3 then
					givePlayerItem( v, q )
					table.remove(self.drops, i)	
				end
			end
		end
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
	local items = openPackage(entity.attDat.szDrop)
	for k, v in pairs(items) do
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
				if Map:isWall(dropVec.x,dropVec.z) == true then
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

function DropManager:useItem(player, sid)
	local item = player.pickItems[sid]
	if not item then
		return 1	--已被使用	
	end
	
	local errorCode = 0
	local itemData = g_shareData.itemRepository[item.itemId]
	repeat
		local skillId
		
		if itemData.n32Type == 1 then
			skillId = player:getGodSkill()
		else
			skillId = item.skillId
		end
		
		if itemData.n32Type == 0 or itemData.n32Type == 1 then
			if player.skillTable[skillId] == Quest.SkillMaxLevel then
				errorCode = 2	--已达最高等级
				break
			end
			if not player.skillTable[skillId] and table.size(player.skillTable) == Quest.SkillMaxNum then
				errorCode = 3
				break
			end
		end
		
	until true
	if errorCode ~= 0 then
		return errorCode
	end
	
	--使用道具
	if itemData.n32Type == 0 then
		player:addSkill(item.skillId, true)
	elseif itemData.n32Type == 1 then
		player:addSkill(player:getGodSkill(), true)
	elseif itemData.n32Type == 2 then
		player.affectTable:buildEffect(player, itemData.szRetain3) 
	end

	--tell all teamers, inclue player self
	EntityManager:sendPlayer("delPickItem", {item_sid = sid, user_sid = player.serverId})
	
	return errorCode
end

function DropManager:replaceSkill(player, sid, skillId)	
	local item = player.pickItems[sid]
	if not item then
		return 1	--已被使用
	end
	local errorCode = 0
	local itemData = g_shareData.itemRepository[item.itemId]
	repeat
		if player:getReplaceSkillTimes() >= Quest.MaxReplaceSkillTimes then
			errorCode = 4	--最多能替换三次技能
		end
		if itemData.n32Type ~= 0 then
			errorCode = 5
			break
		end
		
		if skillId == player:getGodSkill() then
			errorCode = -1
			break
		end
		
		local skillDat = g_shareData.skillRepository[skillId]
		if skillDat.bActive then
			if player.cooldown:getCdTime(skillId) > 0 then
				errorCode = 2	--技能在CD中
				break
			end
		else
			if player.spell:isSpellRunning() and player:getCommonSkill() == player.spell.skilldata.id then
				errorCode = 3	--普工释放中
				break
			end	
		end
		
	until true
	if errorCode ~= 0 then
		return errorCode
	end
	--使用道具
	player:addReplaceSkillTimes(1)
	player:removeSkill(skillId)
	player:addSkill(item.skillId)

	--tell all teamers, inclue player self
	EntityManager:sendPlayer("delPickItem", {item_sid = sid, user_sid = player.serverId})
	
	return errorCode, item.skillId
end

return DropManager.new()
