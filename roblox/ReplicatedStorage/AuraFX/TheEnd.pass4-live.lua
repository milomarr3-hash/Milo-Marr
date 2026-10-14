--[[
	AuraFX.TheEnd — 『 THE END 』 worn (1 in 1,000,000,000). Midnight of the universe, worn: black, white and silver only.
	Pass 2 (2026-10-13), Milo: "scale it up so much bigger", "the light flashes are annoying": a colossal look built from
	steady light — glowing HDR layers (SurfaceGui / BillboardGui Brightness) and soft additive particles over dark smoke —
	with NO pulses, strobes or flicker: everything turns, drifts or rises slowly and evenly.
	  the sigil    a radiant clock ~28 studs across towering behind and above the wearer: a crown of light spikes, bold
	               glowing numerals, the hands frozen at twelve, over a disc of black smoke with a soft corona of light
	               round it; light shards radiating out and turning slowly; sparkle dust over its rim; black smoke curling
	               off its edge. Fainter from behind (no smoke disc or hands across the wearer).
	  the rings    two engraved clock rings (18 and 23 studs) circling the wearer, tilted, turning against each other.
	  the pair     the last star (a white sun ~1.4 studs with a steady four-point flare, a long lens streak, a halo, a sparkle
	               trail and a light of its own) and the black hole (a 3-stud black ball in a dark halo and swirling black
	               smoke, a ring of light at its edge, a white star glint on it) orbit each other ~9 studs out, trailing light.
	  the ground   a galaxy ~44 studs across turning under the wearer (arms of light, lanes of dark smoke), a swirl of light over
	               it turning the other way, an engraved clock ring ~52 studs round it all, ornate rings of light round the
	               feet, black smoke and mist curling with the spin, light motes and black ash rising, and a soft column of
	               light from the galaxy up to the floating feet (a turning ring of light under them).
	  the body     a soft white glow round the wearer, two streams of light spiralling up, fine sparks; floats ~2.4 studs up
	               with a slow bob (AuraFX.pose, applied after the Animator), leaning into a glide when moving.
	Quality: phones / low graphics draw fewer particles (rates x0.4, no trails/light/mist/extra streams, smaller canvases);
	past 110 studs the particles stop (the layers stay); nothing past 320 (AuraFX).
	Pass 3 (2026-10-13), Milo's brief ("a cinematic, cosmic phenomenon", KEEP THE CLOCK): the pair became two opposite
	energies (a cloudy silver moon; a black void with a brilliant white core and fragments of light at its edge) joined by
	curved ribbons of light circling the wearer (hair-thin lines, travelling light, one broad translucent band), and three
	scales of fine detail drift round everything (silver dust, small four-point glints, a few big slow stars).
	Pass 4 (2026-10-13), Milo: "ultra realistic, just like equinox ... go all out": photographic orbs (a cloudy white moon and a
	fractured black void, camera-facing spheres), the clock rebuilt as fine-line dials stacked in depth (parallax, each turning at
	its own pace, slender hands frozen at twelve), five true 3D orbit rings of beams (two engraved with ticks), even line ribbons,
	a photographic galaxy underfoot; and an assembly on equip: the void, then the moon, the orbits folding into place, the clock
	spinning up, one soft pulse, the ground last; the wearer's own screen dims and cools for a few seconds.
	Textures: aura_work/tex4/make_theend_tex4.py (ids in aura_work/tex4/uploaded.md); aura_work/tex3/make_theend_tex3.py (ids in aura_work/tex3/uploaded.md) + the AuraCinema kit / _VFXLib (VFX Studio).
]]

local TEX = {
	-- pass 2 (aura_work/tex3)
	sigil = "rbxassetid://75027519125121", hands = "rbxassetid://93759864716353", shards = "rbxassetid://113607571698621",
	flare = "rbxassetid://93291601851916", streak = "rbxassetid://115797014411278", galaxy = "rbxassetid://125411838674546",
	gring = "rbxassetid://82989578201256", void = "rbxassetid://81195317493584",
	softGlow = "rbxassetid://90101855061498", rim = "rbxassetid://121599880739521",
	-- pass 1 (aura_work/tex)
	spark = "rbxassetid://109765380822041", ash = "rbxassetid://91995992047091",
	-- AuraCinema kit + _VFXLib (VFX Studio / Euphoric RNG auras)
	glow = "rbxassetid://88172507927269", glint = "rbxassetid://16956515291", sparkles = "rbxassetid://115317702570755", -- (4x4)
	puff = "rbxassetid://17062535921", mist = "rbxassetid://13826565206", -- (4x4 each)
	swirl = "rbxassetid://17086022111", ornate = "rbxassetid://14591895021",
	swirlRing = "rbxassetid://17087733793", pillar = "rbxassetid://3029306948",
	-- pass 4 (aura_work/tex4)
	moon = "rbxassetid://105160126126488", voidOrb = "rbxassetid://98346126355034", line = "rbxassetid://111152711897982",
	tick = "rbxassetid://99880756430819", dialOuter = "rbxassetid://138970147678654", dialMid = "rbxassetid://79447855638088",
	dialInner = "rbxassetid://134434932210706", hands4 = "rbxassetid://120547039021938", galaxy4 = "rbxassetid://91068008644782",
}
local WHITE = Color3.fromRGB(248, 249, 255)
local SILVER = Color3.fromRGB(222, 228, 240)
local INK = Color3.fromRGB(5, 5, 8)
local SMOKE = Color3.fromRGB(14, 14, 19)

local End = {}

