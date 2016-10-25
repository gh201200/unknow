local sheduleSpell = class("sheduleSpell")
function sheduleSpell:ctor(src,tgt,skilldata,time)
	self.lifetime = time
	self.source = src
	self.target = tgt
	self.spell = self.source.spell
	self.skilldata = skilldata
	self.isDead = false
end

function sheduleSpell:update(dt)
	self.lifetime = self.lifetime - dt
	if self.lifetime < 0 and self.isDead == false then
		--触发效果
		self.spell:synSpell(self.source,self.target,self.skilldata,SpellStatus.Cast,0)
		self.spell:onTriggerSkillAffect(self.skilldata,self.source,self.target)
		self.isDead = true	
	end	
end
return sheduleSpell
