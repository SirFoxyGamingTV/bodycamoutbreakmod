# Infected civilian appearance pass

Implemented candidate palettes (linear material multipliers, not display swatches):
- Existing shirt/trousers with neutral skin.
- Blue shirt, charcoal trousers, slightly warmer pale skin.
- Rust shirt, olive trousers, slightly sallow skin.

Verified runtime material slots: skin 0, trousers 1, shirt 2. SkinTone is the
native tint parameter. Dynamic instances retain the native texture detail.
Face work begins with restrained skin-tone differences; facial geometry, wounds,
eyes and hair have not been replaced. Avoid claiming unique faces from tint alone.

Hair: no separate hair slot on current mesh. Next asset milestone is a compatible
short-hair mesh with scalp fit, attachment/bone mapping and ragdoll verification.
Do not place an unverified hair mesh on the horde. Desired variants: cropped dark
hair, thinning brown hair, and bald; preserve silhouette/readability and low cost.

Need a living host pawn for a controlled specimen test. Validate both added
palettes in daylight and dark interiors, then validate remote-client appearance.

## Verified head/hair blocker, 2026-10-10

Live GG_Hospital scan reports FACIAL_MORPH_COUNT 0 for the clothed mesh,
zero matching loaded SkeletalMesh head/hair assets and zero GroomAsset matches.
StaticMesh matches were chairs (substring false positives), not hair; the probe
now matches word starts to exclude chairs. This is a loaded-object inventory,
not proof that no unused assets exist anywhere in the game's packages.
No Blender or Unreal Editor executable found in PATH, standard installation
locations, or their registered uninstall entries. No geometry feature deployed.

Next required production step: author or obtain a licensed civilian mesh with
facial detail and short hair, fit it to the verified ALS skeleton, and cook it
for the exact engine/build with Unreal Editor. Need access to that asset pipeline
before promising new facial shapes or hairstyles in-game. Skin tint is not a
substitute for this. Test deformation, scalp fit, death/ragdoll, materials and
network appearance on one actor before horde rollout.
