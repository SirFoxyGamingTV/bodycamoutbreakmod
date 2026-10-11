-- civilians.lua: deterministic picks and component assembly with mocked engine objects.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local count=0
local function check(c,msg) assert(c,msg);count=count+1 end
local function obj(name,extra)
    local o={IsValid=function() return true end,GetFullName=function() return name end}
    for k,v in pairs(extra or {}) do o[k]=v end
    return o
end
local env=setmetatable({},{__index=_G}); env._G=env
env.print=function() end
env.FName=function(s) return s end
local loaded={}
local pakInstalled=true
env.StaticFindObject=function(p)
    if p:find('KismetMaterialLibrary',1,true) then
        return obj('lib',{CreateDynamicMaterialInstance=function(_,_,parent) local params={}
            return obj('MID',{params=params,SetVectorParameterValue=function(_,k,v) params[k]=v end,
                SetScalarParameterValue=function(_,k,v) params[k]=v end}) end})
    end
    if p:find('^/Script/') then return obj(p) end
    if pakInstalled and (p:find('/Game/',1,true)==1) then loaded[p]=loaded[p] or obj(p);return loaded[p] end
    return {IsValid=function() return false end}
end
local M=assert(loadfile(dir..'/civilians.lua','t',env))()
-- picks are deterministic and complete
local a,b=M.pick(2147481234),M.pick(2147481234)
check(a.face==b.face and a.groom==b.groom and a.parts[2]==b.parts[2],'deterministic')
check(#a.parts==4 and a.base:find('_base%.') and a.parts[1]:find('_body%.'),'base/body')
check(a.binding:find(a.face:match('/([^/.]+)%.'),1,true)~=nil,'binding matches face')
local seen={}
for i=1,200 do seen[M.pick(i).sex]=true end
check(seen.m and seen.f,'both sexes')
-- assembly: base attached to zombie mesh with retarget anim, parts follow base, mesh hidden
local comps={}
local function component(class)
    local c={class=class,IsValid=function() return true end}
    function c:K2_AttachToComponent(p) self.parent=p end
    function c:SetSkeletalMeshAsset(m) self.mesh=m end
    function c:K2_SetRelativeLocation(v) self.z=v.Z end
    function c:SetAnimInstanceClass(k) self.anim=k end
    function c:SetLeaderPoseComponent(l) self.leader=l end
    function c:SetOverlayMaterial(m) self.overlay=m end
    function c:SetBindingAsset(x) self.binding=x end
    function c:SetGroomAsset(x) self.groom=x end
    function c:SetEnableSimulation() end
    comps[#comps+1]=c
    return c
end
local mesh={IsValid=function() return true end,visible=true}
function mesh:SetVisibility(v) self.visible=v end
function mesh:IsVisible() return self.visible end
local z=obj('BP_NormalZombie_C 2147481234',{Mesh=mesh,AddComponentByClass=function(_,class) return component(class) end})
env.OutbreakCivilianLooks=nil
check(M.available()==true and env.OutbreakCivilianAvailable==true,'pak detected and remembered')
local desc=M.apply(z)
check(type(desc)=='string' and #comps==7,'base + 4 parts + face + hair')
local base=comps[1]
check(base.parent==mesh and base.z==M.FOOT_OFFSET and base.anim~=nil,'base attached, raised, retargeting')
for i=2,6 do check(comps[i].leader==base and comps[i].overlay~=nil,'part follows base with overlay') end
check(comps[7].groom~=nil and comps[7].parent==comps[6],'hair on face')
check(mesh.visible==false and mesh.VisibilityBasedAnimTickOption==0,'zombie mesh hidden but animating')
check(M.apply(z)=='already dressed' and #comps==7,'idempotent')
mesh.visible=true;M.maintain(z);check(mesh.visible==false,'maintain re-hides')
check(comps[2].overlay.params.ZombieTint~=nil,'skin tint set')
return count
