ENT.Type = "anim"
ENT.Base = "joes_turret_base"

ENT.PrintName = "SAM Turret"
ENT.Category = "Joe | Turrets"

ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Editable = true

ENT.model = "models/sam_model/base.mdl"

ENT.HideDriver = true
ENT.SeatPos = Vector(0,0,50)
ENT.SeatAng = Angle(0,-90,0)

ENT.MaxHealth = 500
ENT.MaxShield = 100 --set 0 for no shield
ENT.Range = 60000
ENT.LoseTargetDistance = ENT.Range + 1000
ENT.Clip = 8

ENT.targetgroundvehicles = true
ENT.targetairvehicles = true
ENT.targethumans = true

ENT.team = 1