local skynet = require "skynet"

local roomAccount = {}	
local roomAgent = {}
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

function response.getAgent(account)
	local map = roomAccount[account]
	if map == nil then return nil end
	local offLinetime = skynet.call(map, "lua", "getOffLineTime", {id=account})
	if offLinetime < 90 then 
		return roomAgent[account]
	else
		return nil
	end
end


-------------------------------------------------------
--POST
function accept.roomend(room)
	print('room end ', room)
	for k, v in pairs(roomAccount) do
		if v == room then
			local ref = skynet.call(roomAgent[k],"lua","addConnectRef",-1) 
			if ref <=  0 then
				skynet.send(roomAgent[k],"lua","disconnect")
			end
			roomAgent[k] = nil
			roomAccount[k] = nil
		end
	end
end

function accept.roomstart(room, players)
	print('room start ', room)
	for k, v in pairs(players) do
		roomAccount[v.account] =  room
		roomAgent[v.account] = v.agent 
		skynet.call(v.agent,"lua","addConnectRef",1)
	end
end


