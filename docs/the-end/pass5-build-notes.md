# THE END pass 5: build notes ("The Last Clock")

Module: `roblox/ReplicatedStorage/AuraFX/TheEnd.lua` (ModuleScript `ReplicatedStorage.AuraFX.TheEnd`), built in the cloud from
`docs/the-end/pass5-spec.md`. **Nothing here has run in Roblox Studio.** It has run in the headless harness (mock Roblox runtime) and
been drawn by the preview renderer (`tools/`), which are strong filters but not Studio. Every engine assumption that only Studio can
confirm is marked `-- STUDIO-VERIFY:` in the code and listed at the end of this page.

Renders for Milo: `docs/the-end/pass5-renders/` (see the list at the end).

## What was built

Everything in spec §3 to §17, with the spec's part counts: **360 moving parts on high quality, 149 on low** (one `BulkMoveTo` per
frame), 18 particle systems (19 emitters; 11 on low), 6 beams (2), 11 GUIs (7), 2 PointLights (1), 1 Highlight. The clock is
viewer-anchored through the critically damped yaw spring (§5), the armillary and dais are body-anchored, the orbs hang on the
viewer-anchored balance. The 6.5 s mechanical assembly (§12) plays on every build, with the wearer-only grade copied from pass 4.
Day/night uses the quantised ClockTime night factor (§11). Far LOD, low quality and the near-camera rules follow §13. The optional
film-mesh path (§15) is implemented and off by default. `TEX` is pass 4's table verbatim; `TEX5` is all `""` (pending upload) with the
`T(key)` resolver and the spec's `FALLBACK` table; every emitter takes its flipbook layout and mode from `T`.

Character integration (§10): `End.pose` is pass 4's verbatim. Palm attachments `TheEndPalmR/L` are made on the hands (copying the grip
attachment's position, R15 or R6), sole attachments `TheEndSoleL/R` on the feet; the streams' Attachment1 flips between palms only
when the wearer turns past f = ±0.2 against the viewer. All 4 character attachments (and the 2 drip emitters on them) are destroyed in
`fx.destroy()`, as are the root model and the camera grade.

## Decisions where the spec was ambiguous, inconsistent, or did not survive the preview

Each was made after looking at renders or measuring snapshots, and is the kind of thing to re-check in Studio.

