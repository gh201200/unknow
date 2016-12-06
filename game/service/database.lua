local skynet = require "skynet"
local redis = require "redis"
local config = require "config.database"
local account = require "db.account_rd"
local cards = require "db.cards_rd"
local explore = require "db.explore_rd"
local cooldown = require "db.cooldown_rd"
local activity = require "db.activity_rd"
local skills = require "db.skills_rd"

local center
local group = {}
local ngroup

function connection_handler (key)
	local hash
	local t = type (key)
	if t == "string" then
		hash = hash_str (key)
	else
		hash = hash_num (assert (tonumber (key)))
	end

	return group[hash % ngroup + 1]
end


local MODULE = {}
local function module_init (name, mod)
	MODULE[name] = mod
	mod.init (connection_handler)
end

local CMD = {}
function CMD.flushdb()
	for k, v in pairs(group) do
		v:flushdb()
	end
end

MODULE['CMD'] = CMD


local traceback = debug.traceback

skynet.start (function ()
	module_init ("account", account)
	module_init ("cards", cards)
	module_init ("explore", explore)
	module_init ("cooldown", cooldown)
	module_init ("activity", activity)
	module_init ("skills", skills)
	
	center = redis.connect (config.center)
	ngroup = #config.group
	for _, c in ipairs (config.group) do
		table.insert (group, redis.connect (c))
	end

	skynet.dispatch ("lua", function (_, _, mod, cmd, ...)
		local m = MODULE[mod]
		if not m then
			skynet.error("module is nil: " .. mod)
			return skynet.ret ()
		end
		local f = m[cmd]
		if not f then
			skynet.error("cmd is nil: " .. cmd)
			return skynet.ret ()
		end
		
		local function ret (ok, ...)
			if not ok then
				skynet.ret ()
			else
				skynet.retpack (...)
			end

		end
		ret (xpcall (f, traceback, ...))
	end)
end)

