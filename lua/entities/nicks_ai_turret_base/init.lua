AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:SpawnFunction( ply, tr, ClassName )
	if not tr.Hit then return end

    local ent = ents.Create( ClassName )
    ent:SetPos( tr.HitPos + tr.HitNormal )
    ent:Spawn()
    ent:Activate()
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
		print("LFS: missing model. Plane terminated.")
		return
	end
	
	phys:SetMass( self.mass )
	phys:Wake()

    self:RechargeShield()
	self.SearchInterval = 10
	self.nextS = CurTime()
	self.nextT = CurTime()
	self.MaxAmmo = self:GetAmmoPrimary()
	self.target = nil
	self.returning = false
	self.NextShoot = CurTime()
	self.reverseForward = true
	self.first = true
	self.TB = 100
	self.ai = self:GetAIEnabled()
	self:CreateDriver()
	self:OnSpawn()
end

function ENT:CreateDriver()
	if IsValid( self:GetDriverSeat() ) then return end
	
	local seat = ents.Create( "prop_vehicle_prisoner_pod" )
	if not IsValid( seat ) then
		self:Remove()
		
		print("LFS: Failed to create driverseat. Plane terminated.")
		
		return
	else
		self:SetDriverSeat( seat )
		local sphys = seat:GetPhysicsObject()
		
		seat:SetMoveType( MOVETYPE_NONE )
		seat:SetModel( "models/nova/airboat_seat.mdl" )
		seat:SetKeyValue( "vehiclescript","scripts/vehicles/prisoner_pod.txt" )
		seat:SetKeyValue( "limitview", 0 )
		seat:SetPos( self:LocalToWorld( self.SeatPos ) )
		seat:SetAngles( self:LocalToWorldAngles( self.SeatAng ) )
		seat:SetOwner( self )
		seat:Spawn()
		seat:Activate()
		seat:SetParent( self )
		seat:SetNotSolid( true )
		seat:SetColor( Color( 255, 255, 255, 0 ) ) 
		seat:SetRenderMode( RENDERMODE_TRANSALPHA )
		seat:DrawShadow( false )
		seat.DoNotDuplicate = true
		seat:SetNWInt( "pPodIndex", 1 )
		
		if IsValid( sphys ) then
			sphys:EnableDrag( false ) 
			sphys:EnableMotion( false )
			sphys:SetMass( 1 )
		end
		
		self:DeleteOnRemove( seat )
		
		self:dOwner( seat )
	end
end

function ENT:OnRemove()
end

function ENT:OnSpawn()
end

function ENT:Think()
	self:NextThink(CurTime())
	self:HandleActive()
	self:HandleWeapons()
	
	if not self.ai and self:GetAIEnabled() then
		self:ReturnViewToNormal()
		self.ai = true
	end
	
	if self.ai and not self:GetAIEnabled() then
		self.ai = false
	end
	
	if self:GetAIEnabled() and IsValid(self:GetDriver()) then
		self:SetAIEnabled(false)
	end
	
	if self:GetAIEnabled() and IsValid(self) and IsValid(self.target) then
		self:FireControl()
	end
	if self:GetAIEnabled() then
		self:HandleTargeting()
		if self.SENT:IsValid() and self.target == nil or !self.returning then
			self:SweepEnt(self.SENT)
		end
	end
	
	self:Tick()
	return true
end

function ENT:HandleWeapons(Fire1, Fire2)
	local Driver = self:GetDriver()
	
	if IsValid( Driver ) then
		if Driver:KeyDown( IN_ATTACK ) then
			self:PrimaryFire()
		end
		
		if Driver:KeyDown( IN_ATTACK2 ) then
			self:SecondaryFire()
		end
	end
end

function ENT:PrimaryFire()
end

function ENT:SecondaryFire()
end

