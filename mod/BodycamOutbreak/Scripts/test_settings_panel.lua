-- settings.lua + panel.lua: parsing, clamping, damage rules, keyboard navigation.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local count=0
local function check(c,m) assert(c,m);count=count+1 end
local files={}
local env=setmetatable({},{__index=_G}); env._G=env
env.print=function() end
env.io={open=function(path,mode)
    if mode=='r' then if not files[path] then return nil end
        return {read=function() return files[path] end,close=function() end} end
    local buf={}
    return {write=function(_,t) buf[#buf+1]=t end,close=function() files[path]=table.concat(buf) end}
end}
env.dofile=function(path) return assert(loadfile(path,'t',env))() end
local S=env.dofile(dir..'/settings.lua')
-- parsing and clamping
local p=S.parse('zombiesPerWave=35\ndamage=250\nspeed=abc\nbogus=1\n')
check(p.zombiesPerWave==35 and p.damage==100 and p.speed==420,'parse clamps and defaults')
check(S.parse('').zombiesPerWave==20,'defaults')
check(S.parse('zombiesPerWave=1').zombiesPerWave==5,'min clamp')
-- live settings, adjust and persistence
local s=S.get()
check(s.zombiesPerWave==20 and s.damage==100,'fresh defaults')
check(S.adjust('zombiesPerWave',2)==30,'adjust up')
check(S.adjust('damage',-3)==70,'adjust down')
check(files[S.FILE]:find('zombiesPerWave=30',1,true) and files[S.FILE]:find('damage=70',1,true),'saved')
env.OutbreakSettings=nil
check(S.get().zombiesPerWave==30,'reloaded from file')
-- damage rules
check(S.hitDamage(100)==70 and S.nativeDamage()==70,'partial damage')
S.adjust('damage',10)
check(S.hitDamage(100)>=10000 and S.nativeDamage()==10000,'100% is a one-hit kill')
-- panel navigation
env.OutbreakPanel=nil
local P=env.dofile(dir..'/panel.lua')
check(P.handle('Down')==nil and env.OutbreakPanel.row==1,'keys ignored while closed')
P.handle('F6');check(env.OutbreakPanel.open,'F6 opens')
P.handle('Right');check(S.get().zombiesPerWave==35,'right raises zombies per wave')
P.handle('Down');P.handle('Left');check(S.get().damage==90,'left lowers damage')
P.handle('Up');P.handle('Up');check(env.OutbreakPanel.row==#P.ROWS,'wraps to bottom')
check(P.handle('Right')=='cleanup','cleanup action')
P.handle('Up');check(P.handle('Right')=='toggle' and P.handle('Left')==nil,'toggle action, left does nothing')
check(P.render():find('Zombies per wave',1,true) and P.render():find('>>',1,true),'renders')
P.handle('F6');check(not env.OutbreakPanel.open,'F6 closes')
return count
