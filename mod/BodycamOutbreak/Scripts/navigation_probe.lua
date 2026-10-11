-- Read-only validation of the engine navigation query on the active map.
return function(world,write)
    local path='/Script/NavigationSystem.NavigationSystemV1:K2_GetRandomReachablePointInRadius'
    local fn=StaticFindObject(path)
    if not fn:IsValid() then write('NAV unavailable'); return end
    local gs=StaticFindObject('/Script/Engine.Default__GameplayStatics')
    local pc=gs:GetPlayerController(world,0)
    if not pc:IsValid() or not pc.Pawn:IsValid() then return end
    local nav=StaticFindObject('/Script/NavigationSystem.Default__NavigationSystemV1')
    local p=pc.Pawn:K2_GetActorLocation()
    local out={}
    local ok,err=pcall(function()
        local found=nav:K2_GetRandomReachablePointInRadius(world,{X=p.X,Y=p.Y,Z=p.Z},out,1200,nil,nil)
        write('NAV found='..tostring(found))
        for k,v in pairs(out) do write('NAV_OUT '..tostring(k)..'='..tostring(v)) end
    end)
    if not ok then write('NAV_ERROR '..tostring(err)) end
end
