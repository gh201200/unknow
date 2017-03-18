local ActivitysMethod = require "agent.activitys_method"

local activitys = nil

---------------------------------------------------------
--GET

function response.getValue(atype)
	local uid = calcUid(activitys.account_id, atype)
	if activitys.units[uid] and activitys.units[uid].expire > os.time() then
		return activitys.units[uid].value
	end
	return 0
end

function response.getValueByUid( uid )
	return activitys:getValueByUid( uid )
end

------------------------------------------------
--POST

function accept.addValue(op, atype, val, expire)
	activitys:addValue(op, atype, val, expire)
end

function accept.setValue(op, atype, val, expire)
	activitys:setValue(op, atype, val, expire)
end


----------------------------------------------------------------
----------------------
function init()
	activitys = { account_id = 'system' }
	setmetatable(activitys, {__index = ActivitysMethod})
	activitys:loadSystem()
end

function exit()
end


