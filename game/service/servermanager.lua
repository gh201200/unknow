local skynet = require "skynet"

local roomAccount = {}	

function init()
end

function exit()

end

-------------------------------------------------------
--REQUSET

function response.getroomad(aid)
	return roomAccount[aid]
end

function response.getroomif(aid)
	if not roomAccount[aid] then return nil end
	local ret = skynet.call(roomAccount[aid], "lua", "getRoomInfo")
	return ret, roomAccount[aid] 
end


-------------------------------------------------------
--POST

function accept.roomstart(room, players)
	print('room start ', room)
	for k, v in pairs(players) do
		roomAccount[v.account] =  room
	end
end

function accept.roomend(room)
	print('room end ', room)
	for k, v in pairs(roomAccount) do
		if v == room then
			roomAccount[k] = nil
		end
	end
end

