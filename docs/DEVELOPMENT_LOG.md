# Development log

## 2026-10-09 — M0 foundation

- Inspected dedicated workspace: empty Git repository on master, no commits and
  no project instructions/files found.
- Read Steam registry/library metadata and Bodycam's own manifest, identifying
  exact path, build and executable SHA256 recorded in compatibility.json.
- Inspected executable directory metadata only; no screenshots or unrelated
  game content opened. Observed ReShade; no UE4SS installation in Win64.
- Probed tools and Visual Studio components. C++ workload absent. Hardware CIM
  inspection denied; used basic OS/CPU metadata instead. No installations run.
- Researched official UE4SS releases/docs and bot mod author sources.
- Added disabled bootstrap, read-only fingerprint diagnostics, PowerShell static
  validation, workspace-only staging, milestone gates and architecture notes.

## Active blockers

1. Permitted offline launch/test route and protection policy not established.
2. Exact engine minor version and UE4SS compatibility unknown.
3. Lua runtime absent; Lua execution tests pending. C++ tools absent, deferred.
4. No local class/function/navigation/damage/death evidence for a zombie adapter.

No NPC, horde, Director or special infected is implemented. No gameplay tests
have run. Advance to M1 only once its offline prerequisite can be satisfied.

## Validation results — 2026-10-09

- Inspect-Environment.ps1 executed successfully; installed build and executable hash match the recorded profile.
- Build-Staging.ps1 ran Test-Workspace.ps1: 7 static/workspace checks passed.
- Staged file hashes and disabled registration verified independently.
- Reports: artifacts/reports/environment.json and workspace-tests.json.
- Staging: artifacts/staging/d3e4e5fabbff4115aa6addb3ceef6993.
- Lua execution, UE4SS loading, NPC behavior and gameplay tests NOT run.
- No Bodycam Saved/Logs directory found under the game's install or its expected LocalAppData location.
- Current official Steam listing advertises Online PvP; this is not evidence of an available offline test mode.
- No game installation writes, software installs, downloads executed, or game launches.

## 2026-10-09 — user changed testing scope

User instructed: "just do online test forget offline". Offline-only requirement
is superseded. Plan now uses a private online lobby with consenting participants.
Installation approval and no-protection-bypass requirements remain in force.

Downloaded official v3.0.1 developer archive into workspace, inspected archive
entries/settings, recorded SHA256 and prepared a minimal five-file loader stage.
No third-party binaries executed and no game files modified. All five proposed
destinations are absent. See LOADER_TEST_PLAN.md and the JSON deployment manifest.

Earlier offline blockers are historical. Current gate: user approval to deploy
and load the exact staged loader, then real compatibility/session verification.

Validation: an edit introduced a PowerShell parser error through array flattening;
rewrote the affected script explicitly and reran validation. Seven static checks
now pass; installed game fingerprint still matches; all five loader-stage hashes
match and target files remain absent. No loader/game execution test performed.

## 2026-10-09 — approved deployment and loader tests

User approved installation and ongoing development without repeated approvals.
Deployed the reviewed stable loader with original-file fingerprints and receipt.
Stable 3.0.1 FAILED: identified UE5.5, GUObjectArray and FText constructor scans
failed, then timed out. Archived log: ue4ss-stable-failure.log.
Closed that test and removed only hash-verified receipt-listed additions.

Downloaded official experimental 3.0.1-1164-g5e627997, verified GitHub asset SHA256
6e5dc6c28d63bfdb0a2c2f5665e87b81461277659296b52557a4338981a2cb20,
deployed minimal loader and bootstrap. Real launch loaded BodycamOutbreak and
printed its marker. Archive: ue4ss-experimental-bootstrap.log. Nonfatal warning:
FObjectPtrProperty size unavailable; avoid relying on that type until validated.
This verifies Lua bootstrap loading only, not gameplay or stability in a match.

## 2026-10-09 — private deathmatch integration

User reports native Zombies mode is unavailable and supplied a private deathmatch.
Verified DM_RussianBuilding, GM_Deathmatch, server=true, standalone=false,
IsPublicLobby=false, seven total player states, GetRealPlayersCount=1.
Replaced native-Zombies-only test restriction with a verified supported-mode check.
Twelve pure Lua session validation tests passed inside the real UE4SS runtime.
Eight PowerShell/static checks passed separately.

