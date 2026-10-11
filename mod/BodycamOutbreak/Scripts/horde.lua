-- Native zombie waves. All calls and timers execute on the game thread.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local policy=dofile(dir..'/horde_policy.lua')
local settings=dofile(dir..'/settings.lua')
-- Panel settings (F6) apply live: wave size/cap and speed are re-read every tick.
local function applySettings()
    local s=settings.get()
    policy.cap=s.zombiesPerWave;policy.waveSize=s.zombiesPerWave;policy.speed=s.speed
    policy.trigger=math.max(1,math.floor(s.zombiesPerWave/4))
    policy.attackDamage=settings.nativeDamage()
end
applySettings()
local targets=dofile(dir..'/targets.lua')
local function valid(o) return o and o:IsValid() end
local function log(message)
    local f=io.open(dir..'/../horde.log','a')
    if f then f:write(os.date('!%Y-%m-%dT%H:%M:%SZ'),' ',message,'\n');f:close() end
    print('[Outbreak horde] '..message..'\n')
end
local function currentWorld()
    for _,e in ipairs(FindAllOf('GameEngine') or {}) do
        if valid(e) and not e:GetFullName():find('Default__',1,true) and valid(e.GameViewport) then return e.GameViewport.World end
    end
end
local M={}
-- True once the match has ended (scoreboard / tablet map vote). Unknown counts as not over.
function M.matchOver(world)
    local ok,over=pcall(function() return world.GameState:IsMatchOver() end)
    return ok and over==true
end
function M.stop(world,reason)
    local s=_G.OutbreakHorde
    if not s then return end
    if s.handle then CancelDelayedAction(s.handle) end
    _G.OutbreakHorde=nil
    if valid(world) and world:GetFullName()==s.worldName then
        for _,z in ipairs(s.actors) do
            if valid(z) and not z:IsActorBeingDestroyed() then z:K2_DestroyActor() end
        end
    end
    log('STOP '..reason)
end
-- F10 / panel: stop waves and remove every zombie this mod spawned.
function M.cleanup()
    if not _G.OutbreakHorde then return 'nothing to clean up' end
    M.stop(currentWorld(),'F10 cleanup')
    return 'zombies removed'