End.pose = {
	hover = 2.4, bob = 0.28, bobSpeed = 1.4,
	-- degrees in the parent part's axes (X right, Y up, Z back): +X on a hip/shoulder swings the limb forward,
	-- -X on a knee bends it back, -Z on the left shoulder lifts that arm out (+Z the right one)
	idle = {
		Root = { 2, 0, 0 }, Waist = { 2, 0, 0 }, Neck = { -8, 0, 0 },
		LeftShoulder = { 6, 0, -24 }, RightShoulder = { 6, 0, 24 }, LeftElbow = { 16, 0, 0 }, RightElbow = { 16, 0, 0 },
		LeftHip = { 10, 0, -3 }, RightHip = { -5, 0, 3 }, LeftKnee = { -16, 0, 0 }, RightKnee = { -40, 0, 0 },
		LeftAnkle = { -26, 0, 0 }, RightAnkle = { -32, 0, 0 },
	},
	glide = {
		Root = { -18, 0, 0 }, Waist = { -5, 0, 0 }, Neck = { 14, 0, 0 },
		LeftShoulder = { -30, 0, -26 }, RightShoulder = { -30, 0, 26 }, LeftElbow = { 10, 0, 0 }, RightElbow = { 10, 0, 0 },
		LeftHip = { -14, 0, -2 }, RightHip = { -22, 0, 2 }, LeftKnee = { -26, 0, 0 }, RightKnee = { -48, 0, 0 },
		LeftAnkle = { -34, 0, 0 }, RightAnkle = { -34, 0, 0 },
	},
	breathe = { LeftShoulder = { 0, 0, -5 }, RightShoulder = { 0, 0, 5 }, LeftElbow = { 4, 0, 0 }, RightElbow = { 4, 0, 0 }, Waist = { 1.5, 0, 0 } },
	suppress = {
		Root = 0.6, Waist = 0.6, Neck = 0.2, LeftShoulder = 0.7, RightShoulder = 0.7, LeftElbow = 0.6, RightElbow = 0.6,
		LeftHip = 0.93, RightHip = 0.93, LeftKnee = 0.93, RightKnee = 0.93, LeftAnkle = 0.9, RightAnkle = 0.9,
	},
}

local rad, sin, cos, exp = math.rad, math.sin, math.cos, math.exp
local G4 = Enum.ParticleFlipbookLayout.Grid4x4
local ONESHOT, LOOP = Enum.ParticleFlipbookMode.OneShot, Enum.ParticleFlipbookMode.Loop
local DISC, VOLUME = Enum.ParticleEmitterShape.Disc, Enum.ParticleEmitterShapeStyle.Volume
local TOP = Enum.NormalId.Top

-- the wearer's own screen dims and cools for a few seconds when they put it on (not when spawning or joining)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local spawnedAt = setmetatable({}, { __mode = "k" })
if Players.LocalPlayer then
	local function mark(c) spawnedAt[c] = os.clock() end
	if Players.LocalPlayer.Character and time() < 20 then mark(Players.LocalPlayer.Character) end -- (just joined: not an equip)
	Players.LocalPlayer.CharacterAdded:Connect(mark)
end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function seq(points)
	local kp = {}
	for _, p in ipairs(points) do table.insert(kp, NumberSequenceKeypoint.new(p[1], p[2], p[3] or 0)) end
	return NumberSequence.new(kp)
end
local function n(a, b) return NumberRange.new(a, b or a) end
-- soft in, hold, soft out: with Rate x Lifetime = 3 the overlapping copies always add up to the same light (no breathing)
local function even(tr) return seq({ { 0, 1 }, { 1 / 3, tr }, { 2 / 3, tr }, { 1, 1 } }) end

