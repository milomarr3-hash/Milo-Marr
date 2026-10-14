# Snapshot format (harness -> preview renderer)

This is the authority for the JSON frames `run_aura.py` writes to `OUT/snapshots/<scenario>/frame_NNNNN.json`
(one file per captured frame). It implements the SHARED SNAPSHOT CONTRACT the lead set for pass 5, plus a few
**additive extensions** marked *(ext)*. A reader written against the original contract keeps working: no field was
renamed or removed, and every extension is a new key.

## Conventions

- Roblox units and axes: studs, +Y up, right-handed. A `CF` is 12 numbers in `CFrame:GetComponents()` order:
  `[px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22]` (rotation row-major). Columns: X = RightVector,
  Y = UpVector, Z = -LookVector.
- Cylinder parts' axis is local X. Beams curve along each attachment's local X axis (`Attachment.Axis`).
  `BillboardGui.StudsOffset` is in camera space, `StudsOffsetWorldSpace` in world space.
- Colours are `[r, g, b]` on a 0-255 scale (floats). Number sequences are `[[time, value, envelope], ...]`,
  colour sequences `[[time, r, g, b], ...]`.
- `path` is `Instance:GetFullName()` (dot separated, from below `game`), e.g.
  `Workspace.AuraFX_Auras.TheEnd_Player1.Moon`. `id` is a stable integer per instance within one scenario run.
- Absent references are JSON `null` (never a missing key) for the fields the contract lists as nullable.
- Only what Roblox would draw is listed: the aura container's descendants **while the container is in Workspace**,
  plus anything the module created elsewhere that renders (attachments/beams on the character, effects under the
  camera or in Lighting). When `fx.setVisible(false)` has parented the aura to nil, the lists are empty and
  `auraInWorld` is `false`.
- Values are the instance state at the end of that frame (after `fx.update`, tweens and deferred events).
- List order carries no meaning: lists are sorted by path and content. Ids are stable within a run; across runs they can
  swap between instances a module created inside a `pairs()` loop over EnumItem/Instance keys (arbitrary order in
  Roblox too). Same seed + same module = same frames otherwise.

## Top level

| key | type | notes |
|---|---|---|
| `version` | 1 | |
| `scenario` | string | see `run_aura.py --list`; with a camera override, `NAME@SPEC` (e.g. `day_idle@front34`). The folder name is this with characters other than letters, digits and `@ . = -` replaced by `_` |
| `frame` | int | frame index (60 fps, frame 60 = t 1.0 s) |
| `t` | number | seconds since the scenario started |
| `clockTime` | number | `Lighting.ClockTime` (0..24) |
| `quality` | `"high"` / `"low"` | the `ctx.quality` the aura was built with |
| `auraInWorld` *(ext)* | bool | the aura container is under Workspace (false while hidden) |
| `camera` | object | `cf`, `fov` (vertical degrees); *(ext)* `viewport` `[1920, 913]`, `cameraType`, `preset` (the `--camera` / `NAME@SPEC` override that placed it, absent otherwise: see README "Cameras") |
| `wearer` | object | `cf` (HumanoidRootPart; NOT raised by the hover), `hover`, `glide` (0..1), `legLen`, `ground` (`[x,y,z]` hit under the wearer or `null`); *(ext)* `isLocal`, `rig` (`"R15"`/`"R6"`), `alpha` (fade-in) |
| `characters` *(ext)* | array | every wearer's posed rig: `{ name, wearer, parts: [{ name, class, size, cf, color, transparency }] }`. The body floats: the harness applies `End.pose` (hover on the Root joint, idle/glide/breathe angles) to the Motor6Ds, so these CFrames are the visible pose. Draw the avatar from this. |
| `parts`, `attachments`, `beams`, `guis`, `emitters`, `trails`, `lights`, `highlights`, `effects` | arrays | below |

## parts

`{ id, path, class, shape, size, cf, color, material, transparency, localTransparencyModifier, reflectance, meshId, textureId, parentPath }`

- `shape`: `Block | Ball | Cylinder | Wedge | CornerWedge | Mesh` (`Mesh` for MeshPart and unions).
- `material`: the `Enum.Material` name (`SmoothPlastic`, `Metal`, `Neon`, `Glass`, `ForceField` ...).
- `meshId` / `textureId`: MeshPart only, else `null`. The fake film meshes use ids `rbxassetid://7000000000N`
  (not real assets): render them by name/size (`RingG` ring, `Dial` disc, `Astrolabe`, `Hand`, `Gear`, `Moon`, `SmoothSphere`).
- *(ext)* `castShadow`; `meshSize` (MeshPart native size); `specialMesh { meshType, meshId, textureId, scale, offset }`;
  `decals [{ class, face, texture, color, transparency }]`; `surfaceAppearance { colorMap }`.

## attachments

