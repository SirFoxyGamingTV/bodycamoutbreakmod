local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local env=setmetatable({},{__index=_G})
env._G=env
env.io={open=function() return {write=function() end,close=function() end} end}
env.print=function() end
local mode='Team Deathmatch'
env.dofile=function(path)
    if path:find('modes.lua',1,true) then return {detect=function() return mode end} end
    return assert(loadfile(path,'t',env))()
end
local pre,post
env.StaticFindObject=function() return {IsValid=function() return true end} end
env.RegisterHook=function(_,a,b) pre,post=a,b;return 1,2 end
local world={AuthorityGameMode={}}
local function obj(name,extra)
    local o={IsValid=function() return true end,GetFullName=function() return name end,GetWorld=function() return world end}
    for k,v in pairs(extra or {}) do o[k]=v end
    return o
end
local function player(name,kills,score)
    local ps=obj(name..'PS',{Kill=kills,Score=score,GetPlayerName=function() return name end})
    return obj('PC_Bodycam_C '..name,{PlayerState=ps,Pawn=obj('Bodycam_Player_C '..name)})
end
local zombiePawn=obj('BP_NormalZombie_C z1')
env.OutbreakHorde={actors={zombiePawn}}
local M=env.dofile(dir..'/score_filter.lua')
local function param(v) local box={v=v};return {get=function() return box.v end,set=function(_,x) box.v=x end,box=box} end
local function notify(killer,victim) local i=param(killer);pre(nil,i,param(victim));post();return i end
local function zombie(name) return obj('AIC_Zombie_C '..name,{Pawn=zombiePawn}) end
local count=0
local function check(c) assert(c);count=count+1 end

-- pure counting rule
local a1,b1=M.zombieKill(nil);check(a1==0 and b1==1)
local a2,b2=M.zombieKill(9);check(a2==1 and b2==0)
local a3,b3=M.zombieKill(1);check(a3==0 and b3==2)
check(M.rule('Versus').every==nil and M.rule('Deathmatch').every==10 and M.rule('Gun Game').native)

-- Team Deathmatch: native credit blocked, score never changes, 1 kill per 10 zombies
local p=player('Alice',5,7)
local i=notify(p,zombie('c1'))
check(i.box.v==nil); check(p.PlayerState.Score==7 and p.PlayerState.Kill==5)
for _=2,9 do notify(p,zombie('c1b')) end
check(p.PlayerState.Score==7 and p.PlayerState.Kill==5)
notify(p,zombie('c1c'));check(p.PlayerState.Score==7 and p.PlayerState.Kill==6)

-- killed by a native zombie attack: score and kills restored
local b=player('Bob',3,2)
pre(nil,param(zombie('c4')),param(b));b.PlayerState.Score=1;post()
check(b.PlayerState.Score==2 and b.PlayerState.Kill==3)
-- melee self-kill marked by melee.lua: restored
env.OutbreakZombieHits={[b.Pawn:GetFullName()]=os.time()}
pre(nil,param(b),param(b));b.PlayerState.Kill=4;b.PlayerState.Score=0;post()
check(b.PlayerState.Score==2 and b.PlayerState.Kill==3)
-- ordinary self-kill without a zombie mark is untouched
pre(nil,param(b),param(b));b.PlayerState.Score=1;post()
check(b.PlayerState.Score==1)

-- Gun Game: nine zombie kills blocked, the tenth passed to the game as a real kill
mode='Gun Game'
local g=player('Gina',2,2)
for _=1,9 do check(notify(g,zombie('g')).box.v==nil) end
check(g.PlayerState.Kill==2 and g.PlayerState.Score==2)
local gi=param(g);pre(nil,gi,param(zombie('g10')))
check(gi.box.v==g) -- instigator kept so the game awards kill, score and gun upgrade
g.PlayerState.Kill=3;g.PlayerState.Score=3;post()
check(g.PlayerState.Kill==3 and g.PlayerState.Score==3)
check(notify(g,zombie('g11')).box.v==nil) -- counting restarts
-- Gun Game: killed by a zombie restores kills and score
pre(nil,param(zombie('g12')),param(g));g.PlayerState.Kill=2;g.PlayerState.Score=1;post()
check(g.PlayerState.Kill==3 and g.PlayerState.Score==3)

-- Versus: zombie kills never award anything, even past ten
mode='Versus'
local vs=player('Vic',4,4)
for _=1,12 do check(notify(vs,zombie('v')).box.v==nil) end
check(vs.PlayerState.Kill==4 and vs.PlayerState.Score==4)
pre(nil,param(zombie('v2')),param(vs));vs.PlayerState.Score=3;post()
check(vs.PlayerState.Kill==4 and vs.PlayerState.Score==4)
return count
