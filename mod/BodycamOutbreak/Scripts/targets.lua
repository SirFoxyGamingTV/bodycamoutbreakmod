local M={}
local function valid(o) return o and o:IsValid() end
function M.collect(world)
    local result,seen={},{}
    for _,class in ipairs({'Bodycam_Player_C','AI_Humanoid_C'}) do
        for _,a in ipairs(FindAllOf(class) or {}) do
            if valid(a) and not a:GetFullName():find('Default__',1,true) and not a:IsActorBeingDestroyed()
                and valid(a.RootComponent) and valid(a:GetWorld()) and a:GetWorld():GetFullName()==world:GetFullName()
                and a:IsCharacterAlive() and not seen[a:GetFullName()] then
                seen[a:GetFullName()]=true
                result[#result+1]={actor=a,position=a:K2_GetActorLocation(),name=a:GetFullName()}
            end
        end
    end
    return result
end
function M.nearest(origin,candidates)
    local best,distance
    for _,candidate in ipairs(candidates) do
        local p=candidate.position
        local d=(p.X-origin.X)^2+(p.Y-origin.Y)^2+(p.Z-origin.Z)^2
        if not distance or d<distance then best=candidate;distance=d end
    end
    return best
end
return M
