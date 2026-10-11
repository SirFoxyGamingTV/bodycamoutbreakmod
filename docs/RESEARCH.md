# Compatibility research — 2026-10-09

## Installed build

Steam app 2406770, build 25505592. Exact installation:
`C:\Program Files (x86)\Steam\steamapps\common\Bodycam`.
Shipping executable: `Bodycam\Binaries\Win64\Bodycam-Win64-Shipping.exe`.
SHA256: `2792EA9A5E062BFC69883F496E9517D2F1308CA573DADE7F8DB108F722DB127C`.
Version resource says UE5-CL-0; this does not establish the UE minor version.
ReShade files and dxgi.dll exist. No UE4SS DLL or directory was observed in Win64.
No game launch, injection, asset extraction or game file change performed.

## Sources and assessment

- [UE4SS official documentation](https://docs.ue4ss.com/): engine coverage is
  broad but game compatibility is not guaranteed. Build-specific testing required.
- [Official releases](https://github.com/UE4SS-RE/RE-UE4SS/releases): v3.0.1 is
  labelled latest stable; experimental is separate. C++ mods require rebuilding
  for v3.0.1. No archive selected or installed.
- [Inactive bot spawner, author page](https://www.nexusmods.com/bodycam/mods/23):
  author recommends v3.0.1 and waiting for level load. Advertises inactive bots;
  does not prove pursuit, melee or support for build 25505592. Source not reviewed.
- [TRENCH repository](https://github.com/0x0d4ddy/TRENCH) and
  [Lua source](https://raw.githubusercontent.com/0x0d4ddy/TRENCH/master/TRENCH/Scripts/main.lua):
  source calls GameMode SpawnBot, adjusts team capacity and restarts controllers
  with AI-on-possession enabled. It explicitly requires a networked host and
  rejects standalone. These are useful lifecycle and spawning leads, not an
  acceptable offline implementation to copy. Its loading delay and cached-object
  handling identify investigation areas, not guarantees of safety.
- [Original player-limit mod](https://github.com/TRUEMODELOFTHEWORLD/BODYCAM-Game---Increase-maximum-limit-of-players):
  upstream research lead; no source port undertaken.
- [TRENCH distribution page](https://www.nexusmods.com/bodycam/mods/50): permission
  text differs from repository MIT declaration. No code/assets copied; verify the
  exact file license before any reuse. Its claims about Blueprint behavior are
  author observations, not proof that all Lua AI changes are impossible.

Bodycam previously shipped zombie content according to the
[developer's Steam announcement](https://store.steampowered.com/news/app/2406770/view/4703536805551911078).
Whether this build exposes usable zombie assets and offline play remains unknown.
Investigate existing native zombie behavior before building replacement AI.

## Conclusion

UE4SS compatibility with this exact build is UNKNOWN. Bot spawning approaches
may inform an adapter after local reflection evidence, but do not establish a
working hostile zombie or a permitted offline route. Do not adopt network-host
checks, guessed paths, offsets, protection workarounds or published spawn names
as locally verified APIs. Web sources can change; pin a revision before reuse.

Offline follow-up: the [current official Steam listing](https://store.steampowered.com/app/2406770/Bodycam/)
advertises Online PvP and does not establish a supported offline testing route.
No existing log was found at the expected Bodycam Saved/Logs paths. Offline
eligibility remains unknown, rather than assumed impossible or silently waived.

## Updated test scope — 2026-10-09

User authorized online testing, superseding the earlier offline-only constraint.
Use the private-session loader proposal in LOADER_TEST_PLAN.md. UE4SS v3.0.1
has now been downloaded and staged, but remains unexecuted and unverified.
