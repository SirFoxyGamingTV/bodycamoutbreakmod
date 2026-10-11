# Architecture decisions

Lua first. C++ is deferred until measured performance or a missing Lua capability
requires it. The loader ABI is pinned to experimental 3.0.1-1164-g5e627997.

## Implemented single-zombie test

- `main.lua`: F8 diagnostics and explicit controls; no automatic spawning.
- `controls.lua`: game-thread action dispatch, F9 spawn and F10 cleanup.
- `session_gate.lua`: pure validation of host, online, supported mode, private
  visibility and one-human test session. Twelve runtime tests cover rejection.
- `probe.lua`: focused health/position/controller/target/death telemetry.
- `experiment.lua`: UWorld:SpawnActor using the locally verified normal zombie
  asset and native AI. One living zombie maximum; only owned actor cleanup.
- `monitor.lua` / `lifecycle.lua`: bounded samples and world-change invalidation.
- `diagnostics.lua`: targeted snapshot and real Lua syntax/tests. No ForEachUObject.
- `combat_events.lua`: disabled experimental observer; never loaded by gameplay.

Game-native navigation, animation, attacks, damage and death are reused. No direct
health subtraction, teleport pursuit, replacement player camera, or visual setting
changes are used. Setting AttackDamage does not yet establish the damage applied
by the native ability system; calibration remains necessary.

## Evidence and constraints

The private DM_RussianBuilding test verified a live native zombie with 100 health,
AIC_Zombie controller, player target, movement and a dead state after damage. Six
soldier AI brains were paused for 45 seconds to separate melee testing from their
combat; repeated player health loss was observed near the zombie. Brains restored.
A sustained stability test and map-travel validation remain outstanding.

The generic deferred spawn route yielded unusable actors and is abandoned pending
root-cause analysis. The UE4SS UWorld spawn wrapper works in actual tests. Broad
UObject enumeration crashed UE4SS; its full scanner now lives in research/ only.
Crash symbols and all gameplay logs are stored under ignored artifacts/reports.

Hordes, Director and special-infected implementation remain behind the M2 gate.
Actor references must be discarded on world changes. Gameplay actions revalidate
session eligibility each time. Full object enumeration is forbidden in live code.