| # | Spec | Built | Why |
|---|---|---|---|
| 1 | `CLOCK_HEIGHT` 9.6 | **9.85** | Measured on snapshots: at the bob's low point the bezel's bottom corners sat only 0.02 above the spinning arms layer G1 (the spec's −4.74 figure was G2's height and used the segment centre, not its corners). +0.25 gives ≥ 0.24 everywhere (spec wants ≥ 0.2). Still a CONFIG/attribute tunable. |
| 2 | Meridian lean 24°, equator 66° | **33°, 57°** | Same cause: at the bob's low point the meridian's outer edge dipped ~0.15 below the floating galaxy-core layer G2 (spec wants ≥ 0.25 above). 33° gives ≥ 0.28; the equator's relative tilt was reduced by the same 9° so it still averages level. |
| 3 | Moon halo `StudsOffset` z −4.8 | **−2.0** | Pushed 4.8 back, on the clock side the halo reached the inlay plane (−0.27 to −1.1 studs: Roblox would cut it, the pass-4 "white wedge"). 2.0 still puts it behind the ball (the ball hides its inner edge) and keeps ≥ 0.55 from every GUI plane (spec §18.2 wants ≥ 0.4). |
| 4 | Corona plane 40 × 40 | **44 × 44** | Seen from the front, a ring 3.2 studs behind the clock lands ~7 % smaller on screen, so a peak at R 14.8 hid behind the bezel (R 14.12). At 44 the peak (R 16.3) shows just outside the bezel at night. Still rim-only. |
| 5 | Equator band 0.75 deep, ticks 0.5 | **0.40, ticks 0.32** | From a level front camera the near half of the dark band read as a black bar across the chest. Thinner, it reads as a bracelet ring; still dark steel with 12 lume hours. |
| 6 | Particle sizes and rates (§9) | **Tuned up** (below) | At Milo's 40-stud framing most spec sizes were 1 to 4 pixels and the white motes vanished on sand and sky. Totals stay inside §14: Rate ≈ 178/s high (limit 200), ≈ 57/s low (limit 80). |
| 7 | Bokeh peak transparency 0.6 | **0.72** | Texture note (d): the te5 hexagons read like glass panels. |
| 8 | STEEL (44,46,52), DEEP (30,31,36) | **(44,46,51), (30,31,35)** | One unit bluer-to-neutral so the harness's HSV palette lint passes (it flags saturation > 0.15 above value 0.12). Visually identical; still B ≥ R, spread ≤ 20. |
| 9 | Funnel spin `rad(70)*t` ("verify the sign") | **−70°/s** | The floor's arms wind counter-clockwise outward, so matter falling inward along them turns clockwise; locked particles spiral with the host's spin. |
| 10 | Accretion `dir` ±1 | **+1** | te5_accretion's streaks wind clockwise outward, so a counter-clockwise turn (positive Y as seen on its Top face) makes them trail. P1's swirl host uses the same `dir`. |
| 11 | P3 shards size | **×1.3 only when te5_shards resolves** | Texture note (b): the te5 sliver fills ~half its cell. The fallback (`ash`) fills its sprite, so it keeps the base size. |
| 12 | B5 ribbon Color (12,12,16) | **WHITE when `T('ribbon')` is te5_ribbon** | Texture note (a): Beam Color multiplies the texture; the te5 ribbon carries its own ink body and white hairlines. (12,12,16) stays for the `line` fallback. |
| 13 | Night factor every 1 s, steps of 0.05 | **plus at most one 0.05 step per tick** | A fast in-game day could jump several steps in one tick; the cap guarantees no brightness step > 0.05 per second (§11 "dusk never steps"). The first evaluation at build jumps straight to the current value. |
| 14 | Beam fade "≤ 20 writes" | **11 precomputed steps per beam** | The Transparency NumberSequences for each fade step are built once at build, so update only assigns one (no allocation in update); ≤ 10 writes per beam per fade. |
| 15 | Assembly timing while hidden | **Pauses** | The framework does not call `update` while the aura is hidden (Scriptable camera, e.g. the roll cutscene), so the assembly resumes when the player can see it. The grade runs on wall time (as pass 4). |
| 16 | Gear spin-up only listed for GA–GD | **All 7 gears** spin up from 300°/s and wind down (exp) from their own slide-in time | Mechanical consistency; integrated as an extra angle so nothing jumps. |
| 17 | Film-mesh assembly | Single-mesh bezel/dial/rete fly in as one piece in the same windows | 32 segments' sweep cannot apply to one mesh. |
| 18 | `DAIS_FLOAT = false` | Dais stays at the last ground height (or floats if there was never ground) | Not specified. |
| 19 | `setVisible(false)` and emitters | Only the 2 foot-drip emitters are toggled | Everything else leaves the world with the root model, so no writes are needed. |
| 20 | Hold-yaw init | `yawTarget = psi` from the build-time camera, else the wearer's facing (owner view) | As §5. With `VIEWER_ANCHOR = false`, V = W turned 180° and the owner-only see-through rule (LocalTransparencyModifier 0.5 on all clock parts, written only on flips) is active. |

Particle tuning (spec → built; high/low rates): P1 VoidSwirl rate 24/10 → 34/12, size 0.32→0.12 → 0.55→0.18 · P2 MoonDust peak
0.24 → 0.40 · P3 ShardFeed rate 3 → 5, size 0.5/0.75/0.3 → 0.6/0.9/0.35 (× 1.3 with te5) · P4a SmokeVoid rate 5/2 → 7/3 · P4b
SmokeMoon rate 4 → 5 · P5a RimGlints rate 2.5/1 → 3/1.2, peak 0.9 → 1.3 · P5b peak 0.6 → 0.9 · P6a AirDust 0.06–0.16 → 0.10–0.26 ·
P6b AirGlints rate 4 → 5, peak 0.45 → 0.7 · P8a GalaxyMotes peak 0.3 → 0.42 · P8b ash 0.28–0.42 → 0.40–0.60 · P9 funnel 0.3→0.08 →
0.42→0.10 · P10 palms 0.22 → 0.30 · P11 drips 0.14 → 0.18. Dark smoke, ash and shards were favoured because they read on the bright
day sky (pass-4 lesson: additive white vanishes by day).

