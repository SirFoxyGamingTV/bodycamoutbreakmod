if _G.OutbreakTimerTestStarted then return end
_G.OutbreakTimerTestStarted=true
local source=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/')
local scripts=assert(source:match('^(.*)/[^/]+$'))
local ticks=0
local handle
handle=LoopInGameThreadWithDelay(100,function()
    ticks=ticks+1
    if ticks==3 then CancelDelayedAction(handle) end
end)
ExecuteInGameThreadWithDelay(1200,function()
    local active=IsDelayedActionActive(handle)
    local f=assert(io.open(scripts..'/../timer-test.txt','w'))
    f:write((ticks==3 and not active) and 'PASS' or 'FAIL',
        ' ticks=',tostring(ticks),' active=',tostring(active),'\n')
    f:close()
end)
