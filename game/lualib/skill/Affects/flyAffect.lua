local Affect = require "skill.Affects.Affect"
local flyAffect = class(Affect,"flyAffect")

function flyAffect:ctor(owner,source,data)
	super.ctor(self,owner,source,data)
end

