# Milestones and evidence gates

Each milestone must pass before implementation advances to the next.

| Milestone | Acceptance evidence | Current status |
| --- | --- | --- |
| M0: repository and environment | Exact install/build/hash, tool inventory, scripts checked and staging produced | Foundation ready; tool installation deferred |
| M1: private online loader | Confirm controlled private test session and protection policy; approved install plan; pinned UE4SS; fresh log; clean exit; rollback verified | Experimental loader and private deathmatch verified; runtime stability under investigation |
| M2: one hostile zombie | Verified asset/class/controller; spawn one; navigate to player around obstacle; melee range/cooldown; damage both ways; death; cleanup on map travel | In progress: visible spawn, native controller/target, movement, health and death recorded; melee attribution, obstacle navigation and stability outstanding |
| M3: hordes | Bounded spawn queue, population cap, navigation-aware placement, cleanup, sustained survival test | User requested advancement after accepting single zombie. Implemented sprinter waves; live Hospital waves 1 and 2 verified. Sustained performance and travel cleanup pending |
| M4: Director | Tested build/peak/recovery pacing driven by player pressure; deterministic unit tests; bounded difficulty | Not started |
| M5: special infected | Original archetypes with clear attacks/counters; verified animations, damage and cleanup | Not started |
| M6: performance and release | Same visual settings/map baseline; frame-time percentiles; long session; reproducible package and rollback | Not started |

M2 test record must include build/hash, loader version, map, private-session evidence,
class/function evidence, steps, expected/actual results, logs and observed failures.
A spawned idle pawn is not a working zombie. Authority alone does not prove a lobby is private or participants consent.


