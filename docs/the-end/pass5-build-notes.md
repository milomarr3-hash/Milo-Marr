# THE END pass 5: build notes ("The Last Clock")

Module: `roblox/ReplicatedStorage/AuraFX/TheEnd.lua` (ModuleScript `ReplicatedStorage.AuraFX.TheEnd`), built in the cloud from
`docs/the-end/pass5-spec.md`. **Nothing here has run in Roblox Studio.** It has run in the headless harness (mock Roblox runtime) and
been drawn by the preview renderer (`tools/`), which are strong filters but not Studio. Every engine assumption that only Studio can
confirm is marked `-- STUDIO-VERIFY:` in the code and listed at the end of this page.

Renders for Milo: `docs/the-end/pass5-renders/` (see the list at the end).

**Review round 1** (the last section of this page) changed many of the numbers in the sections above (budgets, decisions 5, 6,
14, 15, the particle tuning, the known weaknesses). Those sections are kept as the record of the first build; where they
disagree, the review-round-1 section and the spec (`pass5-spec.md`, updated to the built numbers) are current.

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
| `08_clock_closeup.jpg` | Close-up from the front and above (orbit 24°, 26° up, 27 studs): bezel, chapter ring, rete, the movement plate behind the dial, the void |
| `09_assembly_strip.jpg` | The equip assembly, 0.7 s to 6.6 s |
| `10_te5_day_studio.jpg` | After the te5 textures are uploaded: day, studio camera (numerals, accretion streaks, ribbon) |
| `11_te5_night_front34.jpg` | After te5 upload: night, front 3/4 |
| `12_te5_clock_closeup_night.jpg` | After te5 upload: the same close-up at night (star window, moon face, accretion) |
| `13_pass4_vs_pass5_day.jpg` | The real pass-4 Studio screenshot next to the pass-5 preview from the same camera |
| `14_contact_sheet.jpg` | All of the above on one page |

## Review round 1

Four critics reviewed the first build: an art director (AD1 to AD10), the wearer's and other players' view (W1 to W14), a
Studio skeptic (F1 to F18) and a code review (CR1-01 to CR1-12). Duplicates were merged (W1 = F3, W2 = F1, W3 = F11, W7a = F12,
F10 = CR1-11, F14b ~ CR1-10). Every priority-1 and priority-2 finding is implemented, and so is most of the priority-3 polish;
the few that were declined or only partly done are listed with the reason. **Still nothing has run in Roblox Studio**: everything
below is harness output, snapshot measurements and preview renders. The spec (`pass5-spec.md`) is updated to the built numbers.

### What changed, and why

**Engine safety**

- **AD2 Luau register limit (P1).** `End.build` was 3 registers below Luau's 200 limit, so one more local anywhere would have
  stopped the module compiling. Long-lived state moved into three tables (`st` for runtime state, `hosts` for carriers, `em` for
  emitters that change later) and build steps into `do ... end` blocks: **70 registers spare**. New tool
  `tools/harness/register_headroom.py` (adds dummy locals until `luau` refuses to compile; `--measure`) and a test in
  `tools/harness/tests/run_tests.py` that fails below 16 spare.
- **CR1-05, CR1-07 attributes.** Read again at every build (set an attribute, then unequip and equip). An upper-case attribute
  that is not a flag warns once (catches typos), wrong types / NaN / infinity are ignored with a warning, numbers are clamped to
  ranges (`RANGES`), the four direction flags take only the sign, and the hysteresis pairs are kept in order.
