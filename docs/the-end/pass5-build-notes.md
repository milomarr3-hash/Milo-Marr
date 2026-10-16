# THE END pass 5: build notes ("The Last Clock")

Module: `roblox/ReplicatedStorage/AuraFX/TheEnd.lua` (ModuleScript `ReplicatedStorage.AuraFX.TheEnd`), built in the cloud from
`docs/the-end/pass5-spec.md`. **Nothing here has run in Roblox Studio.** It has run in the headless harness (mock Roblox runtime) and
been drawn by the preview renderer (`tools/`), which are strong filters but not Studio. Every engine assumption that only Studio can
confirm is marked `-- STUDIO-VERIFY:` in the code and listed at the end of this page.

Renders for Milo: `docs/the-end/pass5-renders/` (see the list at the end).

**Review rounds 1, 2 and 3** (the last three sections of this page) changed many of the numbers in the sections above
(budgets, decisions 5, 6, 14, 15, the particle tuning, the known weaknesses). Those sections are kept as the record of the
first build; where they disagree, the review sections (round 3 last) and the spec (`pass5-spec.md`, updated to the built
numbers) are current.

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
| `09_assembly_strip.jpg` | The equip assembly, 0.7 s to 6.6 s (studio camera: the rings rise first, as before; at the default zoom they wait for the hands) |
| `10_te5_day_studio.jpg` | After the te5 textures are uploaded: day, studio camera (numerals, accretion streaks, the 56-stud engraved stage) |
| `11_te5_night_front34.jpg` | After te5 upload: night, front 3/4 |
| `12_te5_clock_closeup_night.jpg` | After te5 upload: the same close-up at night (star window, moon face, accretion) |
| `13_pass4_vs_pass5_day.jpg` | The real pass-4 Studio screenshot next to the pass-5 preview from the same camera |
| `14_contact_sheet.jpg` | All of the above on one page; since review round 2 also Roblox's default 12.5-stud zoom (fallback and te5) and first person |

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

## Review round 2

Four critics reviewed the round-1 build (111.7 KB): the art director (AD2-01 to AD2-06), the wearer's and other players' view
(W2-1 to W2-9), a Studio skeptic (R2S-1 to R2S-10) and a code review (CR2-01 to CR2-07): 5 priority-1, 10 priority-2 and 17
priority-3 findings. The art director's verdict: "better built, but not insane yet, and in two places worse than pass 4" (the
moon after the te5 upload, particles adding almost nothing at 36-40 studs, the void reading as a black ball with a faceted
outline, the silver tinting cyan, the default-zoom framing). The first round-2 fixer was cut off by a usage limit part-way
through (lifecycle, moon face, ghost split, near fade, far fade, height ride, layer lift and particle edits were in the module;
none of the tools, textures, install kit or docs). The lead fixer audited every one of its edits against the findings, fixed
what was half done or inconsistent (te5_ash and te5_hairspring no longer matched their PNGs and manifests, so the install kit's
own tests failed; the fallback moon had become a 9-stud white plate; the moon's stream crossed its face; the fix-up hooks held
their own weak keys), finished the rest, and verified it. Every priority-1 and priority-2 finding is done (W2-5's far beacon is built, but whether
it is on by default is Milo's call); of the priority-3 findings, R2S-10 is half done (its second half needs a Studio memory
measurement) and two optional extras were not needed (all below). **Still nothing has run in Roblox Studio**: everything here is harness output, snapshot
measurements and preview renders.

### What changed, and why

**The roll cutscene and the hide/show lifecycle** (R2S-1 = CR2-02, P1)

- `fx.update` now returns **before anything else** while the aura is hidden. Round 1 relied on the mock framework not calling
  update while hidden; the real framework is not in this repo, and if it keeps calling update during the roll film, the grade
  dimmed Milo's film and the whole assembly played unseen (the skeptic measured "first drawn frame at age 4.92"). Now neither
  can happen whichever way the framework behaves. The grade also never starts over a Scriptable camera, never after age 4.5,
  and only the build that took the shared grade last eases it out (a second "own" build no longer kills the first one's grade).
- After a hide of more than 0.5 s the first visible frame **snaps** the yaw spring, the zoom factor, the dais, the height ride
  and the ring lift to where they belong (no springing in from the old pose), forgets the last position (no fake 900 studs/s
  speed spike and speed-trail burst on reveal) and applies the current day/night at once (dusk may have passed meanwhile).
- New harness scenarios `equip_in_cutscene` (the framework keeps calling update while hidden) and `equip_in_cutscene_paused`
  (it does not), with two new lints: `grade-over-cutscene` and `assembly-unseen`. The live pass-4 module trips both; pass 5
  trips neither, in both framework behaviours.

**The moon** (AD2-01, P1; R2S-9)

- The face is now an **opaque 9-stud disc part** (MOONCORE, outside the Highlight) placed 4.4 studs toward the camera and turned
  to face it every frame, with the texture on a SurfaceGui. Round 1's face was a BillboardGui: transparent, so the Silver
  Highlight composited afterwards painted the bezel over the moon's right third in Milo's studio framing. A part writes depth:
  the Highlight, the rings and the moon's own smoke born behind it can no longer veil it (which also settles R2S-9).
- Before the te5 upload (what Milo installs and sees first) the same disc carries **pass 4's moon**, cropped to its disc
  (`ImageRectOffset/Size`, chosen by `applyTex` from a `CROP` table whenever the fallback is in use, including after a failed
  te5 load) and rounded with a `UICorner`, at Brightness 1.0 → 1.7. The cut-off build had put the uncropped te4 image (a moon
  inside a glow ring) on a 9-stud white Neon disc: a white plate with a moon in the middle. The toy ball and its 6 flat crater
  discs are gone.
- The silver stream now leaves from **behind the face's rim** at about 4 o'clock (an attachment on the face disc) and rises
  toward the wearer, so it never crosses the photographic face (at the default zoom it drew a white arc across it).
- The halo billboard stays (15 studs: the face is nearer the camera than the core).

**Particles** (AD2-02, P1; CR2-06; R2S-10)

- The opacity rule changed (spec §7.3): particles with an **opaque core** (motes, glints, streaks, shards, ash) may be up to
  2 studs; only translucent sprites keep the 0.6 cap. At 40 studs a 0.6-stud mote's core was ~3 px.
- Rebalanced inside §14 (the art director's prototype numbers): white particles at Brightness 2.4 by day (just above Bloom: steady
  glints read as light, not grey specks; they grow, hold and shrink, never flash), the void swirl 40 → 28/s but 0.9 → 1.5 studs,
  rim glints 3 → 9/s at 1.9 studs, floor motes 26 → 18/s at 1.2 studs, the void's ink smoke denser (peak 0.30 → 0.16, 5 → 14
  studs: the one particle that reads on the bright sky), the moon's smoke grey-silver (176) instead of near-white.
