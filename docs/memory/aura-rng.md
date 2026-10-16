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

Style lock: black, white and silver only (a faint cool tint is ok). Keep the clock. **No flashes, strobes or flicker.**
Must read by day (bright tropical islands, cyan sky) and by night.

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
  scenarios. Module 126,319 bytes (checksum 822800729), payloads regenerated. **Still not run in Studio**: next step is
  Milo's Mac (`roblox/install/MILO_PROMPT.md`), first with the fallback textures, then with the 19 te5 uploads.

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

## Texture ids in use (pass 4 TEX table)

See the `TEX` table at the top of `roblox/ReplicatedStorage/AuraFX/TheEnd.pass4-live.lua`. Pass-4 uploads:
te4_moon 105160126126488 · te4_void 98346126355034 · te4_inkline 111152711897982 · te4_inktick 99880756430819 ·
te4_dial_outer 138970147678654 · te4_dial_mid 79447855638088 · te4_dial_inner 134434932210706 · te4_hands
120547039021938 · te4_galaxy2 91068008644782 (spares: te4_sigil 117924879451354, te4_line 84223670910110,
te4_tick 74913731926412, te4_galaxy 89197720947386).
