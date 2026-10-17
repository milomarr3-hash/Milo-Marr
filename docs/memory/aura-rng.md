# Aura RNG — project memory

This file is the long-term memory for Milo's Roblox game, kept in the repo so cloud sessions (which can't see Milo's Mac or
his claude.ai chats) can pick up the work. Update it at the end of every session: what changed, what's next.

## The game

- **Aura RNG** — a Roblox RNG game: players roll auras of different rarities and equip them. The top aura is
  **『 THE END 』 (1 in 1,000,000,000)**. It has a roll cutscene (the "film", which Milo loved) and an *equipped* aura VFX
  (what you wear after rolling it). Current work is the **equipped** VFX, not the cutscene.
- Studio place: "milos place", placeId 132315219934780 (Milo's main game).
- The real project lives on Milo's Mac, **not in this repo**:
  - `~/Documents/AuraRNG-overnight/` — project folder (`CLAUDE.md`, `docs/PROJECT_BIBLE.md`, `CHANGELOG.md`, `scripts/` disk
    mirrors of the Studio scripts, `aura_work/` texture generators + captures, `backups/`).
  - `scripts/AuraFX.lua` — the client aura framework (ModuleScript `ReplicatedStorage.AuraFX`, run from
    `StarterPlayerScripts.AuraRNG_AuraFX`).
  - `scripts/AuraFX_TheEnd.lua` — THE END's aura (ModuleScript `ReplicatedStorage.AuraFX.TheEnd`).
  - `scripts/AuraCinema_TheEnd.lua` — THE END's cutscene; lines ~853-940 build the film's clock from meshes in
    `ReplicatedStorage.AuraCinema.Assets.TheEnd` (RingG, Dial, Astrolabe, Hand, Gear …).
  - Local Claude Code memory: `~/.claude/projects/<project>/memory/project-aura-rng.md`.
- Milo's local Claude Code drives Roblox Studio through the **Roblox Studio MCP** (`execute_luau`, `screen_capture`,
  `start_stop_play`, `upload_image`, …). Cloud sessions have **no Studio access** — they write code/textures here, and the
  local session (or Milo) installs them.

## How cloud work reaches the game

