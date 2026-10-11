# Bodycam Outbreak (host package)

Zombie waves for Bodycam multiplayer. Only the player who **hosts** the match needs this.
Includes UE4SS 3.0.1-1164-g5e627997 (MIT license, included) and no Bodycam game files.

## Install

1. Close Bodycam.
2. Extract this ZIP, open a terminal in the extracted folder (right-click > Open in Terminal) and run:

   ```powershell
   ./Install-Host.ps1
   ```

   - Other Steam library: add `-GameRoot 'D:\SteamLibrary\steamapps\common\Bodycam'`
   - Bodycam updated since this build was tested: add `-Force`

The installer verifies every file, backs up anything it replaces to
`Bodycam\Binaries\Win64\OutbreakBackups\`, keeps other mods and ReShade, and enables the mod.

## Play

Start Bodycam, host a Deathmatch, Team Deathmatch, Gun Game, Versus, Hardpoint or Zombies match, then:

| Key | Action |
|---|---|
| F6 | Settings panel (zombies per wave, damage, speed) in the UE4SS console window |
| F7 | Start / stop zombie waves |
| F10 | Stop and remove all zombies |
| F8 | Diagnostics report |

Zombies are removed automatically when the match ends. Dying to a zombie never costs score.

## Disable / uninstall

Disable: in `Bodycam\Binaries\Win64\ue4ss\Mods\mods.txt` change `BodycamOutbreak : 1` to `: 0`.
Uninstall: delete `ue4ss\Mods\BodycamOutbreak`; restore replaced files from `OutbreakBackups`
(`receipt.json` lists files the package added).
