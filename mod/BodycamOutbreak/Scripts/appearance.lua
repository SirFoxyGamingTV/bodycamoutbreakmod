-- Native clothed infected prototype. No external assets or shared defaults changed.
local M={}
local path='/Game/ZombiesPackV4/Zombie_Jocker/joker_CHEMISE_PANTALON.joker_CHEMISE_PANTALON'
local function valid(o) return o and o:IsValid() end
local palettes={
    {name='original',skin={0.14,0.14,0.14}},
    {name='blue-charcoal',shirt={0.16,0.29,0.46},trousers={0.11,0.12,0.14},skin={0.17,0.15,0.14}},
    {name='rust-olive',shirt={0.43,0.19,0.12},trousers={0.18,0.22,0.12},skin={0.13,0.15,0.12}},
}
function M.install()
    _G.OutbreakAppearanceApply=M.apply
    if _G.OutbreakAppearanceTimer then return end
    _G.OutbreakAppearanceTimer=LoopInGameThreadWithDelay(1000,function()
        local current
        for _,e in ipairs(FindAllOf('GameEngine') or {}) do
            if valid(e) and not e:GetFullName():find('Default__',1,true) and valid(e.GameViewport) then
                current=e.GameViewport.World;break
            end
        end
        local s=_G.OutbreakHorde
        if not s or not valid(current) or current:GetFullName()~=s.worldName then
            CancelDelayedAction(_G.OutbreakAppearanceTimer)
            _G.OutbreakAppearanceTimer=nil
            return
        end
        for _,z in ipairs(s.actors) do
            local ok,err=pcall(function()
                if valid(z) and not z:IsActorBeingDestroyed() and z:IsCharacterAlive() and valid(z.Mesh)
                    and valid(z.Mesh.SkeletalMesh) and z.Mesh.SkeletalMesh:GetFullName()~='SkeletalMesh '..path then
                    _G.OutbreakAppearanceApply(z)
                end
            end)
            if not ok then
                print('[Outbreak appearance] monitor stopped: '..tostring(err)..'\n')
                CancelDelayedAction(_G.OutbreakAppearanceTimer);_G.OutbreakAppearanceTimer=nil
                return
            end
        end
    end)
end
function M.apply(z)
    assert(valid(z) and not z:IsActorBeingDestroyed() and z:IsCharacterAlive(),'living zombie required')
    local c=z.Mesh
    local replacement=StaticFindObject(path)
    assert(valid(c) and valid(replacement),'clothed infected asset unavailable')
    local old=c.SkeletalMesh
    assert(valid(old) and valid(old.Skeleton) and valid(replacement.Skeleton),'skeleton unavailable')
    assert(old.Skeleton:GetFullName()==replacement.Skeleton:GetFullName(),'incompatible skeleton')
    local materials={}
    local variant=palettes[(tonumber(z:GetFullName():match('(%d+)$')) or 0)%#palettes+1]
    local count=c:GetNumMaterials()
    for i=0,count-1 do materials[i]=c:GetMaterial(i) end
    local ok,err=pcall(function()
        c:SetSkeletalMeshAsset(replacement)
        for i=0,math.max(count,c:GetNumMaterials())-1 do c:SetMaterial(i,nil) end
        assert(c.SkeletalMesh:GetFullName()==replacement:GetFullName(),'mesh assignment failed')
        -- Slots and SkinTone parameter verified from this cooked mesh/material.
        for _,entry in ipairs({{slot=0,color=variant.skin},{slot=1,color=variant.trousers},{slot=2,color=variant.shirt}}) do
            if entry.color then
                local mid=c:CreateDynamicMaterialInstance(entry.slot,c:GetMaterial(entry.slot),FName('None'))
                assert(valid(mid),'dynamic material creation failed')
                local rgb=entry.color
                mid:SetVectorParameterValue(FName('SkinTone'),{R=rgb[1],G=rgb[2],B=rgb[3],A=1})
            end
        end
    end)
    if not ok then
        c:SetSkeletalMeshAsset(old)
        for i=0,count-1 do c:SetMaterial(i,materials[i]) end
        error(err)
    end
    print('[Outbreak appearance] APPLIED '..z:GetFullName()..' '..replacement:GetFullName()..' variant='..variant.name..'\n')
    M.install()
end
return M
