-- Never dereference an old actor to check whether travel happened.
local source=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/')
local scripts=assert(source:match('^(.*)/[^/]+$'))
return function(world,write)
    local path=scripts..'/../session-world.txt'
    local previous
    local input=io.open(path,'r')
    if input then previous=input:read('*l'); input:close() end
    local current=world:GetFullName()
    if previous and previous~=current then
        _G.OutbreakOwnedZombie=nil
        write('WORLD_CHANGED '..previous..' -> '..current..'; owned reference cleared')
    end
    if previous~=current then
        local out=assert(io.open(path,'w')); out:write(current,'\n'); out:close()
    end
end
