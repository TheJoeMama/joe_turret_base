ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Nicks lfs turret base"
ENT.Category = "[LFS] Nick's AI turrets"

DEFINE_BASECLASS( "lunasflightschool_basescript" )

ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Editable = true

ENT.PrintName = "base"

ENT.model = "error.mdl"

ENT.HideDriver = false
ENT.SeatPos = Vector(00,0,0)
ENT.SeatAng = Angle(0,-90,0)

ENT.MaxHealth = 500
ENT.MaxShield = 0 --set 0 for no shield
ENT.Range = 5000 --range at which it will see the target
ENT.LoseTargetDistance = ENT.Range + 1000 --range at which it will lose the target
ENT.Clip = 50 --ammount of ammo before reload, set to -1 for inf
ENT.AA = true --is it anti-air
ENT.AG = true --is it anti-ground
ENT.AP =true --is it anti-personel
ENT.mass = 500
ENT.team = 2 --0 friendly to all, 1 good guys, 2 bad guys, 3 hostile to all
ENT.cone = true --should the turret search in a cone(true) or sphere(false)

function ENT:SetupDataTables()

	self:NetworkVar( "Entity",0, "Driver" )
	self:NetworkVar( "Entity",1, "DriverSeat" )
	self:NetworkVar( "Entity",2, "Gunner" )
	self:NetworkVar( "Entity",3, "GunnerSeat" )

	self:NetworkVar("Float",27, "Shield" )

	self:NetworkVar("Int",16, "AmmoPrimary" )
	self:NetworkVar("Int",17, "AmmoSecondary" )

	self:NetworkVar( "Float",2, "RPM" )
	self:NetworkVar( "Bool",3, "RotorDestroyed" )
	self:NetworkVar( "Bool",4, "EngineActive" )
	self:NetworkVar( "Bool",7, "lfsLockedStatus" )
	self:NetworkVar( "Bool",5, "Active" )
	self:NetworkVar( "Bool",6, "AI")
	self:NetworkVar( "Float",8, "MaintenanceProgress" )

	self:NetworkVar("Int",0, "AITEAM", { KeyName = "aiteam", Edit = { type = "Int", order = 1,min = 1, max = 3, category = "AI"} } )
	self:NetworkVar("Float",0, "HP", { KeyName = "Health", Edit = { type = "Float", order = 0,min = 0, max = self.MaxHealth} } )
	self:NetworkVar("Float",3, "Range", { KeyName = "range", Edit = { type = "Float", order = 5,min = 1, max = 50000} } )
	self:NetworkVar("Float",4, "LoseTargetDistance", { KeyName = "loseTargetDistance" } )
	self:NetworkVar("Bool",11, "AntiAir", { KeyName = "antia-air", Edit = { type = "Boolean", order = 1, category = "Type"} } )
	self:NetworkVar("Bool",12, "AntiGround", { KeyName = "anti-ground", Edit = { type = "Boolean", order = 1, category = "Type"} } )
	self:NetworkVar("Bool",13, "AntiPersonel", { KeyName = "anti-personnel", Edit = { type = "Boolean", order = 1, category = "Type"} } )

	self:NetworkVar("Bool",1, "AIEnabled", { KeyName = "AIenabled", Edit = { type = "Boolean", order = 1} } )
	self:NetworkVar("Bool",15, "Cone", { KeyName = "cone(true)/sphere(false)", Edit = { type = "Boolean", order = 1} } )

	if self.team == 0 then
		self:SetAITEAM(3)
	else
		self:SetAITEAM(self.team)
	end
	self:SetHP(self.MaxHealth)
	self:SetShield(self.MaxShield)
	self:SetRange(self.Range)
	self:SetLoseTargetDistance(self.LoseTargetDistance)
	self:SetAmmoPrimary(self.Clip)
	self:SetAIEnabled(false)
	self:SetCone(self.cone)
	self:SetAntiAir(self.AA)
	self:SetAntiGround(self.AG)
	self:SetAntiPersonel(self.AP)

	if SERVER then
		self:NetworkVarNotify( "Range", self.SetRangeStuff )
	end
end

function ENT:SetRangeStuff(name, old, new)
	self:SetLoseTargetDistance(new + 1000)
end