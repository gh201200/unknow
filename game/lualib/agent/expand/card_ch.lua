local skynet = require "skynet"

local CardCh = class("CardCh")

local user
local REQUEST = {}

function CardCh:ctor()
	self.REQUEST = REQUEST
end

function CardCh:init( u )
	user = u
end

return CardCh.new()
