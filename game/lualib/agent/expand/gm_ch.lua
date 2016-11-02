
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
	
end

function CMD.gm_add_money( args )
	print ( args )
	user.account:addGold("gm_add_money", args.gold)
	user.account:addMoney("gm_add_money", args.money)
end

function CMD.gm_add_card( args )
	user.cards:addCard("gm_add_card", args.dataId, args.cardNum)
end



return GMCH.new()
