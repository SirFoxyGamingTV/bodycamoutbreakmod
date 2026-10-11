# Bodycam Outbreak

Host-controlled zombie waves for **Bodycam** multiplayer. Hordes of fast zombies spawn around the
players and bots on normal PvP maps, chase the nearest target, and kill in one hit, while the game's
own weapons, camera, movement, maps and graphics stay untouched.

Built as a [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) Lua mod. Only the **host** needs it.

## Features

- **Zombie waves on demand**: press F7 (or use the F6 panel) to start or stop. A wave spawns one
  zombie per second at reachable spots at least 6 m from any player; when five or fewer are left
  the next wave tops the horde back up.
- **Settings panel (F6)**: zombies per wave, damage per hit and zombie speed, changed live and
  saved between sessions.
- **Fair scoring**: dying to a zombie never costs kills or score. Killing zombies rewards you
  depending on the mode (see below).
- **Automatic cleanup**: when the match ends (scoreboard / tablet map vote) the horde stops and
  every zombie is removed, so nobody gets killed while voting. Map changes stop it too.
- **Corpses** stay for 15 seconds and then disappear.

### Supported modes and scoring

| Mode | Killing zombies | Killed by a zombie |
|---|---|---|
| Deathmatch, Hardpoint, Zombies | every 10 zombie kills = +1 kill | no effect |
| Team Deathmatch | every 10 zombie kills = +1 kill | no effect |
| Gun Game | every 10th zombie kill counts as a real kill (kill, score **and** gun upgrade) | no effect |
| Versus | no reward | no effect |

The horde will not start in other modes, or when you are not the host.

## Requirements

- Bodycam on Steam (tested on build 25505592, Unreal Engine 5.5).
- **UE4SS experimental 3.0.1-1164-g5e627997.** The stable UE4SS 3.0.1 release does *not* work
  with this game build. The release ZIP below already includes the right version.
- Windows 10/11 with PowerShell (only needed for the installer script).

## Installation (host only)

### Option A: release ZIP (recommended)

1. Close Bodycam.
2. Download `BodycamOutbreak-Host.zip` from the [Releases](../../releases) page and extract it.
3. In the extracted folder, right-click empty space, choose **Open in Terminal**, and run:

   ```powershell
   ./Install-Host.ps1
   ```

   If Bodycam is installed in a different Steam library, add
   `-GameRoot 'D:\SteamLibrary\steamapps\common\Bodycam'`. If Bodycam has updated since this
   version was tested, the installer stops; add `-Force` to install anyway.

The installer checks every file, backs up anything it replaces to
`Bodycam\Binaries\Win64\OutbreakBackups\`, keeps other mods and ReShade, and enables the mod.

### Option B: manual

1. Install UE4SS experimental 3.0.1-1164-g5e627997 into `Bodycam\Bodycam\Binaries\Win64`
   (`dwmapi.dll` next to the game exe, the `ue4ss` folder beside it).
2. Copy this repo's `mod\BodycamOutbreak` folder to `Bodycam\Bodycam\Binaries\Win64\ue4ss\Mods\`.
3. Add the line `BodycamOutbreak : 1` to `ue4ss\Mods\mods.txt`.

## How to play

1. Start Bodycam and **host** a match in a supported mode (public or private lobby).
2. Press **F6** to open the settings panel, or **F7** to start the zombie waves straight away.
3. Press **F7** again or **F10** to stop and remove all zombies at any time.

Friends join your lobby normally and do not need the mod. Waves must be started again each match.

### Controls

| Key | Action |
|---|---|
| **F6** | Open / close the Outbreak settings panel |
| **F7** | Start / stop zombie waves |
| **F10** | Stop waves and remove every mod zombie |
| **F8** | Write a diagnostics report (for troubleshooting) |

### Settings panel (F6)

The panel appears in the **UE4SS console window** (the black log window that opens with the game).
It works any time, including with the pause menu open.

```
================ OUTBREAK SETTINGS (F6 to close) ================
Horde: RUNNING, wave 2
>> Zombies per wave   < 20 >
   Damage per hit     < 100 >  % of health (100 = one-hit kill)
   Zombie speed       < 420 >
   Start / stop zombie waves (F7)   (press Right)
   Clean up all zombies (F10)   (press Right)
```

**Up/Down** chooses a row, **Left/Right** changes the value or runs the action.

| Setting | Range | Default | Applies |
|---|---|---|---|
| Zombies per wave | 5 to 60 (steps of 5) | 20 | next spawn/wave |
| Damage per hit | 10 to 100 % of health (100 = one-hit kill) | 100 | next hit |
| Zombie speed | 150 to 700 | 420 | within a second, all zombies |

Settings are saved to `ue4ss\Mods\BodycamOutbreak\settings.txt` and survive restarts. Delete that
file to return to the defaults.

## Troubleshooting

- **Nothing happens on F7**: the console explains why (not the host, unsupported mode, or the
  match is over). Run `Open-Diagnostics.cmd` from this repo to watch the log live.
- **Game will not start after installing**: Bodycam probably updated and needs a newer UE4SS.
  Restore from `OutbreakBackups` or disable the mod (below).
- **Report a problem**: press F8 and attach `ue4ss\Mods\BodycamOutbreak\diagnostics.txt` and
  `ue4ss\UE4SS.log` to an issue.

### Disable or uninstall

- Disable: change `BodycamOutbreak : 1` to `BodycamOutbreak : 0` in `ue4ss\Mods\mods.txt`.
- Uninstall: delete `ue4ss\Mods\BodycamOutbreak`. To remove UE4SS too, delete `dwmapi.dll` and
  the `ue4ss` folder from `Bodycam\Bodycam\Binaries\Win64`.

## Limitations

- Host-side only. Zombies, damage and scoring run on the host and replicate normally; the F6
  panel is visible only to the host.
- In-game bots fight the zombies too and can steal targets.
- Round-based modes are assumed to report "match over" only at the very end of the match.
- No protections or anti-cheat are bypassed; use it in your own lobbies.

## Development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the code layout, tests, deployment and
building the release ZIP.

## License

[MIT](LICENSE) for this mod's code. UE4SS is MIT-licensed by its authors. Bodycam and its assets
belong to their owners; this repo contains no game files.
