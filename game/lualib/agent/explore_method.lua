local skynet = require "skynet"
local syslog = require "syslog"
local uuid = require "uuid"

local ExploreMethod =
{
	--
	sendExploreData = function(self, unit)
		if unit then
			local p = table.clone( unit )
			if p.time ~= 0 then
				p.time = p.time - os.time()
			end
			agentPlayer.send_request("sendExplore", {exploresList = {p}})
		else
			local exploresList = {}
			for k, v in pairs(self.units) do
				local p = table.clone( v )
				if p.time ~= 0 then
					p.time = p.time - os.time()
				end
				table.insert( exploresList, p )
			end
			agentPlayer.send_request("sendExplore", {exploresList = exploresList})
		end
	end;
	--
	getExplore = function(self, _uuid)
		return self.units[_uuid]
	end;
	--
	getTime = function(self, _uuid)
		return self.units[_uuid].time
	end;
	--
	initExplore = function(level, num)
		local t = {}
		local sum = 0
		local r = 0
		for k, v in pairs(g_shareData.exploreRepository) do
			r = v.n32RandC1 + v.n32RandC2 * level
			sum = sum + r
			table.insert(t, {id=k, rate=sum})
		end
		local r = {}
		for i=1, num do
			local rd = math.random(1, sum)
			for k, v in pairs(t) do
				if v.rate >= rd then
					local dat = g_shareData.exploreRepository[v.id]
					local u = {uuid = uuid.gen()}
					u.dataId = v.id
					u.att0 = math.random(1, 3)
					u.cam0 = math.random(1, 3)
					u.cam1 = math.random(1, 3)
					u.att1 = math.random(1, 3)
					u.cam2 = math.random(1, 3)
					u.att2 = math.random(1, 3)
					u.uuid0 = ""
					u.uuid1 = ""
					u.uuid2 = ""
					u.time = 0
					if dat.n32Color == 2 then
						for j=0, 2 do
							local half = math.random(1, 10000)
							if half < 5000 then
								u['att'..j] = 0
							else
								u['cam'..j] = 0
							end
						end
					elseif dat.n32Color == 3 then
						for j=1, 2 do
							local half = math.random(1, 10000)
							if half < 5000 then
								u['att'..j] = 0
							else
								u['cam'..j] = 0
							end
						end
					elseif dat.n32Color == 4 then
						local half = math.random(1, 10000)
						if half < 5000 then
							u['att2'] = 0
						else
							u['cam2'] = 0
						end
					end
					table.insert(r, u)
					break
				end
			end
		end
		return r
	end;
	--
	resetExplore = function(self, op, _uuid)
		local v = self.units[_uuid]
		local t = self.initExplore(agentPlayer.level, 1)
		t[1].uuid = _uuid
		table.merge(v, t[1])
	
		self:sendExploreData(v)
		
		local database = skynet.uniqueservice("database")
		skynet.call(database, "lua", "explores", "update", self.account_id, v) 
	end;
	--
	beginExplore = function(self, op, args)
		local unit = self.units[args.uuid]
		local dat = g_shareData.exploreRepository[unit.dataId]
		unit.time = os.time() + dat.n32Time
		unit["uuid0"] = args.uuid0
		unit["uuid1"] = args.uuid1
		unit["uuid2"] = args.uuid2

		self:sendExploreData(unit)

		local database = skynet.uniqueservice("database")
		skynet.call(database, "lua", "explores", "update", self.account_id, unit, "time", "uuid0", "uuid1", "uuid2")
	end;
}

return ExploreMethod
