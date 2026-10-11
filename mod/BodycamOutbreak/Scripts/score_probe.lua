return function(world,write)
    local gs=StaticFindObject('/Script/Engine.Default__GameplayStatics')
    local pc=gs:GetPlayerController(world,0)
    local objects={world.AuthorityGameMode}
    local rule=StaticFindObject('/Script/Bodycam.BodycamScoreLimitRuleComponent')
    if rule:IsValid() then objects[#objects+1]=rule:GetCDO() end
    if pc:IsValid() and pc.PlayerState:IsValid() then objects[#objects+1]=pc.PlayerState end
    local function interesting(name) return name:lower():find('kill') or name:lower():find('score') or name:lower():find('death') end
    for _,o in ipairs(objects) do
        if o:IsValid() then
            local cls=o:GetClass()
            for level=1,5 do
                if not cls:IsValid() then break end
                cls:ForEachProperty(function(p)
                    local name=p:GetFullName()
                    if interesting(name) then write('SCORE_PROPERTY '..name) end
                end)
                cls:ForEachFunction(function(f)
                    if interesting(f:GetFullName()) then
                        write('SCORE_FUNCTION '..f:GetFullName())
                        f:ForEachProperty(function(p) write('SCORE_PARAM '..p:GetFullName()) end)
                    end
                end)
                cls=cls:GetSuperStruct()
            end
        end
    end
end
