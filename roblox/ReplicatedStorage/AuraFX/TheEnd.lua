--[[
	AuraFX.TheEnd — 『 THE END 』 worn (1 in 1,000,000,000). Midnight of the universe, worn: black, white and silver only.
	Pass 2 (2026-10-13), Milo: "scale it up so much bigger", "the light flashes are annoying": a colossal look built from
	steady light — glowing HDR layers (SurfaceGui / BillboardGui Brightness) and soft additive particles over dark smoke —
	with NO pulses, strobes or flicker: everything turns, drifts or rises slowly and evenly.
	Pass 3 (2026-10-13), Milo's brief ("a cinematic, cosmic phenomenon", KEEP THE CLOCK): the pair became two opposite
	energies (a cloudy silver moon; a black void with a brilliant white core and fragments of light at its edge) joined by
	curved ribbons of light circling the wearer, and three scales of fine detail drift round everything.
	Pass 4 (2026-10-13), Milo: "ultra realistic, just like equinox ... go all out": photographic orbs, the clock rebuilt as
	fine-line dials stacked in depth, five 3D orbit rings of beams, a photographic galaxy underfoot, and an assembly on equip.
	Pass 5 (2026-10-14), Milo: "it needs so much more work, add depth, so much better particle effects, less transparency and
	more feel toward the build. Go all out, take your time and build it so much better." — "Make it amazing!"
	"The Last Clock": the aura is now a machine of ~360 solid parts (opaque: they write depth, so things pass in front of
	and behind each other for real), about 26 studs deep, in black steel, silver and white lume.
	  the clock      a skeleton pocket watch 28 studs across standing 8 studs beyond the wearer, always on the far side from
	                 whoever is watching (each viewer's own camera, through a soft spring, so it never blocks the owner's
	                 view and swings round to show its thickness): a fluted silver bezel 2.4 deep, a dark chapter ring with
	                 inlaid white numerals and raised lume plots, an openwork star rete, a guilloché sub-dial, seven toothed
	                 gears turning at meshed rates behind and in front of the dial (their teeth break the rim at 1:30, 4, 8
	                 and 10:30), hands locked at twelve while the seconds hand sweeps, a crown and bow on top. Glints ride
	                 the bezel, smoke curls off its rim (ink on the void side, silver on the moon side), metal shards break
	                 off at eleven and fly into the void, and a corona rings it at night.
	  the armillary  three gimballed rings round the wearer — a precessing silver meridian, a dark equator band with twelve
	                 lume hours, the ecliptic at 23.4° — joined by pins, with eight time shards riding the ecliptic.
	  the balance    a solid cratered white moon and a pure-black void hang on an invisible beam on the viewer's left and
	                 right and rock slowly like scales. The void has a white photon ring hugging its silhouette, a lensed arc
	                 over the top, a white four-point heart with crackle veins, an opaque accretion disc nearly edge-on (its
	                 near half crosses in front of the core) and matter spiralling into it. Dust snows off the moon; its own
	                 key light rims the wearer at night.
	  the streams    a silver stream arcs from the moon into one palm and an ink stream from the void into the other (the
	                 palms drink them in), and an ink ribbon falls from the void onto the dais rim.
	  the dais       a dark galaxy pool 30 studs across with white arms inside a raised fluted silver rim, two floating arm
	                 layers turning against it, an engraved clock ring round it, a balance wheel with a hairspring swinging
	                 under the feet with a vortex of streaks climbing into it, motes and black ash rising, time dripping off
	                 the soles, ankle mist when standing on the ground. It stays put for jumps and floats under a flyer.
	  the air        silver dust, glints, and big slow bokeh drifting between the camera and the wearer (three scales).
	Equip (~6 s, mechanical, no flash): the void condenses, the moon rises out of the floor, the rings unfold up round the
	wearer, the bezel sweeps round from twelve, the gears slide out and spin down, the hands spin in and lock at twelve, the
	dais rim rises in a wave, the crown drops on, the shards settle on their ring; the wearer's own screen dims and cools
	meanwhile. After that everything turns, sways or drifts at a steady pace: no pulses, strobes or flicker, ever.
	Day reads by value (dark steel, black void and dark pool against white lume, silver metal and an ink contour; one
	Highlight keeps the metal neutral under the cyan sky); night glows softly through GUI Brightness above the Bloom threshold.
	Past ~110 studs the particles stop and the fine detail is dropped; low quality builds 149 parts. Flags: CONFIG below (a
	ModuleScript attribute with the same name and type overrides each one in Studio).
	Spec: docs/the-end/pass5-spec.md. Build notes and decisions: docs/the-end/pass5-build-notes.md.
	Textures: aura_work/tex4/make_theend_tex4.py (ids in aura_work/tex4/uploaded.md); aura_work/tex3/make_theend_tex3.py (ids in aura_work/tex3/uploaded.md) + the AuraCinema kit / _VFXLib (VFX Studio).
	Pass 5 textures: textures/te5/ (TEX5 below; until they are uploaded each one falls back to a pass-4 texture).
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
-- pass 5 (textures/te5/surfaces, textures/te5/particles): filled in on the Mac after upload. "" = not uploaded yet;
-- "rbxassetid://123" and bare digits both work. Until a key is filled in it falls back to a pass-4 texture (FALLBACK).
local TEX5 = {
	dialInlay = "", subdial = "", accretion = "", galaxyFloor = "", galaxyArms = "", galaxyCore = "", engraving = "",
	halo = "", hairspring = "", stream = "", ribbon = "",
	shards5 = "", smoke5 = "", mote = "", glint5 = "", bokeh = "", streak5 = "", ash5 = "",
}
local TEX5_LAYOUT = { shards5 = { "Grid4x4", "Loop" }, smoke5 = { "Grid4x4", "OneShot" }, ash5 = { "Grid2x2", "Random" } }
local FALLBACK = { -- key -> { pass-4 TEX key, flipbook layout, mode }
	dialInlay = { "dialOuter" }, subdial = { "dialInner" }, accretion = { "galaxy4" }, galaxyFloor = { "galaxy4" },
	galaxyArms = { "galaxy4" }, galaxyCore = { "ornate" }, engraving = { "gring" }, halo = { "rim" }, hairspring = { "swirl" },
	stream = { "line" }, ribbon = { "line" },
	shards5 = { "ash", "None", "Loop" }, smoke5 = { "puff", "Grid4x4", "OneShot" }, mote = { "glow" }, glint5 = { "glint" },
	bokeh = { "glow" }, streak5 = { "spark" }, ash5 = { "ash", "None", "Loop" },
}
local function idOf(v)
	if type(v) ~= "string" or v == "" then return nil end
	if string.match(v, "^%d+$") then return "rbxassetid://" .. v end
	return v
end
-- T(key) -> id, flipbook layout name, flipbook mode name (layout "None" when it is not a flipbook). Accepts a TEX5 key or
-- a pass-4 TEX key. The layout comes from whichever texture is used, because a fallback can be laid out differently.
local function T(key)
	local id = idOf(TEX5[key])
	if id then
		local l = TEX5_LAYOUT[key]
		return id, l and l[1] or "None", l and l[2] or "Loop"
	end
	local f = FALLBACK[key]
	if f then return TEX[f[1]], f[2] or "None", f[3] or "Loop" end
	return TEX[key] or "", "None", "Loop"
end
local function isTe5(key) return idOf(TEX5[key]) ~= nil end

-- particle and beam colours (as pass 4) and a few more for pass 5
local WHITE = Color3.fromRGB(248, 249, 255)
local INK = Color3.fromRGB(5, 5, 8)
local SMOKE = Color3.fromRGB(14, 14, 19)
local MIST = Color3.fromRGB(205, 209, 220)
local ASH = Color3.fromRGB(16, 16, 20)
local RIBBON_INK = Color3.fromRGB(12, 12, 16)
-- solid parts: colour, material, reflectance and the sub-model they live in (the Highlight covers only "Silver")
local MAT = {
	SILVER = { Color3.fromRGB(176, 180, 190), Enum.Material.Metal, 0.08, "Silver" },
	BRIGHT = { Color3.fromRGB(214, 218, 226), Enum.Material.Metal, 0.12, "Silver" },
	STEEL = { Color3.fromRGB(44, 46, 51), Enum.Material.SmoothPlastic, 0, "Dark" },
	DEEP = { Color3.fromRGB(30, 31, 35), Enum.Material.SmoothPlastic, 0, "Dark" },
	BASE = { Color3.fromRGB(12, 12, 16), Enum.Material.SmoothPlastic, 0, "Dark" },
	VOID = { Color3.fromRGB(0, 0, 0), Enum.Material.Neon, 0, "Dark" },
	LUME = { Color3.fromRGB(236, 240, 248), Enum.Material.Neon, 0, "Lume" },
	ARC = { Color3.fromRGB(205, 208, 216), Enum.Material.Neon, 0, "Lume" },
	VEIN = { Color3.fromRGB(220, 224, 232), Enum.Material.Neon, 0, "Lume" },
	MOON = { Color3.fromRGB(234, 236, 240), Enum.Material.SmoothPlastic, 0, "Silver" },
	CRATER = { Color3.fromRGB(168, 171, 178), Enum.Material.SmoothPlastic, 0, "Silver" },
}

-- flags (any attribute on this ModuleScript with the same name and type overrides the default when it is required)
local CONFIG = {
	USE_FILM_MESHES = false, -- master switch for the FILM_* flags: the cutscene's own meshes (ReplicatedStorage.AuraCinema.Assets.TheEnd)
	FILM_BEZEL = false, FILM_DIAL = false, FILM_RETE = false, FILM_HANDS = false, FILM_GEARS = false, FILM_MOON = false,
	FILM_VOID = false, FILM_HAND_FLIP = false, FILM_KEEP_TEXTURES = false,
	VIEWER_ANCHOR = true, -- the clock stands on the far side of the wearer from each viewer's camera (false: always behind, as pass 4)
	CLOCK_DIST = 8, CLOCK_HEIGHT = 9.85, CLOCK_TILT = 8,
	YAW_SPRING = 6.5, -- how fast the clock swings round when the camera moves (rad/s; 95 % in 0.73 s)
	HIGHLIGHT = true, HIGHLIGHT_LOW = true, -- the silver-tone Highlight (keeps the metal neutral under the cyan sky)
	SHADOWS = true, -- the moon and the void cast shadows (high quality only)
	ASSEMBLY = true, ASSEMBLY_REMOTE = true, GRADE = true,
	DAIS_FLOAT = true, -- the dais floats under the feet when the ground is far below
	NEAR_HIDE = true, -- hide the rings and the bokeh when the camera is right inside them
	NIGHT_INTERVAL = 1.0,
	DEBUG = false,
}
do
	local ok, attrs = pcall(function() return script:GetAttributes() end)
	if ok and type(attrs) == "table" then
		for k, v in pairs(attrs) do
			local d = CONFIG[k]
			if d ~= nil then
				if typeof(v) == typeof(d) then
					CONFIG[k] = v
				else
					warn(string.format("TheEnd: attribute %s is a %s, expected a %s (ignored)", k, typeof(v), typeof(d)))
				end
			end
		end
	end
end

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

local rad, sin, cos, exp, sqrt, abs, atan2 = math.rad, math.sin, math.cos, math.exp, math.sqrt, math.abs, math.atan2
local min, max, clamp, pi = math.min, math.max, math.clamp, math.pi
local TAU = 2 * pi
local IDENT = CFrame.new()
local DISC = CFrame.Angles(0, rad(90), 0) -- a cylinder lying with its axis along z (a disc facing the viewer)
local VERT = CFrame.Angles(0, 0, rad(90)) -- a cylinder standing upright
local FLIP = CFrame.Angles(0, pi, 0)
local TILT15 = CFrame.Angles(rad(15), 0, 0)
local TILT33 = CFrame.Angles(rad(33), 0, 0)
local FLAT = CFrame.new(0, 0.95, 0) * CFrame.Angles(rad(90), 0, 0) -- the rings lying flat on the dais before they rise
local ASM_END = 6.5

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- the wearer's own screen dims and cools for a few seconds when they put it on (not when spawning or joining)
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
local function wrapPi(a) return (a + pi) % TAU - pi end
local function smooth(u)
	if u <= 0 then return 0 elseif u >= 1 then return 1 end
	return u * u * (3 - 2 * u)
end
-- eases in with a small overshoot (~6 %) and locks exactly at 1, like a part snapping into its seat
local function easeOutBack(u)
	if u <= 0 then return 0 elseif u >= 1 then return 1 end
	local v = u - 1
	return 1 + 2.25 * v * v * v + 1.25 * v * v
end
-- position eased with overshoot (k may go a little below 0), rotation blended without overshoot
local function lerpCF(a, b, k)
	return CFrame.new(a.Position + (b.Position - a.Position) * k) * a.Rotation:Lerp(b.Rotation, clamp(k, 0, 1))
end
local function ss(a, b, x)
	local u = clamp((x - a) / (b - a), 0, 1)
	return u * u * (3 - 2 * u)
end
-- 0 by day, 1 by night (dusk 17:30-19:00, dawn 05:00-06:30), in steps of 0.05
local function nightStep()
	local ct = Lighting.ClockTime
	return math.floor(max(ss(17.5, 19, ct), 1 - ss(5, 6.5, ct)) * 20 + 0.5) / 20
end

-- the gears: where they sit on the clock (x, y, z), tip and root diameters, teeth bars, thickness, tooth width, web, spokes,
-- turning speed (°/s, all clients agree through the server clock), and whether low quality builds it
local GEARS = {
	{ "GA", 8.839, 8.839, -2.00, 9.0, 8.0, 8, 0.50, 0.785, true, true, -4.0, true },
	{ "GB", 11.172, -6.450, -1.85, 6.0, 5.2, 6, 0.45, 0.681, true, false, 9.0, false },
	{ "GC", -10.912, -6.300, -2.10, 7.0, 6.1, 6, 0.45, 0.798, true, true, -6.0, false },
	{ "GD", -8.768, 8.768, -1.90, 8.0, 7.1, 7, 0.50, 0.797, true, false, 4.6, false },
	{ "GE", 0, 0, -0.95, 7.6, 6.8, 8, 0.40, 0.668, true, true, 6.0, true },
	{ "GH", 5.196, -3.000, 0.58, 3.6, 3.0, 4, 0.24, 0.589, false, false, -12.0, false },
	{ "GI", -5.196, -3.000, 0.58, 3.6, 3.0, 4, 0.24, 0.589, false, false, -12.0, false },
}
-- moon craters: direction on the moon (its +X faces the viewer), diameter, built on low
local CRATERS = {
	{ Vector3.new(0.80, 0.35, -0.20), 2.6, true }, { Vector3.new(0.70, -0.45, 0.25), 1.8, true },
	{ Vector3.new(0.95, 0.05, 0.25), 1.2, false }, { Vector3.new(0.45, 0.75, 0.30), 1.6, true },
	{ Vector3.new(0.55, -0.15, -0.70), 2.0, true }, { Vector3.new(0.30, -0.80, -0.25), 1.4, false },
}
-- crackle veins on the void's heart (viewer x right, y up)
local VEINS = {
	{ 0.35, 0.25, 1.25, 0.95 }, { 1.25, 0.95, 1.85, 0.80 }, { -0.30, -0.40, -1.10, -1.35 }, { -1.10, -1.35, -1.05, -2.05 },
	{ 0.40, -0.35, 1.40, -0.70 },
}

-- the film's own meshes (only looked up when the FILM_* flags ask for them; any failure keeps the procedural part)
local function meshOf(o)
	if not o then return nil end
	if o:IsA("MeshPart") then return o end
	return o:FindFirstChildWhichIsA("MeshPart", true)
end
local function filmKit()
	local te, obl
	pcall(function()
		local cinema = ReplicatedStorage:FindFirstChild("AuraCinema")
		local assets = cinema and cinema:FindFirstChild("Assets")
		te = assets and assets:FindFirstChild("TheEnd")
		obl = (te and te:FindFirstChild("Oblivion")) or (assets and (assets:FindFirstChild("Oblivion") or assets:FindFirstChild("Oblivion", true)))
	end)
	return te, obl
end
local function goodMesh(m)
	if not m then return false end
	local ok, good = pcall(function()
		local s = m.Size
		return m.MeshId ~= "" and s.X >= 0.01 and s.Y >= 0.01 and s.Z >= 0.01
	end)
	return ok and good == true
end
-- a right-handed rotation that sends the mesh's local axes to the clock axes picked for them
local function axesTo(img)
	if img[1]:Cross(img[2]):Dot(img[3]) < 0 then img[2] = -img[2] end
	return CFrame.fromMatrix(Vector3.zero, img[1], img[2], img[3])
end
-- a disc-like mesh: its thinnest axis becomes the depth (z), the other two must be round; scaled to the target diameter
local function fitDisc(m, dia, depth)
	local sz = m.Size
	local s = { sz.X, sz.Y, sz.Z }
	local thin = 1
	if s[2] < s[thin] then thin = 2 end
	if s[3] < s[thin] then thin = 3 end
	local a, b = thin % 3 + 1, (thin + 1) % 3 + 1
	if max(s[a], s[b]) / min(s[a], s[b]) > 1.15 then return nil end
	local k = dia / max(s[a], s[b])
	local ns = { s[1] * k, s[2] * k, s[3] * k }
	if ns[thin] < 0.3 * depth or ns[thin] > 3 * depth then ns[thin] = depth end
	local img = {}
	img[thin], img[a], img[b] = Vector3.zAxis, Vector3.xAxis, Vector3.yAxis
	return Vector3.new(ns[1], ns[2], ns[3]), axesTo(img)
end
-- a hand: the longest axis points at XII (y), the thinnest of the other two is the depth (z)
local function fitHand(m, length)
	local sz = m.Size
	local s = { sz.X, sz.Y, sz.Z }
	local long = 1
	if s[2] > s[long] then long = 2 end
	if s[3] > s[long] then long = 3 end
	local a, b = long % 3 + 1, (long + 1) % 3 + 1
	local thin, other = a, b
	if s[b] < s[a] then thin, other = b, a end
	local k = length / s[long]
	local img = {}
	img[long], img[thin], img[other] = Vector3.yAxis, Vector3.zAxis, Vector3.xAxis
	return Vector3.new(s[1] * k, s[2] * k, s[3] * k), axesTo(img)
end
-- a sphere: scaled evenly to the target diameter
local function fitSphere(m, dia)
	local sz = m.Size
	local big, small = max(sz.X, sz.Y, sz.Z), min(sz.X, sz.Y, sz.Z)
	if big / small > 1.1 then return nil end
	return sz * (dia / big), IDENT
end

function End.build(ctx)
	local low = ctx.quality == "low"
	local hi = not low
	local char = ctx.char
	local destroyed = false
	local root = new("Model", { Name = "TheEnd_" .. char.Name })
	local mats = {
		Silver = new("Model", { Name = "Silver" }, root), Dark = new("Model", { Name = "Dark" }, root),
		Lume = new("Model", { Name = "Lume" }, root), Fx = new("Folder", { Name = "Fx" }, root),
	}
	-- every part belongs to one hideable group: Core, Detail (dropped when far), Armillary (hidden when the camera is inside
	-- the rings) or ArmillaryDetail (both). Each group has its own child model inside each material model.
	local CORE, DETAIL, ARM, ARMD = 1, 2, 3, 4
	local HIDE_NAMES = { "Core", "Detail", "Armillary", "ArmillaryDetail" }
	local hideD, hideA = { false, true, false, true }, { false, false, true, true }
	local holders, holderOf, shownH = { {}, {}, {}, {} }, {}, { true, true, true, true }
	local function holder(mat, h)
		local key = mat .. h
		local m = holderOf[key]
		if not m then
			m = new(mat == "Fx" and "Folder" or "Model", { Name = HIDE_NAMES[h] }, mats[mat])
			holderOf[key] = m
			table.insert(holders[h], { m, mats[mat] })
		end
		return m
	end

	-- the rigid groups every part rides in (their CFrames are worked out each frame)
	local GK, GHOUR, GMIN, GSEC, GCROWN = 1, 2, 3, 4, 5
	local GGEAR = 5 -- + 1..7
	local GF1, GF2, GF3 = 13, 14, 15
	local GSHARD = 15 -- + 1..8
	local GMOON, GVOID, GPF, GHF, GACC, GSWIRL = 24, 25, 26, 27, 28, 29
	local GDAIS, GG0, GG1, GG2, GENG, GWHEEL, GHAIR, GFUNNEL, GRIBEND = 30, 31, 32, 33, 34, 35, 36, 37, 38
	local GFEED, GAIR, GBOKEH, GPALMM, GPALMV = 39, 40, 41, 42, 43
	local GCF = table.create(43, IDENT)

	-- the part registry: part, group, rest transform in the group, hide group; the assembly's start transform and motion
	-- window; the fade window; the photon ring / lensed arc keep a radius that follows the void's silhouette
	local PP, PG, PL, PH, PS, PM0, PM1, PF0, PF1, PCUR = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
	local PROT, PRR, PRS, PRSO = {}, {}, {}, {}
	local NP = 0
	local solids = {} -- parts that fade in (rest Transparency 0)
	local clockParts = {} -- (for the body-anchored fallback's see-through rule)
	local function reg(p, grp, L, h)
		NP += 1
		PP[NP], PG[NP], PL[NP], PH[NP] = p, grp, L, h
		if grp <= GGEAR + 7 then table.insert(clockParts, p) end
		return NP
	end
	local function solidPart(p, tok, h, grp, L)
		local m = MAT[tok]
		p.Color, p.Material, p.Reflectance = m[1], m[2], m[3]
		p.Transparency = 1
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Massless, p.Locked = true, false, false, false, false, true, true
		p.Parent = holder(m[4], h)
		local i = reg(p, grp, L, h)
		PF0[i], PF1[i], PCUR[i] = 0, 0.2, 1
		table.insert(solids, i)
		return i
	end
	-- a solid part: shape "Block", "Ball", "Cylinder" or "Wedge"
	local function solid(name, tok, h, grp, shape, size, L)
		local p = Instance.new(shape == "Wedge" and "WedgePart" or "Part")
		if shape == "Ball" then p.Shape = Enum.PartType.Ball elseif shape == "Cylinder" then p.Shape = Enum.PartType.Cylinder end
		p.Name = name
		p.Size = size
		return solidPart(p, tok, h, grp, L)
	end
	-- an invisible carrier for GUIs, emitters and beam ends: Transparency 1 forever
	local function carrier(name, h, grp, size, L)
		local p = new("Part", { Name = name, Size = size, Transparency = 1, Anchored = true, CanCollide = false, CanQuery = false,
			CanTouch = false, CastShadow = false, Massless = true, Locked = true }, holder("Fx", h))
		reg(p, grp, L or IDENT, h)
		return p
	end
	local function fadeWin(i, a, b) PF0[i], PF1[i] = a, b end
	local function motion(i, S, a, dur) PS[i], PM0[i], PM1[i] = S, a, a + dur end

	-- GUIs: images fade in once; their Brightness only changes on the night tick
	local images, brights = {}, {} -- { image, rest transparency, fade from, fade to, written }, { gui, day, night }
	local hiCanvas, midCanvas = low and 512 or 1024, low and 256 or 512
	local function surface(host, face, canvas, b0, b1, key, f0, f1, color)
		local g = new("SurfaceGui", { Face = face, SizingMode = Enum.SurfaceGuiSizingMode.FixedSize, CanvasSize = Vector2.new(canvas, canvas),
			LightInfluence = 0, Brightness = b0, AlwaysOnTop = false }, host)
		local im = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = (T(key)),
			ImageColor3 = color or Color3.new(1, 1, 1), ImageTransparency = 1 }, g)
		local e = { im, 0, f0, f1, 1 }
		table.insert(images, e)
		if b1 then table.insert(brights, { g, b0, b1 }) end
		return g, e
	end

	-- the film meshes (CONFIG.USE_FILM_MESHES + one FILM_* flag per element), cloned and scaled to the procedural size
	local filmTe, filmObl
	if CONFIG.USE_FILM_MESHES then filmTe, filmObl = filmKit() end
	local function film(flag, name, oblivion)
		if not (CONFIG.USE_FILM_MESHES and CONFIG[flag]) then return nil end
		local m
		pcall(function()
			local box = oblivion and filmObl or filmTe
			m = meshOf(box and box:FindFirstChild(name))
		end)
		if goodMesh(m) then return m end
		return nil
	end
	local function filmSolid(tpl, size, name, tok, h, grp, L)
		local ok, p = pcall(function()
			local c = tpl:Clone()
			if not CONFIG.FILM_KEEP_TEXTURES then
				c:ClearAllChildren()
				pcall(function() c.TextureID = "" end)
			end
			pcall(function() c.RenderFidelity = Enum.RenderFidelity.Automatic end) -- STUDIO-VERIFY: may not be settable at runtime (harmless if not)
			c.Name = name
			c.Size = size
			return c
		end)
		if not ok or not p then return nil end
		return solidPart(p, tok, h, grp, L)
	end

	---------------------------------------------------------------- THE CLOCK: a skeleton pocket watch, 28 studs, 8 studs beyond
	-- (frame K: x = viewer's right, y = toward XII, z = toward the viewer; the angle θ runs clockwise from XII)
	local function radial(th, r, z) return CFrame.Angles(0, 0, -rad(th)) * CFrame.new(0, r, z) end
	-- the bezel: a fluted silver coin edge 2.4 deep (the segments alternate in depth, so the flutes show and nothing z-fights);
	-- on equip it sweeps round clockwise from twelve, each segment flying in from outside and behind
	local filmBezel = film("FILM_BEZEL", "RingG")
	local fsz, frot
	if filmBezel then fsz, frot = fitDisc(filmBezel, 28.24, 2.5) end
	local k0 = fsz and filmSolid(filmBezel, fsz, "Bezel", "SILVER", CORE, GK, CFrame.new(0, 0, -0.2) * frot)
	if k0 then
		motion(k0, CFrame.new(0, 0, -4.2) * CFrame.Angles(0, 0, -rad(40)) * frot, 2.0, 0.9)
		fadeWin(k0, 2.0, 2.3)
	else
		local NB = low and 20 or 32
		for i = 0, NB - 1 do
			local th = (i + 0.5) * 360 / NB
			local odd = i % 2 == 1
			local Ro = odd and 14.12 or 14.00
			local zb, zf = odd and -1.44 or -1.40, odd and 1.12 or 1.00
			local rm, zc = (12.2 + Ro) / 2, (zb + zf) / 2
			local k = solid("Bezel", "SILVER", CORE, GK, "Block", Vector3.new(2 * Ro * math.tan(rad(180 / NB)) + 0.02, Ro - 12.2, zf - zb),
				radial(th, rm, zc))
			local a = 2.0 + 0.9 * i / NB
			motion(k, radial(th + 40, rm + 7, zc - 4), a, 0.7)
			fadeWin(k, a, a + 0.25)
		end
	end
	-- the chapter ring: dark steel, recessed into the bezel (its outer edge tucks under the bezel and hides the polygon)
	local filmDial = film("FILM_DIAL", "Dial")
	fsz, frot = nil, nil
	if filmDial then fsz, frot = fitDisc(filmDial, 25.0, 0.5) end
	k0 = fsz and filmSolid(filmDial, fsz, "Dial", "STEEL", CORE, GK, CFrame.new(0, 0, -0.15) * frot)
	if k0 then
		motion(k0, CFrame.new(0, 0, -3.15) * frot, 2.3, 0.6)
		fadeWin(k0, 2.3, 2.55)
	else
		local NC = low and 16 or 24
		for i = 0, NC - 1 do
			local th = (i + 0.5) * 360 / NC
			local odd = i % 2 == 1
			local zb, zf = odd and -0.42 or -0.40, odd and 0.12 or 0.10
			local zc = (zb + zf) / 2
			local k = solid("Chapter", "STEEL", CORE, GK, "Block", Vector3.new(2 * 12.5 * math.tan(rad(180 / NC)) + 0.02, 3.1, zf - zb),
				radial(th, 10.95, zc))
			local a = 2.3 + 0.9 * i / NC
			motion(k, radial(th, 10.95, zc - 3), a, 0.6)
			fadeWin(k, a, a + 0.25)
		end
	end
	-- the inlay: white Roman numerals, minute track and stars set into the chapter ring (opaque strokes, glowing through
	-- Brightness, not alpha). STUDIO-VERIFY: SurfaceGui Face = Back draws on the +Z face (toward the viewer), XII up.
	local inlay = carrier("Inlay", CORE, GK, Vector3.new(24.4, 24.4, 0.05), CFrame.new(0, 0, 0.12))
	surface(inlay, Enum.NormalId.Back, hiCanvas, 1.6, 2.6, "dialInlay", 3.4, 4.2)
	-- raised lume plots at the hours, on the minute track
	if hi then
		for h = 0, 11 do
			local k = solid("Plot", "LUME", DETAIL, GK, "Block", Vector3.new(0.42, 0.55, 0.18), radial(h * 30, 11.85, 0.21))
			motion(k, radial(h * 30, 11.85, 3.21), 3.4 + 0.04 * h, 0.3)
			fadeWin(k, 3.4 + 0.04 * h, 3.5 + 0.04 * h)
		end
	end
	-- the rete: an openwork twelve-point star of silver bars over the open dial (the bars alternate in depth at the crossings)
	if hi then
		local filmRete = film("FILM_RETE", "Astrolabe")
		fsz, frot = nil, nil
		if filmRete then fsz, frot = fitDisc(filmRete, 18.2, 0.24) end
		k0 = fsz and filmSolid(filmRete, fsz, "Rete", "SILVER", DETAIL, GK, CFrame.new(0, 0, 0.27) * frot)
		if k0 then
			motion(k0, CFrame.new(0, 0, 3.27) * CFrame.Angles(0, 0, rad(60)) * frot, 3.0, 0.6)
			fadeWin(k0, 3.0, 3.15)
		else
			for k = 0, 11 do
				local phi = (k + 2.5) * 30
				local zk = k % 2 == 0 and 0.25 or 0.29
				local i = solid("Rete", "SILVER", DETAIL, GK, "Block", Vector3.new(17.58, 0.26, 0.20), radial(phi, 2.355, zk))
				motion(i, radial(phi, 2.355 * 2.2, zk), 3.0 + 0.04 * k, 0.5)
				fadeWin(i, 3.0 + 0.04 * k, 3.15 + 0.04 * k)
			end
		end
	end
	-- the sub-dial: a dark guilloché disc at the centre. STUDIO-VERIFY: SurfaceGui Face = Left is the cylinder's -X end, which
	-- faces the viewer after the 90° turn (canvas right = the viewer's right)
	local subdial = PP[solid("SubDial", "DEEP", CORE, GK, "Cylinder", Vector3.new(0.30, 6.5, 6.5), CFrame.new(0, 0, 0.57) * DISC)]
	motion(NP, CFrame.new(0, 0, -1.43) * DISC, 3.2, 0.4)
	fadeWin(NP, 3.2, 3.4)
	surface(subdial, Enum.NormalId.Left, midCanvas, 1.4, 2.2, "subdial", 3.2, 3.4)

	-- the hands: hour and minute locked at XII (midnight, the end), the seconds hand sweeping smoothly; raised above the dial
	local function handPart(name, tok, h, grp, shape, size, pos, rot)
		local i = solid(name, tok, h, grp, shape, size, CFrame.new(pos) * (rot or IDENT))
		fadeWin(i, 3.6, 3.8)
		return i
	end
	local R45 = CFrame.Angles(0, 0, rad(45))
	local filmHand = film("FILM_HANDS", "Hand")
	for _, hd in ipairs({ { GHOUR, 8.55, 2.67, 0.55, 5.6, 3.4, 0.70, 6.45, 1.6, -0.8, 0.24, 4.6, 3.6 },
		{ GMIN, 11.17, 3.58, 0.40, 8.0, 4.6, 0.52, 8.8, 2.0, -1.0, 0.16, 6.2, 4.9 } }) do
		local grp = hd[1]
		local done = false
		if filmHand then
			local sz, rot = fitHand(filmHand, hd[2])
			local flip = CONFIG.FILM_HAND_FLIP and CFrame.Angles(0, 0, pi) or IDENT
			local k = sz and filmSolid(filmHand, sz, "Hand", "SILVER", CORE, grp, CFrame.new(0, hd[3], 0) * flip * rot)
			if k then
				fadeWin(k, 3.6, 3.8)
				done = true
			end
		end
		if not done then
			handPart("Shaft", "SILVER", CORE, grp, "Block", Vector3.new(hd[4], hd[5], 0.16), Vector3.new(0, hd[6], 0))
			handPart("Tip", "SILVER", CORE, grp, "Block", Vector3.new(hd[7], hd[7], 0.16), Vector3.new(0, hd[8], 0), R45)
			if hi then handPart("Tail", "SILVER", CORE, grp, "Block", Vector3.new(hd[4], hd[9], 0.16), Vector3.new(0, hd[10], 0)) end
		end
		if hi then handPart("Lume", "LUME", CORE, grp, "Block", Vector3.new(hd[11], hd[12], 0.05), Vector3.new(0, hd[13], 0.105)) end
	end
	handPart("Needle", "SILVER", CORE, GSEC, "Block", Vector3.new(0.12, 12.2, 0.08), Vector3.new(0, 3.5, 0))
	if hi then
		handPart("Weight", "BRIGHT", CORE, GSEC, "Cylinder", Vector3.new(0.08, 0.9, 0.9), Vector3.new(0, -2.0, 0), DISC)
		handPart("SecondsTip", "LUME", CORE, GSEC, "Ball", Vector3.new(0.26, 0.26, 0.26), Vector3.new(0, 9.6, 0))
	end
	-- the hub stack over the hands: a dark base, a bright cap and a lume jewel
	handPart("Hub", "STEEL", CORE, GK, "Cylinder", Vector3.new(0.30, 1.30, 1.30), Vector3.new(0, 0, 1.62), DISC)
	handPart("HubCap", "BRIGHT", CORE, GK, "Cylinder", Vector3.new(0.20, 0.85, 0.85), Vector3.new(0, 0, 1.85), DISC)
	if hi then handPart("Jewel", "LUME", CORE, GK, "Ball", Vector3.new(0.45, 0.45, 0.45), Vector3.new(0, 0, 1.98)) end

	-- the gears: silver discs with a dark web, a bright hub, teeth (bars across the whole gear: only their ends show past the
	-- rim) and two spokes; four big ones behind the rim, a centre wheel behind the sub-dial, two small ones on the dial
	local gearData = {}
	local filmGear = film("FILM_GEARS", "Gear")
	for gi, G in ipairs(GEARS) do
		local name, cx, cy, cz, Dt, Dr, K, d, wt, web, spokes, rate, onLow = table.unpack(G)
		if hi or onLow then
			local grp = GGEAR + gi
			local h = (gi >= 6) and DETAIL or CORE
			local big = gi <= 4
			local a = big and 2.6 or 3.0
			local f1 = big and 2.9 or 3.2
			local function gp(nm, tok, shape, size, L)
				local i = solid(name .. nm, tok, h, grp, shape, size, L)
				fadeWin(i, a, f1)
			end
			local done = false
			if filmGear then
				local sz, rot = fitDisc(filmGear, Dt, d)
				local k = sz and filmSolid(filmGear, sz, name, "SILVER", h, grp, rot)
				if k then
					fadeWin(k, a, f1)
					done = true
				end
			end
			if not done then
				gp("Disc", "SILVER", "Cylinder", Vector3.new(d, Dr, Dr), DISC)
				if web and hi then gp("Web", "STEEL", "Cylinder", Vector3.new(d + 0.04, 0.74 * Dr, 0.74 * Dr), DISC) end
				for j = 0, K - 1 do
					gp("Tooth", "SILVER", "Block", Vector3.new(wt, Dt, d - 0.06), CFrame.Angles(0, 0, -rad(j * 180 / K)))
				end
				if spokes and hi then
					gp("Spoke", "SILVER", "Block", Vector3.new(0.11 * Dr, 0.72 * Dr, d + 0.08), CFrame.Angles(0, 0, rad(45)))
					gp("Spoke", "SILVER", "Block", Vector3.new(0.11 * Dr, 0.72 * Dr, d + 0.08), CFrame.Angles(0, 0, rad(135)))
				end
			end
			if gi >= 6 then
				gp("Hub", "BRIGHT", "Cylinder", Vector3.new(d + 0.10, 0.30 * Dr, 0.30 * Dr), DISC)
			else
				gp("Hub", "BRIGHT", "Cylinder", Vector3.new(d + 0.3, 0.22 * Dr, 0.22 * Dr), DISC)
			end
			-- on equip: the big four slide out from behind the dial, the centre wheel from behind, the small two from the front;
			-- all spin up fast and wind down to their running pace
			local sx, sy, sz2
			if big then sx, sy, sz2 = 0.3 * cx, 0.3 * cy, -4 elseif gi == 5 then sx, sy, sz2 = cx, cy, cz - 3 else sx, sy, sz2 = cx, cy, cz + 3 end
			table.insert(gearData, { grp = grp, cx = cx, cy = cy, cz = cz, sx = sx, sy = sy, sz = sz2, rate = rate, a0 = a, a1 = a + (big and 1.0 or 0.6),
				sign = rate < 0 and -1 or 1, extra = 0 })
		end
	end

	-- the crown and the bow above XII
	local function crownPart(name, shape, size, L)
		local i = solid(name, "BRIGHT", CORE, GCROWN, shape, size, L)
		fadeWin(i, 4.2, 4.4)
		return i
	end
	crownPart("Stem", "Cylinder", Vector3.new(1.4, 1.1, 1.1), CFrame.new(0, 14.6, -0.2) * VERT)
	crownPart("Crown", "Cylinder", Vector3.new(1.5, 2.6, 2.6), CFrame.new(0, 16.0, -0.2) * VERT)
	if hi then
		crownPart("Cap", "Ball", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 16.85, -0.2))
		for j = 0, 9 do
			local b = rad((j + 0.5) * 36)
			local i = solid("Bow", "BRIGHT", DETAIL, GCROWN, "Cylinder", Vector3.new(1.662, 0.55, 0.55),
				CFrame.new(2.283 * cos(b), 19.6 + 2.283 * sin(b), -0.2) * CFrame.Angles(0, 0, b + rad(90)))
			fadeWin(i, 4.2, 4.4)
		end
	end

	-- the night corona: a soft ring of light just outside the bezel (night only, rim-only, behind the clock)
	local corona, coronaEntry
	if hi then
		local cp = carrier("Corona", DETAIL, GK, Vector3.new(44, 44, 0.05), CFrame.new(0, 0, -3.2)) -- (ring peak R 16.3: seen from the front, 3.2 studs back, it lands just outside the bezel)
		corona, coronaEntry = surface(cp, Enum.NormalId.Back, 512, 1.8, nil, "halo", 5.0, 6.0, Color3.fromRGB(236, 240, 248))
		corona.Enabled = false
		coronaEntry[2] = 1
	end
	-- the clock's emitter hosts: the bezel annulus (glints), the two rim smoke banks, the shard feed at eleven
	local rimGlint = carrier("RimGlint", CORE, GK, Vector3.new(28.4, 28.4, 0.2), CFrame.new(0, 0, 1.05))
	local smokeVoid = carrier("SmokeVoid", CORE, GK, Vector3.new(4, 22, 3), CFrame.new(12.6, 0, -1.2))
	local smokeMoon = hi and carrier("SmokeMoon", CORE, GK, Vector3.new(4, 22, 3), CFrame.new(-12.6, 0, -1.2))
	local shardFeed = hi and carrier("ShardFeed", DETAIL, GFEED, Vector3.new(2, 2, 2))

	---------------------------------------------------------------- THE ARMILLARY: three gimballed rings round the wearer
	-- flat bands made of segments; every other segment is a hair thicker so the overlaps never z-fight
	local meridian = {}
	local function ring(name, tok, h, grp, N, R, w, t, f0)
		for i = 0, N - 1 do
			local th = (i + 0.5) * 360 / N
			local k = solid(name, tok, h, grp, "Block", Vector3.new(2 * (R + w / 2) * math.tan(rad(180 / N)) + 0.02, w, t + (i % 2 == 0 and 0.02 or -0.02)),
				radial(th, R, 0))
			fadeWin(k, f0, f0 + 0.3)
			if grp == GF1 then meridian[i] = PP[k] end
		end
	end
	ring("Meridian", "SILVER", ARM, GF1, low and 12 or 18, 6.0, 0.55, 0.24, 1.0)
	ring("Equator", "STEEL", ARM, GF2, low and 12 or 18, 5.3, 0.20, 0.4, 1.3)
	if hi then
		for k = 0, 11 do -- twelve lume hours on the equator band's outer face
			local i = solid("Hour", "LUME", ARMD, GF2, "Block", Vector3.new(0.14, 0.06, 0.32), radial(k * 30, 5.43, 0))
			fadeWin(i, 1.3, 1.6)
		end
		ring("Ecliptic", "SILVER", ARM, GF3, 16, 4.6, 0.45, 0.20, 1.6)
		for _, x in ipairs({ 5.56, -5.56 }) do -- pins: equator to meridian
			local i = solid("Pin", "BRIGHT", ARMD, GF1, "Cylinder", Vector3.new(0.45, 0.30, 0.30), CFrame.new(x, 0, 0))
			fadeWin(i, 1.0, 1.3)
		end
		for _, y in ipairs({ 5.01, -5.01 }) do -- pins: ecliptic to equator
			local i = solid("Pin", "BRIGHT", ARMD, GF2, "Cylinder", Vector3.new(0.45, 0.30, 0.30), CFrame.new(0, y, 0) * VERT)
			fadeWin(i, 1.3, 1.6)
		end
		-- the time shards: eight slivers riding the inside of the ecliptic like beads on a wire, tumbling as they go
		for i = 0, 7 do
			local k = solid("TimeShard", i % 2 == 0 and "BRIGHT" or "LUME", ARMD, GSHARD + 1 + i, "Wedge", Vector3.new(0.14, 0.7 + 0.15 * (i % 3), 0.40), IDENT)
			fadeWin(k, 5.0 + 0.06 * i, 5.2 + 0.06 * i)
		end
	end

	---------------------------------------------------------------- THE BALANCE: the moon and the void, rocking like scales
	-- the moon: a solid white ball with grey crater rims, tidally locked to the wearer (its +X faces the viewer)
	local moon
	local filmMoon = film("FILM_MOON", "Moon", true)
	if filmMoon then
		local sz = fitSphere(filmMoon, 9)
		local k = sz and filmSolid(filmMoon, sz, "Moon", "MOON", CORE, GMOON, IDENT)
		if k then
			moon = PP[k]
			fadeWin(k, 0.6, 0.9)
		end
	end
	if not moon then
		moon = PP[solid("Moon", "MOON", CORE, GMOON, "Ball", Vector3.new(9, 9, 9), IDENT)]
		fadeWin(NP, 0.6, 0.9)
		for _, c in ipairs(CRATERS) do
			if hi or c[3] then
				local u = c[1].Unit
				local dia = c[2]
				local f = sqrt(4.5 * 4.5 - (0.175 * dia) ^ 2)
				local i = solid("Crater", "CRATER", DETAIL, GMOON, "Cylinder", Vector3.new(0.4, dia, dia),
					CFrame.new(u * (f - 0.2)) * (CFrame.lookAt(Vector3.zero, u) * CFrame.Angles(0, rad(90), 0)).Rotation)
				fadeWin(i, 0.6, 0.9)
			end
		end
	end
	moon.CastShadow = CONFIG.SHADOWS and hi
	local moonOut = new("Attachment", { Name = "StreamOut", CFrame = CFrame.new(0, 0, -4.55) * CFrame.Angles(0, 0, rad(90)) }, moon)
	local keyAtt = new("Attachment", { Name = "KeyLight", Position = Vector3.new(0, 4.5, -5.5) }, moon)
	-- STUDIO-VERIFY: a PointLight on an attachment of a part moved by BulkMoveTo follows it every frame
	local keyLight = new("PointLight", { Name = "Key", Range = 22, Color = Color3.fromRGB(226, 232, 246), Brightness = 0, Shadows = false, Enabled = false }, keyAtt)
	-- a thin halo round the moon's rim (the only billboard). It sits 2 studs behind the ball, so the ball hides its inner
	-- edge; not further, or on the clock side it would reach the inlay plane and get cut (keeps >= 0.4 from every GUI plane)
	local halo = new("BillboardGui", { Name = "Halo", Size = UDim2.new(13, 0, 13, 0), StudsOffset = Vector3.new(0, 0, -2.0), LightInfluence = 0,
		Brightness = 1.0, MaxDistance = 400, AlwaysOnTop = false }, moon)
	local haloIm = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = (T("halo")),
		ImageColor3 = Color3.fromRGB(236, 240, 248), ImageTransparency = 1 }, halo)
	local haloEntry = { haloIm, 0.65, 1.4, 2.2, 1 }
	table.insert(images, haloEntry)
	table.insert(brights, { halo, 1.0, 1.6 })

	-- the void: a pure-black Neon ball. STUDIO-VERIFY: Neon black renders pure black under the place's Bloom
	local void
	local voidSize = Vector3.new(8, 8, 8)
	local filmVoid = film("FILM_VOID", "SmoothSphere", true)
	if filmVoid then
		local sz = fitSphere(filmVoid, 8)
		local k = sz and filmSolid(filmVoid, sz, "Void", "VOID", CORE, GVOID, IDENT)
		if k then
			void = PP[k]
			voidSize = sz
			fadeWin(k, 0, 0.4)
		end
	end
	if not void then
		void = PP[solid("Void", "VOID", CORE, GVOID, "Ball", Vector3.new(8, 8, 8), IDENT)]
		fadeWin(NP, 0, 0.4)
	end
	void.CastShadow = CONFIG.SHADOWS and hi
	local voidOut = new("Attachment", { Name = "StreamOut", CFrame = CFrame.new(0, 0, -4.05) * CFrame.Angles(0, 0, rad(90)) }, void)
	local ribbonOut = new("Attachment", { Name = "RibbonOut", CFrame = CFrame.new(0, -4.05, 0) * CFrame.Angles(0, rad(-90), 0) }, void)
	-- the accretion disc: opaque white-hot streaks with black dust lanes, nearly edge-on, its near half in front of the core
	local accretion = carrier("Accretion", CORE, GACC, Vector3.new(13, 0.05, 13))
	surface(accretion, Enum.NormalId.Top, hiCanvas, 1.5, 2.4, "accretion", 0.3, 1.1)
	surface(accretion, Enum.NormalId.Bottom, hiCanvas, 1.5, 2.4, "accretion", 0.3, 1.1)
	local swirlHost = carrier("VoidSwirl", CORE, GSWIRL, Vector3.new(13, 0.3, 13))
	-- the photon ring: lume segments that always hug the black silhouette as the camera sees it (from any distance)
	for i = 0, (low and 8 or 14) - 1 do
		local N = low and 8 or 14
		local th = (i + 0.5) * 360 / N
		local k = solid("PhotonRing", "LUME", CORE, GPF, "Block", Vector3.new(low and 3.92 or 2.17, 0.22, 0.12), IDENT)
		PROT[k], PRR[k], PRS[k] = CFrame.Angles(0, 0, -rad(th)), 0.18, 11
		PS[k], PM0[k], PM1[k] = true, 0.25 + 0.04 * i, 0.85 + 0.04 * i
		fadeWin(k, 0.25 + 0.04 * i, 0.45 + 0.04 * i)
	end
	-- the lensed arc: the far side of the disc bent up over the top of the shadow
	if hi then
		for i = 0, 6 do
			local th = -75 + (i + 0.5) * 150 / 7
			local k = solid("LensedArc", "ARC", DETAIL, GPF, "Block", Vector3.new(1.85, 0.38, 0.10), IDENT)
			PROT[k], PRR[k], PRSO[k] = CFrame.Angles(0, 0, -rad(th)), 0.6, 3
			PS[k], PM0[k], PM1[k] = true, 0.7, 1.4
			fadeWin(k, 0.7, 0.9)
		end
	end
	-- the heart: a white four-point star just in front of the core, with white crackle veins.
	-- STUDIO-VERIFY: Roblox wedge orientation (right angle at -Y, +Z); if the spikes come out hollow, swap the halves' ±90°
	local hb = solid("Heart", "LUME", CORE, GHF, "Ball", Vector3.new(0.70, 0.70, 0.70), IDENT)
	fadeWin(hb, 0.9, 1.1)
	local function grow(i, L)
		motion(i, CFrame.new(L.Position * 0.05) * L.Rotation, 0.9, 0.6)
		fadeWin(i, 0.9, 1.1)
	end
	for _, sp in ipairs({ { 0, 2.8 }, { 180, 2.8 }, { 90, 2.2 }, { 270, 2.2 } }) do
		if hi or sp[1] % 180 == 0 then
			local S = CFrame.Angles(0, 0, -rad(sp[1]))
			local h = sp[2]
			local La = S * CFrame.new(-0.16, h / 2, 0) * CFrame.Angles(0, rad(90), 0)
			local Lb = S * CFrame.new(0.16, h / 2, 0) * CFrame.Angles(0, rad(-90), 0)
			grow(solid("Spike", "LUME", CORE, GHF, "Wedge", Vector3.new(0.08, h, 0.32), La), La)
			grow(solid("Spike", "LUME", CORE, GHF, "Wedge", Vector3.new(0.08, h, 0.32), Lb), Lb)
		end
	end
	if hi then
		for _, v in ipairs(VEINS) do
			local dx, dy = v[3] - v[1], v[4] - v[2]
			local L = CFrame.new((v[1] + v[3]) / 2, (v[2] + v[4]) / 2, 0.02) * CFrame.Angles(0, 0, atan2(-dx, dy))
			grow(solid("Vein", "VEIN", DETAIL, GHF, "Block", Vector3.new(0.07, sqrt(dx * dx + dy * dy) + 0.07, 0.05), L), L)
		end
	end

	---------------------------------------------------------------- THE DAIS: a dark galaxy pool in a raised silver rim
	local base = solid("DaisBase", "BASE", CORE, GDAIS, "Cylinder", Vector3.new(0.12, 29.6, 29.6), CFrame.new(0, 0.06, 0) * VERT)
	fadeWin(base, 4.0, 4.4)
	-- STUDIO-VERIFY: Top-face canvas orientation (up = +Z); the arms must trail the spin (floor turns clockwise from above)
	local floor = carrier("GalaxyFloor", CORE, GG0, Vector3.new(29.6, 0.05, 29.6))
	surface(floor, Enum.NormalId.Top, hiCanvas, 1.3, 2.4, "galaxyFloor", 4.2, 5.2)
	if hi then
		local arms = carrier("GalaxyArms", DETAIL, GG1, Vector3.new(21, 0.05, 21))
		surface(arms, Enum.NormalId.Top, 1024, 1.4, 2.4, "galaxyArms", 4.2, 5.2)
	end
	local core = carrier("GalaxyCore", CORE, GG2, Vector3.new(12, 0.05, 12))
	surface(core, Enum.NormalId.Top, midCanvas, 1.5, 2.6, "galaxyCore", 4.2, 5.2)
	if hi then
		local eng = carrier("Engraving", DETAIL, GENG, Vector3.new(40, 0.05, 40))
		surface(eng, Enum.NormalId.Top, 1024, 1.2, 2.0, "engraving", 4.2, 5.2)
	end
	-- the rim: fluted silver blocks rising in a wave round the pool on equip
	local NR = low and 20 or 30
	for i = 0, NR - 1 do
		local th = i * 360 / NR
		local h = i % 2 == 0 and 0.90 or 0.96
		local k = solid("DaisRim", "SILVER", CORE, GDAIS, "Block", Vector3.new(2 * 15.55 * math.tan(rad(180 / NR)) + 0.02, h, 0.80),
			CFrame.Angles(0, rad(th), 0) * CFrame.new(0, h / 2, -15.15))
		local a = 4.0 + 0.8 * i / NR
		motion(k, CFrame.Angles(0, rad(th), 0) * CFrame.new(0, h / 2 - 1.2, -15.15), a, 0.45)
		fadeWin(k, a, a + 0.15)
	end
	-- the balance wheel under the feet (the watch's heartbeat: a slow smooth swing, no ticking) with its hairspring
	local NW = low and 8 or 12
	for i = 0, NW - 1 do
		local k = solid("WheelRim", "SILVER", CORE, GWHEEL, "Block", Vector3.new(2 * 2.46 * math.tan(rad(180 / NW)) + 0.02, 0.30, 0.32),
			CFrame.Angles(0, rad((i + 0.5) * 360 / NW), 0) * CFrame.new(0, 0, -2.30))
		fadeWin(k, 4.6, 4.9)
	end
	if hi then
		for _, yaw in ipairs({ 0, 90 }) do
			fadeWin(solid("WheelSpoke", "SILVER", CORE, GWHEEL, "Block", Vector3.new(4.3, 0.16, 0.22), CFrame.Angles(0, rad(yaw), 0)), 4.6, 4.9)
		end
	end
	local wheelHub = PP[solid("WheelHub", "BRIGHT", CORE, GWHEEL, "Cylinder", Vector3.new(0.5, 0.7, 0.7), VERT)]
	fadeWin(NP, 4.6, 4.9)
	if hi then
		local hs = carrier("Hairspring", DETAIL, GHAIR, Vector3.new(3.8, 0.05, 3.8))
		surface(hs, Enum.NormalId.Top, 512, 1.4, 2.2, "hairspring", 4.2, 5.2)
	end
	local funnel = hi and carrier("Funnel", CORE, GFUNNEL, Vector3.new(11, 0.4, 11))
	local ribbonEnd = hi and carrier("RibbonEnd", CORE, GRIBEND, Vector3.new(0.4, 0.4, 0.4))
	local ribbonIn = ribbonEnd and new("Attachment", { Name = "RibbonIn" }, ribbonEnd)

	---------------------------------------------------------------- THE AIR and the palm intake carriers
	local air = carrier("AirVolume", CORE, GAIR, Vector3.new(36, 20, 36))
	local bokehHost = hi and carrier("BokehHost", DETAIL, GBOKEH, Vector3.new(18, 10, 5))
	local palmMoon = carrier("PalmMoon", CORE, GPALMM, Vector3.new(2.6, 2.6, 2.6))
	local palmVoid = carrier("PalmVoid", CORE, GPALMV, Vector3.new(2.6, 2.6, 2.6))

	-- the Highlight: one per aura, on the Silver model only (neutral silver by day plus an ink contour on the bright sky).
	-- STUDIO-VERIFY: a Highlight on a Model of 200+ parts
	local tone
	if CONFIG.HIGHLIGHT and (hi or CONFIG.HIGHLIGHT_LOW) then
		tone = new("Highlight", { Name = "TheEndTone", Adornee = mats.Silver, FillColor = Color3.fromRGB(205, 208, 215), FillTransparency = 1,
			OutlineColor = Color3.fromRGB(10, 10, 14), OutlineTransparency = 1, DepthMode = Enum.HighlightDepthMode.Occluded }, mats.Silver)
	end

	---------------------------------------------------------------- THE CHARACTER: palms and soles
	local charStuff = {}
	local function limb(r15, r6) return char:FindFirstChild(r15) or char:FindFirstChild(r6) end
	local function palm(hand, name, grip)
		if not (hand and hand:IsA("BasePart")) then return nil end
		local g = hand:FindFirstChild(grip)
		local pos
		if g and g:IsA("Attachment") then pos = g.Position
		elseif hand.Name == "RightHand" or hand.Name == "LeftHand" then pos = Vector3.new(0, -hand.Size.Y / 2, 0)
		else pos = Vector3.new(0, -1, 0) end
		local a = new("Attachment", { Name = name, Position = pos }, hand)
		table.insert(charStuff, a)
		return a
	end
	local palmR = palm(limb("RightHand", "Right Arm"), "TheEndPalmR", "RightGripAttachment")
	local palmL = palm(limb("LeftHand", "Left Arm"), "TheEndPalmL", "LeftGripAttachment")
	-- (no hands: the streams end on the intake carriers, placed beside the wearer)
	local moonCarA = new("Attachment", { Name = "Palm" }, palmMoon)
	local voidCarA = new("Attachment", { Name = "Palm" }, palmVoid)
	local function sole(foot, name)
		if not (foot and foot:IsA("BasePart")) then return nil end
		local pos = (foot.Name == "LeftFoot" or foot.Name == "RightFoot") and Vector3.new(0, -foot.Size.Y / 2, 0) or Vector3.new(0, -1, 0)
		local a = new("Attachment", { Name = name, Position = pos }, foot)
		table.insert(charStuff, a)
		return a
	end
	local soleL = sole(limb("LeftFoot", "Left Leg"), "TheEndSoleL")
	local soleR = sole(limb("RightFoot", "Right Leg"), "TheEndSoleR")
	-- the starting yaws: the wearer's facing, and the viewer's side (as if seen from behind when the camera tells us nothing)
	local hcf = ctx.hrp.CFrame
	local lv0 = hcf.LookVector
	local yawW = atan2(-lv0.X, -lv0.Z)
	local lastCamPos = (hcf * CFrame.new(0, 3.5, 12.5)).Position
	local cam0 = workspace.CurrentCamera
	if cam0 then lastCamPos = cam0.CFrame.Position end
	local yawTarget = yawW
	do
		local v = hcf.Position + Vector3.new(0, End.pose.hover, 0) - lastCamPos
		local dh = sqrt(v.X * v.X + v.Z * v.Z)
		if dh > 1.5 and dh > 0.2 * abs(v.Y) then yawTarget = atan2(-v.X, -v.Z) end
	end
	local psi, psiVel = yawTarget, 0
	if not CONFIG.VIEWER_ANCHOR then psi = yawW + pi end
	-- which palm drinks which stream: the void's stream goes to the hand on the viewer's right
	local assign = cos(psi - yawW) >= 0 and 1 or -1 -- 1: void -> right palm, moon -> left palm; -1: the other way round
	local function palmFor(side, carA) -- side 1 = the wearer's right hand
		local a = palmL
		if side > 0 then a = palmR end
		return a or carA
	end

	---------------------------------------------------------------- THE STREAMS (beams)
	local beams = {} -- { beam, faded transparency steps, written step, LE day, night, Br day, night, detail }
	local function beam(name, a0, a1, tex, mode, len, speed, w0, w1, c0, c1, color, le0, le1, br0, br1, tr, detail)
		local b = new("Beam", { Name = name, Attachment0 = a0, Attachment1 = a1, Texture = tex, TextureMode = mode, TextureLength = len,
			TextureSpeed = speed, Width0 = w0, Width1 = w1, CurveSize0 = c0, CurveSize1 = c1, Color = ColorSequence.new(color),
			LightEmission = le0, LightInfluence = 0, Brightness = br0, FaceCamera = true, Segments = 20, ZOffset = 0,
			Transparency = NumberSequence.new(1) }, holder("Fx", CORE))
		-- (the fade steps are made here, once: update only picks one)
		local steps = {}
		for q = 0, 10 do
			local pts = {}
			for _, p in ipairs(tr) do table.insert(pts, { p[1], 1 - (1 - p[2]) * q / 10 }) end
			steps[q] = seq(pts)
		end
		table.insert(beams, { b, steps, 0, le0, le1, br0, br1, detail })
		return b
	end
	local WRAP, STRETCH = Enum.TextureMode.Wrap, Enum.TextureMode.Stretch
	local moonA0, voidA0 = palmFor(-assign, moonCarA), palmFor(assign, voidCarA)
	-- STUDIO-VERIFY: Beam TextureSpeed direction: the streams must flow from the orb INTO the palm and the ribbon must flow
	-- down onto the dais (negate TextureSpeed if they run backwards)
	local trCore = { { 0, 0.15 }, { 0.12, 0.05 }, { 0.88, 0.05 }, { 1, 0.30 } }
	local B1 = beam("MoonCore", moonOut, moonA0, (T("stream")), WRAP, 5, 0.8, 1.4, 0.30, 4.0, 0, WHITE, 0, 0.45, 1.6, 2.4, trCore)
	local B2 = hi and beam("MoonFlow", moonOut, moonA0, TEX.streak, WRAP, 7, 1.6, 0.5, 0.15, 4.3, 0, WHITE, 0.3, 0.9, 2.0, 2.6,
		{ { 0, 0.4 }, { 0.15, 0.2 }, { 0.85, 0.2 }, { 1, 0.6 } }, true)
	local B3 = beam("VoidCore", voidOut, voidA0, (T("stream")), WRAP, 5, 0.7, 1.6, 0.35, 3.0, 0, Color3.fromRGB(18, 18, 24), 0, 0, 1.0, 1.0, trCore)
	local B4 = hi and beam("VoidCrackle", voidOut, voidA0, (T("line")), STRETCH, 1, 0, 0.14, 0.10, 2.6, 0, WHITE, 0.2, 0.8, 1.8, 2.4,
		{ { 0, 0.3 }, { 0.1, 0.1 }, { 0.9, 0.1 }, { 1, 0.5 } }, true)
	if hi then
		-- (the te5 ribbon carries its own ink body and white hairlines, so it needs a white Beam Color; the fallback line is inked)
		beam("Ribbon", ribbonOut, ribbonIn, (T("ribbon")), WRAP, 8, -0.5, 0.9, 2.2, 3.0, -5.0, isTe5("ribbon") and WHITE or RIBBON_INK,
			0, 0, 1.0, 1.0, { { 0, 0.2 }, { 0.1, 0.05 }, { 0.9, 0.05 }, { 1, 0.3 } })
		beam("RibbonEdge", ribbonOut, ribbonIn, (T("line")), STRETCH, 1, 0, 0.12, 0.12, 3.3, -5.3, WHITE, 0.2, 0.8, 1.8, 2.4,
			{ { 0, 0.3 }, { 0.1, 0.1 }, { 0.9, 0.1 }, { 1, 0.4 } }, true)
	end

	---------------------------------------------------------------- THE PARTICLES: every system has a job and a path
	local emitters = {} -- { emitter, on time, kind, live, written Enabled }
	local emitNight = {} -- { emitter, LE day, LE night, Br day, Br night }
	local function pe(parent, key, tOn, props, le, br, kind)
		local p = Instance.new("ParticleEmitter")
		local id, layout, mode = T(key)
		p.Texture = id
		p.FlipbookLayout = Enum.ParticleFlipbookLayout[layout]
		if layout ~= "None" then p.FlipbookMode = Enum.ParticleFlipbookMode[mode] end
		p.LightInfluence = 0
		p.VelocityInheritance = 0
		p.Color = ColorSequence.new(WHITE)
		p.Speed = n(0)
		p.Rotation = n(0)
		p.RotSpeed = n(0)
		p.Enabled = false
		local sz = props.Size
		if typeof(sz) == "NumberRange" then -- (a size range: a steady size with a random spread)
			local v, e = (sz.Min + sz.Max) / 2, (sz.Max - sz.Min) / 2
			props.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, v, e), NumberSequenceKeypoint.new(1, v, e) })
		end
		for k, v in pairs(props) do p[k] = v end
		p.LightEmission = le and le[1] or 0
		p.Brightness = br and br[1] or 1
		if le or br then table.insert(emitNight, { p, le and le[1] or 0, le and le[2] or 0, br and br[1] or 1, br and br[2] or 1 }) end
		p.Parent = parent
		table.insert(emitters, { p, tOn, kind, false, false })
		return p
	end
	local function rate(h, l) return low and l or h end
	local SPHERE, CYL, DISCSHAPE, BOX = Enum.ParticleEmitterShape.Sphere, Enum.ParticleEmitterShape.Cylinder, Enum.ParticleEmitterShape.Disc,
		Enum.ParticleEmitterShape.Box
	local SURFACE, VOLUME = Enum.ParticleEmitterShapeStyle.Surface, Enum.ParticleEmitterShapeStyle.Volume
	local INWARD, OUTWARD = Enum.ParticleEmitterShapeInOut.Inward, Enum.ParticleEmitterShapeInOut.Outward
	local VPAR = Enum.ParticleOrientation.VelocityParallel
	local N_ = Enum.NormalId
	local WHITE_LE, WHITE_BR = { 0.3, 0.9 }, { 1.6, 2.4 }
	-- P1: matter spirals in along the accretion disc and vanishes into the black core (straight inward motion inside a
	-- spinning host becomes a spiral). STUDIO-VERIFY: Cylinder + Surface + Inward emits on the curved side toward the axis,
	-- and LockedToPart particles ride a host moved by BulkMoveTo
	pe(swirlHost, "mote", 1.2, { Shape = CYL, ShapeStyle = SURFACE, ShapeInOut = INWARD, EmissionDirection = N_.Top, Rate = rate(34, 12),
		Lifetime = n(1.1, 1.3), Speed = n(2.2, 2.6), Size = seq({ { 0, 0.55 }, { 1, 0.18 } }),
		Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.8, 0.05 }, { 1, 0.4 } }),
		Color = ColorSequence.new(WHITE, Color3.fromRGB(170, 174, 184)), LockedToPart = true, ZOffset = 0.3 }, WHITE_LE, WHITE_BR)
	-- P2: dust snows off the moon and falls away below it
	pe(moon, "mote", 1.6, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = rate(12, 5), Lifetime = n(3.0, 4.5),
		Speed = n(0.25, 0.6), Acceleration = Vector3.new(0, -1.1, 0), Drag = 0.4, Size = seq({ { 0, 0.14 }, { 0.2, 0.4, 0.12 }, { 1, 0.14 } }),
		Transparency = seq({ { 0, 1 }, { 0.12, 0.08 }, { 0.75, 0.15 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(238, 240, 246)),
		Rotation = n(0, 360), RotSpeed = n(-30, 30) }, { 0.2, 0.7 }, { 1.4, 2.2 })
	if hi then
		-- P3: metal shards break off the bezel at eleven and fly across the face into the void (tumbling flipbook)
		local shardScale = isTe5("shards5") and 1.3 or 1 -- (the te5 sliver fills about half its cell)
		pe(shardFeed, "shards5", 4.8, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Front, Rate = 5, Lifetime = n(2.9, 3.2),
			Speed = n(8.5, 9.5), SpreadAngle = Vector2.new(6, 6),
			Size = seq({ { 0, 0.6 * shardScale }, { 0.85, 0.9 * shardScale, 0.12 * shardScale }, { 1, 0.35 * shardScale } }),
			Transparency = seq({ { 0, 1 }, { 0.06, 0 }, { 0.9, 0 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(214, 218, 226)),
			Rotation = n(0, 360), RotSpeed = n(-120, 120), FlipbookFramerate = n(10, 14), FlipbookStartRandom = true }, { 0, 0.3 }, { 1, 1.6 })
	end
	-- P4: two-tone smoke curls off the rim: ink on the void side, silver on the moon side, drifting back and up
	pe(smokeVoid, "smoke5", 3.2, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Right, Rate = rate(7, 3), Lifetime = n(3.5, 4.5),
		Speed = n(0.6, 1.2), SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, 0.5, 0), Drag = 0.3,
		Size = seq({ { 0, 3 }, { 1, 7.5 } }), Transparency = seq({ { 0, 1 }, { 0.2, 0.30 }, { 0.7, 0.45 }, { 1, 1 } }),
		Color = ColorSequence.new(SMOKE), Rotation = n(0, 360), RotSpeed = n(-20, 20) })
	if hi then
		pe(smokeMoon, "smoke5", 3.2, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Left, Rate = 5, Lifetime = n(3.5, 4.5),
			Speed = n(0.6, 1.2), SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, 0.5, 0), Drag = 0.3,
			Size = seq({ { 0, 3 }, { 1, 7 } }), Transparency = seq({ { 0, 1 }, { 0.2, 0.45 }, { 0.7, 0.6 }, { 1, 1 } }),
			Color = ColorSequence.new(Color3.fromRGB(196, 200, 210)), Rotation = n(0, 360), RotSpeed = n(-20, 20) }, { 0.1, 0.4 })
	end
	-- P5: slow four-point glints bloom on the bezel metal and fade (grow, hold, shrink: never a flash).
	-- STUDIO-VERIFY: Disc ShapePartial = the inner-radius fraction (0.86 -> the annulus over the bezel), oriented by EmissionDirection
	local glintT = seq({ { 0, 0.1 }, { 1, 0.1 } })
	pe(rimGlint, "glint5", 3.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.86, EmissionDirection = N_.Back, Rate = rate(3, 1.2),
		Lifetime = n(1.6, 2.2), Size = seq({ { 0, 0 }, { 0.35, 1.3, 0.35 }, { 0.65, 1.3, 0.35 }, { 1, 0 } }), Transparency = glintT,
		LockedToPart = true, ZOffset = 1.0, Rotation = n(0, 90) }, { 0.5, 1 }, WHITE_BR)
	if hi then
		for _, seg in ipairs({ meridian[0], meridian[9] }) do
			pe(seg, "glint5", 3.8, { Shape = BOX, ShapeStyle = VOLUME, Rate = 0.4, Lifetime = n(1.6, 2.2),
				Size = seq({ { 0, 0 }, { 0.35, 0.9, 0.25 }, { 0.65, 0.9, 0.25 }, { 1, 0 } }), Transparency = glintT, LockedToPart = true,
				ZOffset = 0.5, Rotation = n(0, 90) }, { 0.5, 1 }, WHITE_BR)
		end
	end
	-- P6: three scales of air: fine silver dust, mid glints, and big slow bokeh between the camera and the wearer
	pe(air, "mote", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(26, 10), Lifetime = n(6, 9), Speed = n(0.1, 0.3),
		SpreadAngle = Vector2.new(180, 180), Size = n(0.1, 0.26), Transparency = seq({ { 0, 1 }, { 0.2, 0.1 }, { 0.8, 0.15 }, { 1, 1 } }),
		Color = ColorSequence.new(Color3.fromRGB(226, 230, 240)) }, { 0.2, 0.8 }, { 1.4, 2.2 })
	pe(air, "glint5", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(5, 1.5), Lifetime = n(4, 6), Speed = n(0.2, 0.5),
		SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.3, 0.7, 0.2 }, { 0.7, 0.7, 0.2 }, { 1, 0 } }),
		Transparency = seq({ { 0, 1 }, { 0.3, 0.1 }, { 0.7, 0.1 }, { 1, 1 } }), Rotation = n(0, 90), RotSpeed = n(-20, 20) }, { 0.4, 1 }, WHITE_BR)
	local bokeh = hi and pe(bokehHost, "bokeh", 3.0, { Shape = BOX, ShapeStyle = VOLUME, Rate = 0.5, Lifetime = n(5, 7), Speed = n(0.1, 0.25),
		SpreadAngle = Vector2.new(180, 180), Size = n(1.2, 2.4), Transparency = seq({ { 0, 1 }, { 0.25, 0.72 }, { 0.75, 0.72 }, { 1, 1 } }),
		Color = ColorSequence.new(Color3.fromRGB(232, 236, 246)), Rotation = n(0, 360), RotSpeed = n(-4, 4) }, { 0.3, 0.8 }, { 1.2, 1.8 }, "bokeh")
	if hi then
		-- P7: one low mist bank at the ankles, only while standing on the ground
		pe(floor, "smoke5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, EmissionDirection = N_.Top, Rate = 2.5, Lifetime = n(6, 8),
			Speed = n(0.1, 0.25), Size = seq({ { 0, 8 }, { 1, 14 } }), Transparency = seq({ { 0, 1 }, { 0.3, 0.80 }, { 0.7, 0.82 }, { 1, 1 } }),
			Color = ColorSequence.new(MIST), LockedToPart = true, Rotation = n(0, 360), RotSpeed = n(-6, 6) }, nil, nil, "ground")
	end
	-- P8: motes rise off the turning arms and swirl with them; black ash flakes rise against them
	pe(floor, "mote", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top, Rate = rate(18, 8),
		Lifetime = n(2.6, 3.6), Speed = n(0.5, 1.2), Acceleration = Vector3.new(0, 0.35, 0), Drag = 0.2,
		Size = seq({ { 0, 0 }, { 0.2, 0.42, 0.12 }, { 1, 0 } }), Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.8, 0.15 }, { 1, 1 } }),
		LockedToPart = true, ZOffset = 0.2 }, WHITE_LE, WHITE_BR)
	if hi then
		-- STUDIO-VERIFY: te5_ash is 256² with a 2x2 flipbook; Roblox may only animate flipbooks on 1024² textures
		pe(floor, "ash5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top, Rate = 7,
			Lifetime = n(3, 4.5), Speed = n(0.8, 2.0), Acceleration = Vector3.new(0, 0.3, 0), Drag = 0.4, Size = n(0.4, 0.6),
			Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.75, 0.2 }, { 1, 1 } }), Color = ColorSequence.new(ASH), Rotation = n(0, 360),
			RotSpeed = n(-90, 90) })
		-- P9: a vortex funnel: streaks spiral inward and climb into the balance wheel.
		-- STUDIO-VERIFY: te5_streak assumes VelocityParallel puts the texture's TOP along the velocity (flip the PNG if not)
		pe(funnel, "streak5", 4.8, { Shape = CYL, ShapeStyle = SURFACE, ShapeInOut = INWARD, EmissionDirection = N_.Top, Rate = 16,
			Lifetime = n(1.7, 2.0), Speed = n(2.8, 3.2), Acceleration = Vector3.new(0, 1.0, 0), Size = seq({ { 0, 0.42 }, { 1, 0.1 } }),
			Transparency = seq({ { 0, 1 }, { 0.12, 0.05 }, { 0.85, 0.1 }, { 1, 1 } }), LockedToPart = true, Orientation = VPAR }, WHITE_LE, WHITE_BR)
	end
	-- P10: the palms drink the streams: silver motes converge into one palm, ink motes into the other.
	-- STUDIO-VERIFY: Sphere + Surface + Inward converges on the centre (fallback: Outward with a negative Speed)
	local function intake(host, color, le, br)
		pe(host, "streak5", 5.2, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = INWARD, Rate = rate(14, 6), Lifetime = n(0.85, 0.95),
			Speed = n(1.35, 1.45), Size = seq({ { 0, 0.3 }, { 1, 0.05 } }), Transparency = seq({ { 0, 1 }, { 0.25, 0.05 }, { 1, 0.2 } }),
			Color = ColorSequence.new(color), ZOffset = 0.2, Orientation = VPAR }, le, br)
	end
	intake(palmMoon, WHITE, WHITE_LE, WHITE_BR)
	intake(palmVoid, INK, nil, nil)
	-- P11: time drips off each sole onto the balance wheel below
	for _, a in ipairs({ soleL, soleR }) do
		if a then
			pe(a, "mote", 5.2, { EmissionDirection = N_.Bottom, Rate = rate(4, 2), Lifetime = n(0.6, 0.8), Speed = n(0.1, 0.3),
				SpreadAngle = Vector2.new(8, 8), Acceleration = Vector3.new(0, -5, 0), Size = seq({ { 0, 0.18 }, { 1, 0.08 } }),
				Transparency = seq({ { 0, 0.1 }, { 0.8, 0.2 }, { 1, 1 } }) }, WHITE_LE, WHITE_BR, "foot")
		end
	end
	table.sort(emitters, function(a, b) return a[2] < b[2] end)

	-- lights: the moon's key light (lights its top and rims the wearer) and the wheel's underlight on the feet (night only)
	local wheelLight = hi and new("PointLight", { Name = "Underlight", Range = 12, Color = Color3.fromRGB(230, 234, 246), Brightness = 0,
		Shadows = false, Enabled = false }, wheelHub)

	---------------------------------------------------------------- the move list (one BulkMoveTo per frame)
	local act, actParts, acf = table.create(NP), table.create(NP), table.create(NP)
	local nAct = 0
	local function rebuildActive()
		table.clear(act)
		table.clear(actParts)
		table.clear(acf)
		nAct = 0
		for i = 1, NP do
			if shownH[PH[i]] then
				nAct += 1
				act[nAct], actParts[nAct], acf[nAct] = i, PP[i], IDENT
			end
		end
	end
	rebuildActive()

	---------------------------------------------------------------- the wearer's own screen grade (real equips only)
	local grade, gradeIn, gradeOut, gradeConn
	if CONFIG.GRADE and ctx.isLocal and os.clock() - (spawnedAt[char] or 0) > 4 and workspace.CurrentCamera then
		grade = new("ColorCorrectionEffect", { Name = "TheEndReveal" }, workspace.CurrentCamera)
		gradeIn = TweenService:Create(grade, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Saturation = -0.75, Brightness = -0.1, Contrast = 0.15, TintColor = Color3.fromRGB(232, 238, 255) })
		gradeIn:Play()
		task.delay(5.8, function()
			if destroyed or not (grade and grade.Parent) then return end
			gradeOut = TweenService:Create(grade, TweenInfo.new(2.2, Enum.EasingStyle.Sine), { Saturation = 0, Brightness = 0, Contrast = 0,
				TintColor = Color3.new(1, 1, 1) })
			gradeConn = gradeOut.Completed:Connect(function()
				if grade then
					grade:Destroy()
					grade = nil
				end
			end)
			gradeOut:Play()
		end)
	end

	---------------------------------------------------------------- state
	local fx = {}
	local remote = not ctx.isLocal
	local age = (CONFIG.ASSEMBLY and (CONFIG.ASSEMBLY_REMOTE or not remote)) and 0 or ASM_END
	local VIEWER = CONFIG.VIEWER_ANCHOR
	local near, visible, armHidden, bokehNear, grounded = true, true, false, false, true
	local alphaW, alphaOn, settled = -1, false, false
	local nq, nightClock = -1, 0
	local nextEmit = 1
	local accExtra, voidD = 0, (age >= ASM_END) and 8 or 0.6
	local rt = 3.9
	local daisY, lastGroundY = nil, nil
	local ltmOn = false
	local hlF, hlO = -1, -1
	local dir = 1 -- (the accretion texture's streaks wind clockwise outward, so a counter-clockwise turn makes them trail)
	local SHARD_A = {}
	for i = 0, 7 do SHARD_A[i] = rad(300 + 20 * i) end
	local FEED_PT = Vector3.new(-10.72, 9.00, 0)
	if age >= ASM_END then void.Size = voidSize else void.Size = voidSize * (0.6 / 8) end

	---------------------------------------------------------------- event writes (never per frame in steady state)
	local function refreshEmitters()
		for _, e in ipairs(emitters) do
			local want = e[4] and near and alphaOn
			local kind = e[3]
			if kind == "ground" then want = want and grounded
			elseif kind == "bokeh" then want = want and not bokehNear
			elseif kind == "foot" then want = want and visible end -- (they live on the character, outside our model)
			if want ~= e[5] then
				e[1].Enabled = want
				e[5] = want
			end
		end
	end
	local keyOn, wheelOn, detailBeams = false, false, true
	local function refreshLights()
		local on = near and alphaOn and visible and nq > 0
		if (on and age >= 0.6) ~= keyOn then
			keyOn = not keyOn
			keyLight.Enabled = keyOn
		end
		if wheelLight and (on and age >= 4.6) ~= wheelOn then
			wheelOn = not wheelOn
			wheelLight.Enabled = wheelOn
		end
		if near ~= detailBeams then
			detailBeams = near
			for _, b in ipairs(beams) do
				if b[8] then b[1].Enabled = near end
			end
		end
	end
	local function setGroups()
		local changed = false
		for h = 1, 4 do
			local show = not (hideD[h] and not near) and not (hideA[h] and armHidden)
			if show ~= shownH[h] then
				shownH[h] = show
				changed = true
				for _, hp in ipairs(holders[h]) do hp[1].Parent = show and hp[2] or nil end
			end
		end
		if changed then rebuildActive() end
	end
	-- day/night: every glowing value blends with the night factor, written only when the quantised factor changes
	local function applyNight(q)
		nq = q
		for _, b in ipairs(brights) do b[1].Brightness = b[2] + (b[3] - b[2]) * q end
		for _, e in ipairs(emitNight) do
			e[1].LightEmission = e[2] + (e[3] - e[2]) * q
			e[1].Brightness = e[4] + (e[5] - e[4]) * q
		end
		for _, b in ipairs(beams) do
			b[1].LightEmission = b[4] + (b[5] - b[4]) * q
			b[1].Brightness = b[6] + (b[7] - b[6]) * q
		end
		keyLight.Brightness = 1.5 * q
		if wheelLight then wheelLight.Brightness = 0.9 * q end
		if bokeh then bokeh.Rate = 0.5 + 0.7 * q end
		haloEntry[2] = 0.65 - 0.2 * q
		if corona then
			coronaEntry[2] = 1 - 0.4 * q
			corona.Enabled = q > 0.05
		end
		if settled then
			-- (after the assembly the night values are written straight away; during it the fades pick them up)
			local a = alphaW
			local tr = 1 - (1 - haloEntry[2]) * a
			if tr ~= haloEntry[5] then
				haloIm.ImageTransparency = tr
				haloEntry[5] = tr
			end
			if coronaEntry then
				tr = 1 - (1 - coronaEntry[2]) * a
				if tr ~= coronaEntry[5] then
					coronaEntry[1].ImageTransparency = tr
					coronaEntry[5] = tr
				end
			end
			if tone then
				hlF, hlO = 1 - (0.45 - 0.25 * q) * a, 1 - (0.65 - 0.35 * q) * a
				tone.FillTransparency, tone.OutlineTransparency = hlF, hlO
			end
		end
		refreshLights()
	end
	-- the fades: every part, image and beam goes from invisible to its rest value in its own window (times the framework's
	-- fade-in alpha); a value is written only when it moved enough, and snapped exactly at the ends (no blinking)
	local function fadeAll(a, asm, thr)
		for _, i in ipairs(solids) do
			local f = a
			if asm then
				local u = (age - PF0[i]) / (PF1[i] - PF0[i])
				f *= u <= 0 and 0 or u >= 1 and 1 or u * u * (3 - 2 * u)
			end
			local tr = 1 - f
			local cur = PCUR[i]
			if tr ~= cur and (abs(tr - cur) >= thr or tr <= 0 or tr >= 1) then
				PP[i].Transparency = tr
				PCUR[i] = tr
			end
		end
		for _, e in ipairs(images) do
			local f = a
			if asm then f *= smooth((age - e[3]) / (e[4] - e[3])) end
			local tr = 1 - (1 - e[2]) * f
			if tr ~= e[5] and (abs(tr - e[5]) >= thr or f <= 0 or f >= 1) then
				e[1].ImageTransparency = tr
				e[5] = tr
			end
		end
		local fb = a
		if asm then fb *= smooth((age - 4.6) / 0.8) end
		local q = math.floor(fb * 10 + 0.5)
		for _, b in ipairs(beams) do
			if q ~= b[3] then
				b[1].Transparency = b[2][q]
				b[3] = q
			end
		end
		if tone then
			local fh = a
			if asm then fh *= smooth((age - 3.6) / 0.6) end
			local fill, out = 1 - (0.45 - 0.25 * max(nq, 0)) * fh, 1 - (0.65 - 0.35 * max(nq, 0)) * fh
			if abs(fill - hlF) >= thr or (fh >= 1 and fill ~= hlF) or (fh <= 0 and fill ~= hlF) then
				tone.FillTransparency = fill
				tone.OutlineTransparency = out
				hlF, hlO = fill, out
			end
		end
	end

	---------------------------------------------------------------- the frame
	function fx.update(dt, s)
		if destroyed then return end
		if dt > 0.1 then dt = 0.1 end
		age += dt
		local asm = age < ASM_END
		local t, now, g = s.t, s.now, s.glide
		local cf = s.cf
		local O = cf.Position + Vector3.new(0, s.hover, 0)

		-- 1. frames: the wearer (W), this client's viewer (V), the clock (K)
		local lv = cf.LookVector
		yawW = wrapPi(yawW + wrapPi(atan2(-lv.X, -lv.Z) - yawW) * (1 - exp(-5 * dt)))
		local W = CFrame.new(O) * CFrame.Angles(0, yawW, 0)
		local cam = workspace.CurrentCamera
		local camPos = lastCamPos
		if cam then
			camPos = cam.CFrame.Position
			lastCamPos = camPos
		end
		local V
		if VIEWER then
			-- the clock swings to the far side of the wearer from this camera through a critically damped spring (no overshoot);
			-- it holds still when the camera is inside the wearer (first person) or straight above
			local v = O - camPos
			local dh = sqrt(v.X * v.X + v.Z * v.Z)
			if dh > 1.5 and dh > 0.2 * abs(v.Y) then yawTarget = atan2(-v.X, -v.Z) end
			local k = CONFIG.YAW_SPRING
			local x = wrapPi(psi - yawTarget)
			local e = exp(-k * dt)
			local tmp = (psiVel + k * x) * dt
			x = (x + tmp) * e
			psiVel = (psiVel - k * tmp) * e
			psi = wrapPi(yawTarget + x)
			if psi ~= psi or psiVel ~= psiVel then psi, psiVel = yawTarget, 0 end
			V = CFrame.new(O) * CFrame.Angles(0, psi, 0)
		else
			V = W * FLIP
		end
		local K = V * CFrame.new(0, CONFIG.CLOCK_HEIGHT - 0.5 * g, -(CONFIG.CLOCK_DIST + 2 * g))
			* CFrame.Angles(0, rad(9 + 5 * sin(TAU * t / 16)), 0) * CFrame.Angles(-rad(CONFIG.CLOCK_TILT + 14 * g), 0, 0)
		GCF[GK] = K

		-- 2. the clockwork: gears (meshed rates from the server clock), hands, crown
		for _, gd in ipairs(gearData) do
			local x, y, z = gd.cx, gd.cy, gd.cz
			if asm then
				-- spin up fast and wind down to the running pace (an integrated extra angle, so nothing jumps)
				gd.extra = (gd.extra + rad((gd.sign * 300 - gd.rate) * exp(-4 * max(0, age - gd.a0))) * dt) % TAU
				local u = (age - gd.a0) / (gd.a1 - gd.a0)
				if u < 1 then
					local kk = 1 - easeOutBack(u)
					x, y, z = x + (gd.sx - x) * kk, y + (gd.sy - y) * kk, z + (gd.sz - z) * kk
				end
			end
			GCF[gd.grp] = K * CFrame.new(x, y, z) * CFrame.Angles(0, 0, -((rad(gd.rate) * now + gd.extra) % TAU))
		end
		local th, tm, ts = 0, 0, rad(6 * (now % 60))
		local crownY = 0
		if asm then
			local kk = 1 - easeOutBack((age - 3.6) / 1.2)
			th, tm, ts = -rad(330) * kk, -rad(1050) * kk, ts - rad(720) * kk
			crownY = 6 * (1 - easeOutBack((age - 4.2) / 0.6))
		end
		GCF[GHOUR] = K * CFrame.Angles(0, 0, -th) * CFrame.new(0, 0, 0.85)
		GCF[GMIN] = K * CFrame.Angles(0, 0, -tm) * CFrame.new(0, 0, 1.15)
		GCF[GSEC] = K * CFrame.Angles(0, 0, -ts) * CFrame.new(0, 0, 1.42)
		GCF[GCROWN] = crownY ~= 0 and K * CFrame.new(0, crownY, 0) or K

		-- 3. the dais: stays on the ground for walks and jumps, floats under a flyer
		local feetY = cf.Position.Y - s.legLen
		local gnd = s.ground
		local isGrounded = gnd ~= nil and (feetY - gnd.Y) < 7
		local target
		if isGrounded then
			target = gnd.Y
			lastGroundY = target
		elseif CONFIG.DAIS_FLOAT or not lastGroundY then
			target = feetY + s.hover - 2.4
		else
			target = lastGroundY
		end
		daisY = daisY and daisY + (target - daisY) * (1 - exp(-8 * dt)) or target
		local Gd = CFrame.new(O.X, daisY, O.Z)
		GCF[GDAIS] = Gd
		GCF[GG0] = Gd * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, (rad(-6) * now) % TAU, 0)
		GCF[GG1] = Gd * CFrame.new(0, 0.42, 0) * CFrame.Angles(0, (rad(9) * now) % TAU, 0)
		GCF[GG2] = Gd * CFrame.new(0, 0.66, 0) * CFrame.Angles(0, (rad(-16) * now) % TAU, 0)
		GCF[GENG] = Gd * CFrame.new(0, 0.04, 0) * CFrame.Angles(0, (rad(2.5) * now) % TAU, 0)
		GCF[GFUNNEL] = Gd * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, (rad(-70) * t) % TAU, 0)
		local wheelAngle = rad(160) * sin(TAU * t / 3.2) * (asm and smooth((age - 4.6) / 1.2) or 1)
		local Bw = CFrame.new(O.X, O.Y - s.legLen - 0.35, O.Z) * CFrame.Angles(0, wheelAngle, 0)
		GCF[GWHEEL] = Bw
		GCF[GHAIR] = Bw * CFrame.new(0, 0.22, 0) * CFrame.Angles(0, -0.5 * wheelAngle, 0)

		-- 4. the armillary (body-anchored, leaning with the glide); on equip each ring rises from lying flat on the dais
		local A0 = W * CFrame.new(0, 1.3, 0) * CFrame.Angles(-rad(18 * g), 0, 0)
		local F1 = A0 * CFrame.Angles(0, (rad(8) * t) % TAU, 0) * TILT33
		local F2 = F1 * CFrame.Angles(rad(57) + rad(18) * sin(TAU * t / 19), 0, 0)
		local F3 = F2 * CFrame.Angles(0, rad(23.4) + rad(14) * sin(TAU * t / 27 + 1.1), 0)
		GCF[GF1], GCF[GF2], GCF[GF3] = F1, F2, F3
		if asm then
			local flat = Gd * FLAT
			if age < 2.4 then GCF[GF1] = lerpCF(flat, F1, easeOutBack((age - 1.0) / 1.4)) end
			if age < 2.7 then GCF[GF2] = lerpCF(flat, F2, easeOutBack((age - 1.3) / 1.4)) end
			if age < 3.0 then GCF[GF3] = lerpCF(flat, F3, easeOutBack((age - 1.6) / 1.4)) end
		end
		if hi then
			for i = 0, 7 do
				local c = F3 * CFrame.Angles(0, 0, -((rad(i * 45 + 22.5) + rad(22) * t) % TAU)) * CFrame.new(0, 4.0, 0)
					* CFrame.Angles((t * rad(50 + 15 * i)) % TAU, (t * rad(35 - 7 * i)) % TAU, 0)
				if asm then
					local u = (age - 5.0 - 0.06 * i) / 0.8
					if u < 1 then
						local a = SHARD_A[i]
						local sp = K * Vector3.new(14 * sin(a), 14 * cos(a), 0)
						c = CFrame.new(sp + (c.Position - sp) * easeOutBack(u)) * c.Rotation
					end
				end
				GCF[GSHARD + 1 + i] = c
			end
		end

		-- 5. the balance: moon and void on the viewer's left and right of an invisible beam, rocking like scales
		local sway = asm and smooth((age - 1.8) / 1.2) or 1
		local Pv = V * CFrame.new(0, 6.0, 1.5) * CFrame.Angles(0, 0, rad(10) * sin(TAU * t / 10) * sway)
		local moonC = Pv * Vector3.new(-12.5, 0, 0)
		local voidC = Pv * Vector3.new(12.5, 0, 0)
		local focus = O + Vector3.new(0, 1, 0)
		if asm and age < 1.8 then
			local sp = V * Vector3.new(-12.5, -9, 1.5) -- (the moon rises out of the dais)
			moonC = sp + (moonC - sp) * easeOutBack((age - 0.6) / 1.2)
		end
		GCF[GMOON] = CFrame.lookAt(moonC, focus)
		GCF[GVOID] = CFrame.lookAt(voidC, focus)
		-- the void's camera-facing details: the photon ring sits on the silhouette circle the camera sees (radius rt)
		local dv = camPos - voidC
		local dm = dv.Magnitude
		local nrm = dm > 1e-3 and dv / dm or -V.LookVector
		local dc = max(dm, 5)
		local up = abs(nrm.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis
		rt = 4 * sqrt(1 - 16 / (dc * dc))
		GCF[GPF] = CFrame.lookAt(voidC + nrm * (16 / dc), voidC, up)
		GCF[GHF] = CFrame.lookAt(voidC + nrm * 4.1, voidC, up)
		local Dk = CFrame.new(voidC) * V.Rotation * TILT15
		if asm then accExtra = (accExtra + rad(360 * exp(-3 * max(0, age - 0.3))) * dt * dir) % TAU end
		GCF[GACC] = Dk * CFrame.Angles(0, (rad(40) * now * dir + accExtra) % TAU, 0)
		GCF[GSWIRL] = Dk * CFrame.Angles(0, (rad(85) * now * dir) % TAU, 0)
		local az = atan2(voidC.X - O.X, voidC.Z - O.Z)
		GCF[GRIBEND] = Gd * CFrame.new(13.2 * sin(az), 0.3, 13.2 * cos(az)) * CFrame.Angles(0, az, 0)
		GCF[GFEED] = CFrame.lookAt(K * FEED_PT, voidC)

		-- 6. the air and the palms
		local camDist = (camPos - O).Magnitude
		GCF[GAIR] = CFrame.new(O + Vector3.new(0, 4, 0))
		GCF[GBOKEH] = V * CFrame.new(0, 3.0, min(7.5, camDist - 4))
		local f = W.RightVector:Dot(V.RightVector)
		local flip = (f > 0.2 and assign ~= 1) and 1 or (f < -0.2 and assign ~= -1) and -1 or nil
		if flip then assign = flip end
		local moonSide = -assign
		local mA, vA = palmFor(moonSide, moonCarA), palmFor(-moonSide, voidCarA)
		GCF[GPALMM] = mA ~= moonCarA and CFrame.new(mA.WorldPosition) or W * CFrame.new(2.3 * moonSide, -0.3, -0.5)
		GCF[GPALMV] = vA ~= voidCarA and CFrame.new(vA.WorldPosition) or W * CFrame.new(-2.3 * moonSide, -0.3, -0.5)

		-- 7. every part = its group's frame x its rest transform (eased from its start pose while it assembles)
		for j = 1, nAct do
			local i = act[j]
			local L = PL[i]
			local rr = PRR[i]
			if rr then L = PROT[i] * CFrame.new(0, rt + rr, 0) end
			if asm then
				local S = PS[i]
				if S and age < PM1[i] then
					local kk = 1 - easeOutBack((age - PM0[i]) / (PM1[i] - PM0[i]))
					if rr then
						local r0 = PRS[i] or (rt + PRSO[i])
						L = PROT[i] * CFrame.new(0, rt + rr + (r0 - rt - rr) * kk, 0)
					else
						L = lerpCF(L, S, kk)
					end
				end
			end
			acf[j] = GCF[PG[i]] * L
		end
		workspace:BulkMoveTo(actParts, acf, Enum.BulkMoveMode.FireCFrameChanged)

		-- 8. event writes only
		if flip then
			B1.Attachment1 = mA
			if B2 then B2.Attachment1 = mA end
			B3.Attachment1 = vA
			if B4 then B4.Attachment1 = vA end
		end
		local a = s.alpha
		local on = a >= 0.6
		if on ~= alphaOn then
			alphaOn = on
			refreshEmitters()
			refreshLights()
		end
		if asm then
			-- the void condenses out of a point (Size writes on this one part, during the assembly only)
			local d = 0.6 + 7.4 * easeOutBack(age / 1.2)
			if abs(d - voidD) >= 0.01 or (d == 8 and voidD ~= 8) then
				voidD = d
				void.Size = voidSize * (d / 8)
			end
			fadeAll(a, true, 0.03)
			alphaW = a
			-- the emitters switch on in turn as their part of the machine locks in
			local e = emitters[nextEmit]
			if e and age >= e[2] then
				while e and age >= e[2] do
					e[4] = true
					nextEmit += 1
					e = emitters[nextEmit]
				end
				refreshEmitters()
				refreshLights()
			end
		elseif not settled or a ~= alphaW then
			-- the assembly has ended (snap everything to rest) or the framework is fading the aura out
			if not settled then
				settled = true
				if voidD ~= 8 then
					voidD = 8
					void.Size = voidSize
				end
				for _, e in ipairs(emitters) do e[4] = true end
				nextEmit = #emitters + 1
				refreshEmitters()
				refreshLights()
				fadeAll(a, false, 0.03)
			else
				fadeAll(a, false, 0.04)
			end
			alphaW = a
		end
		-- near-camera rules (with hysteresis): no rings or bokeh blobs across the lens
		if CONFIG.NEAR_HIDE then
			local dA = (camPos - A0.Position).Magnitude
			if (not armHidden and dA < 7) or (armHidden and dA > 8) then
				armHidden = not armHidden
				setGroups()
			end
			if (not bokehNear and camDist < 9) or (bokehNear and camDist > 10) then
				bokehNear = not bokehNear
				refreshEmitters()
			end
		end
		if isGrounded ~= grounded then
			grounded = isGrounded
			refreshEmitters()
		end
		-- body-anchored fallback: the owner sees through the clock while it stands between the camera and the head
		if not VIEWER and ctx.isLocal then
			local head = O + Vector3.new(0, 2, 0)
			local nz = K.LookVector
			local d0, d1 = (camPos - K.Position):Dot(nz), (head - K.Position):Dot(nz)
			local cross = false
			if d0 * d1 < 0 then
				local hit = camPos + (head - camPos) * (d0 / (d0 - d1))
				cross = (hit - K.Position).Magnitude < 14
			end
			if cross ~= ltmOn then
				ltmOn = cross
				for _, p in ipairs(clockParts) do p.LocalTransparencyModifier = cross and 0.5 or 0 end
			end
		end
		nightClock += dt
		if nightClock >= CONFIG.NIGHT_INTERVAL then
			nightClock = 0
			local q = nightStep()
			if q ~= nq then
				-- (at most 0.05 per tick, so dusk never steps)
				if q > nq + 0.05 then q = math.floor((nq + 0.05) * 20 + 0.5) / 20
				elseif q < nq - 0.05 then q = math.floor((nq - 0.05) * 20 + 0.5) / 20 end
				applyNight(q)
			end
		end
	end

	function fx.setVisible(on)
		if destroyed then return end
		visible = on
		root.Parent = on and ctx.container or nil
		refreshEmitters()
		refreshLights()
	end

	function fx.setDetail(isNear)
		if destroyed then return end
		near = isNear
		setGroups()
		refreshEmitters()
		refreshLights()
	end

	function fx.destroy()
		if destroyed then return end
		destroyed = true
		root:Destroy()
		if gradeConn then gradeConn:Disconnect() end
		if gradeIn then gradeIn:Cancel() end
		if gradeOut then gradeOut:Cancel() end
		if grade then
			grade:Destroy()
			grade = nil
		end
		for _, o in ipairs(charStuff) do o:Destroy() end
		table.clear(charStuff)
		table.clear(act)
		table.clear(actParts)
		table.clear(acf)
		nAct = 0
	end

	applyNight(nightStep())
	root.Parent = ctx.container
	if CONFIG.DEBUG then
		local nb, ng = 0, 0
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then ng += 1 elseif d:IsA("Beam") then nb += 1 end
		end
		print(string.format("TheEnd: %d parts (%d moved), %d emitters, %d GUIs, %d beams", NP, nAct, #emitters, ng, nb))
	end
	return fx
end

return End
