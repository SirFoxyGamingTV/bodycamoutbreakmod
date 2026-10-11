-- Key bindings: F7 toggles zombie waves (horde_controls.lua), F10 removes all mod zombies.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
dofile(dir..'/horde_controls.lua')
if _G.OutbreakControlsInstalled then return end
RegisterKeyBind(Key.F10,function()
    ExecuteInGameThread(function()
        local ok,result=pcall(function() return dofile(dir..'/horde.lua').cleanup() end)
        print('[Outbreak] F10: '..tostring(result)..'\n')
    end)
end)
_G.OutbreakControlsInstalled=true
