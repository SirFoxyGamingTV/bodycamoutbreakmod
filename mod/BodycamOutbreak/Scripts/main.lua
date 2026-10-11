-- Bodycam Outbreak: host-controlled zombie waves for Bodycam multiplayer (UE4SS Lua mod).
-- Nothing spawns automatically; the host starts waves with F7 or the F6 panel.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local busy=false
RegisterKeyBind(Key.F8,function()
    if busy then return end
    busy=true
    ExecuteInGameThread(function()
        local ok,err=pcall(function() dofile(dir..'/diagnostics.lua') end)
        print('[Outbreak] diagnostics '..(ok and 'written to diagnostics.txt' or tostring(err))..'\n')
        busy=false
    end)
end)
dofile(dir..'/controls.lua')
dofile(dir..'/panel.lua').install()
print('[Outbreak] Bodycam Outbreak loaded: F6 settings, F7 zombie waves, F10 clean up, F8 diagnostics\n')
