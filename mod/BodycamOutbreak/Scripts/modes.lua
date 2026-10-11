-- Identifies the running game mode. Shared by the session gate (probe.lua) and scoring rules.
local M={}
local function valid(o) return o and o:IsValid() end
local MODE_ASSETS={
    {'/Game/GM/DATA/DataAsset/DA_Hardpoint.DA_Hardpoint','Hardpoint'},
    {'/Game/GM/DATA/DataAsset/DA_GameModeTeamDeathmatch.DA_GameModeTeamDeathmatch','Team Deathmatch'},
    {'/Game/GM/DATA/DataAsset/DA_Versus.DA_Versus','Versus'},
}
-- Returns mode name (nil if unsupported) and the config asset name for diagnostics.
function M.detect(gm)
    if not valid(gm) then return nil end
    local zombie=StaticFindObject('/Game/GM/Zombie/Gamemode/GM_Zombie.GM_Zombie_C')
    if valid(zombie) and gm:IsA(zombie) then return 'Zombies' end
    local native=StaticFindObject('/Script/Bodycam.BodycamGameMode')
    local ok,config=pcall(function()
        if valid(native) and gm:IsA(native) and valid(gm.ConfigDataAsset) then return gm.ConfigDataAsset:GetFullName() end
    end)
    if not ok then config=nil end
    if config then
        for _,entry in ipairs(MODE_ASSETS) do
            local asset=StaticFindObject(entry[1])
            if valid(asset) and asset:GetFullName()==config then return entry[2],config end
        end
    end
    -- Gun Game's asset has not been seen in diagnostics yet; match it by name.
    if (config and config:lower():find('gungame',1,true)) or gm:GetFullName():lower():find('gungame',1,true) then
        return 'Gun Game',config
    end
    local dm=StaticFindObject('/Game/GM/Gamemode/GM_Deathmatch.GM_Deathmatch_C')
    if valid(dm) and gm:IsA(dm) then return 'Deathmatch',config end
    return nil,config
end
return M
