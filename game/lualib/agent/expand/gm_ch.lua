local skynet = require "skynet"


local GMCH = class("GMCH")

local user
local REQUEST = {}
local CMD = {}

local CLIENT_GM_CMD = {
}



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

CLIENT_GM_CMD['addcard'] = function( args )
	local p = { dataId=args.params[1], cardNum=args.params[2]}
	CMD.gm_add_card( p )
end;

CLIENT_GM_CMD['additem'] = function( args )
	local items = {}
	items[tonumber(args.params[1])] = tonumber(args.params[2])
	CMD.gm_add_items( items )
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

function CMD.gm_add_money( args )
	user.account:addGold("gm_add_money", args.gold)
	user.account:addMoney("gm_add_money", args.money)
end

function CMD.gm_add_card( args )
	user.cards:addCard("gm_add_card", args.dataId, args.cardNum)
end

function CMD.gm_add_items( args )
	user.servicecmd.addItems("gm_add_items", args)
end



return GMCH.new()
