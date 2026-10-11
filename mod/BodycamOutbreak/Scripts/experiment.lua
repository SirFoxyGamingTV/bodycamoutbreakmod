-- Explicit one-shot integration experiment, dispatched on the game thread.
local source=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/')
local scripts=assert(source:match('^(.*)/[^/]+$'))
local function valid(o) return o and o:IsValid() end
return function(world, write, command)
    if not command then
        local request=io.open(scripts..'/../experiment.request','r')
        if not request then return end
        command=request:read('*l'); request:close()
        assert(os.remove(scripts..'/../experiment.request')) -- consume before any mutation
    end
    local appearancePreview=command=='appearance-preview'
    if appearancePreview then command='spawn-one' end
    if command=='cleanup-one' then dofile(scripts..'/horde.lua').stop(world,'F10 cleanup') end
    if command=='horde' then dofile(scripts..'/horde.lua').start(world);return end
    local s=dofile(scripts..'/probe.lua').capture(world,write)
    local allowed,reason=dofile(scripts..'/session_gate.lua').check(s)
    assert(allowed,reason)
    dofile(scripts..'/score_filter.lua')
    dofile(scripts..'/melee.lua')
    if appearancePreview then
        local owned=dofile(scripts..'/ownership.lua')
        for _,candidate in ipairs(FindAllOf('BP_NormalZombie_C') or {}) do
            if valid(candidate) and owned.contains(candidate) and not candidate:IsActorBeingDestroyed()
                and candidate:IsCharacterAlive() and candidate:GetWorld():GetFullName()==world:GetFullName() then
                dofile(scripts..'/appearance.lua').apply(candidate)
                write('APPEARANCE_PREVIEW applied to existing '..candidate:GetFullName())
                return
            end
        end
    end
    -- Event hooks disabled during crash-isolation testing.
    if command=='isolate' then
        assert(StaticFindObject('/Script/AIModule.BrainComponent:StopLogic'):IsValid(),'StopLogic unavailable')
        assert(StaticFindObject('/Script/AIModule.BrainComponent:RestartLogic'):IsValid(),'RestartLogic unavailable')
        local brains={}
        for _,bot in ipairs(FindAllOf('AI_Humanoid_C') or {}) do
            if valid(bot) and valid(bot:GetWorld()) and bot:GetWorld():GetFullName()==world:GetFullName() and valid(bot.Controller) then
                local brain=bot.Controller.BrainComponent
                if valid(brain) then
                    table.insert(brains,brain)
                    brain:StopLogic('BodycamOutbreak 45-second melee isolation test')
                end
            end
        end
        write('EXPERIMENT paused soldier brains='..#brains)
        ExecuteInGameThreadWithDelay(45000,function()
            for _,brain in ipairs(brains) do if valid(brain) then brain:RestartLogic() end end
            print('[BodycamOutbreak] soldier AI restored after isolation test\n')
        end)
        assert(#brains==6,'did not pause the expected six soldier bots')
        command='spawn-one'
    end
    if command=='observe' then dofile(scripts..'/monitor.lua')(world); write('EXPERIMENT observing 60 seconds'); return end
    assert(command=='spawn-one' or command=='cleanup-one','unknown experiment command')
    if command=='cleanup-one' then
        local owned=_G.OutbreakOwnedZombie
        if valid(owned) and valid(owned:GetWorld()) and owned:GetWorld():GetFullName()==world:GetFullName() then
            owned:K2_DestroyActor()
            write('EXPERIMENT cleaned owned actor')
        end
        _G.OutbreakOwnedZombie=nil
        return
    end
    for _,existing in ipairs(FindAllOf('BP_NormalZombie_C') or {}) do
        if valid(existing) and valid(existing.RootComponent) and not existing:IsActorBeingDestroyed() and existing:IsCharacterAlive() and not existing:GetFullName():find('Default__',1,true)
            and existing:GetWorld():GetFullName()==world:GetFullName() then
            error('single-zombie limit reached')
        end
    end
    local gs=StaticFindObject('/Script/Engine.Default__GameplayStatics')
    local pawn=gs:GetPlayerController(world,0).Pawn
    assert(valid(pawn) and pawn:IsCharacterAlive(),'living local pawn required')
    local cls=StaticFindObject('/Game/BodycamZombies/ZombieAI/BP_NormalZombie.BP_NormalZombie_C')
    local pda=StaticFindObject('/Game/GM/Zombie/Gamemode/PDA/cemeteryZombies.cemeteryZombies')
    assert(valid(cls) and valid(pda),'zombie assets unavailable')
    local p=pawn:K2_GetActorLocation(); local f=pawn:GetActorForwardVector()
    write('EXPERIMENT begin spawn-one')
    local z=world:SpawnActor(cls,{X=p.X+f.X*200,Y=p.Y+f.Y*200,Z=p.Z+20},{Pitch=0,Yaw=0,Roll=0})
    assert(valid(z),'spawn rejected, possibly blocked by collision')
    write('EXPERIMENT spawned '..z:GetFullName())
    local ok,err=pcall(function()
        z.PDA_Zombie=pda
        z.ShouldCommunicateDeath=false
        z.ExpectedHealth=100
        z.AttackDamage=10000
        z.Speed=420
        z.TargetToGo=pawn
    end)
    if not ok then
        if valid(z) then z:K2_DestroyActor() end
        error(err)
    end
    _G.OutbreakOwnedZombie=z
    if appearancePreview then
        dofile(scripts..'/appearance.lua').apply(z)
        write('APPEARANCE_PREVIEW clothed infected applied')
    end
    write('EXPERIMENT finished '..z:GetFullName())
    local expectedWorld=world:GetFullName()
    local function sessionStillCurrent()
        for _,engine in ipairs(FindAllOf('GameEngine') or {}) do
            if valid(engine) and not engine:GetFullName():find('Default__',1,true) and valid(engine.GameViewport) then
                local current=engine.GameViewport.World
                return valid(current) and current:GetFullName()==expectedWorld
            end
        end
        return false
    end
    local function sample()
        local out=assert(io.open(scripts..'/../spawn-telemetry.txt','a'))
        local function log(v) out:write(tostring(v),'\n'); out:flush() end
        log('SAMPLE '..os.date('!%Y-%m-%dT%H:%M:%SZ')..' valid='..tostring(valid(z)))
        local yes,why=pcall(function()
            if valid(z) and not z:IsActorBeingDestroyed() and valid(z.RootComponent) then
                local health={}; z:GetHealth(health)
                local dead={}; z:IsDead(dead)
                local pos=z:K2_GetActorLocation()
                log(string.format('ZOMBIE health=%s dead=%s pos=%.1f,%.1f,%.1f',tostring(health.Health),tostring(dead['Dead?']),pos.X,pos.Y,pos.Z))
                log('DESTROYING '..tostring(z:IsActorBeingDestroyed()))
                log('ROOT '..(valid(z.RootComponent) and z.RootComponent:GetFullName() or 'none'))
                log('WORLD '..(valid(z:GetWorld()) and z:GetWorld():GetFullName() or 'none'))
                log('CONTROLLER '..(valid(z.Controller) and z.Controller:GetFullName() or 'none'))
                log('TARGET '..(valid(z.TargetToGo) and z.TargetToGo:GetFullName() or 'none'))
                log('MESH '..tostring(z.Mesh.SkeletalMesh))
            end
        end)
        if not yes then log('ERROR '..tostring(why)) end
        out:close()
    end
    sample()
    dofile(scripts..'/monitor.lua')(world)
    local remaining=120
    local handle
    handle=LoopInGameThreadWithDelay(500,function()
        if remaining<=0 then CancelDelayedAction(handle); return end
        -- Check the current world before touching the captured actor reference.
        if not sessionStillCurrent() or _G.OutbreakOwnedZombie~=z then
            CancelDelayedAction(handle)
            return
        end
        sample()
        remaining=remaining-1
        if remaining<=0 then CancelDelayedAction(handle) end
    end)
    print('[BodycamOutbreak] spawned one experimental zombie; behavior unverified\n')
end









