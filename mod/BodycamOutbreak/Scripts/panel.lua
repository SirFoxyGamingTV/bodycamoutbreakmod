-- Outbreak host panel (F6). Shown in the UE4SS console; usable any time, including with the
-- pause menu open. Up/Down picks a row, Left/Right changes a value or runs an action.
-- Changes apply immediately (next spawn / next hit) and are saved to settings.txt.
local dir=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/'):match('^(.*)/[^/]+$')
local settings=dofile(dir..'/settings.lua')
local M={}
M.ROWS={}
for _,f in ipairs(settings.FIELDS) do M.ROWS[#M.ROWS+1]={kind='setting',key=f.key,label=f.label,unit=f.unit} end
M.ROWS[#M.ROWS+1]={kind='action',key='toggle',label='Start / stop zombie waves (F7)'}
M.ROWS[#M.ROWS+1]={kind='action',key='cleanup',label='Clean up all zombies (F10)'}

_G.OutbreakPanel=_G.OutbreakPanel or {open=false,row=1}
local state=_G.OutbreakPanel

function M.render()
    local s=settings.get()
    local running=_G.OutbreakHorde~=nil
    local out={'================ OUTBREAK SETTINGS (F6 to close) ================',
               'Horde: '..(running and ('RUNNING, wave '..tostring(_G.OutbreakHorde.wave)) or 'stopped')}
    for i,r in ipairs(M.ROWS) do
        local mark=(i==state.row) and '>>' or '  '
        if r.kind=='setting' then
            out[#out+1]=string.format('%s %-18s < %s >  %s',mark,r.label,tostring(s[r.key]),r.unit)
        else
            out[#out+1]=string.format('%s %s   (press Right)',mark,r.label)
        end
    end
    out[#out+1]='Up/Down: choose   Left/Right: change / run'
    return table.concat(out,'\n')
end

-- Pure input handling. Returns an action name ('toggle'/'cleanup') when one should run.
function M.handle(key)
    if key=='F6' then state.open=not state.open;return nil end
    if not state.open then return nil end
    local r=M.ROWS[state.row]
    if key=='Up' then state.row=(state.row-2)%#M.ROWS+1
    elseif key=='Down' then state.row=state.row%#M.ROWS+1
    elseif key=='Left' or key=='Right' then
        if r.kind=='setting' then settings.adjust(r.key,key=='Right' and 1 or -1)
        elseif key=='Right' then return r.key end
    end
    return nil
end

local function currentWorld()
    for _,e in ipairs(FindAllOf('GameEngine') or {}) do
        if e:IsValid() and not e:GetFullName():find('Default__',1,true) and e.GameViewport:IsValid() and e.GameViewport.World:IsValid() then
            return e.GameViewport.World
        end
    end
end
local function run(action)
    if action=='toggle' then
        local world=assert(currentWorld(),'game world not ready')
        dofile(dir..'/horde.lua').start(world) -- starts, or stops a running horde
    elseif action=='cleanup' then
        print('[Outbreak panel] '..dofile(dir..'/horde.lua').cleanup()..'\n')
    end
end

function M.install()
    if _G.OutbreakPanelInstalled then return end
    _G.OutbreakPanelInstalled=true
    local keys={F6=Key.F6,Up=Key.UP_ARROW,Down=Key.DOWN_ARROW,Left=Key.LEFT_ARROW,Right=Key.RIGHT_ARROW}
    for name,code in pairs(keys) do
        RegisterKeyBind(code,function()
            ExecuteInGameThread(function()
                local ok,err=pcall(function()
                    local p=dofile(dir..'/panel.lua') -- reload so edits apply without restarting
                    local wasOpen=_G.OutbreakPanel.open
                    local action=p.handle(name)
                    if action then run(action) end
                    if _G.OutbreakPanel.open then print('\n'..p.render()..'\n')
                    elseif wasOpen then print('[Outbreak panel] closed\n') end
                end)
                if not ok then print('[Outbreak panel] '..tostring(err)..'\n') end
            end)
        end)
    end
    print('[Outbreak panel] F6 opens the Outbreak settings panel\n')
end
return M