## Checks run (cloud only)

- **Harness, all 19 scenarios:** 0 errors, 0 harness gaps, nothing left behind after `destroy()` in any scenario (instances,
  connections, tweens, render-step bindings), 0 new instances per frame, exactly 1 BulkMoveTo per update, 0 steady-state writes to
  GUI properties or `Transparency` (dusk shows only the night-tick writes; `toggle_visible` shows the assembly resuming after the
  Scriptable-camera pause). Measured budgets match §14 exactly: 360/149 parts moved, 19/11 emitters, 6/2 beams, 11/7 GUIs, 2/1
  lights, 1 Highlight; far LOD moves 266 (94 Detail parts dropped).
- **Remaining harness warnings, judged not real:** `translucent-layer` on the moon halo (13 studs at 0.65 day / 0.45 night) and the
  night corona (44 studs at 0.60): both are the spec's allowed rim-only soft elements (§7.3; the lint cannot tell rim-only images from
  uniform ones). `flicker` on the 2 foot-drip emitters in `toggle_visible`: that scenario hides and shows the aura 4 times in 0.3 s,
  and §10 requires the drips (which live on the character) to switch off while hidden.
- **Spec §18.2 geometry, measured on snapshots** (camera orbit, glide, air, day, low, remote, R6): the clock is always on the far side
  of the wearer (spring lag ≤ 5.6° at the harness's 18°/s orbit, matching 2·speed/k); no NaN; armillary vs body points ≥ 1.0; vs moon
  and void ≥ 2.8; vs the accretion disc ≥ 1.3; time shards vs hands ≥ 0.79; void disc vs the clock ≥ 2.5; clock bottom vs the dais
  layer under it ≥ 0.24; meridian vs dais layers ≥ 0.28; moon halo vs every GUI plane ≥ 0.55; no visible part below the dais.
- **Edge cameras:** straight above (yaw held, no NaN), first person (all 76 armillary parts hidden, bokeh off, yaw held).
- **Unequip fade** (a test copy forcing `s.alpha` 1 → 0 over 0.9 s): parts, images, Highlight and beams fade together, emitters stop
  below 0.6, ends fully transparent, no errors.
- **Film meshes** (a test copy with every FILM_* flag on): with the mock kit present, 129 procedural parts become 9 meshes (231 parts),
  no errors; kit absent → silent fallback to 360 procedural parts. A unit test of the normalisation on the spec's odd sizes passes
  11/11 (thin axis → clock depth, non-round Dial rejected, hand long axis → XII, right-handed frames, sphere rules).
- **Preview renders** (day, night, 8 cameras, the assembly, fallback textures and the te5 textures) were looked at critically and
  drove decisions 1 to 7 and the particle tuning.
- **Static type check** (`tools/harness/typecheck.sh`, luau-lsp built from the pinned commit): default mode, which is what Studio's
  Script Analysis shows, reports **0 type errors and 0 other diagnostics** (pass 4's baseline had 4 style notes). `--strict
  --api-only` reports 53 findings, all inference artefacts of forcing `--!strict` on an untyped module, none a Roblox API mistake:
  mixed-type tuple tables (the `MAT` palette and `CRATERS`), locals reset to nil, a nil-guarded reassignment, the generic `new()`
  helper, and `pe()` converting a NumberRange Size to a NumberSequence (the same known false positive as pass 4).
- **Install:** the module is 82.6 KB. Regenerate the Studio payloads with `roblox/install/make_payloads.py` before installing (the
  kit's README says to run it before every install; payloads made from an earlier revision are refused by their own checksums).

## Known weaknesses (honest)

- **By day the white particles are still subtle** at Milo's 40-stud framing (white on sand and sky). The dark rim smoke, ash and
  shards carry the day; at night all particle systems read clearly. More would need bigger or more opaque particles than the opacity
  rules allow.
- **The owner's default camera view is very full**: from 16 studs behind, the dial fills the top of the screen and the orbs loom in
  the top corners (the character itself is never covered). The spec accepts this (§19); `CLOCK_DIST` / `CLOCK_HEIGHT` are tunable.
- **The moon reads as a grey cratered ball rather than a glowing moon** by day (Highlight fill plus shading); the craters are flat
  grey discs from far away. At night its key light and halo help.
- **The photon ring is a 14-sided polygon** that shows its facets from close up (fine from ~20 studs).
- **The equator band still crosses the chest** as a thin dark line from a level front camera (by design: bands cross in front).
- **The Highlight flattens the silver** in the preview (a 45 % fill); in Studio it may look more matte than "polished metal".
  `HIGHLIGHT` can be switched off by attribute to compare.
- **Fallback textures** (before te5 is uploaded): the ribbon and streams are thin lines and the inlay is pass 4's fine-line dial, so
  the clock face reads less well than with te5. The pass-5 look needs the te5 upload.
- **te5_ash is 256² with a 2×2 flipbook.** Roblox's API says "Particle texture must be 1024 by 1024 to use flipbooks". Re-export it
  at 1024² (512 px cells) before uploading, or the ash will not animate as separate flakes.
- Cost: 360 CFrames per frame per wearer plus 1 Highlight; fine on paper for a 1-in-a-billion aura, but only the MicroProfiler can say.

## Studio-verify list (all marked `-- STUDIO-VERIFY:` in the code)

1. Disc emitter `ShapePartial` = inner-radius fraction (rim glints sit on the bezel annulus).
2. Cylinder + Surface + Inward (void swirl, funnel) and Sphere + Surface + Inward (palm intake) converge as intended.
3. `LockedToPart` particles ride a host moved by `BulkMoveTo` (void swirl, galaxy motes, funnel, rim glints).
4. WedgePart orientation for the heart spikes (right angle at −Y, +Z; swap the halves' ±90° if they come out hollow).
5. SurfaceGui `Face = Back` on the inlay plane (XII up, not mirrored) and `Face = Left` on the sub-dial cylinder.
6. Top-face canvas orientation (galaxy arms must trail the spin).
7. Beam `TextureSpeed` direction (streams flow into the palms, the ribbon flows down).
8. The Highlight on a Model of 200+ parts (look and cost); the cyan sky tint really neutralised.
9. Neon black void renders pure black under Bloom.
10. PointLight on an attachment of a BulkMoveTo-moved part follows it.
11. te5_streak with `VelocityParallel` leads with its top (flip the PNG if streaks fly tail-first).
12. te5_ash flipbook needs a 1024² texture (see above).
13. `MeshPart.RenderFidelity` may not be settable at runtime (wrapped in `pcall`; harmless).

Install and test order: spec §18.4 (first with TEX5 empty, then with te5 uploaded).

## Render set (`docs/the-end/pass5-renders/`)

Preview renders (harness + three.js renderer), **not Studio screenshots**. Unless the name says `te5`, they use the fallback textures
that the module uses until te5 is uploaded.

| file | what it shows |
|---|---|
| `01_day_studio.jpg` | Day, the camera of Milo's pass-4 screenshots (40 studs, front) |
| `02_night_studio.jpg` | Night, same camera: inlay and galaxy glow, the corona rings the bezel |
| `03_day_front34.jpg` | Day, front 3/4: the clock stands beyond the wearer, orbs at the sides, the dais pool |
| `04_day_back_owner_view.jpg` | Day, behind and above (the owner's usual view): the dial faces you over the shoulders, nothing covers the character |
| `05_night_back_owner_view.jpg` | Night, owner's view |
| `06_day_side.jpg` | Day, from the wearer's right: the clock still faces the viewer, beyond the wearer |
| `07_day_far.jpg` | Day, 130 studs: particles and fine detail dropped (far LOD); the silhouette still reads |
| `08_clock_closeup.jpg` | Clock close-up (spec view P6): bezel, chapter ring, rete, sub-dial, gears behind the dial |
| `09_assembly_strip.jpg` | The equip assembly, 0.6 s to 6.5 s |
| `10_te5_day_studio.jpg` | After the te5 textures are uploaded: day, studio camera (numerals, accretion streaks, ribbon) |
| `11_te5_night_front34.jpg` | After te5 upload: night, front 3/4 |
| `12_te5_clock_closeup_night.jpg` | After te5 upload: clock close-up at night |
| `13_pass4_vs_pass5_day.jpg` | The real pass-4 Studio screenshot next to the pass-5 preview from the same camera |
| `14_contact_sheet.jpg` | All of the above on one page |
