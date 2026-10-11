local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local env=setmetatable({},{__index=_G})
env._G=env
env.OutbreakMeleeHook=true
env.FName=function(s) return s end
local printed={}
env.print=function(m) printed[#printed+1]=m end
env.io={open=function() return {write=function() end,close=function() end} end}
env.dofile=function(path) return assert(loadfile(path,'t',env))() end
local server,visible=true,true
env.StaticFindObject=function() return {IsServer=function() return server end} end
local world={IsValid=function() return true end,GetFullName=function() return 'world' end}
local position={X=100,Y=0,Z=0}
local health,hits=100,0
local target={IsValid=function() return true end,IsActorBeingDestroyed=function() return false end,
    IsCharacterAlive=function() return health>0 end,GetWorld=function() return world end,
    K2_GetActorLocation=function() return position end,GetFullName=function() return 'target' end,
    GetHealth=function(self,out) out.Health=health end,
    ApplyPointDamage=function(self,damage) hits=hits+1;health=health-damage end,
    PlayerState={IsValid=function() return true end,GetPlayerName=function() return 'TestPlayer' end}}
local name='z1'
local z={IsValid=function() return true end,IsActorBeingDestroyed=function() return false end,
    IsCharacterAlive=function() return true end,GetFullName=function() return name end,
    GetWorld=function() return world end,K2_GetActorLocation=function() return {X=0,Y=0,Z=0} end,
    TargetToGo=target,Controller={IsValid=function() return true end,LineOfSightTo=function() return visible end}}
env.OutbreakHorde={actors={z}}
env.dofile(dir..'/melee.lua')
env.OutbreakMeleeHandler(z);assert(hits==1 and health<=0)
assert(env.OutbreakZombieHits.target)
health=100;name='z2';server=false;env.OutbreakMeleeHandler(z);assert(hits==1)
server=true;visible=false;env.OutbreakMeleeHandler(z);assert(hits==1)
visible=true;position.X=181;env.OutbreakMeleeHandler(z);assert(hits==1)
position.X=100;position.Z=121;env.OutbreakMeleeHandler(z);assert(hits==1)
position.Z=0;env.OutbreakHorde=nil;env.OutbreakMeleeHandler(z);assert(hits==1)
return 7
