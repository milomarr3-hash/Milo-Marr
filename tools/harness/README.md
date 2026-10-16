# Aura harness: run AuraFX modules without Roblox Studio

Cloud sessions can't open Studio, so this harness runs an aura module (like
`roblox/ReplicatedStorage/AuraFX/TheEnd.pass4-live.lua`) against a **mock Roblox runtime written in Luau**, driven by
the real `luau` CLI. It catches the errors Studio would throw, lints the aura for the project's rules (no flicker,
black/white/silver, readable from the default camera, nothing left behind), measures per-frame cost, and writes
snapshot frames for the 3D preview renderer.

It is a strong filter, not a replacement for Studio: see [What it can't tell you](#what-it-cant-tell-you).

## Quick start

```sh
# all 35 scenarios, report + snapshots in tools/harness/out/<module>/
python3 tools/harness/run_aura.py roblox/ReplicatedStorage/AuraFX/TheEnd.pass4-live.lua

# a few scenarios, custom output, extra snapshot frames (frames, or t= seconds)
python3 tools/harness/run_aura.py MODULE.lua --scenarios day_idle,night_idle --out /tmp/run \
    --snapshot "day_idle:t=1,2.5,4" --snapshot "night_idle:600"

# the same scenario under another camera (the aura sees that camera; the snapshot camera is the render camera)
python3 tools/harness/run_aura.py MODULE.lua --scenarios day_idle@studio,day_idle@front34,night_idle@back --snapshot "all:t=8"

python3 tools/harness/run_aura.py --list            # scenario names
python3 tools/harness/tests/run_tests.py            # harness self-tests (+ pass 4 must run clean)
tools/harness/typecheck.sh MODULE.lua               # optional static check against the Roblox API (see below)
```

Output: `report.md` (read this), `report.json` (everything, for tools), `snapshots/<scenario>/frame_NNNNN.json`.
Exit code: `0` clean, `1` the module raised errors, `2` the harness itself failed (crash/timeout/bad arguments).
Needs `python3` and the `luau` CLI (`--luau PATH` or `LUAU_BIN`; default `/home/user/luau-lang/luau/build/luau`).
A full run of pass 4 takes ~10 s on 4 cores.

Options: `--seed N` (all randomness is seeded; same seed = same frames, see SNAPSHOT.md for the one caveat), `--quality high|low` (force),
`--camera SPEC` (override every scenario's camera, see [Cameras](#cameras)), `--mono/--no-mono`
(THE END rules: the palette and opacity lints; on automatically when the file name contains "TheEnd"), `--keep` (keep the generated `.luau` in
`OUT/gen/` for debugging), `--jobs N`, `--timeout S`, `--script` (run a plain script in a default world: unit specs).

## Cameras

Each scenario has its own camera (mostly Roblox's follow camera, 16 studs behind and 6 up). `--camera SPEC` replaces it in every
scenario run, and a scenario named `NAME@SPEC` replaces it for that run only, so one command can run the same scenario under
several cameras in parallel (`day_idle@front34,day_idle@back`). The camera is placed relative to the main wearer every frame,
before the aura updates, so the aura sees it (pass 5's viewer-anchored clock is placed for it), and the snapshot's `camera` is
the camera a renderer should use. SPEC is one of:

| SPEC | camera |
|---|---|
| `front`, `front34`, `back`, `side`, `top`, `far`, `closeup` | the preview renderer's view presets, read from `tools/preview/web/views.js` (azimuth from the wearer's front toward their right, elevation, distance, aimed at the body + a height) |
| `studio` | the camera of the real pass-4 Studio screenshots from the Mac session (032409 day, 032418 night, 032533 reveal): Roblox's Custom camera with CameraSubject focus = HumanoidRootPart + (0, 1.5, 0), Camera Min/MaxZoomDistance = 40, and `cam.CFrame = CFrame.lookAt(p + f * 38 + r * 8 + Vector3.new(0, 7, 0), p + Vector3.new(0, 6, 0))` set once |
| `orbit:AZ,EL,DIST[,TY]` | any angle, as the renderer's `orbit:` view |
| `subject:F,R,U,ZOOM` | Roblox's Custom camera in general: focus HRP + 1.5 up, ZOOM studs out along front x F + right x R + up x U |

Append `/fov=N` for another FieldOfView. The snapshot's `camera.preset` names the SPEC; snapshot folders replace characters
other than letters, digits and `@ . = -` with `_` (`day_idle@orbit:30,10,40` is written to `snapshots/day_idle@orbit_30_10_40/`).
The follow-camera `view-blocked` check is skipped for overridden runs (it is about the default camera). The scenario's own
camera logic still runs underneath, so overriding `far`, `camera_orbit` or `remote_wearer` changes what those scenarios test.
`tools/check_aura.sh` uses `day_idle@VIEW` and `night_idle@VIEW` for its standard renders.

## What it runs

The aura goes through a mock of the client framework `ReplicatedStorage.AuraFX` (contract in
`docs/memory/aura-rng.md`): the module is required once (`script` = `ReplicatedStorage.AuraFX.TheEnd`), `End.pose`
is validated, `End.build(ctx)` is called with `ctx = { char, hrp, hum, quality, isLocal, container }`, then every
frame (dt = 1/60) `fx.update(dt, s)` with `s = { cf, hover, glide, t, now, legLen, ground, alpha }`; `setDetail(false)`
past 110 studs, `setVisible(false)` past 320 studs or while the camera is Scriptable, `destroy()` on unequip. At the
end of every scenario the aura is destroyed and the harness keeps running 1.5 s to look for leftovers.

| scenario | what it exercises |
|---|---|
| `day_idle` | ClockTime 14, idle, Roblox's follow camera 16 studs behind and 6 up |
| `night_idle` | ClockTime 0.3 |
| `showcase_front` | camera in front ~34 studs out, the way Milo frames screenshots |
| `camera_orbit` | the camera circles the wearer once over 20 s |
| `glide` | walks forward on a curve at WalkSpeed 16 (glide ramps 0 -> 1), stops |
| `air` | rises 8 studs/s; the 60-stud ground ray loses the floor (ground = nil) |
| `dusk` | ClockTime sweeps 17 -> 19.5 (day/night blending) |
| `low_quality` | `ctx.quality = "low"`, touch device |
| `remote_wearer` | someone else wears it (`isLocal = false`), viewed from 30 studs |
| `far` | 20 -> 150 (setDetail false) -> 400 (setVisible false) -> 20 studs |
| `toggle_visible` | Scriptable camera 3-5 s, then rapid hide/show |
| `destroy_mid_assembly` | unequipped 2 s in; late callbacks still fire |
| `reequip` | equip, unequip, equip again (module-level state) |
| `respawn` | the wearer dies; aura destroyed; new character; built again |
| `join_wearing` | joined already wearing it (`time() < 20`) |
| `r6_character` | R6 rig (`Torso`, `Left Arm`, `RootJoint`, HipHeight 0) |
| `film_meshes_present` | fake `ReplicatedStorage.AuraCinema.Assets.TheEnd` (RingG, Dial, Astrolabe, Hand, Gear, Oblivion.Moon / SmoothSphere) with deliberately varied native sizes/orientations |
| `film_meshes_absent` | that folder exists but is empty (fallback path) |
| `crowd` | six wearers at once (cost scaling, Highlight cap) |
| `fast_turn`, `fast_turn90` | the follow camera orbits at 180 / 90 deg/s for 2 s (a right-drag or a swipe) |
| `camera_flick` | the follow camera flicks half a turn in 0.25 s (a mouse flick) |
| `pair_behind`, `pair_walkby` | a second (remote) wearer stands / walks between the local wearer and the camera |
| `jump` | Roblox's default jump (JumpHeight 7.2, gravity 196.2) every 2 s |
| `seated` | the wearer sits on a Seat (`Humanoid.Sit`, `SeatPart`): the ground ray hits the seat top |
| `small_avatar` | a short R15 (HipHeight 1.4), idle then walking |
| `downhill` | walking while the ground drops 6 studs/s (the plaza part moves down) |
| `equip_in_cutscene`, `equip_in_cutscene_paused` | equipped while the roll cutscene's Scriptable camera holds the screen (0-5 s); the first keeps calling `update` while the aura is hidden, the second does not (the real framework is not in this repo, so both are tested): the assembly and the screen grade must wait for the player |
| `pair_side` | another wearer stands 5 studs to your side (friends side by side: nothing of theirs is in your way); with `pair_behind` it also checks that nothing solid of theirs hides your own clock's hub or XII from your camera (`own-clock-hidden`) |
| `visit_close` | a player without the aura stands in front of a wearer, then walks round to their side |
| `teleport` | the wearer is teleported 60 studs up and back down (no hide): the clock and orbs must arrive with them (`teleport-lag`) and the speed trail must not fire (`teleport-trail`) |
| `nan_frame` | one update gets a NaN hover, another a NaN HumanoidRootPart CFrame (a physics fling): no part may keep a NaN position and the clock must ride where it did (`nan-state`) |
| `slope` | the plaza is a 10-degree slope; idle, then walking uphill: the dais must lie along it and no rim block may sink into it (`slope-dais`); snapshots record the tilted plaza and the renderer tilts the ground |

The world: a plaza part at y = 0 (the only thing rays hit), the camera, `Lighting` with the place's Bloom
(Intensity 1, Size 24, Threshold 2), players `Player1` (local) ... with R15 characters built like Roblox's
(HumanoidRootPart, Lower/UpperTorso, Head, arms, hands, legs, feet; Motor6Ds `Root`, `Waist`, `Neck`,
`LeftShoulder` ... `RightAnkle`; the usual rig and accessory attachments, `RightGripAttachment` etc.; Humanoid with
Animator; an accessory). `End.pose` is applied to the rig, so snapshots show the floating pose.

## What it catches (as errors, like Studio)

The mock's classes, members, types, enums, read-only flags and defaults come from Roblox's API
(`api/roblox_api.luau`, generated from luau-lsp's definitions + the Full-API-Dump, see `gen_api.py`). So:

- `X is not a valid member of Part "Folder.Part"` for unknown properties/children (reads and writes), with Roblox's
  full-name format; `Unable to create an Instance of type "X"` for unknown, abstract or service classes.
- `Unable to assign property Size. Vector3 expected, got number` - type checks for every datatype, `bool` strictness,
  instance refs of the right class (`Attachment expected, got Part`), enums of the right enum (numbers and names are
  coerced like Roblox: `Invalid value "Neonn" for enum Material`).
- Read-only members (`ClassName`, `Humanoid.MoveDirection`, `Camera.ViewportSize` ...) and write-restricted ones
  (`MeshPart.MeshId`: "Script write access is restricted"); members a game script may not touch.
- Datatype rules: NumberSequence/ColorSequence (2..20 keypoints, starts at 0, ends at 1, ordered), NumberRange
  (min <= max), bad arguments (`invalid argument #2 (Vector3 expected, got number)`), immutable values.
- Parent locked after `Destroy`, circular parents, `Expected ':' not '.'`, `WaitForChild` that never resolves
  (warning after 5 s like Studio, error at the end), yielding inside `require`/`build`, TweenService on
  non-tweenable types or unknown properties, `BulkMoveTo` with mismatched or non-part lists, CSG at runtime on the
  client, HTTP requests (HttpService is OFF in Milo's place), `loadstring` (nil on clients).
- Runtime errors in the module's own code (`attempt to index nil with 'Y'`), with the module's file and line,
  scenario, frame and a stack trace. An error that repeats every frame is reported once with a count.
- The fx contract: `build` must return a table with `update`, `setVisible`, `setDetail`, `destroy`; `End.pose`
  shape (numbers, `{ x, y, z }` triples, R15 joint names, suppress 0..1).

## What it warns about

| code | meaning |
|---|---|
| `gui-writes-per-frame` | a GUI property written on most steady frames (stalls Roblox; write only on change) |
| `part-writes-per-frame`, `many-writes-per-frame` | appearance writes on many parts on most steady frames (bursts on events, e.g. the 3 steps of a ghost fade, are not flagged) / very busy properties |
| `instances-per-frame` | `Instance.new`/`Clone` inside update or callbacks after the build |
| `particle-budget`, `emitter-heavy` | estimated live particles (Rate x Lifetime) over budget (4000 high / 1500 low per wearer; 800 per emitter) |
| `lifetime-clamp`, `range`, `segments`, `light-range`, `size-clamp`, `canvas`, `rate` | values Roblox clamps or caps (Lifetime 0..20, LightEmission 0..1, Beam segments 1..1000, light range 60, part size 0.001..2048, huge canvases) |
| `asset-id` | content ids not in a Roblox format (`rbxassetid://<number>` etc.) |
| `palette` | (THE END rules) a colour with saturation > 0.15: outside the black/white/silver lock |
| `translucent-layer` | (THE END rules) an element over 6 studs at a uniform transparency of 0.3..0.8: the pass-5 opacity rule against ghostly stacked planes |
| `billboard-cut` | a solid camera-facing sprite (ImageTransparency < 0.3, inner half of its quad) crosses a SurfaceGui plane, which cuts it in Roblox (the pass-4 "white wedge" on the moon) |
| `flicker` | brightness/transparency reversing 3+ times in a second, or on/off 4+ times (no flashes or strobes); a ParticleEmitter's Size sequence too (it resizes the live particles at once) |
| `grade-over-cutscene`, `assembly-unseen` | a ColorCorrectionEffect under the camera more than 0.6 s into a Scriptable-camera period (it dims the roll cutscene); the void already full size on the first frame after the cutscene (the equip assembly played while hidden; `equip_in_cutscene*` only) |
| `view-blocked` | from the default follow camera, solid aura parts (or opaque SurfaceGui planes) cover the wearer's head in > 40% of samples |
| `leak-instances`, `leak-connections`, `leak-renderstep`, `leak-tweens` | after `destroy()`: instances the aura made still in the game (e.g. on the character or camera), connections still live, bindings or tweens still running |
| `weld-anchors-character`, `weld-mass` | an anchored aura part jointed to the character (anchors the player) / non-massless parts added to it |
| `build-yield`, `update-yield`, `call-yield`, `infinite-yield` | yields where the framework expects an immediate return |
| `pose` | `End.pose` suspicious values (unknown joint name, hover out of range, radians by mistake) |
| `light-shadows`, `instance-new-parent`, `module-warn`, `harness-gap` | shadow-casting lights; `Instance.new(class, parent)`; the module's own `warn()`; an API the mock doesn't implement |

## What it measures (per scenario, in the report)

Instances by class in the aura; BaseParts and MeshParts; parts moved per frame by `BulkMoveTo`; property writes per
frame by `Class.Property` (average over all frames, steady state after the assembly, max, how many frames) split into
update / callbacks / tweens, plus redundant writes (same value again); emitters, the sum of Rate and the estimated
live particles (and a "particle area" for fill-rate); beams and segments; GUIs, images, SurfaceGui canvas pixels;
lights (with shadows); highlights; trails; new instances per frame after the build; Lua time per `fx.update` (real
time in the mock: indicative only); build time; share of frames where the aura blocks the camera's view of the
head; and the cleanup checks above. `report.json` has all of it per scenario (census after the build, at ~10 s and
at the end).

## Snapshots

Default: frames at t = 1, 3, 6 and 10 s of every scenario (`--snapshot none` to skip). Format: [SNAPSHOT.md](SNAPSHOT.md).
They include the posed characters, emitter host history (so particles can be re-simulated) and trail history.
`check_snapshot.py OUT/snapshots` validates frames against the contract (the tests do this for pass 4).

`tests/modules/good_pass5_features.lua` is a small, clean reference for the APIs pass 5 is expected to use (cloning the
film meshes with a fallback, welded gears moved through their root, a viewer-anchored clock on the far side of the
wearer, a night factor written only when it changes, palm beams on the hand's grip attachment, Highlight, bursts).

## What it can't tell you

- **Anything visual.** No rendering, lighting, bloom, transparency sorting, texture loading, flipbook playback, the
  cyan sky tint on metals, Neon colour shift, BillboardGui/SurfaceGui intersection cuts, how particles actually look.
  That is what the preview renderer (and Studio) are for.
- **Physics and the real engine.** Parts don't fall or collide; joints are solved kinematically (welded assemblies
  follow the part that moved, like Roblox, but anchored/unanchored subtleties are not modelled); no network
  replication, StreamingEnabled, LOD or device performance. Raycasts only hit the plaza and parts with CanQuery.
- **The real AuraFX framework.** It is a mimic built from the documented contract and the excerpts in the Mac
  session's transcript (alpha ramp `dt / 0.9`, thresholds 110/320). Assumed: `update` is not called while the aura is
  hidden, the ground ray is 60 studs and ignores the character and the auras. The hover/bob/glide smoothing curves and the pose
  blending are reasonable guesses, so `s.hover`/`s.glide` values are close to, not identical to, Studio's. The R6 pose
  mapping (`Root` -> `RootJoint`, `LeftShoulder` -> `Left Shoulder` ...) is a guess too.
- **Exact engine messages and every rule.** Error texts follow Roblox's wording where known; a few are paraphrased.
  Rules the API data doesn't carry are hand-written (clamps above). The harness is lenient where unsure (e.g. lowercase
  `v.x` on vectors works here) so it never invents errors Studio wouldn't throw. Vector3/CFrame are tables in the mock:
  using them as table keys compares by identity here but by value in Roblox.
- **Performance numbers.** `update us` measures Lua in the mock (property access goes through metatables), useful to
  compare versions of the same aura, not as a frame-time prediction.
- **Real timing.** Time is virtual (`os.clock`, `time()`, `tick()`, `task.wait`, tweens all advance exactly 1/60 s
  per frame); `time()` starts at 120 s (the player has been in the game a while) unless the scenario says otherwise.

When the report shows a `harness-gap`, the module used an API the mock doesn't implement (it returned nil): extend
`runtime/classes_*.luau` rather than changing the aura.

## How it works

`run_aura.py` builds one Luau file per scenario: the module source wrapped in a function whose parameters are the
Roblox globals it uses (so `math`, `string` ... stay native), then the runtime (`runtime/*.luau` in order: prelude,
API table, datatypes, enum, scheduler, instance, lints, classes_parts, classes_services, world, framework, stats,
scenarios, main), the config and the scenario call. It runs `luau -O1` on it (Studio's level; `-O2` inlining would
shift `error(msg, level)` positions), parses the `@@H {json}` lines from stdout, maps generated line numbers back
to `MODULE.lua:LINE` / `harness/runtime/*.luau:LINE`, and writes the report. Scenarios run in parallel processes.

- `runtime/instance.luau` - proxies with `__index`/`__newindex` validation, hierarchy, events, attributes, tags,
  clone (remaps refs inside the clone), destroy (locks Parent, disconnects), WaitForChild.
- `runtime/datatypes.luau` - Vector3, Vector2, CFrame (all constructors, Euler orders, axis-angle, slerp Lerp,
  space conversions), Color3, UDim/UDim2, Number/ColorSequence, NumberRange, Rect, TweenInfo, Random (seeded),
  BrickColor (minimal), Ray, Region3, RaycastParams/Result, OverlapParams, Font, DateTime, Content ...
- `runtime/scheduler.luau` - virtual time, `task.*`, deprecated `wait/delay/spawn`, signals with Roblox's deferred
  behaviour (handlers run at the next resumption point), connection tracking.
- `runtime/classes_parts.luau`, `classes_services.luau` - BasePart/Attachment/Model/joints/Camera/Workspace,
  Lighting, Players, Humanoid, RunService, TweenService (easing, repeat, reverse, cancel on override), Debris,
  CollectionService, HttpService (JSON only), and small services.
- `runtime/world.luau`, `framework.luau`, `scenarios.luau`, `stats.luau`, `lints.luau`, `main.luau`.

## Tests

`tests/run_tests.py` runs:

1. `tests/spec_datatypes.luau`, `tests/spec_instances.luau` (script mode, ~270 checks of datatype math and instance
   semantics against Roblox's conventions);
2. every `tests/modules/*.lua`: 25 small modules with one deliberate defect each (unknown property, wrong enum, bad
   NumberSequence, nil index in update, leaked connection, per-frame GUI writes, strobe, palette, MeshId, infinite
   WaitForChild, read-only write, BulkMoveTo mismatch, per-frame Instance.new, tween of a NumberSequence, pose typos,
   missing fx method, lifetime clamp, HTTP, runtime CSG, weld to the character, bad asset id, yielding require,
   Vector3 as Color3, an infinite loop) whose `-- EXPECT` header names what must be reported, plus two modules that must come out
   clean (`good_minimal`, and `good_pass5_features`, which uses film meshes, Highlight, a viewer-anchored clock,
   welded gears, a ClockTime night factor, palm beams, trails and bursts);
3. the real pass-4 module across all scenarios: it runs in Studio without errors, so any error here is a harness bug;
   its 75 snapshot frames are validated against the contract;
4. with `LUAU_LSP` set, the static type-check of three broken modules and the clean pass-5 feature module.

`tests/make_modules.py` regenerates the broken modules. `--update-baseline` refreshes `baseline/pass4-report.md`.

## Baseline

`baseline/pass4-report.md` (+ `.json`) is the pass-4 run (live in Studio): clean, with one design warning - from
the default camera the pass-4 clock covers the wearer's head in ~70-80% of samples (DialInner/DialMid/DialOuter/Hands/Void),
which is exactly what the pass-5 art direction set out to fix (viewer-anchored clock). Compare a new pass against it.

## Static type-checking (optional)

`typecheck.sh` runs luau-lsp's command line (`luau-lsp analyze`) with luau-lsp's Roblox definitions and a generated
sourcemap that places the module at `ReplicatedStorage.AuraFX.<Name>`. It reads every code path, including the ones no
scenario executes:

```sh
LUAU_LSP=/path/to/luau-lsp tools/harness/typecheck.sh MODULE.lua                      # like Studio's Script Analysis
LUAU_LSP=/path/to/luau-lsp tools/harness/typecheck.sh --strict --api-only MODULE.lua  # Roblox API mistakes only
```

`--strict` checks the file as `--!strict` (the module itself is not changed); `--api-only` keeps only diagnostics about
the Roblox API: unknown members of Roblox classes, the wrong enum, the wrong datatype. On the test modules it flags
`Key 'Transparancy' not found in external type 'Part'`, `Expected 'Enum.PartType' but got 'Enum.Material'` and
`Expected 'Color3', but got 'Vector3'` at their exact lines. It cannot see runtime-only rules (MeshId being
write-restricted, NumberSequence keypoint rules, leaks...): that is the harness's job. Code that sets properties
through a generic helper (`new(class, props)`, `o[k] = v`) is invisible to it, and in `--strict` such helpers produce
type noise. Baseline for pass 4: `baseline/pass4-typecheck.txt` (default mode: 0 type errors, 4 style notes;
`--strict --api-only`: 6 findings, all the same known false positive).

Getting luau-lsp: on the Mac, install the release binary (e.g. `rokit add JohnnyMorganz/luau-lsp` or download it from
the luau-lsp GitHub releases). In a cloud container without release downloads, build it (~25 min on 3 cores):

```sh
git clone --depth 1 https://github.com/JohnnyMorganz/luau-lsp && cd luau-lsp
# its `luau` submodule is pinned; a luau checkout at the same commit works: ln -s /path/to/luau luau
CC=clang CXX=clang++ cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DLSP_WERROR=OFF
ninja -C build Luau.LanguageServer.CLI     # -> build/luau-lsp
```
(`-DLSP_WERROR=OFF` because GCC 13 reports a false `-Wmaybe-uninitialized` that `-Werror` turns into a build failure.)
`DEFS=` points the script at the definitions file (`luau-lsp/scripts/globalTypes.d.luau`); without it the script
looks next to the binary's source tree or downloads it once. `tests/run_tests.py` includes the type-check tests when
`LUAU_LSP` is set.

## Refreshing the Roblox API data

```sh
curl -sSLo /tmp/dump.json https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Full-API-Dump.json
python3 tools/harness/gen_api.py --defs PATH/luau-lsp/scripts/globalTypes.None.d.luau \
    --defs-full PATH/luau-lsp/scripts/globalTypes.d.luau --dump /tmp/dump.json --dump-version "$(curl -sSL \
    https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/version.txt)"
```
Current data: Roblox 0.742.0.7421053, luau-lsp definitions at commit 6f90396.
