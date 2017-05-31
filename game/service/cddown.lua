local skynet = require "skynet"
local snax = require "snax"
local sharedata = require "sharedata"
local CoolDownsMethod = require "agent.cooldowns_method"
local database = nil

local function RefreshShopCard()
	local activity = snax.queryservice 'activity'

	local st1 = {}
	local st2 = {}
	local st3 = {}
	
	for k, v in pairs(g_shareData.shopRepository) do
		if v.n32Type == 4 then
			if v.n32Site == 0 then
				table.insert(st1, v.id)
			elseif v.n32Site == 1 then
				table.insert(st2, v.id)
			elseif v.n32Site == 2 then
				table.insert(st3, v.id)
			end
		end		
	end
	local idx = math.random(1, #st1)
	activity.post.setValue('RefreshShopCard', ActivitySysType.ShopCardId1, st1[idx])
	idx = math.random(1, #st2)
	activity.post.setValue('RefreshShopCard', ActivitySysType.ShopCardId2, st2[idx])
	idx = math.random(1, #st3)
	activity.post.setValue('RefreshShopCard', ActivitySysType.ShopCardId3, st3[idx])
end

local function cooldown_updatesys()

	if cooldowns:isTimeout(CoolDownSysType.RefreshShopCard) then		--刷新卡牌商店	
		cooldowns:setTime(CoolDownSysType.RefreshShopCard, Quest.RefreshShopCardCD)
		
		local r, r1  = pcall(RefreshShopCard)
		if not r then
			error(r1)
		end
	end

	skynet.timeout(100,  cooldown_updatesys)
end


----------------------------------------------------
--REQ
function response.getRemainingTime( atype )
	return cooldowns:getRemainingTime( atype )
end

function response.getValue( atype )
	return cooldowns:getValue( atype )
end

function response.getValueByUid( uid )
	return cooldowns:getValueByUid( uid )
end


------------------------------------------------
--POST

function accept.setValue(atype, val)
	cooldowns:setTime(atype, val)
end

function accept.Start()
	cooldown_updatesys()
end


---------------------------------------------------------------
------------------------

function init()
	cooldowns = { account_id = 'system' }
	setmetatable(cooldowns, {__index = CoolDownsMethod})
	
	g_shareData = sharedata.query "gdd"
	DEF = g_shareData.DEF
	Quest = g_shareData.Quest
	
	cooldowns:loadSystem()
end

function exit()

end
