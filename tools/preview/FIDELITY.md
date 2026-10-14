# Preview fidelity: what to trust, what not to

The preview renderer draws harness snapshots so cloud sessions can see an aura without Roblox Studio. This page says how close
it gets, based on the only ground truth we have: **three real Studio screenshots of the live pass-4 aura** from the Mac
session of 2026-10-14. Nothing in `tools/` has ever run in Studio; a render is evidence, not proof. The final check is always
Play mode on Milo's Mac (day and night, glide, back view, low quality).

## How it was calibrated

| capture | when | lighting |
|---|---|---|
| `032409` day | ~8.5 s after equipping (fully assembled) | ClockTime 14 |
| `032418` night | fully assembled | ClockTime 0.3 |
| `032533` night reveal | ~6 s into the equip reveal | ClockTime 0.3, the wearer's ColorCorrection grade still on |

All three used one camera, which both tools now reproduce as **`studio`**: Roblox's Custom camera with Camera Min/MaxZoomDistance
= 40 and `cam.CFrame = CFrame.lookAt(p + f * 38 + r * 8 + Vector3.new(0, 7, 0), p + Vector3.new(0, 6, 0))` set once, which
puts it 40 studs from the CameraSubject focus (HumanoidRootPart + 1.5 up) along front x 38 + right x 8 + up x 1, nearly
level, FieldOfView 70, viewport 1920x913. The moon and the void orbit with a random phase, so for each capture a harness seed
was searched (1-160) that puts them where they were on screen (within ~10-35 px): day seed 58 at t = 8.6 s, night seed 61 at
t = 8 s, reveal seed 96 at t = 6.05 s. `tools/baseline/make_pass4.sh` rebuilds the comparisons:

- `tools/baseline/pass4/compare_day.jpg`, `compare_night.jpg`, `compare_reveal.jpg`: Studio | preview, same camera
- `tools/baseline/pass4/real_*.jpg`: the three screenshots (960 px), `day_sheet.jpg` / `night_sheet.jpg`: the standard views

Probes (`tools/preview/calibration_probe.py`, sRGB, both images at 1920x913; "clock" = brightness percentiles inside the dial
between the hands' pivot and XII, where the real clock is black between fine white lines):

| | Studio | preview now | preview before calibration |
|---|---|---|---|
| day grass (open ground, lower right) | (163, 220, 95) | (157, 207, 94) | (132, 198, 85) |
| day sand | (243, 228, 185) | (235, 226, 181) | (218, 205, 169) |
| clear day sky (median) | (117, 189, 204) | (117, 189, 204) | ~(103, 178, 215) |
| night grass, away from the aura's light | (98, 158, 41) | (101, 156, 51) | (52, 83, 36) |
| night sand (near the aura) | (230, 204, 153) | (215, 201, 145) | (142, 132, 108) |
| day clock interior p10 / p50 / p90 | 3 / 23 / 117 | 4 / 43 / 155 | 42 / 95 / 213 |
| reveal clock interior p10 / p50 / p90 | 0 / 26 / 207 | 0 / 39 / 216 | (n/a) |

What was changed to get there (all in this folder unless noted):

1. **Tone curve**: filmic (the Narkowicz ACES fit) instead of Khronos Neutral. The captures' day and night colours of sand,
   grass and leaves only agree with one consistent night light (~0.45x the day light) once a filmic shoulder is undone;
   under a linear-toe curve they contradict each other. `--tone neutral` keeps the old curve.
2. **Lighting per curve** (`LIGHTS` in `web/env.js`): Milo's place is bright at night (the ground keeps its colour), so the
   night fill is strong and nearly neutral; the old night was ~2x too dark. Sky and fog colours are the colours Studio displays,
   pushed through the inverse curve. The sky is cyan (117, 189, 204), not deep blue; clouds are soft grey-white by day and lit
   grey by night. The ground texture is 4x sharper (it looked out of focus near the camera).
3. **Bloom**: Roblox adds the energy above Threshold back once (Intensity 1) within about Size px. The stock UnrealBloom mix
   added ~3.5x that, spread over hundreds of px, and turned the black clock grey (`bloomWeights` in `web/post.js`).
4. **GUI blending** (`web/guis.js`), the biggest single fix. With a plain linear blend and Brightness multiplying every texel,
   the soft glows and dark ink edges of the real te4 dial textures (Brightness 3-3.4) greyed out the clock's black disc
   (median 95 vs 23). Two empirical rules fix it: faint light texels count for less (alpha^2.2, as if GUIs blended in gamma
   space), and Brightness lifts only the light texels (ink edges stay dark). Beams get the first rule too (thin lines in Studio).
5. **SurfaceGui depth**: a SurfaceGui now hides what is behind its nearly opaque texels (alpha >= 0.6), so mist particles behind
   the black disc stay hidden, as in Studio.
6. **Stand-in textures** (`standins/make_standins.py`) tuned to what the captures show: the tex3 void is a dense black smoke disc
   (solid to ~85% of its radius), the kit smoke is fuller, the spinning swirl ring round the void and the clock's light shards
   are faint, the spark is a speck (not a needle), the mist is lighter, the pulse ring is thinner, and the ground clock ring
   (tex3 gring) has a bold double band, big numerals with four-point stars between them and triangles pointing in.
7. **Harness** (`tools/harness`): camera overrides (`--camera`, `NAME@SPEC`) with the renderer's presets and `studio`; the
   follow camera's focus no longer rises with the hover (Roblox's focus is the HumanoidRootPart + 1.5, and the hover moves the
   body through the Root joint).

## Trust (checked against the captures)

