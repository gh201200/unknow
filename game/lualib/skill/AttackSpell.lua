local spell = require "skill.spell"
local AttackSpell = class("AttackSpell",spell)

function AttackSpell:ctor(entity,source,data)
	self.super.ctor(self,entity,source,data)
	self.attachdatas = {}
end

function AttackSpell:onExec(dt)
	for i= #self.attachdatas,1,-1 do
		self.attachdatas[i][2] = self.attachdatas[i][2] - dt
		if self.attachdatas[i][2] <= 0 then
			table.remove(self.attachdatas,i)
		end
	end
	self.super.onExec(self,dt)
end

function AttackSpell:addAttachdata(tab)
	table.insert(self.attachdatas,tab)
end

function AttackSpell:trgggerAffect(datastr,targets)
	self.super.trgggerAffect(self,datastr,targets)
	--触发附加效果
	for _k,_v in pairs(self.attachdatas) do
		if math.random(100) < _v[2] then
			if _v[3] ~= "" and _v[3] ~= nil then
				self.super.trgggerAffect(self,datastr,{ [1] = self.source })
			end
			if _v[4] ~= "" and _v[4] ~= nil then
				self.super.trgggerAffect(self,datastr,{ [1] = self.source })
			end
		end
	end
end
return AttackSpell
