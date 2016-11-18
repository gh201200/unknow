
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


------------------------
-- get card serial id
function Macro_GetCardSerialId(_id)
	return math.floor(_id / 10)
end
--get card color
function Macro_GetCardColor(_id)
	return _id%10
end
--Get card data id
function Macro_GetCardDataId(serId, color)
	return serId*10 + color
end

function getAccountLevel( _exp )
	local lv = 1
	for k, v in pairs(g_shareData.accountLevel) do
		if _exp <= v.n32Exp then
			return v.id
		end
		lv = v.id
	end
	return lv
end
