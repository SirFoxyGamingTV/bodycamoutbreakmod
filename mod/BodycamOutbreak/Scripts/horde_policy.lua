local M={cap=20,waveSize=20,trigger=5,maxPlacementFailures=10,speed=420,attackDamage=10000}
function M.step(s,alive)
    if s.failures>=M.maxPlacementFailures then return 'stop' end
    if s.remaining>0 then return alive<M.cap and 'spawn' or 'wait' end
    if alive>M.trigger then return 'wait' end
    s.wave=s.wave+1
    s.remaining=M.cap-alive
    return 'wave'
end
return M
