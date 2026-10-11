-- Apply native point damage on the host at the zombie's attack-hit event.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local owned=dofile(dir..'/ownership.lua')
local function valid(o) return o and o:IsValid() end
local function log(message)
    local f=io.open(dir..'/../melee.log','a')
    if f then f:write(os.date('!%Y-%m-%dT%H:%M:%SZ'),' ',message,'\n');f:close() end
end
local recent={}
_G.OutbreakMeleeHandler=function(z)
    if not owned.contains(z) or z:IsActorBeingDestroyed() or not z:IsCharacterAlive() then return end
    local world=z:GetWorld()
    local k=StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
    if not valid(world) or not k:IsServer(world) then return end
    local target=z.TargetToGo
    if not valid(target) or target:IsActorBeingDestroyed() or not target:IsCharacterAlive() then return end
    if target:GetWorld():GetFullName()~=world:GetFullName() then return end
    local zp,tp=z:K2_GetActorLocation(),target:K2_GetActorLocation()
    local dx,dy,dz=tp.X-zp.X,tp.Y-zp.Y,tp.Z-zp.Z
    if dx*dx+dy*dy>180*180 or math.abs(dz)>120 then return end
    local controller=z.Controller
    if not valid(controller) then return end
    if not controller:LineOfSightTo(target,{X=0,Y=0,Z=0},false) then return end
    local now=os.time()
    local key=z:GetFullName()
    if recent[key]==now then return end
    recent[key]=now
    local before={};target:GetHealth(before)
    if type(before.Health)~='number' or before.Health<=0 then return end
    local amount=dofile(dir..'/settings.lua').hitDamage(before.Health) -- F6 panel: damage per hit
    -- score_filter.lua reads this mark: the game reports these kills as self-kills.
    _G.OutbreakZombieHits=_G.OutbreakZombieHits or {}
    _G.OutbreakZombieHits[target:GetFullName()]=now
    target:ApplyPointDamage(amount,0,FName('None'),{X=tp.X,Y=tp.Y,Z=tp.Z},{X=dx,Y=dy,Z=dz},controller,true)
    local after={};target:GetHealth(after)
    log('HIT target='..target:GetFullName()..' health='..tostring(before.Health)..'->'..tostring(after.Health)..' alive='..tostring(target:IsCharacterAlive()))
end
if not _G.OutbreakMeleeHook then
    local attack='/Game/BodycamZombies/ZombieAI/Zombie.Zombie_C:AttackHitDetection'
    assert(StaticFindObject(attack):IsValid(),'zombie hit event unavailable')
    assert(StaticFindObject('/Script/Engine.Controller:LineOfSightTo'):IsValid(),'line of sight API unavailable')
    local pre,post=RegisterHook(attack,function(context)
        local ok,err=pcall(_G.OutbreakMeleeHandler,context:get())
        if not ok then log('ERROR '..tostring(err)) end
    end)
    _G.OutbreakMeleeHook={pre=pre,post=post}
    log('READY host attack-hit handler')
end