`{ id, path, hostId, worldCf }` - every attachment used by a beam, trail, emitter, billboard or light, and every
attachment under a listed part. `hostId` = the parent part's id (or `null`; a character part is not in `parts`, so
use `worldCf`).

## beams

`{ path, a0, a1, curve0, curve1, width0, width1, segments, faceCamera, texture, textureMode, textureLength, textureSpeed, color, transparency, lightEmission, lightInfluence, brightness, zOffset, enabled }`
- `a0` / `a1` are attachment ids (or `null`).

## guis

`{ kind, path, hostId, face, canvas, sizeStuds, studsOffset, studsOffsetWorldSpace, brightness, lightInfluence, alwaysOnTop, enabled, maxDistance, images }`
- `kind` `SurfaceGui`: `face` (NormalId name), `canvas` `[w, h]`; *(ext)* `sizingMode`, `pixelsPerStud`, `zOffset`.
  `sizeStuds`, `studsOffset*`, `maxDistance` are `null`.
- `kind` `BillboardGui`: `sizeStuds` `[w, h]` = the Size's scale components (studs); *(ext)* `sizeOffsetPx`
  (the pixel offsets), `extentsOffset`. `face`/`canvas` are `null`. `maxDistance` `null` = infinite.
- `hostId`: the part the GUI is drawn on/at (`Adornee`, else the parent; a billboard under an attachment uses that
  attachment's part) *(ext)* `hostAttachmentId` when a billboard hangs on an attachment (position = its `worldCf`).
  *(ext)* `hostCf`: the host part's world CFrame (present even when the host is not in `parts`, e.g. a character part).
- `images`: every ImageLabel/ImageButton inside: `{ image, color, transparency, rotation, size, position }` with
  `size`/`position` as `[scaleX, offsetX, scaleY, offsetY]`; *(ext)* `anchor` `[x, y]`, `visible`, `zIndex`,
  `backgroundTransparency`, `backgroundColor`. *(ext)* `texts`: TextLabels `{ text, color, transparency, size, position, visible }`.

## emitters

`{ path, hostId, hostAttachmentId, enabled, texture, rate, lifetime, speed, spreadAngle, emissionDirection, shape, shapeStyle, shapeInOut, shapePartial, size, transparency, color, lightEmission, lightInfluence, brightness, acceleration, drag, lockedToPart, rotation, rotSpeed, zOffset, orientation, flipbookLayout, flipbookMode, squash, timeScale }`
- Exactly one of `hostId` (emits from the part's volume/surface per `shape*`) or `hostAttachmentId` (a point).
- *(ext)* `hostCf` (the host part's or attachment's world CFrame), `hostSize` (the host part's size), `flipbookFramerate`, `flipbookStartRandom`, `velocityInheritance`.
- *(ext)* `hostHistory`: `[[t, px, py, pz, r00..r22, enabled01], ...]` - the host's world CFrame and the emitter's
  `Enabled`, sampled every 0.1 s over the last ~21 s, so a renderer can re-simulate particles that were born
  earlier at other positions (orbiting orbs, the moving wearer). Present when snapshots were requested.
- *(ext)* `bursts`: `[[t, count], ...]` - `:Emit(n)` calls in the last 20 s.

## trails

`{ path, a0, a1, enabled, texture, textureMode, textureLength, lifetime, minLength, maxLength, widthScale, color, transparency, lightEmission, lightInfluence, brightness, faceCamera }`
- *(ext)* `history`: `[[t, x0, y0, z0, x1, y1, z1], ...]` - both attachments' world positions every 0.1 s.

## lights

`{ class, hostId, color, brightness, range, enabled }`; *(ext)* `path`, `hostAttachmentId`, `hostCf` (where the light
is), `shadows`, `angle` and `face` (SpotLight/SurfaceLight, else `null`).

## highlights

`{ path, adorneePath, fillColor, fillTransparency, outlineColor, outlineTransparency, depthMode, enabled }`; *(ext)* `adorneeId`.
A Highlight with no `Adornee` adorns its parent (that is what `adorneePath` reports).

## effects

`{ class, props }` for post effects the module created (ColorCorrectionEffect, BloomEffect, BlurEffect, SunRaysEffect,
DepthOfFieldEffect, Atmosphere, Sky) wherever they live (usually `Workspace.Camera`); `props` holds the
explicitly-set number / bool / string / colour / enum-name properties. *(ext)* `path`, `parentPath`.
The place's own Lighting (Bloom Intensity 1, Size 24, Threshold 2) is not listed: it is fixed scenery.

## Validating

`python3 tools/harness/check_snapshot.py FILE_OR_DIR ...` checks frames against this contract (required keys and types,
id references); the harness tests run it on the pass-4 snapshots.

## The scene around the aura

Not in the snapshot (the renderer supplies it): a flat plaza at y = 0 (sand paths and grass, palm trees, torch posts),
a bright cyan-blue sky with clouds when `clockTime` is between ~7 and ~17.5, a dark cloudy sky at night.
