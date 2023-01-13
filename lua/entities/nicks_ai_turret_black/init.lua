AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )
    local ent = ents.Create( ClassName )
    ent:SetPos( tr.HitPos + tr.HitNormal * 5 )
    ent:Spawn()
    ent:Activate()
    return ent
end

function ENT:OnSpawn()
	self.SENT = ents.Create("prop_physics")
	self.SENT:SetModel("models/random_turrets/turret.mdl")
	self.SENT:SetPos(self:GetPos()+self:GetUp()*36)
	self.SENT:SetAngles(self:GetAngles())
	self.SENT:Spawn()
	self.SENT:Activate()
	self.SENT:SetParent(self)
	self.barrelPos = self.SENT:GetForward() * 22 + self.SENT:GetUp() * 8
	self.reverseForward = false
	self.TB = 4.4
end

function ENT:Tick()
	if IsValid(self:GetDriver()) and IsValid(self) then
		local an = self:GetDriver():EyeAngles()
		self.SENT:SetAngles(Angle(an.x, an.y, an.z))
	end
end

function ENT:PrimaryFire()
	if self.NextShoot > CurTime() then return end
	if not IsValid(self.SENT) then return end
	if self:GetAmmoPrimary() == 0 then
		self:SetAmmoPrimary(self.MaxAmmo)
		self:EmitSound(Sound("ambient/levels/caves/ol04_gearengage.wav"), 120, math.random(90,110))
		self.NextShoot = CurTime() + 2
		return
	end

	local fP = {
		self.SENT:GetForward()*44+self.SENT:GetUp()*60+self.SENT:GetRight()*15,
		self.SENT:GetForward()*44+self.SENT:GetUp()*60+self.SENT:GetRight()*-15,
	}

	self.NumPrim = self.NumPrim and self.NumPrim + 1 or 1
	if self.NumPrim > 2 then self.NumPrim = 1 end
	
	local dir = self.SENT:GetForward():GetNormalized()
    if self.reverseForward then
        dir = -self.SENT:GetForward():GetNormalized()
    end
	self:EmitSound( "random_turrets/shoot.wav" )
	self.NextShoot = CurTime() + 0.2
	
	self:SetAmmoPrimary(self:GetAmmoPrimary() - 1)
	
	local bullet = {}
	bullet.Num 	= 1
	bullet.Src 	= self:LocalToWorld(fP[self.NumPrim])
	bullet.Dir 	= dir
	bullet.Spread 	= Vector( 0.01,  0.01, 0.01 )
	bullet.Tracer	= 1
	bullet.TracerName	= "lfs_laser_green"
	bullet.Force	= 100
	bullet.HullSize 	= 50
	bullet.Damage	= 20
	bullet.Attacker 	= self:GetDriver()
	bullet.AmmoType = "Pistol"
	bullet.IgnoreEntity = self
	bullet.IgnoreEntity = self.SENT
	bullet.Callback = function(att, tr, dmginfo)
		dmginfo:SetDamageType(DMG_AIRBOAT)
	end
	self:FireBullets( bullet )
end