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
	ncard = 5,		--card表切割数
	savecd = 2,		--保存间隔(s)
	savenum = 10000,	--单次保存数目
}

local database_config = { center = center, group = group, mysql = mysql }

return database_config
