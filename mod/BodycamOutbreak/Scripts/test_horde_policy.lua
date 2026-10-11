local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local p=dofile(dir..'/horde_policy.lua')
local s={remaining=20,failures=0,wave=1}
assert(p.step(s,20)=='wait')
assert(p.step(s,19)=='spawn')
assert(p.step(s,5)=='spawn' and s.wave==1)
s.remaining=0
assert(p.step(s,6)=='wait')
assert(p.step(s,5)=='wave' and s.remaining==15 and s.wave==2)
s.remaining=0
assert(p.step(s,0)=='wave' and s.remaining==20)
s.remaining=0
assert(p.step(s,4)=='wave' and s.remaining==16)
s.failures=10
assert(p.step(s,0)=='stop')
return 8
