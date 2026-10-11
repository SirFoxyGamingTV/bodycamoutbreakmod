-- Read-only live integration telemetry. Call only on the game thread.
local source = debug.getinfo(1, 'S').source:gsub('^@', ''):gsub('\\', '/')
local scripts = assert(source:match('^(.*)/[^/]+$'))
local gate = dofile(scripts .. '/session_gate.lua')
local function valid(o) return o and o:IsValid() end
local function name(o) return valid(o) and o:GetFullName() or '<none>' end
local function query(fn)
    local ok, value = pcall(fn)
    if ok then return value end
    return nil, tostring(value)
end
local M = {}
function M.capture(world, write)
    local gs = StaticFindObject('/Script/Engine.Default__GameplayStatics')
    local k = StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
    local gm = world.AuthorityGameMode
    local zombieClass = StaticFindObject('/Game/GM/Zombie/Gamemode/GM_Zombie.GM_Zombie_C')
    local s = {
        server = k:IsServer(world), standalone = k:IsStandalone(world),
        zombieMode = valid(gm) and valid(zombieClass) and gm:IsA(zombieClass),
    }
    local config
    s.modeName,config=dofile(scripts..'/modes.lua').detect(gm)
    s.hardpointMode=s.modeName=='Hardpoint'
    s.supportedMode=s.modeName~=nil
    write('SESSION mode='..tostring(s.modeName)..' gamemode='..name(gm)..' config='..tostring(config))
    write('SESSION hardpointMode='..tostring(s.hardpointMode))
    if s.supportedMode then s.publicLobby = query(function() return gm:IsPublicLobby() end) end
    s.playerCount = query(function() return world.GameState.PlayerArray:GetArrayNum() end)
    s.humanCount = query(function() local out={}; gm:GetRealPlayersCount(out); return out.PlayerCount end)
    local allowed, reason = gate.check(s)
    for _, key in ipairs({'server','standalone','zombieMode','supportedMode','publicLobby','playerCount','humanCount'}) do
        write('SESSION ' .. key .. '=' .. tostring(s[key]))
    end
    write('SESSION gameplayAllowed=' .. tostring(allowed) .. ' reason=' .. reason)
    local function actor(a, label)
        write(label .. ' ' .. name(a))
        local pos, err = query(function() return a:K2_GetActorLocation() end)
        if pos then write(string.format('  POSITION %.2f %.2f %.2f', pos.X,pos.Y,pos.Z)) end
        if err then write('  POSITION_ERROR ' .. err) end
        local health, why = query(function()
            local out = {}; a:GetHealth(out); return out.Health
        end)
        write('  HEALTH ' .. tostring(health) .. (why and (' ERROR ' .. why) or ''))
    end
    local pc = gs:GetPlayerController(world, 0)
    if valid(pc) and valid(pc.Pawn) then actor(pc.Pawn, 'PLAYER') end
    local count = 0
    for _, z in ipairs(FindAllOf('BP_NormalZombie_C') or {}) do
        if valid(z) and valid(z.RootComponent) and not z:IsActorBeingDestroyed() and not z:GetFullName():find('Default__',1,true)
            and name(z:GetWorld()) == name(world) then
            count = count + 1
            if count <= 8 then
                actor(z, 'ZOMBIE')
                local speed=query(function() return z.Speed end)
                write('  SPEED '..tostring(speed))
                local movement,why=query(function() return z.CharacterMovement.MaxWalkSpeed end)
                write('  MAX_WALK_SPEED '..tostring(movement)..(why and (' ERROR '..why) or ''))
                local dead={}; z:IsDead(dead); write('  DEAD '..tostring(dead['Dead?']))
                write('  CONTROLLER ' .. name(z.Controller))
                write('  TARGET ' .. name(z.TargetToGo))
            end
        end
    end
    write('ZOMBIE_COUNT ' .. count)
    return s
end
return M


