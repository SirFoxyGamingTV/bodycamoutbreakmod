-- Pure policy: unknown values never grant a gameplay write.
local M = {}
function M.check(s)
    if s.server ~= true then return false, 'host authority required: install Outbreak on the hosting PC; a joining client cannot spawn server zombies' end
    if s.standalone ~= false then return false, 'online session required' end
    if s.supportedMode ~= true then return false, 'supported mode required: Deathmatch, Team Deathmatch, Gun Game, Versus, Hardpoint or Zombies' end
    if type(s.publicLobby) ~= 'boolean' then return false, 'lobby visibility not verified' end
    if type(s.humanCount) ~= 'number' or s.humanCount < 1 or s.humanCount == math.huge
        or s.humanCount % 1 ~= 0 then return false, 'valid human player count required' end
    return true, s.publicLobby and 'public host session verified' or 'private host session verified'
end
return M

