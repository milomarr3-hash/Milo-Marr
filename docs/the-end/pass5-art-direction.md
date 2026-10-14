# THE END — pass 5 art direction (recovered)

Recovered on 2026-10-14 from the cloud copy of the "Roblox game creation" session. This is the first ~10 KB of the
pass-5 workflow result (the art director's report). The rest (the end of `buildFeel`, `characterIntegration`, `gaps`,
`particleIdeas`, the Studio scout and code-audit reports, and the full `spec.md`) is only on Milo's Mac:
`~/Documents/AuraRNG-overnight/aura_work/pass5/` (artdirection.md, scout.md, code_audit.md, spec.md) and the
workflow journal. If those files are ever copied into this repo, they supersede this page.

## Look

"The Last Clock". Keep pass 4's monochrome Equinox duality, but build it as a solid object instead of a drawing. A black-steel and silver pocket watch about 28 studs across stands behind the wearer like a monument. It is built from the film's own meshes in ReplicatedStorage.AuraCinema.Assets.TheEnd: a thick RingG bezel 2.4 deep, a recessed dark Dial plate with opaque white inlaid numerals, an Astrolabe rete, Hand meshes frozen at XII with Neon lume while the seconds hand sweeps smoothly, openwork Gear meshes meshing behind the rim, and a crown and bow above XII. The wearer floats inside a silver armillary of 3 gimballed rings (Ø 10/12/14, the ecliptic ring at 23.4°). A cratered white moon (Oblivion.Moon, Ø 9, lit by its own key light) and a pure-black void (Oblivion.SmoothSphere in Neon black, Ø 8) hang at his sides. The void has an opaque accretion disc Ø 22 whose near half crosses in front of the core, a photon ring, a lensed arc, a white 4-point heart and white crackle veins. The two orbs sway like a balance (±22°, 10 s) instead of orbiting through his face. Opaque streams run from the moon into one palm (silver) and from the void into the other (ink), and an Equinox-style ink ribbon spirals from the void into a galaxy dais below. The dais is Ø 30 with opaque white arms and black lanes, a raised silver RingG rim and two stacked arm layers that form a shallow bowl, with a vortex funnel up to a balance wheel under the feet. Purposeful particles at visible sizes: matter spirals into the void, dust snows off the moon, shards break off the bezel and are pulled into the void, smoke tendrils curl off the rim (dark on the void side, silver on the moon side), and glints ride the metal. Everything is black, white and silver, solid and layered, and it moves like a mechanism: constant meshed rotations, overshoot locks, no brightness pulses or flicker. Pass 2 read better from a distance because it was bold and opaque. Pass 5 needs pass 2's boldness with pass 4's realism, achieved through geometry. Full notes: /Users/milomarr/Documents/AuraRNG-overnight/aura_work/pass5/artdirection.md

## Depth plan

