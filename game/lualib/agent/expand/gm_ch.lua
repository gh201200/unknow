local skynet = require "skynet"
local snax = require "snax"

local GMCH = class("GMCH")

local user
local REQUEST = {}
local CMD = {}

local CLIENT_GM_CMD = {}

function GMCH:ctor()
	self.request = REQUEST
	self.cmd = CMD
end

function GMCH:init( u )
	user = u
end

function REQUEST.clientGMcmd( args )
	print ( args )
	CLIENT_GM_CMD[args.gmcmd]( args )
end

CLIENT_GM_CMD['addmoney'] = function( args )
	local p = { money=args.params[1], gold=args.params[2]}
	CMD.gm_add_money( p )
end;

CLIENT_GM_CMD['addlevel'] = function( args )
	local p = { exp=args.params[1], }
	CMD.gm_add_level( p )
end;

CLIENT_GM_CMD['addaexp'] = function( args )
	local p = { exp=args.params[1], }
	CMD.gm_add_aexp( p )
end;

CLIENT_GM_CMD['additem'] = function( args )
	local items = {}
	items[tonumber(args.params[1])] = tonumber(args.params[2])
	CMD.gm_add_items( items )
end;

CLIENT_GM_CMD['delitem'] = function( args )
	local items = {}
	items[tonumber(args.params[1])] = tonumber(args.params[2])
	CMD.gm_del_items( items )
end;


CLIENT_GM_CMD['addgold'] = function( args )
	local p = { id=user.account.account_id, gold=args.params[1] }
	skynet.call(user.MAP, "lua", "addgold", p)
end;

CLIENT_GM_CMD['addexp'] = function( args )
	local p = { id=user.account.account_id, exp=args.params[1] }
	skynet.call(user.MAP, "lua", "addexp", p)
end;


CLIENT_GM_CMD['addskill'] = function( args )
	local p = { id=user.account.account_id, skillId=math.floor(args.params[1])}
	skynet.call(user.MAP, "lua", "addskill", p)
end;

CLIENT_GM_CMD['endbattle'] = function( args )
	if user.MAP then
		local p = { id=user.account.account_id, code=tonumber(args.params[1]) }
		skynet.call(user.MAP, "lua", "endbattle", p)
	end
end;

CLIENT_GM_CMD['endmission'] = function( args )
	for k, v in pairs(user.missions.units) do
		if g_shareData.missionRepository[v.dataId].n32Content == tonumber(args.params[1]) then
			v.progress = g_shareData.missionRepository[v.dataId].n32Goal
			user.missions:updateMission("endmission", v)
		end
	end
end;

CLIENT_GM_CMD['setcd'] = function( args )
	local ctype = tonumber(args.params[1])
	local cdtime = tonumber(args.params[2])
	local cooldown = snax.uniqueservice("cddown")
	local activity = snax.uniqueservice("activity")
	if ctype == 1 then
		for k, v in pairs(user.cards.units) do
			if v.explore > os.time() then
				user.cards:setExplore(k, cdtime + os.time())
			end
		end
	elseif ctype == 2 then
		cooldown.post.setValue(1, cdtime)
	elseif ctype == 3 then
		user.cooldowns:setValue(1001, cdtime)
	elseif ctype == 4 then
		user.explore:setTime(cdtime)
	elseif ctype == 5 then
		user.missions:setDailyMissionTime(cdtime)
	elseif ctype == 6 then
		local atype = tonumber(args.params[3])
		local val = tonumber(args.params[4])
		local name = 'system'
		if atype > 1000 then
			name = user.account.account_id
		end
		if name == user.account.account_id then
			user.activitys:setValue("gm", atype, val, cdtime + os.time())
		else
			activity.post.setValue("gm", atype, val, cdtime + os.time())
		end
	end
end;

function CMD.gm_add_money( args )
	user.account:addGold("gm_add_money", args.gold)
	user.account:addMoney("gm_add_money", args.money)
end


function CMD.gm_add_items( args )
	user.servicecmd.addItems("gm_add_items", args)
end

function CMD.gm_del_items( args )
	for k, v in pairs(args) do
		local item = g_shareData.itemRepository[k]
		if item.n32Type == 3 then	--英雄卡
			local serId = Macro_GetCardSerialId(item.n32Retain1)
			local unit = user.cards:getCardBySerialId(serId)
			if unit then
				user.cards:delCardByUuid('gm_del_items', unit.uuid, v)
			end
		elseif item.n32Type == 7 then	--技能材料
			local serId = Macro_GetSkillSerialId(item.n32Retain1)
			local unit = user.skills:getSkillBySerialId(serId)
			if unit then
				user.skills:delSkillByUuid('gm_del_items', unit.uuid, v)
			end
		end
	end
end

function CMD.gm_add_level( args )
	user.account:addExp("gm_add_exp", args.exp)
end

function CMD.gm_add_aexp( args )
	user.account:addAExp("gm_add_aexp", args.exp)
end

return GMCH.new()
