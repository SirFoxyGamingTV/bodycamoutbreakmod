-- City Sample civilian look for owned zombies. Needs OutbreakCivilians_P.pak in Content/Paks/~mods.
-- The zombie keeps its own (hidden) mesh, animation, collision and damage; a City Sample person
-- rides on it: an invisible SK_Base skeleton copies the zombie pose through ABP_CivilianRetarget,
-- and body/top/bottom/shoes/face follow that skeleton. Purely visual and host-local.
local M={}
local function valid(o) return o and o:IsValid() end
local CS='/Game/CitySampleCrowd/Character/'
local ABP='/Game/OutbreakCivilians/Rig/ABP_CivilianRetarget.ABP_CivilianRetarget_C'
local OVERLAY='/Game/OutbreakCivilians/Materials/M_ZombieOverlay.M_ZombieOverlay'
M.FOOT_OFFSET=8.4 -- City Sample feet sit 8.4 cm lower than the zombie skeleton's
M.SEXES={
    {folder='Male',p='m',faces={'001','002','003','004','005','006'},
     tops={'crewneck','crewneck','crewneck','buttonOpen','buttonDown','turtleneck'},
     bottoms={'jeans','jeans','jeansLong','slacks'},shoes={'loafers','oxfords'},
     hair={{'Hair_S_AfroFade','m_001'},{'Hair_S_BuzzCut','m_004'},{'Hair_S_PulledBack','m_004'},
           {'Hair_M_SideSweptFringe','m_003'},{'Hair_S_CurlyFade','m_002'},{'Hair_S_Messy','m_002'},{'Hair_S_HairLoss','m_006'}}},
    {folder='Female',p='f',faces={'001','002','003','004','005','006'},
     tops={'scoopneck','scoopneck','scoopneck','buttonOpen','buttonDown','turtleneck'},
     bottoms={'jeans','jeans','slacks','skirt'},shoes={'dressFlats','loafers','oxfords'},
     hair={{'Hair_S_Messy','f_006'},{'Hair_M_BobCurly','f_005'},{'Hair_S_Updo','f_004'},
           {'Hair_S_LowPonytail','f_003'},{'Hair_S_Pixie','f_002'},{'Hair_S_Coil','f_001'}}},
}
M.WEIGHTS={{'NormalWeight','nrw'},{'NormalWeight','nrw'},{'OverWeight','ovw'}}

local function asset(path) local name=path:match('([^/]+)$');return path..'.'..name end
local function mix(seed,salt) -- small integer hash so each choice varies independently
    local x=(seed*2654435761+salt*40503)&0x7fffffff
    x=((x~(x>>15))*2246822519)&0x7fffffff
    x=((x~(x>>13))*3266489917)&0x7fffffff
    return x~(x>>16)
