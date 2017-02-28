
function bit(n)
	return 1<<n
end

function bit_and(a, b)
	return a & b
end

function bit_or(a, b)
	return a | b
end

function bit_not(a)
	return ~a
end

function mClamp(a, min, max)
	if a < min then return min end
	if a > max then return max end
	return a
end

--判断点是否在矩形范围
function ptInRect(p,rectPts)
	local size = 4 
	local ncross = 0
	for i=0,size-1,1 do
		while true do
			local p1 = rectPts[i]
			local p2 = rectPts[(i+1)% size ]
			if p1.z == p2.z then break end
			if p.z >= math.max(p1.z,p2.z) then break end
			if p.z < math.min(p1.z,p2.z) then break end
			local x = (p.z - p1.z) * (p2.x - p1.x) / (p2.z - p1.z) + p1.x
			if x > p.x then
				ncross = ncross + 1
			end
			break
		end		
	end
	if ncross % 2 == 1 then
		return true
	end
	return false
end

--判断点是否在扇形范围内
function ptInSector(pt,center,udir,r,theta)
	--print("ptInSector pt:",pt.x,pt.z)
	--print("ptInSector center:",center.x,center.z)
	--print("ptInSector udir:",udir.x,udir.z)
	--print("ptInSector r:",r,"theta",theta)
	local dx = pt.x - center.x
	local dz = pt.z - center.z
	local length = math.sqrt(dx * dx + dz * dz)
	if length > r then
		return false
	end
	dx = dx / length
	dz = dz / length
	local deg = math.deg(math.acos(dx * udir.x + dz * udir.z))
	--print("deg======:",deg,"theta",theta)
	return deg < theta
end
--------common func to register get set-----------
function register_class_var(t, name, iv, callBack)
	t['m_'..name] = iv
	t['set'..name] = function(self, v)
		t['m_'..name] = v
		if callBack then
			callBack(self)
		end
	end
	t['get'..name] = function(self)
		return t['m_'..name]
	end
	if type(iv) == "number" then
		t['add'..name] = function(self, v)
			if v == 0 then return end
			t['m_'..name] = t['m_'..name] + v
			if callBack then
				callBack(self)
			end
		end
	end
	
end

local server_id = 0
function assin_server_id()
	server_id = server_id + 1
	return server_id
end