Frame: O = HRP.Position + hover (the module's 'body'); W = CFrame.new(O)*rotY; +X is the wearer's right, +Y up, +Z behind. Head is about +2.0, idle hands about (±2.3,-0.3,-0.5), feet -3.0, ground about -5.4 while floating.

KEY DECISION: the clock is viewer-anchored and everything else is body-anchored. Each client places the clock on the far side of the wearer from its own camera: yaw = the horizontal direction camera→wearer through a critically damped spring of about 0.7 s, with a fixed 8° back-tilt. The owner's normal camera is BEHIND the wearer, and pass 4 had the clock between that camera and the character, seen from its 0.7-transparent back. With this change the owner sees the dial's face and is never blocked. The spring lag reveals the bezel's thickness and the gears when the camera swings. Fallback if body-anchored: owner-only LocalTransparencyModifier 0.5 when the camera→head ray crosses the clock.

Clock: centre at O+(0,8.5,0) plus 7 studs beyond the wearer, bezel Ø 28 (y -5.5 to +22.5, sitting about 0.5 above the dais), bow top about +28.5.

Layers:
- L0 (clock +4..+6): smoke bank and a sparse star-field disc behind the clock; corona ring at night only.
- L1 (+1.4..+2.8): 7 openwork gears Ø 4-9, 30-50% visible past the rim at 1-2, 4, 8 and 10-11 o'clock, plus the case-back ring at +1.8.
- L2 (0..+1.2): bezel 2.4 deep, dial plate recessed +0.6, inlay SurfaceGui at -0.05.
- L3 (-0.5..-2.7): rete at -0.7, sub-ring at -1.0, hands at -1.4/-1.8/-2.2, hub caps at -2.4/-2.7, two skeleton gears on the dial face at IV and VIII.
- L4 (body Z +3..+7): far half of the armillary, the far orb in side views, the void→ground ink ribbon.
- L5 (Z ±1..±4): the wearer, with 10 time shards orbiting at r 3.4-4.2 on a 20° plane (half in front at any time).
- L6 (Z -2..-7): near armillary bands crossing in front of the torso; orbs at W(±11,+4.5,-1.5); the accretion disc tilted 15° from edge-on toward the viewer; palm streams.
- L7 (Z -8..-14): big slow bokeh and occasional glints between camera and wearer, plus ankle-height mist.
- Ground (+0..+1.2): raised silver rim Ø 31, galaxy Ø 30 with arm layers Ø 22 at +0.5 and Ø 13 at +1.0 (a shallow bowl), engraved ring Ø 40 (down from 58), funnel to a balance wheel at y -3.3.

Footprint: about 36 studs wide and about 34 tall. Orb edges (about ±16) overlap the bezel (R 14) in front of it, so occlusion is real. Depth comes from opaque geometry, which writes depth and occludes correctly, instead of stacked transparent planes that sort per object and pop. The white wedge cut into the moon in after4/zoom_moon.png is that sorting artifact.

## Opacity plan

Structural parts are opaque (transparency 0): bezel, case ring, dial, gears, hands, rete, hub, crown, bow, armillary rings and pins, time shards, moon, void core, debris rocks, dais rim and balance wheel.

Luminous details are opaque images (ImageTransparency 0-0.1): inlaid numerals and minute track, hand lume, photon ring, lensed arc, white heart, crackle veins. They glow through Brightness above the place's Bloom threshold of 2 (Bloom Intensity 1, Size 24), not through alpha: inlays 1.6 by day → 2.6 at night.

Discs (galaxy and accretion) are opaque in the body, with white arms AND black lanes at alpha 1, fading only over the outer 12-15% and the inner hole edge. Stream cores 0.05-0.15. Small particles peak at 0-0.15. Smoke peaks at 0.3 (dark) and 0.45 (silver). Bokeh 0.6, mist 0.8 (one emitter only).

BANNED: any element more than 6 studs across with uniform transparency between 0.3 and 0.8. Delete these pass-4 layers: Shards plane 48 (0.62), corona sprite 32 (0.6), moon glow 24 (0.72), body glow 15 (0.8), the broad 8-wide ribbon band (0.75), ground Swirl 36 (0.68), air mist haze (0.86), the 58-stud ground ring, RingA/RingB image rings (0.55/0.7), and every "faint back face" spec (0.7/0.75). Allowed soft elements: at most 3 rim-only halos (moon halo 0.45 at night / 0.65 by day, night-only bezel corona, heart), bokeh, smoke, one mist.

Day vs night:
- Sky tint: the scout captures (pass5/scout/04, 07, 09) show Metal, Foil, Glass and SmoothPlastic turning CYAN by day from the tropical sky, which breaks the monochrome lock. Scout 10 shows a Highlight neutralises it. Use one Highlight per wearer's aura Model: FillColor (205,208,215), FillTransparency 0.55 by day → 0.8 at night, OutlineColor (10,10,14), OutlineTransparency 0.35 by day → 0.7 at night, DepthMode Occluded. That gives neutral silver plus an ink contour (ref 3's inked metal), readable on a bright sky. The cap is 31 Highlights and the film stage disables them, both fine. Fallback: warm-compensated metal colours.
- nightFactor from Lighting.ClockTime (smoothstep 17.5→19 and 6.5→5), written once per second only when it changes. It drives GUI Brightness, white emitters' LightEmission (0.25 by day → 0.8 at night), the two PointLights (0 → 1.5) and the Highlight values.
- Day reads by value structure: dark dial, black void, black lanes and dark smoke against the white moon, white inlays and silver rims. Nothing relies on additive white.
- Night: inlays and disc bloom softly, the moon is lit by its key light (which also rims the wearer), and the corona appears.
- No brightness steps or pulses ever. Transparency changes only on equip, unequip and the LOD distance fade.

## Build feel (cut off mid-way)

The clock is a real pocket watch built from the film's meshes (the film's clock is at scripts/AuraCinema_TheEnd.lua lines 853-940; Milo loved that film). Final studs, clock frame, -Z toward the viewer:
- Bezel: RingG Ø 28 × 2.4 deep, Metal SILVER (176,180,190), Reflectance 0.08.
- Case-back ring: RingG Ø 27 × 1.2 at +1.8, gunmetal (60,62,68), so the side view shows a case band.
- Dial plate: Dial mesh Ø 24 × 1.2, recessed +0.6 behind the bezel lip, dark steel (48,50,56).
- Inlay layer: an invisible Part 0.0 … (cut off here)