- **P13 time dust**, the hero system, replaces the two meridian glint emitters (0.4/s each): 16 glints/s born just **outside**
  the bezel's rim, locked to a ring that turns clockwise with the hands, so the clock wears a slow halo of moving light. (Placed
  round the rim, not on it: a white glint on the silver bezel hardly read by day.)
- The floor motes are drawn half size while the camera is close (a second size sequence made at build, swapped only when the
  zoom crosses cz 0.5): at the default zoom 1.2-stud motes passed the lens as white bubbles.
- `te5_ash` is one 256² flake instead of a 1024² 2×2 flipbook: 5 MB less texture memory for a flake of ~20 px, one fewer large
  upload, and no flipbook mode to get wrong (CR2-06: Random would cross-fade each flake into another). The PNG, its generator,
  manifest and sheets are regenerated.
- Measured (share of pixels that change by more than 24 / 60 levels when the particles are drawn; day studio, day back = the
  owner's view, night back): **te5** studio 2.4 / 0.8 % → 3.0 / 1.3 %, back 1.7 / 0.4 % → 2.5 / 1.0 %, night back 2.3 / 0.7 % → 3.2 / 1.4 % (the art director's prototype reached 3.4 / 1.5, 3.1 / 1.3 and 3.4 / 1.6; this measure counts large changes, so the small glints of the time-dust ring hardly register in it, though they read in the renders); **fallback textures** (what ships until the upload) studio 3.6 / 1.4 % → 4.8 / 2.1 %, back 3.5 / 1.4 % → 5.0 / 2.1 %, night back 3.8 / 1.5 % → 4.9 / 2.1 %.

**The void** (AD2-03; W2-7)

- An **event-horizon glow** made of particles: one te5_halo ring a second on the silhouette plane, three alive at once,
  overlapping into a steady rim glow that blooms at night (pass 4's swirl-ring trick; a glow billboard would be cut by the
  accretion plane, which the art director's first prototype showed).
- Finer details: the photon ring is a 0.13-stud hairline of 24 segments (12 on low: 8 read as a white octagon on phones), the
  lensed arc 9 shorter, thinner blocks (6 thick ones read as a separate faceted bracket), the heart a small brilliant star
  (spikes 1.6 / 1.1, were 2.8 / 2.2), and the eight "spider" veins are gone.
- The ribbon is a whip-thin strand curling into the pool (0.45 → 1.3 wide, curves 7 / −8) instead of a black stalk planting
  the void in the dais. The accretion disc's never-seen Bottom GUI went to the moon's face.

**The silver** (AD2-04, P2)

- The tokens are neutral, a hair warm: SILVER (186, 184, 183), BRIGHT (226, 224, 223), SATIN (143, 141, 140); the Highlight fill
  (216, 212, 208). Measured B − R on the bezel by day: round 1 +11 to +19 (the art director measured up to +39 on the crown and
  meridian) → +4 to +10; on the rings at the default zoom +28 / +34 → about +15; at night +1 to +2 (neutral). One step warmer,
  as the art director suggested, would have made the night silver visibly warm, so this is the compromise.
- Close up the Highlight's **ink outline eases off** (AD2-06): 0.35 at 30+ studs, about 0.74 at the default zoom, in 0.05
  steps written only when they change; fill and outline are written separately (CR2-04: a `HIGHLIGHT_FILL` of 1 no longer
  hides the outline).

**Roblox's default 12.5-stud zoom and first person** (W2-1 = AD2-05, P1; R2S-2; W2-3; W2-8)

- The owner's clock stands 32 studs further back at the default zoom (other players' clocks 16, so a passing wearer's clock does
  not slide far away); the orbs come down 5 and 10.5 toward the camera. Measured at 1280×720: the dial spans y 7 to 240 with
  the hands at XII and the hub at y 105 (round 1: XII, the hands and the crown above the frame, hub at y 69); the moon moves out
  of the top-left corner (centre (346, 196), was (259, 93)) and the hands visibly lock at XII during the equip. The crown and bow
  stay just above the frame (at 19° down a 36-stud upright object cannot fit); MILO_PROMPT says to scroll out to ~30 studs to
  see the whole watch. Nothing changes at 30 studs and beyond.
- **First person** follows where the camera looks instead of holding the last yaw: the lifted clock rides in the sky ahead,
  the orbs hang about 97° off the line of sight (outside the field of view) and the palm streams switch off. Before, turning
  90° put the 8-stud void and its smoke straight into the view at ~13 studs. `tools/check_aura.sh --first-person` renders it.
- The **armillary stays upright** while walking: its −18°·g lean laid the dark equator across the head line from the follow
  camera. `glide` view-blocked 31 % → 4 %.
- The rings **fade** out over 0.25 s in three steps before the near rule removes them, and fade back in, so scrolling between
  9 and 12 studs never snaps them.

**Other players** (W2-2, CR2-01 = R2S-4, W2-4, R2S-3, R2S-6, W2-5)

- **Split ghosting:** their clock and orbs ghost (with their GUIs, Highlight and corona) only when they really stand between
  your camera and you, and stay ghosted 1.2 s after; their rings ghost on their own (0.6 s). Round 1 ghosted the whole aura and
  switched its dial off whenever someone just stood beside a wearer. New scenarios `pair_side` and `visit_close`: a friend 5
  studs to the side now sees only the 76 ring parts go see-through.
- Their **beams and particles ghost too** (Beam and ParticleEmitter have the same hidden `LocalTransparencyModifier`; probed at
  build, and if it cannot be written those beams and emitters switch off instead): no dark smoke cloud or ink ribbon stays
  across your character.
- **Layer lift:** every wearer's dais layers sit at their own height (owner 0, others 0.018 / 0.037 by UserId parity), so two
  pools side by side never share a plane (Roblox z-fights coplanar faces as a crawling shimmer).
