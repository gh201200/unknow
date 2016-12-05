local Affect = class "Affect"
local uuid = require "uuid"
function Affect:ctor(entity,source,data,skillId)
	self.status = "enter"
        skillId = skillId or 0
	self.owner =  entity  	--效果接受者
        self.source =  source	--效果来源
	self.data = table.copy(data)
	self.affectState = 0
	self.projectId = uuid.gen()
	self.skillId = skillId
end

function Affect:onEnter()
	--print("Affect:onEnter")
	self.status = "exec"
end

function Affect:onExec()
	
end

function Affect:onExit()
	--print("Affect:onExit")
	self.status = "exit"	
end

function Affect:getAttributeValue(data)
	attId,rate,value = data[2],data[3],data[4]
	local entity = self.source
	local r = 0
	local attIdToFuns = {
		[0] = "getAttack",[1] = "getStrength",[2] = "getAgility",
		[3] = "getIntelligence",[4] = "getDefence",[5] = "getHpMax",
		[6] = "getMpMax",[7] = "getHp",[8] = "getMp"};
	if attId <= 8 then
		r = entity[attIdToFuns[attId]](entity) * rate + value
	elseif attId == 9 then
		r = (entity:getHpMax() - entity:getHp()) * rate + value	
	elseif attId == 10 then
		r = (entity:getMpMax() - entity:getMp()) * rate + value	
	else
		assert(0,"error attId:" .. attId)
	end
end

function Affect:getBaseAttributeValue(data)
	attId,rate,value = data[2],data[3],data[4]
	local entity = self.source
	local attIdToFuns = {
		[1] = "Attack",[2] = "Strength",[3] = "Agility",
		[4] = "Intelligence",[5] = "Defence",[6] = "HpMax",
		[7] = "MpMax",[8] = "Hp",[9] = "Mp"};
	local midValue = entity["getMid" .. attIdToFuns[attId]](entity)
	local midPecent =  entity["getMid" .. attIdToFuns[attId] .. "Pc"](entity)
	local finalValue = self:getAttributeValue(attId,rate,value)	
	local originValue = (finalValue - midValue) * (1.0 / (1 + midPecent))
	return math.floor(originValue)
end

return Affect
