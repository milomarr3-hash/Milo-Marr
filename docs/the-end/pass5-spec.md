# THE END — pass 5 design spec: "The Last Clock" (equipped aura)

Status: definitive design for the pass-5 **equipped** aura of 『 THE END 』 (1 in 1,000,000,000). Not the cutscene.
Written in the cloud (no Studio access). Nothing here has been tested in Studio. The builder implements it as
`roblox/ReplicatedStorage/AuraFX/TheEnd.lua`, keeping the module name `TheEnd`. The headless harness (`tools/harness/`) and the
preview renderer check it, and Milo's Mac installs it later.

Sources: `docs/memory/aura-rng.md` (Milo's direction, framework contract, lessons), `docs/the-end/pass5-art-direction.md`
(the art director's recovered "Last Clock" notes; this spec adopts and finishes them), `TheEnd.pass4-live.lua` (the live pass-4
module: API, helpers, TEX ids), and the real pass-4 Studio captures.

Conventions used throughout: studs; degrees unless written `rad(...)`. A CFrame written as `X * Y` means Roblox CFrame multiplication.
"Silver / Dark / Lume" name the sub-model a part goes in (§7). Values are `high / low` quality when two are given; a dash means the
element is not built on low.

---------------------------------------------------------------------------------------------------------------------------------

## 1. What Milo asked, and how pass 5 answers it

Milo's latest words (after pass 4): *"it needs so much more work, add depth, so much better particle effects, less transparency and
more feel toward the build. Go all out, take your time and build it so much better. its getting better though, your on the right
track."* Standing rules: **KEEP THE CLOCK** (the theme), black/white/silver only, **no flashes, strobes or flicker**, must read by day
(bright cyan tropical sky) and by night.

| Milo said | Pass 5 answer |
|---|---|
| "add depth" | The aura spans about **26 studs of depth** in 8 layers (§6). The clock stands 8 studs beyond the wearer, the orbs 1.5 studs in front of him, the armillary bands cross in front of his body, and bokeh drifts between the camera and him. Everything is opaque geometry, which writes depth, so occlusion is real. Parallax comes from gears at 3 depths behind the dial, hands at 3 heights above it, a 9° ± 5° slow yaw sway on the clock, the clock's yaw spring lagging when the camera swings, and galaxy layers stacked at 3 heights. |
| "so much better particle effects" | 18 particle systems (11 on low), each with a job and a path: matter spirals into the void, the palms draw in the two streams, shards break off the bezel and fly into the void, a vortex funnel climbs into the balance wheel, time drips off the feet, two-tone smoke curls off the rim, glints ride the metal, and motes come in 3 sizes. New textures have ink rims, so particles read on a bright sky (§9, §16). |
| "less transparency" | Every structural element is **opaque** (Transparency 0): bezel, dial ring, gears, hands, armillary, moon, void, dais rim, balance wheel. Glow comes from Neon and GUI Brightness, not from alpha. Every pass-4 see-through layer is deleted (§7.3). Soft alpha survives only in 2 rim-only halos, smoke, bokeh, one mist and small particles. |
| "more feel toward the build" | THE END becomes a machine built from about 360 parts. It has a fluted silver bezel, a recessed dark chapter ring with inlaid numerals and lume plots, a skeleton dial with an openwork star rete, 7 toothed gears (spokes and hubs, turning at fixed meshed rates), hands with lume, and a crown and bow. A 3-ring gimballed armillary with pins surrounds the wearer. A balance wheel with a hairspring swings under his feet, and the galaxy sits as a raised-rim dais. On equip the parts fly in and lock into place with a small overshoot (§12). |
| "go all out" | The full budget is used: 360 moving parts on high quality, 18 emitters, 11 GUIs, 6 beams and 2 lights. Optional film-mesh flags can later swap in the cutscene's own meshes (§15). |

---------------------------------------------------------------------------------------------------------------------------------

## 2. What is wrong with pass 4 (from the real Studio captures)

The captures are from 2026-10-14: `032409` day front, `032533` night front, `0319*` reveal, `0320*`–`0322*` day/night variants,
`032311` moon zoom.

1. **The clock is a drawing.** It is 4 flat fine-line SurfaceGui layers on a smoke disc. From every angle it reads as a picture, with
   no thickness, no rim and no mechanism. By day the fine white lines dissolve into the sky (`032409`, `032240`).
2. **It is see-through.** The black smoke disc is the only dark mass, and it is a soft, transparent puff. The world shows through the
   whole clock.
3. **It washes out by day.** Additive white (LightEmission 1) vanishes on the cyan sky, and the metal and GUIs pick up a cyan cast.
4. **The orbs read as stickers.** They are camera-facing photo sprites. The moon gets a white wedge cut into it by transparent-plane
   sorting (`032311`). The void is a flat disc with a star.
5. **The ground ring is a faint decal.** A 58-stud engraved ring at 0.3 transparency sprawls over the plaza paths (`032533`, `032102`)
   and reads as a smudge, not a stage.
6. **There is no depth layering.** Everything sits within about 4 studs of the clock plane behind the wearer. Nothing passes in front
   of him, and nothing is far behind.
7. **The flash rule is broken.** The one soft pulse on equip is still a pulse. Pass 5 removes it.

---------------------------------------------------------------------------------------------------------------------------------

## 3. The look

**"The Last Clock."** A skeleton pocket watch about 28 studs across, cut from black steel and silver, stands 8 studs beyond the
wearer. It always faces whoever is watching. Its hands are locked at XII (midnight, the end) while the seconds hand sweeps on. Gears
turn behind the open dial, and their teeth break the silhouette at 1:30, 4, 8 and 10:30. A crown and bow sit above XII. The wearer
floats inside a silver armillary of 3 gimballed rings. The middle ring is a dark band marked with 12 lume hours. Two opposite bodies
hang on an invisible balance beam beside him and rock slowly like scales. On the viewer's left is a solid cratered white moon,
tidally locked to him. On the viewer's right is a pure-black void with a white photon ring, a lensed arc, a white 4-point heart and
an opaque swirling accretion disc whose near half crosses in front of the core. A silver stream arcs from the moon into one palm and
an ink stream from the void into the other. An ink ribbon falls from the void into a galaxy dais below: a dark pool, Ø 30, with
white arms, a raised silver rim and floating arm layers. A balance wheel swings under the feet. Particles do work: matter, shards,
smoke, glints, drips and dust. The palette is black, white and silver. It moves like a mechanism: constant rotations, smooth
oscillations, and overshoot-locks only on assembly. No brightness ever pulses.

```
FRONT VIEW (viewer in front of the wearer; heights relative to O = body centre; ground at -5.4)

                                   ( )          bow top  +31.6
                                   [=]          crown    +25.3
                      GD  .-'''''''''''''''-.  GA                  bezel top  +23.7
                     \|/.'  XI    XII    I  '.\|/
                       /  X                II  \
                      |  IX   o <- hub     III  |                 clock centre +9.6, 8 studs beyond
          .-.         | VIII GI    rete  GH IV  |         (void)
 moon -> (   ) ===>    \  VII   [wearer]   V   /    <=== @====    orbs at x -/+12.5, y +6.0 (rocking +/-10 deg)
          '-'           '. GC   (armillary) GB.'          \       void accretion disc nearly edge-on
                          '-..___  VI ___..-'              \      ink ribbon to the dais
             ________________[balance wheel]________________\     wheel  -3.35 below O (under the feet)
           (====== dark galaxy pool, white arms, raised silver rim Ø31 ======)   ground
       ( - - - - - - - - - engraved clock ring Ø40 on the ground - - - - - - - - - )

TOP VIEW (camera at the bottom)

             ===============  clock plane (faces the camera, 8 studs beyond O)  ===============
                  gears L1 behind it, smoke L0 behind that
                                  .--armillary R<=6.3--.
            moon O               (       [O]          )              @ void (+ disc R 6.5)
            (x -12.5, z +1.5)     '--------------------'             (x +12.5, z +1.5)
                                  bokeh volume (7.5 toward camera)
                                            ^
                                          camera
```

---------------------------------------------------------------------------------------------------------------------------------

## 4. Frames and conventions (exact)

All per-frame. `s` is the framework state (§17.1). `g = s.glide` (0..1).

| Frame | Definition | Axes |
|---|---|---|
| **O** (point) | `s.cf.Position + Vector3.new(0, s.hover, 0)` | The visible body centre (HRP height plus hover and bob). Head ≈ O+2.0, idle hands ≈ W(±2.3, −0.3, −0.5), soles ≈ O−`s.legLen` (≈ −3.0), ground ≈ −5.4 while floating. |
| **yawW** | Smoothed wearer facing, as in pass 4: `target = atan2(-lv.X, -lv.Z)` with `lv = s.cf.LookVector`; `yawW += wrapPi(target - yawW) * (1 - exp(-5*dt))`. | |
| **W** | `CFrame.new(O) * CFrame.Angles(0, yawW, 0)` | +X wearer's right, +Y up, **+Z behind the wearer** (−Z = forward). Same as the HRP. |
| **ψ** | Viewer yaw from the spring in §5 | |
| **V** | `CFrame.new(O) * CFrame.Angles(0, ψ, 0)` | LookVector = horizontal direction **camera → wearer** (away from the viewer). +X = **viewer's right**, +Y up, **+Z toward the viewer**. |
| **K** (clock) | `V * CFrame.new(0, Hc, -Dc) * CFrame.Angles(0, rad(ya), 0) * CFrame.Angles(rad(-tilt), 0, 0)` with `Hc = 9.6 - 0.5*g`, `Dc = 8 + 2*g`, `tilt = 8 + 14*g`, `ya = 9 + 5*sin(2π*s.t/16)` | x = viewer's right, y = toward XII, **z = toward the viewer** (+z is in front of the dial). The top leans away from the viewer. |
| **clock angle θ** | Measured **clockwise from XII as the viewer sees it**. Point at radius r: `(r*sin θ, r*cos θ, z)`. A part laid along the radius at θ: `CFrame.Angles(0, 0, -θ) * CFrame.new(0, r, z)`. | |
| **A0** (armillary) | `W * CFrame.new(0, 1.3, 0) * CFrame.Angles(rad(-18*g), 0, 0)` | Leans forward with the glide pose (Root −18°·g, same sign convention as `End.pose`). |
| **Pv** (balance pivot) | `V * CFrame.new(0, 6.0, 1.5) * CFrame.Angles(0, 0, β)`, `β = rad(10) * sin(2π*s.t/10) * swayAmp` | Moon centre `moonC = (Pv * CFrame.new(-12.5, 0, 0)).Position`, void centre `voidC = (Pv * CFrame.new(12.5, 0, 0)).Position`. |
| **n, dc** | `n = unit(camPos - voidC)`, `dc = max(|camPos - voidC|, 5)` | `up = (|n.Y| > 0.98) and Vector3.zAxis or Vector3.yAxis` (passed as the 3rd argument of every lookAt below). |
| **Hf** (heart) | `CFrame.lookAt(voidC + n*4.1, voidC, up)` | x = viewer's right, y up, z toward the viewer. Same for Pf. |
| **Pf** (photon) | `CFrame.lookAt(voidC + n*zt, voidC, up)`, `zt = 16/dc` (R²/dc with R = 4) | Ring radius `rt = 4*sqrt(1 - 16/dc^2)` = the silhouette circle of the core seen from the camera. |
| **Dk** (accretion) | `CFrame.new(voidC) * V.Rotation * CFrame.Angles(rad(15), 0, 0)` | The disc normal tilts 15° toward the viewer, so the viewer sees its top face. The near half dips in front of the core's lower half. |
| **Gd** (dais) | `CFrame.new(O.X, daisY, O.Z)` (world-aligned) | daisY in §8.6. |
| **Bw** (wheel) | `CFrame.new(O.X, O.Y - s.legLen - 0.35, O.Z) * CFrame.Angles(0, wheelAngle, 0)` | |

Every `rate × time` angle is wrapped with `% (2π)` before use (as in pass 4), so precision holds over long sessions.

CFrame helpers the builder writes once: `ring(N, R, w, t, ...)` (segment CFrames and sizes), `gear(spec)`, `spike(h, d, thick)`,
`easeOutBack(u, c1)`, `smooth(u)`, `win(a, b)` = `clamp((age - a)/(b - a), 0, 1)`.

**Part rest transforms.** Every part has a fixed `local` CFrame inside its rigid group. Each frame:
`cfs[i] = groupCF[group(i)] * local[i]`, plus the assembly offset while assembling (§12). There is one `workspace:BulkMoveTo` per
frame (§17).

---------------------------------------------------------------------------------------------------------------------------------

## 5. Viewer-anchored clock and orbs (exact)

**Why.** The owner's camera is normally behind the wearer. Pass 4 put the clock between that camera and the character, seen from its
back. In pass 5 every client places the clock on the far side of the wearer from its own camera, and the moon/void balance on that
camera's left/right. The owner sees the dial's face over their shoulders. Spectators in front see it behind the wearer. Side
viewers see it beyond him. The orbs never sit between a camera and the wearer, and the void's disc can never cut into the clock (a
body-anchored void would cross the clock plane in side views; this was found while placing the parts).

**Algorithm (per wearer, per client, every frame):**

```lua
local cam = workspace.CurrentCamera
local camPos = cam and cam.CFrame.Position or lastCamPos      -- keep the last known position if there is no camera
lastCamPos = camPos
local v = O - camPos
local vh = Vector3.new(v.X, 0, v.Z)
local dh = vh.Magnitude
if dh > 1.5 and dh > 0.2 * math.abs(v.Y) then                 -- else HOLD: camera inside the wearer (first person) or straight above
	yawTarget = math.atan2(-vh.X, -vh.Z)                       -- CFrame.Angles(0, yawTarget, 0).LookVector == vh.Unit
end
-- exact critically damped spring (stable for any dt), natural frequency k = CONFIG.YAW_SPRING = 6.5 rad/s
local x = wrapPi(psi - yawTarget)                              -- wrapPi -> (-pi, pi]
local e = math.exp(-k * dt)
local tmp = (psiVel + k * x) * dt
x = (x + tmp) * e
psiVel = (psiVel - k * tmp) * e
psi = yawTarget + x
```