function ENT:FireControl()
	if self.first then
		timer.Simple(1, function()
			if IsValid(self.target) and IsValid(self) then
				self:PrimaryFire()
				self:SecondaryFire()
			end
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
	if self.nextS > CurTime() then return end
    local reps = 100
	local newAng = math.random(-30,30)
    local delay = 3 / reps
    local ratio = 0
    local startAngle = ent:GetAngles()
    local endAngle = Angle(startAngle.x,(startAngle.y + newAng),startAngle.z)
	if not timer.Exists("SweepAllTheDay"..self:EntIndex()) then
		self.nextS = CurTime() + 5
		
		timer.Create("SweepAllTheDay"..self:EntIndex(),delay,reps, function()
            if not ent:IsValid() or self.target != nil or not self:GetAIEnabled() or self.returning then
				timer.Remove("SweepAllTheDay"..self:EntIndex())
				return
			end
			
            ratio = ratio + (5 / reps)
            ent:SetAngles(LerpAngle(ratio, startAngle, endAngle))
		end)
	end
end

function ENT:FindTarget()
    local angle = math.cos( math.rad( 60 ) )
    local dir = self.SENT:GetForward()
	if (self.reverseForward) then
        dir = -dir
    end
	local ent = {}
	if self:GetCone() then
		ent = ents.FindInCone(self:GetPos(),dir,self:GetRange(),angle)
	else
		ent = ents.FindInSphere(self:GetPos(),self:GetRange())
	end
	if #ent == 0 then return end
    for k, v in pairs(ent) do
		if IsValid(v) then
			if self:Visible(v) then
				if (v.Base == "lunasflightschool_basescript" or v.Base == "lunasflightschool_basescript_heli" or v.Base == "lunasflightschool_basescript_gunship" ) and self:GetAntiAir() and v:GetAITEAM() != self:GetAITEAM() then
					return v
				elseif v.Base == "fighter_base" and self:GetAntiAir() then
					return v
				elseif v.Base == "heracles421_lfs_base" and self:GetAntiGround() and v:GetAITEAM() != self:GetAITEAM() then
					return v
				elseif v.Base == "speeder_base" and self:GetAntiGround() then
					return v
				elseif v:IsPlayer() and self:GetAntiPersonel() then
					if v:lfsGetAITeam() != self:GetAITEAM() then
						return v
					end
				end
			end
		end
    end
	
    return nil
end

function ENT:HandleTargeting()
	if self.target == nil then
		if self.nextT > CurTime() then return end
        self.target = self:FindTarget()
		self.nextT = CurTime() + 0.1
	elseif not IsValid(self.target) then
		self.target = nil
		self:ReturnViewToNormal()
    elseif self:GetPos():DistToSqr(self.target:GetPos()) > (self:GetLoseTargetDistance()*self:GetLoseTargetDistance()) or not self.SENT:Visible( self.target ) then
		self.target = nil
		self:ReturnViewToNormal()
	elseif self.target:IsPlayer() then
		if not self.target:Alive() then
			self.target = nil
			self:ReturnViewToNormal()
		else
			self:Track(self.target)
		end
	else
		self:Track(self.target)
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
    local ang = ((enemyPos) - self.SENT:GetPos()):Angle()

    local reps = 10
    local delay = 1 / 1000
    local ratio = 0
    local startAngle = self.SENT:GetAngles()
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
	
	if not timer.Exists("TrackTarget"..self:EntIndex()) then
		timer.Create("TrackTarget"..self:EntIndex(),delay,reps, function()
			if (IsValid(self.SENT)) then
				if (!IsValid(target)) then 
					timer.Remove("TrackTarget"..self:EntIndex())
					return
				end
				ratio = ratio + (1 / reps)
				self.SENT:SetAngles(LerpAngle(ratio, startAngle, endAngle))
			end
		end)
	end
end

function ENT:Shoot()
end

function ENT:ReturnViewToNormal()
    self.returning = true
    local ang = ((self:GetPos() ) - self.SENT:GetPos()):Angle()
    local reps = 40
    local delay = 0.1 / reps
    local ratio = 0
    local startAngle = self.SENT:GetAngles()
    local endAngle = Angle(0,ang.y,self:GetAngles().z)
	if not timer.Exists("ReturnToStart"..self:EntIndex()) then
		timer.Create("ReturnToStart"..self:EntIndex(),delay,reps, function()
				if not IsValid(self) or self.target != nil or not IsValid(self.SENT) or not self:GetAIEnabled() then
					timer.Remove("ReturnToStart"..self:EntIndex())
					self.returning = false
					return
				end
				ratio = ratio + (1 / reps)
				self.SENT:SetAngles(LerpAngle(ratio, startAngle, endAngle))
				if timer.RepsLeft("ReturnToStart"..self:EntIndex()) == 0 then
					self.returning = false
				end
		end)
	end
end

function ENT:Use( ply )
	if not IsValid( ply ) then return end
	self:SetPassenger( ply )
end

function ENT:HandleActive()
	local Pod = self:GetDriverSeat()
	
	if not IsValid( Pod ) then
		self:SetActive( false )
		return
	end
	
	local Driver = Pod:GetDriver()
	local Active = self:GetActive()
	
	if Driver ~= self:GetDriver() then

		if self.HideDriver then
			if IsValid( self:GetDriver() ) then
				self:GetDriver():SetNoDraw( false )
			end
			if IsValid( Driver ) then
				Driver:SetNoDraw( true )
			end
		end
		
		self:SetDriver( Driver )
		self:SetActive( IsValid( Driver ) )
		
		if IsValid( Driver ) then
			Driver:lfsBuildControls()
		end
		
		if Active then
			self:EmitSound( "vehicles/atv_ammo_close.wav" )
		else
			self:EmitSound( "vehicles/atv_ammo_open.wav" )
		end
	end
end