- **CR1-06 TEX5 values.** `idOf` accepts `rbxassetid://123`, `"123"`, the number 123 and `rbxasset://` / `rbxthumb://`, trims
  spaces, and warns once and falls back on anything else. `pending:<key>` (the preview renderer's placeholder) is still accepted,
  but `roblox/install/make_payloads.py` now refuses to build payloads from a module that contains one, so it cannot ship.
- **F9 texture loading.** At require, one background `ContentProvider:PreloadAsync` over the filled-in te5 ids (never blocks
  require or build). A texture that fails to load is reported once and swapped for its pass-4 fallback everywhere it is used,
  including the flipbook layout; later builds use the fallback straight away. Studio snippet S9 does the same check by hand.
- **F6, F18 particle textures.** `te5_ash.png` is now 1024² (four 512-px flakes): Roblox only animates flipbooks on 1024²
  textures. `te5_streak.png` is now a square 256² (particles are drawn square; the 64×256 capsule was squashed) and is drawn
  2.2× the fallback's size. `patch_tex5.py` refuses to record or patch a Grid flipbook PNG that is not 1024². The palm intake
  emitters are `LockedToPart`, so the streaks keep converging on a moving palm.
- **CR1-08, CR1-09 beam fades.** 21 precomputed steps (≤ 5 % per step) and the step index is clamped, so an alpha slightly
  outside [0, 1] can no longer throw every frame.
- **CR1-10, F14, F13 lifecycle.** `destroy()` destroys the sub-models that far LOD or the near rule had parented to nil, and
  clears every table. `update()` returns early while hidden. If something replaces the hands, the palms fall back to the body
  carriers and the beams are re-pointed on the next event.
- **CR1-12 readability.** The hands use named fields, `GGEAR` became `GGEAR0` (an offset), dead locals were dropped.

**The wearer's camera** (W1 = F3, W2 = F1, W4, W8, W9)

- **Close-camera layout.** Every judgement in the first build was made at Milo's 40-stud screenshot camera, but players play at
  Roblox's 12.5-stud default zoom. A smoothed camera-closeness factor `cz` (0 at 30+ studs, 1 at 14; attributes `ZOOM_FAR` /
  `ZOOM_NEAR`) now moves the clock 16 studs further back and 3 lower and leans it 24° more (so the dial still faces a camera that
  looks down), and brings the orbs 6 studs further from the camera. Measured from the default zoom: camera-to-orb distance
  11.6 → 16.9 studs, and the character is no longer framed by a wall of dial (render `zoom_fp_cmp`, and the `subject` view in
  `tools/check_aura.sh`'s new default view list).
- **Lag cap.** A right-drag or swipe swings the camera at 90 to 720°/s, where the yaw spring trailed 27 to 140° and threw the
  orbs into the lens. The shown lag is now `L·tanh(x/L)` with `L = YAW_LAG_MAX` (22°). Measured: at 180°/s the nearest orb stays
  17.5 studs from the camera (was 4.0), and in a 0.25 s half-turn flick 17.7 (was 3.9).
- **First person** (`FIRST_PERSON_LIFT`): the owner's clock rises 16 studs and tips to face down, out of the level view; look up
  to see it. Solid, no transparency.
- **Near rules.** The rings hide below 10 studs from their centre and return above 11.5 (were 7 / 8: at the common 8.6 to 10-stud
  zoom a ring passed 1.5 to 3.5 studs from the lens). The big bokeh shows only beyond 20 studs (hides below 18).

**Other players** (W3 = F11, W5, W6)

- **Remote ghosting** (`GHOST_REMOTE`). When another wearer's clock, rings or orbs stand between your camera and your character,
  their parts take `LocalTransparencyModifier` in 3 steps (one burst of writes per step) and their GUIs, Highlight and corona switch
  off (GUIs ignore that modifier). Enter at once, leave after 0.6 s clear. Measured with six wearers (`crowd`): the local player's
  view of their own head blocked 61 % → 3 % of samples. New scenarios `pair_behind` and `pair_walkby`.
- **Far silhouette** (W5, AD6). The rete star, the bow and the corona moved from Detail to Core, so far LOD (past ~110 studs) no
  longer strips the clock's silhouette and its night glow in one frame. Far move list 266 → 290 parts (Detail is now 46 parts).
- **Far beacon** (W6): built behind `FAR_BEACON`, **default off**: an ink-by-day, white-at-night spire seen only from far away,
  steady, no pulse. It needs Milo's OK (it changes how the aura looks to the whole server).

**The character matches the aura** (Milo: "floating, flying, sitting, walking")

- **Jumps** (F2). Roblox's default JumpHeight 7.2 lifted the feet past the old fixed 7-stud "flying" threshold, so every jump
  floated the dais. Now hysteresis `AIR_ON` 12 / `AIR_OFF` 9: in the new `jump` scenario the dais never moves and nothing flickers.
- **Sitting** (W7a = F12). `Humanoid.Sit` is read every frame and smoothed: the dais sits at the lower of the ground ray (which
  hits the seat top) and the feet, the clock lowers 3 and comes 2 closer (a throne back), the rings drop 1, the balance wheel rests
  on the dais and the foot drips stop. Measured in the new `seated` scenario: clock vs dais −1.23 → +0.25, rings vs dais −1.19 →
  +0.21, wheel vs dais −0.67 → +0.26 studs. (If the framework keeps its 2.4 hover on a seat, that is the framework's to fix:
  Studio checklist.)
- **Short avatars, slopes** (CR1-01). The clock's height is clamped so its bezel's lowest edge stays 1.2 above the dais; the rings
  lift when their lowest edge would dip into it; the dais follows the ground down at 30/s (up at 8/s). Measured: `small_avatar`
  clock vs dais −0.33 → +0.25, `downhill` −0.26 → +0.25.
- **Floating free** (W10): the balance wheel hangs 0.9 below the soles (was 0.35), so the wearer floats above it instead of
  standing on a hover-disc.
- **Speed** (AD10, W11): a speed state (on above 12 studs/s, off below 8; horizontal only while grounded, so a jump is not a
  flight) adds 4° of clock lean and turns on P12, a short trail of silver streaks behind the body (the 20th emitter). While
  travelling the void and moon smoke thin out (rate and lifetime) so no trail of puffs hangs on the path.
- **Unequip and hides** (CR1-04, F10 = CR1-11, W14). The screen grade starts with the first frame the wearer can see (not on wall
  time at build), eases back in 0.4 s on hide and 0.8 s on destroy instead of snapping, and a quick re-equip takes over the live
  grade instead of stacking a second one. After a hide of more than 0.5 s (e.g. the roll cutscene) the aura fades back in over
  0.4 s instead of popping; the emitters follow only the framework's fade (this also removed the first build's `toggle_visible`
  flicker warning).

