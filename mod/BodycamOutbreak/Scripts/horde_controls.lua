if _G.OutbreakHordeControlsInstalled then return end
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
RegisterKeyBind(Key.F7,function()
    ExecuteInGameThread(function()
        local ok,err=pcall(function()
            for _,e in ipairs(FindAllOf('GameEngine') or {}) do
                if e:IsValid() and not e:GetFullName():find('Default__',1,true) and e.GameViewport:IsValid() and e.GameViewport.World:IsValid() then
                    dofile(dir..'/horde.lua').start(e.GameViewport.World);return
                end
            end
        end)
        if not ok then print('[Outbreak horde] '..tostring(err)..'\n') end
    end)
end)
_G.OutbreakHordeControlsInstalled=true
