-- Read-only, class-scoped inventory; never enumerate the global UObject array.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
return function(world)
    local file=assert(io.open(dir..'/../appearance-probe.txt','w'))
    local function write(v) file:write(tostring(v),'\n');file:flush() end
    local function valid(o) return o and o:IsValid() end
    local function name(o) return valid(o) and o:GetFullName() or '<none>' end
    local function inspect(label,fn)
        local ok,result=pcall(fn);write(label..' '..(ok and tostring(result) or ('ERROR '..tostring(result))))
    end
    local ok,err=pcall(function()
        write('APPEARANCE '..os.date('!%Y-%m-%dT%H:%M:%SZ')..' '..name(world))
        local seen={}
        inspect('FACIAL_MORPHS',function()
            local mesh=StaticFindObject('/Game/ZombiesPackV4/Zombie_Jocker/joker_CHEMISE_PANTALON.joker_CHEMISE_PANTALON')
            local count=mesh.MorphTargets:GetArrayNum()
            write('FACIAL_MORPH_COUNT '..count)
            mesh.MorphTargets:ForEach(function(_,e) write('FACIAL_MORPH '..name(e:get())) end)
            return 'done'
        end)
        for _,class in ipairs({'SkeletalMesh','StaticMesh','GroomAsset'}) do
            local count=0
            for _,asset in ipairs(FindAllOf(class) or {}) do
                if valid(asset) then
                    local n=asset:GetFullName():lower()
                    if n:find('%f[%a]hair') or n:find('beard') or n:find('%f[%a]head') or n:find('groom') then
                        count=count+1;write('HEAD_ASSET '..name(asset))
                    end
                end
            end
            write('HEAD_ASSET_COUNT '..class..' '..count)
        end
        for _,m in ipairs(FindAllOf('MaterialInstanceConstant') or {}) do
            if valid(m) and (m:GetFullName():lower():find('jock') or m:GetFullName():find('/Cloth/',1,true) or m:GetFullName():lower():find('hair')) then
                write('CANDIDATE '..name(m))
                inspect('VECTORS',function()
                    m.VectorParameterValues:ForEach(function(_,e)
                        local p=e:get();local v=p.ParameterValue
                        write(' VECTOR '..p.ParameterInfo.Name:ToString()..' '..v.R..','..v.G..','..v.B..','..v.A)
                    end)
                    return name(m.Parent)
                end)
            end
        end
        inspect('MESH_SLOTS',function()
            local mesh=StaticFindObject('/Game/ZombiesPackV4/Zombie_Jocker/joker_CHEMISE_PANTALON.joker_CHEMISE_PANTALON')
            mesh.Materials:ForEach(function(i,e) local p=e:get();write('ASSET_SLOT '..i..' '..p.MaterialSlotName:ToString()..' '..name(p.MaterialInterface)) end)
            return 'done'
        end)
        for _,z in ipairs(FindAllOf('BP_NormalZombie_C') or {}) do
            if valid(z) and valid(z.Mesh) and valid(z.Mesh.SkeletalMesh) and z.Mesh.SkeletalMesh:GetFullName():find('joker_CHEMISE_PANTALON',1,true) then
                for slot=0,z.Mesh:GetNumMaterials()-1 do
                    local m=z.Mesh:GetMaterial(slot)
                    write('SLOT '..slot..' '..name(m))
                    for level=1,5 do
                        if not valid(m) or seen[name(m)] then break end
                        seen[name(m)]=true
                        write('MATERIAL '..name(m))
                        for _,field in ipairs({'VectorParameterValues','ScalarParameterValues','TextureParameterValues'}) do
                            inspect(field,function()
                                m[field]:ForEach(function(_,e)
                                    local p=e:get()
                                    local n=p.ParameterInfo.Name:ToString()
                                    local v=p.ParameterValue
                                    if field=='VectorParameterValues' then
                                        write(' VECTOR '..n..' '..v.R..','..v.G..','..v.B..','..v.A)
                                    elseif field=='ScalarParameterValues' then write(' SCALAR '..n..' '..tostring(v))
                                    else write(' TEXTURE '..n..' '..name(v)) end
                                end)
                                return 'done'
                            end)
                        end
                        local yes,parent=pcall(function() return m.Parent end)
                        if not yes then break end
                        m=parent
                    end
                end
                break
            end
        end
        for _,mesh in ipairs(FindAllOf('SkeletalMesh') or {}) do
            if valid(mesh) then
                write('MESH '..name(mesh))
                inspect(' SKELETON',function() return name(mesh.Skeleton) end)
                inspect(' PHYSICS',function() return name(mesh.PhysicsAsset) end)
            end
        end
        for _,z in ipairs(FindAllOf('BP_NormalZombie_C') or {}) do
            if valid(z) then
                write('ZOMBIE '..name(z))
                inspect(' MESH',function() return name(z.Mesh.SkeletalMesh) end)
                inspect(' ANIM_CLASS',function() return name(z.Mesh.AnimClass) end)
                if not _G.OutbreakAppearanceMetadataRead and valid(z.Mesh) then
                    local cls=z.Mesh:GetClass()
                    for level=1,7 do
                        if not valid(cls) then break end
                        cls:ForEachFunction(function(fn)
                            local n=fn:GetFullName()
                            if n:find('SkeletalMesh') or n:find('Material') then
                                write('REFLECTED '..n)
                                fn:ForEachProperty(function(p) write(' PARAM '..p:GetFullName()) end)
                            end
                        end)
                        cls=cls:GetSuperStruct()
                    end
                    _G.OutbreakAppearanceMetadataRead=true
                end
            end
        end
        for _,path in ipairs({'/Script/Engine.SkeletalMeshComponent:SetSkeletalMesh','/Script/Engine.MeshComponent:SetMaterial','/Script/Engine.MeshComponent:GetNumMaterials','/Script/Engine.MeshComponent:GetMaterial'}) do
            local fn=StaticFindObject(path)
            write('API '..name(fn))
            if valid(fn) then fn:ForEachProperty(function(p) write(' PARAM '..p:GetFullName()) end) end
        end
    end)
    if not ok then write('ERROR '..tostring(err)) end
    file:close()
end


