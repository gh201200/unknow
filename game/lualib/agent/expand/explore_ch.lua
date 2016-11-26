local skynet = require "skynet"
local snax = require "snax"

local Explore = class("Explore")

local user
local REQUEST = {}

function Explore:ctor()
	self.request = REQUEST
end

function Explore:init( u )
	user = u
end

return Explore.new()
