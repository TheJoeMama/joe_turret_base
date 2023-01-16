AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )
    local ent = ents.Create( ClassName )
    ent:SetPos( tr.HitPos + tr.HitNormal * 13.5 )
	local ang = (tr.HitPos - ply:EyePos()):Angle()
	ang.p = 0
	ang.r = 0
	ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
	ent:GetPhysicsObject():EnableMotion(false)
    return ent
end

function ENT:Initialize()
	self:SetModel(self.model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetRenderMode( RENDERMODE_TRANSALPHA )
	self:AddFlags( FL_OBJECT )
	
	local phys = self:GetPhysicsObject()

	if not IsValid( phys ) then 
		self:Remove()
		return
	end
	
	phys:SetMass( self.mass )
	phys:Wake()

    self:RechargeShield()
	self.nextS = CurTime()
	self.nextT = CurTime()
	self.nextDistCheck = 0
	self.HasTarget = false
	self.MaxAmmo = self:GetAmmoPrimary()
	self.target = nil
	self.returning = false
	self.issweeping = false
	self.NextShoot = CurTime()
	self.reverseForward = true
	self.first = true
	self.barrelshotcounter = 0
	self.TB = 100
	self.ai = self:GetAIEnabled()
	self:CreateDriver()
	self:OnSpawn()
	self:CustomOnInitialize()
end

function ENT:CustomOnInitialize()
end

function ENT:CreateDriver()
	return
end

function ENT:PrimaryFire()
	if self.NextShoot > CurTime() then return end
	if not IsValid(self.SENT) then return end
	if self:GetAmmoPrimary() == 0 then
		self:SetAmmoPrimary(self.MaxAmmo)
		self.barrelshotcounter = 0
		self:EmitSound(Sound("ambient/levels/caves/ol04_gearengage.wav"), 120, math.random(90,110))
		self.NextShoot = CurTime() + 5
		return
	end
	
	local dir = self.BARRELS:GetForward():GetNormalized()
    if self.reverseForward then
        dir = -self.BARRELS:GetForward():GetNormalized()
    end
	self:EmitSound( "random_turrets/shoot.wav" )
	self.NextShoot = CurTime() + 1
	
	self:SetAmmoPrimary(self:GetAmmoPrimary() - 1)
	self.barrelshotcounter = self.barrelshotcounter + 1
	if self.barrelshotcounter > #self.BarrelPos then
		self.barrelshotcounter = 1
	end

	local ent = ents.Create( "lunasflightschool_missile" )
	ent:SetPos( self.BARRELS:LocalToWorld(self:GetBarrelShootPos()) )
	ent:SetAngles( dir:Angle() )
	ent:SetOwner( self )
	ent.Attacker = self
	ent:Spawn()
	ent:Activate()
	
	ent:SetAttacker( self )
	ent:SetInflictor( self )
	
	if IsValid( self.target ) then
		ent:SetLockOn( self.target )
	end
end

function ENT:GetBarrelShootPos()
	if self.BarrelPos[self.barrelshotcounter] then
		return self.BarrelPos[self.barrelshotcounter]
	end
end

function ENT:OnRemove()
end

function ENT:OnSpawn()
	self.SENT = ents.Create("prop_physics")
	self.SENT:SetModel("models/sam_model/rotator.mdl")
	self.SENT:SetPos(self:LocalToWorld(Vector(0,0,53)))
	self.SENT:SetAngles(self:GetAngles())
	self.SENT:Spawn()
	self.SENT:Activate()
	self.SENT:SetParent(self)
	self.reverseForward = true
	self.TB = 4.4

	self.BARRELS = ents.Create("prop_physics")
	self.BARRELS:SetModel("models/sam_model/missilepods.mdl")
	self.BARRELS:SetPos(self:LocalToWorld(Vector(0,0,53)))
	self.BARRELS:SetAngles(self:GetAngles())
	self.BARRELS:Spawn()
	self.BARRELS:Activate()
	self.BARRELS:SetParent(self)
	self.BARRELS:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

end

function ENT:Think()
	self:NextThink(CurTime())
	local aistate = self:GetAIEnabled()

	if not self.ai and aistate then
		self.ai = true
		self.nextT = 0
	end
	
	if self.ai and not aistate then
		self.ai = false
		self.target = nil
		self.HasTarget = false
		local ang = self:GetAngles()
		self.SENT:SetAngles(ang)
		self.BARRELS:SetAngles(ang)
	end
	
	if aistate and IsValid(self) and IsValid(self.target) then
		self:FireControl()
	end

	if aistate then
		if self.returning then
			self:ReturnViewToNormal()
		end
		self:HandleTargeting()
		if self.SENT:IsValid() and not IsValid(self.target) and not self.returning then
			if self.nextS < CurTime() and self.issweeping == false then
				self.issweeping = true
				self.newAng = nil
				self.sweependAngle = nil
			end

			if self.issweeping == true then
				self:SweepEnt(self.SENT)
			end
		end
	end
	
	self:Tick()
	return true
end

function ENT:HandleWeapons(Fire1, Fire2)
	return
end

function ENT:SecondaryFire()
end

function ENT:FireControl()
	if self.first then
		timer.Simple(1, function()
			if not IsValid(self.target) or not IsValid(self) then return end
			if self.target:IsPlayer() and not self.target:Alive() then return end
				self:PrimaryFire()
				self:SecondaryFire()
		end)
	else
		self.first = false
		self:PrimaryFire()
		self:SecondaryFire()
	end
end

function ENT:Tick()
end

function ENT:RechargeShield()
    if self:GetMaxShield() <= 0 then return end
    if not self:CanRechargeShield() then return end
    local rate = FrameTime() * 30
    
    self:SetShield( self:GetShield() + math.Clamp(self:GetMaxShield() - self:GetShield(),-rate,rate) )
end

function ENT:CanRechargeShield()
    self.NextShield = self.NextShield or 0
    return self.NextShield < CurTime()
end

function ENT:SetNextShield( nDelay )
    if not isnumber( nDelay ) then return end
    
    self.NextShield = CurTime() + nDelay
end

function ENT:TakeShieldDamage( damage )
    local new = math.Clamp( self:GetShield() - damage , 0, self:GetMaxShield()  )
    
    self:SetShield( new )
end

function ENT:OnTakeDamage(dmginfo)
    local dmg = dmginfo:GetDamage()
    local newhp = math.Clamp( self:GetHP() - dmg , 0, self:GetMaxHP()  )
    local ShieldCanBlock = dmginfo:IsBulletDamage() or dmginfo:IsDamageType( DMG_AIRBOAT )

    if ShieldCanBlock then
        self:SetNextShield( 3 )
        
        if self:GetMaxShield() > 0 and self:GetShield() > 0 then
            self:TakeShieldDamage( dmg )
			
            local effectdata = EffectData()
            effectdata:SetOrigin( dmginfo:GetDamagePosition()  )
            util.Effect( "lfs_shield_deflect", effectdata )
        else
			local effectdata = EffectData()
				effectdata:SetOrigin( dmginfo:GetDamagePosition() )
				effectdata:SetNormal( -dmginfo:GetDamageForce():GetNormalized()  )
			util.Effect( "MetalSpark", effectdata )
			
            self:SetHP( newhp )
        end
    else
        self:TakePhysicsDamage( dmginfo )
        self:SetHP( newhp )
    end
	
	if newhp == 0 then
		self:Die()
	end
end

function ENT:PhysicsCollide( data, physobj )
    if IsValid( data.HitEntity ) then
        if data.HitEntity:IsPlayer() or data.HitEntity:IsNPC() then
            return
        end
    end
    if data.Speed > 60 and data.DeltaTime > 0.2 then
        if data.Speed > 500 then
            self:EmitSound( "Airboat_impact_hard" )
            
            self:TakeDamage( data.Speed / 2, data.HitEntity, data.HitEntity )
        elseif (data.Speed >= 200) then
            self:EmitSound( "MetalVehicle.ImpactSoft" )
        end
    end
end


function ENT:Die()
    local effectdata = EffectData()
    effectdata:SetScale(math.random(2,4))
    effectdata:SetMagnitude(math.random(30,60))
    effectdata:SetRadius(math.random(4,6))
    effectdata:SetOrigin(self:GetPos())
    util.Effect( "Explosion", effectdata )
    self:Remove()
end

function ENT:SweepEnt(ent)
	self.issweeping = true
	if not ent:IsValid() or IsValid(self.target) or not self:GetAIEnabled() or self.returning then
		self.issweeping = false
		return
	end
    local reps = 500
	self.newAng = self.newAng or 180
    local startAngle = ent:GetAngles()
    self.sweependAngle = self.sweependAngle or Angle(startAngle.x,(startAngle.y + self.newAng),startAngle.z)

	local ratio =  (5 / reps)
	local lerp = LerpAngle(ratio, startAngle, self.sweependAngle)
	ent:SetAngles(lerp)
	self.BARRELS:SetAngles(lerp)

	if math.abs(math.AngleDifference(lerp.y, self.sweependAngle.y)) < 0.5 then
		self.issweeping = false
		self.nextS = CurTime() + 5
	end
end

function ENT:GetClosestTarget()
	local tbl = {}
	local returnvalue = nil
	
	if table.Count(Joe_Turret_Base.Targets) > 0 then
		local turretpos = self:GetPos()
		local range = self:GetRange() ^ 2
		local selfteam = self:GetAITEAM()

		local airbases = {
			["lunasflightschool_basescript"] = true,
			["lunasflightschool_basescript_heli"] = true,
			["lunasflightschool_basescript_gunship"] = true,
			["fighter_base"] = true
		}

		local targetair = self:GetTargetAir()
		local targetground = self:GetTargetGround()
		local targethuman = self:GetTargetHumans()
		for ent,_ in pairs(Joe_Turret_Base.Targets) do
			if not IsValid(ent) then continue end
			if ent.GetAITEAM != nil and (ent:GetAITEAM() == selfteam) then continue end
			if ent:IsPlayer() and ( ( ent:lfsGetAITeam() == selfteam ) or (not targethuman) or (not ent:Alive()) ) then continue end
			if ent.GetHP and ( ent:GetHP() <= 0 ) then continue end
			if not self:IsEntStillVisible(ent) then continue end

			if airbases[ent.Base] and not targetair then continue end
			if ent.Base == "heracles421_lfs_base" and not targetground then continue end
			if ent.Base == "speeder_base" and targetground then continue end

			local dist = ent:GetPos():DistToSqr(turretpos)
			if dist > range then continue end
			tbl[#tbl + 1] = {ent,dist}
		end

		if table.Count(tbl) > 1 then
			table.sort(tbl, function(a,b) return a[2] < b[2] end)
		end

		for i = 1, table.Count(tbl) do
			if tbl[i] and IsValid(tbl[i][1]) then
				returnvalue = tbl[i][1]
				break
			end
		end
	end

	return returnvalue
end


function ENT:FindTarget()
	local newtarget = self:GetClosestTarget()
		if IsValid(newtarget) then
			self.HasTarget = true
			self.nextDistCheck = CurTime() + 5
		end
    return newtarget
end

function ENT:IsEntStillVisible(ent)
	local tr = util.TraceLine( {
		start = self.BARRELS:GetPos(),
		endpos = ent:LocalToWorld(ent:OBBCenter()),
		filter = {self,self.BARRELS,self.SENT},
	} )
	return (tr.Hit and tr.Entity == ent)
end

function ENT:HandleTargeting()
	local cur = CurTime()
	local intervalchecks = false
	if self.nextT < cur then
		intervalchecks = true
		self.nextT = cur + 0.25
	end
	local nofurtheraction = false
	if self.HasTarget then
		if not IsValid(self.target) then
			self.target = nil
			self.HasTarget = false
			self:ReturnViewToNormal()
		else
			if intervalchecks then
				if nofurtheraction == false and ( ( self:GetPos():DistToSqr(self.target:GetPos()) > (self:GetLoseTargetDistance() ^ 2) ) or not self:IsEntStillVisible(self.target) ) then
					self.target = nil
					self.HasTarget = false
					self:ReturnViewToNormal()
					nofurtheraction = true
				end

				if nofurtheraction == false and (self.target:IsPlayer() and not self.target:Alive() )then
					self.target = nil
					self.HasTarget = false
					self:ReturnViewToNormal()
					nofurtheraction = true
				end

				if nofurtheraction == false and ( self.target.GetHP and ( self.target:GetHP() <= 0 ) ) then
					self.target = nil
					self.HasTarget = false
					self:ReturnViewToNormal()
					nofurtheraction = true
				end

				if nofurtheraction == false and ( self.nextDistCheck < cur) then
					self.nextDistCheck = cur + 5
					self.target = self:FindTarget()
				end
			end


			if nofurtheraction == false then
				self:Track(self.target)
			end
		end
	else
		if intervalchecks then
			self.target = self:FindTarget()
		end
	end
end

function ENT:Track(target)
    if not IsValid(target) or not IsValid(self) then
		self.first = true
		return
	end

    local enemyPos = target:GetPos()
    local min,max = target:GetModelBounds()
    enemyPos = target:GetPos() + Vector(0,0,max.z/self.TB)
    local ang = ((enemyPos) - self.BARRELS:GetPos()):Angle()

    local reps = 10
    local startAngle = self.BARRELS:GetAngles()
    if self.reverseForward then
        ang.y = ang.y + 180
        ang.x = -ang.x
    end
    local endAngle = Angle(ang.x,ang.y,0)
    if (self.rightIsFront != nil and self.rightIsFront) then
        ang.y = ang.y + 90
        local tempZ = ang.z
        ang.z = -math.abs(ang.x - 360)
        ang.x = tempZ
        endAngle = Angle(ang.x,ang.y,ang.z)
    end
	
	local ratio = (1 / reps)
	local lerp = LerpAngle(ratio, startAngle, endAngle)
	self.SENT:SetAngles(Angle(0,lerp.y,lerp.r))
	self.BARRELS:SetAngles(lerp)
end

function ENT:Shoot()
end

function ENT:ReturnViewToNormal()
    self.returning = true

	if IsValid(self.target) or not IsValid(self.SENT) or not self:GetAIEnabled() then
		self.returning = false
		return
	end

    local ang = ((self:GetPos() ) - self.SENT:GetPos()):Angle()
    local reps = 40
    local startAngle = self.BARRELS:GetAngles()
    local endAngle = Angle(0,ang.y,0)

	local ratio = (1 / reps)
	local lerp = LerpAngle(ratio, startAngle, endAngle)
	self.SENT:SetAngles(Angle(0,lerp.y,lerp.r))
	self.BARRELS:SetAngles(lerp)

	if math.AngleDifference(lerp.y, ang.y) < 1 and math.AngleDifference(lerp.p, ang.p) < 0.25 and math.AngleDifference(lerp.r, ang.r) < 0.25 then
		self.returning = false
		self.SENT:SetAngles(endAngle)
		self.BARRELS:SetAngles(endAngle)
		self.nextS = CurTime() + 5
	end
end

function ENT:Use( ply )
	return
end

function ENT:HandleActive()
	return
end