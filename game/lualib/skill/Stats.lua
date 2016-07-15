local Stats = class("Stats")

function Stats:ctor()
	self.n32Strength = 0
	self.n32Strength_Pc = 0
	self.n32Strength_gPc = 0
	self.n32Agile = 0
	self.n32Agile_Pc = 0
	self.n32Aglie_gPc = 0
	self.n32Intelg = 0
	self.n32Intelg_Pc = 0
	self.n32Intelg_gPc = 0
	self.n32Hp = 0
	self.n32Hp_Pc = 0
	self.n32Hp_gPc = 0
	self.n32MaxHp = 0
	self.n32Mp = 0
	self.n32Mp_Pc = 0
	self.n32Mp_gPc = 0
	self.n32MaxMp = 0
	self.n32RecvHp = 0
	self.n32RecvHp_Pc = 0
	self.n32RecvHp_gPc = 0
	self.n32RecvMp  = 0
	self.n32RecvMp_Pc = 0
	self.n32RecvMp_gPc = 0
	self.n32AttackPhy = 0
	self.n32AttackPhy_Pc = 0
	self.n32AttackPhy_gPc = 0
	self.n32DefencePhy = 0
	self.n32DefencePhy_Pc = 0
	self.n32DefencePhy_gPc = 0
	self.n32AttackSpeed = 0
	self.n32AttackSpeed_Pc = 0
	self.n32AttackSpeed_gPc = 0
	self.n32MoveSpeed = 0
	self.n32MoveSpeed_Pc = 0
	self.n32MoveSpeed_gPc = 0
	self.n32AttackRange = 0
	self.n32AttackRange_Pc = 0
	self.n32AttackRange_gPc = 0
end

function Stats:dump()
	print("dump begin stats=======================================")
	for k, v in pairs(self) do
		if type(v) == "number" then
			print(k .. " = " .. v)
		end
	end
	print("dump end stats=======================================")
end

function Stats:clear()
	for k, v in pairs(self) do
		if type(v) == "number" then
			self[k] = 0
		end
	end
end

function Stats:init(buffData)
	self.n32Strength = buffData.n32Strength 
	self.n32Strength_Pc = buffData.n32Strength_Pc
	self.n32Agile = buffData.n32Agile 
	self.n32Agile_Pc = buffData.n32Agile_Pc
	self.n32Intelg = buffData.n32Intelg 
	self.n32Intelg_Pc = buffData.n32Intelg_Pc 
	self.n32Hp = buffData.n32Hp 
	self.n32Hp_Pc = buffData.n32Hp_Pc 
	self.n32Mp = buffData.n32Mp 
	self.n32Mp_Pc = buffData.n32Mp_Pc 
	self.n32RecvHp = buffData.n32RecvHp 
	self.n32RecvHp_Pc = buffData.n32RecvHp_Pc 
	self.n32RecvMp  = buffData.n32RecvMp  
	self.n32RecvMp_Pc = buffData.n32RecvMp_Pc 
	self.n32AttackPhy = buffData.n32AttackPhy 
	self.n32AttackPhy_Pc = buffData.n32AttackPhy_Pc 
	self.n32DefencePhy = buffData.n32DefencePhy 
	self.n32DefencePhy_Pc = buffData.n32DefencePhy_Pc 
	self.n32AttackSpeed = buffData.n32AttackSpeed 
	self.n32AttackSpeed_Pc = buffData.n32AttackSpeed_Pc 
	self.n32MoveSpeed = buffData.n32MoveSpeed 
	self.n32MoveSpeed_Pc = buffData.n32MoveSpeed_Pc 
	self.n32AttackRange_Pc = buffData.n32AttackRange_Pc 
end

function Stats:copy(_stats)
	for k, v in pairs(_stats) do
		if type(v) == "number" then
			self[k] = v
		end
	end
end
function Stats:add(_stats, cnt)
	if not cnt then cnt = 1 end
	for k, v in pairs(_stats) do
		if type(v) == "number" then
			self[k] = self[k] + v * cnt
		end
	end
end

