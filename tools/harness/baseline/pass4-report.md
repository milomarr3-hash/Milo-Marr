# Aura harness report: `TheEnd.pass4-live.lua`

Headless run against the mock Roblox runtime (tools/harness). **Not a Studio test**: no rendering, physics or real engine. Roblox API 0.742.0.7421053; seed 12345; 19 scenarios; generated 2026-10-14 08:17 UTC.

**Verdict: CLEAN: no errors.** 17 warning kind(s).

## Scenarios

| scenario | frames | update us p50 / p95 | instances | BaseParts | emitters on | rate sum | alive est. | beams | GUIs | lights | highlights | parts moved/frame | new inst./frame | GUI writes/frame (steady) | view blocked |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| day_idle | 955 | 119 / 258 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 79% |
| night_idle | 715 | 126 / 271 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 72% |
| showcase_front | 715 | 195 / 368 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 2% |
| camera_orbit | 1195 | 118 / 277 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 29% |
| glide | 955 | 127 / 275 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 79% |
| air | 835 | 173 / 319 | 178 | 23 | 16 | 186 | 691 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 76% |
| dusk | 955 | 115 / 248 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 79% |
| low_quality | 715 | 144 / 295 | 135 | 21 | 13 | 85 | 330 | 17 | 29 | 0 | 0 | 21 | 0 | 0 | 72% |
| remote_wearer | 715 | 122 / 274 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | - |
| far | 801 | 110 / 329 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 75% |
| toggle_visible | 583 | 193 / 398 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 1.10 | 65% |
| destroy_mid_assembly | 120 | 156 / 273 | 179 | 23 | 5 | 52 | 106 | 31 | 29 | 1 | 0 | 0 | 0 | 0 | 0% |
| reequip | 775 | 143 / 384 | 179 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 48% |
| respawn | 817 | 129 / 387 | 178 | 23 | 7 | 86 | 220 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 50% |
| join_wearing | 595 | 125 / 281 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 66% |
| r6_character | 715 | 151 / 325 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 72% |
| film_meshes_present | 715 | 150 / 308 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 72% |
| film_meshes_absent | 715 | 145 / 298 | 178 | 23 | 20 | 256 | 978 | 31 | 29 | 1 | 0 | 23 | 0 | 0 | 72% |
| crowd | 715 | 155 / 365 | 1068 | 138 | 120 | 1539 | 5869 | 186 | 174 | 6 | 0 | 138 | 0 | 0 | 72% |

Columns: census at ~10 s (steady state; if the aura is hidden then, the last census where it was shown); `alive est.` = sum over enabled emitters of Rate x mean Lifetime; `update us` is the real Lua time of one `fx.update` in the mock (indicative only, the mock's property access is slower than Roblox's); `view blocked` = share of samples where an opaque aura part (or an opaque SurfaceGui plane) sits between the camera and the wearer's head.

## Errors (0)

None.
## Warnings (17 kinds)