**The look** (AD1, AD3 to AD9, F4, F5, F17, W12, W13, CR1-02, CR1-03)

- **AD1 solid dial (P1).** A black movement plate (C12, Ø 24.6, 1 part) closes the skeleton dial from behind, between the centre
  wheel and the big gears, turning with the centre wheel. Grass, paths and sky no longer show through the clock; only the big
  gears' teeth show past the rim. A **star window** (new texture `te5_star_window`, fallback the pass-4 galaxy drawn dimmer) turns
  on it. The GUI sits on the plate itself, so no carrier part was needed (GUIs 11 → 12, the limit), and the moon halo stays.
- **AD3 particles (P1).** Re-allocated inside §14: the ink smoke now boils off the void itself (Sphere surface, 4.5 → 12.5 studs,
  peak 0.30) and silver smoke off the moon (3.5 → 9), both 3 studs back so the orbs' outlines stay crisp (their two carrier parts
  were removed); the swirl (40/s, 0.9), moon dust (16/s, 0.6), galaxy motes (26/s, 0.7) and shards (7/s) grew; air dust became
  fewer and bigger (8/s, 0.22 to 0.40). With te5 the smoke is drawn 1.3× bigger (te5_smoke's curls are wispier than the
  pass-4 puff). Measured by rendering with and without particles (share of pixels changing by more than 24 levels; day studio /
  day back / night studio): **fallback textures 1.2 / 0.9 / 1.8 % → 4.6 / 5.0 / 5.4 %**, **te5 textures 1.1 / 0.4 / 1.6 % →
  3.0 / 2.5 / 3.5 %**. The critic's target (4 % studio, 2 % back) is met with the fallback textures that ship until the upload,
  and with te5 in the back view; te5's day studio view stays at 3.0 % (see "Declined").
- **AD4 moon (P2).** New texture `te5_moon` (a photographic full moon: maria, ~60 craters, rays, no ring). Once it is uploaded the
  white ball, its 6 craters and the halo give way to a Ø 6 grey core with the face on a 9-stud billboard 4.4 studs toward the
  camera (placed every frame), glowing 1.0 → 1.8 at night, outside the Highlight. Until then the geometry moon stays.