- **Framing and scale.** With the `studio` camera the clock's centre (~(950, 330) of 1920x913) and size (outer ring ~430 px), the
  wearer's feet (y ~490) and the ground ring's extent match the screenshots within a few px. The harness's camera and the
  renderer's `studio` view give identical images, and the harness's `front34` etc. match the renderer's presets.
- **Orientation conventions that pass 4 exercises.** Front-face SurfaceGuis (the dial reads XII at the top, IX left, III right,
  not mirrored); Top-face SurfaceGuis (on the ground ring, numerals near the camera read upside down and run in decreasing
  order left to right, exactly as in the captures, so the "Front face folded back" mapping has the right handedness; the
  absolute angle can't be checked because the ring turns); BillboardGui sizes and camera-space offsets; FaceCamera beams bent
  along the attachments' X axes (the orbit rings are the same ellipses); Disc emitters aligned with EmissionDirection (the
  clock's black smoke forms round the dial's rim, in its plane).
- **Depth order between the orbs and the clock**: the moon in front of the dial at night, behind it by day; the void hidden behind
  the black disc at night (with the matched seeds).
- **Day/night mood**: sky colour, cloud tone, how bright the place stays at night, the black clock reading black on both, the
  white dial lines crisp with a thin bloom halo, the reveal's ColorCorrection grade (desaturated, slightly dark, cool).
- **The assembly timeline** (what has faded in at a given t), because the harness runs the module's own code with the real
  framework's alpha ramp; equip happens at t = 0.1 s in every scenario.

## Approximate (fine for layout and mood, not for final tuning)

- **The GUI rules are fitted, not known.** alpha^2.2 for light texels, Brightness on light texels only, depth at alpha >= 0.6:
  fitted to pass 4's lightdark textures (white lines over a dark ink halo). A texture built differently (mid-grey content,
  coloured ink) may come out differently in Studio.
- **Particles** are a statistical re-simulation with mostly stand-in textures: the amount, shape and darkness of the smoke and
  dust are plausible, not exact. No soft particles (big smoke crossing the ground shows straight cut lines, believed to match
  Roblox); particles sort per emitter.
- **The tone curve** is a fit; Roblox's exact curve, bloom kernel and shadows differ in detail.
- **Light from the aura** (PointLights) on the ground is weaker than in Studio near the aura (night grass near it reads
  ~(109, 164, 58) here, ~(142, 196, 69) in the capture, though the ground in that spot is different scenery).
- **The ground smoke and the galaxy floor** read darker here than in Studio, where the floor near the feet is a whiter haze.

## Don't trust

- **Stand-in textures.** Only `textures/te4/*` are the real images. Everything from the AuraCinema kit, VFX Studio and the pass-1/2
  `tex`/`tex3` folders is a procedural look-alike (`texmap.json`). New pass-5 textures are real only once their PNG is in
  `textures/te5/*/manifest.json`.
- **A BillboardGui behind or crossing SurfaceGui planes.** In capture 032409 the moon sat just behind four dial planes and read as
  a pale ghost; here it reads normally (only the opaque texels cut it). Roblox's "white wedge" (a translucent ring plane cutting
  the moon's sprite with a straight edge) is not reproduced. The harness's `billboard-cut` warning flags these cases: check them
  in Studio.
- **The void's black ball vs its sprite.** A BillboardGui `StudsOffset` along the camera's Z axis shifts the sprite outward on
  screen relative to the part; the renderer does what the API reference describes, but nobody has compared this in Studio.
- **Scenery.** The plaza, paths, palms and clouds are procedural: placement, HUD, the fountain area and Milo's avatar (blocky
  stand-in, no accessories) differ from the place. The sun's direction depends on GeographicLatitude, which is not recorded.
- **Meshes.** Film meshes are procedural stand-ins; other MeshParts are boxes; MeshPart textures and SurfaceAppearance are not drawn.
- **Conventions pass 4 doesn't use** (WedgePart / CornerWedge orientation, Top-face text, beams without FaceCamera, Beam
  Stretch repeats, ShapePartial and Squash maths): from memory of Roblox, visible in the fixtures, unverified.
- **Performance, LOD, graphics-quality levels** and anything time-varying in Studio (flipbook timing, random particle placement).

## For pass 5

- Judge the viewer-anchored clock only from renders made with the harness running **that** camera: `tools/check_aura.sh` does
  this for every view. A preset view of a run made with another camera shows the clock where it was placed for that other camera.
- Solid metal parts tint cyan by day in Studio (the scout's finding); the renderer's Metal reflects its sky the same way and
  draws Highlights, but nothing here has been compared with a pass-5 build in Studio.
- Opaque geometry is the most trustworthy thing in the renderer. Layer stacks of translucent GUIs and particles are the least.

## Re-calibrating with new screenshots

On the Mac (Studio MCP `execute_luau` in a Play session, then `screen_capture`), frame the wearer with the `studio` camera:

```lua
local plr = game.Players.LocalPlayer
local h = (plr.Character or plr.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
plr.CameraMinZoomDistance, plr.CameraMaxZoomDistance = 40, 40
local p, f, r = h.Position, h.CFrame.LookVector, h.CFrame.RightVector
workspace.CurrentCamera.CFrame = CFrame.lookAt(p + f * 38 + r * 8 + Vector3.new(0, 7, 0), p + Vector3.new(0, 6, 0))
```

Note the time since equipping and ClockTime, then compare with the same camera here:
`tools/check_aura.sh MODULE.lua OUT --time T --real-day day.jpg --real-night night.jpg` (writes `OUT/compare_day.png` and
`OUT/compare_night.png`), and `python3 tools/preview/calibration_probe.py real.jpg OUT/renders/day_idle@studio_f*_cam.png`.
To line the orbs up as well, search harness seeds the way `tools/baseline/make_pass4.sh` describes.
