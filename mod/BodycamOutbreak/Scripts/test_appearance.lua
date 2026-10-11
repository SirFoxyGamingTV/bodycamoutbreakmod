-- appearance.lua: civilian look when the pak is present, native clothed mesh otherwise.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local count=0
local function check(c,msg) assert(c,msg);count=count+1 end
local function obj(name,extra)
    local o={IsValid=function() return true end,GetFullName=function() return name end}
    for k,v in pairs(extra or {}) do o[k]=v end
    return o
end
local function run(pak)
    local env=setmetatable({},{__index=_G}); env._G=env
    env.print=function() end
    env.FName=function(s) return s end
    env.LoopInGameThreadWithDelay=function() return 1 end
    env.FindAllOf=function() return {} end
    local skel=obj('Skeleton ALS_Mannequin_Skeleton')
    local native=obj('SkeletalMesh /Game/ZombiesPackV4/Zombie_Jocker/joker_CHEMISE_PANTALON.joker_CHEMISE_PANTALON',{Skeleton=skel})
    env.StaticFindObject=function(p)
        if p:find('joker_CHEMISE',1,true) then return native end
        return {IsValid=function() return false end}
    end
    local civ={applied=0}
    env.dofile=function(path)
        if path:find('civilians.lua',1,true) then
            return {available=function() return pak end,apply=function() civ.applied=civ.applied+1;return 'm/nrw' end,
                    dressed=function() return false end,maintain=function() end}
        end
        return assert(loadfile(path,'t',env))()
    end
    local M=assert(loadfile(dir..'/appearance.lua','t',env))()
    local tinted=0
    local comp={IsValid=function() return true end,SkeletalMesh=obj('SkeletalMesh momie',{Skeleton=skel})}
    function comp:GetNumMaterials() return 3 end
    function comp:GetMaterial() return obj('Material m') end
    function comp:SetMaterial() end
    function comp:SetSkeletalMeshAsset(m) self.SkeletalMesh=m end
    function comp:CreateDynamicMaterialInstance() return obj('MID',{SetVectorParameterValue=function() tinted=tinted+1 end}) end
    local z=obj('BP_NormalZombie_C 2147480001',{Mesh=comp,IsActorBeingDestroyed=function() return false end,
        IsCharacterAlive=function() return true end})
    M.apply(z)
    return comp.SkeletalMesh,tinted,civ.applied,native
end
local mesh,tinted,civ,native=run(false)
check(mesh==native and tinted>0 and civ==0,'no pak: native clothed mesh with palette')
mesh,tinted,civ,native=run(true)
check(civ==1 and mesh~=native and tinted==0,'pak: civilian look, native mesh untouched')
return count
