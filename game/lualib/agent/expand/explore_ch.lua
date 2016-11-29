local skynet = require "skynet"
local snax = require "snax"
local Quest = require "quest.quest"

local Explore = class("Explore")

local user
local REQUEST = {}

function Explore:ctor()
	self.request = REQUEST
end

function Explore:init( u )
	user = u
end

function Explore.randcon()
	local r = {}
	for i = 1, 5 do
		table.insert(r, math.random(#g_shareData.exploreRepository[i]))
	end 
	return r
end

function REQUEST.explore_goFight( args )
	local errorCode = 0
	repeat
		local card = user.cards:getCardByUuid( args.uuid )
		if not card then
			errorCode = -1
			break
		end
		if card.explore > os.time() then
			errorCode = -1
			break
		end
		if index > 4 or index < 0 then
			errorCode = -1
			break
		end
		if index > 2 and Quest.ExploreLevel > getAccountLevel( user.accout:getExp() ) then
			errorCode = -1
			break
		end

		--
		user.explore:setSlot(index, args.uuid)
		
	until true
	
	return {errorCode=errorCode, uuid=args.uuid, index=args.index}
end

return Explore.new()
