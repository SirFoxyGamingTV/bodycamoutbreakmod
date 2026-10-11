-- Zombie scoring rules, applied on the host around the native kill notification.
-- In every mode, anyone killed by a zombie keeps their Kill and Score exactly as they were.
-- Rewards for killing mod-owned zombies depend on the mode (see RULES below):
--  * Gun Game: every 10th zombie kill is passed to the game as a normal kill, so the game
--    itself awards the Kill, the Score and the weapon upgrade.
--  * Team Deathmatch (and Deathmatch/Hardpoint/Zombies): every 10th zombie kill adds 1 Kill; Score unchanged.
--  * Versus: zombie kills award nothing.
-- The hook is registered once; the handlers are globals so F7 off/on reloads new logic.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local path='/Script/Bodycam.BodycamGameMode:NotifyPlayerKilled'
local ZOMBIES_PER_KILL=10
local RULES={
    ['Gun Game']={every=ZOMBIES_PER_KILL,native=true},
    ['Versus']={},
    default={every=ZOMBIES_PER_KILL},
}
local owned=dofile(dir..'/ownership.lua')
local modes=dofile(dir..'/modes.lua')
local function valid(o) return o and o:IsValid() end
local function log(message,console)
    local f=io.open(dir..'/../score-filter.log','a')
    if f then f:write(os.date('!%Y-%m-%dT%H:%M:%SZ'),' ',message,'\n');f:close() end
    if console then print('[Outbreak] '..message..'\n') end
end
local function displayName(controller)
    local ok,name=pcall(function()
        local n=controller.PlayerState:GetPlayerName()
        if type(n)~='string' then n=n:ToString() end
        if n~='' then return n end
    end)
    if ok and name then return name end
    return valid(controller) and ((controller:GetFullName():match('([^%.:]+)$') or 'unknown')..' (bot)') or 'unknown'
end
local function zombieController(c)
    return valid(c) and (c:GetFullName():find('AIC_Zombie_C',1,true)~=nil or owned.contains(c.Pawn))
end
-- melee.lua marks pawns it hits; its lethal hits are reported by the game as self-kills.
local function hitByZombie(pawn)
    local hits=_G.OutbreakZombieHits
    if not hits or not valid(pawn) then return false end
    local key=pawn:GetFullName()
    local at=hits[key]
    hits[key]=nil
    return at~=nil and os.time()-at<=2
end
local M={}
-- Pure: count one zombie kill. Returns kills to add now and the zombie kills still banked.
function M.zombieKill(banked,every)
    every=every or ZOMBIES_PER_KILL
    banked=(banked or 0)+1
    return math.floor(banked/every),banked%every
end
function M.rule(mode) return RULES[mode] or RULES.default end
local function currentMode(controller)
    local ok,mode=pcall(function() return (modes.detect(controller:GetWorld().AuthorityGameMode)) end)
    return ok and mode or nil
end
_G.OutbreakHalfKills=_G.OutbreakHalfKills or {}

local stack={}
_G.OutbreakScorePre=function(instigator,victim)
    local record={}
    stack[#stack+1]=record
    local v=victim:get()
    if not valid(v) then return end
    local k=instigator:get()
    if owned.contains(v.Pawn) then
        if not (valid(k) and valid(k.PlayerState)) then instigator:set(nil);return end
        local ps=k.PlayerState
        local mode=currentMode(k)
        local rule=M.rule(mode)
        local add,banked=0,nil
        if rule.every then
            local key=ps:GetFullName()
            add,banked=M.zombieKill(_G.OutbreakHalfKills[key],rule.every)
            _G.OutbreakHalfKills[key]=banked
        end
        local progress=rule.every and (' zombies toward next kill '..banked..'/'..rule.every) or ''
        if add>0 and rule.native then
            -- Let the game credit this one as a real kill (Kill, Score and Gun Game upgrade).
            record.native={ps=ps,kills=ps.Kill,score=ps.Score,name=displayName(k),mode=mode}
            return
        end
        record.award={ps=ps,kills=ps.Kill,score=ps.Score,add=add,name=displayName(k),mode=mode,progress=progress}
        instigator:set(nil)
        return
    end
    if zombieController(k) or hitByZombie(v.Pawn) then
        local ps=v.PlayerState
        if valid(ps) then record.protect={ps=ps,kills=ps.Kill,score=ps.Score} end
        log('KILL zombie killed player="'..displayName(v)..'"',true)
    end
end
_G.OutbreakScorePost=function()
    local r=table.remove(stack)
    if not r then return end
    local p=r.protect
    if p and valid(p.ps) then
        local before=tostring(p.ps.Score)
        p.ps.Kill=p.kills;p.ps.Score=p.score
        log('PROTECT score '..before..'->'..tostring(p.score)..' kills kept at '..tostring(p.kills))
    end
    local a=r.award
    if a and valid(a.ps) then
        a.ps.Kill=a.kills+a.add;a.ps.Score=a.score
        log('ZOMBIE_KILL ['..tostring(a.mode)..'] player="'..a.name..'" kills '..tostring(a.kills)..'->'..tostring(a.kills+a.add)..a.progress,true)
    end
    local n=r.native
    if n and valid(n.ps) then
        log('ZOMBIE_KILL ['..tostring(n.mode)..'] player="'..n.name..'" 10 zombies = real kill: kills '..tostring(n.kills)..'->'..tostring(n.ps.Kill)
            ..' score '..tostring(n.score)..'->'..tostring(n.ps.Score),true)
    end
end

if not _G.OutbreakScoreHookV2 then
    assert(StaticFindObject(path):IsValid(),'native kill notification unavailable')
    local old=_G.OutbreakScoreFilter -- replace the earlier filter-only hook if it is loaded
    if old then pcall(UnregisterHook,path,old.pre,old.post);_G.OutbreakScoreFilter=nil end
    local pre,post=RegisterHook(path,function(context,instigator,victim)
        local ok,err=pcall(_G.OutbreakScorePre,instigator,victim)
        if not ok then log('ERROR '..tostring(err)) end
    end,function()
        local ok,err=pcall(_G.OutbreakScorePost)
        if not ok then log('ERROR '..tostring(err)) end
    end)
    _G.OutbreakScoreHookV2={pre=pre,post=post}
    log('READY zombie scoring rules')
end
return M