- **Highlight slots:** on low quality only the owner's aura has a Highlight, and another player's switches off past the detail
  range (Roblox draws at most 31 per client, shared with Milo's other auras).
- **Far remote wearers** update every other frame with both frames' time (springs exact): half the cost for something ~40 px tall.
- **Far beacon** (W2-5): rebuilt as the wearer critic prototyped it (no texture, 8 → 3 studs wide, from above the bow to 280
  studs: a solid ink column by day, white at night, fading in past ~110 studs). Still **off by default**: it changes what the
  whole server sees, so it needs Milo's yes (S8 `FAR_BEACON = true` to try it).

**Feel** (W2-6, CR2-03)

- The clock and the orbs ride a **heavy spring** on the body's height: a 7.2-stud jump no longer throws the 28-stud watch up and
  down. Measured in `jump`: at the apex the clock stays put (its height clamp over the dais holds it) and the moon rises 0.6
  (round 1: clock +4.5, moon +6.5, void +6.3).
- At the 110-stud far-detail switch the lights, the thin streams (and the far beacon the other way) and another player's
  Highlight **fade over 0.5 s** instead of switching in one frame; light Brightness is written only when it changes.

**Texture loading** (R2S-5 = CR2-05)

- Only `AssetFetchStatus.Failure` counts at once; a time-out is asked for once more 20 s later before the fallback is swapped in.
- What the build chose because te5 was there now goes back with the texture: the ribbon to ink (a failed te5 ribbon would have
  been a white strap), the star window's and the moon face's brightness, and the te5-sized smoke, shards and streaks. The hooks
  run only on a failure event and take the object as an argument (a weak-keyed table whose value held its key would never be
  collected).

**Tools** (R2S-7, W2-9, R2S-4 (4))

- `register_headroom.py --opt 0,1,2` (default) compiles at every Luau optimisation level and reports the worst: **64 spare at
  -O1/-O2, 29 at -O0** (a debugging compile keeps constant locals in registers). The test requires ≥ 16 at all three.
- Harness: 4 new scenarios (32), `H.UPDATE_WHILE_HIDDEN`, the two lifecycle lints, per-scenario steady-state start, the
  remote-wearer camera's Focus on the local player (round 1 put it on the remote wearer, which ghosted far views that would not
  ghost in game), snapshots record the plaza top (`world.groundY`), beam and emitter `LocalTransparencyModifier`, and images'
  `ImageRectOffset/Size` and `UICorner`. The `part-writes-per-frame` lint now flags appearance writes on most steady frames
  (event bursts such as ghost steps no longer count; a new broken test module `bad_part_writes` keeps the check honest).
- Preview: the floor at the plaza top (seated renders no longer hide the dais), cropped and rounded images, ghosted beams and
  particles. `check_aura.sh --first-person`. FIDELITY.md says what of this is unverified.

**Install kit** (R2S-8, CR2-07)

- `00_status`, `12_apply` and `90_install_from_file` list the module's **CONFIG overrides** (attributes survive installs and
  rollbacks); the checklist's first line in studio_checks says to clear unexpected ones (S8 `CLEAR_ALL`).
- studio_checks: S5 runs its own copy of the module (unequip THE END before `IS_LOCAL = true`; check the grade and the te5
  fallback with real equips); new checks for the cutscene grade, first person, the ring fade, side-by-side friends, two pools,
  the 110-stud fade, the jump, the Highlight count and texture memory, the `HIGHLIGHT_FILL` 0.65 / 0.8 A/B. README: ~10 piece
  payloads. upload_textures: 19 textures. The install tests' snippet expectations changed because the module did: the low
  bench has 150 parts (was 149) and, on low, a remote stand-in no longer has a Highlight ("OFF on 1 aura" instead of 2).

### Every round-2 finding

| Finding | Status |
|---|---|
| AD2-01 moon (P1) | Done: opaque camera-facing face disc; cropped, rounded te4 fallback; craters and ball removed; stream from the rim. |
| AD2-02 particles (P1) | Done: §7.3 amended, rebalance, P13 time dust (moved outside the rim after looking at the renders), close-zoom mote size. |
| AD2-03 void (P2) | Done: horizon glow, hairlines, small heart, veins removed, thin ribbon; lensed arc 9 blocks. |
| AD2-04 silver (P2) | Done (neutral tokens and a warm fill; one step less warm than proposed, see above); `HIGHLIGHT_FILL` A/B in studio_checks. |
| AD2-05 default-zoom theme (P2) | Done through W2-1's layout (XII and the hands in frame); the 44° lean was not added on top (the dial would read as an ellipse lying back). |
| AD2-06 close ink outline (P3) | Done. |
| W2-1 owner's default camera (P1) | Done (proto B, owner-only extra distance). |
| W2-2 ghost over-triggers (P2) | Done (rings separate; 1.2 s hold for the clock). |
| W2-3 leaning rings hide the head (P2) | Done (upright; glide 31 % → 4 %). |
| W2-4 coplanar pools (P2) | Done (layer lift); same-parity strangers still share planes: Studio check. |
| W2-5 far flex (P2) | Built and documented; default stays off pending Milo's OK. |
| W2-6 jump hop (P3) | Done (height spring). |
| W2-7 photon octagon (P3) | Done (12 / 24 segments). |
| W2-8 ring snap (P3) | Done (3-step fade). |
| W2-9 tool quirks (P3) | Done (plaza ground, local Focus). |
| R2S-1 cutscene interplay (P1) | Done (+ scenarios, lints, studio check 11). |
| R2S-2 first person (P2) | Done (look-follow, orbs back, streams off, `--first-person`). |
| R2S-3 Highlight cap (P2) | Done (owner-only on low; off when far for others); count in studio check 10. |
| R2S-4 ghost misses fx and dais (P3) | Done (fx LTM + fallback; dais layer lift; LTM in snapshots). |
| R2S-5 texture TimedOut / fallback (P3) | Done. |
| R2S-6 far remote cost (P3) | Done (half rate). |
| R2S-7 -O0 headroom (P3) | Done. |
| R2S-8 stale CONFIG attributes (P3) | Done. |
| R2S-9 moon face vs its smoke (P3) | Done by AD2-01 (an opaque face hides smoke born behind it); the `MOON_SMOKE_BEHIND` flag was not needed. STUDIO-VERIFY row added. |
| R2S-10 texture memory (P3) | te5_ash done; the 512² low-quality variants wait for the Studio memory measurement (studio check 10). |
| CR2-01 fx ghosting (P2) | Done (= R2S-4). |
| CR2-02 lifecycle (P2) | Done (= R2S-1). |
| CR2-03 far-detail pop (P3) | Done (0.5 s fade). The optional 0.3 s debounce of `setDetail(false)` was not added: the fade already absorbs a flip-flopping framework (each flip only reverses a fade). |
| CR2-04 outline writes (P3) | Done. |
| CR2-05 texture fallback (P3) | Done (= R2S-5). |
| CR2-06 ash flipbook mode (P3) | Done by removing the flipbook (single flake). The preview's Random flipbook was left as it is: nothing uses it now. |
| CR2-07 S5 runs its own copy (P3) | Done (doc notes). |

