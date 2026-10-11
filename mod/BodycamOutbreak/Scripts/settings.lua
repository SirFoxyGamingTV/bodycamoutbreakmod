-- Outbreak host settings: zombies per wave, damage per hit, zombie speed.
-- Kept in memory (_G.OutbreakSettings) so changes apply immediately, and saved to
-- ../settings.txt so they survive restarts. Pure Lua apart from file access.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local M={}
M.FILE=dir..'/../settings.txt'
-- key, label, default, min, max, step, unit
M.FIELDS={
    {key='zombiesPerWave',label='Zombies per wave',default=20,min=5,max=60,step=5,unit=''},
    {key='damage',label='Damage per hit',default=100,min=10,max=100,step=10,unit='% of health (100 = one-hit kill)'},
    {key='speed',label='Zombie speed',default=420,min=150,max=700,step=30,unit=''},
}
local function field(key) for _,f in ipairs(M.FIELDS) do if f.key==key then return f end end end
local function clamp(f,v)
    v=math.floor(tonumber(v) or f.default)
    if v<f.min then v=f.min elseif v>f.max then v=f.max end
    return v
end
function M.defaults()
    local s={}
    for _,f in ipairs(M.FIELDS) do s[f.key]=f.default end
    return s
end
-- Parse "key=value" lines; unknown keys ignored, bad values clamped/defaulted.
function M.parse(text)
    local s=M.defaults()
    for k,v in (text or ''):gmatch('([%w_]+)%s*=%s*([^\r\n]+)') do
        local f=field(k)
        if f then s[k]=clamp(f,v) end
    end
    return s
end
function M.serialize(s)
    local lines={}
    for _,f in ipairs(M.FIELDS) do lines[#lines+1]=f.key..'='..tostring(s[f.key]) end
    return table.concat(lines,'\n')..'\n'
end
function M.get()
    if not _G.OutbreakSettings then
        local ok,text=pcall(function()
            local f=io.open(M.FILE,'r')
            if not f then return '' end
            local t=f:read('*a');f:close()
            return t
        end)
        _G.OutbreakSettings=M.parse(ok and text or '')
    end
    return _G.OutbreakSettings
end
function M.save()
    local ok=pcall(function()
        local f=assert(io.open(M.FILE,'w'))
        f:write(M.serialize(M.get()));f:close()
    end)
    return ok
end
-- Change one setting by n steps; returns the new value.
function M.adjust(key,steps)
    local f=assert(field(key),'unknown setting '..tostring(key))
    local s=M.get()
    s[key]=clamp(f,s[key]+steps*f.step)
    M.save()
    return s[key]
end
-- Melee damage for a target with `health`: one-hit kill at 100%, otherwise a share of 100 HP.
function M.hitDamage(health)
    local pct=M.get().damage
    if pct>=100 then return math.max(10000,health*2) end
    return pct
end
-- Value for the zombie's native AttackDamage property.
function M.nativeDamage()
    local pct=M.get().damage
    return pct>=100 and 10000 or pct
end
return M
