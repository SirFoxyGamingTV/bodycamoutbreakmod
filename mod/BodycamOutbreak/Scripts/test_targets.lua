local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local t=dofile(dir..'/targets.lua')
local origin={X=0,Y=0,Z=0}
assert(t.nearest(origin,{})==nil)
local human={position={X=100,Y=0,Z=0},name='remote player'}
local bot={position={X=10,Y=0,Z=0},name='soldier'}
assert(t.nearest(origin,{human,bot})==bot)
assert(t.nearest({X=95,Y=0,Z=0},{human,bot})==human)
assert(t.nearest(origin,{human})==human)
return 4