- **AD5 void.** The accretion disc tilts 24° toward the viewer (was 15°: nearly edge-on at Milo's level framing), brightness
  1.6; the photon ring has 18 segments (was 14, faceted up close); the lensed arc is 6 longer blocks; the veins are thinner (Neon
  lines shimmer); plus the ink smoke corona above.
- **AD6 night glow.** Corona kept at every distance (above); the moon's key light Range 22 → 26; the moon face glows at night.
- **AD7 silver.** A SATIN token (150, 154, 164) on the odd bezel flutes and odd dais-rim blocks gives the metal light/dark
  structure; the Highlight's day fill is 0.65 (was 0.55), with attributes `HIGHLIGHT_FILL` / `HIGHLIGHT_OUTLINE` for the Studio A/B.
- **AD8 equator** is SATIN silver instead of dark steel: a bracelet, not a censor bar across the chest.
- **AD9 ribbon** body is opaque (Transparency 0 between the end keypoints), so the sand no longer shows through it.
- **F17 Neon** colours are neutral (LUME 240,240,242; VEIN 226,226,228; ARC 210,210,212): Neon saturates any tint.
- **F4 Highlight** fades in over 5.65 to 6.35 s, after every silver part is solid (it painted the still-fading dais rim at full
  strength, a pop). **W12** the galaxy floor and core fade in with the dais base (4.0 to 4.6). **W13** low quality: meridian and
  equator 14 segments (+4), dais rim 16 (−4); still 149 parts.
- **CR1-02 lights** never pop: `Enabled` flips only at Brightness 0; brightness fades with the assembly and the framework alpha.
  **F16** the key light exists on high only (phones' voxel lighting re-lights a moving light in 4-stud blocks). **CR1-03** groups
  returning from the near rule or far LOD are re-parented by the next update, together with that frame's positions.
- **F5, F7, F8 Studio flips.** Each guess that only Studio can settle is now one attribute flip, no reinstall: `FLOW_SIGN`
  (stream and ribbon flow; the ribbon's −0.5 was certainly wrong against the streams' +0.5), `ACC_DIR`, `FUNNEL_DIR`,
  `GALAXY_DIR`, `WEDGE_SWAP`, `STREAK_FLIP`, `FRONT_FACES`, `SWIRL_POINTS` (`roblox/install/studio_checks.md` S8).

**Harness and tools.** 9 new scenarios (`fast_turn`, `fast_turn90`, `camera_flick`, `pair_behind`, `pair_walkby`, `jump`,
`seated`, `small_avatar`, `downhill`; 28 in all), the last six with the Studio-default follow camera. `tools/check_aura.sh` renders
Roblox's default 12.5-stud zoom by default (`subject:-1,0,0.35,12.5`). The pass-4 baseline report was refreshed.

### Declined or only partly done

| Finding | What was done instead, and why |
|---|---|
| AD3 target with te5, day studio view (4 %) | 3.0 % (fallback 4.6 %; te5 back view 2.5 %, target 2 %). More would need bigger or denser smoke across the dial, which Milo asked to keep solid, or a higher rate than §14 allows (≤ 200/s). Judge in Studio, where bloom adds to the white particles. |
| AD4 core Ø 7.8, colour (150, 153, 160), offset 4.05 | **Ø 6, (184, 186, 192), 4.4.** A billboard faces the camera's plane, not the ray: off-axis the 7.8 core poked out of the 9-stud face as a grey crescent at ~25° in the preview. Ø 6 stays hidden from 8 to 130 studs up to ~45°, and a mid-grey core hides any sliver that does show. |
| AD1 star-window carrier, halo dropped | The GUI went on the plate itself (no extra part), and the GUI budget had room for the halo (12 = limit). |
| AD6 key light Range 30 | **26.** The preview cannot judge aura light on the ground (FIDELITY), and a larger moving light re-lights more of the plaza every frame; 26 reaches the ground under the moon and the wearer. A one-line change if Studio says more. |
| W6 far beacon | Built, **default off** (`FAR_BEACON`): it changes what the whole server sees and needs Milo's OK. No beam limit raised (when on, the far beacon replaces the 3 detail beams that are off when far). |
| W7(b) equator swing cut while gliding | Measured worse: `glide` view-blocked 26 % → 39 % with the cut (the band then hangs level across the head line from the follow camera). Kept the swing. `glide` is 31 % now (the ring lift for clearance adds ~5 %). |
| W10 wheel 1.1 below the soles | **0.9.** At 1.1 the wheel's underside came 0.08 above the galaxy-core plane (spec ≥ 0.2); 0.9 leaves 0.28. |
| F7 two rim emitters per host | **One per host** behind `SWIRL_POINTS`: two would make 22 emitters (limit 20). The host's spin still curls each particle's path into a spiral arm. |
| F15 weld each rigid group to one root and move ~45 roots | Not built blind: it changes the move model and only the MicroProfiler can say whether 360 CFrames per wearer cost too much. Added a MicroProfiler step with numbers (checklist 10). |
| CR1-06 reject `pending:` | Kept for the preview renderer, which needs it to show te5 before upload; the payload builder refuses it instead. |
| Strict type check | Default mode (what Studio's Script Analysis shows): 0 errors, 0 diagnostics. `--strict --api-only`: 65 findings, all inference artefacts of forcing `--!strict` on an untyped module (mixed tuple tables, `pe()` turning a NumberRange Size into a NumberSequence); none is a Roblox API mistake. |
| Halo vs inlay plane at the 40-stud studio camera | 0.31 to 0.35 studs between the halo's square corners and the inlay plane's square corners, below §18.2's 0.4. The same in the first build at that camera; both corners are empty texels (rim-only halo, round inlay) and the harness's billboard-cut lint is silent. Accepted; Studio look. |

### Checks run (cloud only)

- **Harness, 28 scenarios:** 0 errors, 0 harness gaps, nothing left behind after `destroy()` in any scenario, no flicker,
  0 new instances per frame, 1 BulkMoveTo per update, 0 steady-state GUI or Transparency writes (only event writes: night ticks
  at dusk, ghost steps, hide/show). 3 warning kinds remain, all `translucent-layer` on the rim-only moon halo and night corona
  (§7.3's allowed soft elements; the lint cannot tell rim-only images from uniform ones).
- **Budgets** (no limit raised): parts 360 / 149 (355 / 146 with the te5 moon), far 290 / 145; emitters 20 / 12; rate ≈ 183/s
  (+14 while the speed trail runs) / 56 (+6); beams 6 / 2; GUIs 12 / 8; PointLights 2 / 0; 1 Highlight; 70 spare registers.
- **Geometry on snapshots** (spec §18.2, new scenarios included): rings vs body ≥ 1.68, rings vs orbs ≥ 2.34, rings vs the
  accretion disc ≥ 0.77, shards vs hands ≥ 1.03, void disc vs the clock ≥ 3.3, clock vs dais ≥ 0.25, rings vs dais ≥ 0.21, wheel
  vs dais ≥ 0.26 (seated, small avatar, slope and jump included), camera to the nearest orb ≥ 16.9 at the default zoom and ≥ 17.5
  in fast turns and flicks; the clock always on the far side after the spring settles; no NaN.
- **View of the wearer's head blocked** (samples, follow camera): idle 3 %, crowd 61 → 3 %, glide 26 → 31 %, the showcase
  framings unchanged (38 % front, 27 % orbit: rings cross the body by design).
- **Renders** (fallback and te5, day and night, 7 views each) compared with the first build side by side and looked at; the
  14 curated renders in `docs/the-end/pass5-renders/` are regenerated from the final module.
- **Typecheck:** default mode 0 / 0. **Payloads** regenerated with `make_payloads.py` and checked (`--check`).
- Module size 111.7 KB (was 82.6 KB).

### New STUDIO-VERIFY items (also in `roblox/install/studio_checks.md`)

14. The te5 moon face covers its Ø 6 core when the moon sits at the screen's edge (no grey crescent at its side).
15. Cylinder emitters with Surface style: do they also emit from the end caps? If the void swirl or the floor vortex sprays as a
    flat sheet: `SWIRL_POINTS = true`.
16. SurfaceGui Back face on the inlay and corona: mirrored or on the wrong side → `FRONT_FACES = true`.
17. Directions, one flip each: streams and ribbon (`FLOW_SIGN`), accretion and swirl (`ACC_DIR`), floor vortex (`FUNNEL_DIR`),
    galaxy arms (`GALAXY_DIR`), heart spikes (`WEDGE_SWAP`), streaks (`STREAK_FLIP`).
18. Remote ghosting: `LocalTransparencyModifier` on another player's anchored aura parts and the GUIs switching off (2 players,
    or S5 `IS_LOCAL = false`).
19. The speed trail appears on runs and flights only (not on jumps) and streams out behind.
20. The neutral Neon colours stay white under Bloom (compare with a white SmoothPlastic part).
21. Auto roll: after the roll's Scriptable-camera hide the aura fades back in (no pop) and the grade never sits over the cutscene.
22. MicroProfiler with 1 and 3 wearers, high and low: under ~0.6 ms of Luau per wearer, `BulkMoveTo` plus Highlight under 1 ms.
23. Sitting on a Seat: does the framework keep its 2.4 hover while `Humanoid.Sit` is true? (A framework fix if so.)
24. te5 textures load (S9 prints each id's status); a failed one is replaced by its fallback with one warning.
25. The default-zoom layout and the first-person lift feel right while playing (the closeness factor uses the horizontal camera
    distance, smoothed).