- Response to a step: 58% at 0.3 s, 84% at 0.5 s, **95% at 0.73 s**, 99% at 1.0 s, with no overshoot. When the camera orbits, the
  clock trails and shows its bezel band and the gears behind it. At 45°/s orbit speed the steady lag is about 14° (`2·speed/k`).
- Init at build: `yawTarget = psi` = the yaw from the current camera, or `yawW` if degenerate (as if seen from behind, the owner's
  usual view). `psiVel = 0`.
- **Remote wearers:** identical code using *this* client's camera, so every viewer sees the face. No replication is needed.
- **Very close camera / first person** (`dh ≤ 1.5`): yaw is held, so the clock stays where it was in the world while the player looks
  around. The near-camera rules in §13.3 hide the armillary, shards and bokeh.
- **Camera directly above** (`dh ≤ 0.2·|v.Y|`, steeper than about 79°): yaw is held, so the clock does not spin. From above you see its
  top edge, the crown and the bow.
- **dt** is clamped to 0.1 before use. ψ, ψVel and yawTarget must never become NaN (assert in the harness).
- **Fallback flag** `CONFIG.VIEWER_ANCHOR = false`: `V` is replaced by `W * CFrame.Angles(0, π, 0)` (clock behind the wearer facing
  forward, like pass 4). For the owner only (`ctx.isLocal`), while the camera→head segment crosses the clock disc (R 14), every clock
  part's `LocalTransparencyModifier = 0.5`. Write this only when the state flips.

---------------------------------------------------------------------------------------------------------------------------------

## 6. Depth layers

"Beyond" = distance along V's LookVector past O (away from the viewer). Negative = toward the viewer. Clock K-z converts as
beyond ≈ `Dc - z` (ignoring the 8° tilt).

| Layer | Beyond (studs) | Contents |
|---|---|---|
| **L0** | 10.5 … 13 | Night corona plane (K z −3.2), smoke curling back off the rim, rim glints' far side |
| **L1** | 9.5 … 10.5 | Gears GA, GB, GC, GD (K z −1.47 … −2.48): 30–45 % visible past the rim at 1:30, 4, 8, 10:30; visible through the skeleton dial |
| **L2** | 7.0 … 9.4 | Bezel (K z −1.44 … +1.12), chapter ring (−0.42 … +0.12), inlay GUI (+0.145), lume plots (+0.12 … +0.30), centre wheel GE (−1.3 … −0.6) |
| **L3** | 5.8 … 7.85 | Rete star (+0.15 … +0.39), sub-dial (+0.42 … +0.72), front gears GH/GI (+0.41 … +0.75), hands (hour +0.77 … +0.93, minute +1.07 … +1.23, seconds +1.38 … +1.46), hub stack (to +2.21) |
| **L4** | 0 … 6.3 | Far half of the armillary, far half of the dais, far time shards |
| **L5** | −4.6 … +4.6 | The wearer, time shards riding the ecliptic (r 4.0 from A0), palm intake |
| **L6** | −1.5 ± 6.5 | Moon (Ø 9) and void (Ø 8) at 1.5 toward the viewer. The accretion disc's near edge reaches −7.8. Palm streams, near armillary bands crossing the torso. |
| **L7** | −2.5 … −10 | Bokeh volume (centre 7.5 toward the viewer), fine dust |
| **Ground** | — | Dark dais pool Ø 29.6, silver rim Ø 31.1, floating arm layers at +0.42 and +0.66, engraved ring Ø 40, balance wheel 2.05 above the ground under the feet, ink ribbon landing on the dais rim |

**Clearances** (the harness asserts each, §18.2). Void disc far edge vs clock front: ≥ 0.7. Armillary sweep (max reach 6.28 from
A0) vs moon/void surfaces: ≥ 0.8. Armillary vs the void's accretion disc: ≥ 0.2. Armillary vs head, hands and feet sample points:
≥ 0.6. Time shards vs hands: ≥ 0.2. Clock bottom (−4.26 nominal, −4.54 at the
bob low point) vs dais layers (≤ −4.74): ≥ 0.2. Meridian bottom (−4.46) vs G2 (−4.74): ≥ 0.25.

---------------------------------------------------------------------------------------------------------------------------------

## 7. Materials, colours, opacity

### 7.1 Palette

| Token | RGB | Material | Reflectance | Sub-model | Used for |
|---|---|---|---|---|---|
| SILVER | 176, 180, 190 | Metal | 0.08 | Silver | bezel, rete, gear discs/teeth/spokes, meridian, ecliptic, dais rim, wheel rim/spokes, hand bodies |
| BRIGHT | 214, 218, 226 | Metal | 0.12 | Silver | hubs, crown, cap, stem, pins, silver time shards, seconds weight |
| STEEL | 44, 46, 52 | SmoothPlastic | 0 | Dark | chapter ring, gear webs, equator band, hub base |
| DEEP | 30, 31, 36 | SmoothPlastic | 0 | Dark | sub-dial |
| BASE | 12, 12, 16 | SmoothPlastic | 0 | Dark | dais base disc |
| VOID | 0, 0, 0 | **Neon** | 0 | Dark | void core (renders pure black, ignores the sky tint) |
| LUME | 236, 240, 248 | Neon | 0 | Lume | hour plots, hand lume, equator ticks, seconds tip, hub jewel, photon ring, heart, Neon time shards |
| ARC | 205, 208, 216 | Neon | 0 | Lume | lensed arc |
| VEIN | 220, 224, 232 | Neon | 0 | Lume | crackle veins |
| MOON | 234, 236, 240 | SmoothPlastic | 0 | Silver | moon ball |
| CRATER | 168, 171, 178 | SmoothPlastic | 0 | Silver | crater discs |

Particle and beam colours keep pass 4's `WHITE (248,249,255)`, `SILVER (222,228,240)`, `INK (5,5,8)`, `SMOKE (14,14,19)`, plus
`MIST (205,209,220)` and `ASH (16,16,20)`.

**Monochrome rule** (asserted): every Color3, ColorSequence key and ImageColor3 has a max channel spread ≤ 20 and B ≥ R (cool, never
warm).

### 7.2 Sub-models and the Highlight

```
TheEnd_<charName>   (Model, parented to ctx.container)
├─ Silver   (Model)  ← Highlight "TheEndTone" parented here (Adornee = this model)
├─ Dark     (Model)
├─ Lume     (Model)
└─ Fx       (Folder) ← invisible carrier parts (Transparency 1): GUI planes, emitter hosts, beam ends
```

Each hideable group (§13) has its own child model inside each material model, for example `Silver/Armillary`, `Dark/Armillary`,
`Lume/Armillary`, `Silver/Detail`. Hiding a group means parenting those children to nil and dropping its parts from the move list.

**Highlight `TheEndTone`:** FillColor (205, 208, 215), FillTransparency 0.55 (day) → 0.80 (night), OutlineColor (10, 10, 14),
OutlineTransparency 0.35 (day) → 0.70 (night), DepthMode Occluded. It covers **only the Silver model**. That neutralises the cyan sky
tint on the metal and adds an ink contour that reads on a bright sky. It must **not** cover dark parts: a 45 % grey fill would lift
black steel to mid grey and the void to grey. Neon parts are emissive and stay out of it too. Cap: 31 per client, and this aura uses
1. During assembly its Fill/Outline transparency fades from 1 to target over 3.6–4.2 s.

### 7.3 Opacity rules

- **Opaque (Transparency 0):** every structural part in §8.
- **Luminous details are opaque images, glowing through Brightness, not alpha:** inlay numerals and minute track
  (ImageTransparency 0), sub-dial, hairspring, galaxy arms, engraving ring. Day Brightness ≤ 1.6 (below the place Bloom threshold of
  about 2). Night Brightness 2.2–2.6 (soft bloom).
- **Discs** (accretion, galaxy floor) are opaque in the body, with white arms **and** black lanes at alpha 1. Alpha fades only over the
  outer 12–15 % and the inner hole edge.
- **Soft elements allowed (the only ones):** the moon halo (rim-only, 0.65 day / 0.45 night), the night-only bezel corona (rim-only),
  bokeh (peak 0.6), smoke (peak 0.30 dark / 0.45 silver), one ground mist (peak 0.80), and particles ≤ 0.6 studs.
- **BANNED:** any element > 6 studs across with uniform transparency between 0.3 and 0.8; trails on big slow parts; additive-only white
  that must carry the look by day. **Deleted from pass 4:** Shards plane 48, corona sprite 32, moon glow 24, dark halo sprites, body
  glow 15, the broad 8-wide ribbon band, RingA/RingB image rings, ground Swirl 36, air mist haze, the 58-stud ground ring, the
  column-of-light beams, every "faint back face", the **equip pulse**, and all BillboardGuis except the moon halo.
- **No BillboardGui may intersect a SurfaceGui plane** (pass-4 lesson: it gets cut). This is why the void's heart, veins, photon ring
  and lensed arc are geometry. The moon halo billboard keeps ≥ 0.4 studs from every GUI plane (checked in §18.2).

---------------------------------------------------------------------------------------------------------------------------------

## 8. Components

Every part: `Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Massless = true,
Locked = true`, start `Transparency = 1` (the assembly sets it to its rest value). Fx carrier and GUI-plane parts stay at
Transparency 1 forever (only their GUIs fade). Exception: the moon and void core have
`CastShadow = CONFIG.SHADOWS and not low`. Cylinder parts have their axis on local X: Size = (length, Ø, Ø).
**Disc orientation** (axis along K z): `CFrame.Angles(0, rad(90), 0)`. **Vertical axis**: `CFrame.Angles(0, 0, rad(90))`.

### 8.1 The clock (frame K)

**C1 Bezel**: Silver, SILVER. Fluted coin edge. **N = 32 / 20** Block segments. Segment i: θi = (i + 0.5)·360°/N.
Inner radius 12.2 for all.

| | outer R | z back | z front | depth | Size (X tangential, Y radial, Z) |
|---|---|---|---|---|---|
| even i | 14.00 | −1.40 | +1.00 | 2.40 | (2·14.00·tan(180°/N) + 0.02, 1.80, 2.40) → N32: 2.778 · N20: 4.455 |
| odd i | 14.12 | −1.44 | +1.12 | 2.56 | (2·14.12·tan(180°/N) + 0.02, 1.92, 2.56) → N32: 2.801 · N20: 4.493 |

`local = CFrame.Angles(0, 0, -θi) * CFrame.new(0, (12.2 + Rout)/2, (zBack + zFront)/2)`. The alternation makes the flutes and also
prevents coplanar faces, so there is no z-fighting where segments overlap. Static in K.

**C2 Chapter ring**: Dark, STEEL. **N = 24 / 16**. Radial 9.4 → 12.5; the outer 0.3 tucks under the bezel and hides the polygon.
Even: z −0.40 … +0.10. Odd: z −0.42 … +0.12. Size `(2·12.5·tan(180°/N) + 0.02, 3.1, 0.50 | 0.54)` → N24: 3.311, N16: 4.993.
`local = CFrame.Angles(0,0,-θi) * CFrame.new(0, 10.95, zc)`.

**C3 Inlay plane**: Fx, invisible. Size (24.4, 24.4, 0.05) at K (0, 0, +0.12). SurfaceGui **Face = Back** (+Z, toward the viewer),
SizingMode FixedSize, CanvasSize 1024² / 512², LightInfluence 0, Brightness 1.6 → 2.6 (§11), AlwaysOnTop false. One full-size
ImageLabel: Image = T("dialInlay"), ImageColor3 (255,255,255), BackgroundTransparency 1, ImageTransparency 0 after assembly.

**C4 Hour plots** (high only): Lume, LUME. 12 Blocks, Size (0.42, 0.55, 0.18),
`CFrame.Angles(0,0,-h·30°) * CFrame.new(0, 11.85, 0.21)` for h = 0..11 (raised lume plots on the minute track).

**C5 Rete** (high only): Silver, SILVER. An openwork {12/5} star. 12 Blocks, Size (17.58, 0.26, 0.20). Bar k joins star points k and
k+5 on R 9.1. Its midpoint lies at radius 2.355 at angle φk = (k + 2.5)·30°: `CFrame.Angles(0,0,-φk) * CFrame.new(0, 2.355, zk)`,
with zk = +0.25 (even k) and +0.29 (odd k). The alternation avoids z-fighting at the crossings.