- **[billboard-cut]** Moon's 10.8-stud sprite (solid, camera-facing) crosses SurfaceGui planes, which cut it in Roblox (x17; air RingA/RingB 93%; camera_orbit RingB 54%; crowd DialInner/DialMid/DialOuter/Hands/RingA/RingB/Shards/Void 100%; day_idle RingA/RingB 72%; dusk RingA/RingB 72%; far Hands/RingB/Shards 70%; film_meshes_absent RingA/RingB 80%; film_meshes_present RingA/RingB 80%; glide RingA/RingB/Shards 83%; join_wearing DialInner/DialMid/DialOuter/Hands/RingB/Shards 83%; low_quality RingA/RingB 80%; night_idle RingA/RingB 80%; r6_character RingA/RingB 80%; reequip DialMid/DialOuter/RingB/Shards/Void 60%; remote_wearer RingB 80%; showcase_front RingB 80%; toggle_visible RingA/RingB 71%)
- **[billboard-cut]** Void's 12.5-stud sprite (solid, camera-facing) crosses SurfaceGui planes, which cut it in Roblox (x10; camera_orbit RingB 62%; crowd DialInner/DialMid/DialOuter/Hands/RingA/RingB/Shards/Void 100%; day_idle RingB 44%; dusk RingB 44%; far RingB/Shards 50%; glide RingB/Shards 44%; join_wearing DialInner/DialMid/DialOuter/Void 33%; reequip RingB 100%; remote_wearer RingB 60%; showcase_front RingB 40%)
- **[billboard-cut]** Void's 19.0-stud sprite (solid, camera-facing) crosses SurfaceGui planes, which cut it in Roblox (x16; air RingB 43%; camera_orbit Ground/GroundRing/RingA/RingB/Shards/Swirl/Void 73%; crowd DialInner/DialMid/DialOuter/Ground/GroundRing/Hands/RingA/RingB/Shards/Swirl/Void 100%; day_idle RingA/RingB 50%; dusk RingA/RingB 50%; far RingA/RingB 80%; film_meshes_absent RingA/RingB 60%; film_meshes_present RingA/RingB 60%; glide RingA/RingB 61%; join_wearing DialInner/DialMid/DialOuter/Hands/RingA/RingB/Shards/Void 100%; low_quality RingA/RingB 60%; night_idle RingA/RingB 60%; r6_character RingA/RingB 60%; remote_wearer RingB 80%; showcase_front RingB 80%; toggle_visible RingB 43%)
- **[billboard-cut]** Void's 3.2-stud sprite (solid, camera-facing) crosses SurfaceGui planes, which cut it in Roblox (x1; crowd Shards/Void 33%)
- **[billboard-cut]** Void's 7.0-stud sprite (solid, camera-facing) crosses SurfaceGui planes, which cut it in Roblox (x4; camera_orbit RingB 35%; crowd DialMid/Shards/Void 33%; far RingB 30%; reequip RingB 40%)
- **[translucent-layer]** DialInner.SurfaceGui: a 30-stud image layer at transparency 0.75 (opacity rule: nothing over 6 studs at 0.3..0.8) (x23; all scenarios except destroy_mid_assembly)
- **[translucent-layer]** DialMid.SurfaceGui: a 30-stud image layer at transparency 0.75 (opacity rule: nothing over 6 studs at 0.3..0.8) (x23; all scenarios except destroy_mid_assembly)
- **[translucent-layer]** DialOuter.SurfaceGui: a 30-stud image layer at transparency 0.70 (opacity rule: nothing over 6 studs at 0.3..0.8) (x23; all scenarios except destroy_mid_assembly)
- **[translucent-layer]** GroundRing.SurfaceGui: a 58-stud image layer at transparency 0.31 (opacity rule: nothing over 6 studs at 0.3..0.8) (x22; all scenarios except air, destroy_mid_assembly)
- **[translucent-layer]** Moon.BillboardGui: a 18-stud sprite at transparency 0.50 (opacity rule: nothing over 6 studs at 0.3..0.8) (x23; all scenarios except destroy_mid_assembly)
- **[translucent-layer]** Moon.BillboardGui: a 24-stud sprite at transparency 0.72 (opacity rule: nothing over 6 studs at 0.3..0.8) (x23; all scenarios except destroy_mid_assembly)
- **[translucent-layer]** RingA.SurfaceGui: a 18-stud image layer at transparency 0.55 (opacity rule: nothing over 6 studs at 0.3..0.8) (x46; all scenarios except destroy_mid_assembly)
- **[translucent-layer]** RingB.SurfaceGui: a 23-stud image layer at transparency 0.70 (opacity rule: nothing over 6 studs at 0.3..0.8) (x46; all scenarios except destroy_mid_assembly)
- **[translucent-layer]** Shards.BillboardGui: a 32-stud sprite at transparency 0.60 (opacity rule: nothing over 6 studs at 0.3..0.8) (x23; all scenarios except destroy_mid_assembly)
- **[translucent-layer]** Shards.SurfaceGui: a 48-stud image layer at transparency 0.62 (opacity rule: nothing over 6 studs at 0.3..0.8) (x23; all scenarios except destroy_mid_assembly)
- **[translucent-layer]** Swirl.SurfaceGui: a 36-stud image layer at transparency 0.68 (opacity rule: nothing over 6 studs at 0.3..0.8) (x22; all scenarios except air, destroy_mid_assembly)
- **[view-blocked]** from the default camera behind the wearer, solid aura parts cover the wearer's head (DialInner, DialMid, DialOuter, Hands, Void) (x12; air 76%; day_idle 79%; dusk 79%; film_meshes_absent 72%; film_meshes_present 72%; glide 79%; join_wearing 66%; low_quality 72%; night_idle 72%; r6_character 72%; reequip 48%; respawn 50%)

## Cost and per-frame work

Reference scenario `day_idle` (955 frames, 535 steady):

