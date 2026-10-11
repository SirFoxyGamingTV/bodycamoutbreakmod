local source=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/')
local scripts=assert(source:match('^(.*)/[^/]+$'))
if _G.OutbreakEventHooks then return end
_G.OutbreakEventHooks={}
local function name(o) return o and o:IsValid() and o:GetFullName() or '<none>' end
local function log(text)
    local f=assert(io.open(scripts..'/../combat-events.txt','a'))
    f:write(os.date('!%Y-%m-%dT%H:%M:%SZ'),' ',text,'\n'); f:close()
end
local function hook(path,callback)
    assert(StaticFindObject(path):IsValid(),'event unavailable: '..path)
    local a,b=RegisterHook(path,function(...)
        local ok,err=pcall(callback,...)
        if not ok then log('ERROR '..tostring(err)) end
    end)
    table.insert(_G.OutbreakEventHooks,{path=path,pre=a,post=b})
end
hook('/Game/BodycamZombies/ZombieAI/Zombie.Zombie_C:AttackHitDetection',function(context)
    log('ZOMBIE_HIT_DETECTION '..name(context:get()))
end)
hook('/BodycamAnimationFramework/Blueprints/Bodycam_Player.Bodycam_Player_C:ApplyPointDamage',
    function(context,damage,force,bone,location,direction,controller)
        log('PLAYER_POINT_DAMAGE target='..name(context:get())..' damage='..tostring(damage:get())..' instigator='..name(controller:get()))
    end)
hook('/Script/Bodycam.BodycamCharacter:OnDeathStarted',function(context,actor)
    log('DEATH '..name(actor:get()))
end)
log('HOOKS_READY '..#_G.OutbreakEventHooks)
