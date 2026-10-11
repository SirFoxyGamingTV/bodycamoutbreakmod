local source = debug.getinfo(1, 'S').source:gsub('^@', ''):gsub('\\', '/')
local scripts = assert(source:match('^(.*)/[^/]+$'))
local output = assert(io.open(scripts .. '/../diagnostics.txt', 'w'))
local function line(s) output:write(tostring(s), '\n') end
local function valid(o) return o and o:IsValid() end
local function fieldName(p)
    local ok, name = pcall(function() return p:GetFullName() end)
    if ok then return name end
    ok, name = pcall(function() return p:GetFName():ToString() end)
    return ok and name or '<unreadable property>'
end
local function describe(o)
    local cls = o:GetClass()
    line('OBJECT ' .. o:GetFullName())
    for level = 1, 5 do
        if not valid(cls) then break end
        line('CLASS ' .. cls:GetFullName())
        local n = 0
        cls:ForEachProperty(function(p)
            n = n + 1
            line('  PROPERTY ' .. fieldName(p))
            if n >= 200 then return true end
        end)
        n = 0
        cls:ForEachFunction(function(f)
            n = n + 1
            line('  FUNCTION ' .. f:GetFullName())
            f:ForEachProperty(function(p) line('    PARAM ' .. fieldName(p)) end)
            if n >= 200 then return true end
        end)
        cls = cls:GetSuperStruct()
    end
end
local ok, err = pcall(function()
    line('BodycamOutbreak read-only snapshot UTC ' .. os.date('!%Y-%m-%dT%H:%M:%SZ'))
    line('LUA_GATE_TESTS_PASS ' .. dofile(scripts .. '/test_session_gate.lua'))
    local count = 0
    ForEachUObject(function(o)
        if not valid(o) then return end
        local name = o:GetFullName()
        local lower = name:lower()
        if count < 12000 and (lower:find('zomb',1,true) or lower:find('infect',1,true)
            or lower:find('gm_',1,true) or lower:find('ai_humanoid',1,true)
            or lower:find('session',1,true) or lower:find('publiclobby',1,true) or lower:find('tablet',1,true) or lower:find('inputaction',1,true) or lower:find('gamemodeconfig',1,true)) then
            line('FOUND ' .. name)
            count = count + 1
        end
    end)
    for _, path in ipairs({
        '/Game/BodycamZombies/ZombieAI/BP_NormalZombie.BP_NormalZombie_C',
        '/Game/BodycamZombies/ZombieAI/Zombie.Zombie_C',
        '/Game/BodycamZombies/ZombieAI/AIC_Zombie.AIC_Zombie_C',
        '/Game/GM/Zombie/Gamemode/SpawnSystem/BP_ZombieSpawner.BP_ZombieSpawner_C',
        '/Game/GM/Zombie/Gamemode/GM_Zombie.GM_Zombie_C'
    }) do
        local cls = StaticFindObject(path)
        if valid(cls) then describe(cls:GetCDO()) end
    end
    local zc = StaticFindObject('/Game/BodycamZombies/ZombieAI/BP_NormalZombie.BP_NormalZombie_C')
    if valid(zc) then
        local z = zc:GetCDO()
        for _, key in ipairs({'PDA_Zombie','AIControllerClass','AutoPossessAI','Speed','AttackDamage','DistanceAttack','ExpectedHealth','IdleUntilPerception','ShouldCommunicateDeath','Mesh'}) do
            local yes, value=pcall(function() return z[key] end)
            if yes then
                local named, text=pcall(function() return value:GetFullName() end)
                line('ZDEFAULT ' .. key .. '=' .. (named and text or tostring(value)))
            end
        end
    end
    local pda=StaticFindObject('/Game/GM/Zombie/Gamemode/PDA/cemeteryZombies.cemeteryZombies')
    if valid(pda) then describe(pda) end
    for _, imc in ipairs(FindAllOf('InputMappingContext') or {}) do
        if valid(imc) then
            line('INPUTCONTEXT ' .. imc:GetFullName())
            local success, why = pcall(function()
                imc.Mappings:ForEach(function(index, item)
                    local mapping = item:get()
                    line('  MAPPING ' .. mapping.Action:GetFullName() .. ' KEY ' .. mapping.Key.KeyName:ToString())
                end)
            end)
            if not success then line('MAPPING ERROR ' .. tostring(why)) end
        end
    end
    for _, e in ipairs(FindAllOf('GameEngine') or {}) do
        if valid(e) and not e:GetFullName():find('Default__',1,true) then
            local viewport = e.GameViewport
            if valid(viewport) then
                local world = viewport.World
                if valid(world) then
                    line('WORLD ' .. world:GetFullName())
                    dofile(scripts .. '/probe.lua').capture(world, line)
                    dofile(scripts .. '/experiment.lua')(world, line)
                    local k = StaticFindObject('/Script/Engine.Default__KismetSystemLibrary')
                    if valid(k) then
                        line('SERVER ' .. tostring(k:IsServer(world)))
                        line('STANDALONE ' .. tostring(k:IsStandalone(world)))
                    end
                    if valid(world.AuthorityGameMode) then
                        describe(world.AuthorityGameMode)
    
                    end
                    if valid(world.GameState) then describe(world.GameState) end
                    local gs = StaticFindObject('/Script/Engine.Default__GameplayStatics')
                    local gi = gs:GetGameInstance(world)
                    if valid(gi) then describe(gi) end
                    local pc = gs:GetPlayerController(world, 0)
                    if valid(pc) then
                        describe(pc)
                        if valid(pc.Pawn) then describe(pc.Pawn) end
                    end
                end
            end
        end
    end
end)
if not ok then line('ERROR ' .. tostring(err)) end
output:close()
if not ok then error(err) end








