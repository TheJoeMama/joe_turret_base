ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Joes LFS Turret Base"
ENT.Category = "Joe | Turrets"

DEFINE_BASECLASS( "lunasflightschool_basescript" )

ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Editable = true

ENT.model = "models/sam_model/base.mdl"

ENT.HideDriver = true
ENT.SeatPos = Vector(00,0,0)
ENT.SeatAng = Angle(0,-90,0)

ENT.MaxHealth = 5000
ENT.MaxShield = 0 --set 0 for no shield
ENT.Range = 60000 --range at which it will see the target
ENT.LoseTargetDistance = ENT.Range + 1000 --range at which it will lose the target
ENT.Clip = 8 --ammount of ammo before reload, set to -1 for inf
ENT.mass = 500
ENT.team = 1 --0 friendly to all, 1 good guys, 2 bad guys, 3 hostile to all

ENT.targetgroundvehicles = true
ENT.targetairvehicles = true
ENT.targethumans = true

ENT.BarrelPos = {
	[1] = Vector(-22,30,4),
	[2] = Vector(-22,21,4),
	[3] = Vector(-22,30,-4),
	[4] = Vector(-22,21,-4),
	[5] = Vector(-22,-21,4),
	[6] = Vector(-22,-30,4),
	[7] = Vector(-22,-21,-4),
	[8] = Vector(-22,-30,-4),
}

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
	self:NetworkVar("Int",1, "ShootInterval", { KeyName = "shootint", Edit = { type = "Int", order = 1,min = 1, max = 10, category = "Shooting"} } )
	self:NetworkVar("Int",2, "ReloadTime", { KeyName = "reloadtime", Edit = { type = "Int", order = 1,min = 1, max = 20, category = "Shooting"} } )
	self:NetworkVar("Float",0, "HP", { KeyName = "Health", Edit = { type = "Float", order = 0,min = 0, max = self.MaxHealth} } )
	self:NetworkVar("Float",3, "Range", { KeyName = "range", Edit = { type = "Float", order = 5,min = 100, max = 100000} } )
	self:NetworkVar("Float",4, "LoseTargetDistance", { KeyName = "loseTargetDistance" } )
	self:NetworkVar("Bool",11, "TargetAir", { KeyName = "Target Air", Edit = { type = "Boolean", order = 1, category = "Type"} } )
	self:NetworkVar("Bool",12, "TargetGround", { KeyName = "Target Vehicles", Edit = { type = "Boolean", order = 1, category = "Type"} } )
	self:NetworkVar("Bool",13, "TargetHumans", { KeyName = "Target humans", Edit = { type = "Boolean", order = 1, category = "Type"} } )

	self:NetworkVar("Bool",1, "AIEnabled", { KeyName = "AIenabled", Edit = { type = "Boolean", order = 1} } )

	if self.team == 0 then
		self:SetAITEAM(3)
	else
		self:SetAITEAM(self.team)
	end
	self:SetShootInterval(2)
	self:SetReloadTime(10)
	self:SetHP(self.MaxHealth)
	self:SetShield(self.MaxShield)
	self:SetRange(self.Range)
	self:SetLoseTargetDistance(self.LoseTargetDistance)
	self:SetAmmoPrimary(self.Clip)
	self:SetAIEnabled(false)
	self:SetTargetAir(self.targetairvehicles)
	self:SetTargetGround(self.targetgroundvehicles)
	self:SetTargetHumans(self.targethumans)

	if SERVER then
		self:NetworkVarNotify( "Range", self.SetRangeStuff )
	end
end

function ENT:SetRangeStuff(name, old, new)
	self:SetLoseTargetDistance(new + 1000)
end