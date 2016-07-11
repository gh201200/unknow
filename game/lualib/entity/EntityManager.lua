local IMapPlayer = require "entity.IMapPlayer"


local EntityManager = class("EntityManager")


function EntityManager:ctor(p)
	self.entityList = {}
end

function EntityManager:update(dt)
	for k, v in pairs(self.entityList) do
		if v.update then
			v:update(dt)		
		end	
	end
end

function EntityManager:createPlayer(agent, playerId, serverId)
	
	local player = IMapPlayer.new()
	player.serverId = serverId
	player.playerId = playerId
	player.agent = agent
	
	--player:advanceEventStamp(EventStampType.Move)
	table.insert(self.entityList, player)

	return player
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


