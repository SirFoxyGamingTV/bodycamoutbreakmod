# Development setup

Workspace: C:\Dev\BodycamOutbreak
Game: C:\Program Files (x86)\Steam\steamapps\common\Bodycam
Steam app: 2406770; tested build: 25505592; Unreal version: 5.5.4.

Git 2.56, PowerShell 7.6.5 and .NET SDK 10.0.202 are available. Visual Studio
Community 2026 exists without the C++ workload. C++ installation is unnecessary
for the current Lua implementation and has not been performed.

The user authorized deployment and private online testing. Official UE4SS stable
3.0.1 failed on this game build. Experimental 3.0.1-1164-g5e627997 loads successfully.
The installed layout uses Win64/dwmapi.dll plus Win64/ue4ss/UE4SS.dll and Mods/.
Existing ReShade files were preserved. Archive hashes and deployment receipts are
under artifacts/reports; raw downloads are under artifacts/downloads.

Lua syntax and session-policy tests run inside the real UE4SS runtime through F8.
A standalone Lua executable is not installed. Static PowerShell checks remain
separate from runtime/gameplay checks.

Use Test-Workspace.ps1 and Build-Staging.ps1 for checks and a disabled package.
Deploy-Mod.ps1 copies source with backups and hash verification while the game is
closed. The development session additionally used explicit hot module updates;
main.lua changes become active only after restart, while F8/F9 handlers load their
modules on demand. F9/F10 were registered and exercised in the running test.

If C++ becomes necessary, install the appropriate Visual Studio C++ workload and
match build requirements to the pinned UE4SS revision. Do not distribute game assets.
See DEVELOPMENT_LOG.md for crash evidence, fixes, current limits and actual tests.
