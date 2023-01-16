include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end
/*
function ENT:Initialize()
end

function ENT:LFSCalcViewFirstPerson( view, ply )
	local v = {}
	return v
end

function ENT:LFSCalcViewThirdPerson( view, ply )
	local v = {}
	return v
end

function ENT:LFSHudPaintInfoText( X, Y, speed, alt, AmmoPrimary, AmmoSecondary, Throttle )
end

function ENT:LFSHudPaintInfoLine( HitPlane, HitPilot, LFS_TIME_NOTIFY, Dir, Len, FREELOOK )
end

function ENT:LFSHudPaintCrosshair( HitPlane, HitPilot )
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
end

function ENT:OnRemove()
	self:SoundStop()
end

function ENT:SoundStop()
end
*/