local source = debug.getinfo(1, 'S').source:gsub('^@', ''):gsub('\\', '/')
local scripts = assert(source:match('^(.*)/[^/]+$'))
local gate = dofile(scripts .. '/session_gate.lua')
local base = {server=true, standalone=false, supportedMode=true, publicLobby=false, humanCount=1}
assert(gate.check(base))
local cases = {
    {'server', false}, {'standalone', true}, {'supportedMode', false},
    {'publicLobby', 'true'}, {'humanCount', 0}, {'humanCount', -1},
    {'humanCount', 1.5}, {'humanCount', '2'}, {'humanCount', math.huge}, {'humanCount', 0/0},
}
local n = 1
for _, case in ipairs(cases) do
    local s = {}; for k,v in pairs(base) do s[k]=v end
    s[case[1]]=case[2]
    assert(not gate.check(s), 'incorrectly allowed ' .. case[1]); n=n+1
end
for key in pairs(base) do
    local s = {}; for k,v in pairs(base) do s[k]=v end
    s[key]=nil; assert(not gate.check(s), 'allowed unknown ' .. key); n=n+1
end
for _,public in ipairs({false,true}) do
    for _,players in ipairs({1,2,8}) do
        local s={server=true,standalone=false,supportedMode=true,publicLobby=public,humanCount=players}
        assert(gate.check(s),'rejected supported host lobby');n=n+1
        s.server=false
        assert(not gate.check(s),'allowed client spawning');n=n+1
    end
end
return n

