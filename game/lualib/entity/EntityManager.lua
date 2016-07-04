local IMapPlayer = require "entity.IMapPlayer"


local EntityManager = class("EntityManager")


function EntityManager:ctor()
	self.entityList = {}
	
end

function EntityManager:createPlayer(serverId, playerId)
	local player = IMapPlayer.create()
	player.serverId = serverId
	player.playerId = playerId
	
	player:advanceEventStamp(EventStampType.Move)
	table.insert(self.entityList, player)
end

function EntityManager:getEntity(serverId)
	for k, v in pairs(self.entityList) do 
		if v.serverId == serverId then
			return v		
		end
	end
	return nil
end

function EntityManager:getPlayerByPlayerId(playerId)
	for k, v in pairs(self.entityList) do 
		if v.entityType == EntityType.player and v.playerId == playerId then
			return v		
		end
	end
	return nil
end

return EntityManager.new()


