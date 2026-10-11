# Civilian zombies (City Sample Crowds)

With `OutbreakCivilians_P.pak` installed in `Bodycam/Content/Paks/~mods/`, every mod-spawned zombie
is drawn as a City Sample civilian (face, hair, everyday clothes) with a zombie overlay
(grey-green skin, grime, blood). Without the pak, zombies keep the native clothed-infected look.

## How it works

* The zombie keeps its own mesh, animation blueprint, collision and damage. The mesh is hidden but
  keeps animating (`VisibilityBasedAnimTickOption = AlwaysTickPoseAndRefreshBones`).
* `civilians.lua` attaches City Sample's hidden `*_base` skeleton (SK_Base) to the zombie mesh,
  raised 8.4 cm. Its anim blueprint `ABP_CivilianRetarget` contains one *Retarget Pose From Mesh*
  node using `RTG_ZombieToCivilian` (UE4 Mannequin/ALS -> City Sample), so it copies the zombie's
  pose every frame, including death ragdolls.
* Body, top, bottoms, shoes and face meshes follow the base via leader pose; a groom (hair) is
  bound to the face. `M_ZombieOverlay` (unlit, Modulate) is set as each part's overlay material
  with per-zombie tint/blood variation.
* Looks are picked deterministically from the zombie's object id: 2 sexes x 2 body types x 6 faces
  x 6-7 hairstyles x several tops/bottoms/shoes (~1,450 distinct looks per 2,000 zombies).
* Visual only and local to the host. Joining players see the game's normal zombies unless they
  also run the mod.

## Rebuilding the pak

Requires Unreal Engine 5.5 (Bodycam is 5.5; newer engines produce packages the game cannot load)
and the free *City Sample Crowds* pack from Fab added to `Unreal/OutbreakCivilians` (pick 5.3 in
the launcher's version list; 5.5 upgrades it).

The editor runs `Scripts/outbreak_startup.py` on launch and then watches `Scripts/job.txt`.
Write a step name into that file and the editor runs `Scripts/outbreak_<step>.py`, writing a
report to `Saved/Outbreak/<step>.txt`:

| Step | Does |
|---|---|
| `discover` | Read-only inventory of meshes, skeletons and grooms |
| `rig` | IK rigs, retargeter and the (empty) retarget anim blueprint |
| `abp_open` | Unmaps metacarpal chains, opens the anim blueprint |
| *(manual)* | In the anim graph add **Retarget Pose From Mesh** and connect it to Output Pose |
| `abp_finish` | Points the node at the retargeter, compiles and saves |
| `zombify` | Builds `M_ZombieOverlay` |
| `preview` | Places a test civilian on an engine mannequin in the open level |
| `cook` | Cooks for Windows (SM5 + SM6, legacy pak layout, inline shaders) |
| `pak` | When the cook is done: builds `OutbreakCivilians_P.pak` and installs it |

## Licensing

City Sample Crowds is Epic "UE-Only Content": usable in Unreal Engine-based products such as
this Bodycam mod. Do not commit the source assets; ship the cooked pak only.
