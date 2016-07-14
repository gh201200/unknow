local Repository = class("Repositiory")

function Repository:ctor()
	self.gdd = nil
end

function Repository.getData(repName, id)
	local r = Repository.gdd[repName]
	if not r then return nil end
	return r[id]
end


return Repository
