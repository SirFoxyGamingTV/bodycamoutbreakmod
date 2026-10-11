-- Bounded read-only sampling. No gameplay mutation.
local source=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/')
local scripts=assert(source:match('^(.*)/[^/]+$'))
return function(world)
    if _G.OutbreakMonitorRunning then return end
    _G.OutbreakMonitorRunning=true
    local expectedWorld=world:GetFullName()
    local left=120
    local stopped=false
    local handle
    handle=LoopInGameThreadWithDelay(500,function()
        if left<=0 or stopped then CancelDelayedAction(handle); return end
            local file=assert(io.open(scripts..'/../combat-telemetry.txt','a'))
            file:write('TIME ',os.date('!%Y-%m-%dT%H:%M:%SZ'),'\n')
            local ok,err=pcall(function()
                local current
                for _,e in ipairs(FindAllOf('GameEngine') or {}) do
                    if e:IsValid() and not e:GetFullName():find('Default__',1,true) and e.GameViewport:IsValid() then
                        current=e.GameViewport.World
                    end
                end
                if not current or not current:IsValid() or current:GetFullName()~=expectedWorld then
                    file:write('WORLD_CHANGED monitoring stopped\n')
                    _G.OutbreakOwnedZombie=nil
                    stopped=true
                else
                    dofile(scripts..'/probe.lua').capture(current,function(v) file:write(v,'\n') end)
                end
            end)
            if not ok then file:write('ERROR ',tostring(err),'\n') end
            file:close()
        left=left-1
        if left<=0 or stopped then _G.OutbreakMonitorRunning=false; CancelDelayedAction(handle) end
    end)
end
