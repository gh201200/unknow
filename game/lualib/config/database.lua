local host = "127.0.0.1"
local port = 6379
local db = 0

local center = {
	host = host,
	port = port,
	db = db,
}

local ngroup = 1
local group = {}
for i = 1, ngroup do
	table.insert (group, { host = host, port = port + i - 1 , db = db })
end

local mysql = {
	host = host,
	port = 3306,
	database = "threehero",
	user = "root",
	password = "123456",
	max_packet_size = 1024*1024,
	savecd = 5,		--保存间隔(s)
	savenum = 10000,	--单次保存数目
	expire = 2*24*60*60,	--玩家数据过期时间
}

local database_config = { center = center, group = group, mysql = mysql }

return database_config