Generic GameplayStatics deferred spawn calls produced unusable actors: zero health,
no controller, world-origin position. Native Kismet MakeTransform did not fix this.
Cause not conclusively established; do not reuse that path.
UE4SS UWorld:SpawnActor succeeded: visible normal zombie, 100 health, AIC_Zombie,
correct location and player target. It moved toward the player. A subsequent
recording captured health -360 and IsDead=true. Player health also fell, but six
armed bots were present, so melee attribution still requires event evidence.
Sources/evidence: artifacts/reports/spawn-world-api.txt, spawn-telemetry.txt,
combat-telemetry-first.txt. No horde or Director milestone claimed complete.

## 2026-10-09 — crash investigation and focused retest

User reported a crash at 13:24 local time. Cancelled the pending spawn request.
Crash context: EXCEPTION_ACCESS_VIOLATION reading 0xffffffffffffffff; engine 5.5.4;
713 seconds since start. Extracted the exact release PDB from the already verified
zDEV archive. Used Windows DbgHelp to resolve UE4SS offsets offline (no game attach).
Top frames: lua_rawgeti, UObjectBase::construct, auto_construct_object,
setup_lua_global_functions_internal callback, UObjectGlobals::ForEachUObject.
Archived sanitized metadata and symbolized stack under artifacts/reports/crash-*.

Moved the broad diagnostic scanner out of the deployed mod into research/.
Live F8 now captures only focused state and tests. Disabled experimental event hooks
in the test path as an additional isolation measure; root cause beyond the crashing
scan/construction path remains unproven. Restarted session has no registered hooks.
Retest passed 12 gate tests and six then seven module syntax checks. Spawned another
zombie successfully using UWorld:SpawnActor. Telemetry recorded player health 90,
zombie health -480 and Dead=true. This is a short retest, not a stability guarantee.

## 2026-10-09 — isolated melee and controls

F9 spawn verified at 13:28:56; F10 removed the owned zombie at 13:29:49.
At 13:30:54 the isolation experiment found and stopped six AI_Humanoid controller
BrainComponents using reflected StopLogic. Spawned one normal zombie. Player health
repeatedly dropped while it stayed within melee distance and followed movement.
Health also regenerated between hits; damage is not assumed equal to AttackDamage.
RestartLogic restored surviving soldier brains at 13:31:39, confirmed in UE4SS log.
The isolated test supports native melee operation without the Zombies game mode.
Still pending: map-travel cleanup and longer stability run. No horde milestone started.

## 2026-10-09 — timer regression and map travel

At 13:36:56 F8 on DM_Hospital recorded RussianBuilding -> Hospital, cleared the
owned reference and found zero zombies. The new map remained private, host-authority,
with one human. Timer regression: PASS ticks=3 active=false using explicit handles.
ClearAllDelayedActions returned 0 while legacy LoopAsync callbacks kept repeating,
so those callbacks belong to a separate scheduler. A clean game restart is required
for the migrated main.lua to eliminate them. Do not claim live migration cancelled
legacy callbacks. Revised source uses no LoopAsync. Archived both test reports.

## 2026-10-09 — fresh-process verification and travel guard

Clean restart completed at 13:37. Fresh-process timer regression passed (ticks=3,
active=false). F8 at 13:41:38 passed 12 Lua policy tests and syntax checks for 10
modules. Current world is Lobby; gameplay gate correctly rejects spawning there.
Navigation call returned false with X/Y/Z output fields; this is not evidence of
reachable navigation on a Deathmatch map. No repeated soldier-restore callbacks
appear in the fresh process log through this check.

Added a current-world check before the spawn telemetry loop touches its captured
zombie, and cancellation when ownership is cleared by cleanup. Skip destroyed or
rootless actors during sampling. These changes are deployed for the next spawn;
travel behavior still needs a live retest. Fixed action-log open failure leaving
the controls busy flag stuck; that callback change takes effect next restart.
Static checks: 9 pass. Rebuilt disabled staging ca9be068ecd44809a57179e90d593b7f.
Still awaiting private Deathmatch for obstacle pursuit and combat stability tests.

## 2026-10-09 — sprinter hordes (0.4.0 development)

User accepted the single-zombie result and requested sprinters and hordes.
Implemented F7 toggle, one spawn per second, waves 6/7/8 with total living cap 8,
15-second rest after all living zombies clear, bounded navigation retries,
owned corpse disposal, F10 cleanup, stop on death/session change/world change.
Placement uses the Hospital-verified native reachable-point query, six candidate
attempts per tick and minimum horizontal player distance 600 units.
Speed changed 130 -> 420; runtime CharacterMovement.MaxWalkSpeed readback was 420.
No rendering settings changed. Existing Deathmatch soldiers remain active.

