local skynet = require "skynet"
local CardMethod = require "agent.cards_method"
local EntityManager = require "entity.EntityManager"
local DropManager = require "drop.DropManager"


local BattleOverManager = class("BattleOverManager")

function BattleOverManager:ctor()
	self.RedHomeBuilding = nil
	self.BlueHomeBuilding = nil
	self.RedKillNum = 0
	self.BlueKillNum = 0
	self.RestTime = 0
	self.OverRes = 0
	self.PatternDat = nil
end

function BattleOverManager:init( mapDat )
	self.PatternDat = g_shareData.patternRepository[mapDat.n32Pattern]
	self.RestTime = self.PatternDat.n32Time * 1000
end

function BattleOverManager:update( dt )
	if self.OverRes ~= 0 then return end
	self.RestTime = self.RestTime - dt

	repeat
		if self.RedHomeBuilding:isDead() then
			self.OverRes = 1	--蓝方胜
			break
		end
		if self.BlueHomeBuilding:isDead() then
			self.OverRes = 2	--红方胜
			break
		end
		if self.RedKillNum >= self.PatternDat.n32Kills then
			self.OverRes = 2	--红方胜
			break
		end
		if self.BlueKillNum >= self.PatternDat.n32Kills then
			self.OverRes = 1	--蓝方胜
			break
		end
		if self.RestTime <= 0 then
			self.OverRes = 3	--平局
			break
		end
	until true
	if self.OverRes ~= 0 then
		local winners, failers, redRunAway, blueRunAway = self:calcRes()
		self:giveResult()
		self:sendResult(winners, failers)
	end
end