### Declined or only partly done

| Finding | Why |
|---|---|
| AD2-04 "one step warmer" | Measured: with neutral tokens the bezel is B − R +4 to +10 by day and +1 to +2 at night; warmer tokens would read visibly warm at night (the style lock is black, white and silver). The Highlight fill carries the day correction instead. |
| AD2-05 lean 44° | W2-1's layout already puts XII and the hands in frame; adding the lean on top tips the dial into an ellipse. |
| AD2-02 "half of P8 on glint5" | It needs a 21st emitter (limit 20). The close-zoom size swap removes the bubbles instead. |
| W2-5 beacon default on | Needs Milo's OK (it changes what everyone in the server sees). |
| R2S-9 `MOON_SMOKE_BEHIND` | Not needed: the opaque face hides smoke born behind it (`ZOffset −3` keeps the rest behind the face plane). |
| R2S-10 512² low variants | Needs the Studio memory number first (studio check 10). |
| CR2-03 debounce | The fade absorbs it (above). |
| CR2-06 (5) preview Random flipbook | Nothing uses Random any more. |

### Checks run (cloud only)

- **Harness, 32 scenarios:** 0 errors, 0 harness gaps, nothing left behind after `destroy()`, no flicker, 0 new instances per
  frame, 1 BulkMoveTo per update, 0 steady-state GUI or Transparency writes. 3 warning kinds remain, the same as round 1: the
  `translucent-layer` lint on the rim-only moon halo and night corona (§7.3's allowed soft elements).
- **Budgets** (no limit raised): parts 360 / 150 (far 299 / 150), emitters 20 / 12, rate ≈ 186/s (+14 while the speed trail
  runs: 200) / 54 (+6), beams 6 / 2, GUIs 11 / 8, PointLights 2 / 0, 1 Highlight, registers 64 spare at -O1/-O2 and 29 at -O0.
- **Self-tests:** `tools/harness/tests/run_tests.py` passes (incl. `bad_part_writes`, pass 4 clean in all 32 scenarios, the
  baseline report refreshed); `roblox/install/test/run_tests.py` 25/25.
- **Measured on snapshots:** default-zoom framing and jump numbers above; `pair_side` / `visit_close` ghost only the ring parts;
  the crowd's six pools sit at 0, 0.018 and 0.037; first-person renders keep both orbs out of view.
- **Renders** (fallback and te5, day and night, the standard views plus first person and the assembly) compared with round 1 and
  the cut-off build side by side; the curated set in `docs/the-end/pass5-renders/` is regenerated (the contact sheet now also
  shows the default zoom and first person).
- Module size 126,319 bytes, checksum 822800729 (was 111.7 KB). Payloads regenerated with `make_payloads.py` and checked (`--check`).

### New STUDIO-VERIFY items (also in `roblox/install/studio_checks.md`)

26. The moon's face disc: the te5 moon not mirrored (SurfaceGui Left face of a cylinder), whole where it overlaps the bezel, no
    grey veil of its own smoke; before te5, the cropped pass-4 moon round (the `UICorner` rounds an image on a SurfaceGui).
27. Rolling THE END (or equipping during a roll film): S2 says `grade: none` while the film plays, and the whole assembly plays
    after it.
28. First person: turning left and right keeps the void and the moon out of the view; the clock rides in the sky ahead.
29. Another wearer beside you: only the rings ghost; between you and the camera: no dark smoke or ink ribbon stays solid
    (`LocalTransparencyModifier` on beams and particles).
30. Two or three wearers 10 studs apart: no crawling seams where the pools overlap.
31. At night, walking past 110 studs from a wearer: the moon's light on the ground fades, never pops.
32. The time-dust ring reads by day and night as a slow halo of glints round the bezel; no flashing.
33. Highlights in a full server: count them (≤ 31 per client), and the owner's tone is never the one dropped.
34. Texture memory on a phone at graphics level 1-3 (F9 -> Memory -> GraphicsTexture) before and after equipping.
35. The `HIGHLIGHT_FILL` 0.65 / 0.8 A/B with the neutral silvers.

## Review round 3

Four critics reviewed the round-2 build (126,319 bytes): the art director (AD3-01 to AD3-09), the wearer's and other players'
view (R3W-1 to R3W-8), a Studio skeptic (R3S-1 to R3S-10) and a code review (CR3-01 to CR3-08): 2 priority-1, 10 priority-2 and
23 priority-3 findings. The art director's verdict, in short: the particles still add little at the framings Milo screenshots,
and uploading te5 made them *weaker*; at Milo's camera pass 5 takes up less of the screen than the pass 4 that is live now; the
void reads as space art (a ball, a Saturn ring, a sticker star, an ink stick to the floor). The wearer's verdict: the close-camera
layout only works at 12.5-20 studs, and between ~22 and ~40 studs the watch towers over the top of the screen again.

Duplicates were merged: R3S-7 = CR3-07 (texture preload by quality), R3S-8 = CR3-03 (the floor motes' size flip), R3S-10 ~
CR3-05 (the grade after a reset), AD3-09 ~ R3W-6 (white sticks round the lens in first person), R3W-8 ~ AD3-02 (ring
segments), AD3-03 + AD3-02 (the lensed bands pay for the rounder rings). Every priority-1 and priority-2 finding is done (R3S-3's
"commit and push" is the one part this session may not do, see below); of the priority-3 findings, R3W-5 and R3W-7's textured
column were declined and R3W-8 is partly done, with the reasons below. **Still nothing has run in Roblox Studio**: everything
here is harness output, snapshot measurements and preview renders.

### What changed, and why

**Particles that read, with te5 and without** (AD3-01, P1; AD3-05, AD3-07, AD3-09, R3W-6, CR3-04)

- **te5_smoke** is a new texture: a dense cauliflower billow (frame coverage 31-36 % of the cell, the core 93 % opaque) that
  dissolves from the edge inward over its last four frames (no frame-to-frame jump: steps under 0.035 in the body, under 0.10
  in the dissolve; the generator checks this). Round 2's wispy curl covered ~30 % of a cell and was mostly translucent, so
  the void's "ink" read as a teal veil over the day sky. The void smoke is now drawn at the fallback's size (the 1.3x te5
  scale is gone) with a stronger core (peak transparency 0.08, was 0.16). Measured on the te5 day render at the default zoom,
  the smoke's median colour went from (93, 154, 148) to (58, 101, 104) (measured before the last opacity step; the final
  curve is more opaque and was not re-measured).
- **The wearer burns with it** (P11, replaces the sole drips: 0.18-stud specks that showed at no framing): silver wisps rise off
  the shoulders and back (te5_smoke, Box surface of the UpperTorso / Torso, 7/s, 3 on low, 1.2 -> 3.4 studs) and sparks stream
  up the body (glint5, 14/s, 6 on low). They are silver, not ink, because from every camera the wearer stands against the black
  dial. They live on the character (in `charStuff`, so `destroy()` removes them), stop while hidden or in first person, and the
  wisps stop while travelling (the sparks keep going: a comet's tail). Measured on the te5 back view, particles now change
  16.2 % of the pixels on the body (0.8 % before).
- **The air** (P6a): the 0.22-0.40-stud motes that never read became a field of slow four-point sparkles (glint5, 14/s, 4 on low,
  3-4.5 s, up to 1.1 studs) through a 44 x 22 x 44 volume round the whole aura. With the 56-stud stage (below) this gives the aura
  pass 4's footprint back as solid, readable work.
- **The floor** (P8a, AD3-07): the te5 motes read as white pearls with a grey rim on the black pool; they are glint5 four-point
  twinkles now, each at its own angle, turning slowly.
- **P5's slot** (CR3-04, option B): P5's 1.9-stud glints sat on the bezel, inside the silver Highlight, which composites over
  them. P5 is deleted (it was on low too, at 3/s); its rate went to the time-dust ring (P13, 16 -> 20/s) and the air's
  sparkles, and its slot to the body wrap (which also replaces the two sole drips). 19 emitters on high (limit 20; 11 on low,
  was 12) and ≈ 194/s by day: one spare slot and no budget raised.
- **Travelling** (AD3-05): grey smoke clouds and dust were left hanging 20-30 studs behind a gliding wearer. While travelling the
  moon's smoke stops, the void's ink thins to 1.5/s (1 on low) and dies young (1.0-1.4 s), the moon dust halves and the body's
  wisps stop: the trail behind is the silver speed streaks and the body's sparks, nothing grey.
- **First person** (AD3-09 = R3W-6): the camera sits inside the floor funnel and just above the palms, so the funnel and palm
  streaks (and the air's sparkles) passed within a few studs of the lens as white sticks. Those emitters are off in first person
  (a new "nearcam" kind); the galaxy ash drops from 8/s to 3/s there.
- Measured, the same way as round 2 (share of pixels changed by more than 24 levels when the particles are drawn; this round's
  renderer): te5 studio 3.5 -> 6.4 %, back 3.2 -> 7.3 %, night back 3.5 -> 6.3 %, default zoom 12.0 -> 14.1 % (more than 60
  levels: 4.8 -> 10.4 %); fallback studio 5.5 -> 6.1 %, back 6.2 -> 7.7 %, night back 5.6 -> 7.0 %. With te5 the particles now
  add about as much as with the fallback (90-105 %; round 2: about 60 %), so the upload no longer makes them weaker.

**The owner's camera from 12.5 to 40 studs** (R3W-1, P1)

- Round 2's close-camera layout ramps out between 14 and 30 studs, so from ~22 to ~40 studs the 36-stud watch came forward
  again and its top left the screen. Now, for the owner only, the clock steps back along the view until a point `FRAME_TOP`
  (9.6 studs, the XII numeral) above its hub is in frame, from the camera's real pitch and field of view. It glides there
  (spring rate 3), never jumps, is capped at 32 studs (more for a larger `FRAME_TOP`), and is off in first person.
  `FRAME_TOP` is an attribute (0 = off, 22.4 = the whole watch with the crown; Milo's call, MILO_PROMPT step 4).
- Measured on snapshots (follow camera behind, pitched down 0.35, XII's height on screen as a fraction from the top; < 0 =
  off the screen): before 0.02 / 0.05 / 0.03 / -0.00 / -0.01 / 0.06 at 12.5 / 18 / 22 / 26 / 30 / 35 studs; now 0.04 / 0.05 /
  0.04 / 0.04 / 0.04 / 0.05. At 40 and 50 studs nothing changes (0.11, 0.19), nor from the 40-stud studio camera.

**The default zoom: orbs, rings and silver** (R3W-2, R3W-3, AD3-02, R3W-8, P2/P3)

- **Orbs** (R3W-3): at 12.5 studs the moon's face was the biggest thing on screen, 40 % of the screen height beside a 45 % dial.
  The orbs now move back (and a little out) as the camera comes close: moon 28 %, void 20 %, dial 41 % at 12.5 studs (18 studs:
  moon 32 -> 24 %). Nothing changes from 30 studs out; in first person they stay back as in round 2, 3 studs further out to the
  sides (first-person renders looking left and right: both orbs out of view).
- **Rings rise after the lock** (R3W-2): at the default zoom the meridian stood between the camera and the dial while the hands
  spun and locked. For the owner's close camera (decided at the first visible frame) the rings now lie flat on the dais until
  the hands lock (3.5 s later), then rise; from 30+ studs and for everyone else they rise first, as before (the assembly strip
  is from the studio camera).
- **Rounder, finer rings** (AD3-02; R3W-8 partly): meridian 28 segments of 0.26 x 0.15 (was 18 of 0.40 x 0.24), equator 22 of
  0.20 x 0.32 (was 18 of 0.20 x 0.4), ecliptic 24 of 0.28 x 0.14 (was 16 of 0.45 x 0.20); pins and the lume hours re-fitted.
  On low the meridian has 18 segments (was 14); the equator stays 14 (below). The 32 extra parts were paid back without raising
  the 360-part limit: the 9 lensed-arc blocks and the ribbon's end carrier (both replaced by the lensed bands below), 2 bow
  segments (10 -> 8, slightly longer: the bow still reads round), 4 dais-rim blocks (28 -> 24) and 6 chapter-ring blocks
  (24 -> 18: its inner edge is dark on the dark star window and the inlay covers its face). Thinner bands also block less:
  "view blocked" showcase_front 38 -> 32 %, camera_orbit 27 -> 20 %, fast_turn90 28 -> 23 %.
- **Silver close up** (AD3-02): the Highlight's day fill grows by up to 45 % as the camera comes close (same 0.05 steps as the
  outline, written only when the step moves), so the rings read silver, not pale cyan, at the default zoom. The warm close-up
  FillColor the art director offered as a second step waits for Studio (STUDIO-VERIFY 44).

**The void** (AD3-03, AD3-08, R3S-6)

- The ink ribbon (a black stick from the ball to the dais from the studio and back cameras: "a lollipop") and the 9-block lensed
  arc are gone. The lensed disc is now two beams on the horizon host: a bright band arching over the shadow (width 1.5) and a
  thinner one under it (0.8), Bezier-curved, flowing, fading in from 0.9 s, slimmer as the camera comes close (x 1 - 0.45 czq,
  so they do not crowd the default zoom). te5_ribbon is dropped from the upload list (18 textures now).
- The heart is smaller (spikes 1.3 / 0.9, were 1.6 / 1.1): a pinpoint inside the lensed band, not a sticker. On low (AD3-08) it
  is the lume ball alone; a single pair of spikes read as a slit pupil.
- **Hairlines** (R3S-6): Roblox draws without anti-aliasing at lower graphics levels and on phones, and the preview uses 4x MSAA.
  The photon ring and the seconds needle now thicken in three bands with camera distance (under 50, 50-95, over 95 studs; 5
  studs of hysteresis, so a resting camera never flips them; low starts one band up): the photon ring is 0.13 / 0.22 / 0.36
  thick, the needle 0.12 / 0.2 / 0.3. The preview has `--aa off` to look at this (tools/preview/README).

**Presence and the stage** (AD3-04, P2)

- The engraving became a stage: 56 studs across (was 40; moved to CORE, since from far away it is the silhouette), a new
  te5_engraving with a guilloché ring, 120 ticks, Roman numerals 3 studs tall at R ~22, stars, an inked minute band with a white
  frame and 60 ticks, lume batons; opaque lines, Brightness 1.0 by day (the ink carries it) and 2.0 at night. The fallback
  (pass 2's gring) is drawn at the same size. Measured on the te5 studio render, the aura now covers 18.8 % of the frame (round 2:
  12.5 %; the real pass-4 capture: 16.6 %).
- The floor's particles (mist, twinkles, ash) moved to their own invisible disc 0.8 studs above the top floor layer (`FloorFx`,
  R3S-5), so they draw over the galaxy whether Roblox sorts a particle by its emitter's part or by the particles themselves. The
  preview has `--sort host` to look at the pessimistic case.

**Other wearers** (R3W-4, R3S-1, R3S-4)

- **Their clock steps back** (R3W-4): each client places another wearer's clock beyond that wearer as seen from your camera, so a
  friend beside or behind you put their solid clock and moon in front of yours (the harness's `pair_side` / `pair_behind` now
  check this: 11 of 11 samples hid the owner's clock before, 0 now). Another wearer's clock and orbs that would cover your own
  clock now step back along your view until they stand 12 studs behind it (a spring, tested where they would stand without
  stepping back, held 1.5 s so they never swing back and forth).
- **Rings leave the Highlight while they fade** (R3S-1): a Highlight paints a part at full strength whatever its
  `LocalTransparencyModifier`, so the near-camera fade and the ghost left a grey, ink-outlined silhouette of the rings. While
  their `LocalTransparencyModifier` is above 0, the ring parts move to a sibling model outside the Highlight's adornee (two parent
  writes each way, only when it flips).
- **Your own pool on top** (R3S-4): the owner's dais layers now sit highest (0.0366), other wearers' at 0 or 0.0183 by user id, so
  your own galaxy never sinks under a friend's where two pools overlap (W2-4 had proposed this; round 2 had it the other way).

**Robustness** (R3S-2, CR3-01, R3S-9, CR3-02, R3S-7 = CR3-07, R3S-8 = CR3-03, R3S-10 ~ CR3-05, CR3-06, CR3-08)

- **Slopes** (R3S-2): the dais was a level plane at the ground height under the root part; on a hill its downhill side floated
  and its uphill side sank. Every 0.2 s three rays (9 studs out, 120° apart) fit the ground's plane; it is used only if all three
  hit, the slope is under ~20° and all three points lie within 0.6 studs of the plane (so stairs and cliff edges keep the level
  dais), and the tilt is smoothed. The dais, its rim and the stage lie along the slope; the rings and the wheel lift with it; the
  clock lifts (at most 4 studs) where the ground rises toward the camera. The rays exclude the aura, the character and the
  framework's container. New harness scenario `slope` (a 10° plaza).
- **Teleports** (CR3-01): after a vertical teleport the 28-stud watch drifted up through the ground on its spring for a couple
  of seconds. A jump of 30+ studs, or 8+ studs vertically, in one frame now snaps everything into place. Scenario `teleport`.
- **NaN** (R3S-9): one NaN in the root's CFrame (a physics fling) poisoned every spring for the life of the aura. `update`
  returns on a NaN frame, a NaN camera keeps its last position, and any NaN that still reaches a spring resets the state and
  snaps on the next good frame. Scenario `nan_frame`.
- **The pass-2 rim texture** (CR3-02): the night corona, the void's horizon glow and the moon halo are sized from where te5_halo's
  ring peaks (r ≈ 0.73); until te5 is uploaded they use pass 2's `rim`, whose ring peak is not known here. A new attribute `RIM_R`
  (default 0.86, a guess from the texture generator) rescales the three of them until te5_halo loads; studio check 14 measures it
  in one capture.
- **Preload** (R3S-7 = CR3-07): instead of every filled-in te5 id at require, each build asks only for the textures it draws,
  once per id, in the background after it is built; a phone on low no longer downloads the six high-only textures. A failed id
  falls back for every key that uses it.
- **Floor twinkle sizes** (R3S-8 = CR3-03): one swap of the size curve at 22 studs jumped ~56 live twinkles 2x in one frame. Now
  five steps (1.3 -> 0.65 studs), each under 20 %, with hysteresis.
- **The grade after a reset** (R3S-10 ~ CR3-05): the screen grade is skipped when the build comes within 12 s of the character
  spawning (was 4 s) or within 15 s of the owner's previous aura being destroyed on another character (a reset or a respawn,
  however long the framework waits before rebuilding).
- **Flags** (CR3-06): `NEAR_HIDE` and `GHOST_REMOTE` are copied into each build's state, so flipping the attribute during an A/B
  never strands rings unparented or a friend's aura ghosted. With a negative `CLOCK_TILT` the height clamp now uses the front
  face (the bezel no longer dips 0.2 studs into the dais rim at -10°).
- **Docs** (CR3-08): spec §15 (attributes re-read at every build), §18.2 check 4 (the saturation rule the lint enforces), the
  module header (the fallback moon is pass 4's moon cropped round on a grey disc). The silvers' "neutral, a hair warm" is put
  to Milo in plain words (MILO_PROMPT step 4); CLAUDE.md's style line is his to change, not this session's.
- **The fallback moon** (AD3-06): pass 4's pale moon at Brightness 1.0 / 1.7 washed into a white plate. It glows less now (0.75 /
  1.25; te5's moon keeps 1.25 / 2.6): its maria read (luminance spread 7.6 -> 9.4 by day, 4.8 -> 6.2 at night).

**The install kit** (R3S-3, R3W-7)

- MILO_PROMPT step 1 has a stop rule: after `git pull`, `make_payloads.py --check` must report this module's bytes and checksum
  (143,408 bytes, checksum 678854451), or the Mac stops and tells Milo. README names the chunk files by the manifest's order.
  The far beacon now has its own step (MILO_PROMPT step 5, studio check 16): two screenshots at 200 studs, beacon off and on,
  shown to Milo, his answer recorded. Upload list, README and studio checks: 18 textures, te5_moon first.
- Studio checks: new 13 (reset), 14 (the rim radius), 15 (hairlines far away), 16 (the far beacon), 17 (wrap up); steps 2, 3, 6
  and 8 describe the round-3 look; eleven new STUDIO-VERIFY rows.

**Tools**

- Harness: scenarios `teleport`, `nan_frame` and `slope` (35 in all) with their own checks (the clock within 1 stud of where it
  belongs after a NaN frame; the dais on the slope's plane); `pair_side` / `pair_behind` check the owner's clock is never hidden
  by the other wearer's; the flicker lint also counts Size writes. The round-2 module fails the new teleport, slope and NaN
  checks; this one passes.
- Preview: `--aa on|off` (no MSAA, like phones), `--sort centroid|host` (sort particles by their emitter's part), a tilted plaza
  for the slope scenario. FIDELITY.md and the READMEs updated.

### Every round-3 finding

| Finding | Status |
|---|---|
| AD3-01 particles regress with te5, nothing on the body (P1) | Done: new te5_smoke, body wrap (P11), sparkle field (P6a), twinkles (P8a); measured above. |
| AD3-02 default-zoom armillary (P2) | Done: finer, rounder rings (28 / 22 / 24 segments, not the proposed 30 / 28 / 26, to stay at 360 parts), fill strengthened close up; the warm close-up FillColor waits for Studio. |
| AD3-03 void "Saturn lollipop" (P2) | Done: ribbon and arc blocks out, two lensed bands, smaller heart. |
| AD3-04 smaller than pass 4 (P2) | Done: 56-stud engraved stage on CORE + the sparkle field; 18.8 % of the studio frame (pass 4: 16.6 %). |
| AD3-05 glide smoke clumps (P3) | Done. |
| AD3-06 fallback moon plate (P3) | Done (0.75 / 1.25). |
| AD3-07 floor pearls (P3) | Done (glint5 twinkles). |
| AD3-08 low heart slit (P3) | Done (ball only on low). |
| AD3-09 first-person needles (P3) | Done (funnel, palm streaks and air sparkles off in first person). |
| R3W-1 clock towers at 22-40 studs (P1) | Done (owner frame fit, `FRAME_TOP`). |
| R3W-2 rings rise before the lock (P2) | Done (owner's close camera only). |
| R3W-3 moon biggest at the default zoom (P2) | Done (orbs back: moon 40 -> 28 % of the height). |
| R3W-4 a friend's clock in front of yours (P3) | Done (their clock steps back; pair checks). |
| R3W-5 face window (P3) | Declined (below); the thinner rings cut "view blocked" by 5-7 points instead. |
| R3W-6 palm intake in first person (P3) | Done (= AD3-09). |
| R3W-7 far beacon never asked (P3) | Asking Milo: done. Textured column: declined (below). |
| R3W-8 low rings 14-gons (P3) | Partly: meridian 18 segments on low; equator stays 14 (below). |
| R3S-1 Highlight vs LocalTransparencyModifier (P2) | Done (rings leave the tone while they fade). STUDIO-VERIFY 36. |
| R3S-2 the dais on a slope (P2) | Done (plane fit; clock lift capped at 4 instead of the proposed extra ray). |
| R3S-3 branch and checksum (P2) | Stop rule and README done. Commit and push: not done by this session (hard rule: no git commit / push); the workflow's own checkpoint commits already track `bad_part_writes.lua` and remove the two dropped PNGs. |
| R3S-4 layer order (P3) | Done (owner on top). |
| R3S-5 particle sort centres (P3) | Done (FloorFx carrier; preview `--sort host`). |
| R3S-6 hairlines without MSAA (P3) | Done (distance bands; preview `--aa off`). |
| R3S-7 preload by quality (P3) | Done (= CR3-07). |
| R3S-8 mote size flip (P3) | Done (= CR3-03). |
| R3S-9 NaN poisons state (P3) | Done. |
| R3S-10 grade after a late rebuild (P3) | Done (12 s; and 15 s after the owner's last aura on another character). The registry fallback the skeptic offered (if the framework rebuilds much later) waits for a Studio report. |
| CR3-01 teleport (P2) | Done. |
| CR3-02 rim radius (P2) | Done (`RIM_R`, studio check 14). |
| CR3-03 mote size flip (P3) | Done. |
| CR3-04 P5 under the Highlight (P3) | Done (option B). |
| CR3-05 grade spawn race (P3) | Done (= R3S-10). |
| CR3-06 live flags, negative tilt (P3) | Done (both). |
| CR3-07 preload (P3) | Done. |
| CR3-08 doc drift (P3) | Done in the spec and the module; CLAUDE.md's style line is Milo's call (asked in MILO_PROMPT). |

### Declined or only partly done

| Finding | Why |
|---|---|
| R3W-5 face window | Fading ring segments near the face line needs per-segment `LocalTransparencyModifier`, and under the Highlight (R3S-1) a see-through segment still paints at full strength unless it leaves the tone model: segments hopping in and out of the Highlight every ~2 s would read as gaps and pops in the silver. The finer rings (bands 0.14-0.15 thick, the equator 0.32 deep) cut showcase_front 38 -> 32 %, camera_orbit 27 -> 20 %, fast_turn90 28 -> 23 % and leave a line, not a block, across the face. Revisit after Studio if it still bothers Milo. |
| R3W-7 te5_column | Sub-pixel ticks on a column seen from 200-300 studs would crawl without anti-aliasing (R3S-6), it is one more upload for a flag that is off by default, and Milo has not said yet whether he wants the beacon at all. The install kit now asks him (part 1 done). |
| R3W-8 low equator 14 | Low quality is held at 150 parts (the phone budget); the meridian, the biggest silver shape at the default phone zoom, got the extra segments (14 -> 18), paid for by the low heart's spike pair (4 wedges, AD3-08). The equator would need 4 more parts. |
| AD3-02 segment counts 30 / 28 / 26 | 28 / 22 / 24 keeps 360 parts without raising the limit; at the default zoom the facets are under a few pixels. |
| AD3-02 warm close-up FillColor | Only if the default zoom still reads cool in Studio (STUDIO-VERIFY 44): the cloud renderer's sky tint is an approximation. |
| R3S-2 extra clock ray | Replaced by the plane fit's own rise along the view (capped at 4 studs), which costs no extra ray. |
| R3S-3 commit / push | This session may not commit or push (workflow rule). Everything is in the working tree with matching payloads and the stop rule. |
| R3S-10 registry fallback | Conditional on how the real framework rebuilds; wait for studio check 13. |
| CR3-08 CLAUDE.md style line | Changing project instructions is Milo's call; MILO_PROMPT asks him. |

### Checks run (cloud only)

- **Harness, 35 scenarios:** 0 errors, 0 harness gaps, nothing left behind after `destroy()`, no flicker, 0 new instances per
  frame, 1 BulkMoveTo per update, 0 steady-state GUI or Transparency writes. The same 3 warning kinds as rounds 1 and 2 (the
  `translucent-layer` lint on the rim-only moon halo and night corona, §7.3's allowed soft elements).
- **Budgets** (no limit raised): parts 360 / 150, emitters 19 / 11, rate ≈ 194/s idle by day (182 while travelling) / 56, beams
  6 / 2, GUIs 11 / 8, PointLights 2 / 0, 1 Highlight; registers 33 spare at -O0 and 67 at -O1 / -O2 (`End.build`).
- **Self-tests:** `tools/harness/tests/run_tests.py` passes (pass 4 clean in all 35 scenarios); `roblox/install/test/run_tests.py`
  25/25 (the patch-TEX5 stand-in fixture dropped its `ribbon` key to match spec §16.1; the test reads the real module when it
  exists, so nothing was loosened). Texture generators: `make_te5_particles.py` and `make_te5_surfaces.py` checks pass;
  `patch_tex5.py status` 18 keys, up to date. Preview `npm test` passes.
- **Measured on snapshots and renders:** the numbers above (XII on screen, orb sizes, particle pixel shares, coverage, view
  blocked, the pair checks, the moon's luminance spread); renders before / after (fallback and te5, day and night, studio,
  back, front 3/4, default zoom, first person, slope, pair) were compared side by side and iterated (two passes on first
  person, one on the slope, one on the smoke's opacity).
- Module 143,408 bytes, checksum 678854451. Payloads regenerated (`make_payloads.py`, 11 pieces) and checked (`--check`).
- Curated renders in `docs/the-end/pass5-renders/` regenerated (same names; 2.1 MB).

### New STUDIO-VERIFY items (also in `roblox/install/studio_checks.md`)

36. A Highlight on parts with `LocalTransparencyModifier`: by day, zoom slowly from 13 to 8 studs, and stand a stand-in wearer 5
    studs beside you. The rings fade with no grey or ink-outlined silhouette and nothing snaps.
37. The owner's frame fit: from 12.5 to 60 studs, camera tilted up and down, XII always in frame; the clock glides, never jumps;
    from the 40-stud studio camera it stands where it always did. Then the `FRAME_TOP` 22.4 A/B for Milo.
38. At the default zoom the rings wait on the dais until the hands lock; at 30+ studs they rise first.
39. The dais on a ~10° hill or the beach lies along the ground; on stairs and cliff edges it stays level; no rocking.
40. The void's lensed bands: an arch over the shadow and a thinner one under it, flowing smoothly, not cut by the accretion plane.
41. Particle sorting: the floor's twinkles and ash draw over the galaxy floor, the swirl over the accretion disc.
42. Hairlines without anti-aliasing (phone / graphics 3-5, a wearer 60-150 studs away): the photon ring and needle do not crawl.
43. Texture memory with one wearer on low: lower than round 2 (low builds no longer load the six high-only te5 textures).
44. The silver at the default zoom by day: silver, not pale cyan; if still cool, warm the close-up FillColor next pass.
45. The void's ink smoke by day reads as black ink on the sky, not a teal haze (after the te5 upload).
46. `RIM_R` (studio check 14): before te5, the night corona hugs the bezel.
47. Two players side by side and one behind the other: the other wearer's clock and orbs step back behind yours and never swing.
48. Reset with THE END on (studio check 13): no grade over the respawn; the assembly plays once.
49. A teleport (`PivotTo` 60 studs up): the aura arrives with you, no drift through the ground.
50. The body wrap on R15 and R6: wisps off the shoulders and back, sparks up the body; nothing in the first-person view.