- Instances in the aura: 178 (BaseParts 23, MeshParts 0, attachments 44); emitters 20 (20 enabled), rate sum 256.5/s, ~978 particles alive, particle area ~19244 stud^2; beams 31 (544 segments); GUIs 29 (29 images, 17.6 Mpx of SurfaceGui canvas); lights 1 (0 with shadows); highlights 0; trails 0.
- By class: Attachment 44, Beam 31, ImageLabel 29, Part 23, ParticleEmitter 20, SurfaceGui 19, BillboardGui 10, Folder 1, PointLight 1
- Busiest emitters: Dust.ParticleEmitter (270 alive); Ground.ParticleEmitter (150 alive); DialOuter.ParticleEmitter (68 alive); Ground.ParticleEmitter (57 alive); Ground.ParticleEmitter (56 alive)
- fx.update: 955 calls, mean 140 us, p50 119, p95 258, max 2275 (mock time); build 5.6 ms.
- BulkMoveTo: 23.0 parts/frame in 1.0 call(s)/frame (steady).

Property writes per frame made inside `fx.update` (avg over all frames / steady state after the assembly; max):

| class.property | kind | avg/frame | steady avg | max | frames written |
|---|---|---|---|---|---|
| Beam.Transparency | effect | 3.25 | 0.00 | 29 | 107 |
| ImageLabel.ImageTransparency | gui | 2.63 | 0.00 | 28 | 325 |
| ParticleEmitter.Enabled | effect | 0.13 | 0.00 | 20 | 6 |
| BillboardGui.Enabled | gui | 0.12 | 0.00 | 2 | 109 |
| BillboardGui.Size | gui | 0.11 | 0.00 | 1 | 109 |
| Part.Transparency | part | 0.05 | 0.00 | 1 | 51 |
| Beam.Enabled | effect | 0.01 | 0.00 | 2 | 6 |
| PointLight.Enabled | effect | 0.01 | 0.00 | 1 | 6 |

Tween-driven writes: ColorCorrectionEffect.Contrast 0.22/frame (max 1), ColorCorrectionEffect.TintColor 0.22/frame (max 1), ColorCorrectionEffect.Brightness 0.22/frame (max 1), ColorCorrectionEffect.Saturation 0.22/frame (max 1)

Redundant writes (same value written again) inside update: BillboardGui.Enabled 0.11/frame, ParticleEmitter.Enabled 0.10/frame, Beam.Transparency 0.03/frame, ImageLabel.ImageTransparency 0.03/frame, Beam.Enabled 0.01/frame, PointLight.Enabled 0.01/frame, BillboardGui.Size 0.00/frame

## Cleanup (after the final destroy + 1.5 s)

Nothing left behind in any scenario: 0 instances outside the container, 0 live connections, 0 pending callbacks.

Module-level connections (made once when the module is required; they live for the session, expected): CharacterAdded on Players.Player1

## Flicker and view checks

