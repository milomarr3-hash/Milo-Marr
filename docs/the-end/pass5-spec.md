# THE END — pass 5 design spec: "The Last Clock" (equipped aura)

Status: definitive design for the pass-5 **equipped** aura of 『 THE END 』 (1 in 1,000,000,000). Not the cutscene.
**Updated after review round 1** (see `pass5-build-notes.md`, "Review round 1"): the numbers below are the built ones; the
main additions are the movement plate (C12), the close-camera layout (§4, §5), the lag cap (§5), the moon face (§8.3), the
moon/void smoke (§9), the speed trail (P12), sitting / jump / slope handling (§8.6), remote ghosting (§13.3) and the
Studio-flip flags (§15).
**Updated again after review round 2** (build notes, "Review round 2"): the opaque camera-facing moon face (§8.3), neutral silvers
(§7.1), particles with opaque cores up to 2 studs and the time-dust ring (§7.3, §9), the event-horizon glow and finer void
details (§8.3), the default-zoom layout and the first-person look-follow (§4, §5), the upright armillary, the jump height ride and
the dais layer lift (§4, §8.6), split ghosting and the far-detail fade (§13), and the hide/show lifecycle (§12, §17.3).
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
| "more feel toward the build" | THE END becomes a machine built from about 360 parts. It has a fluted silver bezel, a recessed dark chapter ring with inlaid numerals and lume plots, a skeleton dial with an openwork star rete, 7 toothed gears (spokes and hubs, turning at fixed meshed rates), hands with lume, and a crown and bow. A 3-ring gimballed armillary with pins surrounds the wearer. A balance wheel swings under his feet, and the galaxy sits as a raised-rim dais. On equip the parts fly in and lock into place with a small overshoot (§12). |
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
an ink stream from the void into the other. Below is a galaxy dais: a dark pool, Ø 30, with white arms, a raised silver rim and
floating arm layers, inside an engraved clock-ring stage Ø 56 (review round 3; the ink ribbon of the first build became the void's
lensed disc). A balance wheel swings under the feet. Particles do work: matter, shards,
smoke, glints, sparks and dust. The palette is black, white and silver. It moves like a mechanism: constant rotations, smooth
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
                          '-..___  VI ___..-'              \      void accretion disc
             ________________[balance wheel]________________\     wheel  -3.35 below O (under the feet)
           (====== dark galaxy pool, white arms, raised silver rim Ø31 ======)   ground
       ( - - - - - - - - engraved clock-ring stage Ø56 on the ground - - - - - - - - )

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
| **cz, fp** (camera closeness) | `zoomD` = the horizontal camera distance from O, smoothed `1 - exp(-3*dt)`; `cz = smooth((ZOOM_FAR 30 - zoomD) / (ZOOM_FAR - ZOOM_NEAR 14))` (0 at 30+ studs: the showcase layout; 1 at Roblox's 12.5 default zoom); `fp = smooth((4 - zoomD) / 2.5)` for the owner only (first person) | |
| **Vk** (height ride, review round 2) | `V + (0, kY − O.Y, 0)`: `kY` is a critically damped spring on O.Y (k 4 grounded, 12 flying or seated; set to O.Y after a long hide), so a jump does not throw the clock and the orbs (§8.6) | as V |
| **K** (clock) | `Vk * CFrame.new(0, Hc, -Dc) * CFrame.Angles(0, rad(ya), 0) * CFrame.Angles(rad(-tilt), 0, 0)` with `Hc = 9.85 - 0.5*g - 3*cz + 16*fp - 3*sit`, `Dc = 8 + 2*g + D*cz + 6*fp - 2*sit` (**D = 32 for the owner, 16 for other players' auras**: review round 2, `CLOSE.dist` / `CLOSE.distRemote`), `tilt = clamp(8 + 14*g + 4*speed + 24*cz - 32*fp, -10, 50)`, `ya = 9 + 5*sin(2π*s.t/16)`; then `Hc >= daisY + layer + 1.2 - kY + 14.2*cos(tilt) + (tilt >= 0 and 1.44 or 1.12)*|sin(tilt)|` (the bezel's lowest edge, its back face leaning back or its front face leaning forward, clears the dais rim by 0.24; review round 3); for the owner `Dc += fitD` (the frame fit, §5); on a slope rising behind the wearer `Hc >= minHc + min(4, rise*Dc)` (§8.6); another wearer's clock `Dc += yieldD` (§5) | x = viewer's right, y = toward XII, **z = toward the viewer** (+z is in front of the dial). The top leans away from the viewer. `sit`, `speed`: §8.6 / P12 state, smoothed 0..1. |
| **clock angle θ** | Measured **clockwise from XII as the viewer sees it**. Point at radius r: `(r*sin θ, r*cos θ, z)`. A part laid along the radius at θ: `CFrame.Angles(0, 0, -θ) * CFrame.new(0, r, z)`. | |
| **A0** (armillary) | `CFrame.new(O + (0, 1.3 - 1.0*sit + lift, 0)) * W.Rotation`; `lift` (smoothed, rate 6, never more than 0.3 behind) = how far the lowest ring edge (meridian reach 6.23, equator 5.54, ecliptic 4.79, from each ring's normal; review round 3's finer rings) would dip below `daisY + layer + 0.96 + 6.3*tan(slope)` | **Upright** (review round 2): leaning it with the glide (−18°·g) laid the dark equator across the head line from the follow camera, hiding the head and shoulders in 31 % of walking samples (now 4 %). The body's glide pose and the clock's +14°·g tilt carry the forward motion. |
| **Pv** (balance pivot) | `Vk * CFrame.new(0, 6.0 - 5*cz, 1.5 - 18*cz*(1 - fp) + 1.5*fp - yieldD) * CFrame.Angles(0, 0, β)`, `β = rad(10) * sin(2π*s.t/10) * swayAmp` (review round 3: lower and **well behind the wearer** when the camera is close, so at the default zoom the moon sits beside the dial at about its size (226 px, was 337) and clear of the HUD's stats panel; in first person 3 studs behind the camera, about 100° off the line of sight, outside the field of view) | Moon centre `moonC = (Pv * CFrame.new(-arm, 0, 0)).Position`, void centre `voidC = (Pv * CFrame.new(arm, 0, 0)).Position`, `arm = 12.5 + 2*cz` (a little wider close up; the void stays ≥ 13.4 studs out, so its disc clears the rings). |
| **n, dc** | `n = unit(camPos - voidC)`, `dc = max(|camPos - voidC|, 5)` | `up = (|n.Y| > 0.98) and Vector3.zAxis or Vector3.yAxis` (passed as the 3rd argument of every lookAt below). |
| **Hf** (heart) | `CFrame.lookAt(voidC + n*4.1, voidC, up)` | x = viewer's right, y up, z toward the viewer. Same for Pf. |
| **Pf** (photon) | `CFrame.lookAt(voidC + n*zt, voidC, up)`, `zt = 16/dc` (R²/dc with R = 4) | Ring radius `rt = 4*sqrt(1 - 16/dc^2)` = the silhouette circle of the core seen from the camera. |
| **Dk** (accretion) | `CFrame.new(voidC) * V.Rotation * CFrame.Angles(rad(24), 0, 0)` | The disc normal tilts 24° toward the viewer (reads as a disc, not a line), so the viewer sees its top face. The near half dips in front of the core's lower half. |
| **Gd** (dais) | `CFrame.new(O.X, daisY + layer, O.Z) * tiltTo(gn)` (review round 3: tilted to the fitted ground plane `gn`, §8.6; level when no clean plane fits, flying or seated) | daisY and the per-wearer `layer` lift in §8.6. |
| **Bw** (wheel) | `CFrame.new(O.X, y, O.Z) * CFrame.Angles(0, wheelAngle, 0)`, `y = max(lerp(O.Y - s.legLen - 0.9, dY + 1.2, sit), dY + 1.2 + 2.5*tan(slope))`, `dY = daisY + layer` | 0.9 under the soles (the wearer floats free of it); on the dais when seated; always level (it carries the far beacon) |

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
- **Lag cap (review round 1).** Players swing the camera at 90-720°/s, where the spring alone would trail 27-140° and throw the
  clock and orbs (which ride V) into the lens. The spring's own lag `x` is clamped to ±2·L (outward velocity zeroed) and the
  lag that is shown is `L·tanh(x/L)`, `L = rad(CONFIG.YAW_LAG_MAX = 22)`: V uses `yawTarget + L·tanh(x/L)`. Nearly identical for
  small lags, never past ~22°. Measured: at 180°/s and in a 0.25 s half-turn flick the orbs stay ≥ 16.7 studs from the camera
  (3.9 before).
- Init at build: `yawTarget = psi` = the yaw from the current camera, or `yawW` if degenerate (as if seen from behind, the owner's
  usual view). `psiVel = 0`.
- **Remote wearers:** identical code using *this* client's camera, so every viewer sees the face. No replication is needed.
- **Very close camera / first person** (`dh ≤ 1.5`, the camera nearly level with the wearer, `|v.Y| < 4`; review round 2): "beyond
  the wearer" becomes **where the camera looks**: `yawTarget = atan2(-look.X, -look.Z)` from `Camera.CFrame.LookVector` (unless it
  looks nearly straight up or down). Roblox turns the character with the camera in first person, so holding the yaw put the void
  (8 studs of Neon black plus its smoke) straight ahead at ~13 studs whenever the player turned 90°. Now the lifted clock rides
  in the sky ahead, the orbs hang about 97° off the line of sight (Pv, §4) and the palm streams switch off. The near-camera rules
  in §13.3 fade out the armillary, shards and bokeh.
- **After a long hide** (more than 0.5 s, e.g. the roll cutscene; review round 2): the first visible frame snaps the yaw spring,
  the zoom factor, the dais, the height ride and the ring lift to where they belong instead of springing in from where they were.
- **Camera directly above** (`dh ≤ 0.2·|v.Y|`, steeper than about 79°): yaw is held, so the clock does not spin. From above you see its
  top edge, the crown and the bow.
- **Frame fit (owner only; review round 3, R3W-1).** The close-camera form only worked round 12.5-20 studs: between ~22 and
  ~40 studs (`cz` ramps out) the 36-stud watch towered over the frame and XII was cut at the usual downward pitch. Now the
  clock steps back along the view until the point `FRAME_TOP` studs above its hub (default 9.6 = the XII numeral, the hands at
  midnight) is inside the top of the frame:
  `lim = min(1.45, asin(look.Y) + rad(FieldOfView) * 0.455)` (the frame's top edge less ~3°),
  `push = clamp((kY + Hc + FT*cos(tilt) - camPos.Y) / max(tan(lim), 0.05) - dh - FT*sin(tilt) - Dc, 0, CLOSE.dist + 1.1*max(0, FT - 9.6)) * (1 - fp)`,
  smoothed `1 - exp(-3*dt)` (snapped after a long hide), `Dc += fitD`. Looking more than ~32° down the push reaches its cap
  continuously (nothing can fit then). Measured on the critic's prototype: XII in frame at every zoom from 12.5 to 60 at 15-27°
  of pitch; the studio 40-stud view unchanged. `FRAME_TOP = 22.4` fits the whole watch with its bow (smaller at the default
  zoom), `0` turns it off: an A/B for Milo.
- **Another wearer's clock in front of yours (review round 3, R3W-4).** The owner's build publishes its hub (`ownerHub`, a
  module-level value cleared when hidden or destroyed). A remote build tests the segment camera → ownerHub against where its
  own clock disc (R 14.5) and orbs (5.5 / 7.0) would stand without stepping back; while it hits (held 1.5 s) its clock and
  orbs step back along the view (`yieldD`, spring rate 3, at most 48) until they stand 12 studs behind your hub: smaller,
  still solid (no pale ghost). Measured: `pair_behind` and `pair_side` hide your hub or XII in 0 of 11 samples (11/11 before).
- **Teleports and bad frames (review round 3, CR3-01, R3S-9).** A move of 30+ studs, or more than 8 vertically, in one frame
  snaps the springs like a long hide (a teleport is not a fall). A NaN position or hover skips the frame; a spring state that
  went NaN anyway snaps everything next frame. A NaN camera position keeps the last good one.
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
| **Ground** | — | Dark dais pool Ø 29.6, silver rim Ø 31.1, floating arm layers at +0.42 and +0.66, engraved stage Ø 56 (review round 3; was Ø 40), balance wheel 2.05 above the ground under the feet; on a gentle slope the dais lies along the ground (§8.6) |

**Clearances** (the harness asserts each, §18.2). Void disc far edge vs clock front: ≥ 0.7. Armillary sweep (max reach 6.28 from
A0) vs moon/void surfaces: ≥ 0.8. Armillary vs the void's accretion disc: ≥ 0.2. Armillary vs head, hands and feet sample points:
≥ 0.6. Time shards vs hands: ≥ 0.2. Clock bottom (−4.26 nominal, −4.54 at the
bob low point) vs dais layers (≤ −4.74): ≥ 0.2. Meridian bottom (−4.46) vs G2 (−4.74): ≥ 0.25.

---------------------------------------------------------------------------------------------------------------------------------

## 7. Materials, colours, opacity

### 7.1 Palette

| Token | RGB | Material | Reflectance | Sub-model | Used for |
|---|---|---|---|---|---|
| SILVER | 186, 184, 183 | Metal | 0.08 | Silver | bezel, rete, gear discs/teeth/spokes, meridian, ecliptic, dais rim, wheel rim/spokes, hand bodies |
| BRIGHT | 226, 224, 223 | Metal | 0.12 | Silver | hubs, crown, cap, stem, pins, silver time shards, seconds weight |
| STEEL | 44, 46, 51 | SmoothPlastic | 0 | Dark | chapter ring, gear webs, hub base |
| DEEP | 30, 31, 35 | SmoothPlastic | 0 | Dark | sub-dial |
| BASE | 12, 12, 16 | SmoothPlastic | 0 | Dark | dais base disc, movement plate (C12) |
| VOID | 0, 0, 0 | **Neon** | 0 | Dark | void core (renders pure black, ignores the sky tint) |
| LUME | 240, 240, 242 | Neon | 0 | Lume | hour plots, hand lume, equator ticks, seconds tip, hub jewel, photon ring, heart, Neon time shards (neutral: Neon saturates any tint) |
| ARC | 210, 210, 212 | Neon | 0 | Lume | lensed arc |
| MOON | 234, 236, 240 | SmoothPlastic | 0 | Silver | the film-mesh moon only (`FILM_MOON`) |
| SATIN | 143, 141, 140 | Metal | 0.08 | Silver | odd bezel flutes, odd dais-rim blocks, equator band (light/dark structure in the metal) |
| MOONCORE | 184, 186, 192 | SmoothPlastic | 0 | Dark | the Ø 6 moon core and the 9-stud opaque moon face disc (§8.3), outside the Highlight |

**Review round 2, the silvers.** Under the cyan day sky (with the Highlight on) round 1's cool silvers (B − R +12 to +14 in the
token) measured B − R +22 to +39 in the preview: baby-blue plastic, not silver. The silvers are now neutral, a hair warm (B − R −3):
measured B − R +4 to +10 on the bezel by day (rings at the default zoom +15) and +1 to +2 at night, where there is no sky tint.
VEIN and CRATER were removed with the veins and the craters.

Particle and beam colours keep pass 4's `WHITE (248,249,255)`, `SILVER (222,228,240)`, `INK (5,5,8)`, `SMOKE (14,14,19)`, plus
`MIST (205,209,220)` and `ASH (16,16,20)`.

**Monochrome rule** (asserted): every Color3, ColorSequence key and ImageColor3 has a max channel spread ≤ 20 and B ≥ R − 3 (cool or
neutral, never visibly warm; the harness's palette lint flags saturation > 0.15). The one deliberate exception is the Highlight's
FillColor (216, 212, 208): a correction filter that cancels the cyan the day sky puts on Metal (§7.2).

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

**Highlight `TheEndTone`:** FillColor (216, 212, 208) (review round 2: was (205, 208, 215)), FillTransparency 0.65 (day, attribute
`HIGHLIGHT_FILL`) → 0.80 (night), OutlineColor (10, 10, 14), OutlineTransparency 0.35 (day, attribute `HIGHLIGHT_OUTLINE`) → 0.70
(night), DepthMode Occluded. **Close up the ink outline eases off** (review round 2): the day outline strength is multiplied by
`1 − 0.6·cz` (cz in 0.05 steps), so it is 0.35 from 30 studs out and about 0.74 at Roblox's default zoom, where the metal fills the
view and reads by its own shading (a full contour made it look cel-shaded). Fill and outline are written separately, each only
when it moves (so a `HIGHLIGHT_FILL` of 1 still gets its outline).
**One rule for its slot** (review round 2): built for every wearer on high, but on low only for the owner; `Enabled` = not ghosted
and (the owner's, or within the far-detail range), so a far-away wearer frees one of the client's 31 Highlights and its outline
pass, and the owner's own never does. It covers **only the Silver model**. That neutralises the cyan sky
tint on the metal and adds an ink contour that reads on a bright sky. It must **not** cover dark parts: a 45 % grey fill would lift
black steel to mid grey and the void to grey. Neon parts are emissive and stay out of it too. Cap: 31 per client, and this aura uses
1. During assembly its Fill/Outline transparency fades from 1 to target over **5.65–6.35 s**, after the last silver part is
solid (a Highlight paints a part that is still fading in at full strength, which made the rising dais rim pop).

### 7.3 Opacity rules

- **Opaque (Transparency 0):** every structural part in §8.
- **Luminous details are opaque images, glowing through Brightness, not alpha:** inlay numerals and minute track
  (ImageTransparency 0), sub-dial, galaxy arms, engraving ring. Day Brightness ≤ 1.6 (below the place Bloom threshold of
  about 2). Night Brightness 2.2–2.6 (soft bloom).
- **Discs** (accretion, galaxy floor) are opaque in the body, with white arms **and** black lanes at alpha 1. Alpha fades only over the
  outer 12–15 % and the inner hole edge.
- **Soft elements allowed (the only ones):** the moon halo (rim-only, 0.65 day / 0.45 night, fading out as the camera comes
  close), the night-only bezel corona (rim-only), the event-horizon glow (rim-only particles, §8.3 V4b), bokeh (peak 0.72), smoke
  (peak 0.08 dark / 0.32 silver; review round 3: the void's ink smoke is a dense billow, so it reads as ink, not a teal veil), one ground mist (peak 0.80), translucent particles ≤ 0.6 studs, and **particles with an opaque
  core** (peak transparency ≤ 0.15: motes, glints, streaks, shards, ash) **up to 2 studs** (review round 2: at Milo's 36-40-stud
  framings a 0.6-stud mote's opaque core was about 3 px, so the particles added almost nothing; pass 4's sparkles, which do show in
  the real captures, were 0.6-1.4 studs at Brightness 2.4).
- **BANNED:** any element > 6 studs across with uniform transparency between 0.3 and 0.8; trails on big slow parts; additive-only white
  that must carry the look by day. **Deleted from pass 4:** Shards plane 48, corona sprite 32, moon glow 24, dark halo sprites, body
  glow 15, the broad 8-wide ribbon band, RingA/RingB image rings, ground Swirl 36, air mist haze, the 58-stud ground ring, the
  column-of-light beams, every "faint back face", the **equip pulse**, and all BillboardGuis except the moon halo.
- **No BillboardGui may intersect a SurfaceGui plane** (pass-4 lesson: it gets cut). This is why the void's heart, photon ring and
  lensed arc are geometry and its glow is particles. The moon halo is the only BillboardGui; it keeps ≥ 0.4 studs from every GUI
  plane (checked in §18.2). The moon's face is an opaque part (§8.3), not a billboard.

---------------------------------------------------------------------------------------------------------------------------------

## 8. Components

Every part: `Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Massless = true,
Locked = true`, start `Transparency = 1` (the assembly sets it to its rest value). Fx carrier and GUI-plane parts stay at
Transparency 1 forever (only their GUIs fade). Exception: the moon and void core have
`CastShadow = CONFIG.SHADOWS and not low`. Cylinder parts have their axis on local X: Size = (length, Ø, Ø).
**Disc orientation** (axis along K z): `CFrame.Angles(0, rad(90), 0)`. **Vertical axis**: `CFrame.Angles(0, 0, rad(90))`.

### 8.1 The clock (frame K)

**C1 Bezel**: Silver, SILVER (even) / SATIN (odd: the raised flutes read darker). Fluted coin edge. **N = 32 / 20** Block segments. Segment i: θi = (i + 0.5)·360°/N.
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

**C5 Rete** (high only): Silver, SILVER, group **Core** (kept at every distance: it is the dial's far silhouette). An openwork {12/5} star. 12 Blocks, Size (17.58, 0.26, 0.20). Bar k joins star points k and
k+5 on R 9.1. Its midpoint lies at radius 2.355 at angle φk = (k + 2.5)·30°: `CFrame.Angles(0,0,-φk) * CFrame.new(0, 2.355, zk)`,
with zk = +0.25 (even k) and +0.29 (odd k). The alternation avoids z-fighting at the crossings.

**C6 Sub-dial**: Dark, DEEP. Cylinder Size (0.30, 6.5, 6.5), disc orientation, at K (0, 0, +0.57). SurfaceGui on **Face = Left** (the
cylinder's −X, which faces the viewer after the 90° turn), CanvasSize 512² / 256², Brightness 1.4 → 2.2, Image T("subdial").

**C12 Movement plate** (review round 1, high and low): Dark, BASE. Cylinder Size (0.10, 24.6, 24.6), disc orientation, in the
centre wheel GE's frame at local z −0.45 (= K z −1.40: between GE's back face −1.30 and the big gears ≤ −1.60; its edge hides
inside the bezel, inner R 12.2). It closes the skeleton dial from behind: the world no longer shows through the clock, and only
the big gears' teeth show past the rim. It turns with GE (+6°/s, spin-up on equip) and slides in with it (from K z −4.40,
3.0–3.6 s, fade 3.0–3.3). SurfaceGui on its Face Left: the **star window**, T("starWindow") (te5_star_window: a dark star field
with a faint Milky-Way band; fallback: the pass-4 galaxy, galaxy4), CanvasSize 1024² / 512², Brightness 1.1 → 2.0 (0.7 → 1.1 on the fallback,
which is brighter), fade 3.0–3.4.

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

- Stem: Cylinder (1.4, 1.1, 1.1), vertical axis, centre (0, 14.6). (The bow is in group Core since review round 1: the clock's far silhouette.)
- Crown: Cylinder (1.5, 2.6, 2.6), vertical axis, centre (0, 16.0).
- Cap: Ball Ø 1.2 at (0, 16.85).
- **Bow** (high only): a loop of **10** Cylinders, Size (1.662, 0.55, 0.55), round a centre at (0, 19.6), loop radius 2.4, in the
  clock plane. Segment j: `βj = (j + 0.5)·36°`, position = centre + 2.283·(cos βj, sin βj, 0),
  `CFrame.Angles(0, 0, βj + rad(90))` (cylinder axis tangent). Top of the bow ≈ K y 22.27.

Low quality builds the stem and crown only.

**C10 Corona plane** (high only, night only): Fx, invisible, group **Core** (the clock's night glow from across the plaza), Size 44 × 44 (decision 4) at K (0, 0, −3.2). SurfaceGui Face = Back,
Image T("halo"), ImageColor3 (236,240,248), Brightness 1.8, CanvasSize 512². `Enabled = n > 0.05`;
`ImageTransparency = 1 - 0.4*n` (written on the night tick only). The ring peaks just outside the bezel (R ≈ 14.8).

**C11 Clock carriers** (Fx, invisible, static in K):

- `RimGlint`: Size (28.4, 28.4, 0.2) at K (0, 0, +1.05). Host of P5a.
- (`SmokeVoid` / `SmokeMoon` were removed in review round 1: P4a and P4b now boil off the void and the moon themselves.)
- `ShardFeed` (high only): Size (2, 2, 2). Not in K: placed each frame at the bezel point at angle 310° (K (−10.72, 9.00, 0)),
  oriented `CFrame.lookAt(thatPoint, voidC)`. Host of P3.

### 8.2 The armillary (frames F1, F2, F3; body-anchored)

Flat-band ring recipe (ring in its frame's XY plane): segment i at θi = (i + 0.5)·360°/N,
`local = CFrame.Angles(0, 0, -θi) * CFrame.new(0, R, 0)`, Size `(2·(R + w/2)·tan(180°/N) + 0.02, w, t ± 0.02 alternating)`.

| Ring | Frame | R | w (radial) | t (axial) | N | Segment L | Colour | Motion |
|---|---|---|---|---|---|---|---|---|
| **A1 Meridian** | `F1 = A0 * CFrame.Angles(0, φ1, 0) * CFrame.Angles(rad(33), 0, 0)`, `φ1 = rad(8)·s.t` | 6.0 | **0.26** | **0.15** | **28 / 18** | 1.371 / 2.181 | SILVER | Precesses 8°/s with a fixed 24° lean; lowest point A0 −5.76 = O −4.46 |
| **A2 Equator** (bracelet band) | `F2 = F1 * CFrame.Angles(rad(57) + rad(18)*sin(2π*s.t/19), 0, 0)` | 5.3 | 0.20 | **0.32** | **22 / 14** | 1.566 / 2.486 | SATIN (Silver) | Near-horizontal, rocks ±18° about the meridian's pin axis |
| A2 ticks (high) | in F2 | — | — | — | 12 | — | LUME | Block (0.14, 0.10, **0.28**) at `CFrame.Angles(0,0,-k·30°) * CFrame.new(0, 5.45, 0)`: lume hours on the band's outer face |
| **A3 Ecliptic** (high only) | `F3 = F2 * CFrame.Angles(0, rad(23.4) + rad(14)*sin(2π*s.t/27 + 1.1), 0)` | 4.6 | **0.28** | **0.14** | **24** | 1.268 | SILVER | Rocks about the equator's pin axis around the 23.4° obliquity |
| **A4 Pins** (high only) | — | — | — | — | 4 | — | BRIGHT | Cylinders (0.62 \| 0.52, 0.26, 0.26): two at `F1 * CFrame.new(±5.6, 0, 0)` (axis X) joining equator to meridian; two at `F2 * CFrame.new(0, ±4.97, 0) * CFrame.Angles(0,0,rad(90))` joining ecliptic to equator |

Review round 3 (AD3-02, R3W-8): fine silver wire with many short segments. At Roblox's default zoom the rings are 7-12 studs from
the lens, the biggest thing in the most-played view; the round-2 bands (0.40 × 0.24 meridian, 0.45 × 0.20 ecliptic, 16-18
segments of 20-22.5°) showed their kinks and joints there and read as plastic pipes. The parts were paid back elsewhere (the
lensed arc's 9 blocks, the ribbon's end carrier, 2 bow segments, 4 dais-rim blocks, 6 chapter-ring blocks), so high quality
stays at 360. On low the meridian gets 18 segments (the biggest silver shape on a phone's screen read as a 14-gon) and the
equator keeps 14, paid for by the heart's spikes (low builds no spikes now).

Max reach of any band from A0 is 6.28. Tilt limits keep every band ≥ 0.6 from the body sample points (head, hands, feet) in the idle
and glide poses. The harness checks this (§18.2).

### 8.3 The orbs: balance, moon, void

**Balance.** The orbs hang at ±12.5 (±14.5 when the camera is close, 16.5 studs behind the wearer: §4) on the viewer's left/right of pivot Pv (§4) and rock ±10° over a 10 s period. One rises as the other
falls, like scales. `swayAmp` ramps 0 → 1 during assembly (1.8–3.0 s). Height range of the orb centres: +3.83 … +8.17.

**M1 Moon core** (review round 2): Dark, MOONCORE (184, 186, 192), Ball Ø 6. `CF = CFrame.lookAt(moonC, O + Vector3.new(0, 1, 0))`
(tidally locked to the wearer). It carries the dust (P2), the smoke (P4b) and the key light, and casts the shadow (high). With the
film-mesh moon (`FILM_MOON`) the mesh replaces core and face (Silver, MOON (234, 236, 240), Ø 9).

- Attachment `KeyLight`: at (0, 4.5, −5.5). It holds PointLight L1 (§11). It lights the moon's wearer-facing top and rim-lights the
  wearer at night.
- BillboardGui `Halo`: Size UDim2.new(15, 0, 15, 0) × `hs` (the face is 4.4 studs nearer the camera, so it looks bigger than the core; `hs` = 1 with te5_halo, `0.73 / RIM_R` while the pass-2 `rim` texture stands in: review round 3, CR3-02),
  StudsOffset (0, 0, −2.0) (decision 3), LightInfluence 0, Brightness 1.0 → 1.6, MaxDistance 400, AlwaysOnTop false. ImageLabel:
  Image T("halo"), ImageColor3 (240,240,244), ImageTransparency 0.65 → 0.45 (rim-only). It fades out as the camera comes close
  (cz 0.3 → 0.7, event writes while zooming), where the close-camera clock's leaning dial plane would cut it.

**M3 Moon face** (review round 2, always): an **opaque** disc, Dark, MOONCORE, Cylinder Size (0.1, 9, 9) with rest `DISC`, in its own
group 44 placed every frame at `fpos = moonC + unit(camPos − moonC)·4.4` and turned to face the camera:
`CFrame.lookAt(fpos, fpos − fdir)` (+z toward the camera, as the clock frame, so the cylinder's Left face looks at it). SurfaceGui
on the Left face, canvas 1024² / 512², LightInfluence 0, Image T("moon") with a `UICorner` (CornerRadius 0.5: a round image; a
SurfaceGui on a cylinder's end is drawn on the square face). te5_moon (a photographic full moon) is drawn whole at Brightness
1.25 → 2.6; the fallback te4_moon is a moon disc inside a glow ring, so it is cropped to the disc (`ImageRectOffset` (104, 104),
`ImageRectSize` (304, 304), set by `applyTex` from the `CROP` table whenever the fallback is used) and drawn at **0.75 → 1.25**
(review round 3, AD3-06: a paler, softer image; at 1.0 → 1.7 its maria washed out on the tone curve's shoulder into a white plate). Why a part and not a billboard (round 1's face): a transparent BillboardGui writes
no depth, so the Silver Highlight composited afterwards painted the bezel behind it over the moon's right third (AD2-01); an opaque
part writes depth, so neither the Highlight nor the moon's own smoke born behind it can veil it. The 9-stud face covers the Ø 6 core
from any angle.
- Attachment `StreamOut` (on the face): part-local (0.1, −1.77, 3.81) = just behind the face's rim at about 4 o'clock (the wearer's
  side, as the viewer sees it), X axis rising 20° toward the wearer: the silver stream leaves from behind the rim and never crosses
  the face. (Film-mesh moon: on the mesh at (0, 0, −4.55), X axis up, as before.)
- The round-1 craters (M2) and the 9-stud ball are gone.

**V1 Void core**: Dark, VOID (Neon black), Ball Ø 8. `CF = CFrame.lookAt(voidC, O + Vector3.new(0, 1, 0))`.

- `StreamOut` attachment: `CFrame.new(0, 0, -4.05) * CFrame.Angles(0, 0, rad(90))`.
- (The `RibbonOut` attachment went with the ribbon in review round 3.)

**V2 Accretion plane**: Fx, invisible, Size (13, 0.05, 13), CF = `Dk * CFrame.Angles(0, rad(40)*s.now*dir, 0)` (`dir` = attribute
`ACC_DIR`). SurfaceGui on the **Top** face only (review round 2: the disc always tilts toward the viewer, so its underside is never
seen; the Bottom GUI went to the moon's face), CanvasSize 1024² / 512², LightInfluence 0, Brightness 1.6 → 2.4, Image T("accretion"),
ImageTransparency 0. `dir` (±1) is chosen so the texture's streaks trail the spin; verify in the preview. The opaque core hides the
far half behind it, and the near half crosses in front of the core's lower half: correct occlusion, because the core writes depth.

**V3 VoidSwirl host**: Fx, invisible, Size (13, 0.3, 13), CF = `Dk * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, rad(85)*s.now*dir, 0)`
(review round 3, R3S-5: 0.3 above the disc plane toward the viewer, so its particles sort over the disc and the void whether Roblox
keys an emitter at its part or at its particles). Host of P1.

**V4 Photon ring**: Lume, LUME, **24 / 12** Blocks in Pf (review round 2: 18 still kinked at the default zoom, and low's 8 read as a
white octagon). Segment i at θi = (i + 0.5)·360°/N: `CFrame.Angles(0,0,-θi) * CFrame.new(0, rt + 0.115 + y/2, 0)`, Size (1.14 | 2.25,
**y**, 0.12): a hairline that hugs the black silhouette exactly, from any distance, and blooms softly at night without alpha.
**Hairline bands** (review round 3, R3S-6): `y` = 0.13 / 0.22 / 0.36 with the camera-to-void distance under 50 / 50-95 / beyond 95
studs (5 studs of hysteresis each way; low quality starts at the middle band), and the seconds needle's width 0.12 / 0.2 / 0.3 by
the camera-to-clock distance: without anti-aliasing (phones, low graphics levels) a line under a pixel wide crawls in stair-steps.
24 Size writes per band change, event only.

**V4b Event-horizon glow** (high, review round 2): an invisible 0.2-stud carrier `Horizon` in Pf (camera-facing, on the silhouette
plane) emits one te5_halo particle a second (Size 11.2 × `hs`, Lifetime 3, LockedToPart, Transparency [0,1] [0.2,0.12] [0.8,0.12] [1,1],
random rotation, RotSpeed ±8, ZOffset 0.4, LightEmission 0.4 → 1, Brightness 1.6 → 3.0): three soft rings alive at once overlap into
a steady glow whose peak (r 0.72 of the image) lands on the black edge. No pulse; never a billboard (the accretion plane would cut it).

**V5 Lensed disc** (high only; review round 3, AD3-03): two beams on attachments of the `Horizon` carrier (camera-facing, so they
hug the silhouette from every side). `LensTop`: A0 at (−4.45, 0, 0) with its X axis up, A1 at (+4.45, 0, 0) with its X axis down,
CurveSize 6 / 6 (a Bezier arch peaking 4.5 above the centre), T("stream") Wrap 6 at +0.4 × `FLOW_SIGN`, Width **1.5**, WHITE,
LightEmission 0.2 → 0.8, Brightness 2.0 → 3.0, Transparency [0, 1] [0.15, 0.05] [0.85, 0.05] [1, 1]. `LensBottom`: mirrored under
the shadow, Width **0.8**, Brightness 1.8 → 2.8. Both widths × `(1 − 0.45·czq)` on the zoom steps (event writes): at the default
zoom a full-width band read as a broad crescent. They fade in with the heart (0.9 s). This is Gargantua's read: the far side of the
accretion disc lensed into a bright band over and under the shadow. The round-2 lensed arc (9 blocks of 0.16, a hairline that did
not register) and the ink ribbon (a black stick from the ball to the dais from the studio and back cameras) are gone.

**V6 Heart**: Lume, LUME. A small brilliant 4-point star in Hf (a pinpoint of light inside the lensed band, not a sticker).

- Centre Ball Ø 0.70 at Hf origin.
- **Spikes** (up/down h = 1.3; right/left h = 0.9; review round 3, were 1.6 / 1.1, and 2.8 / 2.2 before review round 2), each from 2 Wedges, Size (0.08, h, 0.32) (attribute `WEDGE_SWAP` swaps the halves' ±90°). Spike k with direction αk (0 up, 90
  right, 180 down, 270 left, as the viewer sees it), `S = Hf * CFrame.Angles(0, 0, -αk)`:
  - half A: `S * CFrame.new(-0.16, h/2, 0) * CFrame.Angles(0, rad(90), 0)`
  - half B: `S * CFrame.new(0.16, h/2, 0) * CFrame.Angles(0, rad(-90), 0)`

  (Roblox wedge: the triangle lies in local YZ with the right angle at (−Y, +Z). The +Z back edge becomes the spike's centre line, the
  base sits at the star centre and the apex at h.) Verify the wedge convention in the mock and renderer (§19).
- Low quality: the centre ball only (review round 3, AD3-08: the up and down spike pair alone read as a cat's eye, a slit pupil).

**V7 Crackle veins**: removed in review round 2 (eight straight white lines read as "spider" veins on a sticker).

### 8.4 Beams: streams and the lensed disc

Beams live in `Fx`. All have FaceCamera true, LightInfluence 0, Segments 20, ZOffset 0. Writes happen only during assembly and on
night ticks.

| Beam | A0 → A1 | Texture (TextureMode, Length, Speed) | Width0 → Width1 | Curve0 / Curve1 | Color | LightEmission day → night | Brightness | Transparency (rest) |
|---|---|---|---|---|---|---|---|---|
| **B1 MoonCore** | moon face `StreamOut` → moon palm | T("stream") Wrap 5, +0.8 | 1.4 → 0.30 | 4.0 / 0 | WHITE | 0 → 0.45 | 1.6 → 2.4 | [0, 0.15] [0.12, 0.05] [0.88, 0.05] [1, 0.30] |
| B2 MoonFlow (high) | same | TEX.streak Wrap 7, +1.6 | 0.5 → 0.15 | 4.3 / 0 | WHITE | 0.3 → 0.9 | 2.0 → 2.6 | [0, 0.4] [0.15, 0.2] [0.85, 0.2] [1, 0.6] |
| **B3 VoidCore** | void `StreamOut` → void palm | T("stream") Wrap 5, +0.7 | 1.6 → 0.35 | 3.0 / 0 | (18, 18, 24) | 0 | 1.0 | same as B1 |
| B4 VoidCrackle (high) | same | T("line") Stretch 1, 0 | 0.14 → 0.10 | 2.6 / 0 | WHITE | 0.2 → 0.8 | 1.8 → 2.4 | [0, 0.3] [0.1, 0.1] [0.9, 0.1] [1, 0.5] |
| B5 LensTop (high) | `Horizon` LensTop0 → LensTop1 | T("stream") Wrap 6, +0.4 | 1.5 (× (1 − 0.45·czq)) | 6.0 / 6.0 | WHITE | 0.2 → 0.8 | 2.0 → 3.0 | [0, 1] [0.15, 0.05] [0.85, 0.05] [1, 1] |
| B6 LensBottom (high) | `Horizon` LensBottom0 → LensBottom1 | T("stream") Wrap 6, +0.4 | 0.8 (× (1 − 0.45·czq)) | 6.0 / 6.0 | WHITE | 0.2 → 0.8 | 1.8 → 2.8 | same |

Review round 3 (AD3-03): the ink ribbon (B5/B6 until then) read as a stick from the ball to the dais from the studio and back
cameras (a lollipop); its two beams became the lensed disc (§8.3 V5), and te5_ribbon was dropped from the upload list. The four
palm streams switch off in first person (their ends sit just under the lens). Each beam fades in on equip from its own time (the
lens with the heart at 0.9 s, the streams at 4.6 s).

**Flow direction:** the stream textures must visibly flow from the orb **into** the palm. All four are built source →
destination, so one sign serves them all: every TextureSpeed is multiplied by the attribute `FLOW_SIGN` (1); if they run backwards
in Studio, set it to −1 (no reinstall). The lensed bands share the sign (they drift slowly over the shadow; either way reads).
Fade steps: 21 precomputed Transparency sequences per beam (≤ 5 % per step).

**B7 Spire** (attribute `FAR_BEACON`, default **off**, needs Milo's OK: MILO_PROMPT asks him with two screenshots): a FaceCamera beam from 38 studs above the balance wheel's level hub (above
the bow, so it never crosses the dial) to 280 studs, Width 8 → 3, **no texture** (a solid band reads at 300 studs; round 1's textured
line thinned to a 1-px hairline), Transparency [0, 0.1] [0.6, 0.15] [1, 1], Color INK by day → WHITE at night (LightEmission 0 → 1,
Brightness 1 → 2, on the night tick). It fades in past ~110 studs (`setDetail(false)`, through the far-detail fade), so the owner
never sees it: players across the map spot the aura. Steady, no pulse. Beams 7 when on.

### 8.5 Time shards (high only; they ride the ecliptic)

8 small Wedge parts slide along the **inside of the ecliptic ring (A3)** like beads on a wire, or planets on an orrery. Even i:
Silver, BRIGHT. Odd i: Lume, LUME. Size (0.14, 0.7 + 0.15·(i % 3), 0.40).

Shard i: `F3 * CFrame.Angles(0, 0, -(rad(i*45 + 22.5) + rad(22)*s.t)) * CFrame.new(0, 4.0, 0) * CFrame.Angles(s.t*rad(50 + 15*i), s.t*rad(35 - 7*i), 0)`
(an orbit at 22°/s plus a tumble).

Half of them are always in front of the torso, and they never cross a ring: they live on the ecliptic. Clearance to the hands ≥ 0.2,
to the equator ≥ 0.3. They are built, hidden and shown together with the armillary (§13), and are absent on low quality.

### 8.6 The dais (ground)

**daisY.** Let `feetY = s.cf.Position.Y - s.legLen` and `visFeet = feetY + s.hover`.

- `grounded = s.ground ~= nil and (feetY - s.ground.Y) < (grounded and AIR_ON 12 or AIR_OFF 9)` (hysteresis: Roblox's default
  JumpHeight 7.2 lifts the HumanoidRootPart 7.2 studs, which the old fixed 7 counted as flying).
- Target = `s.ground.Y` if grounded; **seated** (`Humanoid.Sit`): `min(s.ground.Y, feetY)` (the ground ray hits the seat top; the
  feet line is nearer the floor, and in a vehicle the dais rides along). Otherwise (`CONFIG.DAIS_FLOAT`) the dais floats under
  the flyer at `visFeet - 2.4`.
- `daisY += (target - daisY) * (1 - exp(-k*dt))` with k = 30 going down (no lag walking downhill), 8 going up. At build, daisY =
  target (no slide-in from 0).
- Normal jumps do **not** move the dais and cause **no transparency writes**.
- The grounded flag only toggles P7 (mist).

| Id | Part | Size / shape | Position in Gd | Material / model | Motion | high / low |
|---|---|---|---|---|---|---|
| D1 Base | Cylinder (0.12, 29.6, 29.6), vertical axis | | (0, 0.06, 0) | BASE, Dark | static | 1 / 1 |
| D2 G0 floor plane | Fx part (29.6, 0.05, 29.6) | SurfaceGui **Top**, T("galaxyFloor"), 1024²/512², Brightness 1.3 → 2.4, fades in 4.0–4.6 with the base | (0, 0.15, 0) | invisible | `CFrame.Angles(0, rad(-6)*s.now*GALAXY_DIR, 0)` (clockwise from above; arms must trail) | 1 / 1 |
| D3 G1 arms plane | (21, 0.05, 21) | Top, T("galaxyArms"), 1024², 1.4 → 2.4 | (0, 0.42, 0) | invisible | `rad(+9)*s.now` | 1 / — |
| D4 G2 core plane | (12, 0.05, 12) | Top, T("galaxyCore"), 512²/256², 1.5 → 2.6, fades in 4.0–4.6 | (0, 0.66, 0) | invisible | `rad(-16)*s.now*GALAXY_DIR` | 1 / 1 |
| D5 Engraving plane (**the stage**) | **(56, 0.05, 56)**, group **Core** (review round 3, AD3-04: was 40 in Detail) | Top, T("engraving"), 1024², **1.0** → 2.0 | (0, 0.04, 0) | invisible | `rad(+2.5)*s.now` | 1 / — |
| D5b FloorFx (review round 3, R3S-5) | (29.6, 0.05, 29.6) Disc host for P7, P8a and P8b | — | **(0, 0.95, 0)** (group G0: L (0, 0.8, 0)) | invisible | turns with D2 | 1 / 1 |
| D6 Rim | **24 / 16** Blocks, Size (4.11 \| 6.21, h, 0.80); h = 0.90 even / 0.96 odd (fluted top) | radial 14.75 → 15.55 | `CFrame.Angles(0, θi, 0) * CFrame.new(0, h/2, -15.15)` | SILVER even / SATIN odd, Silver | static | 24 / 16 |
| D7 Balance wheel | in **Bw**: rim 12 / 8 Blocks (1.338 \| 2.058, 0.30, 0.32) at `CFrame.Angles(0, θi, 0) * CFrame.new(0, 0, -2.30)` · 2 spoke Blocks (4.3, 0.16, 0.22) at yaw 0° and 90° (high) · hub Cylinder (0.5, 0.7, 0.7) vertical axis | | | SILVER rim/spokes, BRIGHT hub, Silver | `wheelAngle = rad(160)·sin(2π·s.t/3.2)·wheelAmp` (smooth swing, the watch's heartbeat; wheelAmp ramps in assembly) | 15 / 9 |
| D9 Funnel host | (11, 0.4, 11) | | (0, 0.8, 0) · `rad(-70)*s.t*FUNNEL_DIR` (decision 9) | invisible | spins | 1 / — |

D1 sits on the ground, so it can z-fight with flat ground on its bottom face only, which is unseen. (D8, the hairspring plane, was
removed in review round 2: invisible at every framing. D10, the ribbon's end carrier, went with the ribbon in review round 3.)

**The stage** (review round 3, AD3-04): at Milo's studio camera pass 5 covered less of the screen than the pass 4 that is live
(12.5 % of the frame against 16.6 %), because pass 4's 58-stud ground ring was cut and the 40-stud engraving barely cleared the
31-stud rim. The engraving is now a 56-stud stage in Core (it is the aura's footprint from far away too): te5_engraving runs from
just outside the rim to the edge, with Roman numerals 3 studs tall and an inked minute track (a solid dark band with white ticks)
that reads on bright sand by day. Measured: the aura covers 18.8 % of the studio frame (bounding box 827 × 467 px; pass 4 16.6 %,
781 × 392).

**On a slope** (review round 3, R3S-2): the dais used to stay level, an opaque base with a raised rim half buried in a hillside.
Now, every 0.2 s while standing on the ground (not seated), three rays (`workspace:Raycast`, excluding every aura and the
wearer, `RespectCanCollide`) go down 9 studs from 4 above the dais at radius 9 round the wearer (yaw 0°, 120°, 240°). Their
plane is accepted only if all three hit, it passes within 0.6 studs of the framework's ground point under the wearer, and it
tilts at most 20°; otherwise the target is level (stairs, cliff edges, another player's body). The normal `gn` eases toward
the target (rate 4) and Gd tilts to it (below 0.5° it stays level). The clearances follow: the ring lift adds `6.3·tan`, the
wheel clamp `2.5·tan`, and on ground rising behind the wearer the clock stands up to 4 studs higher (more would lift it out of
the view). The `slope` scenario (a 10° plaza) checks the base's tilt and that no rim block sinks into the ground.

**Layer lift** (review round 2): two wearers' pools side by side would put their layers in exactly the same planes, and Roblox
z-fights coplanar faces as a crawling shimmer. Every layer of the dais (Gd) is lifted by `st.layer`: **0.0366 for the owner, 0 or
0.0183 for other players** (by UserId parity; review round 3, R3S-4: your own pool on top, so where two pools overlap yours is the
one you see, if Roblox lets the nearer SurfaceGui win). The layer surfaces (engraving 0.065, base 0.12, floor 0.175) repeat every 0.055 studs,
so lifts a third of that apart keep every pair of surfaces ≥ 0.018 apart. Two other players with the same parity still share
planes (STUDIO-VERIFY). The clearance clamps use the lifted height.

**The clock's height ride** (review round 2): the clock (K) and the balance (Pv) ride `st.kY`, a critically damped spring on O.Y
(k 4 while grounded, 12 flying or seated; snaps after a long hide), so a 7.2-stud jump no longer throws the 28-stud watch and both
orbs up and down with the body. Measured in `jump`: at the apex the clock stays put (its height clamp over the dais holds it) and
the moon rises 0.6 (was +6.5); the armillary stays on the body.

### 8.7 Body carriers (Fx, invisible)

- `AirVolume` **(44, 22, 44)** (review round 3: the sparkle field fills the space round the whole aura) at `CFrame.new(O + Vector3.new(0, 4, 0))`, turned to face the way the wearer travels
  (`CFrame.lookAt(O, O + travelDir) * CFrame.new(0, 4, 0)` once there is a travel direction). Hosts P6a and P6b, and an
  Attachment `Trail` at local (0, −4, 0) (= O) hosting P12.
- `BokehHost` (high only) (18, 10, 5) at `V * CFrame.new(0, 3.0, min(7.5, camDist - 4))`. Hosts P6c (shown only when the camera is
  more than 20 studs away: §13.3).
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
| **P1 VoidSwirl** | matter spirals inward along the disc and vanishes into the black core | V3 · Cylinder (Surface, **Inward**) · Top (`SWIRL_POINTS`: one rim Attachment at (6.3, 0, 0) aimed at the axis, EmissionDirection Front, Spread (0, 10)) | T("mote") | 28 / 12 | 1.1–1.3 | 2.2–2.6 · 0 | 0 · 0 | [0, 1.5] [1, .35] | [0, 1] [.15, .05] [.8, .05] [1, .4] | WHITE → (170,174,184) | .3→.9 · 2.4→3.0 | **true** (the spin turns inward motion into a spiral) · .3 · 0 / 0 · FacingCamera |
| **P2 MoonDust** | dust snows off the moon and falls away below it | M1 ball · Sphere (Surface, Outward) | T("mote") | **10 / 5** (halved while travelling; review round 3) | 3.0–4.5 | .25–.6 · 0 | (0, −1.1, 0) · .4 | [0, .18] [.2, .6, .15] [1, .18] | [0, 1] [.12, .08] [.75, .15] [1, 1] | (238,240,246) | .2→.7 · 1.4→2.2 | false · 0 · 0–360 / ±30 · FacingCamera |
| **P3 ShardFeed** | metal shards break off the bezel at 10–11 o'clock and fly across the face into the void | ShardFeed · Box (Volume) · Front (toward the void) | T("shards5") Loop 10–14 fps, StartRandom | 7 / — | 2.9–3.2 | 8.5–9.5 · (6, 6) | 0 · 0 | [0, .6] [.85, .9, .12] [1, .35] (×1.3 with te5) | [0, 1] [.06, 0] [.9, 0] [1, 1] | (214,218,226) | 0→.3 · 1→1.6 | false · 0 · 0–360 / ±120 · FacingCamera |
| **P4a SmokeVoid** | ink smoke boils off the void and curls out and up round it (a dark corona that reads on the day sky) | V1 ball · Sphere (Surface, Outward) | T("smoke5") OneShot | 10 / 4 (**1.5 / 1** while travelling) | 3.5–4.5 (**1.0–1.4** while travelling) | 1.4–2.4 · 0 | (0, .4, 0) · .35 | [0, 5] [1, 14] (review round 3: te5_smoke is a dense billow now, drawn at the fallback's size, no 1.3x) | [0, 1] **[.18, .08] [.7, .32]** [1, 1] (round 3: ink, not teal) | SMOKE | 0 · 1 | false · **−3** (the core's silhouette stays crisp) · 0–360 / ±25 · FacingCamera |
| **P4b SmokeMoon** (high) | silver smoke boils off the moon (the void's opposite energy) | M1 ball · Sphere (Surface, Outward) | T("smoke5") | 5 / — (**0** while travelling) | 3.5–4.5 | .9–1.5 · 0 | (0, .3, 0) · .35 | [0, 3.5] [1, 9] | [0, 1] [.2, .32] [.7, .55] [1, 1] | (176,176,178) (grey-silver: shades against the sky instead of vanishing) | .1→.4 · 1 | false · −3 · 0–360 / ±20 |
| ~~P5a RimGlints~~ | removed in review round 3 (CR3-04): its glints sat on the bezel, inside the silver Highlight, which composites over them; its 9/s went to P13 and the air's sparkles | | | | | | | | | | | |
| **P13 TimeDust** (high, review round 2; replaces P5b, the meridian glints at 0.4/s) | the hero system: glints born just round the bezel's rim ride a ring that turns clockwise with the hands, so the clock wears a slow halo of moving light (round the rim, not on it: under the silver tone a white glint on the bezel hardly reads by day; against the sky and the dark gears it does) | TimeDust carrier (31.6, 31.6, 0.2), group 45 = `K * CFrame.new(0, 0, 1.3) * CFrame.Angles(0, 0, -(rad(20)·now % 2π))` · **Disc** (Volume, Partial **0.9**: R 14.2–15.8) · Back | T("glint5") | **20** / — | 4–5 | 0 | 0 | [0, 0] [.3, 1.7, .35] [.7, 1.7, .35] [1, 0] | [0, .1] [1, .1] | WHITE | .5→1 · 2.4→3.0 | **true** · 1.0 · 0–90 / ±15 |
| **P6a AirSparkles** (review round 3: was AirDust, 0.22–0.40 motes that never read) | a field of slow four-point sparkles round the whole aura (scale 1; pass 4's sparkles are what reads in the real captures) | AirVolume (44, 22, 44) · Box (Volume) | T("glint5") | **14 / 4** | **3–4.5** | .1–.3 · (180, 180) | 0 · 0 | [0, 0] [.3, 1.1, .3] [.7, 1.1, .3] [1, 0] | [0, .1] [1, .1] | WHITE | .3→.9 · 2.4→3.0 | false · 0 · 0–90 / ±15; **off in first person** |
| P6b AirGlints (high and low) | small glints (scale 2) | AirVolume · Box | T("glint5") | 5 / 1.5 | 4–6 | .2–.5 · (180, 180) | 0 · 0 | [0, 0] [.3, .7, .2] [.7, .7, .2] [1, 0] | [0, 1] [.3, .1] [.7, .1] [1, 1] | WHITE | .4→1 · 2.4→3.0 | false · 0 · 0–90 / ±20; off in first person |
| P6c Bokeh (high) | big slow out-of-focus discs between the camera and the wearer (scale 3, L7) | BokehHost · Box (Volume) | T("bokeh") | **0.5 → 1.2** (night) / — | 5–7 | .1–.25 · (180, 180) | 0 · 0 | NumberRange 1.2–2.4 | [0, 1] [.25, .6] [.75, .6] [1, 1] | (232,236,246) | .3→.8 · 1.2→1.8 | false · 0 · 0–360 / ±4 |
| P7 RimMist (high) | a low mist bank round the pool's rim, only when grounded | **FloorFx** (review round 3) · Disc (Volume, **Partial 0.8**: the outer fifth, so the galaxy inside stays clear) · Top | T("smoke5") | 2.5 / — | 6–8 | .1–.25 · 0 | 0 · 0 | [0, 8] [1, 14] | [0, 1] [.3, .80] [.7, .82] [1, 1] | MIST | 0 · 1 | true · 0 · 0–360 / ±6 |
| **P8a GalaxyTwinkles** (review round 3, AD3-07: were white pearls with a grey rim on the black pool) | starlight rises off the turning arms in slow four-point twinkles and swirls with them | **FloorFx** · Disc (Volume, Partial .15) · Top | T("**glint5**") | 18 / 8 | 2.6–3.6 | .5–1.2 · 0 | (0, .35, 0) · .2 | [0, 0] [.25, pk, .3·pk/1.3] [.75, pk, …] [1, 0], **pk = 1.3 / 1.14 / 0.98 / 0.81 / 0.65** stepping down as the camera comes close (R3S-8 / CR3-03: each step under 20 %, changed only a 0.05 band past cz 0.30 / 0.45 / 0.60 / 0.75, so a resting camera never flips it; the round-2 single swap jumped every live mote 2x) | [0, .1] [1, .1] | WHITE | .3→.9 · 2.4→3.0 | **true** · .2 · 0–90 / ±20 |
| P8b GalaxyAsh (high) | black ash flakes rise against them | **FloorFx** · Disc (Volume, Partial .15) · Top | T("ash5") (one 256² flake, no flipbook) | 8 / — (**3 in first person**) | 3–4.5 | .8–2.0 · 0 | (0, .3, 0) · .4 | NumberRange .40–.60 | [0, 1] [.15, .05] [.75, .2] [1, 1] | ASH | 0 · 1 | false · 0 · 0–360 / ±90 |
| P9 Funnel (high) | a vortex funnel: streaks spiral inward and climb into the balance wheel | D9 host · **Cylinder** (Surface, **Inward**) · Top (`SWIRL_POINTS`: one rim Attachment at (5.3, 0, 0)) | T("streak5") | 16 / — | 1.7–2.0 | 2.8–3.2 · 0 | (0, 1.0, 0) · 0 | [0, .42] [1, .1] (×2.2 with te5_streak) | [0, 1] [.12, .05] [.85, .1] [1, 1] | WHITE | .3→.9 · 2.4→3.0 | **true** · 0 · 0 (180 with `STREAK_FLIP`) / 0 · **VelocityParallel**; off in first person (review round 3: the camera sits right inside it) |
| **P10a PalmMoon** | silver streaks converge into the moon palm (the palm drinks the stream) | PalmMoon · Sphere (Surface, **Inward**) | T("streak5") | 14 / 6 | .85–.95 | 1.35–1.45 · 0 | 0 · 0 | [0, .3] [1, .05] (×2.2 with te5_streak) | [0, 1] [.25, .05] [1, .2] | WHITE | .3→.9 · 2.4→3.0 | **true** (still converging on a moving palm) · .2 · 0 (180 with `STREAK_FLIP`) / 0 · VelocityParallel; off in first person (review round 3: the palms sit just under the lens) |
| **P10b PalmVoid** | ink motes converge into the void palm | PalmVoid · same | T("streak5") | 14 / 6 | same | same | 0 · 0 | same | same | INK | 0 · 1 | same |
| **P11a/b BodyWrap** (review round 3, AD3-01: replaces the sole drips, 0.18-stud specks invisible at every framing) | the wearer burns with the aura: **a** silver wisps rise off the shoulders and back (Rate 0 while travelling: no smog trail); **b** sparks stream up the body (they keep going while travelling: a comet's tail). Silver, not ink: from every camera the wearer stands against the black dial | the character's UpperTorso / Torso (in `charStuff`: destroy() removes them) · **a** Box (Surface) Top, Spread (20, 20) · **b** Box (Volume) Top, Spread (25, 25) | **a** T("smoke5") · **b** T("glint5") | **a 7 / 3 · b 14 / 6** | **a** 1.6–2.2 · **b** 1.4–2.0 | **a** 1.5–2.5 · **b** 1.5–3.0 | **a** (0, 1, 0) · **b** (0, 1.5, 0) | **a** [0, 1.2] [1, 3.4] · **b** [0, 0] [.25, 1.3, .3] [.75, 1.3, .3] [1, 0] | **a** [0, 1] [.2, .32] [.6, .55] [1, 1] · **b** [0, .1] [1, .1] | **a** (200, 202, 208) · **b** WHITE | **a** .2→.6 · 1.2→2.0 · **b** .5→1 · 2.4→3.0 | false · **a** −1.5 · **b** 0.5; off while hidden (back 1.1 s after showing) and in first person |
| **P12 SpeedTrail** | while the wearer travels fast (speed > 12 studs/s on, < 8 off; horizontal only while grounded, so a jump is not a flight) silver streaks stream out behind the body | AirVolume `Trail` attachment · EmissionDirection Back (the volume faces the travel direction) | T("streak5") | 14 / 6 (only while fast) | .45–.6 | 4–6 · (10, 10) | 0 · 0 | [0, .5] [1, .1] (×2.2 with te5_streak) | [0, .2] [.6, .3] [1, 1] | (226,230,240) | .3→.9 · 2.4→3.0 | false · 0 · 0 (180 with `STREAK_FLIP`) / 0 · VelocityParallel |

Plus **P14 Horizon** (high, review round 2): the event-horizon glow, 1/s te5_halo rings on the void's silhouette (§8.3 V4b).

Totals (review round 3): **19 emitter instances** high (P11 is two; P5 removed) and **11** on low. Total Rate ≈ **194/s** high by
day (+0.7 bokeh at night) and **56/s** on low. While travelling the smoke, moon dust and body wisps thin out and the speed trail
(+14 / +6) comes on: ≈ 182/s high, ≈ 54/s low, so the idle number is the maximum. Particles alive ≈ 518 high and 123 low (harness
census). Review round 3 (AD3-01) put the particles where the round-2 measurements said they still did not read: a dense te5 smoke
billow (the void's ink was a thin teal veil by day), the body wrap (P11), a field of four-point sparkles in the air (P6a), four-point
twinkles off the floor instead of pearls (P8a), and P5's slot spent on those. Measured the same way as round 2 (share of pixels
changed by more than 24 levels when the particles are drawn, day unless named; this round's renderer): te5 studio 3.5 → 6.4 %,
back (owner) 3.2 → 7.3 %, night back 3.5 → 6.3 %, default zoom 12.0 → 14.1 % (more than 60 levels: 4.8 → 10.4 %); fallback studio
5.5 → 6.1 %, back 6.2 → 7.7 %, night back 5.6 → 7.0 %; on the wearer's body (te5, back) 0.8 → 16.2 %. Round 2's numbers, for the
record: studio 2.4 / 0.8 % → 3.0 / 1.3 % (te5), fallback 3.6 / 1.4 % → 4.8 / 2.1 % (24 / 60 levels).

Notes:

- P1, P8a and P9 rely on `LockedToPart` with a host that **rotates**. Locked particles live in the host's frame, so straight inward
  motion becomes a spiral.
- Shape semantics to confirm in Studio (§19): Disc `ShapePartial` = inner-radius fraction; the Cylinder and Disc shapes are oriented by
  EmissionDirection; `Inward` points velocity toward the shape's axis or centre. Fallbacks if any differs: P1/P9 become Disc + Surface
  + Speed 0 + locked spin (a rotating ring of motes); P10 becomes Sphere + Outward with negative Speed.
- Day vs night: LE and Br switch on the night tick. Smoke and ash stay at LE 0 (dark shapes carry the day). White systems keep
  LE ≤ 0.5 by day and Brightness 2.4, just above the place's Bloom threshold, plus their ink-rim textures. P6c Rate changes with n. P7 toggles with
  `grounded`. P3 and P6c are high only.

**Pass 5.2 (2026-10-17): particles with jobs and timing.** (Pass 5.1 added P15-P18: see the build notes.) "burst" = never
enabled, fired once with `:Emit` at midnight (§12); "converge" = on only in the reveal's buildup.

| Id | Job | Host · shape · direction | Texture | Rate (high / low) | Life | Speed · drag | Size | Notes |
|---|---|---|---|---|---|---|---|---|
| P19 MoonFeed | moonlight drifts from the moon into the clock at IX | LinkMoon carrier (aimed at IX) · point · Front | mote | 5 (30 in the buildup) / — | 2.2–2.4 | link length / 2.3 · 0 | ≤ 0.55 (×1.2 te5) | locked; speed written when the link's length changes by a stud |
| P20 SpiralArms ×2 | motes stream in along two arms that stand still on the floor | two attachments circling the pool's edge (+36°/s) on a host turning -42°/s · Back (inward) | mote | 9 each / — | 4.2–4.6 | 2.4–2.6 · 0 | ≤ 0.6 | locked; attachment `CFrame` writes each frame while near |
| P21 HeartGlint | the void's star: a slow glow with rays round the sharp lume core | attachment on the heart | glint5 | 1 / — | 2.4 | 0 | 3.0–3.6 | locked; ZOffset 1; 2-3 overlap into a steady glow |
| P22 MoonRing | glints orbiting the moon on a tilted ring | MoonRing carrier (14 studs, tipped 68°/-14°, 25°/s) · Disc Partial .86 · Top | twinkle | 6 / — | 3-4 | 0 | 0.75 | locked |
| P23 Infall | matter spirals into the void from all round | Infall carrier (18 studs, turning 60°/s about the disc axis, 0.3 toward the viewer) · Sphere (Surface, Inward) | mote | 12 / — | 1.4–1.5 | 5.2–5.8 · 0 | 0.5 → 0.2 | locked: the turn makes each path a spiral; it vanishes into the void |
| P24 Wave + front | the floor's wave at midnight and streaks racing out with it | WaveHost (dais, 1 stud up) · **wave**: point, Top, **VelocityPerpendicular** (flat) · **front**: Cylinder (Surface, Outward) | shockwave · streak5 | burst 1 / burst 1 · burst 40 / — | 1.7 · 1.5–1.6 | .05 · 15.5–16.5 | 3 → 65 (ring 0.86 × size) · ≤ 0.7 | locked; the front keeps pace with the ring |
| P25 DialBurst | glints burst off the dial and slow into orbit round it | BurstRing (hub, axis along the dial's, turning 30°/s) · Cylinder (Surface, Outward) | glint5 | burst 44 / — | 4.5–6 | 13–19 · drag 1.7 | ≤ 1.8 | locked: they stop 8-11 studs out and orbit |
| P25b Flare | the stroke of midnight: one star flares at the hub, the only flash | attachment on LinkPorts, 2.2 in front of the hub | glint5 | burst 1 / — | 0.7 | 0 | 3 → 16 → 0 | locked; ZOffset 1.5; over the silver hub the Highlight's fill composites over it, so it is big enough for its rays to reach the dark dial |
| P26 Converge | streaks converge on the hub through the buildup | Converge carrier (30 studs, on the clock) · Sphere (Surface, Inward) | streak5 | 10 → 60 (4.9-6.6 only) / — | 1.6–1.8 | 7.5–8.2 | ≤ 0.5 (×2.2 te5) | locked; VelocityParallel |
| P27 Lift | sparks lift off the floor at midnight and hang | FloorFx · Disc Partial .2 · Top | glint5 | burst 30 / — | 3–4.5 | 5–9 · drag 1.5 | ≤ 0.9 | locked (they turn with the floor) |
| P28 MoonPulse | the moon's one pulse: a ring that grows out from behind its face | attachment at the moon's centre | shockwave | burst 1 / — | 1.0 | 0 | 9 → 26 | locked; ZOffset -1 (the face hides its start) |
| P29 MoonGlow | the moon's broad soft glow (a pale haze by day) | the same attachment | softGlow | 1 / — | 3 | 0 | 18 | locked; ZOffset -2.5; LE 0 → .6 |
| P30 VoidTendrils | thin ink tendrils curling between the void's billows | the void ball · Sphere (Surface, Outward) | wisp | 5 / — | 2.6–3.4 | 1.6–2.6 · .25 | 2.4 → 5.4 | colour (28,28,32); ZOffset -2.5 |
| P31 Signature ×3 | a big slow twinkle at XII and a small one at each link's port | attachments on LinkPorts (GK) | twinkle | 0.4 · 0.6 · 0.6 / — | 2-3 | 0 | 3.2–3.8 · 1.6–2.2 | locked |

Rates changed in pass 5.2: P4a 10 → 8 (gaps between the billows), P6a 18 → 14 and P13 20 → 16 at rest (both lifted in
the aftermath, to 30), P4a's speed drawn in during the buildup.

---------------------------------------------------------------------------------------------------------------------------------

## 10. Character integration

- **Pose:** `End.pose` is copied **verbatim from pass 4** (hover 2.4, bob 0.28, bobSpeed 1.4, idle, glide, breathe and suppress
  tables). Reason: it already floats the wearer with arms out, which presents both palms to the streams. Glide leans forward
  (Root −18°); the armillary and shard orbit (A0) stay upright (review round 2: leaning them by the same angle hid the head from
  the follow camera), and the clock tilts 14° further back in a glide. Changing the framework's motor list is out of scope.
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
- **The body wrap** (review round 3, AD3-01; replaces the sole attachments and their drips, which were invisible at every
  framing): two emitters on the character's `UpperTorso` (R15) or `Torso` (R6), P11a silver wisps off the shoulders and back
  and P11b sparks streaming up the body (§9). Body-region particle share in the te5 back view: 0.8 % → 16 % of pixels.
  - At night the wheel's PointLight L2 (§11) lights the feet from below. This is the "foot glow", with no billboard.
- **Body clearance:** nothing solid passes within 0.6 of the head, torso, hands or feet (§18.2). The armillary and the shards on it
  cross in front of the body without touching it (shards keep ≥ 0.2 from the hands).
- **Cleanup:** every attachment and emitter created on the character is listed and destroyed in `fx.destroy()`.
  `fx.setVisible(false)` disables the body-wrap emitters, because they live outside our model (they come back 1.1 s after it is
  shown again), and they are off in first person.
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
| Highlight FillTransparency / OutlineTransparency | 0.65 / 0.35 (`HIGHLIGHT_FILL` / `HIGHLIGHT_OUTLINE`; the outline eases to ~0.74 at the default zoom, §7.2) | 0.80 / 0.70 | 1 + 1 (written separately) |
| Inlay GUI Brightness | 1.6 | 2.6 | 1 |
| Sub-dial Brightness | 1.4 | 2.2 | 1 |
| Accretion GUIs Brightness | 1.6 | 2.4 | 2 |
| Galaxy G0 / G1 / G2 Brightness | 1.3 / 1.4 / 1.5 | 2.4 / 2.4 / 2.6 | 3 |
| Engraving Brightness | 1.2 | 2.0 | 1 |
| Moon halo Brightness / ImageTransparency | 1.0 / 0.65 | 1.6 / 0.45 | 1 (opacity × `haloZ`, which fades the halo out as the camera closes in, §5) |
| Moon face SurfaceGui Brightness (te5_moon / the cropped te4 fallback) | 1.25 / 1.0 | 2.6 / 1.7 | 1 |
| Star-window backplate Brightness | 1.1 (fallback galaxy4: 0.7) | 2.0 (fallback 1.1) | 1 |
| Corona `Enabled` / ImageTransparency | false (n ≤ 0.05) / — | true / 0.60 (and off while ghosted, §13.3) | 1 |
| PointLight L1 (moon key, **high only**) Brightness, Range 26, Color (230,232,240), Shadows false | 0 | 1.5 | 1 |
| PointLight L2 (wheel underlight, high only) Brightness, Range 12, Color (230,234,246), on the wheel hub | 0 | 0.9 | 1 |
| White emitters LE / Br | per §9 | per §9 | ~12 |
| Beams LE / Br | per §8.4 | per §8.4 | 6 |
| P6c Rate | 0.5 | 1.2 | 1 |
| Far beacon Beam Color (only with `FAR_BEACON`) | ink | white | 1 |

All values interpolate linearly with nq. **Lights never pop:** a light's `Enabled` flips only while its Brightness is 0 (night
factor 0, hidden, or far); its brightness itself is `night × fade`, where the fade follows the assembly (key 0.6–1.6 s, wheel
4.6–5.6 s) and the framework alpha, written on changes ≥ 0.03. Lights are off when far (`setDetail(false)`) or hidden.

- **Day reads by value structure:** the dark dial ring, black void, black disc lanes, dark dais pool and dark smoke sit against the
  white moon, white Neon lume, white inlays and silver metal with an ink Highlight contour. Nothing depends on additive white by day.
- **Night:** the inlays, galaxy and accretion bloom softly through Brightness above the Bloom threshold. Neon lume and the photon ring
  glow. The moon shows a lit limb from its key light, the corona appears, and the wheel light glows on the feet.

---------------------------------------------------------------------------------------------------------------------------------

## 12. Equip assembly (≈ 6 s, mechanical, no flash) and unequip

> **Pass 5.2 (2026-10-17): the reveal.** Milo: *"the effect has a clear buildup, a single strong peak, and an aftermath
> that settles into a beautiful lower-intensity idle state ... Allow brief, controlled flashes only at the most important
> moment."* The assembly below still builds the machine, then a **reveal** runs on top of it (`hosts.reveal`, called every
> frame while `st.revOn`; `ASM_END` 7.0, `REV_BUILD` 4.6, `PEAK` 6.6, `REV_END` 9.8):
>
> | Time (s) | What happens |
> |---|---|
> | 3.6–4.8 | the hands spin in to **five to midnight** (minute hand at XI, hour hand 2.5° short of XII) |
> | 4.6–6.4 | **buildup**: the energy links light up along their length (moon 4.6, void 5.2, floor 5.6); the gears race (pace ×1 → ×3); the runners race; the void's smoke draws in (its speed falls in 4 steps to a quarter); the moon (+0.45) and the galaxy's heart (+0.8) brighten; the moon's motes surge into IX (rate 5 → 30); streaks converge on the hub from a 15-stud shell (rate 10 → 60, 4.9–6.6); a golden light sweeps once round the stage (4.6–6.6); the wearer's bloom builds (0 → 0.3) and the view pushes in (FOV × 0.94) |
> | 5.0–6.6 | the trail of light sweeps the dial once, reaching each hour plot as it lights (I at 5.13 … XII at 6.6, each 0.3 s in five Neon steps); the minute hand **ticks** from XI to XII a minute at a time (5.0, 5.4, 5.8, 6.2, 6.6; each tick 0.14 s with a hair of overshoot) |
> | **6.6** | **midnight**, once: the gears stop dead for 0.4 s; the wave across the floor (one flat ring, Size 3 → 65 over 1.7 s, its front streaks racing out at 16 studs/s); one star flares at the hub (Size 3 → 16 → 0 over 0.7 s, the only flash); 44 glints burst off the dial and slow into orbit round it (Drag 1.7, locked to a ring turning 30°/s); 30 sparks lift off the floor; a ring off the moon (Size 9 → 26 over 1 s, behind its face); the void's smoke blown out (12 billows at speed 7–10); a pulse of light on the links (+1.4), the moon (+0.9), the galaxy's heart (+0.9) and the stage (+0.4), decaying with a 0.3 s time constant; the wearer's bloom peaks (+0.7) |
> | 6.6–9.8 | **aftermath**: the boosts fall back, the air's sparkles and the time dust stay lively and calm down (rates 30 → 14, 30 → 16), the trail fades out and comes back on the seconds hand (7.8–8.8), the bloom is destroyed (8.2), the grade eases back (from 7.1 over 2.4 s), the field of view returns exactly (9.4) |
>
> So the table's "no pulse and no flash" now reads: one pulse, at midnight, and nothing else. Every value the reveal drives
> is quantised and written only when its step changes, and at the end everything is left at rest (`st.revOn` false: no
> more writes). With `ASSEMBLY` off the aura starts at `REV_END`: the plots are lit and nothing of the reveal runs.

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
| 0.0 | **Grade** (local wearer, real equip only, as pass 4) | ColorCorrection `TheEndReveal` under the camera tweens to Saturation −0.75, Brightness −0.1, Contrast 0.15, Tint (232,238,255) over 1.2 s Sine. It starts on the **first update with the aura visible** (review round 2: `update` returns before anything else while the aura is hidden, so neither the grade nor the assembly advances under the roll cutscene even if the framework keeps calling it; never over a Scriptable camera; never later than age 4.5), and from age 5.8 (checked in update) tweens back over 2.2 s, then destroys itself. On `setVisible(false)` it eases out in 0.4 s, on `destroy` in 0.8 s (never snaps). One grade per client: a re-equip during the ease-out takes the live one over instead of stacking a second, and only the build that took it last eases it out (`gradeOwner`) | — |
| 1.0 | P4a ink smoke on (off the void, so the dark corona builds round the core as it forms) | | |
| 0.0–1.2 | **Void core** condenses | `Size` Ø 0.6 → 8 by easeOutBack (Size writes on 1 part, assembly only) | 0.0–0.4 |
| 0.25–1.4 | Photon ring | segment i slides radially from R 11 to rest, start 0.25 + 0.04·i, 0.6 s each | first 0.2 s of each |
| 0.3–1.1 | Accretion disc | spin rate 400°/s decays to 40°/s by `40 + 360*exp(-3*(age-0.3))` | ImageTransparency 0.3–1.1 |
| 0.6–1.8 | **Moon rises** (the Ø 6 core and its opaque face disc) | from V y −9 (out of the dais) up to Pv | 0.6–0.9 |
| 0.6–1.6 | Key light L1 (night only) | Brightness 0 → night value | — |
| 0.9–1.7 | Lensed disc (beams B5, B6; review round 3) | | Beam Transparency 0.9–1.7 |
| 0.9–1.5 | Heart spikes extend | from the star centre (local y 0) outward | 0.9–1.1 |
| 1.2 | P1 VoidSwirl on | | |
| 1.0–2.4 (+r0) | **Meridian** and pins | from lying flat on the dais (frame `Gd * CFrame.new(0, 0.95, 0) * CFrame.Angles(rad(90), 0, 0)`) up to F1. **r0** (review round 3, R3W-2) = 3.5 for the owner's close camera (cz > 0.5 at the first visible frame, decided once), else 0: at the default zoom the rings wait flat on the dais until the hands have locked at XII and rise as the finale (4.5–5.9, 4.8–6.2, 5.1–6.5); risen earlier, the meridian stood across the dial during the lock | 1.0–1.3 |
| 1.3–2.7 (+r0) | **Equator** and ticks | same start, up to F2 | 1.3–1.6 |
| 1.4–2.2 | Moon halo | | ImageTransparency |
| 1.6 | P2 MoonDust and P4b moon smoke on | | |
| 1.6–3.0 (+r0) | **Ecliptic** | same start, up to F3 (ends at 6.5 = ASM_END with r0: nothing snaps) | 1.6–1.9 |
| 1.8–3.0 | Balance sway | swayAmp 0 → 1 (smooth) | — |
| 2.0–3.6 | **Bezel sweep** | segment i flies in from (R + 7, z − 4, θ + 40°), start 2.0 + 0.9·i/N (clockwise from XII), 0.7 s | first 0.25 s |
| 2.3–3.8 | **Chapter ring** | segment i from z −3, start 2.3 + 0.9·i/N, 0.6 s | first 0.25 s |
| 2.5 | P6a, P6b air sparkles on | | |
| 2.6–3.6 | **Gears GA–GD** slide out from behind the dial | from (0.3·cx, 0.3·cy, −4) to rest; spin rate 300°/s → running rate (exp) | 2.6–2.9 |
| 3.0–3.6 | GE (from z −3), GH and GI (from z +3); the **backplate** rides GE's frame and slides in with it | | 3.0–3.2 (backplate 3.0–3.3, its star-window GUI 3.0–3.4) |
| 3.0–3.95 | Rete bars | bar k from radius ×2.2, start 3.0 + 0.04·k, 0.5 s | first 0.15 s |
| 3.0 | P6c bokeh on | | |
| 3.2–3.6 | Sub-dial | from z −2 | 3.2–3.4 |
| 3.4–4.15 | Hour plots set in | plot h from z +3, start 3.4 + 0.04·h, 0.3 s | first 0.1 s |
| 3.4–4.2 | Inlay GUI | | ImageTransparency |
| 3.6–4.8 | **Hands spin in and lock** | hour from θ −330°, minute from −1050°, seconds from θs(now) − 720°, by easeOutBack; the seconds hand then runs | 3.6–3.8 |
| 4.0–4.4 | Dais base disc | | 4.0–4.4 (G0 floor and G2 core GUIs 4.0–4.6, with it) |
| 4.0–5.25 | **Dais rim wave** | segment i rises from y −1.2, start 4.0 + 0.8·i/N, 0.45 s | first 0.15 s |
| 4.2–4.8 | **Crown, stem, cap, bow** drop in | from y + 6 | 4.2–4.4 |
| 4.2–5.2 | Galaxy G1 arms, engraving GUIs | | ImageTransparency |
| 4.6–5.8 | **Balance wheel** starts swinging | wheelAmp 0 → 1 | 4.6–4.9 |
| 4.6–5.6 | Wheel light L2 (night only) | Brightness 0 → night value | — |
| 4.6–5.4 | Streams | Beam Transparency sequences scaled from fully transparent to rest (≤ 20 writes; each beam fades from its own time) | — |
| 4.8 | P3 ShardFeed, P7 mist, P8a/b, P9 funnel on | | |
| 5.0–6.25 | **Time shards** fly from the bezel rim (K point at R 14, angle 300° + 20°·i) onto their slots on the ecliptic **where it is** (review round 3: rising or still flat on the dais) | start 5.0 + 0.06·i, 0.8 s | first 0.2 s |
| 5.0–6.0 | Corona (if night) | | ImageTransparency to its night value |
| 5.2 | P10a/b palm intake, P11 body wrap, P12 speed trail (only while fast) on | | |
| 5.65–6.35 | **Highlight** | Fill and Outline transparency 1 → target, only once every silver part is solid (a Highlight paints a part that is still fading in at full strength, which made the rising dais rim pop) | — |
| 5.8–8.0 | Grade eases back (wearer only) | | |

- **Who sees it:** the assembly plays on every build (`CONFIG.ASSEMBLY_REMOTE = true` also for other players' auras). The grade plays
  only for `ctx.isLocal`, and not on spawn or join (pass 4's `spawnedAt`). Review round 3 (R3S-10, CR3-05): decided at the **first
  visible update**, not at build (by then every `CharacterAdded` handler has run, whichever order the framework's and ours ran in),
  with a **12 s** window after the character spawned (the framework may build only once the avatar has loaded), and never when
  this client's own THE END was taken away from a different character less than 15 s before the build (a respawn; a weak
  reference, so no old character is kept alive).
- **Framework alpha** (`s.alpha`, 0 → 1 over 0.9 s at build; it may fall on unequip): the effective fade for each part is
  `assemblyFade × s.alpha`. After the assembly, while `s.alpha < 1` (unequip), every visible part, GUI and beam writes
  `rest + (1 - rest)*(1 - alpha)` on changes ≥ 0.04, and emitters switch off below alpha 0.6. `fx.destroy()` may arrive at any moment
  and must still clean everything.
- **Reveal after a hide:** when `setVisible(true)` follows more than 0.5 s hidden, the root is re-parented by the next update (with
  that frame's positions) and every fade is multiplied by a reveal factor that rises 0 → 1 over 0.4 s, so the aura fades back in
  instead of popping. The emitters follow the framework alpha only (the sky they start from is empty anyway); the body wrap waits
  until the wearer has been visible for 1.1 s. `setDetail(true)` likewise re-shows the Detail groups on the next update.
- `CONFIG.ASSEMBLY = false` jumps straight to rest at build.

---------------------------------------------------------------------------------------------------------------------------------

## 13. LOD, low quality, near-camera rules

Every part belongs to exactly **one** hideable group, and each group carries two flags: `detail` (hidden when far, §13.1) and
`armillary` (hidden when the camera is inside the rings, §13.3). A group is shown only when none of its flags hides it. Groups:
`Core` (no flags), `Detail` (detail), `Armillary` (armillary: the three bands), and `ArmillaryDetail` (both: equator ticks, pins and
time shards).

### 13.1 Far LOD (`fx.setDetail(false)`, framework: past ~110 studs)

- All emitters off (framework rule).
- The **Detail** and **ArmillaryDetail** groups are hidden: their sub-models are parented to nil and dropped from the move list.
  Detail = hour plots (12), GH and GI (12), G1 arms plane, bokeh host and ShardFeed host: **27 parts** (review round 3: the lensed
  arc is gone and the engraving, now the 56-stud stage, is Core). ArmillaryDetail = equator ticks (12), pins (4) and time shards
  (8). High moves **309** parts when far, low moves 150 (low builds no Detail parts). The rete, the bow, the corona and the stage
  stay (they are the clock's silhouette, its night glow and the aura's footprint from across the plaza).
- **No pop at the switch** (review round 2): the lights, the near-only beams B2, B4 (and the far beacon the other way) and
  another player's Highlight follow a far-detail fade `st.lod` (0.5 s, 0.05 steps, through the beams' precomputed fade steps);
  `Enabled` flips only at zero. At night a lit 52-stud patch of plaza no longer appears or vanishes in one frame at 110 studs.
- **Half rate** (review round 2): another player's aura past the detail range updates every other frame with both frames' time
  (springs and spins stay exact): half the cost for something about 40 px tall.
- `setDetail(true)` flags the groups to come back, and the **next update** re-parents them together with that frame's positions
  (one parent write per sub-model), so nothing flashes in at a stale pose.
- Past ~320 studs the framework calls `setVisible(false)`: the root is parented to nil and the body-wrap emitters are disabled.

### 13.2 Low quality (`ctx.quality == "low"`)

Built with the low counts in every table (150 parts, 11 emitters, 8 GUIs, 2 beams, 0 lights).

- Dropped entirely: hour plots, rete, bow and cap, corona, the ecliptic and pins, equator ticks, GB/GC/GD/GH/GI, the heart's
  spikes (review round 3: alone, the vertical pair read as a slit pupil), the horizon glow, time dust, time shards, G1,
  engraving, funnel, bokeh, mist, ash, moon-side smoke, ShardFeed, B2/B4 and the lensed disc B5/B6, L1 and L2
  (a moving light steps in 4-stud blocks on phones' voxel lighting).
- CanvasSizes are halved and shadows are off.
- The Highlight is kept for the owner's own aura (`CONFIG.HIGHLIGHT_LOW = true`) because it carries the monochrome look by day;
  other players' auras on low have none (review round 2: Roblox draws at most 31 Highlights per client, shared by the whole game).
- The rest is identical, including the assembly (shorter: the absent parts are simply not built).

### 13.3 Near-camera rules (all wearers; state flips only, with hysteresis)

| Rule | Hide when | Show when | Action |
|---|---|---|---|
| Armillary (inc. ticks, pins and the time shards) | `|camPos − A0| < NEAR_ARM_HIDE` (10) | `> NEAR_ARM_SHOW` (11.5) | **fade first** (review round 2): `LocalTransparencyModifier` on the ring parts in 3 steps over 0.25 s, then parent its sub-models to nil and drop them from the move list; on show, back in the world fully see-through at that frame's positions and faded in the same way (scrolling between 9 and 12 studs never snaps the biggest thing near the lens). **While the rings fade or ghost they leave the silver Highlight** (review round 3, R3S-1): their Silver holders are re-parented to a `SilverRings` model outside it (2 parent writes each way; `setGroups` follows), because a Highlight paints a see-through part at full strength and would leave a grey, ink-outlined ring silhouette |
| Bokeh P6c | `|camPos − O| < NEAR_BOKEH_HIDE` (18) | `> NEAR_BOKEH_SHOW` (20) | `Enabled` (the big discs only drift by in showcase framings) |
| **Remote ghost** (`GHOST_REMOTE`, other players' auras only) | the segment camera → `Camera.Focus` crosses their clock disc (R 14.5), passes within 5.5 of the moon or 7.0 of the void | clear for **1.2 s** | ramps at 5/s in 3 steps: clock and orb parts (and the moon face) take `LocalTransparencyModifier` 0.25 / 0.5 / 0.75 (one burst of writes per step), **and so do their beams and the emitters on the orbs, the swirl, the rim, the time dust, the shard feed, the horizon and the palms** (review round 2: Beam and ParticleEmitter have the same hidden property; if a build cannot write it, those beams and emitters switch off instead); from the second step the clock's GUIs (inlay, sub-dial, star window), the halo and moon face, the accretion GUI and the corona switch `Enabled` off (GUIs ignore LTM), and **the Highlight from the first step** (review round 3: it would paint the first ghost step solid) |
| **Remote ring ghost** (review round 2) | the same segment passes within 6.5 of their rings' centre | clear for 0.6 s | only the 76 ring parts take the LTM steps (a friend standing beside a wearer looks through the rings, never through the clock; round 1 ghosted the whole aura and switched its GUIs off whenever someone stood beside it). Ring LTM = the larger of this and the near-camera fade |

First person and close zoom never put rings or blobs across the lens: the layout eases into its close form (§5, factors `cz`, `fp`),
the moon halo fades with `cz`, and in first person the owner's clock rises into the sky (`FIRST_PERSON_LIFT`). The clock, orbs,
streams and dais stay. In first person (review round 3, AD3-09, R3W-6) the funnel (P9) and palm (P10) streaks, the air's
sparkles (P6a/b) and the body wrap (P11) switch off and the floor ash drops to 3/s (one event write each way): they sat round
the lens as white needles and black flakes.

The rules read `NEAR_HIDE` and `GHOST_REMOTE` as this build read them (review round 3, CR3-06): turning a flag off while a state
is held no longer leaves rings unparented or an aura ghosted until the next equip.

---------------------------------------------------------------------------------------------------------------------------------

## 14. Budget (asserted by the harness)

> **Pass 5.1 (2026-10-16):** the particle budget was raised for Milo's "particle effects tenfold" (new systems P15-P18,
> film-quality textures). The table rows below for parts, emitters and rate carry the pass 5.1 numbers; the texture list is
> in §16 and the details in `pass5-build-notes.md`, "Pass 5.1".
>
> **Pass 5.2 (2026-10-17):** raised again for Milo's execution brief (the clock's band, flange, star and Breguet hands,
> the runners, the link and reveal carriers, P19-P31). As built, high / low with the fallback textures: **454 / 163 parts**
> (459 with te5: the five te5-only layer carriers), **43 emitters, 34 on by day / 12 on** (the bursts and the converging
> streaks are never on: they `:Emit` once or run only in the buildup), **≈ 343 / 78 particles a second** at rest
> (≈ 891 / 164 alive; midnight adds about 130 once), **9 / 4 beams** (the three links / two), **11 / 8 GUIs** (16 with te5),
> 2 / 0 PointLights, 1 Highlight. Registers: 29 spare at -O0, 65 at -O1 / -O2. After the reveal (10 s) there are no
> per-frame GUI or Transparency writes; during it, quantised writes only (plot colours, boosts, rates, the trail's and the
> sweep's transparency), the wearer's bloom intensity and field of view, and two attachment `CFrame`s a frame for the
> spiral arms (always, while near).

Counts as built after review round 3 (fallback and te5 textures alike). **No limit was raised**: the finer armillary (+22
parts) was paid for by the lensed arc (9 blocks), the ribbon's end carrier, 2 bow segments, 4 dais-rim blocks and 6
chapter-ring blocks, and the new FloorFx carrier by P5's rim-glint carrier.

| Item | High | Low | Limit |
|---|---|---|---|
| **Parts moved per frame** (one `BulkMoveTo`) | **362** (pass 5.1: + the star halo and helix hub carriers) | **151** (+ the helix hub) | ≤ 362 / ≤ 151 |
| — clock C1–C12 (bezel 32, chapter **18**, rete, gears, hands, hub, plots, crown with an **8**-segment bow, backplate, the time-dust and shard-feed carriers, corona) | 173 | 68 | |
| — armillary A1–A4 (meridian **28 / 18**, equator **22 / 14**, ecliptic **24**, 12 hours, 4 pins) | 90 | 32 | |
| — moon M1, M3 (core + opaque face) | 2 | 2 | |
| — void V1–V6 (core, accretion, swirl and horizon carriers, photon ring 24 / 12, heart: ball + 8 spikes / ball only) | 37 | 16 | |
| — time shards | 8 | 0 | |
| — dais D1–D9 (base, floor, arms, core, **56-stud stage**, **FloorFx**, rim **24 / 16**, wheel, funnel) | 46 | 29 | |
| — body carriers | 4 | 3 | |
| Parts moved when far (Detail and ArmillaryDetail hidden) | **309** | 150 | |
| ParticleEmitters | **25** instances (pass 5.1: P1–P18 without P5; P11 is two on the torso; P6 and P15 are two each), 23 on by day | 12 on | ≤ 26 / ≤ 14 |
| Total Rate (particles/s) | ≈ **304** idle by day, ≈ 770 alive (pass 5.1; travelling: the smoke, moon dust, wisps and the helix cut back) | ≈ 78, ≈ 165 alive | ≤ 310 / ≤ 80 |
| Beams | 6 (+ 1 with `FAR_BEACON`, far only) | 2 | ≤ 6 / ≤ 3 (the beacon replaces the 2 detail beams, which are off when far) |
| SurfaceGuis + BillboardGuis | 10 + 1 = 11 | 7 + 1 = 8 | ≤ 12 / ≤ 8 |
| PointLights | 2 | 0 | ≤ 2 |
| Highlights | 1 | 1 (the owner's aura only) | ≤ 1 |
| Character-parented instances | 2 attachments (palms) + 2 emitters (the body wrap) | same | all cleaned in destroy |
| Luau registers in `End.build` | **67** spare at -O1 / -O2, **33 at -O0** (a debugging compile keeps constant locals in registers) | | ≥ 16 spare at every level (`tools/harness/register_headroom.py --opt 0,1,2`, run by `run_tests.py`) |
| Per-frame property writes after `age > 6.5` and alpha = 1 | 0 GUI or Transparency writes. Event writes only: night tick ≤ 1/s, palm flip, near-camera fade steps (and the rings' 2 parent writes in and out of the Highlight), grounded flip, speed-trail flip, ghost steps, seat flip, far-detail fade steps, Highlight fill and outline steps on zoom, the floor twinkles' size steps and the lensed bands' widths on zoom, the hairline bands (24 photon-ring Size writes, 1 needle), first-person flips (emitters, ash rate), the travelling flip (smoke, moon dust, wisps), Size writes during assembly. Every 0.2 s while grounded: 3 raycasts (no writes) | | |

---------------------------------------------------------------------------------------------------------------------------------

## 15. CONFIG flags and the film-mesh upgrade

`local CONFIG = {...}` sits at the top of the module. Any **attribute on the ModuleScript with the same name and type overrides the
default**, so Milo can flip flags in Studio without editing code. They are **read again at every build** (since review round 1: set
the attribute, then unequip and equip) and type-checked; a wrong type is ignored with a warn.

| Flag | Default | Purpose |
|---|---|---|
| `USE_FILM_MESHES` | false | Master switch for every `FILM_*` flag below |
| `FILM_BEZEL` | false | `RingG` replaces C1 (32 segments → 1 MeshPart) |
| `FILM_DIAL` | false | `Dial` replaces C2 (if the Dial is a solid disc it covers the skeleton; judge by screenshot) |
| `FILM_RETE` | false | `Astrolabe` replaces C5 |
| `FILM_HANDS` | false | `Hand` replaces the hour and minute hand bodies (shaft, tip, tail); the lume strips stay |
| `FILM_GEARS` | false | `Gear` replaces each gear's disc, web, teeth and spokes (hub kept), scaled per gear Dtip |
| `FILM_MOON` | false | `Oblivion.Moon` replaces M1 and its face disc |
| `FILM_VOID` | false | `Oblivion.SmoothSphere` replaces V1 (Material Neon, Color 0,0,0 forced) |
| `FILM_HAND_FLIP` | false | Turn the film hands 180° if their tip points at the hub |
| `FILM_KEEP_TEXTURES` | false | Keep each film MeshPart's TextureID (otherwise cleared and recoloured per §7) |
| `VIEWER_ANCHOR` | true | §5. false = body-anchored fallback |
| `CLOCK_DIST` / `CLOCK_HEIGHT` / `CLOCK_TILT` | 8 / 9.85 / 8 | Clock placement (§4, §5) |
| `YAW_SPRING` | 6.5 | Spring frequency in rad/s (95 % settle in 0.73 s) |
| `HIGHLIGHT` / `HIGHLIGHT_LOW` | true / true | Silver-tone Highlight (§7.2) |
| `SHADOWS` | true | Moon and void core cast shadows (high only) |
| `ASSEMBLY` / `ASSEMBLY_REMOTE` | true / true | §12 |
| `GRADE` | true | Wearer-only equip grade |
| `DAIS_FLOAT` | true | Dais floats under the feet when airborne |
| `AIR_ON` / `AIR_OFF` | 12 / 9 | Feet this high above the ground count as flying (the dais lifts); below `AIR_OFF` grounded again (§8.6) |
| `YAW_LAG_MAX` | 22 | Most (degrees) the clock and orbs may trail a fast camera swing (§5) |
| `ZOOM_FAR` / `ZOOM_NEAR` | 30 / 14 | Camera distances over which the layout eases into its close-camera form (§5; Roblox's default zoom is 12.5) |
| `FIRST_PERSON_LIFT` | true | In first person the owner's clock rises into the sky, out of the level view |
| `HIGHLIGHT_FILL` / `HIGHLIGHT_OUTLINE` | 0.65 / 0.35 | Day FillTransparency / OutlineTransparency of the silver tone (night 0.80 / 0.70) |
| `NEAR_HIDE` | true | §13.3 |
| `NEAR_ARM_HIDE` / `NEAR_ARM_SHOW` | 10 / 11.5 | Armillary near rule (§13.3) |
| `NEAR_BOKEH_HIDE` / `NEAR_BOKEH_SHOW` | 18 / 20 | Bokeh near rule (§13.3) |
| `GHOST_REMOTE` | true | Another wearer's aura turns see-through while it stands between you and your camera (§13.3) |
| `FAR_BEACON` | false | (Needs Milo's OK) a thin steady spire over the wearer seen only from far away; ink by day, white at night, no pulse. MILO_PROMPT asks him with two screenshots (review round 3, R3W-7) |
| `LINKS` | true | (Pass 5.2) the three energy links: moon → IX, III → void, VI → the floor's vortex (thin tapered Beams with gliding pearls of light) |
| `REVEAL_BLOOM` | true | (Pass 5.2) on the wearer's own screen only, a BloomEffect under the Camera that builds through the reveal's buildup, peaks at midnight and is destroyed ~1.6 s later |
| `REVEAL_PUSH` | true | (Pass 5.2) on the wearer's own screen only, the field of view narrows 6 % through the buildup and comes back exactly by the end of the reveal; it lets go at once (never writes again) if anything else changes the field of view or a cutscene takes the camera |
| `FRAME_TOP` | 9.6 | (Review round 3, R3W-1) how far above the hub the owner's camera always keeps the watch in frame: 9.6 = up to XII (the hands at midnight), 22.4 = the whole watch with its bow (smaller at the default zoom), 0 = off (§5). Range 0–24 |
| `RIM_R` | 0.86 | (Review round 3, CR3-02) where the pass-2 `rim` texture's ring peaks, as a fraction of its half-width; the corona, the void's horizon glow and the moon halo are scaled by `0.73 / RIM_R` until te5_halo is uploaded. Measured on the Mac (studio_checks check 14). Range 0.5–0.98 |
| `FLOW_SIGN` / `ACC_DIR` / `FUNNEL_DIR` / `GALAXY_DIR` | 1 | Studio direction checks, one flip each: −1 reverses the stream flow, the accretion / swirl spin, the floor vortex, the galaxy arms |
| `WEDGE_SWAP` | false | true if the heart's spikes come out hollow (Roblox wedge orientation) |
| `STREAK_FLIP` | false | true if the streak particles fly tail-first |
| `FRONT_FACES` | false | true if the dial inlay / corona show mirrored or on the wrong side (uses pass 4's proven Front faces) |
| `SWIRL_POINTS` | false | true if the void swirl / floor vortex spray as flat sheets (Cylinder emitters incl. caps): one rim point emitter each instead |
| `NIGHT_INTERVAL` | 1.0 | Seconds between day/night evaluations |
| `DEBUG` | false | Print counts (parts, emitters, GUIs, beams) once at build |

**Attribute reading** (review round 1): an attribute whose name looks like a flag (upper case) but is not one warns once (a
spelling check); a wrong type, NaN or infinity is ignored with a warning; numbers outside their range (`RANGES` in the module) are
clamped with a warning; the four direction flags accept only the sign; the hysteresis pairs are kept in order (`ZOOM_NEAR <
ZOOM_FAR − 1`, `AIR_OFF ≤ AIR_ON − 0.5`, each SHOW ≥ HIDE + 0.5).

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

> **Pass 5.1 (2026-10-16):** 23 te5 textures in three groups: `textures/te5/particles/` (shards, ash, twinkle, stardust,
> mote, glint, bokeh, streak, spark: six flipbooks are 1024² Grid4x4), `textures/te5/smoke/` (billow and wisp, 1024²
> Grid4x4 OneShot; mistbank, 512²) and `textures/te5/surfaces/` (the 11 surfaces; te5_stream is now 512×128). te5_smoke is
> retired (billow, wisp and mistbank replace it). The module's tables (`TEX5`, `TEX5_LAYOUT`, `FALLBACK`) hold the pass 5.1
> keys; the tables below describe pass 5 and are kept for history. Each manifest records the texture's key, fallback,
> size, layout and mode.
>
> **Pass 5.2 (2026-10-17): 29 te5 textures.** New: `te5_bezel_band` (1024², bezelBand: the bezel band's engraving, every
> visible pixel inside r 0.9365-0.9895 of a 27.4-stud plane, so the band's dark parts at 12.70-13.62 studs cover it: a
> 360-tick degree scale, the hours' stars at r 0.958, planets between, faint constellation hairlines, bevelled edge lines
> at r 0.940 and 0.986), `te5_trail` (1024², trail: a comet arc, core at r 0.946, head at the canvas top fading out within
> ~2.5° clockwise, tail running counter-clockwise for 80° as exp(-dθ/22°); 11.83 studs on the 25-stud dial plane, 26.5 on
> the 56-stud stage), `te5_galaxy_swirl` (1024², galaxySwirl: fine filaments, the floor's winding, pitch 14°, mean alpha
> 0.17, empty inside r 0.10), `te5_energy_rings` (1024², energyRings: rings at r 0.22-0.86, some broken into 24, 12, 8 or
> 18 arcs, 120 ticks at r 0.80, a boundary ring at r 0.965), `te5_link` (512×128, link → streak: a faint thread with one
> symmetric pearl of light per tile, nothing beyond ±33 px of the centre row) and `te5_shockwave` (512², shockwave → rim:
> a thin ring at r 0.86 with a streaked wake inward to r 0.55; its front is 0.86 × the particle's size). Rebuilt:
> `te5_engraving` is now an **opaque near-black annulus** (r 0.548-0.992, base grey 14) with light markings (205-255,
> a centre-ridge bevel that stays right as the stage turns): the rings, the guilloche band, the Roman numerals, a degree
> scale on the r 0.875-0.918 ring, the minute band's ticks and batons, ten small constellations; the module tints it gold
> (`GOLD` 228,196,132), so its row below describes the pass-5 version. `te5_dial_inlay` keeps its layout, with a
> polished-metal bevel on the numerals, ticks and stars (light from the upper left; the module draws it at Brightness 1.0
> by day and 1.8 at night so the bevel is not clipped to flat white). The four te5-only layers (bezelBand, trail,
> galaxySwirl, energyRings) have no pass-4 look-alike: their `FALLBACK` is `none` and they are not built until uploaded.

### 16.1 Tables in the module

Keep pass 4's `TEX` table **verbatim** (all ids already uploaded). Add `TEX5` (18 keys; review round 2 dropped `hairspring`, review
round 3 `ribbon`), which
Milo's Mac fills after upload (ids stay `""` until then), and a resolver:

```lua
local TEX5 = { -- te5 uploads (textures/te5/); "" until uploaded from the Mac
	dialInlay = "", subdial = "", accretion = "", galaxyFloor = "", galaxyArms = "", galaxyCore = "", engraving = "",
	halo = "", stream = "", moon = "", starWindow = "",
	shards5 = "", smoke5 = "", mote = "", glint5 = "", bokeh = "", streak5 = "", ash5 = "",
}
local TEX5_LAYOUT = { shards5 = { "Grid4x4", "Loop" }, smoke5 = { "Grid4x4", "OneShot" } }
-- the fallback te4_moon is cropped to its moon disc on the face (applyTex sets ImageRectOffset / ImageRectSize from this)
local CROP = { moon = { Vector2.new(104, 104), Vector2.new(304, 304) } }
local FALLBACK = { -- key -> { pass-4 TEX key, layout, mode }
	dialInlay = { "dialOuter" }, subdial = { "dialInner" }, accretion = { "galaxy4" }, galaxyFloor = { "galaxy4" },
	galaxyArms = { "galaxy4" }, galaxyCore = { "ornate" }, engraving = { "gring" }, halo = { "rim" },
	stream = { "line" }, moon = { "moon" }, starWindow = { "galaxy4" },
	shards5 = { "ash", "None", "Loop" }, smoke5 = { "puff", "Grid4x4", "OneShot" }, mote = { "glow" }, glint5 = { "glint" },
	bokeh = { "glow" }, streak5 = { "spark" }, ash5 = { "ash", "None", "Loop" },
}
-- T(key) -> id, layoutName, modeName   (layout "None" when not a flipbook)
```

Emitters must apply the **layout and mode returned by `T`**, because a fallback can have a different layout from its te5 texture.

- **Validation (`idOf`):** a TEX5 value may be `"rbxassetid://123"`, bare digits `"123"`, the number `123`, or `rbxasset://` /
  `rbxthumb://`; surrounding spaces are trimmed. Anything else (a typo, a URL, a decal page link) warns once and uses the fallback.
  `"pending:<key>"` is the preview renderer's placeholder for a PNG not uploaded yet (tools/); `make_payloads.py` refuses a module
  that still holds one, so it is never shipped.
- **Load check:** at the end of each build, the filled-in ids **that build draws** and that were not asked for yet go to one
  background `ContentProvider:PreloadAsync` (never blocks require or build; review round 3, R3S-7 / CR3-07: a low-quality build
  never asks for galaxyArms, engraving, shards5, ash5 and bokeh, so a phone does not hold ~17 MB of textures it never draws;
  several keys may share one id, and a failure swaps every one of them). A texture that does not load is reported once and **swapped for its fallback everywhere** it is used (images, beams,
  emitters including their flipbook layout), and later builds use the fallback straight away. Review round 2: only
  `AssetFetchStatus.Failure` counts at once; a `TimedOut` (or any other status: common on a phone or a cold cache) is asked for once
  more 20 s later before anything is swapped.
- **Choices made because te5 was there** (review round 2): the face brightness of `moon`, the star window's brightness, the ×1.3 /
  ×2.2 particle sizes of `shards5` and `streak5`, and (review round 3, CR3-02) the sizes of the night corona, the void's horizon
  glow and the moon halo, which are made for te5_halo's ring (r 0.73) and scaled by `0.73 / RIM_R` while the pass-2 `rim` texture
  stands in (`RIM_R` attribute, default 0.86 until measured on the Mac). Each such object registers a fix-up hook (`fixUps[o](o)`,
  weak-keyed, the object passed in so the entry never holds its own key) that the failure path runs after the texture swap: the
  brightnesses and sizes go to the fallback's. Nothing runs per frame. (te5_smoke is a dense billow since review round 3 and is
  drawn at the fallback's size: no ×1.3, no hook.)
- **Geometry:** the moon is the same core and opaque face disc with either texture (§8.3); te5_moon is drawn whole, te4_moon
  cropped (`CROP`). `starWindow` is drawn brighter than its galaxy4 fallback (§11).

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
| `te5_engraving.png` | 1024² | engraving → gring | **The stage** (review round 3): a ground ring for the **56-stud** plane (r 1 = 28 studs), from just outside the dais rim to the edge. White (240) strokes with a 2 px ink edge (20, alpha 0.95), nothing semi-transparent: a frame of rings at r 0.585 (3 px), 0.605, 0.632 and 0.688 (1.6 px); a guilloche band of 120 ticks r 0.638–0.682 (every 10th 2.6 px); Roman numerals I–XII **3 studs tall** (height 0.107) at r 0.80 with half-hour four-point stars; rings at r 0.725 and 0.875; and an **inked minute track**, a solid ink band (16, 16, 20, alpha 1) r 0.925–0.975 framed by white rings at 0.918 and 0.982, with 60 white ticks inside it and lume batons (6 px) every five minutes. |
| `te5_halo.png` | 512² | halo → rim | Rim-only halo: alpha 0 for r < 0.66, smooth rise to 0.95 at r 0.74, then a soft tail: 0.35 at 0.82, 0.10 at 0.90, 0 at 1.0. RGB white. Used by the moon halo (15 studs), the night corona (44 studs) and the event-horizon glow particles (11.2 studs). |
| `te5_stream.png` | 256×64 | stream → line | Beam band, tiled in U (seamless). v ∈ [−0.5, 0.5] across. Alpha 1 for \|v\| < 0.40 with a 1.5 px AA edge. **Ink edges** (RGB 12) for \|v\| 0.32–0.40. A white core (base L 0.8) for \|v\| < 0.30 with 5–7 brighter longitudinal filaments (L 1.0) that wave with a period of 256 px. 2 px transitions. |
| ~~`te5_ribbon.png`~~ | — | — | Dropped in review round 3: the ink ribbon became the void's lensed disc, which uses te5_stream (generator in the git history). |
| `te5_moon.png` | 1024² | moon → moon | (Review round 1, AD4.) Photographic full-moon face for the moon's camera-facing opaque face disc (§8.3). North up, Earth-facing side: maria (metaball shorelines, grey 95–145) where the real ones are, highlands 212–240, ~60 craters with lit upper-left rims and shadowed floors, rayed Tycho / Copernicus / Kepler / Aristarchus, faint limb darkening and low relief. Hard alpha edge at r 0.985 (1.6 % ramp): no ring, no glow. |
| `te5_star_window.png` | 1024² | starWindow → galaxy4 | (Review round 1, AD1.) Deep space for the clock's solid movement plate. Opaque near-black field (alpha 1 to r 0.985), a faint grey Milky-Way band at 32° with dust lanes, ~2600 single-pixel stars and ~70 soft brighter ones (5 with tiny spikes). Turns with the centre wheel. |

**Group "particles"**

| File | Size | Flipbook | texKey → fallback | Spec |
|---|---|---|---|---|
| `te5_shards.png` | 1024² | **Grid4x4**, Loop | shards5 → ash | A tumbling metal sliver: an irregular thin quad prism with vertices (−0.30, −0.42), (0.22, −0.35), (0.34, 0.40), (−0.12, 0.46) × 0.8 of the cell and thickness 0.06. 16 frames rotate 22.5° each about the axis normalize(0.35, 1, 0.2), for a seamless loop. Flat shading: front face L 0.86, back face L 0.25, sides L 0.55, a 1 px specular line on the lit edge, and a 2 px ink outline (10) round the silhouette. Alpha 1 inside, 1 px AA, ≥ 20 % padding. |
| `te5_smoke.png` | 1024² | **Grid4x4**, OneShot | smoke5 → puff | Review round 3 (AD3-01): **a dense ink-tight billow** (the old curl covered ~30 % of its cell, mostly translucent, so in game the void's "ink" read half see-through and teal). The billow fills ~80 % of its cell: a body of radius 0.37 → 0.405 with round cauliflower lobes reaching ~0.44, alpha ~0.93 over its inner half, per-cell mean alpha ≥ 0.30 in frames 0–11, torn ridged wisps only at the edge; a slow curl; it dissolves from the edge inward into ragged wisps only in frames 12–15 (mean alpha 0.36 → 0.08). Radial window reaching 0 at 0.46 of the cell. RGB 0.75–1.0 internal shading (the lobes' relief, lit from the upper left), so a dark particle Color keeps its structure. Dithered alpha. Drawn at the fallback's size (no ×1.3). |
| `te5_mote.png` | 128² | — | mote → glow | Core disc r < 0.22 (alpha 1, RGB 255). Ink rim r 0.22–0.30 (RGB 18, alpha 0.85) so it reads on a bright sky. Glow r 0.30–0.5 (RGB 255, alpha 0.25 → 0, smooth). |
| `te5_glint.png` | 256² | — | glint5 → glint | 4-point glint. Horizontal and vertical spikes span the full width; thickness 6 px at the centre tapering to 0.5 px at the tips; alpha 1 → 0 toward the tips. 45° spikes at half length 0.45 with alpha 0.5. Core disc r 0.05 at alpha 1. A thin ink halo r 0.07–0.09 (RGB 15, alpha 0.6). |
| `te5_bokeh.png` | 256² | — | bokeh → glow | A hexagonal aperture disc (circumradius 0.46, corners rounded 15 %). Interior alpha 0.55 with radial brightening L 0.9 → 1.0. Rim band (outer 8 %) alpha 0.85. 2 px AA, faint onion-ring noise ±0.03 alpha. White. |
| `te5_streak.png` | 256² | — | streak5 → spark | A **vertical** matter streak for VelocityParallel, in a **square** 256 px cell (Roblox draws particles square: the old 64×256 PNG was squashed). Capsule from y 0.04 to 0.96, 22 px wide (1:10): a white core ~13 px (alpha 1) and ~4 px ink edges (RGB 15, alpha 0.9). The upper (leading) end is brightest; the tail fades over the lower 40 %. The module draws it 2.2× the spark fallback's size; `STREAK_FLIP` if it flies tail-first. |
| `te5_ash.png` | 256² | — | ash5 → ash | (Review round 2: was a 1024² 2×2 flipbook, 5 MB of texture memory for a flake that never covers more than ~20 px, and its Random mode would have cross-faded each flake into another.) One irregular charred flake (a jagged 9-gon, 0.74 of the image); the emitter's random rotation and tumble make every particle look different. Body RGB 14–22 at alpha 1 with faint fibre texture. A 1 px silver edge highlight (RGB 190) on the upper-left edges. ≥ 12 % padding. **Roblox only animates flipbooks on 1024² textures**, so every Grid PNG (shards, smoke) is 1024²; `patch_tex5.py` refuses to record or patch a flipbook PNG of any other size. |

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
11. Grade wanted (if equip); it is created by the first update that has the aura visible (§12).
12. `root.Parent = ctx.container`.
    (Review round 1: the build body keeps ≥ 16 of Luau's 200 registers spare: state lives in the `st`, `hosts` and `em` tables.)
13. Initialise ψ, yawW, daisY and the night factor.

### 17.3 `fx.update(dt, s)` outline

```lua
function fx.update(dt, s)
	if destroyed or not visible then return end       -- (review round 2) FIRST: hidden = nothing advances, whether or not
	                                                  -- the framework keeps calling update under the roll cutscene
	if remote and not near then ... end               -- (review round 2) far remote wearers: every other frame, with both dts
	dt = math.min(dt, 0.1); age += dt
	local O = s.cf.Position + Vector3.new(0, s.hover, 0)
	-- 0 grade start (first visible frame, never over a Scriptable camera, never after age 4.5); speed; seat
	--   (after a long hide: st.snap -> the spring, zoom, dais, height ride and ring lift start where they belong)
	-- 1 frames: yawW -> W; camera + spring -> psi -> V; K; A0 -> F1/F2/F3; Pv -> moonC/voidC; n, dc -> Hf, Pf, rt; Dk; daisY -> Gd; Bw
	-- 2 group CFrames for every shown group (gears and hands use s.now; sway, gimbals and wheel use s.t)
	-- 3 cfs[i] = groupCF * local[i]   (while age < 6.5: lerp from the assembly start pose per §12)
	workspace:BulkMoveTo(activeParts, activeCfs, Enum.BulkMoveMode.FireCFrameChanged)
	-- 4 event writes only:
	--   assembly fades / Size / beam transparency while age < 6.5;  unequip fades while s.alpha < 1
	--   palm flip (Attachment1 x4);  near-camera fade steps (§13.3);  grounded flip (P7 Enabled)
	--   speed-trail flip (P12);  seat flip;  remote ghost steps (§13.3);  re-show after hide / far (pending flags)
	--   far-detail fade steps (§13.1);  first-person stream flip;  Highlight outline / floor-mote size steps on zoom
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
2. Ease the grade out over 0.8 s, then destroy it (if any).
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

**Review round 1 additions** (named scenarios in `tools/harness/runtime/scenarios.luau`; 28 after round 1; the ones marked
FOLLOW use the Studio-default follow camera in `run_aura.py`):

| Scenario | What it does | Checks |
|---|---|---|
| `fast_turn` | follow camera 16 behind / 6 up orbits at 180°/s for 2 s from t = 8 (a right-drag) | the clock and orbs trail at most `YAW_LAG_MAX`, never cross the lens |
| `fast_turn90` | the same at 90°/s | as above |
| `camera_flick` | the follow camera flicks half a turn round the wearer in 0.25 s | the lag cap holds; no NaN; the spring settles |
| `pair_behind` (FOLLOW) | a remote wearer stands 7 studs behind-right, between you and your camera | their aura ghosts (§13.3) |
| `pair_walkby` (FOLLOW) | a remote wearer walks across behind you (z = 8) from x −30 to +30 | ghost enters and leaves in steps, no flicker |
| `jump` (FOLLOW) | a full Roblox jump (JumpHeight 7.2, gravity 196.2) every 2 s from t = 7 | the dais holds; no speed trail; no flicker |
| `seated` (FOLLOW) | the wearer sits on a 1-stud Seat (Humanoid.Sit, SeatPart): the ground ray hits the seat top | the dais sits at the lower of ground and feet |
| `small_avatar` (FOLLOW) | HipHeight 1.4 (HRP 2.4 above the ground), idle then walking | the wheel and clock clear the dais; the layout scales with the legs |
| `downhill` (FOLLOW) | walks at 16 studs/s while the ground drops 6 studs/s (t = 8..11) | the dais follows down fast (spring 30/s down, 8/s up), never lags behind |

**Review round 2 additions** (32 scenarios in all):

| Scenario | What it does | Checks |
|---|---|---|
| `equip_in_cutscene` (FOLLOW) | equipped at 0.1 s while the roll cutscene's Scriptable camera holds the screen (0–5 s); the framework **keeps calling update** while the aura is hidden (`H.UPDATE_WHILE_HIDDEN`) | lint `grade-over-cutscene` (no ColorCorrection under the camera past 0.6 s of a Scriptable period) and `assembly-unseen` (the void is still condensing on the first visible frame): pass 4 trips both, pass 5 neither |
| `equip_in_cutscene_paused` (FOLLOW) | the same, but the framework does not call update while hidden (the mock's default) | the same checks |
| `pair_side` (FOLLOW) | another wearer stands 5 studs to your side | only their rings ghost, never their clock, orbs or GUIs |
| `visit_close` | a player without the aura stands in front of a wearer, then walks round to their side | as above; no flicker |

**Review round 3 additions** (35 scenarios in all):

| Scenario | What it does | Checks |
|---|---|---|
| `teleport` (FOLLOW) | the wearer is teleported 60 studs up onto a platform at t = 8 and back down at t = 10 (no hide); the camera follows at once | lint `teleport-lag` (the clock's inlay, the moon and the void within 0.5 studs of where they rode, relative to the HumanoidRootPart, in the 3 frames after each jump) and `teleport-trail` (the speed trail stays off) |
| `nan_frame` (FOLLOW) | one update gets a NaN hover (t = 8), another a NaN HumanoidRootPart CFrame (t = 9; the framework's culling still sees the real one) | lint `nan-state`: no aura part keeps a NaN position, and the clock rides within 1 stud of where it did |
| `slope` (FOLLOW) | the plaza is a 10° slope rising ahead; idle, then walking uphill (t = 8..10) | lint `slope-dais`: the dais base within 1.5° of the slope, no rim block more than 0.1 into the ground; snapshots record the tilted plaza (`world.groundUp`) and the renderer tilts its ground |
| `pair_side`, `pair_behind` | (above) | also lint `own-clock-hidden`: from your camera nothing solid of the other wearer's aura hides your own clock's hub or XII (sampled every 0.5 s from t = 7 to 12; round 2's module: 11 of 11 hidden) |

The flicker lint also watches a ParticleEmitter's `Size` sequence (a swapped size resizes the live particles at once).

The register headroom of `End.build` (≥ 16 spare of Luau's 200, at -O0, -O1 and -O2) is a test in
`tools/harness/tests/run_tests.py`.

### 18.2 Automated acceptance checks (fail the run on any)

1. **Budgets** (§14): moved parts ≤ 360 / 150, emitters, total Rate, beams, GUIs, lights ≤ 2, Highlights = 1.
2. **Part flags:** every part is Anchored with CanCollide, CanQuery and CanTouch false. CastShadow is false except moon and void on
   high.
3. **Write discipline:** after t > 7 with alpha = 1, there are 0 writes to any GUI property or BasePart.Transparency, apart from
   night-tick writes (≤ 1 per simulated second, and only when nq changed). There are 0 `Instance.new` calls inside update. There is
   exactly 1 BulkMoveTo per update.
4. **Monochrome:** what the harness lint enforces: no colour's HSV saturation above 0.15 (at value above 0.12). The silvers have
   been neutral, a hair warm (B a little below R), since review round 2: the cyan day sky already tints Metal blue, so cool
   tokens read baby-blue (CR3-08: the earlier "B ≥ R" rule no longer matches the module or the lint).
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
9. **Character:** the palm attachments and the body-wrap emitters are created on the right parts (R15 and R6). The palm flip
   happens only across f = ±0.2.
   After `destroy()` nothing is left on the character, camera or container (S14), and `update()` after destroy is a no-op.
10. **Film flags:** (a) falls back silently with no yields; (b) normalised sizes are within 2 % of target, the thin axis maps to K z,
    and the non-round Dial is rejected.
11. **Assembly:** at t = 6.5 every part sits at rest (CFrame error < 0.001) at rest transparency. No part's transparency goes 0 → >0
    → 0 during the assembly (no blink). The grade exists only for `isLocal` with a real equip.
12. **Dais:** S08 → the dais Y never changes and there are no transparency writes. S07 → the dais floats 2.4 below the visible feet.
13. **LOD:** S10 → 51 parts parented out (high: 27 Detail + 24 ArmillaryDetail; review round 3), the move list = 309, emitters
    off; everything restored by the first update after t = 11.

### 18.3 Preview renderer views (and what to look for)

| View | Camera | Pass when |
|---|---|---|
| P1 front day | S02 | The clock reads as a **solid object**: a silver fluted ring with a dark chapter ring, gear teeth breaking the silhouette at 1:30/4/8/10:30, crown and bow at the top. Numerals are legible at this distance. Moon on the left, void on the right, the disc's near half crossing the core. A dark dais pool with white arms inside a silver rim. Nothing ghostly. |
| P2 front night | S03 | Inlays, lume, photon ring and galaxy arms glow. The moon shows a lit limb. The corona rings the bezel. Particles are visible. |
| P3 owner | S01 at t = 10 | The dial face is seen over the wearer's shoulders, hands at XII above the head, and the world visible through the skeleton gaps. The orbs sit near the screen edges. Nothing blocks the character. |
| P4 side | camera O + 30·W.Right + (0, 6, 0) | The clock faces the camera beyond the wearer. The armillary rings cross in front of the torso. The disc does not touch the clock. Depth layering is obvious. |
| P5 high 3/4 | O + 25·f + (0, 25, 0) | The dais bowl, the floating arm layers' parallax, the balance wheel under the feet, the 56-stud engraved stage round it. |
| P6 clock close-up | O + 22·f + 10·r + (0, 12, 0) → clock centre | The bezel band thickness, flutes, chapter ring step, gears at 3 depths, hands above the dial. |
| P7 void close-up | 14 studs from voidC | The photon ring hugs the silhouette with a gap, then the lensed arc over the top, the heart, the horizon glow and spiral matter. |
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
7. Flow directions: streams flow into the palms, the void's lensed bands flow round it, accretion streaks and galaxy arms trail their spin. Fix signs
   via `dir` / TextureSpeed if not.
8. Particle shape semantics (§19): VoidSwirl and Funnel spiral **inward**, the palm intake converges, the time dust rides just outside the bezel.
9. Film-mesh flags: set the module attributes `USE_FILM_MESHES` plus each `FILM_*` one at a time, and screenshot each. Keep only the
   ones that look better. Try `FILM_HAND_FLIP` if the hand points inward.
10. Performance: MicroProfiler / Stats with 1 and 3 wearers on screen. Frame time increase < 1.5 ms for 1 wearer on the Mac.
11. Update `docs/memory/aura-rng.md` and CHANGELOG, and show Milo thumbnails.

---------------------------------------------------------------------------------------------------------------------------------

## 19. Risks and Studio-verify items

| Risk | Mitigation |
|---|---|
| **Owner's view is busier**: the clock is 20 studs from a default-zoom camera, 69° tall, with orbs at the screen edges | A skeleton dial (about 40 % open) and thin bands. The camera never sees the clock from behind and nothing sits between the camera and the wearer. Tunables: `CLOCK_DIST`, `CLOCK_HEIGHT`. |
| Highlight looks wrong (too flat or grey) or costs too much on phones | A single Highlight on the Silver model only. Fallback: `HIGHLIGHT = false` and silver turns cyan by day (still monochrome-ish). Review round 2 made the silvers neutral (B − R −3) and the fill a touch warm (216, 212, 208). |
| ParticleEmitter shape semantics differ (Disc ShapePartial as inner radius; Cylinder/Disc orientation from EmissionDirection; Inward) | Every inward system has a documented fallback (§9 notes). Studio checklist item 8. |
| Roblox wedge orientation assumed (right angle at (−Y, +Z)) | The harness mock and renderer implement this convention. Studio check on the heart spikes. If wrong, swap the halves' `±90°`. |
| Transparent sorting between stacked galaxy GUI planes | They are concentric, so the per-object sort is right for any camera above +0.33 studs. The opaque base disc writes depth under them. |
| The billboard-cut lesson | Only one BillboardGui (the moon halo), checked ≥ 0.4 from every GUI plane (the halo fades out with `cz` as the camera closes in). The moon face is an opaque disc; all void details are geometry or particles. |
| The moon face's SurfaceGui (Left face of a cylinder) is mirrored, or the UICorner does not round an image on a SurfaceGui | Studio check (studio_checks item 14): the te5 maria must read as the real moon (not mirrored); the cropped te4 fallback must show no square corners. The disc itself turns to the camera ray, so it always covers the Ø 6 core. |
| Two other players' pools share planes (same UserId parity) | The owner's pool never shares a plane with anyone's (lift 0.037 vs 0 / 0.018; review round 3 put the owner's on top); Studio check with 3 wearers. If Roblox sorts the SurfaceGuis per object and the overlap swaps as the camera orbits, the next pass hides the overlapping part of another player's floor images instead. |
| Every Studio-only unknown needs a code edit | Review round 1 turned each into one attribute flip (`FLOW_SIGN`, `ACC_DIR`, `FUNNEL_DIR`, `GALAXY_DIR`, `WEDGE_SWAP`, `STREAK_FLIP`, `FRONT_FACES`, `SWIRL_POINTS`), see `roblox/install/studio_checks.md`. |
| Viewer anchoring means each client sees a different layout | Intended. Screenshots differ per viewer. `VIEWER_ANCHOR = false` restores body anchoring. |
| 360 parts × several wearers on low-end PCs | Low quality has 150 parts, and far LOD moves 309 / 150. THE END is 1 in a billion (rarely more than 1–2 per server). Measure in Studio. |
| Film meshes: unknown pivots and orientations | Normalisation by bounding box plus `FILM_HAND_FLIP`, all default OFF, with a per-element procedural fallback. |
| Uneven ground: the flat dais clips steps and slopes | Review round 3 (R3S-2): the dais tilts to a clean slope (three rays, a plane through the ground under the wearer, ≤ 20°); stairs, cliff edges and bumpy terrain keep it level and may still clip a little. The 56-stud stage follows the same plane, so on a curved hill its edge can still dip into the ground. Studio check on a hill, a beach and stairs. |
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
- (Review round 1) The te5 moon face covering its core at the screen edges; Cylinder emitters including their caps (`SWIRL_POINTS`);
  the inlay / corona faces (`FRONT_FACES`); the stream / accretion / vortex / galaxy directions (the four sign flags); the remote
  ghost (LocalTransparencyModifier on another player's anchored parts, GUIs off); the speed trail on runs and flights only; the
  Neon colours of the lume under Bloom; the reveal after the Auto roll's hide; MicroProfiler cost of 360 parts; a seated wearer's
  hover (the framework's pose on a Seat); te5 texture preload and the fallback swap.
- (Review round 3) A Highlight on parts with `LocalTransparencyModifier` (the fading rings now leave it, which should be enough
  whatever Roblox does); the owner's frame fit (smooth, never a jump); the rings waiting for the hands at the default zoom; the
  dais on a slope; the void's lensed bands (not cut by the accretion plane); particle sorting against the floor and disc GUIs
  (the emitters' carriers now sit above those planes); hairlines without anti-aliasing; texture memory per build on a phone; the
  silver tint at the default zoom; the ink smoke by day; the pass-2 rim radius (`RIM_R`); a reset with THE END on (no grade);
  two real wearers (the other's clock steps back behind yours); the owner's pool on top where two pools overlap.
