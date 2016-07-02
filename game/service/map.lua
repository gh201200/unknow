local skynet = require "skynet"
local snax = require "snax"
local IMapPlayer = require "entity.IMapPlayer"
local vector3 = require "vector3"

local max_number = 4
local roomid
local gate
local users = {}

function accept.move(playerId, args)
	print("playerId = "..playerId)
	print("x = "..args.dir.x.." y = "..args.dir.y.." z = "..args.dir.z)
	local ret = {pos = vector3.create(1,2,3), dir = vector3.create(0,2,0)}
	return {pos = {x=6,y=3,z=2}, dir = {x=4,y=6,z=7}}
end

function response.move000(playerId, args)
	print("playerId = "..playerId)
	print("x = "..args.dir.x.." y = "..args.dir.y.." z = "..args.dir.z)
	local ret = {pos = vector3.create(1,2,3), dir = vector3.create(0,2,0)}
	return {pos = {x=6,y=3,z=2}, dir = {x=4,y=6,z=7}}
end

function response.join(fd)
	local player = IMapPlayer.create()
	player.serverId = fd
	table.insert(users, player)
end

function response.leave(session)
	
end

function response.query(session)
	
end

function init()
	
end

function exit()
	
end