function BattleOverManager:calcRes()
	local redPlayers = {}
	local bluePlayers = {}
	local redRunAway = {}
	local blueRunAway = {}
	for k, v in pairs(EntityManager.entityList) do
		if v.entityType == EntityType.player then
			v.BattleGains = {items = {}, score=0}
			if v:isRed() then
				if v:getOffLineTime() > 90 then
					table.insert(redRunAway, v)
				else
					table.insert(redPlayers, v)
				end
			else
				if v:getOffLineTime() > 90 then
					table.insert(blueRunAway, v)
				else
					table.insert(bluePlayers, v)
				end
			end
		end
	end
	local winners, faliers
	local win_items = DropManager:openPackage( self.PatternDat.szWinDrops )
	local fail_items = DropManager:openPackage( self.PatternDat.szFailDrops )
	if self.OverRes == 1 then
		winners = bluePlayers
		for k, v in pairs(winners) do
			v.BattleGains.items = win_items
		end	
		failers = redPlayers
		for k, v in pairs(failers) do
			v.BattleGains.items = fail_items
		end	
	elseif self.OverRes == 2 then
		winners = redPlayers
		for k, v in pairs(winners) do
			v.BattleGains.items = win_items
		end	
		failers = bluePlayers
		for k, v in pairs(failers) do
			v.BattleGains.items = fail_items
		end	winners = redPlayers
	else
		for k, v in pairs(redPlayers) do
			v.BattleGains.items = fail_items
		end	
		for k, v in pairs(bluePlayers) do
			v.BattleGains.items = fail_items
		end	
	end

	if self.OverRes == 3 then return end

	local winScore, failScore, runAwayScore
	if #redRunAway > 0 and #blueRunAway > 0 then
		for k, v in pairs(winners) do
			v.BattleGains.score = v.accountLevel * 10 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
		end	
		for k, v in pairs(failers) do
			v.BattleGains.score = v.accountLevel * 9 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
			v.BattleGains.score = -math.floor( v.Battle.score / #redRunAway / 2 )
		end	
		for k, v in pairs(redRunAway) do
			v.BattleGains.score = v.accountLevel * 9 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
			v.BattleGains.score = -v.BattleGains.score * 2
		end	
		for k, v in pairs(blueRunAway) do
			v.BattleGains.score = v.accountLevel * 9 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
			v.BattleGains.score = -v.BattleGains.score * 2
		end	
	elseif #redRunAway == 0 and  #blueRunAway == 0 then
		for k, v in pairs(winners) do
			v.BattleGains.score = v.accountLevel * 10 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
		end
		for k, v in pairs(failers) do
			v.BattleGains.score = v.accountLevel * 9 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
			v.BattleGains.score = - v.Battle.score
		end	
	elseif #redRunAway > 0 then
		if self.OverRes == 1 then	
			for k, v in pairs(winners) do
				v.BattleGains.score = v.accountLevel * 10
			end
			for k, v in pairs(failers) do
				v.BattleGains.score = math.floor( v.accountLevel * 9 / (#redRunAway * 2))
			end
			for k, v in pairs(redRunAway) do
				v.BattleGains.score = v.accountLevel * 9 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
				v.BattleGains.score = - v.Battle.score * 2
			end
		elseif self.OverRes == 2 then
			for k, v in pairs(winners) do
				v.BattleGains.score = v.accountLevel * 10 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
				v.BattleGains.score = v.Battle.score * 2
			end
			for k, v in pairs(failers) do
				v.BattleGains.score = v.accountLevel * 9 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
				v.BattleGains.score = - v.Battle.score
			end
			for k, v in pairs(redRunAway) do
				v.BattleGains.score = v.accountLevel * 9 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
				v.BattleGains.score = - v.Battle.score * 2
			end

		end
	elseif #blueRunAway > 0 then
		if self.OverRes == 2 then	
			for k, v in pairs(winners) do
				v.BattleGains.score = v.accountLevel * 10
			end
			for k, v in pairs(failers) do
				v.BattleGains.score = math.floor( v.accountLevel * 9 / (#redRunAway * 2))
			end
			for k, v in pairs(redRunAway) do
				v.BattleGains.score = v.accountLevel * 9 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
				v.BattleGains.score = - v.Battle.score * 2
			end
		elseif self.OverRes == 1 then
			for k, v in pairs(winners) do
				v.BattleGains.score = v.accountLevel * 10 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
				v.BattleGains.score = v.Battle.score * 2
			end
			for k, v in pairs(failers) do
				v.BattleGains.score = v.accountLevel * 9 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
				v.BattleGains.score = - v.Battle.score
			end
			for k, v in pairs(bluwRunAway) do
				v.BattleGains.score = v.accountLevel * 9 + math.floor((600 - self.PatternDat.n32Time + self.RestTime)/10)
				v.BattleGains.score = - v.Battle.score * 2
			end

		end
	end
	return winners, failers, redRunAway, blueRunAway
end

function BattleOverManager:giveResult()
	local database = skynet.uniqueservice("database")		
	for k, v in pairs(EntityManager.entityList) do
		if v.entityType == EntityType.player then
			if v.agent then
				skynet.call(v.agent, "lua", "giveBattleGains", v.BattleGains)
			else	
				local account = skynet.call(database, "lua", "account_rd", "load", v.account_id)
				account.exp = mClamp(account.exp + v.BattleGains.score, 0, math.maxinteger)
				skynet.call (database, "lua", "account_rd", "update", account, "exp")
				for p, q in pairs(v.BattleGains.items) do
					local itemDat = g_shareData.itemRepository[q.itemId]
					if itemDat.n32Type == 3 then	
						local _serId = Macro_GetCardSerialId( itemDat.n32Retain1 )
						local card = skynet.call(db, "lua", "cards_rd", "loadBySerialId", v.account_id, _serId) 
						if not card then
							card = CardMethod.initCard( itemDat.n32Retain1 )
							card.count = (q.itemNum-1) *  g_shareData.heroRepository[itemDat.n32Retain1].n32WCardNum 
						else
							card.count = card.count + q.itemNum *  g_shareData.heroRepository[itemDat.n32Retain1].n32WCardNum 
						end
						skynet.call(db, "lua", "cards_rd","addCard", account_id, card)
					elseif itemDat.n32Type == 5 then
						account.gold = mClamp(account.gold + itemDat.n32Retain1*q.itemNum, 0, math.maxinteger)
						skynet.call (database, "lua", "account_rd", "update", account, "gold")
					elseif itemDat.n32Type == 6 then
						account.money = mClamp(account.money + itemDat.n32Retain1*q.itemNum, 0, math.maxinteger)
						skynet.call (database, "lua", "account_rd", "update", account, "money")
					end
				end
			end
		end
	end
end


function BattleOverManager:sendResult()
	local r = {}
	r.result = self.OverRes
	for k, v in pairs(EntityManager.entityList) do
		if v.entityType == EntityType.player then
			if not r.maxBeDamage then
				r.maxBeDamage = v
			elseif r.maxBeDamage.HonorData[2] < v.HonorData[2] then
				r.maxBeDamage = v
			end
			
			if not r.maxDamage then
				r.maxDamage = v
			elseif r.maxDamage.HonorData[1] < v.HonorData[1] then
				r.maxDamage = v
			end
			
			if not r.maxHelp then
				r.maxHelp = v
			elseif r.maxHelp.HonorData[3] < v.HonorData[3] then
				r.maxHelp = v
			end
		end
	end
	
	r.maxBeDamage  = r.maxBeDamage.serverId
	r.maxDamage = r.maxDamage.serverId
	r.maxHelp = r.maxHelp.serverId
	for k, v in pairs(EntityManager.entityList) do
		if v.entityType == EntityType.player then
			r.score = v.BattleGains.score
			r.kills = v.HonorData[4]
			r.deads = v.HonorData[5]
			r.helps = v.HonorData[3]
			r.items = {}
			for p, q in pairs(v.BattleGains.items) do
				table.insert(r.items, {x=q.itemId,y=q.itemNum})
			end
			if v.agent then
				skynet.call(v.agent, "lua", "sendRequest", "battleOver", r)
			end
		end
	end
end

return BattleOverManager.new()
