local skynet = require "skynet"
local redis = require "redis"
local sharedata = require "sharedata"
local config = require "config.database"
local MAX_NUM = 200
local conn

local rankGroup = {}

local function calcKey(atype)
	return "toprank"..atype
end

local function newRanks( sets )
	print( sets )
	local items = {}
	for i=1, #sets, 2 do
		local account = skynet.call(database, "lua", "account", "load", sets[i], "icon", "nick")
		print( account )
		local item = {
			score = sets[i+1],
			head = account[1],
			nick = account[2],
			factionicon = "10001.icon",
			factionname = "拜上帝教",	
		}
		table.insert(items, item)
	end
	return items
end

----------------------------------------------------
--REQ
function response.load( args )
	print ( args )
	local group = rankGroup[args.atype]
	if group.olddata then
		local sets = conn:zrevrange(calcKey(args.atype), 0, MAX_NUM, "WITHSCORES")
		group.rankItems = newRanks( sets )
		group.olddata = false
	end
	print( group.rankItems )
	local ret = {}
	for i=args.start+1, args.start+args.num do
		if not group.rankItems[i] then break end
		table.insert(ret, group.rankItems[i])
	end
	return ret
end

-----------------------------------------------------
--POST
function accept.add(atype, score, member)
	local key = calcKey(atype)
	score = score * 1000 + 999 - conn:zcount(key, score*1000, score*1000 + 999)

	local sets = conn:zrevrange( key, MAX_NUM, MAX_NUM , "WITHSCORES")
	if sets[1] then
		if tonumber(sets[2]) < score then
			conn:zrem(key, sets[1])
			conn:zadd(key, score, member)
			rankGroup[atype].olddata = true
		end
	else
		conn:zadd(key, score, member)
		rankGroup[atype].olddata = true
	end
end

-------------------------------------------------------------------
function init()
	g_shareData  = sharedata.query "gdd"
	DEF = g_shareData.DEF
	Quest = g_shareData.Quest

	database = skynet.uniqueservice ("database")
	conn = redis.connect (config.center)
	for k, v in pairs( Quest.RankType ) do
		local groupItem = {
			olddata = true,
			rankItems = {},
		}
		rankGroup[v] = groupItem	
	end
end

function exit()

end

