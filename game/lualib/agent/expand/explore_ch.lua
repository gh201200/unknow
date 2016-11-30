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

function Explore.getId(sid, slv)
	return sid * 1000 + slv
end

function Explore.getSerId( id )
	return math.floor(id / 1000)
end

function Explore.getSerLv( id )
	return id % 1000
end

function Explore.randcon()
	local r = {}
	for i = 1, 5 do
		table.insert(r, Explore.getId(i, math.random(#g_shareData.exploreRepository[i])))
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
		if args.index > 4 or args.index < 0 then
			errorCode = -1
			break
		end
		local con = user.explore:getCon( args.index )
		local serId = Explore.getSerId( con )
		local serLv = Explore.getSerLv( con )
		local dat = g_shareData.exploreRepository[serId][serLv]
		if dat.n32Level > getAccountLevel( user.account:getExp() ) then
			errorCode = -1
			break
		end

		--
		--user.explore:setUuid(index, args.uuid)
		
	until true
	
	return {errorCode=errorCode, uuid=args.uuid, index=args.index}
end

function REQUEST.exploreBegin( args )
	local errorCode = 0
	repeat
		for i=0, 4 do
			local u = user.explore:getUuid( i )
			if u then
				errorCode = 0
				break
			else
				errorCode = -1
			end
		end
		if errorCode ~= 0 then break end

		if user.explore:getTime() ~= 0 then
			errorCode = -1
			break
		end
		--
		local nextTime = calcNextTime( { {hour=24, min=0, sec=0} } )
		user.cards:setExplore(args.uuid0, nexyTime)
		user.cards:setExplore(args.uuid1, nexyTime)
		user.cards:setExplore(args.uuid2, nexyTime)
		user.cards:setExplore(args.uuid3, nexyTime)
		user.cards:setExplore(args.uuid4, nexyTime)
		user.explore:begin(args.uuid0, args.uuid1, args.uuid2, args.uuid3, args.uuid4)
	until true
	
	return {errorCode=errorCode}
end

function REQUEST.exploreEnd( args )
	local errorCode = 0
	repeat
		if user.explore:getTime() < os.time() then
			errorCode = -1
			break
		end
		--
		
	until true
	return {errorCode=errorCode}
end

return Explore.new()