- Flicker (3+ back-and-forth changes of brightness / transparency / Enabled within one second): none
- The camera's view of the wearer's head (sampled 10x a second from the local player's camera):

| scenario | blocked | by (samples) |
|---|---|---|
| day_idle | 79% (126 of 160) | DialInner 126, DialMid 126, DialOuter 126, Hands 126, Void 126 |
| night_idle | 72% (86 of 120) | DialInner 86, DialMid 86, DialOuter 86, Hands 86, Void 86 |
| showcase_front | 2% (3 of 120) | Void 3 |
| camera_orbit | 29% (58 of 200) | Hands 57, DialInner 55, DialOuter 51, DialMid 50, Void 47 |
| glide | 79% (126 of 160) | Void 129, DialInner 126, DialMid 126, DialOuter 126, Hands 126 |
| air | 76% (106 of 140) | Void 109, DialInner 106, DialMid 106, DialOuter 106, Hands 106 |
| dusk | 79% (126 of 160) | DialInner 126, DialMid 126, DialOuter 126, Hands 126, Void 126 |
| low_quality | 72% (86 of 120) | DialInner 86, DialMid 86, DialOuter 86, Hands 86, Void 86 |
| far | 75% (100 of 134) | DialInner 100, DialMid 100, DialOuter 100, Hands 100, Void 100 |
| toggle_visible | 65% (64 of 98) | DialInner 64, DialMid 64, DialOuter 64, Hands 64, Void 64 |
| reequip | 48% (62 of 130) | DialInner 62, DialMid 62, DialOuter 62, Hands 62, Void 62 |
| respawn | 50% (69 of 137) | DialInner 69, DialMid 69, DialOuter 69, Hands 69, Void 69 |
| join_wearing | 66% (66 of 100) | DialInner 66, DialMid 66, DialOuter 66, Hands 66, Void 66 |
| r6_character | 72% (86 of 120) | DialInner 86, DialMid 86, DialOuter 86, Hands 86, Void 86 |
| film_meshes_present | 72% (86 of 120) | DialInner 86, DialMid 86, DialOuter 86, Hands 86, Void 86 |
| film_meshes_absent | 72% (86 of 120) | DialInner 86, DialMid 86, DialOuter 86, Hands 86, Void 86 |
| crowd | 72% (86 of 120) | Void 162, DialInner 152, DialMid 152, DialOuter 152, Hands 152 |

## Harness gaps hit

None: every API the module used is implemented by the mock.

## Asset ids used (27)

- `rbxassetid://105160126126488` (ImageLabel.Image)
- `rbxassetid://109765380822041` (ParticleEmitter.Texture)
- `rbxassetid://111152711897982` (Beam.Texture)
- `rbxassetid://113607571698621` (ImageLabel.Image)
- `rbxassetid://115317702570755` (ParticleEmitter.Texture)
- `rbxassetid://115797014411278` (Beam.Texture)
- `rbxassetid://120547039021938` (ImageLabel.Image)
- `rbxassetid://121599880739521` (ImageLabel.Image)
- `rbxassetid://134434932210706` (ImageLabel.Image)
- `rbxassetid://13826565206` (ParticleEmitter.Texture)
- `rbxassetid://138970147678654` (ImageLabel.Image)
- `rbxassetid://14591895021` (ImageLabel.Image)
- `rbxassetid://16956515291` (ParticleEmitter.Texture)
- `rbxassetid://17062535921` (ParticleEmitter.Texture)
- `rbxassetid://17086022111` (ImageLabel.Image)
- `rbxassetid://17087733793` (ParticleEmitter.Texture)
- `rbxassetid://3029306948` (Beam.Texture)
- `rbxassetid://79447855638088` (ImageLabel.Image)
- `rbxassetid://81195317493584` (ImageLabel.Image)
- `rbxassetid://82989578201256` (ImageLabel.Image)
- `rbxassetid://88172507927269` (ParticleEmitter.Texture)
- `rbxassetid://90101855061498` (Beam.Texture, ImageLabel.Image)
- `rbxassetid://91068008644782` (ImageLabel.Image)
- `rbxassetid://91995992047091` (ParticleEmitter.Texture)
- `rbxassetid://93291601851916` (ImageLabel.Image, ParticleEmitter.Texture)
- `rbxassetid://98346126355034` (ImageLabel.Image)
- `rbxassetid://99880756430819` (Beam.Texture)

## Scenario notes

- **day_idle**: Day (ClockTime 14), wearer idle, default follow camera 16 studs behind and 6 up
- **night_idle**: Night (ClockTime 0.3), wearer idle, follow camera behind
- **showcase_front**: Day, camera in front of the wearer ~34 studs out and 8 up (how Milo frames his screenshots)
- **camera_orbit**: Day, the camera circles the wearer once (radius 30, 8 up) over 20 s
- **glide**: Day, idle 2 s, then walks forward on a gentle curve at WalkSpeed 16 (glide ramps 0->1), stops at 12 s
- **air**: Day, the wearer rises from the ground at 8 studs/s from t = 2 (ground ray of 60 studs loses the floor near t = 9)
- **dusk**: ClockTime sweeps 17.0 -> 19.5 (sunset into night) while idle: tests day/night blending
- **low_quality**: Day, quality = "low" (phones / low graphics), touch device
- **remote_wearer**: Another player (isLocal = false) wears it; the local player stands 30 studs away looking at them
- **far**: Camera pulls back: 20 -> 150 studs (setDetail false past 110) -> 400 (setVisible false past 320) -> back to 20
- **toggle_visible**: Camera goes Scriptable 3-5 s (framework hides the aura), then rapid hide/show at 8.0/8.1/8.2/8.3 s
- **destroy_mid_assembly**: Unequipped 2 s after equipping (mid assembly); runs on to 8 s so late callbacks fire
- **reequip**: Equip, unequip at 4 s, equip again at 5 s (module-level state must not break the second build)
- **respawn**: The wearer dies at 6 s: the framework destroys the aura, a new character spawns and it is built again
- **join_wearing**: The player just joined already wearing it (time() < 20): the equip-only screen grade must not run
- **r6_character**: Day, an R6 character (Torso, Left Arm ...; RootJoint / Left Shoulder joints, HipHeight 0)
- **film_meshes_present**: ReplicatedStorage.AuraCinema.Assets.TheEnd holds fake film meshes (RingG, Dial, Astrolabe, Hand, Gear, Oblivion.Moon/SmoothSphere)
- **film_meshes_absent**: ReplicatedStorage.AuraCinema.Assets.TheEnd exists but is empty (the fallback path)
- **crowd**: Six wearers at once (the local player + 5 others in a ring of radius 25): per-client cost scaling
