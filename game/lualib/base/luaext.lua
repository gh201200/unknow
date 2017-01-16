-- lua扩展

-- table扩展

-- 返回table大小
table.size = function(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- 判断table是否为空
table.empty = function(t)
    return not next(t)
end

-- 返回table索引列表
table.indices = function(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, k)
    end
end

-- 返回table值列表
table.values = function(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, v)
    end
end

-- 浅拷贝
table.clone = function(t, nometa)
    local result = {}
    if not nometa then
        setmetatable(result, getmetatable(t))
    end
    for k, v in pairs (t) do
        result[k] = v
    end
    return result
end

-- 深拷贝
table.copy = function(t, nometa)   
    local result = {}

    if not nometa then
        setmetatable(result, getmetatable(t))
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = copy(v)
        else
            result[k] = v
        end
    end
    return result
end

table.merge = function(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end
--查看表是否包含键值
function table.containKey( t, key )
    for k, v in pairs(t) do
        if key == k then
            return true;
        end
    end
    return false;
end
--计算两个表相交
function table.calCross(tab1,tb2)
        local left = {}
        local mid = {}
        local right = {}
        for _k,_v in pairs(tab1) do
                if table.containKey(tb2,_v) == true then
                        table.insert(mid,_v)
                end
        end
        for _k,_v in pairs(tab1) do
                if table.containKey(mid,_v) == false then
                        table.insert(left,_v)
                end
        end
        for _k,_v in pairs(tab2) do
                if table.containKey(mid,_v) == false then
                        table.insert(right,_v)
                end
        end
        return mid,left,right
end
--打包为redis存储格式
function table.packdb(unit, ...)
	local r = {}
	local p = { ... }
	if next(p) then
		for k, v in pairs( p ) do
			if v then
				r[2*k-1] = v
				r[2*k] = unit[v]
			end
		end
	else
		local i = 1
		for k, v in pairs(unit) do
			if k ~= "doNotSavebg" and k ~= "uuid" and v then
				r[i] = k
				r[i+1] = v
				i = i + 2	
			end
		end
	end
	return table.unpack(r)
end
--打包为sql格式
function table.packsql(unit)
	local keys = ""
	local bk = false
	local values = ""
	local bv = false
	for k, v in pairs(unit) do
		if bk then
			keys = keys .. "," .. k
		else
			keys = k
			bk = true
		end
		if bv then
			if type(v) == 'string' then
				values = values .. ",\'" .. v .."\'"
			else
				values = values .. "," .. v
			end
		else
			if type(v) == 'string' then
				values = "\'" .. v .. "\'"
			else
				values = v
			end
			bv = true
		end	
	end
	return keys, values
end
-- string扩展

-- 下标运算
do
    local mt = getmetatable("")
    local _index = mt.__index

    mt.__index = function (s, ...)
        local k = ...
        if "number" == type(k) then
            return _index.sub(s, k, k)
        else
            return _index[k]
        end
    end
end

string.split = function(s, delim)
    local split = {}
    local pattern = "[^" .. delim .. "]+"
    string.gsub(s, pattern, function(v) table.insert(split, v) end)
    return split
end

string.ltrim = function(s, c)
    local pattern = "^" .. (c or "%s") .. "+"
    return (string.gsub(s, pattern, ""))
end

string.rtrim = function(s, c)
    local pattern = (c or "%s") .. "+" .. "$"
    return (string.gsub(s, pattern, ""))
end

string.trim = function(s, c)
    return string.rtrim(string.ltrim(s, c), c)
end

string.parserskillStr = function(s)
	local t = {}
	for v in string.gmatch(s,"%[(.-)%]") do
		local data = {}
		for tp,vals in string.gmatch(v,"(%a+)%:(.+)") do
			vals = vals .. "," 
			table.insert(data,tp)
			local valtb = string.split(vals,",")
			for _,val in pairs(valtb) do
				if val ~= "" then
					table.insert(data,tonumber(val))
				end
			end 
		end
		table.insert(t,data)
	end
	return t 
end
local function dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end

do
    local _tostring = tostring
    tostring = function(v)
        if type(v) == 'table' then
            return dump(v)
        else
            return _tostring(v)
        end
    end
end

-- math扩展
do
	local _floor = math.floor
	math.floor = function(n, p)
		if p and p ~= 0 then
			local e = 10 ^ p
			return _floor(n * e) / e
		else
			return _floor(n)
		end
	end
end

math.round = function(n, p)
        local e = 10 ^ (p or 0)
        return math.floor(n * e + 0.5) / e
end

math.random_ext = function(n,p)
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
  	return math.random(n,p)
end

math.pow2 = function(x)
	return x * x
end

math.maxint32 = 0x7fffffff
math.maxuint32 = 0xffffffff

-- lua面向对象扩展
function class(classname, super)
    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    if superType == "function" or (super and super.__ctype == 1) then
        -- inherited from native C++ Object
        cls = {}

        if superType == "table" then
            -- copy fields from super
            for k,v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
            cls.ctor = function() end
        end

        cls.__cname = classname
        cls.__ctype = 1

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k,v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end

    else
        -- inherited from Lua Object
        if super then
            cls = {}
            setmetatable(cls, {__index = super})
            cls.super = super
        else
            cls = {ctor = function() end}
        end

        cls.__cname = classname
        cls.__ctype = 2 -- lua
        cls.__index = cls
        function cls.new(...)
            local instance = setmetatable({}, cls)
            instance.class = cls
            instance:ctor(...)
            
            return instance
        end
    end

    return cls
end

function iskindof(obj, classname)
    local t = type(obj)
    local mt
    if t == "table" then
        mt = getmetatable(obj)
    elseif t == "userdata" then
        mt = tolua.getpeer(obj)
    end

    while mt do
        if mt.__cname == classname then
            return true
        end
        mt = mt.super
    end

    return false
end
