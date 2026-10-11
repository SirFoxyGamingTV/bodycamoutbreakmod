-- Is this pawn one of the zombies spawned by the current horde?
local M={}
function M.contains(pawn)
    if not pawn or not pawn:IsValid() then return false end
    local h=_G.OutbreakHorde
    if not h then return false end
    local name=pawn:GetFullName()
    for _,a in ipairs(h.actors) do if a:IsValid() and a:GetFullName()==name then return true end end
    return false
end
return M
