
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

local MAP_GRID_SIZE = 1
function POS_2_GRID(p)
	return math.floor(p/MAP_GRID_SIZE)
end

function GRID_2_POS(g)
	return G * MAP_GRID_SIZE
end

function IS_SAME_GRID(v1, v2)
	local g1_x = POS_2_GRID(v1.x)
	local g1_z = POS_2_GRID(v1.z)
	local g2_x = POS_2_GRID(v2.x)
	local g2_z = POS_2_GRID(v2.z)
	return g1_x==g2_x and g1_z==g2_z
end

function mClamp(a, min, max)
	if a < min then return min end
	if a > max then return max end
	return a
end

function ptInRect(p,rectPts)
	local size = #rectPts
	local ncross = 0
	for i=1,size,1 do
		while true do
			local p1 = rectPts[i]
			local p2 = rectPts[(i+1)% size ]
			if p1.y == p2.y then break end
			if p.y >= math.max(p1.y,p2.y) then break end
			if p.y < math.min(p1.y,p2.y) then break end
			local x = (p.y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y) + p1.x
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
function register_class_var(t, name, iv)
	t['m_'..name] = iv
	t['set'..name] = function(self, v)
		t['m_'..name] = v
	end
	t['get'..name] = function(self)
		return t['m_'..name]
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
function getCardSerialId(_id)
	return math.floor(_id / 10)
end
--get card color
function getCardColor(_id)
	return _id%10
end
