local skynet = require "skynet"

local syslog = require "syslog"
local handler = require "agent.handler"


local REQUEST = {}
local user
handler = handler.new (REQUEST)

handler:init (function (u)
	user = u
end)

function REQUEST.CastSkill(args)
	assert (args and args.skillid)
	local skillid = args.skillid
	print("castskill:" .. skillid)
	user.entity.m_spell.cast(skillid) 
	return { }
end



return handler