function Stats:plusDone()
	self.n32Strength = math.floor(self.n32Strength * (1.0 + self.n32Strength_Pc / GAMEPLAY_PERCENT))
	self.n32Strength_Pc  = 0
	self.n32Agile = math.floor(self.n32Agile * (1.0 + self.n32Agile_Pc / GAMEPLAY_PERCENT))
	self.n32Agile_Pc = 0
	self.n32Intelg = math.floor(self.n32Intelg * (1.0 + self.n32Intelg_Pc / GAMEPLAY_PERCENT))
	self.n32Intelg_Pc = 0
	self.n32Hp = math.floor(self.n32Hp * (1.0 + self.n32Hp_Pc / GAMEPLAY_PERCENT))
	self.n32Hp_Pc = 0
	self.n32Mp = math.floor(self.n32Mp * (1.0 + self.n32Mp_Pc / GAMEPLAY_PERCENT))
	self.n32Mp_Pc = 0
	self.n32RecvHp = math.floor(self.n32RecvHp * (1.0 + self.n32RecvHp_Pc / GAMEPLAY_PERCENT))
	self.n32RecvHp_Pc = 0
	self.n32RecvMp  = math.floor(self.n32RecvMp  * (1.0 + self.n32RecvMp_Pc / GAMEPLAY_PERCENT))
	self.n32RecvMp_Pc = 0
	self.n32AttackPhy = math.floor(self.n32AttackPhy * (1.0 + self.n32AttackPhy_Pc / GAMEPLAY_PERCENT))
	self.n32AttackPhy_Pc = 0
	self.n32DefencePhy = math.floor(self.n32DefencePhy * (1.0 + self.n32DefencePhy_Pc / GAMEPLAY_PERCENT))
	self.n32DefencePhy_Pc = 0
	self.n32AttackSpeed = math.floor(self.n32AttackSpeed * (1.0 + self.n32AttackSpeed_Pc / GAMEPLAY_PERCENT))
	self.n32AttackSpeed_Pc = 0
	self.n32MoveSpeed = math.floor(self.n32MoveSpeed * (1.0 + self.n32MoveSpeed_Pc / GAMEPLAY_PERCENT))
	self.n32MoveSpeed_Pc = 0

	self.n32MaxHp = self.n32Hp
	self.n32MaxMp =self.n32Mp
end

function Stats:Calc(summa)
	self:clear()
	
	self.n32Strength = math.floor(summa.n32Strength * (1.0 + summa.n32Strength_Pc / GAMEPLAY_PERCENT))
	self.n32Strength_Pc = summa.n32Strength_Pc
	self.n32Agile = math.floor(summa.n32Agile * (1.0 + summa.n32Agile_Pc / GAMEPLAY_PERCENT))
	self.n32Agile_Pc = summa.n32Agile_Pc 
	self.n32Intelg = math.floor(summa.n32Intelg * (1.0 + summa.n32Intelg_Pc / GAMEPLAY_PERCENT))
	self.n32Intelg_Pc = summa.n32Intelg_Pc 
	self.n32Hp = math.floor(summa.n32Hp * (1.0 + summa.n32Hp_Pc / GAMEPLAY_PERCENT))
	self.n32Hp_Pc = summa.n32Hp_Pc 
	self.n32Mp = math.floor(summa.n32Mp * (1.0 + summa.n32Mp_Pc / GAMEPLAY_PERCENT))
	self.n32Mp_Pc = summa.n32Mp_Pc 
	self.n32RecvHp = math.floor(summa.n32RecvHp * (1.0 + summa.n32RecvHp_Pc / GAMEPLAY_PERCENT))
	self.n32RecvHp_Pc = summa.n32RecvHp_Pc 
	self.n32RecvMp = math.floor(summa.n32RecvMp * (1.0 + summa.n32RecvMp_Pc / GAMEPLAY_PERCENT))
	self.n32RecvMp_Pc = summa.n32RecvMp_Pc 
	self.n32AttackPhy = math.floor(summa.n32AttackPhy * (1.0 + summa.n32AttackPhy_Pc / GAMEPLAY_PERCENT))
	self.n32AttackPhy_Pc = summa.n32AttackPhy_Pc 
	self.n32DefencePhy = math.floor(summa.n32DefencePhy * (1.0 + summa.n32DefencePhy_Pc / GAMEPLAY_PERCENT))
	self.n32DefencePhy_Pc = summa.n32DefencePhy_Pc 
	self.n32AttackSpeed = math.floor(summa.n32AttackSpeed * (1.0 + summa.n32AttackSpeed_Pc / GAMEPLAY_PERCENT))
	self.n32AttackSpeed_Pc = summa.n32AttackSpeed_Pc 
	self.n32MoveSpeed = math.floor(summa.n32MoveSpeed * (1.0 + summa.n32MoveSpeed_Pc / GAMEPLAY_PERCENT))
	self.n32MoveSpeed_Pc = summa.n32MoveSpeed_Pc 
	self.n32AttackRange_Pc = summa.n32AttackRange_Pc 
end

return Stats