**C6 Sub-dial**: Dark, DEEP. Cylinder Size (0.30, 6.5, 6.5), disc orientation, at K (0, 0, +0.57). SurfaceGui on **Face = Left** (the
cylinder's −X, which faces the viewer after the 90° turn), CanvasSize 512² / 256², Brightness 1.4 → 2.2, Image T("subdial").

**C7 Hands.** Hand frame `Hh = K * CFrame.Angles(0, 0, -θhand) * CFrame.new(0, 0, zh)`. After assembly the hour and minute hands are
**locked at XII** (θ = 0). The seconds hand sweeps smoothly: `θs = 6°·(s.now % 60)`, continuous (no ticking).

| Hand | zh | Parts (Size; local position in Hh) | high / low |
|---|---|---|---|
| Hour | +0.85 | shaft Block (0.55, 5.6, 0.16) at (0, 3.4, 0) Silver · tip Block (0.70, 0.70, 0.16) rotated `CFrame.Angles(0,0,rad(45))` at (0, 6.45, 0) Silver · tail Block (0.55, 1.6, 0.16) at (0, −0.8, 0) Silver · lume Block (0.24, 4.6, 0.05) at (0, 3.6, +0.105) Lume | 4 / 2 (shaft, tip) |
| Minute | +1.15 | shaft (0.40, 8.0, 0.16) at (0, 4.6, 0) · tip (0.52, 0.52, 0.16) rot 45° at (0, 8.8, 0) · tail (0.40, 2.0, 0.16) at (0, −1.0, 0) · lume (0.16, 6.2, 0.05) at (0, 4.9, +0.105) Lume | 4 / 2 |
| Seconds | +1.42 | needle Block (0.12, 12.2, 0.08) at (0, 3.5, 0) Silver · weight Cylinder (0.08, 0.9, 0.9) disc orientation at (0, −2.0, 0) BRIGHT · tip Ball Ø 0.26 at (0, 9.6, 0) Lume | 3 / 1 (needle) |
| Hub (θ = 0, static) | — | Cylinder (0.30, 1.30, 1.30) disc orientation at K z +1.62 STEEL Dark · Cylinder (0.20, 0.85, 0.85) at z +1.85 BRIGHT · Ball Ø 0.45 at z +1.98 Lume (jewel) | 3 / 2 (no jewel) |

**C8 Gears.** Gear frame `Gk = K * CFrame.new(cx, cy, cz) * CFrame.Angles(0, 0, -spin)`, `spin = rad(rate)·s.now` (all clients agree).
Template parts in Gk:

- **disc**: Cylinder (d, Dr, Dr), disc orientation, SILVER, Silver.
- **web**: Cylinder (d + 0.04, 0.74·Dr, 0.74·Dr), STEEL, Dark. Proud by 0.02 on each face, so it reads as a recessed dark web inside a
  silver rim.
- **hub**: Cylinder (d + 0.3, 0.22·Dr, 0.22·Dr), BRIGHT. For GH/GI: (d + 0.10, 0.30·Dr, 0.30·Dr).
- **teeth**: K = teeth/2 Blocks, each crossing the whole gear: Size (wt, Dtip, d − 0.06), `CFrame.Angles(0, 0, -j·180°/K)` for
  j = 0..K−1, SILVER. The middle is hidden inside the disc, so only the tooth ends show past Dr.
- **spokes** (where marked): 2 Blocks (0.11·Dr, 0.72·Dr, d + 0.08) at `CFrame.Angles(0,0,rad(45))` and `rad(135)`, SILVER. They sit in
  front of the dark web.

| Gear | where | (cx, cy) | cz | Dtip | Dr | teeth (K) | d | wt | web | spokes | rate °/s | parts high / low |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| GA | 1:30, R 12.5 | (8.839, 8.839) | −2.00 | 9.0 | 8.0 | 16 (8) | 0.50 | 0.785 | yes | yes | −4.0 | 13 / 10 (no web, spokes) |
| GB | 4:00, R 12.9 | (11.172, −6.450) | −1.85 | 6.0 | 5.2 | 12 (6) | 0.45 | 0.681 | yes | no | +9.0 | 9 / — |
| GC | 8:00, R 12.6 | (−10.912, −6.300) | −2.10 | 7.0 | 6.1 | 12 (6) | 0.45 | 0.798 | yes | yes | −6.0 | 11 / — |
| GD | 10:30, R 12.4 | (−8.768, 8.768) | −1.90 | 8.0 | 7.1 | 14 (7) | 0.50 | 0.797 | yes | no | +4.6 | 10 / — |
| GE | centre wheel | (0, 0) | −0.95 | 7.6 | 6.8 | 16 (8) | 0.40 | 0.668 | yes | yes | +6.0 (with the seconds) | 13 / 10 |
| GH | IV, R 6.0 | (5.196, −3.000) | +0.58 | 3.6 | 3.0 | 8 (4) | 0.24 | 0.589 | no | no | −12.0 | 6 / — |
| GI | VIII, R 6.0 | (−5.196, −3.000) | +0.58 | 3.6 | 3.0 | 8 (4) | 0.24 | 0.589 | no | no | −12.0 | 6 / — |

GA–GD reach 1.9–3.0 studs past the bezel and draw a toothed silhouette around the clock. GE's teeth ring peeks out around the
sub-dial. Each pair at different z overlaps in projection without touching, so they read as meshed.

**C9 Crown and bow**: Silver, BRIGHT. All at K z −0.20.

- Stem: Cylinder (1.4, 1.1, 1.1), vertical axis, centre (0, 14.6).
- Crown: Cylinder (1.5, 2.6, 2.6), vertical axis, centre (0, 16.0).
- Cap: Ball Ø 1.2 at (0, 16.85).
- **Bow** (high only): a loop of **10** Cylinders, Size (1.662, 0.55, 0.55), round a centre at (0, 19.6), loop radius 2.4, in the
  clock plane. Segment j: `βj = (j + 0.5)·36°`, position = centre + 2.283·(cos βj, sin βj, 0),
  `CFrame.Angles(0, 0, βj + rad(90))` (cylinder axis tangent). Top of the bow ≈ K y 22.27.

Low quality builds the stem and crown only.

**C10 Corona plane** (high only, night only): Fx, invisible, Size (40, 40, 0.05) at K (0, 0, −3.2). SurfaceGui Face = Back,
Image T("halo"), ImageColor3 (236,240,248), Brightness 1.8, CanvasSize 512². `Enabled = n > 0.05`;
`ImageTransparency = 1 - 0.4*n` (written on the night tick only). The ring peaks just outside the bezel (R ≈ 14.8).

**C11 Clock carriers** (Fx, invisible, static in K):

- `RimGlint`: Size (28.4, 28.4, 0.2) at K (0, 0, +1.05). Host of P5a.
- `SmokeVoid`: Size (4, 22, 3) at K (+12.6, 0, −1.2). Host of P4a. The void is always on the viewer's right.
- `SmokeMoon` (high only): Size (4, 22, 3) at K (−12.6, 0, −1.2). Host of P4b.
- `ShardFeed` (high only): Size (2, 2, 2). Not in K: placed each frame at the bezel point at angle 310° (K (−10.72, 9.00, 0)),
  oriented `CFrame.lookAt(thatPoint, voidC)`. Host of P3.

### 8.2 The armillary (frames F1, F2, F3; body-anchored)

Flat-band ring recipe (ring in its frame's XY plane): segment i at θi = (i + 0.5)·360°/N,
`local = CFrame.Angles(0, 0, -θi) * CFrame.new(0, R, 0)`, Size `(2·(R + w/2)·tan(180°/N) + 0.02, w, t ± 0.02 alternating)`.

| Ring | Frame | R | w (radial) | t (axial) | N | Segment L | Colour | Motion |
|---|---|---|---|---|---|---|---|---|
| **A1 Meridian** | `F1 = A0 * CFrame.Angles(0, φ1, 0) * CFrame.Angles(rad(24), 0, 0)`, `φ1 = rad(8)·s.t` | 6.0 | 0.55 | 0.24 | 18 / 12 | 2.233 / 3.383 | SILVER | Precesses 8°/s with a fixed 24° lean; lowest point A0 −5.76 = O −4.46 |
| **A2 Equator** (bracelet band) | `F2 = F1 * CFrame.Angles(rad(66) + rad(18)*sin(2π*s.t/19), 0, 0)` | 5.3 | 0.20 | 0.75 | 18 / 12 | 1.924 / 2.914 | STEEL (Dark) | Near-horizontal, rocks ±18° about the meridian's pin axis |
| A2 ticks (high) | in F2 | — | — | — | 12 | — | LUME | Block (0.14, 0.06, 0.50) at `CFrame.Angles(0,0,-k·30°) * CFrame.new(0, 5.43, 0)`: lume hours on the band's outer face |
| **A3 Ecliptic** (high only) | `F3 = F2 * CFrame.Angles(0, rad(23.4) + rad(14)*sin(2π*s.t/27 + 1.1), 0)` | 4.6 | 0.45 | 0.20 | 16 | 1.940 | SILVER | Rocks about the equator's pin axis around the 23.4° obliquity |
| **A4 Pins** (high only) | — | — | — | — | 4 | — | BRIGHT | Cylinders (0.45, 0.30, 0.30): two at `F1 * CFrame.new(±5.56, 0, 0)` (axis X) joining equator to meridian; two at `F2 * CFrame.new(0, ±5.01, 0) * CFrame.Angles(0,0,rad(90))` joining ecliptic to equator |

Max reach of any band from A0 is 6.28. Tilt limits keep every band ≥ 0.6 from the body sample points (head, hands, feet) in the idle
and glide poses. The harness checks this (§18.2).

### 8.3 The orbs: balance, moon, void

**Balance.** The orbs hang at ±12.5 on the viewer's left/right of pivot Pv (§4) and rock ±10° over a 10 s period. One rises as the other
falls, like scales. `swayAmp` ramps 0 → 1 during assembly (1.8–3.0 s). Height range of the orb centres: +3.83 … +8.17.

**M1 Moon**: Silver, MOON, Ball Ø 9. `CF = CFrame.lookAt(moonC, O + Vector3.new(0, 1, 0))`. It is **tidally locked** to the wearer,
so the viewer sees its local +X hemisphere and the crater pattern stays stable.

- Attachment `StreamOut`: `CFrame.new(0, 0, -4.55) * CFrame.Angles(0, 0, rad(90))`. Its X axis points up, so the stream arcs.
- Attachment `KeyLight`: at (0, 4.5, −5.5). It holds PointLight L1 (§11). It lights the moon's wearer-facing top, so the viewer sees a
  lit limb and a terminator, and it rim-lights the wearer at night.
- BillboardGui `Halo`: Size UDim2.new(13, 0, 13, 0), StudsOffset (0, 0, −4.8) (pushed behind the ball), LightInfluence 0,
  Brightness 1.0 → 1.6, MaxDistance 400, AlwaysOnTop false. ImageLabel: Image T("halo"), ImageColor3 (236,240,248),
  ImageTransparency 0.65 → 0.45.

**M2 Craters**: Silver, CRATER, 6 / 4 Cylinders. Each disc has its outer face sunk to `f = sqrt(4.5² − (0.175·Dc)²)` along the unit
direction **u**, centre at `u·(f − 0.2)`, Size (0.4, Dc, Dc), axis along u:
`local = CFrame.new(u*(f-0.2)) * (CFrame.lookAt(Vector3.zero, u) * CFrame.Angles(0, rad(90), 0)).Rotation`.
The white sphere bulges through the middle and leaves a grey crater **rim ring**, raised by up to 0.16 at its edge.

| # | u (unnormalised, moon local) | Ø | low |
|---|---|---|---|
| c1 | (0.80, 0.35, −0.20) | 2.6 | ✓ |
| c2 | (0.70, −0.45, 0.25) | 1.8 | ✓ |
| c3 | (0.95, 0.05, 0.25) | 1.2 | |
| c4 | (0.45, 0.75, 0.30) | 1.6 | ✓ |
| c5 | (0.55, −0.15, −0.70) | 2.0 | ✓ |
| c6 | (0.30, −0.80, −0.25) | 1.4 | |

**V1 Void core**: Dark, VOID (Neon black), Ball Ø 8. `CF = CFrame.lookAt(voidC, O + Vector3.new(0, 1, 0))`.

- `StreamOut` attachment: `CFrame.new(0, 0, -4.05) * CFrame.Angles(0, 0, rad(90))`.
- `RibbonOut` attachment: `CFrame.new(0, -4.05, 0) * CFrame.Angles(0, rad(-90), 0)`. Its X axis points away from the wearer, so the
  ribbon bulges outward first.

**V2 Accretion plane**: Fx, invisible, Size (13, 0.05, 13), CF = `Dk * CFrame.Angles(0, rad(40)*s.now*dir, 0)`. SurfaceGuis on
**Top and Bottom** (2 GUIs), CanvasSize 1024² / 512², LightInfluence 0, Brightness 1.5 → 2.4, Image T("accretion"),
ImageTransparency 0. `dir` (±1) is chosen so the texture's streaks trail the spin; verify in the preview. The opaque core hides the
far half behind it, and the near half crosses in front of the core's lower half: correct occlusion, because the core writes depth.

**V3 VoidSwirl host**: Fx, invisible, Size (13, 0.3, 13), CF = `Dk * CFrame.Angles(0, rad(85)*s.now*dir, 0)`. Host of P1.

**V4 Photon ring**: Lume, LUME, **14 / 8** Blocks in Pf. Segment i at θi = (i + 0.5)·360°/N:
`CFrame.Angles(0,0,-θi) * CFrame.new(0, rt + 0.18, 0)`, Size (2.17 | 3.92, 0.22, 0.12). Sizes are fixed for r = 4.6, so the
segments overlap at any rt ≤ 4.0. The ring always hugs the black silhouette exactly, from any distance, and blooms softly at night
without alpha.

**V5 Lensed arc** (high only): Lume, ARC, **7** Blocks in Pf over θ from −75° to +75° (through the top). θi = −75° + (i + 0.5)·150°/7:
`CFrame.Angles(0,0,-θi) * CFrame.new(0, rt + 0.6, 0)`, Size (1.85, 0.38, 0.10). This is Gargantua's lensed far-side arc over the
shadow.

**V6 Heart**: Lume, LUME. A white 4-point star in Hf.

- Centre Ball Ø 0.70 at Hf origin.
- **Spikes** (up/down h = 2.8; right/left h = 2.2), each from 2 Wedges, Size (0.08, h, 0.32). Spike k with direction αk (0 up, 90
  right, 180 down, 270 left, as the viewer sees it), `S = Hf * CFrame.Angles(0, 0, -αk)`:
  - half A: `S * CFrame.new(-0.16, h/2, 0) * CFrame.Angles(0, rad(90), 0)`
  - half B: `S * CFrame.new(0.16, h/2, 0) * CFrame.Angles(0, rad(-90), 0)`

  (Roblox wedge: the triangle lies in local YZ with the right angle at (−Y, +Z). The +Z back edge becomes the spike's centre line, the
  base sits at the star centre and the apex at h.) Verify the wedge convention in the mock and renderer (§19).
- Low quality: the centre ball plus the up and down spikes only (5 parts).

**V7 Crackle veins** (high only): Lume, VEIN, 5 Blocks in Hf at z +0.02, each joining p0 → p1 (viewer x right, y up):
(0.35, 0.25)→(1.25, 0.95) · (1.25, 0.95)→(1.85, 0.80) · (−0.30, −0.40)→(−1.10, −1.35) · (−1.10, −1.35)→(−1.05, −2.05) ·
(0.40, −0.35)→(1.40, −0.70). Size (0.07, |p1 − p0| + 0.07, 0.05) at the midpoint, `CFrame.Angles(0, 0, atan2(-dx, dy))`.

### 8.4 Beams: streams and ribbon

Beams live in `Fx`. All have FaceCamera true, LightInfluence 0, Segments 20, ZOffset 0. Writes happen only during assembly and on
night ticks.

| Beam | A0 → A1 | Texture (TextureMode, Length, Speed) | Width0 → Width1 | Curve0 / Curve1 | Color | LightEmission day → night | Brightness | Transparency (rest) |
|---|---|---|---|---|---|---|---|---|
| **B1 MoonCore** | moon `StreamOut` → moon palm | T("stream") Wrap 5, +0.8 | 1.4 → 0.30 | 4.0 / 0 | WHITE | 0 → 0.45 | 1.6 → 2.4 | [0, 0.15] [0.12, 0.05] [0.88, 0.05] [1, 0.30] |
| B2 MoonFlow (high) | same | TEX.streak Wrap 7, +1.6 | 0.5 → 0.15 | 4.3 / 0 | WHITE | 0.3 → 0.9 | 2.0 → 2.6 | [0, 0.4] [0.15, 0.2] [0.85, 0.2] [1, 0.6] |
| **B3 VoidCore** | void `StreamOut` → void palm | T("stream") Wrap 5, +0.7 | 1.6 → 0.35 | 3.0 / 0 | (18, 18, 24) | 0 | 1.0 | same as B1 |
| B4 VoidCrackle (high) | same | T("line") Stretch 1, 0 | 0.14 → 0.10 | 2.6 / 0 | WHITE | 0.2 → 0.8 | 1.8 → 2.4 | [0, 0.3] [0.1, 0.1] [0.9, 0.1] [1, 0.5] |
| B5 Ribbon (high) | void `RibbonOut` → `RibbonEnd` | T("ribbon") Wrap 8, −0.5 | 0.9 → 2.2 | 3.0 / −5.0 | (12, 12, 16) | 0 | 1.0 | [0, 0.2] [0.1, 0.05] [0.9, 0.05] [1, 0.3] |
| B6 RibbonEdge (high) | same | T("line") Stretch 1, 0 | 0.12 → 0.12 | 3.3 / −5.3 | WHITE | 0.2 → 0.8 | 1.8 → 2.4 | [0, 0.3] [0.1, 0.1] [0.9, 0.1] [1, 0.4] |

**Flow direction:** the stream textures must visibly flow from the orb **into** the palm, and the ribbon flows down. If they run
backwards in Studio, negate TextureSpeed. This is a checklist item.

### 8.5 Time shards (high only; they ride the ecliptic)

8 small Wedge parts slide along the **inside of the ecliptic ring (A3)** like beads on a wire, or planets on an orrery. Even i:
Silver, BRIGHT. Odd i: Lume, LUME. Size (0.14, 0.7 + 0.15·(i % 3), 0.40).

Shard i: `F3 * CFrame.Angles(0, 0, -(rad(i*45 + 22.5) + rad(22)*s.t)) * CFrame.new(0, 4.0, 0) * CFrame.Angles(s.t*rad(50 + 15*i), s.t*rad(35 - 7*i), 0)`
(an orbit at 22°/s plus a tumble).

Half of them are always in front of the torso, and they never cross a ring: they live on the ecliptic. Clearance to the hands ≥ 0.2,
to the equator ≥ 0.3. They are built, hidden and shown together with the armillary (§13), and are absent on low quality.

### 8.6 The dais (ground)

**daisY.** Let `feetY = s.cf.Position.Y - s.legLen` and `visFeet = feetY + s.hover`.

- `grounded = s.ground ~= nil and (feetY - s.ground.Y) < 7`.
- Target = `s.ground.Y` if grounded. Otherwise (`CONFIG.DAIS_FLOAT`) the dais floats under the flyer at `visFeet - 2.4`.
- `daisY += (target - daisY) * (1 - exp(-8*dt))`. At build, daisY = target (no slide-in from 0).
- Normal jumps (< 7 studs) do **not** move the dais and cause **no transparency writes**.
- The grounded flag only toggles P7 (mist).

| Id | Part | Size / shape | Position in Gd | Material / model | Motion | high / low |
|---|---|---|---|---|---|---|
| D1 Base | Cylinder (0.12, 29.6, 29.6), vertical axis | | (0, 0.06, 0) | BASE, Dark | static | 1 / 1 |
| D2 G0 floor plane | Fx part (29.6, 0.05, 29.6) | SurfaceGui **Top**, T("galaxyFloor"), 1024²/512², Brightness 1.3 → 2.4 | (0, 0.15, 0) | invisible | `CFrame.Angles(0, rad(-6)*s.now, 0)` (clockwise from above; arms must trail) | 1 / 1 |
| D3 G1 arms plane | (21, 0.05, 21) | Top, T("galaxyArms"), 1024², 1.4 → 2.4 | (0, 0.42, 0) | invisible | `rad(+9)*s.now` | 1 / — |
| D4 G2 core plane | (12, 0.05, 12) | Top, T("galaxyCore"), 512²/256², 1.5 → 2.6 | (0, 0.66, 0) | invisible | `rad(-16)*s.now` | 1 / 1 |
| D5 Engraving plane | (40, 0.05, 40) | Top, T("engraving"), 1024², 1.2 → 2.0 | (0, 0.04, 0) | invisible | `rad(+2.5)*s.now` | 1 / — |
| D6 Rim | **30 / 20** Blocks, Size (3.289 \| 4.946, h, 0.80); h = 0.90 even / 0.96 odd (fluted top) | radial 14.75 → 15.55 | `CFrame.Angles(0, θi, 0) * CFrame.new(0, h/2, -15.15)` | SILVER, Silver | static | 30 / 20 |
| D7 Balance wheel | in **Bw**: rim 12 / 8 Blocks (1.338 \| 2.058, 0.30, 0.32) at `CFrame.Angles(0, θi, 0) * CFrame.new(0, 0, -2.30)` · 2 spoke Blocks (4.3, 0.16, 0.22) at yaw 0° and 90° (high) · hub Cylinder (0.5, 0.7, 0.7) vertical axis | | | SILVER rim/spokes, BRIGHT hub, Silver | `wheelAngle = rad(160)·sin(2π·s.t/3.2)·wheelAmp` (smooth swing, the watch's heartbeat; wheelAmp ramps in assembly) | 15 / 9 |
| D8 Hairspring plane | (3.8, 0.05, 3.8) in Bw at (0, 0.22, 0), extra `CFrame.Angles(0, -0.5*wheelAngle, 0)` | Top, T("hairspring"), 512², 1.4 → 2.2 | | invisible | breathes against the wheel | 1 / — |
| D9 Funnel host | (11, 0.4, 11) | | (0, 0.8, 0) · `rad(70)*s.t` (verify the sign makes inflow spiral with the arms) | invisible | spins | 1 / — |
| D10 RibbonEnd | (0.4, 0.4, 0.4) | Attachment at its centre (X axis = tangent) | `CFrame.new(13.2*sin(az), 0.3, 13.2*cos(az)) * CFrame.Angles(0, az, 0)`, `az = atan2(voidC.X - O.X, voidC.Z - O.Z)` | invisible | follows the void's azimuth | 1 / — |

D1 sits on the ground, so it can z-fight with flat ground on its bottom face only, which is unseen. On slopes and steps the dais
stays level and may clip; this is accepted.

### 8.7 Body carriers (Fx, invisible)

- `AirVolume` (36, 20, 36) at `CFrame.new(O + Vector3.new(0, 4, 0))`. Hosts P6a and P6b.
- `BokehHost` (high only) (18, 10, 5) at `V * CFrame.new(0, 3.0, min(7.5, camDist - 4))`. Hosts P6c.
- `PalmMoon` and `PalmVoid` (2.6, 2.6, 2.6). Each frame they are placed at the assigned palm attachment's `WorldPosition` (§10).
  Hosts P10a and P10b.

---------------------------------------------------------------------------------------------------------------------------------

## 9. Particle systems

Defaults for every emitter unless the row says otherwise: LightInfluence 0, TimeScale 1, VelocityInheritance 0, Enabled false until
its assembly time (§12). Keypoint lists are `[time, value, envelope]`. "LE" = LightEmission and "Br" = Brightness (day → night, on
the night tick). "T(...)" = resolved texture (§16), which also sets FlipbookLayout and FlipbookMode for that texture. Rates are
high / low; "—" = not built on low.

| Id | Purpose / path | Host · Shape (Style, InOut, Partial) · EmissionDirection | Texture | Rate | Lifetime | Speed · Spread | Accel · Drag | Size | Transparency | Color | LE · Br | Locked · ZOffset · Rotation / RotSpeed · Orientation |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **P1 VoidSwirl** | matter spirals inward along the disc and vanishes into the black core | V3 · Cylinder (Surface, **Inward**) · Top | T("mote") | 24 / 10 | 1.1–1.3 | 2.2–2.6 · 0 | 0 · 0 | [0, .32] [1, .12] | [0, 1] [.15, .05] [.8, .05] [1, .4] | WHITE → (170,174,184) | .3→.9 · 1.6→2.4 | **true** (the spin turns inward motion into a spiral) · .3 · 0 / 0 · FacingCamera |
| **P2 MoonDust** | dust snows off the moon and falls away below it | M1 ball · Sphere (Surface, Outward) | T("mote") | 12 / 5 | 3.0–4.5 | .25–.6 · 0 | (0, −1.1, 0) · .4 | [0, .1] [.2, .24, .08] [1, .1] | [0, 1] [.12, .08] [.75, .15] [1, 1] | (238,240,246) | .2→.7 · 1.4→2.2 | false · 0 · 0–360 / ±30 · FacingCamera |
| **P3 ShardFeed** | metal shards break off the bezel at 10–11 o'clock and fly across the face into the void | ShardFeed · Box (Volume) · Front (toward the void) | T("shards5") Loop 10–14 fps, StartRandom | 3 / — | 2.9–3.2 | 8.5–9.5 · (6, 6) | 0 · 0 | [0, .5] [.85, .75, .1] [1, .3] | [0, 1] [.06, 0] [.9, 0] [1, 1] | (214,218,226) | 0→.3 · 1→1.6 | false · 0 · 0–360 / ±120 · FacingCamera |
| **P4a SmokeVoid** | dark smoke curls off the void-side rim and drifts back and up | SmokeVoid · Box (Volume) · Right | T("smoke5") OneShot | 5 / 2 | 3.5–4.5 | .6–1.2 · (35, 35) | (0, .5, 0) · .3 | [0, 3] [1, 7.5] | [0, 1] [.2, .30] [.7, .45] [1, 1] | SMOKE | 0 · 1 | false · 0 · 0–360 / ±20 · FacingCamera |
| **P4b SmokeMoon** | silver smoke curls off the moon-side rim | SmokeMoon · Box (Volume) · Left | T("smoke5") | 4 / — | 3.5–4.5 | .6–1.2 · (35, 35) | (0, .5, 0) · .3 | [0, 3] [1, 7] | [0, 1] [.2, .45] [.7, .6] [1, 1] | (196,200,210) | .1→.4 · 1 | same |
| **P5a RimGlints** | slow 4-point glints appear on the bezel metal and fade (grow, hold, shrink: no flash) | RimGlint · **Disc** (Volume, Partial **0.86**, the annulus R 12.2–14.2) · Back (toward the viewer) | T("glint5") | 2.5 / 1 | 1.6–2.2 | 0 | 0 | [0, 0] [.35, .9, .3] [.65, .9, .3] [1, 0] | [0, .1] [1, .1] | WHITE | .5→1 · 1.6→2.4 | **true** · 1.0 · 0–90 / 0 |
| P5b ArmGlints (high) | glints riding the meridian ring | meridian segments 0 and 9 (2 emitters × 0.4 counted as one system) · Box (Volume) | T("glint5") | 0.8 total / — | 1.6–2.2 | 0 | 0 | [0, 0] [.35, .6, .2] [.65, .6, .2] [1, 0] | [0, .1] [1, .1] | WHITE | same | true · .5 · 0–90 / 0 |
| **P6a AirDust** | fine silver dust drifting through everything (scale 1) | AirVolume · Box (Volume) | T("mote") | 26 / 10 | 6–9 | .1–.3 · (180, 180) | 0 · 0 | NumberRange .06–.16 (steady) | [0, 1] [.2, .1] [.8, .15] [1, 1] | (226,230,240) | .2→.8 · 1.4→2.2 | false · 0 · 0 / 0 |
| P6b AirGlints (high and low) | mid-size glints (scale 2) | AirVolume · Box | T("glint5") | 4 / 1.5 | 4–6 | .2–.5 · (180, 180) | 0 · 0 | [0, 0] [.3, .45, .15] [.7, .45, .15] [1, 0] | [0, 1] [.3, .1] [.7, .1] [1, 1] | WHITE | .4→1 · 1.6→2.4 | false · 0 · 0–90 / ±20 |
| P6c Bokeh (high) | big slow out-of-focus discs between the camera and the wearer (scale 3, L7) | BokehHost · Box (Volume) | T("bokeh") | **0.5 → 1.2** (night) / — | 5–7 | .1–.25 · (180, 180) | 0 · 0 | NumberRange 1.2–2.4 | [0, 1] [.25, .6] [.75, .6] [1, 1] | (232,236,246) | .3→.8 · 1.2→1.8 | false · 0 · 0–360 / ±4 |
| P7 GroundMist (high) | one low mist bank at ankle height, only when grounded | D2 plane · Disc (Volume) · Top | T("smoke5") | 2.5 / — | 6–8 | .1–.25 · 0 | 0 · 0 | [0, 8] [1, 14] | [0, 1] [.3, .80] [.7, .82] [1, 1] | MIST | 0 · 1 | true · 0 · 0–360 / ±6 |
| **P8a GalaxyMotes** | motes rise off the turning arms and swirl with them | D2 plane · Disc (Volume, Partial .15) · Top | T("mote") | 18 / 8 | 2.6–3.6 | .5–1.2 · 0 | (0, .35, 0) · .2 | [0, 0] [.2, .3, .1] [1, 0] | [0, 1] [.15, .05] [.8, .15] [1, 1] | WHITE | .3→.9 · 1.6→2.4 | **true** · .2 · 0 / 0 |
| P8b GalaxyAsh (high) | black ash flakes rise against them | D2 plane · Disc (Volume, Partial .15) · Top | T("ash5") Random | 7 / — | 3–4.5 | .8–2.0 · 0 | (0, .3, 0) · .4 | NumberRange .28–.42 | [0, 1] [.15, .05] [.75, .2] [1, 1] | ASH | 0 · 1 | false · 0 · 0–360 / ±90 |
| P9 Funnel (high) | a vortex funnel: streaks spiral inward and climb into the balance wheel | D9 host · **Cylinder** (Surface, **Inward**) · Top | T("streak5") | 16 / — | 1.7–2.0 | 2.8–3.2 · 0 | (0, 1.0, 0) · 0 | [0, .3] [1, .08] | [0, 1] [.12, .05] [.85, .1] [1, 1] | WHITE | .3→.9 · 1.6→2.4 | **true** · 0 · 0 / 0 · **VelocityParallel** |
| **P10a PalmMoon** | silver motes converge into the moon palm (the palm drinks the stream) | PalmMoon · Sphere (Surface, **Inward**) | T("streak5") | 14 / 6 | .85–.95 | 1.35–1.45 · 0 | 0 · 0 | [0, .22] [1, .04] | [0, 1] [.25, .05] [1, .2] | WHITE | .3→.9 · 1.6→2.4 | false · .2 · 0 / 0 · VelocityParallel |
| **P10b PalmVoid** | ink motes converge into the void palm | PalmVoid · same | T("streak5") | 14 / 6 | same | same | 0 · 0 | same | same | INK | 0 · 1 | same |
| **P11a/b FootDrip** | time drips off each sole onto the balance wheel | foot attachments (§10), 1 emitter each · EmissionDirection Bottom | T("mote") | 4 / 2 each | .6–.8 | .1–.3 · (8, 8) | (0, −5, 0) · 0 | [0, .14] [1, .06] | [0, .1] [.8, .2] [1, 1] | WHITE | .3→.9 · 1.6→2.4 | false · 0 · 0 / 0 |

Totals: **18 emitters** high (P5b counted once; it is two small emitters on 2 segments, so 19 instances) and **11** on low.
Total Rate ≈ **162/s** high (161 by day) and **54/s** on low. Particles alive ≈ 510 high and 160 low.

Notes:

- P1, P8a and P9 rely on `LockedToPart` with a host that **rotates**. Locked particles live in the host's frame, so straight inward
  motion becomes a spiral.
- Shape semantics to confirm in Studio (§19): Disc `ShapePartial` = inner-radius fraction; the Cylinder and Disc shapes are oriented by
  EmissionDirection; `Inward` points velocity toward the shape's axis or centre. Fallbacks if any differs: P1/P9 become Disc + Surface
  + Speed 0 + locked spin (a rotating ring of motes); P10 becomes Sphere + Outward with negative Speed.
- Day vs night: LE and Br switch on the night tick. Smoke and ash stay at LE 0 (dark shapes carry the day). White systems keep
  LE ≤ 0.3 by day, so they rely on their ink-rim textures rather than additive glow. P6c Rate changes with n. P7 toggles with
  `grounded`. P3 and P6c are high only.

---------------------------------------------------------------------------------------------------------------------------------

## 10. Character integration

- **Pose:** `End.pose` is copied **verbatim from pass 4** (hover 2.4, bob 0.28, bobSpeed 1.4, idle, glide, breathe and suppress
  tables). Reason: it already floats the wearer with arms out, which presents both palms to the streams. Glide leans forward
  (Root −18°), and pass 5 matches that by leaning the armillary and shard orbit (A0) by the same angle. Changing the framework's motor
  list is out of scope.
- **Palms (stream ends + intake hosts).** Find the hand parts, R15 first then R6:
  `RightHand`/`LeftHand` (R15) or `Right Arm`/`Left Arm` (R6), via `ctx.char:FindFirstChild` (never WaitForChild).
  - On each hand, create our own Attachment `TheEndPalmR` / `TheEndPalmL`.
  - Position: copy `RightGripAttachment.Position` / `LeftGripAttachment.Position` if that child exists. Otherwise use
    `(0, -hand.Size.Y/2, 0)` (R15) or `(0, -1, 0)` (R6).
  - No hand parts at all: put the attachments on `PalmMoon` / `PalmVoid` and place each carrier at its assigned side: left
    W(−2.3, −0.3, −0.5), right W(2.3, −0.3, −0.5).
- **Which palm gets which stream** (orbs are viewer-anchored): let `f = W.RightVector:Dot(V.RightVector)`.
  - `f > 0.2` → the wearer's right hand is on the viewer's right: void → right palm, moon → left palm.
  - `f < -0.2` → moon → right palm, void → left palm.
  - In between: keep the previous assignment (hysteresis). Initial assignment by the sign of f.
  - On a flip, write only `Attachment1` of B1–B4 (4 writes). `PalmMoon` / `PalmVoid` follow their assigned palm's `WorldPosition`
    every frame through the BulkMoveTo list.
- **Feet.** Create attachments `TheEndSoleL` / `TheEndSoleR` on `LeftFoot`/`RightFoot` (R15, at `(0, -Size.Y/2, 0)`) or
  `Left Leg`/`Right Leg` (R6, at `(0, -1, 0)`). They host P11a/b: time drips onto the balance wheel 0.35 below the soles.
  - At night the wheel's PointLight L2 (§11) lights the feet from below. This is the "foot glow", with no billboard.
- **Body clearance:** nothing solid passes within 0.6 of the head, torso, hands or feet (§18.2). The armillary and the shards on it
  cross in front of the body without touching it (shards keep ≥ 0.2 from the hands).
- **Cleanup:** every attachment and emitter created on the character is listed and destroyed in `fx.destroy()`.
  `fx.setVisible(false)` disables the foot emitters, because they live outside our model.
- **Sitting / walking / flying:** everything follows O and W. The dais stays on the ground for walks and normal jumps and floats under
  the flyer when the ground is more than 7 studs away. The clock drops 0.5, steps back 2 and leans 14° further back in a glide.

---------------------------------------------------------------------------------------------------------------------------------

## 11. Day / night

**Night factor:** `n = max(smoothstep(17.5, 19, ct), 1 - smoothstep(5, 6.5, ct))`, with `ct = Lighting.ClockTime`.
Samples: 12:00 → 0, 18:00 → 0.26, 18:30 → 0.74, 19:00 → 1, 05:30 → 0.74, 06:00 → 0.26.

- Evaluate on a timer every `CONFIG.NIGHT_INTERVAL = 1.0` s (the first evaluation runs at build).
- Quantise to steps of 0.05. Call `applyNight(nq)` **only when nq changes**.
- No brightness ever steps within a frame: during dusk each change is ≤ 0.05 per second.

| Property | Day (n = 0) | Night (n = 1) | Count |
|---|---|---|---|
| Highlight FillTransparency / OutlineTransparency | 0.55 / 0.35 | 0.80 / 0.70 | 1 |
| Inlay GUI Brightness | 1.6 | 2.6 | 1 |
| Sub-dial, hairspring Brightness | 1.4 | 2.2 | 2 |
| Accretion GUIs Brightness | 1.5 | 2.4 | 2 |
| Galaxy G0 / G1 / G2 Brightness | 1.3 / 1.4 / 1.5 | 2.4 / 2.4 / 2.6 | 3 |
| Engraving Brightness | 1.2 | 2.0 | 1 |
| Moon halo Brightness / ImageTransparency | 1.0 / 0.65 | 1.6 / 0.45 | 1 |
| Corona `Enabled` / ImageTransparency | false (n ≤ 0.05) / — | true / 0.60 | 1 |
| PointLight L1 (moon key) Brightness, Range 22, Color (226,232,246), Shadows false | 0 (Enabled false) | 1.5 | 1 |
| PointLight L2 (wheel underlight, high only) Brightness, Range 12, Color (230,234,246), on the wheel hub | 0 (Enabled false) | 0.9 | 1 |
| White emitters LE / Br | per §9 | per §9 | ~12 |
| Beams LE / Br | per §8.4 | per §8.4 | 6 |
| P6c Rate | 0.5 | 1.2 | 1 |

All values interpolate linearly with nq.

- **Day reads by value structure:** the dark dial ring, black void, black disc lanes, dark dais pool and dark smoke sit against the
  white moon, white Neon lume, white inlays and silver metal with an ink Highlight contour. Nothing depends on additive white by day.
- **Night:** the inlays, galaxy and accretion bloom softly through Brightness above the Bloom threshold. Neon lume and the photon ring
  glow. The moon shows a lit limb from its key light, the corona appears, and the wheel light glows on the feet.

---------------------------------------------------------------------------------------------------------------------------------

## 12. Equip assembly (≈ 6 s, mechanical, no flash) and unequip

`age` = seconds since build. Helpers:

- `easeOutBack(u) = 1 + 2.25*(u-1)^3 + 1.25*(u-1)^2` (c1 = 1.25: about 6 % overshoot, then it locks exactly at 1).
- `smooth(u) = u*u*(3 - 2u)`.

Every part starts at **Transparency 1**, sitting at its start pose. A part's transparency goes `1 → rest` over its *fade window* (writes
only while its value changes by ≥ 0.03). Its CFrame moves from start to rest over its *motion window*:
`cf = rest:Lerp(start, 1 - easeOutBack(u))`, with position from easeOutBack and rotation through Lerp. Emitters switch on at their
time. Spin-ups (accretion, gears) add an integrated extra angle (`extra += (rate - runRate)*dt`) on top of the running angle
(`rad(runRate)*s.now`), so nothing jumps when the spin-up ends. After `age > 6.5` no assembly code runs.
**There is no pulse and no flash.** The only screen-wide change is the wearer-only grade.

| Time (s) | What locks in | Start pose → rest | Fade window |
|---|---|---|---|
| 0.0 | **Grade** (local wearer, real equip only, as pass 4) | ColorCorrection `TheEndReveal` under the camera tweens to Saturation −0.75, Brightness −0.1, Contrast 0.15, Tint (232,238,255) over 1.2 s Sine; from 5.8 s tweens back over 2.2 s, then destroys itself | — |
| 0.0–1.2 | **Void core** condenses | `Size` Ø 0.6 → 8 by easeOutBack (Size writes on 1 part, assembly only) | 0.0–0.4 |
| 0.25–1.4 | Photon ring | segment i slides radially from R 11 to rest, start 0.25 + 0.04·i, 0.6 s each | first 0.2 s of each |
| 0.3–1.1 | Accretion disc | spin rate 400°/s decays to 40°/s by `40 + 360*exp(-3*(age-0.3))` | ImageTransparency 0.3–1.1 |
| 0.6–1.8 | **Moon rises** with its craters | from V y −9 (out of the dais) up to Pv | 0.6–0.9 |
| 0.7–1.4 | Lensed arc | from rt + 3 → rt + 0.6 | 0.7–0.9 |
| 0.9–1.5 | Heart spikes and veins extend | from the star centre (local y 0) outward | 0.9–1.1 |
| 1.2 | P1 VoidSwirl on | | |
| 1.0–2.4 | **Meridian** and pins | from lying flat on the dais (frame `Gd * CFrame.new(0, 0.95, 0) * CFrame.Angles(rad(90), 0, 0)`) up to F1 | 1.0–1.3 |
| 1.3–2.7 | **Equator** and ticks | same start, up to F2 | 1.3–1.6 |
| 1.4–2.2 | Moon halo | | ImageTransparency |
| 1.6 | P2 MoonDust on | | |
| 1.6–3.0 | **Ecliptic** | same start, up to F3 | 1.6–1.9 |
| 1.8–3.0 | Balance sway | swayAmp 0 → 1 (smooth) | — |
| 2.0–3.6 | **Bezel sweep** | segment i flies in from (R + 7, z − 4, θ + 40°), start 2.0 + 0.9·i/N (clockwise from XII), 0.7 s | first 0.25 s |
| 2.3–3.8 | **Chapter ring** | segment i from z −3, start 2.3 + 0.9·i/N, 0.6 s | first 0.25 s |
| 2.5 | P6a, P6b dust on | | |
| 2.6–3.6 | **Gears GA–GD** slide out from behind the dial | from (0.3·cx, 0.3·cy, −4) to rest; spin rate 300°/s → running rate (exp) | 2.6–2.9 |
| 3.0–3.6 | GE (from z −3), GH and GI (from z +3) | | 3.0–3.2 |
| 3.0–3.95 | Rete bars | bar k from radius ×2.2, start 3.0 + 0.04·k, 0.5 s | first 0.15 s |
| 3.0 | P6c bokeh on | | |
| 3.2–3.6 | Sub-dial | from z −2 | 3.2–3.4 |
| 3.2 | P4a, P4b smoke on | | |
| 3.4–4.15 | Hour plots set in | plot h from z +3, start 3.4 + 0.04·h, 0.3 s | first 0.1 s |
| 3.4–4.2 | Inlay GUI | | ImageTransparency |
| 3.6–4.8 | **Hands spin in and lock** | hour from θ −330°, minute from −1050°, seconds from θs(now) − 720°, by easeOutBack; the seconds hand then runs | 3.6–3.8 |
| 3.6–4.2 | Highlight | Fill and Outline transparency 1 → target | — |
| 3.8 | P5a, P5b glints on | | |
| 4.0–4.4 | Dais base disc | | 4.0–4.4 |
| 4.0–5.25 | **Dais rim wave** | segment i rises from y −1.2, start 4.0 + 0.8·i/N, 0.45 s | first 0.15 s |
| 4.2–4.8 | **Crown, stem, cap, bow** drop in | from y + 6 | 4.2–4.4 |
| 4.2–5.2 | Galaxy G0/G1/G2, engraving, hairspring GUIs | | ImageTransparency |
| 4.6–5.8 | **Balance wheel** starts swinging | wheelAmp 0 → 1 | 4.6–4.9 |
| 4.6–5.4 | Streams and ribbon | Beam Transparency sequences scaled from fully transparent to rest (≤ 20 writes) | — |
| 4.8 | P3 ShardFeed, P7 mist, P8a/b, P9 funnel on | | |
| 5.0–6.25 | **Time shards** fly from the bezel rim (K point at R 14, angle 300° + 20°·i) onto their ecliptic slots | start 5.0 + 0.06·i, 0.8 s | first 0.2 s |
| 5.0–6.0 | Corona (if night) | | ImageTransparency to its night value |
| 5.2 | P10a/b palm intake, P11 drips on | | |
| 5.8–8.0 | Grade eases back (wearer only) | | |

- **Who sees it:** the assembly plays on every build (`CONFIG.ASSEMBLY_REMOTE = true` also for other players' auras). The grade plays
  only for `ctx.isLocal` and only if `os.clock() - spawnedAt[ctx.char] > 4`, with pass 4's `spawnedAt` logic copied exactly (not on
  spawn or join).
- **Framework alpha** (`s.alpha`, 0 → 1 over 0.9 s at build; it may fall on unequip): the effective fade for each part is
  `assemblyFade × s.alpha`. After the assembly, while `s.alpha < 1` (unequip), every visible part, GUI and beam writes
  `rest + (1 - rest)*(1 - alpha)` on changes ≥ 0.04, and emitters switch off below alpha 0.6. `fx.destroy()` may arrive at any moment
  and must still clean everything.
- `CONFIG.ASSEMBLY = false` jumps straight to rest at build.

---------------------------------------------------------------------------------------------------------------------------------

## 13. LOD, low quality, near-camera rules

Every part belongs to exactly **one** hideable group, and each group carries two flags: `detail` (hidden when far, §13.1) and
`armillary` (hidden when the camera is inside the rings, §13.3). A group is shown only when none of its flags hides it. Groups:
`Core` (no flags), `Detail` (detail), `Armillary` (armillary: the three bands), and `ArmillaryDetail` (both: equator ticks, pins and
time shards).

### 13.1 Far LOD (`fx.setDetail(false)`, framework: past ~110 studs)

- All emitters off (framework rule).
- The **Detail** group is hidden: its sub-models are parented to nil and dropped from the move list. Detail = hour plots, rete, bow,
  equator ticks, pins, craters, lensed arc, veins, time shards, GH, GI, G1 plane, engraving plane, hairspring plane, corona plane,
  bokeh host and ShardFeed host. That is **94 parts**: high moves 266 parts when far, low moves 145.
- Beams B2, B4, B6 are disabled. Lights are disabled.
- `setDetail(true)` restores everything (one parent write per sub-model).
- Past ~320 studs the framework calls `setVisible(false)`: the root is parented to nil and the foot emitters are disabled.

### 13.2 Low quality (`ctx.quality == "low"`)

Built with the low counts in every table (149 parts, 11 emitters, 7 GUIs, 2 beams, 1 light).

- Dropped entirely: hour plots, rete, bow and cap, corona, the ecliptic and pins, equator ticks, GB/GC/GD/GH/GI, lensed arc, veins,
  time shards, G1, engraving, hairspring, funnel, ribbon, bokeh, mist, ash, moon-side smoke, ShardFeed, B2/B4/B5/B6 and L2.
- CanvasSizes are halved and shadows are off.
- The Highlight is kept (`CONFIG.HIGHLIGHT_LOW = true`) because it carries the monochrome look by day.
- The rest is identical, including the assembly (shorter: the absent parts are simply not built).

### 13.3 Near-camera rules (all wearers; state flips only, with hysteresis)

| Rule | Hide when | Show when | Action |
|---|---|---|---|
| Armillary (inc. ticks, pins and the time shards) | `|camPos − A0| < 7.0` | `> 8.0` | parent its sub-models to nil and drop from the move list |
| Bokeh P6c | `|camPos − O| < 9` | `> 10` | `Enabled` |

First person and close zoom never put rings or blobs across the lens. The clock, orbs, streams and dais stay.

---------------------------------------------------------------------------------------------------------------------------------

## 14. Budget (asserted by the harness)

| Item | High | Low | Limit |
|---|---|---|---|
| **Parts moved per frame** (one `BulkMoveTo`) | **360** | **149** | ≤ 360 / ≤ 150 |
| — clock C1–C11 | 182 | 69 | |
| — armillary A1–A4 | 68 | 24 | |
| — moon M1–M2 | 7 | 5 | |
| — void V1–V7 | 38 | 16 | |
| — time shards | 8 | 0 | |
| — dais D1–D10 | 53 | 32 | |
| — body carriers | 4 | 3 | |
| Parts moved when far (Detail hidden) | 266 | 145 | |
| ParticleEmitters | 18 systems (19 instances) | 11 | ≤ 20 / ≤ 12 |
| Total Rate (particles/s) | ≈ 162 | ≈ 54 | ≤ 200 / ≤ 80 |
| Beams | 6 | 2 | ≤ 6 / ≤ 3 |
| SurfaceGuis + BillboardGuis | 10 + 1 = 11 | 6 + 1 = 7 | ≤ 12 / ≤ 8 |
| PointLights | 2 | 1 | ≤ 2 |
| Highlights | 1 | 1 | = 1 |
| Character-parented instances | 4 attachments + 2 emitters | same | all cleaned in destroy |
| Per-frame property writes after `age > 6.5` and alpha = 1 | 0 GUI or Transparency writes. Event writes only: night tick ≤ 1/s, palm flip, near-camera flips, grounded flip, Size writes during assembly | | |

---------------------------------------------------------------------------------------------------------------------------------

## 15. CONFIG flags and the film-mesh upgrade

`local CONFIG = {...}` sits at the top of the module. Any **attribute on the ModuleScript with the same name and type overrides the
default** at require time, so Milo can flip flags in Studio without editing code. Read once and type-checked; a wrong type is ignored
with a warn.

| Flag | Default | Purpose |
|---|---|---|
| `USE_FILM_MESHES` | false | Master switch for every `FILM_*` flag below |
| `FILM_BEZEL` | false | `RingG` replaces C1 (32 segments → 1 MeshPart) |
| `FILM_DIAL` | false | `Dial` replaces C2 (if the Dial is a solid disc it covers the skeleton; judge by screenshot) |
| `FILM_RETE` | false | `Astrolabe` replaces C5 |
| `FILM_HANDS` | false | `Hand` replaces the hour and minute hand bodies (shaft, tip, tail); the lume strips stay |
| `FILM_GEARS` | false | `Gear` replaces each gear's disc, web, teeth and spokes (hub kept), scaled per gear Dtip |
| `FILM_MOON` | false | `Oblivion.Moon` replaces M1 (the craters are dropped) |
| `FILM_VOID` | false | `Oblivion.SmoothSphere` replaces V1 (Material Neon, Color 0,0,0 forced) |
| `FILM_HAND_FLIP` | false | Turn the film hands 180° if their tip points at the hub |
| `FILM_KEEP_TEXTURES` | false | Keep each film MeshPart's TextureID (otherwise cleared and recoloured per §7) |
| `VIEWER_ANCHOR` | true | §5. false = body-anchored fallback |
| `CLOCK_DIST` / `CLOCK_HEIGHT` / `CLOCK_TILT` | 8 / 9.6 / 8 | Clock placement (§4) |
| `YAW_SPRING` | 6.5 | Spring frequency in rad/s (95 % settle in 0.73 s) |
| `HIGHLIGHT` / `HIGHLIGHT_LOW` | true / true | Silver-tone Highlight (§7.2) |
| `SHADOWS` | true | Moon and void core cast shadows (high only) |
| `ASSEMBLY` / `ASSEMBLY_REMOTE` | true / true | §12 |
| `GRADE` | true | Wearer-only equip grade |
| `DAIS_FLOAT` | true | Dais floats under the feet when airborne |
| `NEAR_HIDE` | true | §13.3 |
| `NIGHT_INTERVAL` | 1.0 | Seconds between day/night evaluations |
| `DEBUG` | false | Print counts (parts, emitters, GUIs, beams) once at build |

**Film-mesh lookup (never yields; any failure falls back to procedural for that element only, inside `pcall`):**

```lua
local RS = game:GetService("ReplicatedStorage")
local cinema = RS:FindFirstChild("AuraCinema")
local assets = cinema and cinema:FindFirstChild("Assets")
local te = assets and assets:FindFirstChild("TheEnd")
local function meshOf(o)            -- MeshPart, or the first MeshPart inside a Model or Folder
	if not o then return nil end
	if o:IsA("MeshPart") then return o end
	return o:FindFirstChildWhichIsA("MeshPart", true)
end
local function film(name) return meshOf(te and te:FindFirstChild(name)) end            -- RingG, Dial, Astrolabe, Hand, Gear
local obl = (te and te:FindFirstChild("Oblivion")) or (assets and (assets:FindFirstChild("Oblivion") or assets:FindFirstChild("Oblivion", true)))
local function oblivion(name) return meshOf(obl and obl:FindFirstChild(name)) end      -- Moon, SmoothSphere
```

Reject the mesh if it is nil, has an empty `MeshId`, or any `Size` component < 0.01.

**Normalisation** (the template's current `Size` is its bounding box; `MeshSize` is not scriptable):

1. **Disc-like** (RingG, Dial, Astrolabe, Gear):
   - The thinnest axis becomes the depth axis (K z). The other two must be round: `max/min ≤ 1.15`, else reject.
   - Scale `k = targetØ / max(other two)`. New size = `Size*k`. If the scaled thin size falls outside [0.3, 3]× the target depth, set it
     to the target depth (MeshParts scale non-uniformly).
   - Targets: RingG Ø 28.24 × 2.5 at K z −0.2. Dial Ø 25.0 × 0.5 at K z −0.15. Astrolabe Ø 18.2 × 0.24 at K z +0.27. Gear Ø = Dtip,
     depth = d.
2. **Hand:** the longest axis becomes K y (toward XII), and the thinnest of the remaining two becomes K z. Scale so the longest
   axis equals the procedural hand's tip-to-tail length (hour 8.55: tail −1.6 to tip +6.95; minute 11.17: −2.0 to +9.17). Put the
   bounding-box centre at the length midpoint (hour y = 2.67, minute y = 3.58) in the hand frame Hh. Flip 180° about z if
   `FILM_HAND_FLIP`.
3. **Sphere** (Moon Ø 9, SmoothSphere Ø 8): uniform scale to the target Ø. Reject if `max/min > 1.1`.
4. **Rotation from axis assignment:** `R = CFrame.fromMatrix(Vector3.zero, img(X), img(Y), img(Z))`, where `img(a)` is the K axis
   assigned to the mesh's local axis a. If `img(X):Cross(img(Y)):Dot(img(Z)) < 0`, negate `img` of the middle axis so the frame is
   right-handed.
5. Clone, set the §8 properties (Anchored, no collisions or queries, CastShadow false, Locked, Massless), Material and Color per §7
   (TextureID cleared unless `FILM_KEEP_TEXTURES`), `RenderFidelity = Automatic`, then put it in the right sub-model. It replaces the
   procedural parts in its rigid group with the same assembly timing. The budget drops; nothing else is added.

---------------------------------------------------------------------------------------------------------------------------------

## 16. Textures

### 16.1 Tables in the module

Keep pass 4's `TEX` table **verbatim** (all ids already uploaded). Add `TEX5`, which Milo's Mac fills after upload (ids stay `""` until
then), and a resolver:

```lua
local TEX5 = { -- te5 uploads (textures/te5/); "" until uploaded from the Mac
	dialInlay = "", subdial = "", accretion = "", galaxyFloor = "", galaxyArms = "", galaxyCore = "", engraving = "",
	halo = "", hairspring = "", stream = "", ribbon = "",
	shards5 = "", smoke5 = "", mote = "", glint5 = "", bokeh = "", streak5 = "", ash5 = "",
}
local TEX5_LAYOUT = { shards5 = { "Grid4x4", "Loop" }, smoke5 = { "Grid4x4", "OneShot" }, ash5 = { "Grid2x2", "Random" } }
local FALLBACK = { -- key -> { pass-4 TEX key, layout, mode }
	dialInlay = { "dialOuter" }, subdial = { "dialInner" }, accretion = { "galaxy4" }, galaxyFloor = { "galaxy4" },
	galaxyArms = { "galaxy4" }, galaxyCore = { "ornate" }, engraving = { "gring" }, halo = { "rim" }, hairspring = { "swirl" },
	stream = { "line" }, ribbon = { "line" },
	shards5 = { "ash", "None", "Loop" }, smoke5 = { "puff", "Grid4x4", "OneShot" }, mote = { "glow" }, glint5 = { "glint" },
	bokeh = { "glow" }, streak5 = { "spark" }, ash5 = { "ash", "None", "Loop" },
}
-- T(key) -> id, layoutName, modeName   (layout "None" when not a flipbook)
```

Emitters must apply the **layout and mode returned by `T`**, because a fallback can have a different layout from its te5 texture.
`T` accepts both `"rbxassetid://123"` and bare digits in TEX5.

### 16.2 Texture jobs (2 groups; generators in python3 + numpy + PIL, render at 2× then downsample; PNGs in `textures/te5/`)

General rules:

- Premultiplied-correct edges: colour pixels carry the stroke colour, never colour blended with black, so there are no fringes.
- Greyscale only (B ≥ R, spread ≤ 20).
- No hard square edges: every alpha reaches 0 at least 4 % inside the frame or cell.
- Contact sheets go over both a dark (20, 22, 28) and a sky-cyan (120, 200, 255) background.

**Group "surfaces"**

| File | Size | texKey → fallback | Spec |
|---|---|---|---|
| `te5_dial_inlay.png` | 1024² | dialInlay → dialOuter | Overlay for the 24.4-stud inlay plane (image radius r: 1 = 12.2 studs). Alpha 0 except strokes. Strokes are white (250) with a 2 px ink outline (10, 10, 14, alpha 0.9) and 1 px AA. Contents: (a) outer track circle r 0.985, 3 px; (b) inner track circle r 0.955, 2 px; (c) 60 minute ticks from r 0.955 to 0.985, 2 px, every 5th from r 0.94 and 5 px wide; (d) Roman numerals I–XII, **radial** (glyph tops point outward; XII upright at the top), spanning r 0.80–0.93, built procedurally from thick-thin serif strokes (thick 0.016, thin 0.007; I = bar with serifs, V = two slanted bars, X = two crossed slanted bars), no font file; (e) inner edge ring r 0.775, 2 px; (f) small 4-point stars (size 0.025) at the 12 half-hours, r 0.865. |
| `te5_subdial.png` | 512² | subdial → dialInner | For the Ø 6.5 sub-dial face. Transparent background. Outer ring r 0.96 (3 px, white plus ink). 60 ticks r 0.88–0.94 (1.5 px; every 5th 3 px from r 0.84). Guilloché rosette: 24 circles of radius 0.30 centred on a circle of radius 0.30, 1.5 px white at alpha 0.85, clipped to r < 0.78. Centre ring r 0.12, 3 px. |
| `te5_accretion.png` | 1024² | accretion → galaxy4 | Top-down accretion disc for the 13-stud plane (r 1 = 6.5 studs). Alpha: 0 for r < 0.68, ramps to 1 over 0.68–0.72, 1 to r 0.86, smoothstep to 0 at r 1.0. Luminance `L = clamp((0.72/r)^3.2, 0, 1)` (white-hot inner edge r 0.72–0.74 forced to 1.0). Modulate by streaks: `s = (0.5 + 0.5*cos(9*(θ + 2.2*ln r) + warp))^3`, warp = fbm × 0.25 rad, `L *= (0.65 + 0.35*s)*(0.85 + 0.3*fbm)`. Three opaque **black dust lanes** spiral (θ + 1.6 ln r = k·2π/3, Gaussian width 0.1 rad) over r 0.78–0.97: `L *= 1 - 0.92*lane`. Alpha stays 1 in the lanes. RGB = L·255 with B = min(255, 1.03·R). |
| `te5_galaxy_floor.png` | 1024² | galaxyFloor → galaxy4 | Dais pool (Ø 29.6). Alpha 1 to r 0.86, smoothstep to 0 at 1.0. **Opaque near-black base** (RGB 8–14 plus fine noise). A barred 2-arm spiral: bar along θ = 0 to r 0.18 (L 0.85). Log-spiral arms (pitch 16°) from the bar ends, winding **counter-clockwise outward** with image +y up. Arm cores L 0.95 near the bar falling to 0.25 by r 0.85; angular width grows 0.18 → 0.35 rad. A thin black lane (L 0.02, 0.05 rad) on each arm's inner edge. 60 bright knots (2–5 px) along the arms; 1500 single-pixel stars (L 0.4–1.0). Core Gaussian σ 0.06 at L 1.0 plus bulge σ 0.15 at L 0.5. Mean L inside r < 0.86 ≈ 0.22: a dark pool with white arms. |
| `te5_galaxy_arms.png` | 1024² | galaxyArms → galaxy4 | Floating arm layer (Ø 21). Transparent background. The same 2-arm spiral rotated 90°, pitch 13°, **arms only**: alpha = arm profile (1 at the arm core, Gaussian falloff, cut below 0.05). RGB white (L 0.9–1.0) with filament noise. A **black lane** (RGB 10, alpha 1, 0.04 rad) on each arm's leading edge. Knots. The outer 15 % fades. |
| `te5_galaxy_core.png` | 512² | galaxyCore → ornate | Inner layer (Ø 12). Transparent background. White core alpha 1 to r 0.08, soft to 0.25. 4 tightly wound thin arms (pitch 10°) from r 0.1 to 0.8, cores at alpha 0.9, each with a thin black lane. Alpha 0 beyond r 0.85. |
| `te5_engraving.png` | 1024² | engraving → gring | Ground ring for the 40-stud plane (r 1 = 20 studs). Alpha 0 except strokes; white (240) with a 2 px ink edge (20). Circles at r 0.78 (3 px), 0.80 (2 px), 0.965 (2 px), 0.985 (4 px). 120 ticks r 0.94–0.965 (1.5 px; every 10th from 0.92, 4 px). Radial Roman numerals I–XII at r 0.83–0.91 (same glyph builder, height 0.08). 12 small diamonds at the half-hours, r 0.87. |
| `te5_halo.png` | 512² | halo → rim | Rim-only halo: alpha 0 for r < 0.66, smooth rise to 0.95 at r 0.74, then a soft tail: 0.35 at 0.82, 0.10 at 0.90, 0 at 1.0. RGB white. Used by the moon halo (13 studs) and the night corona (40 studs). |
| `te5_hairspring.png` | 512² | hairspring → swirl | Archimedean spiral `r = 0.12 + 0.8*θ/(2π*9)` over 9 turns. Stroke 3 px white with a 1.5 px ink edge. A terminal stud (filled circle r 0.025) at the outer end and a collet ring (r 0.10, 4 px). Transparent elsewhere. |
| `te5_stream.png` | 256×64 | stream → line | Beam band, tiled in U (seamless). v ∈ [−0.5, 0.5] across. Alpha 1 for \|v\| < 0.40 with a 1.5 px AA edge. **Ink edges** (RGB 12) for \|v\| 0.32–0.40. A white core (base L 0.8) for \|v\| < 0.30 with 5–7 brighter longitudinal filaments (L 1.0) that wave with a period of 256 px. 2 px transitions. |
| `te5_ribbon.png` | 256×128 | ribbon → line | Ink ribbon, tiled in U (seamless). Body alpha 1 for \|v\| < 0.46. RGB ink (14, 14, 18) with ±6-level longitudinal streaks. White hairlines (245, 2 px) at \|v\| 0.40–0.43 on both sides. A faint white centre filament (1 px, L 0.6) waving with a period of 256 px. |

**Group "particles"**

| File | Size | Flipbook | texKey → fallback | Spec |
|---|---|---|---|---|
| `te5_shards.png` | 1024² | **Grid4x4**, Loop | shards5 → ash | A tumbling metal sliver: an irregular thin quad prism with vertices (−0.30, −0.42), (0.22, −0.35), (0.34, 0.40), (−0.12, 0.46) × 0.8 of the cell and thickness 0.06. 16 frames rotate 22.5° each about the axis normalize(0.35, 1, 0.2), for a seamless loop. Flat shading: front face L 0.86, back face L 0.25, sides L 0.55, a 1 px specular line on the lit edge, and a 2 px ink outline (10) round the silhouette. Alpha 1 inside, 1 px AA, ≥ 20 % padding. |
| `te5_smoke.png` | 1024² | **Grid4x4**, OneShot | smoke5 → puff | A curling smoke tendril evolving over 16 frames: domain-warped fbm (4 octaves) density inside a soft blob whose radius grows 0.22 → 0.42 of the cell while a spiral (curl) warp grows. Early frames are dense and crisp; late ones thin and wispy. Alpha peaks at 0.85 (frames 2–4) and is ≤ 0.35 by frame 15. It is multiplied by a radial window that reaches 0 at 0.46 of the cell (no square edges). RGB 0.75–1.0 internal shading, so a dark particle Color keeps its structure. Dither the alpha (no banding). |
| `te5_mote.png` | 128² | — | mote → glow | Core disc r < 0.22 (alpha 1, RGB 255). Ink rim r 0.22–0.30 (RGB 18, alpha 0.85) so it reads on a bright sky. Glow r 0.30–0.5 (RGB 255, alpha 0.25 → 0, smooth). |
| `te5_glint.png` | 256² | — | glint5 → glint | 4-point glint. Horizontal and vertical spikes span the full width; thickness 6 px at the centre tapering to 0.5 px at the tips; alpha 1 → 0 toward the tips. 45° spikes at half length 0.45 with alpha 0.5. Core disc r 0.05 at alpha 1. A thin ink halo r 0.07–0.09 (RGB 15, alpha 0.6). |
| `te5_bokeh.png` | 256² | — | bokeh → glow | A hexagonal aperture disc (circumradius 0.46, corners rounded 15 %). Interior alpha 0.55 with radial brightening L 0.9 → 1.0. Rim band (outer 8 %) alpha 0.85. 2 px AA, faint onion-ring noise ±0.03 alpha. White. |
| `te5_streak.png` | 64×256 | — | streak5 → spark | A **vertical** matter streak for VelocityParallel. Capsule from y 0.06 to 0.94, 12 px wide: a white core 6 px (alpha 1) and 2 px ink edges (RGB 15, alpha 0.9). The upper (leading) end is brightest; the tail fades over the lower 40 %. |
| `te5_ash.png` | 256² | **Grid2x2**, Random | ash5 → ash | 4 irregular charred flakes (jagged 7–9-gons, 0.6–0.8 of the cell). Body RGB 14–22 at alpha 1 with faint fibre texture. A 1 px silver edge highlight (RGB 190) on the upper-left edges. ≥ 12 % padding. |

---------------------------------------------------------------------------------------------------------------------------------

## 17. Module structure and the frame loop

### 17.1 Framework contract (unchanged from pass 4)

- `End.pose`: pass 4 verbatim.
- `End.build(ctx) -> fx`, with `ctx = { char, hrp, hum, quality = "high"|"low", isLocal, container }`.
- `fx.update(dt, s)`, with `s = { cf, hover, glide, t, now, legLen, ground (Vector3|nil), alpha }`.
- `fx.setVisible(on)`: the root is parented to `on and ctx.container or nil`, and the foot emitters are disabled while hidden.
- `fx.setDetail(isNear)`: §13.1.
- `fx.destroy()`: idempotent.
- The module must `require` headless: no yields at top level or in build, guard `Players.LocalPlayer == nil`, guard
  `workspace.CurrentCamera == nil`, and use `game:GetService` for Lighting, Players and TweenService.
- Style: tabs, pass-4 helper style (`new`, `seq`, `n`), and short plain-English comments saying what you see.

### 17.2 Build order

1. `CONFIG` plus attribute overrides.
2. The root model and the Silver, Dark, Lume and Fx sub-models.
3. Highlight (Fill/Outline transparency 1).
4. Each component in §8 order: parts registered with `{part, group, local, restTransparency, assembly}`.
5. Attachments, beams and GUIs.
6. Emitters (Enabled false).
7. Lights (Enabled false).
8. Character attachments and emitters.
9. Optional film meshes.
10. Build the move list arrays `parts[]` and `cfs[]` (`table.create`).
11. Grade (if equip).
12. `root.Parent = ctx.container`.
13. Initialise ψ, yawW, daisY and the night factor.

### 17.3 `fx.update(dt, s)` outline

```lua
function fx.update(dt, s)
	dt = math.min(dt, 0.1); age += dt
	local O = s.cf.Position + Vector3.new(0, s.hover, 0)
	-- 1 frames: yawW -> W; camera + spring -> psi -> V; K; A0 -> F1/F2/F3; Pv -> moonC/voidC; n, dc -> Hf, Pf, rt; Dk; daisY -> Gd; Bw
	-- 2 group CFrames for every shown group (gears and hands use s.now; sway, gimbals and wheel use s.t)
	-- 3 cfs[i] = groupCF * local[i]   (while age < 6.5: lerp from the assembly start pose per §12)
	workspace:BulkMoveTo(activeParts, activeCfs, Enum.BulkMoveMode.FireCFrameChanged)
	-- 4 event writes only:
	--   assembly fades / Size / beam transparency while age < 6.5;  unequip fades while s.alpha < 1
	--   palm flip (Attachment1 x4);  near-camera flips (§13.3);  grounded flip (P7 Enabled)
	--   night timer >= NIGHT_INTERVAL -> applyNight(nq) if changed
end
```

Rules:

- **One** BulkMoveTo per frame.
- No `Instance.new`, no table allocation and no closures inside update. Reuse the arrays; only CFrame and Vector3 values are made.
- The active move list is rebuilt only when a group is shown or hidden (§13).
- Part rest transforms are precomputed at build.
- GUI and Transparency properties are never written in steady state.

### 17.4 `fx.destroy()`

1. Destroy the root (which takes the Highlight, beams, GUIs and Fx carriers with it).
2. Destroy the grade (if any).
3. Destroy the 4 character attachments, which takes the foot emitters with them.
4. Clear the arrays.
5. Set `destroyed = true` so a late `update` returns at once.

Nothing may remain under `ctx.char`, `workspace.CurrentCamera` or `ctx.container`.

---------------------------------------------------------------------------------------------------------------------------------

## 18. Test plan

### 18.1 Cloud harness scenarios (headless Luau + mock Roblox API; snapshots per `tools/harness/SNAPSHOT.md`)

Canonical wearer:

- R15 mock, HRP at (0, 10, 0), LookVector −Z; `hover` 2.4 with bob ±0.28 at 1.4 Hz; `legLen` 3; ground (0, 7, 0); glide 0;
  `isLocal` true; quality high; ClockTime 14; FOV 70.
- Hands at W(±2.3, −0.3, −0.5), feet at W(±0.5, −3.0, 0).

The **owner camera** is `O + (0, 2.0, 12.5)` looking at `O + (0, 1.5, 0)` (behind the wearer).

| Id | Scenario | Inputs | Frames |
|---|---|---|---|
| S01 | assembly-owner-day | owner camera | t = 0 … 7 every 0.25 s, plus t = 10 |
| S02 | front-day | camera = HRP + f·40 + r·14 + (0, 10, 0) → HRP + (0, 6, 0) (the pass-4 capture camera) | t = 10 |
| S03 | front-night | S02 with ClockTime 0.5 | t = 10 |
| S04 | camera-orbit | camera orbits O at radius 30, height +8, 45°/s for 8 s | every 0.1 s |
| S05 | top-down | camera O + (0, 45, 0.01), then an elevation sweep 45° → 89° | t = 10 … 14 |
| S06 | first-person | camera at O + (0, 2.0, −0.3) looking forward, then turning 180° over 2 s | t = 10 … 12 |
| S07 | glide-airborne | glide 0 → 1 over 1 s, HRP moving 40 studs/s along −Z, ground nil | t = 8 … 12 |
| S08 | jump | ground present; HRP Y arc +6 over 0.9 s | t = 10 … 11 every 0.05 s |
| S09 | low-quality | S02 with quality low | t = 0 … 7, plus t = 10 |
| S10 | far-LOD | S02, `setDetail(false)` at t = 10, `true` at t = 11 | |
| S11 | remote-wearer | `isLocal` false, camera = another player in front at 25 studs | t = 0 … 10 |
| S12 | r6-rig | S02 with an R6 mock (Right Arm / Left Arm / Right Leg / Left Leg, Torso) | t = 10 |
| S13 | film-flags | all `FILM_*` true: (a) no AuraCinema in the mock; (b) a mock AuraCinema with MeshParts of odd sizes (RingG 10×10×1 thin on X, a Hand with its long axis on Z, a non-round Dial) | t = 10 |
| S14 | destroy | after S01 → `destroy()` → `update()` again | |
| S15 | unequip | alpha 1 → 0 over 0.9 s at t = 10 | |
| S16 | dusk | ClockTime 17 → 20 over 30 s simulated | every 0.1 s |
| S17 | close-zoom | owner camera at 6 studs (O + (0, 1.8, 6)) | t = 10 |
| S18 | wearer-spin | camera fixed (S02), wearer yaw rotates 360° over 6 s | every 0.1 s |
| S19 | no-camera | `workspace.CurrentCamera = nil` for 10 frames | |

### 18.2 Automated acceptance checks (fail the run on any)

1. **Budgets** (§14): moved parts ≤ 360 / 150, emitters, total Rate, beams, GUIs, lights ≤ 2, Highlights = 1.
2. **Part flags:** every part is Anchored with CanCollide, CanQuery and CanTouch false. CastShadow is false except moon and void on
   high.
3. **Write discipline:** after t > 7 with alpha = 1, there are 0 writes to any GUI property or BasePart.Transparency, apart from
   night-tick writes (≤ 1 per simulated second, and only when nq changed). There are 0 `Instance.new` calls inside update. There is
   exactly 1 BulkMoveTo per update.
4. **Monochrome:** every colour has spread ≤ 20 and B ≥ R.
5. **Opacity:** no part, GUI, or beam (measured by its width) > 6 studs across has a uniform transparency in [0.3, 0.8]. Only the §7.3 soft list is exempt.
   Structural parts are at rest Transparency 0 after the assembly.
6. **No flash:** between consecutive frames no Brightness or LightEmission changes by more than 0.1, no Transparency (outside
   assembly and unequip) changes by more than 0.05, and no emitter Transparency curve rises then falls within < 0.3 s of its lifetime.
   Renderer: frame-to-frame mean luminance of aura pixels in S04 changes < 2 %.
7. **Far side:** for S04/S11/S18 after the spring settles, `(clockCentre − O)·(O − camPos)` > 0 horizontally. The step response
   reaches 95 % within 0.8 s, never overshoots, and has no NaN. S05/S06 hold the yaw (ψ changes < 0.5° while degenerate).
8. **Clearances** (§6): the void disc vs the clock front ≥ 0.7; the armillary bounding torus/sweep vs moon and void ≥ 0.8; armillary
   vs body sample points (head sphere r 0.7 at O+2; torso box; hands r 0.4; feet r 0.5) ≥ 0.6 in idle and glide; armillary vs the void
   accretion disc ≥ 0.2; time shards vs hands ≥ 0.2; the clock bottom ≥ 0.2 above the dais layers; no part below `daisY − 0.05` except the dais base underside; the moon halo billboard ≥ 0.4 from
   every SurfaceGui plane.
9. **Character:** palm and sole attachments are created on the right parts (R15 and R6). The palm flip happens only across f = ±0.2.
   After `destroy()` nothing is left on the character, camera or container (S14), and `update()` after destroy is a no-op.
10. **Film flags:** (a) falls back silently with no yields; (b) normalised sizes are within 2 % of target, the thin axis maps to K z,
    and the non-round Dial is rejected.
11. **Assembly:** at t = 6.5 every part sits at rest (CFrame error < 0.001) at rest transparency. No part's transparency goes 0 → >0
    → 0 during the assembly (no blink). The grade exists only for `isLocal` with a real equip.
12. **Dais:** S08 → the dais Y never changes and there are no transparency writes. S07 → the dais floats 2.4 below the visible feet.
13. **LOD:** S10 → 94 detail parts parented out (high), the move list = 266, emitters off; everything restored at t = 11.

### 18.3 Preview renderer views (and what to look for)

| View | Camera | Pass when |
|---|---|---|
| P1 front day | S02 | The clock reads as a **solid object**: a silver fluted ring with a dark chapter ring, gear teeth breaking the silhouette at 1:30/4/8/10:30, crown and bow at the top. Numerals are legible at this distance. Moon on the left, void on the right, the disc's near half crossing the core. A dark dais pool with white arms inside a silver rim. Nothing ghostly. |
| P2 front night | S03 | Inlays, lume, photon ring and galaxy arms glow. The moon shows a lit limb. The corona rings the bezel. Particles are visible. |
| P3 owner | S01 at t = 10 | The dial face is seen over the wearer's shoulders, hands at XII above the head, and the world visible through the skeleton gaps. The orbs sit near the screen edges. Nothing blocks the character. |
| P4 side | camera O + 30·W.Right + (0, 6, 0) | The clock faces the camera beyond the wearer. The armillary rings cross in front of the torso. The disc does not touch the clock. Depth layering is obvious. |
| P5 high 3/4 | O + 25·f + (0, 25, 0) | The dais bowl, the floating arm layers' parallax, the balance wheel under the feet, the ribbon landing on the rim. |
| P6 clock close-up | O + 22·f + 10·r + (0, 12, 0) → clock centre | The bezel band thickness, flutes, chapter ring step, gears at 3 depths, hands above the dial. |
| P7 void close-up | 14 studs from voidC | The photon ring hugs the silhouette with a gap, then the lensed arc over the top, the heart and veins, and spiral matter. |
| P8 low quality | S09 at t = 10 | The same composition reads with fewer details. Polygon facets stay acceptable. |
| P9 assembly strip | S01 frames 0–6.5 | Void → moon → rings unfold → bezel sweep → gears → hands lock → dais wave. No frame is brighter than its neighbours. |

### 18.4 Studio install checklist (later, on Milo's Mac; nothing here is claimed tested)

1. Back up the live `ReplicatedStorage.AuraFX.TheEnd`, install `roblox/ReplicatedStorage/AuraFX/TheEnd.lua`, and check it compiles.
   Upload `textures/te5/*.png`, fill in `TEX5`, and record the ids in `textures/te5/uploaded.md`. First test once **with fallbacks**
   (TEX5 empty) and then with te5.
2. Play, equip The End. Capture: the reveal (owner view, grade dims and returns, no pulse or flash); day (ClockTime 14) and night (0.5)
   from the pass-4 front camera; default-zoom owner view; zoomed out to 25; first person; orbiting the camera fast (spring lag, no
   jitter); camera straight above.
3. Movement: walk, run/glide (clock leans back, armillary leans, the dais floats when high), jump (the dais stays), sit, R15 and R6
   avatars.
4. Day colour: silver must look neutral, not cyan. Toggle the Highlight attribute off and on to compare. The black void stays pure
   black.
5. Phone / low quality (Studio device emulator plus graphics level 1–3): budgets, readability.
6. Other players: Test → 2 players. The remote wearer's clock faces *your* camera, there is no grade on the other client, and the
   assembly plays.
7. Flow directions: streams flow into the palms, the ribbon flows down, accretion streaks and galaxy arms trail their spin. Fix signs
   via `dir` / TextureSpeed if not.
8. Particle shape semantics (§19): VoidSwirl and Funnel spiral **inward**, the palm intake converges, rim glints sit on the bezel.
9. Film-mesh flags: set the module attributes `USE_FILM_MESHES` plus each `FILM_*` one at a time, and screenshot each. Keep only the
   ones that look better. Try `FILM_HAND_FLIP` if the hand points inward.
10. Performance: MicroProfiler / Stats with 1 and 3 wearers on screen. Frame time increase < 1.5 ms for 1 wearer on the Mac.
11. Update `docs/memory/aura-rng.md` and CHANGELOG, and show Milo thumbnails.

---------------------------------------------------------------------------------------------------------------------------------

## 19. Risks and Studio-verify items

| Risk | Mitigation |
|---|---|
| **Owner's view is busier**: the clock is 20 studs from a default-zoom camera, 69° tall, with orbs at the screen edges | A skeleton dial (about 40 % open) and thin bands. The camera never sees the clock from behind and nothing sits between the camera and the wearer. Tunables: `CLOCK_DIST`, `CLOCK_HEIGHT`. |
| Highlight looks wrong (too flat or grey) or costs too much on phones | A single Highlight on the Silver model only. Fallback: `HIGHLIGHT = false` and silver turns cyan by day (still monochrome-ish). Possible later: warm-compensate SILVER to (184, 180, 182). |
| ParticleEmitter shape semantics differ (Disc ShapePartial as inner radius; Cylinder/Disc orientation from EmissionDirection; Inward) | Every inward system has a documented fallback (§9 notes). Studio checklist item 8. |
| Roblox wedge orientation assumed (right angle at (−Y, +Z)) | The harness mock and renderer implement this convention. Studio check on the heart spikes. If wrong, swap the halves' `±90°`. |
| Transparent sorting between stacked galaxy GUI planes | They are concentric, so the per-object sort is right for any camera above +0.33 studs. The opaque base disc writes depth under them. |
| The billboard-cut lesson | Only one BillboardGui (the moon halo), checked ≥ 0.4 from every GUI plane. All void details are geometry. |
| Viewer anchoring means each client sees a different layout | Intended. Screenshots differ per viewer. `VIEWER_ANCHOR = false` restores body anchoring. |
| 360 parts × several wearers on low-end PCs | Low quality has 149 parts, and far LOD moves 266 / 145. THE END is 1 in a billion (rarely more than 1–2 per server). Measure in Studio. |
| Film meshes: unknown pivots and orientations | Normalisation by bounding box plus `FILM_HAND_FLIP`, all default OFF, with a per-element procedural fallback. |
| Uneven ground: the flat dais clips steps and slopes | Accepted (pass 4 did too). The dais stays level and its rim hides small offsets. |
| Unknown framework unequip behaviour | Both alpha fade-out and immediate destroy are handled. |
| Fallback textures differ from te5 (e.g. the galaxy4 accretion has a bright centre) | The core sphere hides the centre. Geometry carries the look. Test once with fallbacks before uploading. |

**Studio-verify list** (the builder marks these `-- STUDIO-VERIFY:` in code):

- The disc emitter partial-ring semantics.
- Inward cylinder and sphere emitters.
- LockedToPart on a spinning BulkMoveTo host.
- Wedge orientation.
- The SurfaceGui Face Back/Left mapping for the inlay and sub-dial.
- Beam TextureSpeed direction.
- The Highlight covering a Model with 200+ parts.
- That a Neon black ball renders pure black under Bloom.
- The PointLight attachment on a moving part.
