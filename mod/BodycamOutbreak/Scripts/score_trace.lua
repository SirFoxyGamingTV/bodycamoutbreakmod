-- Read-only event tracing until the precise zombie award path is verified.
if _G.OutbreakScoreTrace then return end
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local path='/Script/Bodycam.BodycamGameMode:NotifyPlayerKilled'
if not StaticFindObject(path):IsValid() then return end
local function describe(controller)
    if not controller or not controller:IsValid() then return '<none>' end
    local result=controller:GetFullName()
    if controller.Pawn:IsValid() then result=result..' pawn='..controller.Pawn:GetFullName() end
    local ps=controller.PlayerState
    if ps:IsValid() then result=result..' kills='..tostring(ps.Kill)..' score='..tostring(ps.Score) end
    return result
end
local function record(phase,instigator,victim)
    local ok,message=pcall(function() return phase..' killer='..describe(instigator:get())..' victim='..describe(victim:get()) end)
    local f=io.open(dir..'/../score-events.log','a')
    if f then f:write(os.date('!%Y-%m-%dT%H:%M:%SZ'),' ',ok and message or ('ERROR '..tostring(message)),'\n');f:close() end
end
local pre,post=RegisterHook(path,function(context,i,v) record('PRE',i,v) end,function(context,i,v) record('POST',i,v) end)
_G.OutbreakScoreTrace={pre=pre,post=post}
