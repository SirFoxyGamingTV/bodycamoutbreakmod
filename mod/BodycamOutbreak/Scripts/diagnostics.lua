-- F8: run the mod's Lua self-tests and record the current session to ../diagnostics.txt.
-- Read-only: never spawns or changes anything. (Global UObject enumeration crashed UE4SS on
-- this game, so only targeted lookups are used.)
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local file=assert(io.open(dir..'/../diagnostics.txt','w'))
local function write(v) file:write(tostring(v),'\n');file:flush() end
local ok,err=pcall(function()
    write('BodycamOutbreak diagnostics '..os.date('!%Y-%m-%dT%H:%M:%SZ'))
    local modules={'main','controls','horde_controls','horde','horde_policy','targets','melee','ownership',
        'score_filter','modes','probe','session_gate','appearance','settings','panel'}
    for _,m in ipairs(modules) do assert(loadfile(dir..'/'..m..'.lua')) end
    write('SYNTAX_PASS '..#modules)
    for _,t in ipairs({'test_session_gate','test_horde_policy','test_targets','test_match_over'}) do
        write('TEST_PASS '..t..' '..tostring(dofile(dir..'/'..t..'.lua')))
    end
    for _,e in ipairs(FindAllOf('GameEngine') or {}) do
        if e:IsValid() and not e:GetFullName():find('Default__',1,true) and e.GameViewport:IsValid() and e.GameViewport.World:IsValid() then
            local world=e.GameViewport.World
            write('WORLD '..world:GetFullName())
            dofile(dir..'/probe.lua').capture(world,write)
            write('HORDE '..(_G.OutbreakHorde and ('running wave '..tostring(_G.OutbreakHorde.wave)) or 'stopped'))
            write('MATCH_OVER '..tostring(dofile(dir..'/horde.lua').matchOver(world)))
            break
        end
    end
    local s=dofile(dir..'/settings.lua').get()
    write(string.format('SETTINGS zombiesPerWave=%s damage=%s speed=%s',s.zombiesPerWave,s.damage,s.speed))
end)
if not ok then write('ERROR '..tostring(err)) end
file:close()
if not ok then error(err) end
