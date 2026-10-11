# Development

## Layout

```
mod/BodycamOutbreak/Scripts/   UE4SS Lua mod (copied to ue4ss/Mods/BodycamOutbreak)
  main.lua            entry point: key bindings, F8 diagnostics
  controls.lua        F10 cleanup (+ loads horde_controls.lua for F7)
  panel.lua           F6 settings panel (console UI, arrow-key input)
  settings.lua        persisted settings (settings.txt) and damage rules
  horde.lua           wave loop: spawning, targeting, corpse cleanup, match-over cleanup
  horde_policy.lua    pure wave/cap logic
  targets.lua         nearest living player/bot
  melee.lua           host-side zombie hit -> point damage
  score_filter.lua    per-mode scoring around BodycamGameMode:NotifyPlayerKilled
  modes.lua           game-mode detection (config data assets)
  session_gate.lua    pure "may we spawn here?" policy (host, online, supported mode)
  probe.lua           session snapshot used by the gate and diagnostics
  appearance.lua      clothed infected look + colour variants
  ownership.lua       is this pawn one of our zombies?
  diagnostics.lua     F8 report -> diagnostics.txt
  test_*.lua          Lua unit tests with a mocked Unreal API
scripts/
  Test-Lua.py           run all Lua tests (pip install lupa)
  Test-Workspace.ps1    static checks
  Deploy-Mod.ps1        copy the mod into the game (game closed), with backups
  Inspect-Environment.ps1 verify the installed game build matches config/compatibility.json
  Build-HostPackage.ps1 build artifacts/BodycamOutbreak-Host.zip
  Install-Host.ps1      installer shipped inside the ZIP
config/compatibility.json  tested Steam build, exe fingerprint, UE4SS version
```

## Tests

```powershell
pip install lupa
python scripts/Test-Lua.py
./scripts/Test-Workspace.ps1
```

The Lua tests run the real mod code against mocks of the Unreal objects they touch. They cannot
test the game itself; check gameplay changes in a hosted match.

## Deploying while developing

With Bodycam closed:

```powershell
./scripts/Deploy-Mod.ps1
```

It copies `mod/BodycamOutbreak` into the game's `ue4ss/Mods`, backs up replaced files under
`artifacts/backups`, and removes scripts that no longer exist in the repo.

Most modules are reloaded on use, so with the game running you can also copy a changed file into
`ue4ss/Mods/BodycamOutbreak/Scripts` and press F7 twice. `main.lua`, `controls.lua` and the panel's
key bindings only load at game start.

## Building the release ZIP

`Build-HostPackage.ps1` expects the pinned UE4SS build extracted to
`artifacts/loader-review/5e627997` (`dwmapi.dll` and `ue4ss/UE4SS.dll`, `ue4ss/LICENSE`) and a
working local install to copy `UE4SS-settings.ini` from. Upload the resulting
`artifacts/BodycamOutbreak-Host.zip` to a GitHub release.

## Notes and constraints

- Stable UE4SS 3.0.1 fails signature scanning on this game build; use the pinned experimental build.
- Never enumerate all UObjects (`ForEachUObject`): it crashed UE4SS on this game. Use
  `FindAllOf(class)` / `StaticFindObject(path)`.
- All gameplay calls run on the game thread (`ExecuteInGameThread` / delayed loops).
- Do not commit game files, logs or the `artifacts/` folder.
