local skynet = require "skynet"
local snax = require "snax"
local Time = require "time"

local Explore = class("Explore")

local user
local REQUEST = {}
local COLOR_C = {
	0,3,6,9,12
}


function Explore:ctor()
	self.request = REQUEST
end

function Explore:init( u )
	user = u
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
		if args.index > 2 or args.index < 0 then
			errorCode = -1
			break
		end
		local explore = user.explore:getExplore( args.expuuid )
		if explore.time ~= 0 then
			errorCode = -1
			break
		end
		--
		--user.explore:setUuid(index, args.uuid)
		
	until true
	
	return {errorCode=errorCode, uuid=args.uuid, index=args.index,expuuid=args.expuuid}
end

function REQUEST.exploreBegin( args )
	local errorCode = 0
	local unit = user.explore:getExplore( args.uuid )
	repeat
		if string.len(args.uuid0) == 0 and string.len(args.uuid1) == 0 and string.len(args.uuid2) == 0 then
			errorCode = -1
			break
		end
		if unit.time ~= 0 then
			errorCode = -1
			break
		end
		
		--
		local nextTime = Time.tomorrow()
		for i=0, 2 do
			if string.len(args["uuid"..i]) > 0 then
				user.cards:setExplore(args["uuid"..i], nextTime)
			end
		end
		user.explore:beginExplore("exploreBegin", args)
	until true
	
	return {errorCode=errorCode, uuid = args.uuid}
end

function REQUEST.exploreEnd( args )
	local errorCode = 0
	local r = {}
	local unit = user.explore:getExplore( args.uuid )
	repeat

		if unit.time > os.time() then
			errorCode = -1
			break
		end
		
		--
		local gains = {}
		local score = 0
		local exploreDat = g_shareData.exploreRepository[unit.dataId]
		for i=0, 2 do
			local card = user.cards:getCardByUuid( unit['uuid'..i] )
			if card then
				local color_c = 3
				local con_c = 10
				local dat = g_shareData.heroRepository[card.dataId]
				if dat.n32Color >= exploreDat.n32Color  then
					color_c = color_c + COLOR_C[exploreDat.n32Color]
				end
				if unit["att"..i] == dat.n32MainAtt then
					con_c = con_c + 5
				end
				if bit_and(unit["cam"..i], dat.n32Camp) ~= 0 then
					con_c = con_c + 5
				end
				score = score +  color_c * con_c
			end
		end
		score = score * exploreDat.n32Time / 3600
		local cn = math.floor(score * exploreDat.n32CardC)
		
		for i=1, cn do
			local rets = usePackageItem(exploreDat.n32CardItemId, user.level )
			for k, v in pairs(rets) do
				local hit = false
				for _k,_v in pairs(r) do
					if _v.x == k then
						_v.y = _v.y + 1
						hit = true
						break
					end
				end
				if hit == false then
					table.insert(r,{x=k, y=v})
				end
			end
			user.servicecmd.addItems("exploreEnd", rets)
		end
		local sn = math.floor(score * exploreDat.n32SkillC)
		for i=1, sn do
			local rets = usePackageItem(exploreDat.n32SkillItemId, user.level )
			local hit = false
			for k, v in pairs(rets) do
				for _k,_v in pairs(r) do
					if _v.x == k then
						_v.y = _v.y + 1 
						hit = true
						break
					end
				end
				if hit == false then
					table.insert(r,{x=k, y=v})
				end
			end
			user.servicecmd.addItems("exploreEnd", rets)
		end
		user.account:addGold("exploreEnd", math.floor(score * exploreDat.n32GoldC))
		user.explore:resetExplore("exploreEnd", unit.uuid)	
	until true
	return {errorCode=errorCode, uuid=args.uuid, items=r}
end

function REQUEST.exploreRefresh( args )
	local errorCode = 0
	local unit = user.explore:getExplore( args.uuid )
	repeat
		if unit.time ~= 0 then
			errorCode = -1
			break
		end

		local costMoney = 0
		local val = user.activitys:getValue(ActivityAccountType.RefreshExplore)
		if val >= Quest.RefreshExploreTimes then 
			costMoney = Quest.RefreshExploreCost
		end
		if costMoney > user.account:getMoney() then
			errorCode = 1
			break
		end
		if costMoney ~= 0 then
			if not user.account:haveExploreTimes() then
				errorCode = 2
				break
			else
				--扣除次数
				user.account:addExploreTimes(-1)
			end
		end
		
		
		--
		user.account:addMoney("exploreRefresh", -costMoney)
		user.activitys:addValue("exploreRefresh", ActivityAccountType.RefreshExplore, 1,Time.tomorrow())
		user.explore:resetExplore("exploreRefresh", unit.uuid)	
	until true
	return {errorCode=errorCode, uuid=args.uuid}
end

return Explore.new()
