local skynet = require "skynet"
local syslog = require "syslog"

local units = {} 
local database = nil

local function calcUid(name, atype)
	return name .. '$' .. atype
end

local function calcNameType(uid)
	local t =  string.split(uid, '$')
	return t[1], tonumber(t[2])
end

local function create_activity(uid, aid, atype, val)
	return {uid=uid, accountId=aid, atype=atype, value=val}
end

local function loadSystem()
	database = skynet.uniqueservice("database")
	for k, v in pairs(ActivitySysType) do
		local uid = calcUid('system', v)
		local unit  = skynet.call (database, "lua", "activity_rd", "load", uid)
		if unit then
			unit.uid  = uid
			units[uid] = unit
		end
	end
end

---------------------------------------------------------
--GET

function response.getAllSystem()
	local r = {}
	for k, v in pairs(ActivitySysType) do
		local uid = calcUid('system', v)
		if units[uid] and units[uid].expire > os.time() then
			table.insert(r, units[uid])
		end
	end
	return r
end


function response.getValue(name, atype)
	local uid = calcUid(name, atype)
	if units[uid] and units[uid].expire > os.time() then
		return units[uid].value
	end
	return 0
end

function response.getValueByUid( uid )
	if units[uid] and units[uid].expire > os.time() then 
		return units[uid].value
	end
	return 0
end

function response.addValue(op, name, atype, val, expire)
	local uid = calcUid(name, atype)
	if not expire then
		expire = math.maxinteger
	end
	if units[uid] then
		units[uid].value = self.units[uid].value + val
		units[uid].expire = expire
		skynet.call (database, "lua", "activity_rd", "update", units[uid], 'value')
	else
		units[uid] = create_activity(uid, name, atype, val)
		units[uid].expire = expire
		skynet.call (database, "lua", "activity_rd", "update", units[uid], 'accountId', 'atype', 'value', 'expire')
	end

	--log record
	syslog.infof("op[%s]player[%s]:addValue:%d,%d", op, name, atype, val)
	
	return units[uid].value
end

function response.setValue(op, name, atype, val, expire)
	local uid = calcUid(name, atype)	
	if not expire then
		expire = math.maxinteger
	end

	if units[uid] then
		units[uid].value = val
		units[uid].expire = expire
		skynet.call (database, "lua", "activity_rd", "update", units[uid], 'value')
	else
		units[uid] = create_activity(uid, name, atype, val)
		units[uid].expire = expire
		skynet.call (database, "lua", "activity_rd", "update", units[uid], 'accountId', 'atype', 'value', 'expire')
	end

	--log record
	syslog.infof("op[%s]player[%s]:setValue:%d,%d", op, name, atype, val)
	
	return units[uid].value
end

------------------------------------------------
--POST
function accept.loadAccount( aid )
	for k, v in pairs(ActivityAccountType) do
		local uid = calcUid(aid, v)
		local unit  = skynet.call (database, "lua", "activity_rd", "load", uid)
		
		if unit and unit.expire > os.time() then
			unit.uid  = uid
			units[uid] = unit
		end
	end
end

function accept.resetAccountValue(op, types, expire )
	for k, v in pairs(units) do
		for p, q in pairs(types) do
			if v.atype == q then
				v.value = 0
				v.expire = expire
				break
			end
		end
	end
	
	--log record
	syslog.infof("op[%s]player[%s]:resetAccountValue:%d", op, 'system', types[1])
end


----------------------------------------------------------------
----------------------
function init()
	loadSystem()
end

function exit()
end