Live Hospital private host test: 12 session gate assertions and 20 horde policy
assertions passed inside UE4SS. Wave 1 spawned six zombies at 17:44:53–58 UTC;
multiple zombies visibly approached the player. Population fell to zero, then
wave 2 queued seven at 17:45:31. Logs record staggered spawns. This is a short
functional test; long-run frame time and horde travel/death cleanup remain to test.

## 2026-10-09 — public host lobby eligibility

User requested public-lobby support. Session gate now permits public/private host
sessions with any positive integral human count. Client-only sessions, unknown
visibility, unsupported modes and invalid counts are still rejected. Horde ticks
reuse the same gate, so public visibility or an additional human no longer stops
waves. Existing host targeting, host-death stop and population cap are unchanged.

Backed up and deployed session_gate.lua, test_session_gate.lua and horde.lua.
Runtime F8 at 17:49:50 UTC: 28 gate assertions and 20 horde policy assertions pass;
9 workspace static checks pass. Current game is Lobby, not a running public match.
Remote-client visibility, replication and damage remain UNVERIFIED. Public lobby
policy tests do not establish multiplayer gameplay compatibility. Updated README
with these limits. New horde runs use the revised callback; an already-running
old wave loop would need to be stopped and started again.

## 2026-10-09 — ten-zombie waves, shared targeting and score exclusion

Changed cap/wave size to 10, removed rest delay, and begins the next spawn in the
same one-second scheduler tick that observes zero living zombies. Target candidates
are living same-world Bodycam_Player_C and AI_Humanoid_C actors; nearest candidate
is selected per zombie. No targets pauses the loop until a respawn. Placement
rejects points within 600 horizontal units of any candidate.

Runtime tests: 28 session checks, 6 revised wave assertions, 4 nearest-target
assertions passed. Live Hospital START at 17:56:54 UTC queued 10; wave 2 at17:57:16
and wave 3 at17:57:53 each queued 10. Logs show targets assigned to both the host
Bodycam_Player and multiple soldier AI actors. Remote human targeting/replication
remains untested.

Scoring trace proved native BodycamGameMode:NotifyPlayerKilled increments Kill
and Score for zombie victims despite ShouldCommunicateDeath=false. Added a native
pre-hook filtering only mod-owned zombie victims by clearing InstigatorController
for that notification. Does not suppress the death or change other victim types.
Verified live after loading at17:58:22: four zombie kills left Kill and Score
unchanged (5->5/1->1, 8->8/6->6, 9->9/4->4 twice). A normal soldier kill at17:58:44
still incremented Kill 8->9 and Score 6->7. No retroactive score correction.
Filter is installed by horde/single spawn and F8 diagnostics; old broad combat
hooks remain disabled. Preserved telemetry and source hashes in reports.
9 workspace checks passed; rebuilt staging 0f6377128dd146e096ef97282790d16c.

## 2026-10-09: 20 cap, five-survivor refill, experimental server melee and Hardpoint

Implemented cap/wave budget20, threshold5, and replenish-to-cap semantics; avoids
unbounded overlapping waves. Rotates spawn origin even when placement fails.
AttackDamage10000 is used for single zombies and hordes. New melee.lua hooks the
reflected AttackHitDetection event and applies reflected ApplyPointDamage to the
owned zombie's selected target, server-only, with range/height/LOS/cooldown checks.
This is a proposed fix for the reported remote-player/AI damage failure; no live
health-drop evidence was obtained for the new handler. Do not mark it combat verified.
Hardpoint gate checks the shipped DA_Hardpoint identity; no guessed gamemode class.

Real Lua tests using workspace-local Lupa2.6:46 assertions (gate28, waves8,
targets4, melee6),24 syntax checks. Workspace PowerShell/static checks11 passed.
Live lobby diagnostics passed40 assertions from in-game tests. Startup at19:43
crashed18 seconds in, before the new handlers/diagnostics ran. Sanitized crash
summary and UE4SS log preserved in artifacts/reports/startup-crash-20261009.
Subsequent clean launch reached Lobby. F8 worked, but Tab/Escape automated input
never opened the lobby menu, preventing unattended match creation. Closed game
and deployed24 mod files with backup/hash receipt. Hardpoint, lethal combat and
remote-client damage remain unverified. No fabricated gameplay success.

Built BodycamOutbreak-Host-Prototype.zip with pinned official loader, MIT license,
mod sources, hashes, installer and candid instructions. Installer requires matching
Bodycam executable fingerprint, refuses conflicting DLLs, backs up replaced files,
and preserves unrelated mods/ReShade. Joining an unmodified friend's host cannot
provide server authority; friend-host installation is required. No remote machine
or second player was available to verify non-host gameplay.