-------serialize table----------------------------
function serialize_table(t)
	local mark={}
	local assign={}
	local function ser_table(tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			local key = (type(k)=="number" and "["..k.."]") or k
			if type(v)=="table" then
				local dotkey = parent..type(k)=="number" and key or ("."..key)
				if mark[v] then
					table.insert(assign,dotkey.."="..mark[v])
				else
					table.insert(tmp, key.."="..ser_table(v,dotkey))
				end
			elseif type(v) == "string" then
				table.insert(tmp, key.."='"..v.."'")
			elseif type(v) == 'boolean' then
				if v then
					table.insert(tmp, key.."=true")
				else
					table.insert(tmp, key.."=false")
				end
			elseif type(v) == 'number' then
				table.insert(tmp, key.."="..v)
			end
		end
		return "{"..table.concat(tmp,",").."}"
		
	end
	
	return "do local ret="..ser_table(t,"ret")..table.concat(assign," ").." return ret end"
end

function serialize(t)
	local mark={}
	local assign={}
 
	local function ser_table(tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			repeat
				if k == "doNotSavebg" then break end
	
				local key = type(k)=="number" and "["..k.."]" or k
			
				if type(v)=="table" then
					local dotkey= parent..(type(k)=="number" and key or "."..key)
					if mark[v] then
						table.insert(assign,dotkey.."="..mark[v])
					else
						table.insert(tmp, key.."="..ser_table(v,dotkey))
					end
				elseif type(v) == "string" then
					table.insert(tmp, key.."=\""..v.."\"")
				else
					table.insert(tmp, key.."="..v)
				end
			until true
		end
		return "{"..table.concat(tmp,",").."}"
	end
 
	return "do local ret="..ser_table(t,"ret")..table.concat(assign," ").." return ret end"
end

------------------------
-- get card serial id
function Macro_GetCardSerialId(_id)
	return math.floor(_id / 100)
end
--get card color
function Macro_GetCardColor(_id)
	return _id%100
end
--Get card data id
function Macro_GetCardDataId(serId, color)
	return serId*100 + color
end
--Get skill serial id
function Macro_GetSkillSerialId(_id)
	return math.floor(_id / 1000)
end
--Get skill grade
function Macro_GetSkillGrade( _id )
	return math.floor(_id % 1000 / 10)
end
--add skill grade
function Macro_AddSkillGrade( _id, grade )
	return _id + grade * 10
end
--get mission serial id
function Macro_GetMissionSerialId( _id )
	return math.floor(_id / 1000)
end
--get mission data id
function Macro_GetMissionDataId( _serId, lv )
	return _serId * 1000 + lv
end
function openPackage( strPkg, userLv )
	print("openPackage", strPkg, userLv)
	local drops = {}
	local str1 = string.split(strPkg, ";")
	for k, v in pairs( str1 ) do
		local str2 = string.split(v, ",")
		drops[tonumber(str2[1])] = tonumber(str2[2])
	end

	local pkgIds = {}
	for k, v in pairs(drops) do
		for i=1, v do
			local dropDat = g_shareData.dropPackage[k]
			local num = math.random(dropDat[1].n32MinNum, dropDat[1].n32MaxNum)
			for j=1, num do
				local r = 0
				local rd = math.random(1, dropDat.totalRate)
				for p, q in pairs(dropDat) do
					if type(q) == "table" then
						if q.n32Rate >= rd then
							r = q.n32DropId
							break
						end
					end
				end
				table.insert(pkgIds, r)
			end
		end
	end
	local items = {}
	for k, v in pairs(pkgIds) do
		local drop = g_shareData.itemDropPackage[v]
		local filterdrops = {}
		if userLv then
			local tr = 0
			for p, q in pairs(drop) do
				if type(q) == "table" then
					if q.n32ArenaLvUpLimit <= userLv and q.n32ArenaLvLwLimit >= userLv then
						table.insert(filterdrops, q)
						tr = tr + q.n32Rate
						q.n32Rate = tr
					end
				end
			end
			filterdrops.totalRate = tr
		else
			filterdrops = drop
		end
		if filterdrops.totalRate >= 1 then
			local rd = math.random(1, filterdrops.totalRate)
			local r = nil
			for p, q in pairs(filterdrops) do
				if type(q) == "table" then
					if q.n32Rate >= rd then
						r = q
						break
					end
				end
			end
			local itemId = r.n32ItemId
			local itemNum = math.random(r.n32MinNum, r.n32MaxNum)
			if not items[itemId]  then
				items[itemId] = itemNum
			else
				items[itemId] = items[itemId] + itemNum
			end
		end
	end
	return items
end

function usePackageItem( itemId, lv )
	print( itemId )
	local itemDat = g_shareData.itemRepository[itemId]
	if itemDat.n32Type ~= 4 then
		return {}
	end
	local items = openPackage( itemDat.szRetain3, lv )
	return items
end

function hash_str (str)
	local hash = 0
	string.gsub (str, "(%w)", function (c)
		hash = hash + string.byte (c)
	end)
	return hash
end

function hash_num (num)
	local hash = num << 8
	return hash
end

function GET_SkillTgtType(data)
	assert(data,"getskillTgtType data is null")
	local t = math.floor(data.n32Type / 10)
	return t
end

function GET_SkillTgtRange(data)
	assert(data,"getskillTgtRange data is null")
	local t = data.n32Type % 10
	return t
end

function calcVersionCode( version )
	local codes = string.split(version, ".")
	return codes[1] * 100000000 + codes[2] * 1000000 + codes[3] * 10000 + codes[4]
end


