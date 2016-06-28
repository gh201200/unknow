local skynet = require "skynet"

local protoloader = require "proto.protoloader"

skynet.start (function ()
	protoloader.init ()
end)
