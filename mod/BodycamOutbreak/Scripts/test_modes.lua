-- Mode recognition in probe.lua with mocked engine objects.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local function obj(name,extra)
    local o={IsValid=function() return true end,GetFullName=function() return name end}
    for k,v in pairs(extra or {}) do o[k]=v end
    return o
end
local missing={IsValid=function() return false end}
local n=0
local function detect(gmName,configName,classes)
    local env=setmetatable({},{__index=_G})
    env._G=env
    env.dofile=function(path)
        return assert(loadfile(path,'t',env))()
    end
    local assets={
        ['/Game/GM/DATA/DataAsset/DA_Hardpoint.DA_Hardpoint']=obj('GameModeConfigDataAsset DA_Hardpoint'),
        ['/Game/GM/DATA/DataAsset/DA_GameModeTeamDeathmatch.DA_GameModeTeamDeathmatch']=obj('GameModeConfigDataAsset DA_GameModeTeamDeathmatch'),
        ['/Game/GM/DATA/DataAsset/DA_Versus.DA_Versus']=obj('GameModeConfigDataAsset DA_Versus'),
    }
    env.StaticFindObject=function(path)
        if assets[path] then return assets[path] end
        if path:find('GameplayStatics',1,true) then return {GetPlayerController=function() return missing end} end
        if path:find('KismetSystemLibrary',1,true) then return {IsServer=function() return true end,IsStandalone=function() return false end} end
        return obj(path)
    end
    env.FindAllOf=function() return {} end
    local gm=obj(gmName,{
        IsA=function(_,cls) local p=cls:GetFullName();return classes[p]==true end,
        ConfigDataAsset=configName and obj(configName) or missing,
        IsPublicLobby=function() return false end,
        GetRealPlayersCount=function(_,out) out.PlayerCount=2 end})
    local world=obj('World test',{AuthorityGameMode=gm,GameState={PlayerArray={GetArrayNum=function() return 2 end}}})
    local probe=env.dofile(dir..'/probe.lua')
    local s=probe.capture(world,function() end)
    return s
end
local native='/Script/Bodycam.BodycamGameMode'
local dm='/Game/GM/Gamemode/GM_Deathmatch.GM_Deathmatch_C'
local function expect(mode,allowed,...)
    local s=detect(...)
    assert(s.modeName==mode,'expected '..tostring(mode)..' got '..tostring(s.modeName))
    assert(s.supportedMode==allowed);n=n+1
end
expect('Team Deathmatch',true,'GM_TDM','GameModeConfigDataAsset DA_GameModeTeamDeathmatch',{[native]=true})
expect('Versus',true,'GM_Versus','GameModeConfigDataAsset DA_Versus',{[native]=true})
expect('Hardpoint',true,'GM_HP','GameModeConfigDataAsset DA_Hardpoint',{[native]=true})
expect('Gun Game',true,'GM_GunGame_C_1','GameModeConfigDataAsset DA_Other',{[native]=true})
expect('Gun Game',true,'GM_X','GameModeConfigDataAsset DA_GunGame',{[native]=true})
expect('Deathmatch',true,'GM_Deathmatch_C_1','GameModeConfigDataAsset DA_GameModeDeathmatch',{[native]=true,[dm]=true})
expect(nil,false,'GM_Wingman','GameModeConfigDataAsset DA_Wingman',{[native]=true})
expect(nil,false,'GM_Lobby',nil,{})
return n
