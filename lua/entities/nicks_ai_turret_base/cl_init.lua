include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
end

function ENT:Initialize()
end

function ENT:LFSCalcViewFirstPerson( view, ply )
	local v = {}
	local e = ply:EyeAngles()
	v.angle = Angle(e.x, e.y-90, e.z)
	return v
end

function ENT:LFSCalcViewThirdPerson( view, ply )
	local v = {}
	v.origin = self:GetPos() + self:GetUp() * 80
	
	local radius = 800
	radius = radius + radius * ply:GetVehicle():GetCameraDistance()
	
	local e = ply:EyeAngles()
	v.angle = Angle(e.x, e.y-90, e.z)
	
	local TargetOrigin = v.origin-v.angle:Forward()*radius
	
	local WallOffset = 4
	
	local tr = util.TraceLine( {
		start = v.origin,
		endpos = TargetOrigin,
		filter = function( e )
			local c = e:GetClass()
			local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "player" ) and not e.LFS
					
			return collide
		end,
		mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
		maxs = Vector( WallOffset, WallOffset, WallOffset ),
	} )
	
	v.drawviewer = true
	v.origin = tr.HitPos
	if tr.Hit and not tr.StartSolid then
		v.origin = v.origin + tr.HitNormal * WallOffset
	end
	
	return v
end

function ENT:LFSHudPaintInfoText( X, Y, speed, alt, AmmoPrimary, AmmoSecondary, Throttle )
	draw.SimpleText( "CLIP", "LFS_FONT", 10, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( AmmoPrimary, "LFS_FONT", 120, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
end

function ENT:LFSHudPaintInfoLine( HitPlane, HitPilot, LFS_TIME_NOTIFY, Dir, Len, FREELOOK )
end

function ENT:LFSHudPaintCrosshair( HitPlane, HitPilot )
	local center = Vector( ScrW() / 2, ScrH() / 2, 0 )
	surface.SetDrawColor( 255, 255, 255, 255 )
	simfphys.LFS.DrawCircle( center.x, center.y, 10 )
	surface.DrawLine( center.x + 10, center.y, center.x + 20, center.y ) 
	surface.DrawLine( center.x - 10, center.y, center.x - 20, center.y ) 
	surface.DrawLine( center.x, center.y + 10, center.x, center.y + 20 ) 
	surface.DrawLine( center.x, center.y - 10, center.x, center.y - 20 )
	
	-- shadow
	surface.SetDrawColor( 0, 0, 0, 80 )
	simfphys.LFS.DrawCircle( center.x + 1, center.y + 1, 10 )
	surface.DrawLine( center.x + 11, center.y + 1, center.x + 21, center.y + 1 ) 
	surface.DrawLine( center.x - 9, center.y + 1, center.x - 16, center.y + 1 ) 
	surface.DrawLine( center.x + 1, center.y + 11, center.x + 1, center.y + 21 ) 
	surface.DrawLine( center.x + 1, center.y - 19, center.x + 1, center.y - 16 ) 
end

function ENT:LFSHudPaint( X, Y, data, ply )
end

function ENT:LFSHudPaintPassenger( X, Y, ply )
end

function ENT:Think()
	self:DamageFX()
end

function ENT:DamageFX()
	local HP = self:GetHP()
	if HP <= 0 or HP > self:GetMaxHP() * 0.5 then return end
	
	self.nextDFX = self.nextDFX or 0
	
	if self.nextDFX < CurTime() then
		self.nextDFX = CurTime() + 0.05
		
		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetRotorPos() - self:GetForward() * 50 )
		util.Effect( "lfs_blacksmoke", effectdata )
	end
end

function ENT:OnRemove()
	self:SoundStop()
end

function ENT:SoundStop()
end