function End.build(ctx)
	local low = ctx.quality == "low"
	local folder = new("Folder", { Name = "TheEnd_" .. ctx.char.Name })
	local fadesClock, fadesMoon, fadesVoid, fadesBody = {}, {}, {}, {}
	local fades, groundFades = fadesClock, {} -- (fades = the group being built: the parts of the aura assemble in turn)
	local emitters, beams, trails = {}, {}, {}

	local function part(name, size, shape)
		return new("Part", { Name = name, Size = size, Shape = shape or Enum.PartType.Block, Transparency = 1, Anchored = true,
			CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Massless = true, Locked = true }, folder)
	end
	-- a flat glowing layer: a square part with an image on its front and/or back face (or its top, flat on the ground).
	-- spec = { transparency, brightness }; the parts turn, the GUIs are never written per frame (only while fading in)
	local function layer(name, size, tex, color, front, back, canvas, list, top)
		local p = part(name, top and Vector3.new(size, 0.05, size) or Vector3.new(size, size, 0.05))
		local faces = top and { [TOP] = front } or { [Enum.NormalId.Front] = front, [Enum.NormalId.Back] = back }
		for face, spec in pairs(faces) do
			if spec then
				local g = new("SurfaceGui", { Face = face, LightInfluence = 0, Brightness = spec[2], SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
					CanvasSize = Vector2.new(canvas, canvas) }, p)
				local im = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = tex, ImageColor3 = color,
					ImageTransparency = 1 }, g)
				table.insert(list or fades, { im, spec[1] })
			end
		end
		return p
	end
	-- a steady sprite that always faces the camera (no particles: nothing flickers). back = studs pushed away from the camera
	local function sprite(host, w, h, tex, color, tr, bright, back, offset)
		local g = new("BillboardGui", { Size = UDim2.new(w, 0, h, 0), LightInfluence = 0, Brightness = bright, MaxDistance = 400,
			StudsOffset = Vector3.new(0, 0, -(back or 0)), StudsOffsetWorldSpace = offset or Vector3.zero }, host)
		local im = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = tex, ImageColor3 = color,
			ImageTransparency = 1 }, g)
		table.insert(fades, { im, tr })
		return g
	end
	-- particles: soft additive light by default. flags: ground = off when high in the air, high = only on high quality,
	-- lowRate = rate multiplier on low quality. (All particles stop past 110 studs.)
	local function pe(parent, props, flags)
		flags = flags or {}
		if low and flags.high then return nil end
		local p = Instance.new("ParticleEmitter")
		p.LightInfluence = 0
		p.LightEmission = 1
		p.Color = ColorSequence.new(WHITE)
		p.Speed = n(0)
		p.Rate = 0
		local sz = props.Size
		if typeof(sz) == "NumberRange" then -- (a size range: a steady size with a random spread)
			local v, e = (sz.Min + sz.Max) / 2, (sz.Max - sz.Min) / 2
			props.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, v, e), NumberSequenceKeypoint.new(1, v, e) })
		end
		for k, v in pairs(props) do p[k] = v end
		if low then p.Rate *= (flags.lowRate or 0.4) end
		p.Parent = parent
		table.insert(emitters, { p, flags.ground == true, fades })
		return p
	end
	local function att(parent, pos) return new("Attachment", { Position = pos or Vector3.zero }, parent) end
	local hi, mid = low and 512 or 1024, low and 256 or 512

	---------------------------------------------------------------- THE CLOCK (pass 4): a celestial mechanism in layers, towering behind
	-- fine-line dials stacked in depth (each turning at its own pace, so the clock has real parallax), slender hands frozen at
	-- twelve in front, a disc of black smoke behind with a soft corona, faint light shards, sparkle dust over the rim
	local shards = layer("Shards", 48, TEX.shards, WHITE, { 0.62, 1.3 }, { 0.9, 1.1 }, hi)
	local void = layer("Void", 25, TEX.void, INK, { 0.0, 1 }, nil, mid)
	local sigil = layer("DialOuter", 30, TEX.dialOuter, WHITE, { 0.0, 3.4 }, { 0.7, 1.5 }, hi)
	local hands = layer("Hands", 30, TEX.hands4, WHITE, { 0.0, 3.4 }, nil, hi)
	local dialMid = layer("DialMid", 30, TEX.dialMid, WHITE, { 0.0, 3 }, { 0.75, 1.4 }, hi)
	local dialIn = layer("DialInner", 30, TEX.dialInner, WHITE, { 0.0, 3 }, { 0.75, 1.4 }, hi)
	sprite(shards, 32, 32, TEX.softGlow, WHITE, 0.6, 1.3, 6) -- the corona: light behind the black disc, showing round its edge
	-- sparkle dust over the rim (slow: each sparkle takes ~3 s to bloom and fade)
	pe(sigil, { Texture = TEX.sparkles, FlipbookLayout = G4, FlipbookMode = ONESHOT, Rate = 22, Lifetime = n(2.6, 3.6),
		Size = n(0.6, 1.4), Transparency = seq({ { 0, 1 }, { 0.3, 0.1 }, { 0.7, 0.1 }, { 1, 1 } }), Brightness = 2.4, Speed = n(0.1, 0.4),
		EmissionDirection = Enum.NormalId.Front, Shape = DISC, ShapeStyle = VOLUME, ShapePartial = 0.4, LockedToPart = true,
		Rotation = n(0, 360) })
	-- black smoke curling off the edge of the clock
	pe(void, { Texture = TEX.puff, FlipbookLayout = G4, FlipbookMode = ONESHOT, Rate = 12, Lifetime = n(3.2, 4.4),
		Size = seq({ { 0, 5 }, { 1, 11 } }), Transparency = seq({ { 0, 1 }, { 0.25, 0.4 }, { 0.7, 0.58 }, { 1, 1 } }),
		Color = ColorSequence.new(SMOKE), LightEmission = 0, Speed = n(0.3, 0.8), Acceleration = Vector3.new(0, 0.3, 0),
		EmissionDirection = Enum.NormalId.Back, Shape = DISC, ShapeStyle = VOLUME, ShapePartial = 0.6, Rotation = n(0, 360),
		RotSpeed = n(-20, 20) }, { lowRate = 0.35 })

	-- two engraved clock rings circling the wearer, tilted, turning against each other
	local ringA = layer("RingA", 18, TEX.gring, SILVER, { 0.55, 1.6 }, { 0.55, 1.6 }, hi)
	local ringB = layer("RingB", 23, TEX.gring, SILVER, { 0.7, 1.4 }, { 0.7, 1.4 }, hi)

	---------------------------------------------------------------- THE PAIR (pass 4): the moon and the void, two opposite energies
	-- the moon: a pearl of white light (a photographic cloudy sphere with fine grey veins, a bright limb and a thin halo ring,
	-- always facing the camera so it reads as a true sphere from every angle), a hazy glow, silver mist drifting over it
	fades = fadesMoon
	local SPHERE = Enum.ParticleEmitterShape.Sphere
	local star = part("Moon", Vector3.new(6.5, 6.5, 6.5), Enum.PartType.Ball)
	sprite(star, 18, 18, TEX.void, INK, 0.5, 1, 2.4) -- a faint dark halo, so the white reads against a bright sky
	sprite(star, 24, 24, TEX.softGlow, SILVER, 0.72, 1.3, 1.6) -- the hazy glow
	sprite(star, 10.8, 10.8, TEX.moon, WHITE, 0.0, 1.25, 0)
	pe(star, { Texture = TEX.mist, FlipbookLayout = G4, FlipbookMode = LOOP, FlipbookFramerate = n(2, 4), Rate = 5, Lifetime = n(2.6, 3.4),
		Size = n(3, 5), Transparency = seq({ { 0, 1 }, { 0.3, 0.72 }, { 0.7, 0.76 }, { 1, 1 } }), Color = ColorSequence.new(SILVER),
		LightEmission = 0.4, Shape = SPHERE, ShapeStyle = VOLUME, Rotation = n(0, 360), RotSpeed = n(-20, 20), LockedToPart = true,
		ZOffset = 0.5 }, { high = true })
	pe(att(star), { Texture = TEX.sparkles, FlipbookLayout = G4, FlipbookMode = ONESHOT, Rate = 10, Lifetime = n(1.8, 2.6),
		Size = n(0.3, 0.7), Transparency = seq({ { 0, 0.3 }, { 0.7, 0.35 }, { 1, 1 } }), Brightness = 2, Speed = n(0.3, 0.8),
		SpreadAngle = Vector2.new(180, 180), Drag = 1.2, Rotation = n(0, 360), Color = ColorSequence.new(SILVER) }, { lowRate = 0.3 })
	-- the void: a black sphere with fine white fractures and a hairline rim (a camera-facing sphere over a black ball), a halo
	-- of bent darkness and swirling smoke, a brilliant four-point star at its heart, fragments of light breaking off its edge
	fades = fadesVoid
	local hole = new("Part", { Name = "Void", Shape = Enum.PartType.Ball, Size = Vector3.new(6.5, 6.5, 6.5), Material = Enum.Material.SmoothPlastic,
		Color = INK, Reflectance = 0, Transparency = 1, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Locked = true }, folder)
	sprite(hole, 19, 19, TEX.void, INK, 0.25, 1, 3.6) -- a halo of darkness bending round it
	sprite(hole, 12.5, 12.5, TEX.voidOrb, WHITE, 0.0, 1.8, -3.4)
	sprite(hole, 3.2, 3.2, TEX.softGlow, WHITE, 0.2, 2.2, -3.8) -- the white core
	sprite(hole, 7, 7, TEX.flare, WHITE, 0.0, 2.6, -3.9)
	local ha = att(hole)
	pe(ha, { Texture = TEX.swirlRing, Rate = 1, Lifetime = n(3), Size = n(13), Rotation = n(0, 360), RotSpeed = n(70, 90),
		Transparency = even(0.4), Brightness = 2, LockedToPart = true })
	pe(ha, { Texture = TEX.puff, FlipbookLayout = G4, FlipbookMode = ONESHOT, Rate = 14, Lifetime = n(1.8, 2.6),
		Size = seq({ { 0, 4 }, { 1, 9 } }), Transparency = seq({ { 0, 1 }, { 0.25, 0.32 }, { 1, 1 } }), Color = ColorSequence.new(SMOKE),
		LightEmission = 0, Speed = n(0.5, 1.2), SpreadAngle = Vector2.new(180, 180), Drag = 1, Rotation = n(0, 360),
		RotSpeed = n(-60, 60) }, { lowRate = 0.35 })
	pe(hole, { Texture = TEX.spark, Rate = 22, Lifetime = n(1.2, 2), Size = seq({ { 0, 0.3, 0.1 }, { 1, 0 } }),
		Transparency = seq({ { 0, 1 }, { 0.15, 0 }, { 1, 0.6 } }), Brightness = 3, Speed = n(0.4, 1.2), Drag = 0.8, Shape = SPHERE,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, Rotation = n(0, 360), ZOffset = 0.5 }, { lowRate = 0.4 })
	local light
	if not low then
		light = new("PointLight", { Color = Color3.fromRGB(225, 232, 248), Range = 28, Brightness = 1.2, Shadows = false }, star)
		-- (pass 4: no trails on the orbs — at these sizes they draw as flat polygons)
	end
	-- the ribbons: curved paths of light between the two, circling the wearer (as the pair turns they sweep in front and behind):
	-- hair-thin lines, light travelling along two of them, and one broad translucent band round everything
	local ribbons = {}
	local function rseq(x) local e = 1 - (1 - x) * 0.25 return seq({ { 0, e }, { 0.2, x }, { 0.8, x }, { 1, e } }) end
	local function ribbon(tilt, curve, w, tex, wrap, speed, tr, bright)
		local s, c = sin(rad(tilt)), cos(rad(tilt))
		local a0 = new("Attachment", { CFrame = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, s, c), Vector3.new(0, c, -s)) }, star)
		local a1 = new("Attachment", { CFrame = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, -s, -c), Vector3.new(0, c, -s)) }, hole)
		local b = new("Beam", { Attachment0 = a0, Attachment1 = a1, CurveSize0 = curve, CurveSize1 = curve, Texture = tex,
			TextureMode = wrap and Enum.TextureMode.Wrap or Enum.TextureMode.Stretch, TextureLength = wrap or 1, TextureSpeed = speed,
			Width0 = w, Width1 = w, FaceCamera = true, LightEmission = (tex == TEX.line) and 0 or 1, LightInfluence = 0, Brightness = bright, Segments = 24,
			Color = ColorSequence.new(WHITE), Transparency = rseq(1) }, star)
		table.insert(ribbons, { b, tr })
	end
	ribbon(0, 17.3, 0.3, TEX.line, nil, 0, 0.05, 2.4)
	ribbon(0, -17.3, 0.3, TEX.line, nil, 0, 0.05, 2.4)
	ribbon(0, 17.3, 1.2, TEX.streak, 9, 0.45, 0.1, 2.6)
	if not low then
		ribbon(0, -17.3, 1.1, TEX.streak, 7, -0.35, 0.15, 2.4)
		ribbon(32, 20, 0.16, TEX.line, nil, 0, 0.2, 2)
		ribbon(-26, -14, 0.16, TEX.line, nil, 0, 0.25, 2)
		ribbon(18, -22, 0.12, TEX.line, nil, 0, 0.3, 1.8)
		ribbon(-12, 24, 0.12, TEX.line, nil, 0, 0.35, 1.8)
	end
	ribbon(8, 25, 8, TEX.softGlow, nil, 0, 0.75, 1.3) -- the broad band

	---------------------------------------------------------------- THE ORBITS (pass 4): fine 3D rings of light round the wearer
	-- each ring is four beam arcs making a true circle in depth (crisp from every angle; edge-on it thins to a line); two are
	-- engraved with ticks; each has its own tilt, height and pace, and on equip they fold into place
	local orbits = {}
	local function orbitRing(R, w, tex, tile, tr, bright, tx, tz, spin, y)
		local p = part("Orbit", Vector3.new(1, 1, 1))
		local k = 0.5523 * R
		local as = {}
		for i = 0, 3 do
			local a = i * math.pi / 2
			as[i] = new("Attachment", { CFrame = CFrame.fromMatrix(Vector3.new(R * cos(a), 0, R * sin(a)), Vector3.new(-sin(a), 0, cos(a)), Vector3.yAxis) }, p)
		end
		for i = 0, 3 do
			local b = new("Beam", { Attachment0 = as[i], Attachment1 = as[(i + 1) % 4], CurveSize0 = k, CurveSize1 = k, Texture = tex,
				TextureMode = tile and Enum.TextureMode.Wrap or Enum.TextureMode.Stretch, TextureLength = tile or 1, Width0 = w, Width1 = w,
				FaceCamera = true, LightEmission = 0, LightInfluence = 0, Brightness = bright, Segments = 16, Color = ColorSequence.new(WHITE), -- (inked: readable on a bright sky)
				Transparency = NumberSequence.new(1) }, p)
			table.insert(ribbons, { b, tr, true })
		end
		table.insert(orbits, { p, tx, tz, spin, y })
	end
	orbitRing(7, 0.2, TEX.line, nil, 0.1, 2.4, 14, 6, 0.35, -0.6)
	orbitRing(8.4, 0.6, TEX.tick, 4, 0.15, 2.2, -10, -8, -0.22, 0.4)
	orbitRing(13, 0.16, TEX.line, nil, 0.2, 2.2, 72, -16, 0.12, 1.6)
	if not low then
		orbitRing(15, 0.5, TEX.tick, 5, 0.3, 2, 24, 14, -0.08, -1.2)
		orbitRing(19.5, 0.14, TEX.line, nil, 0.4, 1.8, 6, -4, 0.05, -0.2)
	end

	---------------------------------------------------------------- THE DUST (pass 3): three scales of fine detail round everything
	fades = fadesBody
	local dust = part("Dust", Vector3.new(40, 18, 40))
	pe(dust, { Texture = TEX.glow, Rate = 36, Lifetime = n(6, 9), Size = n(0.06, 0.16), Transparency = seq({ { 0, 1 }, { 0.2, 0.15 }, { 0.8, 0.2 }, { 1, 1 } }),
		Brightness = 2, Speed = n(0.1, 0.35), SpreadAngle = Vector2.new(180, 180), ShapeStyle = VOLUME, Color = ColorSequence.new(SILVER) })
	pe(dust, { Texture = TEX.glint, Rate = 7, Lifetime = n(4, 6), Size = n(0.25, 0.6), Transparency = seq({ { 0, 1 }, { 0.3, 0.15 }, { 0.7, 0.2 }, { 1, 1 } }),
		Brightness = 2.4, Speed = n(0.2, 0.5), SpreadAngle = Vector2.new(180, 180), ShapeStyle = VOLUME, Rotation = n(0, 360), RotSpeed = n(-40, 40) },
		{ lowRate = 0.5 })
	pe(dust, { Texture = TEX.flare, Rate = 0.5, Lifetime = n(5, 7), Size = n(1.6, 2.8), Transparency = seq({ { 0, 1 }, { 0.4, 0.1 }, { 0.6, 0.1 }, { 1, 1 } }),
		Brightness = 2.6, ShapeStyle = VOLUME }, { high = true })
	-- soft silver haze drifting through it all (the air round the wearer, like breath in cold light)
	pe(dust, { Texture = TEX.mist, FlipbookLayout = G4, FlipbookMode = LOOP, FlipbookFramerate = n(1, 2), Rate = 3, Lifetime = n(7, 9),
		Size = seq({ { 0, 9 }, { 1, 16 } }), Transparency = seq({ { 0, 1 }, { 0.3, 0.86 }, { 0.7, 0.88 }, { 1, 1 } }), Color = ColorSequence.new(SILVER),
		LightEmission = 0.25, Speed = n(0.2, 0.5), SpreadAngle = Vector2.new(180, 180), ShapeStyle = VOLUME, Rotation = n(0, 360),
		RotSpeed = n(-8, 8) }, { high = true })

	---------------------------------------------------------------- THE GROUND: a galaxy in a clock ring
	local ground = layer("Ground", 50, TEX.galaxy4, WHITE, { 0.0, 2.0 }, nil, hi, groundFades, true)
	local swirl = layer("Swirl", 36, TEX.swirl, WHITE, { 0.68, 1.2 }, nil, hi, groundFades, true)
	local gring = layer("GroundRing", 58, TEX.gring, SILVER, { 0.3, 1.6 }, nil, hi, groundFades, true)
	local ornate = layer("Ornate", 13, TEX.ornate, WHITE, { 0.1, 1.8 }, nil, mid, groundFades, true)
	-- black smoke and mist curling with the spin (locked to the turning disc)
	pe(ground, { Texture = TEX.puff, FlipbookLayout = G4, FlipbookMode = ONESHOT, Rate = 12, Lifetime = n(4, 5.5),
		Size = seq({ { 0, 6 }, { 1, 14 } }), Transparency = seq({ { 0, 1 }, { 0.25, 0.45 }, { 0.7, 0.6 }, { 1, 1 } }), Color = ColorSequence.new(SMOKE),
		LightEmission = 0, Speed = n(0.2, 0.6), EmissionDirection = TOP, Shape = DISC, ShapeStyle = VOLUME, ShapePartial = 0.25,
		Rotation = n(0, 360), RotSpeed = n(-15, 15), LockedToPart = true }, { ground = true, lowRate = 0.3 })
	pe(ground, { Texture = TEX.mist, FlipbookLayout = G4, FlipbookMode = LOOP, FlipbookFramerate = n(2, 3), Rate = 4, Lifetime = n(5, 7),
		Size = seq({ { 0, 10 }, { 1, 18 } }), Transparency = seq({ { 0, 1 }, { 0.3, 0.8 }, { 0.75, 0.84 }, { 1, 1 } }),
		Color = ColorSequence.new(Color3.fromRGB(205, 209, 220)), LightEmission = 0, Speed = n(0.1, 0.3), EmissionDirection = TOP,
		Shape = DISC, ShapeStyle = VOLUME, Rotation = n(0, 360), RotSpeed = n(-6, 6), LockedToPart = true }, { ground = true, high = true })
	-- light motes and black ash rising off the galaxy
	pe(ground, { Texture = TEX.spark, Rate = 40, Lifetime = n(3, 4.5), Size = seq({ { 0, 0 }, { 0.25, 0.7, 0.25 }, { 1, 0 } }),
		Transparency = seq({ { 0, 1 }, { 0.2, 0.05 }, { 0.8, 0.15 }, { 1, 1 } }), Brightness = 2.6, Speed = n(2, 4.5),
		Acceleration = Vector3.new(0, 0.4, 0), Drag = 0.25, EmissionDirection = TOP, Shape = DISC, ShapeStyle = VOLUME,
		Rotation = n(-15, 15) }, { ground = true })
	pe(ground, { Texture = TEX.ash, Rate = 14, Lifetime = n(3, 5), Size = seq({ { 0, 0.35, 0.12 }, { 1, 0.18 } }),
		Transparency = seq({ { 0, 1 }, { 0.15, 0.1 }, { 0.75, 0.3 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(16, 16, 20)),
		LightEmission = 0, Speed = n(1, 3), Acceleration = Vector3.new(0, 0.3, 0), Drag = 0.4, EmissionDirection = TOP,
		Shape = DISC, ShapeStyle = VOLUME, ShapePartial = 0.15, Rotation = n(0, 360), RotSpeed = n(-90, 90) }, { ground = true, lowRate = 0.3 })

	---------------------------------------------------------------- THE FEET: a turning ring of light under them, a column below
	local feet = layer("Feet", 7.5, TEX.ornate, WHITE, { 0.1, 2.0 }, nil, mid, nil, true)
	local fc = att(feet)
	local colBottom = att(ground, Vector3.new(0, 0.1, 0))
	local function column(tex, w0, w1, tr0, tr1, speed, bright)
		table.insert(beams, new("Beam", { Attachment0 = colBottom, Attachment1 = fc, Texture = tex, TextureMode = Enum.TextureMode.Stretch,
			TextureSpeed = speed, Width0 = w0, Width1 = w1, FaceCamera = true, LightEmission = 1, LightInfluence = 0, Brightness = bright,
			Color = ColorSequence.new(WHITE), Transparency = seq({ { 0, tr0 }, { 1, tr1 } }), Segments = 4 }, feet))
	end
	column(TEX.softGlow, 4.5, 2.4, 0.6, 0.8, 0, 1.3)
	if not low then column(TEX.pillar, 3, 1.6, 0.4, 0.7, 0.25, 1.5) end

	---------------------------------------------------------------- THE BODY: a soft glow, streams of light spiralling up, sparks
	local core = part("Core", Vector3.new(4, 5.5, 4))
	-- the pulse: once, when the aura has assembled, a soft ring of light swells out from the wearer and fades (no flash)
	local pulse = new("BillboardGui", { Size = UDim2.new(6, 0, 6, 0), LightInfluence = 0, Brightness = 2, MaxDistance = 400, Enabled = false }, core)
	local pulseIm = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = TEX.rim, ImageColor3 = WHITE,
		ImageTransparency = 1 }, pulse)
	sprite(core, 15, 15, TEX.softGlow, WHITE, 0.8, 1.2, 3)
	pe(core, { Texture = TEX.spark, Rate = 10, Lifetime = n(2, 3), Speed = n(0.6, 1.4), EmissionDirection = TOP,
		SpreadAngle = Vector2.new(20, 20), Acceleration = Vector3.new(0, 0.4, 0), Drag = 0.5, ShapeStyle = VOLUME,
		Size = seq({ { 0, 0 }, { 0.25, 0.45, 0.15 }, { 1, 0 } }), Transparency = seq({ { 0, 1 }, { 0.2, 0.05 }, { 0.8, 0.15 }, { 1, 1 } }),
		Brightness = 2.5, Rotation = n(-15, 15) })
	local spiral = part("Spiral", Vector3.new(1, 1, 1))
	for k, x in ipairs({ 3, -3 }) do
		if not (low and k == 2) then
			local a = att(spiral, Vector3.new(x, -2.8, 0))
			pe(a, { Texture = TEX.glow, Rate = 16, Lifetime = n(2.6), Speed = n(2.6), EmissionDirection = TOP,
				Size = seq({ { 0, 0.2 }, { 0.2, 0.9 }, { 1, 0 } }), Transparency = seq({ { 0, 1 }, { 0.12, 0.35 }, { 0.7, 0.3 }, { 1, 1 } }),
				Brightness = 2, LockedToPart = true }, { lowRate = 0.6 })
			pe(a, { Texture = TEX.spark, Rate = 6, Lifetime = n(2.6), Speed = n(2.6), EmissionDirection = TOP,
				Size = seq({ { 0, 0 }, { 0.3, 0.6 }, { 1, 0 } }), Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 1, 1 } }), Brightness = 2.6,
				LockedToPart = true }, { high = true })
		end
	end

	-- the wearer's own screen: dims and cools while it assembles, then eases back (only when they put it on)
	local grade
	if ctx.isLocal and os.clock() - (spawnedAt[ctx.char] or 0) > 4 then
		grade = new("ColorCorrectionEffect", { Name = "TheEndReveal" }, workspace.CurrentCamera)
		TweenService:Create(grade, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Saturation = -0.75, Brightness = -0.1, Contrast = 0.15, TintColor = Color3.fromRGB(232, 238, 255) }):Play()
		task.delay(5.8, function()
			if not (grade and grade.Parent) then return end
			local tw = TweenService:Create(grade, TweenInfo.new(2.2, Enum.EasingStyle.Sine), { Saturation = 0, Brightness = 0, Contrast = 0,
				TintColor = Color3.new(1, 1, 1) })
			tw.Completed:Connect(function() if grade then grade:Destroy() end end)
			tw:Play()
		end)
	end

	local parts = { shards, void, sigil, hands, ringA, ringB, star, hole, ground, swirl, gring, ornate, feet, core, spiral, dust, dialMid, dialIn }
	for _, o in ipairs(orbits) do table.insert(parts, o[1]) end
	local cfs = table.create(#parts)

	local fx = {}
	local yaw = nil
	local alphaW, groundW = -1, -1
	local gA = 0
	local near, groundOn = true, true
	local phase = math.random() * 6.28
	local lastGround = nil
	local age, ribW, holeW, pulseDone = 0, -1, -1, false
	local groups = { { fadesVoid, 0, 1.2 }, { fadesMoon, 0.6, 1.8 }, { fadesClock, 2.4, 4.4 }, { fadesBody, 3.6, 5 } }
	local groupW = { -1, -1, -1, -1 }
	local live = {}
	local function ease(a0, a1) local u = math.clamp((age - a0) / (a1 - a0), 0, 1) return u * u * (3 - 2 * u) end
	local function boost(a0, a1, turns) local u = math.clamp((age - a0) / (a1 - a0), 0, 1) return (1 - (1 - u) ^ 3) * turns end

	local function write(list, a)
		for _, e in ipairs(list) do e[1].ImageTransparency = 1 - (1 - e[2]) * a end
	end
	local function applyEnabled()
		for _, e in ipairs(emitters) do
			e[1].Enabled = near and (groundOn or not e[2]) and live[e[3]] == true
		end
		for _, b in ipairs(beams) do b.Enabled = groundOn and live[fadesBody] == true end
		for _, tr in ipairs(trails) do tr.Enabled = near and live[fadesMoon] == true end
		if light then light.Enabled = near and live[fadesMoon] == true end
	end

	function fx.update(dt, s)
		age += dt
		local cf = s.cf
		local look = cf.LookVector
		local target = math.atan2(-look.X, -look.Z)
		if not yaw then yaw = target end
		local diff = (target - yaw + math.pi) % (2 * math.pi) - math.pi
		yaw += diff * (1 - exp(-dt * 5))
		local rotY = CFrame.Angles(0, yaw, 0)
		local g, t, now = s.glide, s.t, s.now
		local root = cf.Position
		local body = root + Vector3.new(0, s.hover, 0)

		-- the sigil: towering behind, the wearer's head inside its ring's lower edge; further back and leaning in a glide
		local base = CFrame.new(body) * rotY * CFrame.new(0, 7.2 - 2 * g, 3.6 + 2.5 * g) * CFrame.Angles(rad(4 + 14 * g), 0, 0)
		cfs[1] = base * CFrame.new(0, 0, 1.6) * CFrame.Angles(0, 0, rad((now * 3) % 360))
		cfs[2] = base * CFrame.new(0, 0, 1.4) * CFrame.Angles(0, 0, -rad((now * 2) % 360))
		cfs[3] = base * CFrame.new(0, 0, 0.5)
		cfs[4] = base * CFrame.new(0, 0, -1.3)

		-- the rings: round the wearer, tilted a little, turning slowly against each other, the tilt wandering
		local mid0 = CFrame.new(body) * rotY
		cfs[5] = mid0 * CFrame.new(0, -0.6, 0) * CFrame.Angles(rad(90 + 16 * sin(t * 0.21)), 0, rad(10 * cos(t * 0.17))) * CFrame.Angles(0, 0, (t * 0.25) % 6.2832)
		cfs[6] = mid0 * CFrame.new(0, 0.9, 0) * CFrame.Angles(rad(90 - 12 * sin(t * 0.15 + 1)), 0, rad(-14 * cos(t * 0.13))) * CFrame.Angles(0, 0, -(t * 0.18) % 6.2832)

		-- the pair: opposite each other on a wide tilted orbit round the wearer
		local th = t * 0.5 + phase
		local r = 13 - 2 * g
		local orbit = CFrame.new(body + Vector3.new(0, 2.6, 0)) * rotY * CFrame.Angles(rad(14), 0, rad(-9))
		local bob = 0.5 * sin(t * 1.3)
		cfs[7] = orbit * CFrame.new(cos(th) * r, bob, sin(th) * r) * CFrame.Angles(0, -th, 0)
		cfs[8] = orbit * CFrame.new(-cos(th) * r, -bob, -sin(th) * r) * CFrame.Angles(0, -th, 0)

		-- the ground under the wearer (fades out high in the air)
		local feetY = root.Y - s.legLen
		local gTarget = 0
		if s.ground then
			lastGround = s.ground
			gTarget = 1 - math.clamp((feetY - s.ground.Y - 0.6) / 7, 0, 1)
		end
		gA += (gTarget - gA) * (1 - exp(-dt * 4))
		local gy = (lastGround or Vector3.new(root.X, feetY, root.Z)).Y
		cfs[9] = CFrame.new(root.X, gy + 0.05, root.Z) * CFrame.Angles(0, -rad((now * 7) % 360), 0)
		cfs[10] = CFrame.new(root.X, gy + 0.08, root.Z) * CFrame.Angles(0, rad((now * 12) % 360), 0)
		cfs[11] = CFrame.new(root.X, gy + 0.11, root.Z) * CFrame.Angles(0, rad((now * 2.5) % 360), 0)
		cfs[12] = CFrame.new(root.X, gy + 0.14, root.Z) * CFrame.Angles(0, -rad((now * 9) % 360), 0)
		cfs[13] = CFrame.new(root.X, feetY + s.hover - 0.15, root.Z) * CFrame.Angles(0, rad((now * 16) % 360), 0)
		cfs[14] = CFrame.new(body)
		cfs[15] = CFrame.new(body) * CFrame.Angles(0, (t * 1.6) % 6.2832, 0)
		cfs[16] = CFrame.new(body)
		-- the dials behind and in front of the face turn against each other (spinning up once as the clock assembles)
		local spinIn = boost(2.4, 5, 6.2832)
		cfs[17] = base * CFrame.new(0, 0, 1) * CFrame.Angles(0, 0, -rad((now * 4) % 360) - spinIn)
		cfs[18] = base * CFrame.new(0, 0, -0.7) * CFrame.Angles(0, 0, rad((now * 7) % 360) + spinIn * 1.5)
		-- the orbits: each at its own tilt and pace, the tilt wandering a little; on equip they fold down into place
		local fold = 1 - ease(1.0, 3.4)
		local whirl = boost(1.0, 3.4, 9)
		for i, o in ipairs(orbits) do
			local sgn = (i % 2 == 0) and -1 or 1
			cfs[18 + i] = CFrame.new(body + Vector3.new(0, o[5], 0)) * rotY
				* CFrame.Angles(rad(o[2] + 5 * sin(t * 0.2 + i) + 80 * fold * sgn), 0, rad(o[3] + 4 * cos(t * 0.17 + i)))
				* CFrame.Angles(0, (t * o[4] + whirl * sgn) % 6.2832, 0)
		end
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)

		-- fades (GUI writes only while something changes)
		local a = s.alpha
		-- the assembly: the void, then the moon, the orbits and ribbons, the clock, the body and the ground, each fading in in turn
		for i, gp in ipairs(groups) do
			local e = ease(gp[2], gp[3])
			local w = a * e
			if math.abs(w - groupW[i]) > 0.004 then groupW[i] = w; write(gp[1], w) end
			if not live[gp[1]] and e > 0.25 then live[gp[1]] = true; applyEnabled() end
		end
		local rw = a * ease(1.0, 3.0)
		if math.abs(rw - ribW) > 0.004 then
			ribW = rw
			for _, rb in ipairs(ribbons) do
				local x = 1 - (1 - rb[2]) * rw
				rb[1].Transparency = rb[3] and NumberSequence.new(x) or rseq(x)
			end
		end
		local hw = 1 - a * ease(0, 1.2)
		if math.abs(hw - holeW) > 0.01 then holeW = hw; hole.Transparency = hw end
		if not pulseDone and age > 4.5 then
			local u = math.min((age - 4.5) / 1.8, 1)
			local pw = 6 + 70 * (1 - (1 - u) ^ 3)
			pulse.Enabled = true
			pulse.Size = UDim2.new(pw, 0, pw, 0)
			pulseIm.ImageTransparency = 0.35 + 0.65 * u ^ 0.8
			if u >= 1 then pulseDone = true; pulse.Enabled = false end
		end
		local ga = gA * a * ease(4.4, 5.4)
		if math.abs(ga - groundW) > 0.01 then groundW = ga; write(groundFades, ga) end
		local on = gA > 0.3
		if on ~= groundOn then groundOn = on; applyEnabled() end
	end

	function fx.setVisible(on)
		folder.Parent = on and ctx.container or nil
	end

	function fx.setDetail(isNear)
		near = isNear
		applyEnabled()
	end

	function fx.destroy()
		folder:Destroy()
		if grade then grade:Destroy() end
	end

	applyEnabled()
	folder.Parent = ctx.container
	return fx
end

return End
