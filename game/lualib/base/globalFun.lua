
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
	--求取交集
	for _k,_v in pairs(tab1) do
		if table.containKey(tb2,_v) == true then
			table.insert(mid,_v)
		end
	end
	--左集合 - 交集
	for _k,_v in pairs(tab1) do
		if table.containKey(mid,_v) == false then
			table.insert(left,_v)
		end
	end
	--右集合 - 交集
	for _k,_v in pairs(tab2) do
		if table.containKey(mid,_v) == false then
			table.insert(right,_v)
		end
	end
	return mid,left,right
end
--字符串分割
function string.split(str, delimiter)
	if str==nil or str=='' or delimiter==nil then
		return nil
	end
	
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end