1. Cloud session writes the module / textures into this repo (`roblox/`, `textures/`) and pushes the branch.
2. On the Mac, Milo's local Claude Code (or Milo by hand) installs it into Studio: see `roblox/install/README.md`.
   New textures must be uploaded from the Mac (Studio MCP `upload_image`, or Studio's Asset Manager → Bulk Import) and
   their ids filled into the module's `TEX` table.
3. Test in Studio Play (day + night, glide, back view, low quality), screenshot, iterate.

## Milo's direction for THE END's equipped aura (verbatim, in order)

1. "improve all vfx tenfold ... start on THE END ... the actual vfx/aura ... make sure the actual roblox character matches
   with the aura (floating, flying, sitting, walking, etc.)"
2. "it needs to be tenfold better ... this is the best aura in the game, the vfx should be insane, not just lines, and
   transparency."
3. "it needs to scale up so much bigger ... the light flashes are annoying ... make it 100x better, use the vfx plugin i got too"
4. (a brief he pasted) cinematic cosmic phenomenon; two opposing energies (lunar silver core vs void core with a white
   heart); orbital ribbons; fine particles in 3 scales; layered; custom textures over plain neon; **"KEEP THE CLOCK"**.
5. "KEEP THE CLOCK THOUGH, ITS THE THEME"
6. "work on the vfx, it needs to be ultra realsitic, just like equinox." (Sol's RNG "Equinox" aura is the reference)
7. "go all out, i have 250$ worth of credits from the cloud, make it 1000000x better and ultra realistic, you did insane in
   the cutscene, do the same for the vfx."
8. **Latest (after pass 4):** "it needs so much more work, add depth, so much better particle effects, less transparency and
   more feel toward the build. Go all out, take your time and build it so much better. its getting better though, your on
   the right track."
9. To the cloud session (2026-10-14): "pick up where it left off, go above and beyond ... Make it amazing!"
10. (2026-10-16) "i still think you can make it even better, improve the particle effects and texture tenfold".
11. (2026-10-17, a long brief) "UPGRADE MY EXISTING CELESTIAL VFX — KEEP THE ENTIRE CONCEPT, IMPROVE THE EXECUTION". First:
    "The clock's materials and fine details", "The movement between the elements ... connected through animated energy",
    "The galaxy vortex and particle choreography ... make the particles appear at intentional moments". Keep: the silver
    clock (Roman numerals, gears, central star), the realistic moon on the left, the black void with a white star on the
    right and the dark smoke, white sparkles/fragments, the black-and-white galaxy vortex, **"the gold-and-black circular
    platform with astronomical markings"**, the character at the centre. "a clear buildup, a single strong peak, and an
    aftermath that settles into a beautiful lower-intensity idle state ... Allow brief, controlled flashes only at the
    most important moment." Wearer-only cinematic lighting, restored after; "Do not unexpectedly alter lighting for
    everyone"; "Do not invent uploaded asset IDs"; "Do not change the concept. Upgrade its execution." He also said "THE
    VFX STUDIO IS INSANE, if you need to go ahead and use it" (a plugin on his Mac: the cloud can't reach it).

Style lock: black, white and silver only (a faint cool tint is ok), **plus the gold on the platform** (Milo, 2026-10-17:
"the gold-and-black circular platform"). Keep the clock. **No flashes, strobes or flicker**, except the one controlled pulse
at midnight in the equip reveal (2026-10-17 brief). Must read by day (bright tropical islands, cyan sky) and by night.

## THE END equipped aura — history

- Pass 1-2 (2026-10-13): radiant clock sigil, engraved rings, sun/black-hole pair, galaxy floor. Pass 2 = "scale it up",
  no flashes.
- Pass 3: Milo's brief — moon vs void, ribbons, 3 scales of dust.
- Pass 4 (2026-10-13, live in Studio now): Equinox-style — photographic camera-facing moon/void orbs, 4 fine-line SurfaceGui
  dial layers, 5 Beam orbit rings (inked lines for day readability), galaxy floor, ~6 s equip assembly (void → moon →
  orbits fold in → clock spins up → one soft pulse → ground) and a wearer-only ColorCorrection grade. Exact live source:
  `roblox/ReplicatedStorage/AuraFX/TheEnd.pass4-live.lua` (35000 bytes, checksum 489406639 — see install README).
- Pass 5 (started 2026-10-14 on the Mac, then hit the weekly limit): an 8-agent workflow. Finished: art director,
  Studio scout, code audit, spec writer, 1 texture group. Failed (limit): `tex:orbs`, `tex:dial`, `build:solid-parts`.
  Its outputs are on the Mac in `aura_work/pass5/`. The recovered part of the art direction is in
  `docs/the-end/pass5-art-direction.md` ("The Last Clock": a solid black-steel/silver pocket watch ~28 studs built from the
  film's meshes, viewer-anchored behind the wearer; silver armillary of 3 gimballed rings; solid cratered moon + Neon-black
  void with an opaque accretion disc; galaxy dais bowl; purposeful particles; opacity rules; Highlight to kill the cyan sky
  tint).
- Pass 5 continued in the cloud (2026-10-14): see `docs/the-end/` and `roblox/` for the build and its status.
- Pass 5 review rounds 1 and 2 in the cloud (2026-10-14 to 16; four critics each, then fixers; round 2's first fixer was cut
  off by a usage limit and a lead fixer finished it): opaque camera-facing moon face, neutral silvers, particles with opaque
  cores up to 2 studs and a time-dust ring, an event-horizon glow, the default-zoom layout with XII in frame, first-person
  look-follow, upright armillary, jump height spring, split ghosting of other players' auras (beams and particles too), dais
  layer lift, far-detail fades, hide/show lifecycle that is safe whichever way the framework updates hidden auras, 32 harness
  scenarios. Module 126,319 bytes (checksum 822800729), payloads regenerated.
- Pass 5 review round 3 in the cloud (2026-10-16; four critics, then a lead fixer): particles that read with te5 and without
  (a dense te5_smoke billow, silver wisps and sparks on the wearer's body, a field of four-point sparkles, floor twinkles
  instead of pearls), a 56-stud engraved stage round the dais, the void's ink ribbon and arc blocks replaced by two lensed
  bands, finer rounder rings, the owner's clock stepping back so XII stays in frame from 12.5 to 40 studs (`FRAME_TOP`), orbs
  back at the default zoom, rings rising after the hands lock at the default zoom, another wearer's clock stepping back behind
  yours, the dais lying along gentle slopes, teleport / NaN / reset robustness, `RIM_R` for the pass-2 rim texture, per-build
  texture preload, 35 harness scenarios. te5_ribbon dropped: **18 te5 textures** to upload. Module **143,408 bytes (checksum
  678854451)**, 11 payload pieces; MILO_PROMPT step 1 stops if the Mac's copy reports anything else. **Still not run in
  Studio**: next step is Milo's Mac (`roblox/install/MILO_PROMPT.md`), first with the fallback textures, then with the 18 te5
  uploads. Milo's calls pending: the far beacon (on/off), `FRAME_TOP` 9.6 vs 22.4 (XII vs the whole watch in frame), and
  whether "neutral, a hair warm" silver is ok (CLAUDE.md's style line says only a faint *cool* tint).

- Pass 5.1 in the cloud (2026-10-16, Milo: "improve the particle effects and texture tenfold ... Keep working hard on
  it"): three texture agents rebuilt the textures at film quality (ray-traced tumbling steel shards, a tumbling ember flake,
  a photographic glint, a twinkle flipbook, stardust glitter clusters, a spark fleck, a comet streak, a soft mote, a real
  bokeh disc; ray-marched lit smoke billow / wisp / mistbank that replace te5_smoke; a rendered Moon globe with real maria,
  ~26,000 craters and ray systems; an Interstellar-like accretion disc; a real spiral galaxy for the dais; a Milky-Way star
  window; a braided energy stream). New particle systems: P15 a star halo (a tilted ring of twinkles and stardust 16-21
  studs out, beyond the default camera), P16 a duality helix (a silver ribbon and an ink ribbon braiding up the body), P17
  twinkles inside the dial, P18 sparks where the shards break off. Twinkles and stardust replace static glints; smoke kept
  near upright (baked light). **23 te5 textures** to upload (te5_smoke retired to `textures/te5/particles/retired/`). Module
  **155,147 bytes (checksum 484396720)**, 12 payload pieces. Every smoke/ember emitter takes its pass-4 settings back if
  its te5 texture is missing or fails to load. Still not run in Studio.
- Pass 5.2 in the cloud (2026-10-17, Milo's "keep the entire concept, improve the execution" brief; he wrote it from the pass
  5.1 preview pictures, where the stage looked gold because the sandy plaza showed through it): **the clock**: a near-black
  engraved band in the bezel (its engraving creeps round a degree a second), a polished flange round the star window, a
  faceted eight-point central star (silver and gunmetal facets) over a slowly turning sub-dial, Breguet moon hands, a comet
  of light riding the seconds hand, hour plots that light in turn; **the links**: three thin energy threads with gliding
  pearls of light (moon → IX, III → void, VI → floor), moonlight motes into IX, runners on two rings; **the galaxy**: a fine
  fast swirl and energy rings over the arms, two spiral arms of motes; **the platform**: gold markings on an opaque black
  base (te5_engraving tinted `GOLD`); the moon's glow, ring of glints and libration; the void's Doppler-bright photon ring,
  heart glint, ink tendrils and infall; **the reveal**: hands spin in to five to midnight, a buildup (links light, the dial
  is swept and the plots light I → XII, the gears race, the smoke draws in, a golden sweep round the stage, streaks
  converge), the minute hand ticks five times to XII, **one pulse at midnight** (flare at the hub, floor wave, dial glints
  into orbit, lifting sparks, the moon's ring, smoke blown out), an aftermath that settles by 9.8 s; on the wearer's own
  screen only a bloom and a 6 % push-in, given back exactly. 6 new textures (bezel band, trail, galaxy swirl, energy rings,
  link, shockwave), 2 rebuilt (the gold-and-black engraving, the bevelled dial inlay): **29 te5 textures**. A reviewer
  found and the lead fixed six issues (hide before the buildup cancelled the bloom/push, a runner ran tail-first, frame
  fit vs the push-in, ...). Module **198,845 bytes (checksum 17952987)**, 16 payload pieces. Still not run in Studio.

## Status (cloud, 2026-10-17, pass 5.2)

Pass 5.2 of THE END's equipped aura (pass 5 + review rounds 1-3 + pass 5.1's textures and particles + pass 5.2's execution
upgrade) is **built and verified in the cloud only**. **Nothing has run in Roblox Studio.**

**What's built, and where**
- Module: `roblox/ReplicatedStorage/AuraFX/TheEnd.lua`, **198,845 bytes, checksum 17952987**. TEX5 is empty until the
  upload, so the aura falls back to pass-4 textures (and the four te5-only layers, the bezel engraving, the trail and stage
  sweep, the galaxy swirl and the energy rings, are not built). Live pass 4 for rollback and diffing: `TheEnd.pass4-live.lua`
  (35,000 bytes, checksum 489406639).
- Budgets (high / low): 454 / 163 parts in one BulkMoveTo (459 with te5), 43 emitters (34 on by day) / 12 on, about 343 / 78
  particles per second (about 891 / 164 alive), 9 / 4 beams, 11 / 8 GUIs (16 with te5), 2 / 0 PointLights, 1 Highlight.
  Registers: 29 spare in `End.build` at -O0, 65 at -O1 and -O2.
- New flags: `LINKS`, `REVEAL_BLOOM`, `REVEAL_PUSH` (all on). Reveal constants: `ASM_END` 7.0, `REV_BUILD` 4.6, `PEAK` 6.6,
  `REV_END` 9.8 (spec §12 has the timeline).
- Textures: 29 te5 PNGs (11 particles, 3 smoke, 15 surfaces) in `textures/te5/`, with their generators, manifests and contact
  sheets. `patch_tex5.py status`: 29 keys, 0 filled.
- Docs: `docs/the-end/README.md` (status page for Milo, with pictures from `pass52-renders/`), `pass5-spec.md` (§9 rows
  P19-P31, §12 the reveal, §14 budget, §15 flags, §16 textures), `pass5-build-notes.md` ("Pass 5.2", STUDIO-VERIFY 59-71),
  `pass5-art-direction.md`.
- Install kit: `roblox/install/` (README, MILO_PROMPT, studio_checks (step 2 and new step 17 for the reveal and the
  details), upload_textures (6 batches), patch_tex5.py, make_payloads.py). Payloads: `01_backup`, 16 pieces, `18_apply`
  (18 to run in order), plus `00_status`, `90_install_from_file` and `99_rollback`.

**Cloud tools** (see `tools/README.md`): as before. Pass 5.2 changed the harness's steady state to start 10 s after the build
(the reveal), lengthened the two cutscene scenarios to 17 s, let the palette lint accept the stage's gold, and the preview
now draws `:Emit` bursts from disabled emitters. Preview te5 look: a temp copy with `TEX5 = "pending:<key>"` (never ship).

**Final verification results (pass 5.2, 2026-10-17, all headless)**
- `run_aura.py` (35 scenarios), fallback and te5 previews: 0 errors, 0 harness failures; the 3 known translucent-layer
  warnings only. After the reveal: 0 GUI writes per frame. The field of view returns exactly to 70; the bloom is removed.
- `tests/run_tests.py`: all passed (typecheck included). `install/test/run_tests.py`: 25/25. `typecheck.sh`: 0 diagnostics.
- `make_payloads.py --check`: payloads match (16 pieces). Preview `npm test`: passed. Generators' `--check`: particles 139,
  surfaces 103, smoke 29, all passed.

**Pending**
- First Studio install and Play test with the fallback textures (`roblox/install/MILO_PROMPT.md`, `studio_checks.md`
  steps 1-2), then the 29-texture upload (te5_moon first), `patch_tex5.py`, re-made payloads, and a second test (step 17).
- STUDIO-VERIFY items 1-71: results in `docs/the-end/pass5-studio-results.md`, saying only what was really seen.
- Milo's calls: the far beacon, `FRAME_TOP` 9.6 vs 22.4, the "neutral, a hair warm" silver, and now the reveal's push-in
  and bloom (`REVEAL_PUSH`, `REVEAL_BLOOM`) and the energy links (`LINKS`).
- Maybe later: drop the reveal-only carriers from the move list after the reveal (4 parts); 512² low-quality texture
  variants if Studio's memory measurement asks; R3W-5; the warm close-up FillColor; the R3S-10 registry fallback.

**Next steps**
1. Studio test on the Mac (fallback textures), then the te5 upload and a second test. Fix whatever Studio shows. Iterate
   with Milo's screenshots.
2. Then the other auras. Milo wants "all vfx tenfold better". None of their modules are in this repo yet: copy them from
   `ReplicatedStorage.AuraFX` on the Mac first, and reuse the tooling (harness, preview, install kit) for each.

## Framework contract (from the pass-4 module)

- `End.pose = { hover, bob, bobSpeed, idle = {...}, glide = {...}, breathe = {...}, suppress = {...} }` (degrees per Motor6D).
- `End.build(ctx) -> fx`, `ctx = { char, hrp, hum, quality = "high" | "low", isLocal, container }`.
- `fx.update(dt, s)`, `s = { cf (HRP CFrame), hover, glide (0..1), t (os.clock), now (server clock), legLen, ground
  (Vector3 or nil), alpha (fade-in 0..1) }`.
- `fx.setVisible(on)` (parent the folder to `ctx.container` or nil), `fx.setDetail(isNear)` (particles off when far:
  past ~110 studs particles stop, nothing past ~320), `fx.destroy()`.
- Move parts with `workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)`; write GUI/transparency props
  only when they change (never every frame for many GUIs).
- The aura module is looked up by name via `defFor(name)` (`name:gsub("[^%w]", "")`) under `ReplicatedStorage.AuraFX`,
  loaded with `pcall(require, m)` the first time someone wears it.

## Hard-won tech lessons

- AuraFX pauses drawing while the camera is Scriptable; Studio MCP `execute_luau` resets CameraType to Custom.
- A BillboardGui that intersects a SurfaceGui plane gets cut. Trails on slow, big orbs draw as flat polygons (removed).
- Stacked transparent planes sort per object and pop/cut (the white wedge on the pass-4 moon). Opaque geometry writes depth.
- Additive (LightEmission 1) white vanishes on a bright sky; dark ink edges / LightEmission 0 keep things readable by day.
- By day the tropical sky tints Metal/Foil/Glass/SmoothPlastic **cyan**; one `Highlight` per aura model
  (FillColor 205,208,215; DepthMode Occluded) neutralises it. Highlight cap is 31 per client.
- Place Bloom: Intensity 1, Size 24, threshold ~2 (GUI Brightness above 2 blooms).
- Particle Lifetime max 20 s; parts > ~280 studs from the camera may not draw at low fps; Neon shifts colour; per-frame
  writes to many GUI properties cause stalls (BulkMoveTo parts is fine).
- HttpService is OFF in the place and must stay off. Never publish, never change place settings.
- Textures are code-generated PNGs (python3 + numpy + PIL), max 1024×1024, uploaded from the Mac. Record every id.
- Milo's Mac has 8 GB RAM and Studio is heavy — keep execute_luau payloads ≤ ~25 KB and yield in long loops.
- Show Milo screenshots as thumbnails; explain changes in plain words (he's a young, very motivated game dev).
- (Cloud review, unverified in Studio) A BillboardGui is drawn as a transparent object: a Highlight on parts behind it paints
  over it. Faces that must stay whole (pass 5's moon) are opaque parts turned to the camera with a SurfaceGui.
- (Cloud review) Don't rely on the framework pausing `update` while an aura is hidden: return first thing in `update`, so the
  equip assembly and the screen grade wait for the player whatever the framework does.
- Roblox draws at most 31 Highlights per client, shared by every aura: give the owner's aura one, others only while near and
  on high quality. Beam and ParticleEmitter have a hidden `LocalTransparencyModifier` too (used to ghost another player's
  aura).
- Luau's register limit (200 per function) has half the headroom at -O0 that it has at -O1/-O2: check all three
  (`tools/harness/register_headroom.py`).
- (Cloud review round 3, unverified in Studio) A Highlight paints a part at full strength whatever its
  `LocalTransparencyModifier`: to fade parts of a highlighted model, move them to a sibling model outside the adornee while
  they fade. Phones and low graphics draw without anti-aliasing: hairlines (≤ 0.15 studs) need to thicken with distance or
  they crawl. A dais that is a level plane floats on hills: fit the ground plane with a few rays, but keep it level on stairs.
- (Pass 5.2, cloud, unverified in Studio) The silver Highlight's fill also composites over **particles** in front of silver
  parts (as over BillboardGuis): a flare over the silver hub reads weakly by day, so make such effects big enough to reach
  dark parts. GUIs over highlighted silver are washed the same way: put engraving on dark (non-highlighted) parts.
- (Pass 5.2) Anything the reveal does to the player's screen must start only when its moment comes and only if nothing
  hid the aura first in a way that matters: the framework hides the aura under the roll cutscene's Scriptable camera
  before the first frame, so a "hide = cancel" rule cancelled the bloom and push-in on every real equip. Give the field of
  view back to the camera it was taken from, and let go at once if any other script changes it.
- (Pass 5.2) `ParticleEmitter:Emit(n)` works on a disabled emitter: burst-only emitters stay `Enabled = false` (Rate 0).
  A flat expanding floor ring is one particle with `Orientation = VelocityPerpendicular` and a tiny upward speed.

## Texture ids in use (pass 4 TEX table)

See the `TEX` table at the top of `roblox/ReplicatedStorage/AuraFX/TheEnd.pass4-live.lua`. Pass-4 uploads:
te4_moon 105160126126488 · te4_void 98346126355034 · te4_inkline 111152711897982 · te4_inktick 99880756430819 ·
te4_dial_outer 138970147678654 · te4_dial_mid 79447855638088 · te4_dial_inner 134434932210706 · te4_hands
120547039021938 · te4_galaxy2 91068008644782 (spares: te4_sigil 117924879451354, te4_line 84223670910110,
te4_tick 74913731926412, te4_galaxy 89197720947386).
