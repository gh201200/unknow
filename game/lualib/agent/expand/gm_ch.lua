
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


function CMD.gm_add_money( args )
	user.account:addGold("gm_add_money", args.gold)
	user.account:addMoney("gm_add_money", args.money)
end

function CMD.gm_add_card( args )
	user.cards:addCard("gm_add_card", args.dataId, args.cardNum)
end



return GMCH.new()
