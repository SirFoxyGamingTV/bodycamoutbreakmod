-- horde.lua: matchOver() reads GameState:IsMatchOver() and treats errors/unknown as "not over".
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local env=setmetatable({},{__index=_G}); env._G=env
env.dofile=function(path) return assert(loadfile(path,'t',env))() end
local M=env.dofile(dir..'/horde.lua')
local n=0
local function check(c,m) assert(c,m);n=n+1 end
local function world(v) return {GameState={IsMatchOver=function() return v end}} end
check(M.matchOver(world(true))==true,'over')
check(M.matchOver(world(false))==false,'running')
check(M.matchOver({GameState={}})==false,'function missing')
check(M.matchOver({})==false,'no game state')
check(M.matchOver(world(nil))==false,'unknown')
return n
