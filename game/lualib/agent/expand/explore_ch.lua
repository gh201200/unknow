local skynet = require "skynet"
local snax = require "snax"
local Quest = require "quest.quest"
local Time = require "time"

local Explore = class("Explore")

local user
local REQUEST = {}
local ExploreType = {
	MainAtt = 1,
	Camp = 2,
	Color = 3,
}


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
		if Macro_GetCardColor( card.dataId ) == 0 then
			errorCode = -1
			break
		end
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
		if dat.n32Level > user.level then
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
		local nextTime = Time.nextDay({hour=24, min=0, sec=0})
		nextTime = os.time( nextTime )
		user.cards:setExplore(args.uuid0, nextTime)
		user.cards:setExplore(args.uuid1, nextTime)
		user.cards:setExplore(args.uuid2, nextTime)
		user.cards:setExplore(args.uuid3, nextTime)
		user.cards:setExplore(args.uuid4, nextTime)
		user.explore:beginExplore("exploreBegin", args.uuid0, args.uuid1, args.uuid2, args.uuid3, args.uuid4)
	until true
	
	return {errorCode=errorCode}
end


local function isOkForExploreCon(card, conDat)
	local cardDat = g_shareData.heroRepository[card.dataId]
	if conDat.n32Type1 == ExploreType.MainAtt then
		if cardDat.n32MainAtt ~= conDat.n32Value1 then
			return false
		end
	end

	if conDat.n32Type1 == ExploreType.Camp then
		if cardDat.n32Camp ~= conDat.n32Value1 then
			return false
		end
	end
	
	if conDat.n32Type1 == ExploreType.Color then
		if cardDat.n32Color < conDat.n32Value1 then
			return false
		end
	end
	
	if conDat.n32Type2 == ExploreType.MainAtt then
		if cardDat.n32MainAtt ~= conDat.n32Value2 then
			return false
		end
	end

	if conDat.n32Type2 == ExploreType.Camp then
		if cardDat.n32Camp ~= conDat.n32Value2 then
			return false
		end
	end
	
	if conDat.n32Type2 == ExploreType.Color then
		if cardDat.n32Color < conDat.n32Value2 then
			return false
		end
	end
	
	return true
end

function REQUEST.exploreEnd( args )
	local errorCode = 0
	local gains = {}
	repeat
		if user.explore:getTime() > os.time() then
			errorCode = -1
			break
		end
		--
		for i=0, 4 do
			local uuid = user.explore:getUuid( i )
			local card =  user.cards:getCardByUuid( uuid )
			if card then
				local con = user.explore:getCon( i )
				local serLv = Explore.getSerLv( con )
				local conDat = g_shareData.exploreRepository[i+1][serLv]
				if not isOkForExploreCon(card, conDat) then
					conDat = g_shareData.exploreRepository[i+1][1]
				end

				local pkgs = usePackageItem( conDat.n32Drop, user.level )
				for k, v in pairs(pkgs) do
					table.insert(gains, {itemId=v.itemId, itemNum=v.itemNum})
				end
			end
		end
		user.servicecmd.addItems("exploreEnd", gains)
		user.explore:resetExplore("exploreEnd", Explore.randcon())	
	until true
	local vecs = {}
	for k, v in pairs(gains) do
		table.insert(vecs, {x=v.itemId,y=v.itemNum})
	end
	return {errorCode=errorCode,items=vecs}
end

return Explore.new()