end
function M.start(world)
    if _G.OutbreakHorde then M.stop(world,'toggle');return end
    local session=dofile(dir..'/probe.lua').capture(world,log)
    local allowed,reason=dofile(dir..'/session_gate.lua').check(session)
    assert(allowed,reason)
    assert(not M.matchOver(world),'match is over; hordes start again next match')
    dofile(dir..'/score_filter.lua')
    dofile(dir..'/melee.lua')
    local s={worldName=world:GetFullName(),actors={},deadAt={},remaining=policy.waveSize,wave=1,failures=0,ticks=0}
    local gs=StaticFindObject('/Script/Engine.Default__GameplayStatics')
    local nav=StaticFindObject('/Script/NavigationSystem.Default__NavigationSystemV1')
    local cls=StaticFindObject('/Game/BodycamZombies/ZombieAI/BP_NormalZombie.BP_NormalZombie_C')
    local pda=StaticFindObject('/Game/GM/Zombie/Gamemode/PDA/cemeteryZombies.cemeteryZombies')
    assert(valid(nav) and valid(cls) and valid(pda),'required native assets unavailable')
    _G.OutbreakHorde=s
    s.handle=LoopInGameThreadWithDelay(1000,function()
        local active=currentWorld()
        local ok,err=pcall(function()
            if not valid(active) or active:GetFullName()~=s.worldName then M.stop(nil,'world changed');return end
            -- End of match: same as pressing F10, so the vote screen is zombie-free.
            applySettings()
            if M.matchOver(active) then M.stop(active,'match over (auto cleanup)');return end
            local gm=active.AuthorityGameMode
            local humans={};gm:GetRealPlayersCount(humans)
            local k=StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
            session.server=k:IsServer(active)
            session.standalone=k:IsStandalone(active)
            session.publicLobby=gm:IsPublicLobby()
            session.humanCount=humans.PlayerCount
            local stillAllowed,why=dofile(dir..'/session_gate.lua').check(session)
            if not stillAllowed then M.stop(active,'session changed: '..why);return end
            local candidates=targets.collect(active)
            s.ticks=s.ticks+1
            local kept={}
            local deadAt={}
            local now=os.time()
            for _,z in ipairs(s.actors) do
                if valid(z) and not z:IsActorBeingDestroyed() and valid(z.RootComponent) then
                    if z:IsCharacterAlive() then
                        if #candidates>0 then
                            local target=targets.nearest(z:K2_GetActorLocation(),candidates)
                            z.Speed=policy.speed;z.TargetToGo=target.actor
                            if s.ticks%5==0 then log('TARGET '..z:GetFullName()..' -> '..target.name) end
                        end
                        kept[#kept+1]=z
                    else
                        local key=z:GetFullName()
                        local since=s.deadAt[key] or now
                        if now-since>=15 then
                            z:K2_DestroyActor()
                        else
                            deadAt[key]=since
                            kept[#kept+1]=z
                        end
                    end
                end
            end
            s.actors=kept
            s.deadAt=deadAt
            -- Corpses expire even while every player is waiting to respawn.
            if #candidates==0 then return end
            local pawn=candidates[((s.ticks-1) % #candidates)+1].actor
            local alive=0
            for _,z in ipairs(FindAllOf('BP_NormalZombie_C') or {}) do
                if valid(z) and not z:GetFullName():find('Default__',1,true) and valid(z.RootComponent)
                    and not z:IsActorBeingDestroyed() and z:GetWorld():GetFullName()==s.worldName and z:IsCharacterAlive() then alive=alive+1 end
            end
            local action=policy.step(s,alive)
            if action=='stop' then M.stop(active,'navigation placement failed ten times');return end
            if action=='wave' then log('WAVE '..s.wave..' queued='..s.remaining);action='spawn' end
            if action=='spawn' then
                local origin=pawn:K2_GetActorLocation()
                local point
                for attempt=1,6 do
                    local out={}
                    if nav:K2_GetRandomReachablePointInRadius(active,{X=origin.X,Y=origin.Y,Z=origin.Z},out,1600,nil,nil) then
                        local clear=true
                        for _,candidate in ipairs(candidates) do
                            local dx,dy=out.X-candidate.position.X,out.Y-candidate.position.Y
                            if dx*dx+dy*dy<600*600 then clear=false;break end
                        end
                        if clear then point=out;break end
                    end
                end
                if not point then s.failures=s.failures+1;log('PLACEMENT_RETRY '..s.failures);return end
                local z=active:SpawnActor(cls,{X=point.X,Y=point.Y,Z=point.Z+100},{Pitch=0,Yaw=0,Roll=0})
                if not valid(z) then s.failures=s.failures+1;return end
                s.actors[#s.actors+1]=z -- retain before initialization so errors clean up
                z.PDA_Zombie=pda;z.ShouldCommunicateDeath=false;z.ExpectedHealth=100
                z.AttackDamage=policy.attackDamage;z.Speed=policy.speed;z.TargetToGo=pawn
                local appearanceOK,appearanceError=pcall(function() dofile(dir..'/appearance.lua').apply(z) end)
                if not appearanceOK then log('APPEARANCE_SKIP '..tostring(appearanceError)) end
                s.remaining=s.remaining-1;s.failures=0
                log('SPAWN wave='..s.wave..' owned='..#s.actors..' remaining='..s.remaining..' speed='..tostring(z.Speed))
            end
            if s.ticks%5==0 then log('STATUS wave='..s.wave..' alive='..alive..' queued='..s.remaining) end
        end)
        if not ok then M.stop(active,'error '..tostring(err)) end
    end)
    log('START wave=1 queued='..policy.waveSize..' cap='..policy.cap..' speed='..policy.speed)
end
return M
