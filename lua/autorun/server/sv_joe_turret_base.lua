Joe_Turret_Base = Joe_Turret_Base or {}
Joe_Turret_Base.Targets = Joe_Turret_Base.Targets or {}
Joe_Turret_Base.TargetClasses = Joe_Turret_Base.TargetClasses or {}
Joe_Turret_Base.TargetBases = Joe_Turret_Base.TargetBases or {}

local function AddTargetBase(name)
    Joe_Turret_Base.TargetBases[name] = true
end
// LFS
AddTargetBase("lunasflightschool_basescript")
AddTargetBase("lunasflightschool_basescript_heli")
AddTargetBase("lunasflightschool_basescript_gunship")
AddTargetBase("fighter_base")
AddTargetBase("heracles421_lfs_base")
AddTargetBase("speeder_base")

// LVS
AddTargetBase("lvs_base_fakehover")
AddTargetBase("lvs_walker_atte_hoverscript")
AddTargetBase("lvs_base_starfighter")
AddTargetBase("lvs_base_repulsorlift")
AddTargetBase("lvs_base")
AddTargetBase("lvs_base_fighterplane")

local function AddTargetClass(name)
    Joe_Turret_Base.TargetClasses[name] = true
end

local function AddEntToTargets(ent)
    if not IsValid(ent) then return end
    Joe_Turret_Base.Targets[ent] = true
end

local function RemoveEntFromTargets(ent)
    Joe_Turret_Base.Targets[ent] = nil
end

hook.Add("PlayerSpawn", "Joe_Turret_Base:JoinPlayers", function(ply)
    AddEntToTargets(ply)
end)

hook.Add("PlayerDisconnected", "Joe_Turret_Base:LeavePlayers", function(ply)
    RemoveEntFromTargets(ply)
end)

hook.Add("OnEntityCreated", "Joe_Turret_Base:AddEntities", function(ent)
    if not IsValid(ent) then return end
    local base = ent.Base
    local class = ent:GetClass()
    if ( base and base == "joes_turret_base") or (class and class == "joes_turret_base") then return end
    if ( base and Joe_Turret_Base.TargetBases[base] ) or (class and Joe_Turret_Base.TargetClasses[class]) then
        AddEntToTargets(ent)
    end
end)

hook.Add("EntityRemoved", "Joe_Turret_Base:AddEntities", function(ent)
    if Joe_Turret_Base.Targets[ent] then
        RemoveEntFromTargets(ent)
    end
end)