## 2026-10-09: 15-second horde corpse retention

User reports Hardpoint gameplay working. Replaced immediate dead-actor destruction
with a 15-second retention period from first observed death, checked once per second.
Retained corpses are not counted as living zombies and do not delay wave thresholds.
Expiry runs even when no living targets remain. F10/stop still removes all owned
actors immediately. Invalid/destroyed actors are pruned with their timestamps.
46 existing Lua assertions,24 syntax checks and11 static checks passed; rendering
and native Blueprint corpse lifespan have not been live verified for this change.
Initial atomic replacement failed on a null backup argument; retried with a named
backup successfully. Only installed horde.lua replaced, SHA256 verified.
Current timer captures its old code: F7 off/on loads the new implementation;
no game restart required. Did not interrupt the user's match or toggle waves.

## 2026-10-10: native clothed infected appearance prototype

Class-scoped live asset inventory verified joker_CHEMISE_PANTALON uses the same
ALS_Mannequin_Skeleton as the zombie, with a physics asset. Reflected actual
SetSkeletalMeshAsset(NewMesh), GetNumMaterials/GetMaterial/SetMaterial signatures.
Added appearance.lua with skeleton compatibility check, per-instance mesh swap,
clearing material overrides to the replacement defaults, and error rollback.
Read-only appearance_probe.lua is run by diagnostics. No asset extraction/download.
Preview command first refused the single-spawn limit; changed it to use one owned
living zombie already in the current world. Live APPEARANCE_PREVIEW succeeded on
GG_WornHouse actor BP_NormalZombie_C_2147352218. No isolated close-up or remote-client
visual verification obtained. This is a clothed native infected prototype, not
completed NMRIH2-quality civilian art. Existing death/animation behavior is retained.
New horde spawns now attempt the appearance swap and fall back on an error.
Installed files replaced atomically with backups. Current captured horde code
requires F7 off/on to pick up new-spawn appearance behavior. No forced wave reset.

## 2026-10-10: fix appearance overwritten after spawn

User saw no change. Live log showed APPLIED at spawn, while subsequent asset
snapshot showed the same actors back on Village Nun/Crush/Miners meshes. Added
one game-thread check per second over owned horde actors, replacing only differing
meshes after native delayed initialization. Cancels on horde stop/world change;
checks current world before referencing captured actors. Native late overwrite
was observed and the corrective reapplication now appears in the live log.
Installed appearance.lua atomically without restarting waves. Visible nearby
infected in screenshot now has a striped shirt and trousers. Remote clients
remain unverified. Existing 94 assertions/29 syntax checks pass.

## 2026-10-10: two clothing palettes and initial skin pass

Live material inventory verifies mesh slots 0=skin,1=trousers,2=shirt (TArray
inventory uses 1-based indices). Clothing and skin inherit M_Skin_Master; SkinTone
is present in shirt and skin overrides. Added per-instance dynamic materials with
stable actor-ID palette choice: original, blue/charcoal, rust/olive. SkinTone
variation is subtle and changes exposed skin including face; no face geometry edits.
No shared assets changed. Native late mesh reset still triggers appearance repair.
Existing 94 assertions/29 syntax checks passed; these do not verify new material
rendering. Live specimen attempt was blocked by dead local pawn, with no spawn.
No assertion that either new palette is visually verified. Installed appearance.lua
atomically; new horde spawns load it. No pending experiment request remains.
Hair work started with slot/asset audit: current mesh has no separate hair material.
No compatible dedicated hair mesh identified; hairstyle changes remain pending.

## 2026-10-10: facial geometry/hair feasibility audit

User triggered F8 after automated input conflicted with active play. Live report
05:04:14Z from GG_Hospital: clothed mesh has zero morph targets; no matching loaded
skeletal head/hair or groom assets. Static matches were chairs, excluded by refined
name matching. Evidence saved as head-hair-audit-20261010.txt. No compatible model
or asset-authoring toolchain found. Actual face/hair geometry work remains blocked
on authored compatible assets and Unreal cooking; no cosmetic success claimed.

## 2026-10-10: shorts/T-shirt request

Searched saved runtime inventories for shorts, T-shirt, tee-shirt and bermuda mesh/
package candidates; none found. No custom FBX/OBJ/GLB/BLEND/UAsset source in mod.
Current mesh cannot become shorts via tint. Recorded two outfit color targets in
docs/art/SHORTS-TSHIRT.md, explicitly inactive pending compatible geometry and
asset authoring/cooking. No gameplay files changed; no new outfit claimed.