end
local function pickFrom(list,seed,salt) return list[mix(seed,salt)%#list+1] end

-- Pure: which meshes/groom a zombie with this numeric id wears.
function M.pick(id)
    local sex=M.SEXES[mix(id,0)%2+1]
    local w=pickFrom(M.WEIGHTS,id,1)
    local dir=CS..sex.folder..'/'..w[1]..'/Meshes/'..sex.p..'_tal_'..w[2]..'_'
    local face=pickFrom(sex.faces,id,2)
    local hair=pickFrom(sex.hair,id,3)
    return {
        base=asset(dir..'base'),
        parts={asset(dir..'body'),asset(dir..pickFrom(sex.tops,id,4)),asset(dir..pickFrom(sex.bottoms,id,5)),
               asset(dir..pickFrom(sex.shoes,id,6))},
        face=asset(CS..sex.folder..'/'..sex.p..'_'..face..'/Face/'..sex.p..'_'..face..'_nrw_FaceMesh'),
        groom=asset(CS..sex.folder..'/'..hair[2]..'/Hair/Hair/'..hair[1]),
        binding=asset(CS..sex.folder..'/GroomBindings/GB_'..sex.p..'_'..face..'_nrw_FaceMesh_'..hair[1]),
        sex=sex.p,weight=w[2],
    }
end

-- Loading assets from a mod pak: UE4SS's LoadAsset looks assets up in the asset registry, which
-- does not know about mod paks until their folders are scanned. Try, in order: already loaded,
-- registry scan + LoadAsset, then KismetSystemLibrary's blocking soft-reference load.
local notes={}
local function note(text) notes[#notes+1]=text end
local function scanOnce()
    if _G.OutbreakCivilianScan then return end
    _G.OutbreakCivilianScan='none'
    for _,r in ipairs(FindAllOf and FindAllOf('AssetRegistryImpl') or {}) do
        if valid(r) and not r:GetFullName():find('Default__',1,true) then
            local ok,err=pcall(function()
                r:ScanPathsSynchronous({'/Game/OutbreakCivilians','/Game/CitySampleCrowd'},true,false)
            end)
            _G.OutbreakCivilianScan=ok and 'scanned' or ('scan error '..tostring(err))
            break
        end
    end
    note('registry '.._G.OutbreakCivilianScan)
end
local function load(path)
    local o=StaticFindObject(path)
    if valid(o) then return o end
    scanOnce()
    if LoadAsset then
        local ok,err=pcall(LoadAsset,path)
        o=StaticFindObject(path)
        if valid(o) then return o end
        note('LoadAsset '..path..': '..(ok and 'no object' or tostring(err)))
    end
    local k=StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
    local ok,err=pcall(function()
        local soft=k:MakeSoftObjectPath(path)
        local ref=k:Conv_SoftObjPathToSoftObjRef(soft)
        local loaded=k:LoadAsset_Blocking(ref)
        if valid(loaded) then o=loaded end
    end)
    if not valid(o) then o=StaticFindObject(path) end
    if valid(o) then return o end
    note('LoadAsset_Blocking '..path..': '..(ok and 'no object' or tostring(err)))
    return nil
end
M.load=load
-- Result is remembered for the game session (this file is re-run on every spawn).
function M.available()
    if _G.OutbreakCivilianAvailable==nil then
        local ok=load(OVERLAY)~=nil and load(ABP)~=nil
        _G.OutbreakCivilianAvailable=ok
        print('[Outbreak civilians] asset pak '..(ok and 'found' or 'not loadable; using native zombie look')..'\n')
        for _,n in ipairs(notes) do print('[Outbreak civilians]   '..n..'\n') end
    end
    return _G.OutbreakCivilianAvailable
end

local IDENTITY={Rotation={X=0,Y=0,Z=0,W=1},Translation={X=0,Y=0,Z=0},Scale3D={X=1,Y=1,Z=1}}
local SNAP=2 -- EAttachmentRule::SnapToTarget
local function addComponent(z,class,parent,mesh)
    local c=z:AddComponentByClass(class,true,IDENTITY,false)
    assert(valid(c),'component creation failed')
    c:K2_AttachToComponent(parent,FName('None'),SNAP,SNAP,SNAP,false)
    if mesh then c:SetSkeletalMeshAsset(mesh) end
    return c
end
local function overlayFor(z,skin)
    local lib=StaticFindObject('/Script/Engine.Default__KismetMaterialLibrary')
    local mid=lib:CreateDynamicMaterialInstance(z,load(OVERLAY),FName('None'),0)
    local id=tonumber(z:GetFullName():match('(%d+)$')) or 0
    local v=(id%5)*0.02
    if skin then
        mid:SetVectorParameterValue(FName('ZombieTint'),{R=0.68+v,G=0.77+v,B=0.64+v,A=1})
        mid:SetScalarParameterValue(FName('BloodAmount'),0.10+(id%4)*0.03)
    else
        mid:SetVectorParameterValue(FName('ZombieTint'),{R=0.76+v,G=0.74+v,B=0.70+v,A=1})
        mid:SetScalarParameterValue(FName('BloodAmount'),0.05+(id%3)*0.03)
    end
    return mid
end

-- Dress one zombie. Returns a description string. Errors leave the zombie in its native look.
function M.apply(z)
    _G.OutbreakCivilianLooks=_G.OutbreakCivilianLooks or {}
    local key=z:GetFullName()
    if _G.OutbreakCivilianLooks[key] then return 'already dressed' end
    local id=tonumber(key:match('(%d+)$')) or 0
    local look=M.pick(id)
    local skelClass=StaticFindObject('/Script/Engine.SkeletalMeshComponent')
    local abp=load(ABP)
    local base=load(look.base)
    assert(valid(abp) and valid(base),'civilian base assets missing')
    local created={}
    local ok,err=pcall(function()
        local b=addComponent(z,skelClass,z.Mesh,base)
        created[#created+1]=b
        b:K2_SetRelativeLocation({X=0,Y=0,Z=M.FOOT_OFFSET},false,{},false)
        b:SetAnimInstanceClass(abp)
        local parts={}
        for _,path in ipairs(look.parts) do parts[#parts+1]={path=path,skin=path:find('_body.',1,true)~=nil} end
        parts[#parts+1]={path=look.face,skin=true,face=true}
        local faceComp
        for _,p in ipairs(parts) do
            local mesh=load(p.path)
            if mesh then
                local c=addComponent(z,skelClass,b,mesh)
                created[#created+1]=c
                c:SetLeaderPoseComponent(b,false,false)
                c:SetOverlayMaterial(overlayFor(z,p.skin))
                if p.face then faceComp=c end
            else
                print('[Outbreak civilians] missing '..p.path..'\n')
            end
        end
        local groomClass=StaticFindObject('/Script/HairStrandsCore.GroomComponent')
        local groom,binding=load(look.groom),load(look.binding)
        if valid(groomClass) and faceComp and groom then
            local g=addComponent(z,groomClass,faceComp,nil)
            created[#created+1]=g
            if binding then g:SetBindingAsset(binding) end
            g:SetGroomAsset(groom)
            pcall(function() g:SetEnableSimulation(false) end)
        end
        -- The zombie mesh keeps animating (it drives the civilian) but is no longer drawn.
        z.Mesh.VisibilityBasedAnimTickOption=0 -- AlwaysTickPoseAndRefreshBones
        z.Mesh:SetVisibility(false,false)
    end)
    if not ok then
        for _,c in ipairs(created) do if valid(c) then pcall(function() c:K2_DestroyComponent(c) end) end end
        pcall(function() z.Mesh:SetVisibility(true,false) end)
        error(err)
    end
    _G.OutbreakCivilianLooks[key]=look
    return string.format('%s/%s face=%s', look.sex, look.weight, look.face:match('([^/.]+)$'))
end

-- Called by the appearance monitor: keep the zombie mesh hidden if the game re-shows it.
function M.maintain(z)
    if _G.OutbreakCivilianLooks and _G.OutbreakCivilianLooks[z:GetFullName()] and z.Mesh:IsVisible() then
        z.Mesh:SetVisibility(false,false)
    end
end
function M.dressed(z) return _G.OutbreakCivilianLooks~=nil and _G.OutbreakCivilianLooks[z:GetFullName()]~=nil end
return M
