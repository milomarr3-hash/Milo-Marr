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
-- "rbxassetid://123", "123" and the number 123 all work. Until a key is filled in (or if its upload fails to load in the
-- game) it falls back to a pass-4 texture (FALLBACK), so the aura always looks complete.
local TEX5 = {
	dialInlay = "", subdial = "", accretion = "", galaxyFloor = "", galaxyArms = "", galaxyCore = "", engraving = "",
	halo = "", stream = "", ribbon = "", moon = "", starWindow = "",
	shards5 = "", smoke5 = "", mote = "", glint5 = "", bokeh = "", streak5 = "", ash5 = "",
}
-- (te5_ash is one 256² flake: random rotation and spin vary it, and it costs a quarter of a 1024² flipbook sheet)
local TEX5_LAYOUT = { shards5 = { "Grid4x4", "Loop" }, smoke5 = { "Grid4x4", "OneShot" } }
local FALLBACK = { -- key -> { pass-4 TEX key, flipbook layout, mode }
	dialInlay = { "dialOuter" }, subdial = { "dialInner" }, accretion = { "galaxy4" }, galaxyFloor = { "galaxy4" },
	galaxyArms = { "galaxy4" }, galaxyCore = { "ornate" }, engraving = { "gring" }, halo = { "rim" },
	stream = { "line" }, ribbon = { "line" }, moon = { "moon" }, starWindow = { "galaxy4" },
	shards5 = { "ash", "None", "Loop" }, smoke5 = { "puff", "Grid4x4", "OneShot" }, mote = { "glow" }, glint5 = { "glint" },
	bokeh = { "glow" }, streak5 = { "spark" }, ash5 = { "ash", "None", "Loop" },
}
local warned = {}
local function warnOnce(key, msg)
	if not warned[key] then
		warned[key] = true
		warn(msg)
	end
end
-- a TEX5 value -> a content id, or nil (not filled in, or not an asset id: then the fallback is used and we say so once).
-- "pending:<key>" is the preview renderer's placeholder for a te5 PNG that is not uploaded yet (tools/); it is never
-- shipped: roblox/install/make_payloads.py refuses a module that still holds one.
local function idOf(v, key)
	if type(v) == "number" and v == v and v >= 1 and v < 1e18 then v = string.format("%d", math.floor(v)) end
	if type(v) ~= "string" then return nil end
	v = string.match(v, "^%s*(.-)%s*$")
	if v == "" then return nil end
	if string.match(v, "^%d+$") then return "rbxassetid://" .. v end
	if string.match(v, "^rbxassetid://%d+$") or string.match(v, "^rbxasset://") or string.match(v, "^rbxthumb://")
		or string.match(v, "^pending:%w+$") then
		return v
	end
	warnOnce("tex5:" .. tostring(key), string.format("TheEnd: TEX5.%s = %q is not an asset id; using the pass-4 fallback", tostring(key), v))
	return nil
end
local failed = {} -- te5 keys whose upload did not load in this game (ContentProvider said so): they use the fallback
-- T(key) -> id, flipbook layout name, flipbook mode name (layout "None" when it is not a flipbook). Accepts a TEX5 key or
-- a pass-4 TEX key. The layout comes from whichever texture is used, because a fallback can be laid out differently.
local function T(key)
	local id = not failed[key] and idOf(TEX5[key], key)
	if id then
		local l = TEX5_LAYOUT[key]
		return id, l and l[1] or "None", l and l[2] or "Loop"
	end
	local f = FALLBACK[key]
	if f then return TEX[f[1]], f[2] or "None", f[3] or "Loop" end
	local t = TEX[key]
	if not t then warnOnce("texkey:" .. tostring(key), "TheEnd: no texture called " .. tostring(key)) end
	return t or "", "None", "Loop"
end
local function isTe5(key) return not failed[key] and idOf(TEX5[key], key) ~= nil end
-- every live image, beam and emitter that uses a te5 key, so a texture that fails to load can be swapped for its fallback;
-- fixUps[o] puts back what the build chose because the te5 texture was there (a colour, a brightness, a size)
local texUsers = setmetatable({}, { __mode = "k" })
local fixUps = setmetatable({}, { __mode = "k" })
local function applyTex(o, key)
	local id, layout, mode = T(key)
	if o:IsA("ImageLabel") then
		o.Image = id
	elseif o:IsA("Beam") then
		o.Texture = id
	elseif o:IsA("ParticleEmitter") then
		o.Texture = id
		o.FlipbookLayout = Enum.ParticleFlipbookLayout[layout]
		if layout ~= "None" then o.FlipbookMode = Enum.ParticleFlipbookMode[mode] end
	end
	if TEX5[key] then texUsers[o] = key end
end
-- ask the engine for every filled-in te5 texture once (in the background: never blocks require or build). One that does
-- not load (wrong id, still in moderation, rejected) is reported and swapped for its pass-4 fallback everywhere. A slow
-- phone or a cold cache can time out: that id is asked for once more 20 s later before anything is swapped.
do
	local ids, keyOf, retried = {}, {}, {}
	for k in pairs(TEX5) do
		local id = idOf(TEX5[k], k)
		if id and not string.match(id, "^pending:") then
			table.insert(ids, id)
			keyOf[id] = k
		end
	end
	local function onStatus(id, status)
		local k = keyOf[id]
		if not k or failed[k] or status == Enum.AssetFetchStatus.Success then return end
		if status ~= Enum.AssetFetchStatus.Failure and not retried[k] then
			retried[k] = true
			task.delay(20, function()
				pcall(function() game:GetService("ContentProvider"):PreloadAsync({ id }, onStatus) end)
			end)
			return
		end
		failed[k] = true
		warn(string.format("TheEnd: te5 texture %s (%s) did not load (%s); using its pass-4 fallback", k, id, tostring(status)))
		for o, ok in pairs(texUsers) do
			if ok == k then
				pcall(applyTex, o, k)
				if fixUps[o] then pcall(fixUps[o]) end
			end
		end
	end
	if #ids > 0 then
		task.spawn(function()
			pcall(function() game:GetService("ContentProvider"):PreloadAsync(ids, onStatus) end)
		end)
	end
end

-- particle and beam colours (as pass 4) and a few more for pass 5
local WHITE = Color3.fromRGB(248, 249, 255)
local INK = Color3.fromRGB(5, 5, 8)
local SMOKE = Color3.fromRGB(14, 14, 19)
local MIST = Color3.fromRGB(205, 209, 220)
local ASH = Color3.fromRGB(16, 16, 20)
local RIBBON_INK = Color3.fromRGB(12, 12, 16)
-- solid parts: colour, material, reflectance and the sub-model they live in (the Highlight covers only "Silver").
-- The silvers are neutral: the cyan day sky already tints Metal blue, so a cool token read as baby-blue plastic.
local MAT = {
	SILVER = { Color3.fromRGB(184, 184, 185), Enum.Material.Metal, 0.08, "Silver" },
	BRIGHT = { Color3.fromRGB(224, 224, 225), Enum.Material.Metal, 0.12, "Silver" },
	STEEL = { Color3.fromRGB(44, 46, 51), Enum.Material.SmoothPlastic, 0, "Dark" },
	DEEP = { Color3.fromRGB(30, 31, 35), Enum.Material.SmoothPlastic, 0, "Dark" },
	BASE = { Color3.fromRGB(12, 12, 16), Enum.Material.SmoothPlastic, 0, "Dark" },
	VOID = { Color3.fromRGB(0, 0, 0), Enum.Material.Neon, 0, "Dark" },
	LUME = { Color3.fromRGB(240, 240, 242), Enum.Material.Neon, 0, "Lume" }, -- (neutral: Neon saturates any tint)
	ARC = { Color3.fromRGB(210, 210, 212), Enum.Material.Neon, 0, "Lume" },
	MOON = { Color3.fromRGB(234, 236, 240), Enum.Material.SmoothPlastic, 0, "Silver" }, -- (the film-mesh moon only)
	-- a darker satin silver for every other flute (bezel, dais rim) and the equator band: metal reads as metal when it has
	-- light and dark structure, not one flat value
	SATIN = { Color3.fromRGB(142, 142, 143), Enum.Material.Metal, 0.08, "Silver" },
	-- the moon: a grey core (it carries the dust, smoke, stream and key light, and casts the shadow) behind an opaque face
	-- disc that always turns to the camera. Both stay outside the Highlight (no ink ring, nothing painted over the face)
	MOONCORE = { Color3.fromRGB(184, 186, 192), Enum.Material.SmoothPlastic, 0, "Dark" },
}

-- flags. Any attribute on this ModuleScript with the same name and type overrides the default; they are read again at every
-- build, so in Studio: set the attribute, then unequip and equip the aura (no reinstall). Numbers are range-checked.
local DEFAULTS = {
	USE_FILM_MESHES = false, -- master switch for the FILM_* flags: the cutscene's own meshes (ReplicatedStorage.AuraCinema.Assets.TheEnd)
	FILM_BEZEL = false, FILM_DIAL = false, FILM_RETE = false, FILM_HANDS = false, FILM_GEARS = false, FILM_MOON = false,
	FILM_VOID = false, FILM_HAND_FLIP = false, FILM_KEEP_TEXTURES = false,
	VIEWER_ANCHOR = true, -- the clock stands on the far side of the wearer from each viewer's camera (false: always behind, as pass 4)
	CLOCK_DIST = 8, CLOCK_HEIGHT = 9.85, CLOCK_TILT = 8,
	YAW_SPRING = 6.5, -- how fast the clock swings round when the camera moves (rad/s; 95 % in 0.73 s)
	YAW_LAG_MAX = 22, -- the most (degrees) the clock and the orbs may trail a fast camera swing (a flick never throws them into the lens)
	ZOOM_FAR = 30, ZOOM_NEAR = 14, -- camera distances (studs) over which the layout eases into its close-camera form (Roblox's default zoom is 12.5)
	FIRST_PERSON_LIFT = true, -- in first person the owner's clock rises into the sky, out of the level view
	HIGHLIGHT = true, HIGHLIGHT_LOW = true, -- the silver-tone Highlight (keeps the metal neutral under the cyan sky)
	HIGHLIGHT_FILL = 0.65, HIGHLIGHT_OUTLINE = 0.35, -- its day FillTransparency / OutlineTransparency (night: 0.80 / 0.70)
	SHADOWS = true, -- the moon and the void cast shadows (high quality only)
	ASSEMBLY = true, ASSEMBLY_REMOTE = true, GRADE = true,
	DAIS_FLOAT = true, -- the dais floats under the feet when the ground is far below
	AIR_ON = 12, AIR_OFF = 9, -- feet this high above the ground count as flying (the dais lifts); below AIR_OFF as grounded again
	NEAR_HIDE = true, -- hide the rings and the bokeh when the camera is right inside them
	NEAR_ARM_HIDE = 10, NEAR_ARM_SHOW = 11.5, -- camera distance to the rings' centre: hide below / show above (studs)
	NEAR_BOKEH_HIDE = 18, NEAR_BOKEH_SHOW = 20, -- the big bokeh discs only drift by in showcase framings
	GHOST_REMOTE = true, -- another wearer's clock, rings and orbs turn see-through while they stand between you and your camera
	FAR_BEACON = false, -- (needs Milo's OK) a thin steady spire over the wearer that only far-away players see
	-- Studio checks that are one attribute flip each (see roblox/install/studio_checks.md):
	FLOW_SIGN = 1, -- -1 if the streams flow out of the palms (and the ribbon up into the void)
	ACC_DIR = 1, -- -1 if the accretion streaks (and the void swirl) lead their spin instead of trailing it
	FUNNEL_DIR = 1, -- -1 if the floor vortex winds against the galaxy arms
	GALAXY_DIR = 1, -- -1 if the galaxy floor's arms lead their spin instead of trailing it
	WEDGE_SWAP = false, -- true if the heart's spikes come out hollow (Roblox wedge orientation)
	STREAK_FLIP = false, -- true if the streak particles fly tail-first
	FRONT_FACES = false, -- true if the dial inlay / corona show mirrored or on the wrong side (uses pass 4's proven Front faces)
	SWIRL_POINTS = false, -- true if the void swirl / floor vortex spray as flat sheets (Cylinder emitters including their caps)
	NIGHT_INTERVAL = 1.0,
	DEBUG = false,
}
local RANGES = {
	CLOCK_DIST = { 4, 20 }, CLOCK_HEIGHT = { 6, 16 }, CLOCK_TILT = { -10, 30 }, YAW_SPRING = { 1, 30 }, YAW_LAG_MAX = { 5, 120 },
	ZOOM_FAR = { 10, 120 }, ZOOM_NEAR = { 0, 110 }, HIGHLIGHT_FILL = { 0, 1 }, HIGHLIGHT_OUTLINE = { 0, 1 }, AIR_ON = { 7.5, 60 },
	AIR_OFF = { 7, 59 }, NEAR_ARM_HIDE = { 0, 40 }, NEAR_ARM_SHOW = { 0.5, 41 }, NEAR_BOKEH_HIDE = { 0, 60 },
	NEAR_BOKEH_SHOW = { 0.5, 61 }, NIGHT_INTERVAL = { 0.25, 10 },
}
local SIGNS = { FLOW_SIGN = true, ACC_DIR = true, FUNNEL_DIR = true, GALAXY_DIR = true }
local CONFIG = {}
local function readConfig()
	for k, v in pairs(DEFAULTS) do CONFIG[k] = v end
	local ok, attrs = pcall(function() return script:GetAttributes() end)
	if not (ok and type(attrs) == "table") then return end
	for k, v in pairs(attrs) do
		local d = DEFAULTS[k]
		if d == nil then
			if type(k) == "string" and string.match(k, "^[%u%d_]+$") then
				warnOnce("attr:" .. k, "TheEnd: attribute " .. k .. " is not one of its flags (ignored: check the spelling)")
			end
		elseif typeof(v) ~= typeof(d) then
			warnOnce("type:" .. k, string.format("TheEnd: attribute %s is a %s, expected a %s (ignored)", k, typeof(v), typeof(d)))
		elseif type(v) == "number" then
			if v ~= v or v == math.huge or v == -math.huge then
				warnOnce("nan:" .. k, "TheEnd: attribute " .. k .. " is not a finite number (ignored)")
			elseif SIGNS[k] then
				if v ~= 0 then CONFIG[k] = v < 0 and -1 or 1 end
			else
				local r = RANGES[k]
				if r and (v < r[1] or v > r[2]) then
					warnOnce("range:" .. k, string.format("TheEnd: attribute %s = %s is outside %s..%s (clamped)", k, tostring(v), r[1], r[2]))
					v = math.clamp(v, r[1], r[2])
				end
				CONFIG[k] = v
			end
		else
			CONFIG[k] = v
		end
	end
	-- (the hysteresis pairs must stay in order)
	if CONFIG.ZOOM_NEAR > CONFIG.ZOOM_FAR - 1 then CONFIG.ZOOM_NEAR = CONFIG.ZOOM_FAR - 1 end
	if CONFIG.AIR_OFF > CONFIG.AIR_ON - 0.5 then CONFIG.AIR_OFF = CONFIG.AIR_ON - 0.5 end
	if CONFIG.NEAR_ARM_SHOW < CONFIG.NEAR_ARM_HIDE + 0.5 then CONFIG.NEAR_ARM_SHOW = CONFIG.NEAR_ARM_HIDE + 0.5 end
	if CONFIG.NEAR_BOKEH_SHOW < CONFIG.NEAR_BOKEH_HIDE + 0.5 then CONFIG.NEAR_BOKEH_SHOW = CONFIG.NEAR_BOKEH_HIDE + 0.5 end
end
readConfig()

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
local TILTACC = CFrame.Angles(rad(24), 0, 0) -- the accretion disc tilts 24° toward the viewer (reads as a disc, not a line)
local TILT33 = CFrame.Angles(rad(33), 0, 0)
local FLAT = CFrame.new(0, 0.95, 0) * CFrame.Angles(rad(90), 0, 0) -- the rings lying flat on the dais before they rise
local ASM_END = 6.5
-- the close-camera form (cz = 1 at Roblox's 12.5-stud default zoom, 0 from 30 studs out): the owner's clock stands this
-- much further back (other players' clocks less, so a passing wearer's clock does not slide far away) and leans back a
-- little more; the orbs come in, down and toward the camera, so the dial with its hands at XII and both orbs are on screen
local CLOSE = { dist = 32, distRemote = 16, tilt = 24, arm = 1.0, orbY = 5, orbZ = 10.5 }

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

-- the wearer's equip grade lives here (one per client), so a quick re-equip takes it over instead of stacking a second one
local liveGrade, liveGradeTween, gradeToken = nil, nil, 0
local GRADE_ON = { Saturation = -0.75, Brightness = -0.1, Contrast = 0.15, TintColor = Color3.fromRGB(232, 238, 255) }
local GRADE_OFF = { Saturation = 0, Brightness = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) }
-- where the time shards leave the bezel on equip (K angles), and the bezel point at eleven the metal shards break off from
local SHARD_A = {}
for i = 0, 7 do SHARD_A[i] = math.rad(300 + 20 * i) end
local FEED_PT = Vector3.new(-10.72, 9.00, 0)

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
	readConfig() -- (attributes are read again at every build: set one in Studio, then unequip and equip)
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
	local GGEAR0 = 5 -- (an offset, not a group: the seven gears are groups GGEAR0 + 1 .. GGEAR0 + 7)
	local GF1, GF2, GF3 = 13, 14, 15
	local GSHARD0 = 15 -- (the eight time shards are groups GSHARD0 + 1 .. GSHARD0 + 8)
	local GMOON, GVOID, GPF, GHF, GACC, GSWIRL = 24, 25, 26, 27, 28, 29
	local GDAIS, GG0, GG1, GG2, GENG, GWHEEL, GFUNNEL, GRIBEND = 30, 31, 32, 33, 34, 35, 37, 38 -- (36: unused)
	local GFEED, GAIR, GBOKEH, GPALMM, GPALMV, GMOONF, GDUST = 39, 40, 41, 42, 43, 44, 45
	local GCF = table.create(45, IDENT)
	-- per-frame state that is not a hot inner-loop value lives in one table (End.build is close to Luau's 200-register
	-- limit: every new top-level local here costs one; tools/harness/register_headroom.py keeps 16 spare)
	local st = {
		zoomD = nil, cz = 0, fp = 0, sitT = 0, lift = 0, speed = 0, speedOn = false, speedT = 0, tdir = nil, lastO = nil,
		ghost = 0, ghostQ = 0, ghostHold = 0, ghostGui = false, revealA = 1, hiddenAt = nil, shownAt = -1, footOk = true,
		smokeSlow = false, seated = false, pendingGroups = false, pendingRoot = false, repoint = false,
		gradeWanted = false, gradeStarted = false, gradeOut = false, kf = -1, wf = -1,
		-- (round 2) snap: the first frame after a long hide starts everything where it belongs; kY/kYv: the height the clock
		-- and the balance ride (a heavy spring, so a jump does not throw them); layer: this wearer's dais lift (no z-fighting
		-- between two pools); lodF: the far-detail fade; armF/armQ/armG/armGQ/armHold: the rings' near-camera fade and
		-- their own ghost; fpOn: first person; skipN/skipDt: half-rate updates for a far remote wearer
		snap = false, kY = nil, kYv = 0, layer = 0, lodF = 1, lodQ = 20, armF = 0, armQ = 0, armWant = false, armG = 0, armGQ = 0,
		armHold = 0, fpOn = false, skipN = 0, skipDt = 0, czq = 0, hlO = -1, hlFh = 0, kB = -1, wB = -1, fxLtm = false,
	}

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
		if grp <= GGEAR0 + 7 then table.insert(clockParts, p) end
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
		local im = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ImageColor3 = color or Color3.new(1, 1, 1),
			ImageTransparency = 1 }, g)
		applyTex(im, key)
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
	local hosts = {} -- invisible carriers and attachments the emitters, beams and lights hang on (one table: saves registers)
	local ghostGuis = {} -- GUIs that switch off while another wearer's aura is ghosted (LocalTransparencyModifier skips GUIs)
	local frontL = CONFIG.FRONT_FACES and FLIP or IDENT -- (FRONT_FACES: draw the dial GUIs on Front faces of flipped planes, as pass 4)
	local frontFace = CONFIG.FRONT_FACES and Enum.NormalId.Front or Enum.NormalId.Back
	do
		-- the bezel: a fluted coin edge 2.4 deep, bright silver and darker satin flutes (the segments alternate in depth too,
		-- so the flutes show and nothing z-fights); on equip it sweeps round clockwise from twelve, each segment flying in
		-- from outside and behind
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
				local k = solid("Bezel", odd and "SATIN" or "SILVER", CORE, GK, "Block",
					Vector3.new(2 * Ro * math.tan(rad(180 / NB)) + 0.02, Ro - 12.2, zf - zb), radial(th, rm, zc))
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
		-- Brightness, not alpha). STUDIO-VERIFY: SurfaceGui Face = Back draws on the +Z face (toward the viewer), XII up
		-- (if not: attribute FRONT_FACES = true)
		hosts.inlay = carrier("Inlay", CORE, GK, Vector3.new(24.4, 24.4, 0.05), CFrame.new(0, 0, 0.12) * frontL)
		hosts.inlayGui = surface(hosts.inlay, frontFace, hiCanvas, 1.6, 2.6, "dialInlay", 3.4, 4.2)
		-- raised lume plots at the hours, on the minute track
		if hi then
			for h = 0, 11 do
				local k = solid("Plot", "LUME", DETAIL, GK, "Block", Vector3.new(0.42, 0.55, 0.18), radial(h * 30, 11.85, 0.21))
				motion(k, radial(h * 30, 11.85, 3.21), 3.4 + 0.04 * h, 0.3)
				fadeWin(k, 3.4 + 0.04 * h, 3.5 + 0.04 * h)
			end
		end
		-- the rete: an openwork twelve-point star of silver bars over the open dial (the bars alternate in depth at the
		-- crossings). Kept at every distance: it is the dial's silhouette (dropping it far away made the face pop empty)
		if hi then
			local filmRete = film("FILM_RETE", "Astrolabe")
			fsz, frot = nil, nil
			if filmRete then fsz, frot = fitDisc(filmRete, 18.2, 0.24) end
			k0 = fsz and filmSolid(filmRete, fsz, "Rete", "SILVER", CORE, GK, CFrame.new(0, 0, 0.27) * frot)
			if k0 then
				motion(k0, CFrame.new(0, 0, 3.27) * CFrame.Angles(0, 0, rad(60)) * frot, 3.0, 0.6)
				fadeWin(k0, 3.0, 3.15)
			else
				for k = 0, 11 do
					local phi = (k + 2.5) * 30
					local zk = k % 2 == 0 and 0.25 or 0.29
					local i = solid("Rete", "SILVER", CORE, GK, "Block", Vector3.new(17.58, 0.26, 0.20), radial(phi, 2.355, zk))
					motion(i, radial(phi, 2.355 * 2.2, zk), 3.0 + 0.04 * k, 0.5)
					fadeWin(i, 3.0 + 0.04 * k, 3.15 + 0.04 * k)
				end
			end
		end
		-- the sub-dial: a dark guilloché disc at the centre. STUDIO-VERIFY: SurfaceGui Face = Left is the cylinder's -X end,
		-- which faces the viewer after the 90° turn (canvas right = the viewer's right)
		local subdial = PP[solid("SubDial", "DEEP", CORE, GK, "Cylinder", Vector3.new(0.30, 6.5, 6.5), CFrame.new(0, 0, 0.57) * DISC)]
		motion(NP, CFrame.new(0, 0, -1.43) * DISC, 3.2, 0.4)
		fadeWin(NP, 3.2, 3.4)
		hosts.subdialGui = surface(subdial, Enum.NormalId.Left, midCanvas, 1.4, 2.2, "subdial", 3.2, 3.4)
		-- the movement plate: a solid black disc closing the skeleton dial from behind (it used to be open air: grass, paths
		-- and sky showed through the clock). A window into deep space turns on it with the centre wheel; only the big gears'
		-- teeth now show past the rim. It rides the centre wheel GE's frame (K z -0.95), so it sits at K z -1.40, between GE's
		-- back face (-1.30) and the big gears (<= -1.60), and slides in with GE.
		local plate = PP[solid("Backplate", "BASE", CORE, GGEAR0 + 5, "Cylinder", Vector3.new(0.10, 24.6, 24.6), CFrame.new(0, 0, -0.45) * DISC)]
		fadeWin(NP, 3.0, 3.3)
		-- (te5_star_window is a dark star field; until it is uploaded the plate borrows the pass-4 galaxy, which is much
		-- brighter, so it glows less)
		local sw = isTe5("starWindow")
		local pe5
		hosts.plateGui, pe5 = surface(plate, Enum.NormalId.Left, hiCanvas, sw and 1.1 or 0.7, sw and 2.0 or 1.1, "starWindow", 3.0, 3.4)
		if sw then
			-- (if te5_star_window fails to load in the game, the bright pass-4 galaxy takes its place: dim it as above)
			local be = brights[#brights]
			fixUps[pe5[1]] = function()
				be[2], be[3] = 0.7, 1.1
				be[1].Brightness = 0.7 + 0.4 * nightStep()
			end
		end
		table.insert(ghostGuis, hosts.inlayGui)
		table.insert(ghostGuis, hosts.subdialGui)
		table.insert(ghostGuis, hosts.plateGui)
	end

	-- the hands: hour and minute locked at XII (midnight, the end), the seconds hand sweeping smoothly; raised above the dial
	local function handPart(name, tok, h, grp, shape, size, pos, rot)
		local i = solid(name, tok, h, grp, shape, size, CFrame.new(pos) * (rot or IDENT))
		fadeWin(i, 3.6, 3.8)
		return i
	end
	do
		local R45 = CFrame.Angles(0, 0, rad(45))
		local filmHand = film("FILM_HANDS", "Hand")
		-- (len: tip-to-tail length for a film mesh, mid: its centre; the rest are the procedural parts' sizes and heights)
		for _, hd in ipairs({
			{ grp = GHOUR, len = 8.55, mid = 2.67, w = 0.55, shaft = 5.6, shaftY = 3.4, tip = 0.70, tipY = 6.45, tail = 1.6, tailY = -0.8,
				lumeW = 0.24, lumeL = 4.6, lumeY = 3.6 },
			{ grp = GMIN, len = 11.17, mid = 3.58, w = 0.40, shaft = 8.0, shaftY = 4.6, tip = 0.52, tipY = 8.8, tail = 2.0, tailY = -1.0,
				lumeW = 0.16, lumeL = 6.2, lumeY = 4.9 },
		}) do
			local done = false
			if filmHand then
				local sz, rot = fitHand(filmHand, hd.len)
				local flip = CONFIG.FILM_HAND_FLIP and CFrame.Angles(0, 0, pi) or IDENT
				local k = sz and filmSolid(filmHand, sz, "Hand", "SILVER", CORE, hd.grp, CFrame.new(0, hd.mid, 0) * flip * rot)
				if k then
					fadeWin(k, 3.6, 3.8)
					done = true
				end
			end
			if not done then
				handPart("Shaft", "SILVER", CORE, hd.grp, "Block", Vector3.new(hd.w, hd.shaft, 0.16), Vector3.new(0, hd.shaftY, 0))
				handPart("Tip", "SILVER", CORE, hd.grp, "Block", Vector3.new(hd.tip, hd.tip, 0.16), Vector3.new(0, hd.tipY, 0), R45)
				if hi then handPart("Tail", "SILVER", CORE, hd.grp, "Block", Vector3.new(hd.w, hd.tail, 0.16), Vector3.new(0, hd.tailY, 0)) end
			end
			if hi then handPart("Lume", "LUME", CORE, hd.grp, "Block", Vector3.new(hd.lumeW, hd.lumeL, 0.05), Vector3.new(0, hd.lumeY, 0.105)) end
		end
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
	do
		local filmGear = film("FILM_GEARS", "Gear")
		for gi, G in ipairs(GEARS) do
			local name, cx, cy, cz, Dt, Dr, K, d, wt, web, spokes, rate, onLow = table.unpack(G)
			if hi or onLow then
				local grp = GGEAR0 + gi
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
				-- on equip: the big four slide out from behind the dial, the centre wheel from behind, the small two from the
				-- front; all spin up fast and wind down to their running pace
				local sx, sy, sz2
				if big then sx, sy, sz2 = 0.3 * cx, 0.3 * cy, -4 elseif gi == 5 then sx, sy, sz2 = cx, cy, cz - 3 else sx, sy, sz2 = cx, cy, cz + 3 end
				table.insert(gearData, { grp = grp, cx = cx, cy = cy, cz = cz, sx = sx, sy = sy, sz = sz2, rate = rate, a0 = a, a1 = a + (big and 1.0 or 0.6),
					sign = rate < 0 and -1 or 1, extra = 0 })
			end
		end
	end

	-- the crown and the bow above XII (kept at every distance: the bow is the clock's silhouette from far away)
	do
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
				crownPart("Bow", "Cylinder", Vector3.new(1.662, 0.55, 0.55), CFrame.new(2.283 * cos(b), 19.6 + 2.283 * sin(b), -0.2) * CFrame.Angles(0, 0, b + rad(90)))
			end
		end
	end

	-- the night corona: a soft ring of light just outside the bezel (night only, rim-only, behind the clock). Kept at every
	-- distance: at night it is the clock's glow from across the plaza
	local corona, coronaEntry
	if hi then
		local cp = carrier("Corona", CORE, GK, Vector3.new(44, 44, 0.05), CFrame.new(0, 0, -3.2) * frontL) -- (ring peak R 16.3: seen from the front, 3.2 studs back, it lands just outside the bezel)
		corona, coronaEntry = surface(cp, frontFace, 512, 1.8, nil, "halo", 5.0, 6.0, Color3.fromRGB(240, 240, 242))
		corona.Enabled = false
		coronaEntry[2] = 1
	end
	-- the clock's emitter hosts: the bezel annulus (glints) and the shard feed at eleven (the rim smoke moved onto the void)
	hosts.rimGlint = carrier("RimGlint", CORE, GK, Vector3.new(28.4, 28.4, 0.2), CFrame.new(0, 0, 1.05))
	hosts.timeDust = hi and carrier("TimeDust", CORE, GDUST, Vector3.new(29.4, 29.4, 0.2)) -- (a ring turning with the hands: P13)
	hosts.shardFeed = hi and carrier("ShardFeed", DETAIL, GFEED, Vector3.new(2, 2, 2))

	---------------------------------------------------------------- THE ARMILLARY: three gimballed rings round the wearer
	-- flat bands made of segments; every other segment is a hair thicker so the overlaps never z-fight
	do
		local function ring(name, tok, h, grp, N, R, w, t, f0)
			for i = 0, N - 1 do
				local th = (i + 0.5) * 360 / N
				local k = solid(name, tok, h, grp, "Block", Vector3.new(2 * (R + w / 2) * math.tan(rad(180 / N)) + 0.02, w, t + (i % 2 == 0 and 0.02 or -0.02)),
					radial(th, R, 0))
				fadeWin(k, f0, f0 + 0.3)
			end
		end
		-- (a slimmer silver meridian, so the body reads through the cage; a satin-silver equator bracelet with twelve lume hours)
		ring("Meridian", "SILVER", ARM, GF1, low and 14 or 18, 6.0, 0.40, 0.24, 1.0)
		ring("Equator", "SATIN", ARM, GF2, low and 14 or 18, 5.3, 0.20, 0.4, 1.3)
		if hi then
			for k = 0, 11 do -- twelve lume hours on the equator band's outer face
				local i = solid("Hour", "LUME", ARMD, GF2, "Block", Vector3.new(0.14, 0.10, 0.32), radial(k * 30, 5.45, 0))
				fadeWin(i, 1.3, 1.6)
			end
			ring("Ecliptic", "SILVER", ARM, GF3, 16, 4.6, 0.45, 0.20, 1.6)
			for _, x in ipairs({ 5.58, -5.58 }) do -- pins: equator to meridian
				local i = solid("Pin", "BRIGHT", ARMD, GF1, "Cylinder", Vector3.new(0.55, 0.30, 0.30), CFrame.new(x, 0, 0))
				fadeWin(i, 1.0, 1.3)
			end
			for _, y in ipairs({ 5.01, -5.01 }) do -- pins: ecliptic to equator
				local i = solid("Pin", "BRIGHT", ARMD, GF2, "Cylinder", Vector3.new(0.45, 0.30, 0.30), CFrame.new(0, y, 0) * VERT)
				fadeWin(i, 1.3, 1.6)
			end
			-- the time shards: eight slivers riding the inside of the ecliptic like beads on a wire, tumbling as they go
			for i = 0, 7 do
				local k = solid("TimeShard", i % 2 == 0 and "BRIGHT" or "LUME", ARMD, GSHARD0 + 1 + i, "Wedge", Vector3.new(0.14, 0.7 + 0.15 * (i % 3), 0.40), IDENT)
				fadeWin(k, 5.0 + 0.06 * i, 5.2 + 0.06 * i)
			end
		end
	end

	---------------------------------------------------------------- THE BALANCE: the moon and the void, rocking like scales
	-- the moon, tidally locked to the wearer: a grey core (it carries the dust, the smoke, the stream and the key light, and
	-- casts the shadow) behind its face, an opaque 9-stud disc 4.4 studs toward the camera that turns to face it every
	-- frame. The face is solid geometry, so it writes depth: no Highlight contour, smoke or ring behind it can paint over it
	-- (a BillboardGui face could not stop that). With te5_moon: the photographic full moon on a grey disc. Until it is
	-- uploaded: pass 4's glowing moon on a white Neon disc (a pearl that glows at night).
	local moon, haloIm, haloEntry
	local moonFace = false
	do
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
			moonFace = true
			moon = PP[solid("Moon", "MOONCORE", CORE, GMOON, "Ball", Vector3.new(6, 6, 6), IDENT)]
			fadeWin(NP, 0.6, 0.9)
			local t5 = isTe5("moon")
			hosts.moonFace = PP[solid("MoonFace", t5 and "MOONCORE" or "LUME", CORE, GMOONF, "Cylinder", Vector3.new(0.1, 9, 9), DISC)]
			fadeWin(NP, 0.6, 0.9)
			-- STUDIO-VERIFY: SurfaceGui Face = Left on the face disc (the cylinder's -X end turns to the camera), not mirrored
			local fg, fe = surface(hosts.moonFace, Enum.NormalId.Left, hiCanvas, 1.25, 2.6, "moon", 0.6, 0.9)
			table.insert(ghostGuis, fg)
			if t5 then
				-- (te5_moon failed to load in the game: pass 4's moon needs the white disc behind it)
				local fd = hosts.moonFace
				fixUps[fe[1]] = function()
					fd.Color, fd.Material = MAT.LUME[1], MAT.LUME[2]
				end
			end
		end
		moon.CastShadow = CONFIG.SHADOWS and hi
		hosts.moonOut = new("Attachment", { Name = "StreamOut", CFrame = CFrame.new(0, 0, moonFace and -3.95 or -4.55) * CFrame.Angles(0, 0, rad(90)) }, moon)
		-- a thin halo round the moon's rim (15 studs: the face is 4.4 studs nearer the camera, so it looks bigger than the
		-- core). It sits 2 studs behind the core, so the face hides its inner edge; not further,
		-- or on the clock side it would reach the inlay plane and get cut (keeps >= 0.4 from every GUI plane)
		local halo = new("BillboardGui", { Name = "Halo", Size = UDim2.new(15, 0, 15, 0), StudsOffset = Vector3.new(0, 0, -2.0), LightInfluence = 0,
			Brightness = 1.0, MaxDistance = 400, AlwaysOnTop = false }, moon)
		haloIm = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ImageColor3 = Color3.fromRGB(240, 240, 244),
			ImageTransparency = 1 }, halo)
		applyTex(haloIm, "halo")
		haloEntry = { haloIm, 0.65, 1.4, 2.2, 1 }
		table.insert(images, haloEntry)
		table.insert(brights, { halo, 1.0, 1.6 })
		table.insert(ghostGuis, halo)
	end
	-- the moon's key light (high quality only: on phones' voxel lighting a moving light steps in 4-stud blocks).
	-- STUDIO-VERIFY: a PointLight on an attachment of a part moved by BulkMoveTo follows it every frame
	local keyLight = hi and new("PointLight", { Name = "Key", Range = 26, Color = Color3.fromRGB(230, 232, 240), Brightness = 0, Shadows = false,
		Enabled = false }, new("Attachment", { Name = "KeyLight", Position = Vector3.new(0, 4.5, -5.5) }, moon))

	-- the void: a pure-black Neon ball. STUDIO-VERIFY: Neon black renders pure black under the place's Bloom
	local void
	local voidSize = Vector3.new(8, 8, 8)
	do
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
	end
	if not void then
		void = PP[solid("Void", "VOID", CORE, GVOID, "Ball", Vector3.new(8, 8, 8), IDENT)]
		fadeWin(NP, 0, 0.4)
	end
	void.CastShadow = CONFIG.SHADOWS and hi
	hosts.voidOut = new("Attachment", { Name = "StreamOut", CFrame = CFrame.new(0, 0, -4.05) * CFrame.Angles(0, 0, rad(90)) }, void)
	hosts.ribbonOut = new("Attachment", { Name = "RibbonOut", CFrame = CFrame.new(0, -4.05, 0) * CFrame.Angles(0, rad(-90), 0) }, void)
	do
		-- the accretion disc: opaque white-hot streaks with black dust lanes, tilted 24° toward the viewer, its near half in
		-- front of the core. (Top face only: the disc always tilts toward the viewer, so its underside is never seen.)
		local accretion = carrier("Accretion", CORE, GACC, Vector3.new(13, 0.05, 13))
		table.insert(ghostGuis, (surface(accretion, Enum.NormalId.Top, hiCanvas, 1.6, 2.4, "accretion", 0.3, 1.1)))
		hosts.swirl = carrier("VoidSwirl", CORE, GSWIRL, Vector3.new(13, 0.3, 13))
		-- the event horizon's glow: one emitter on the silhouette plane (camera-facing, like the photon ring) keeps three
		-- soft rings alive at once, overlapping into a steady glow that hugs the black edge (no pulse; never a billboard,
		-- which the accretion plane would cut)
		hosts.horizon = hi and carrier("Horizon", CORE, GPF, Vector3.new(0.2, 0.2, 0.2))
		-- the photon ring: a lume hairline that always hugs the black silhouette as the camera sees it (from any distance)
		local N = low and 12 or 24
		for i = 0, N - 1 do
			local th = (i + 0.5) * 360 / N
			local k = solid("PhotonRing", "LUME", CORE, GPF, "Block", Vector3.new(low and 2.25 or 1.14, 0.13, 0.12), IDENT)
			PROT[k], PRR[k], PRS[k] = CFrame.Angles(0, 0, -rad(th)), 0.18, 11
			PS[k], PM0[k], PM1[k] = true, 0.25 + 0.6 * i / N, 0.85 + 0.6 * i / N
			fadeWin(k, 0.25 + 0.6 * i / N, 0.45 + 0.6 * i / N)
		end
		-- the lensed arc: the far side of the disc bent up over the top of the shadow
		if hi then
			for i = 0, 5 do
				local th = -75 + (i + 0.5) * 150 / 6
				local k = solid("LensedArc", "ARC", DETAIL, GPF, "Block", Vector3.new(2.05, 0.16, 0.10), IDENT)
				PROT[k], PRR[k], PRSO[k] = CFrame.Angles(0, 0, -rad(th)), 0.6, 3
				PS[k], PM0[k], PM1[k] = true, 0.7, 1.4
				fadeWin(k, 0.7, 0.9)
			end
		end
		-- the heart: a small brilliant four-point star just in front of the core (a pinpoint of light, not a sticker).
		-- STUDIO-VERIFY: Roblox wedge orientation (right angle at -Y, +Z); if the spikes come out hollow: attribute WEDGE_SWAP
		local hb = solid("Heart", "LUME", CORE, GHF, "Ball", Vector3.new(0.70, 0.70, 0.70), IDENT)
		fadeWin(hb, 0.9, 1.1)
		local function grow(i, L)
			motion(i, CFrame.new(L.Position * 0.05) * L.Rotation, 0.9, 0.6)
			fadeWin(i, 0.9, 1.1)
		end
		local wa = CONFIG.WEDGE_SWAP and -90 or 90
		for _, sp in ipairs({ { 0, 1.6 }, { 180, 1.6 }, { 90, 1.1 }, { 270, 1.1 } }) do
			if hi or sp[1] % 180 == 0 then
				local S = CFrame.Angles(0, 0, -rad(sp[1]))
				local h = sp[2]
				local La = S * CFrame.new(-0.16, h / 2, 0) * CFrame.Angles(0, rad(wa), 0)
				local Lb = S * CFrame.new(0.16, h / 2, 0) * CFrame.Angles(0, rad(-wa), 0)
				grow(solid("Spike", "LUME", CORE, GHF, "Wedge", Vector3.new(0.08, h, 0.32), La), La)
				grow(solid("Spike", "LUME", CORE, GHF, "Wedge", Vector3.new(0.08, h, 0.32), Lb), Lb)
			end
		end
	end

	---------------------------------------------------------------- THE DAIS: a dark galaxy pool in a raised silver rim
	local base = solid("DaisBase", "BASE", CORE, GDAIS, "Cylinder", Vector3.new(0.12, 29.6, 29.6), CFrame.new(0, 0.06, 0) * VERT)
	fadeWin(base, 4.0, 4.4)
	hosts.base = PP[base]
	local wheelHub
	do
		-- STUDIO-VERIFY: Top-face canvas orientation (up = +Z); the arms must trail the spin (floor turns clockwise from above;
		-- if they lead: attribute GALAXY_DIR = -1). The floor and core images come in with the base disc (no bare grey lid).
		hosts.floor = carrier("GalaxyFloor", CORE, GG0, Vector3.new(29.6, 0.05, 29.6))
		surface(hosts.floor, Enum.NormalId.Top, hiCanvas, 1.3, 2.4, "galaxyFloor", 4.0, 4.6)
		if hi then
			local arms = carrier("GalaxyArms", DETAIL, GG1, Vector3.new(21, 0.05, 21))
			surface(arms, Enum.NormalId.Top, 1024, 1.4, 2.4, "galaxyArms", 4.2, 5.2)
		end
		local core = carrier("GalaxyCore", CORE, GG2, Vector3.new(12, 0.05, 12))
		surface(core, Enum.NormalId.Top, midCanvas, 1.5, 2.6, "galaxyCore", 4.0, 4.6)
		if hi then
			local eng = carrier("Engraving", DETAIL, GENG, Vector3.new(40, 0.05, 40))
			surface(eng, Enum.NormalId.Top, 1024, 1.2, 2.0, "engraving", 4.2, 5.2)
		end
		-- the rim: fluted blocks (bright silver and satin) rising in a wave round the pool on equip
		local NR = low and 16 or 28
		for i = 0, NR - 1 do
			local th = i * 360 / NR
			local h = i % 2 == 0 and 0.90 or 0.96
			local k = solid("DaisRim", i % 2 == 0 and "SILVER" or "SATIN", CORE, GDAIS, "Block",
				Vector3.new(2 * 15.55 * math.tan(rad(180 / NR)) + 0.02, h, 0.80), CFrame.Angles(0, rad(th), 0) * CFrame.new(0, h / 2, -15.15))
			local a = 4.0 + 0.8 * i / NR
			motion(k, CFrame.Angles(0, rad(th), 0) * CFrame.new(0, h / 2 - 1.2, -15.15), a, 0.45)
			fadeWin(k, a, a + 0.15)
		end
		-- the balance wheel under the feet (the watch's heartbeat: a slow smooth swing, no ticking)
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
		wheelHub = PP[solid("WheelHub", "BRIGHT", CORE, GWHEEL, "Cylinder", Vector3.new(0.5, 0.7, 0.7), VERT)]
		fadeWin(NP, 4.6, 4.9)
		hosts.funnel = hi and carrier("Funnel", CORE, GFUNNEL, Vector3.new(11, 0.4, 11))
		local ribbonEnd = hi and carrier("RibbonEnd", CORE, GRIBEND, Vector3.new(0.4, 0.4, 0.4))
		hosts.ribbonIn = ribbonEnd and new("Attachment", { Name = "RibbonIn" }, ribbonEnd)
		if CONFIG.FAR_BEACON then
			-- (the base disc is a cylinder standing upright: its local +X is world up. The column starts above the bow, so it
			-- never crosses the dial, and climbs to 280 studs)
			hosts.beacon0 = new("Attachment", { Name = "BeaconFoot", Position = Vector3.new(38, 0, 0) }, hosts.base)
			hosts.beacon1 = new("Attachment", { Name = "BeaconTop", Position = Vector3.new(280, 0, 0) }, hosts.base)
		end
	end

	---------------------------------------------------------------- THE AIR and the palm intake carriers
	-- (the air volume turns to face the way the wearer travels, so the speed trail streams out behind)
	hosts.air = carrier("AirVolume", CORE, GAIR, Vector3.new(36, 20, 36))
	hosts.trail = new("Attachment", { Name = "Trail", Position = Vector3.new(0, -4, 0) }, hosts.air)
	hosts.bokeh = hi and carrier("BokehHost", DETAIL, GBOKEH, Vector3.new(18, 10, 5))
	hosts.palmMoon = carrier("PalmMoon", CORE, GPALMM, Vector3.new(2.6, 2.6, 2.6))
	hosts.palmVoid = carrier("PalmVoid", CORE, GPALMV, Vector3.new(2.6, 2.6, 2.6))

	-- the Highlight: one per aura, on the Silver model only (neutral silver by day plus an ink contour on the bright sky).
	-- STUDIO-VERIFY: a Highlight on a Model of 200+ parts. Its strength is the HIGHLIGHT_FILL / HIGHLIGHT_OUTLINE attributes.
	-- Its fill leans a touch warm: it is a correction filter that cancels the cyan the day sky puts on Metal. Roblox draws at
	-- most 31 Highlights per client, so on low quality only the owner's aura has one, and a far-away wearer's switches off.
	local tone
	if CONFIG.HIGHLIGHT and (hi or (CONFIG.HIGHLIGHT_LOW and ctx.isLocal)) then
		tone = new("Highlight", { Name = "TheEndTone", Adornee = mats.Silver, FillColor = Color3.fromRGB(216, 212, 208), FillTransparency = 1,
			OutlineColor = Color3.fromRGB(10, 10, 14), OutlineTransparency = 1, DepthMode = Enum.HighlightDepthMode.Occluded }, mats.Silver)
	end

	---------------------------------------------------------------- THE CHARACTER: palms and soles
	local charStuff = {}
	local palmR, palmL, soleL, soleR
	do
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
		palmR = palm(limb("RightHand", "Right Arm"), "TheEndPalmR", "RightGripAttachment")
		palmL = palm(limb("LeftHand", "Left Arm"), "TheEndPalmL", "LeftGripAttachment")
		local function sole(foot, name)
			if not (foot and foot:IsA("BasePart")) then return nil end
			local pos = (foot.Name == "LeftFoot" or foot.Name == "RightFoot") and Vector3.new(0, -foot.Size.Y / 2, 0) or Vector3.new(0, -1, 0)
			local a = new("Attachment", { Name = name, Position = pos }, foot)
			table.insert(charStuff, a)
			return a
		end
		soleL = sole(limb("LeftFoot", "Left Leg"), "TheEndSoleL")
		soleR = sole(limb("RightFoot", "Right Leg"), "TheEndSoleR")
	end
	-- (no hands: the streams end on the intake carriers, placed beside the wearer)
	local moonCarA = new("Attachment", { Name = "Palm" }, hosts.palmMoon)
	local voidCarA = new("Attachment", { Name = "Palm" }, hosts.palmVoid)
	-- the starting yaws: the wearer's facing, and the viewer's side (as if seen from behind when the camera tells us nothing)
	local yawW, lastCamPos, yawTarget
	do
		local hcf = ctx.hrp.CFrame
		local lv0 = hcf.LookVector
		yawW = atan2(-lv0.X, -lv0.Z)
		lastCamPos = (hcf * CFrame.new(0, 3.5, 12.5)).Position
		local cam0 = workspace.CurrentCamera
		if cam0 then lastCamPos = cam0.CFrame.Position end
		yawTarget = yawW
		local v = hcf.Position + Vector3.new(0, End.pose.hover, 0) - lastCamPos
		local dh = sqrt(v.X * v.X + v.Z * v.Z)
		if dh > 1.5 and dh > 0.2 * abs(v.Y) then yawTarget = atan2(-v.X, -v.Z) end
		st.zoomD = dh
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
	-- { beam, faded transparency steps, written step, LE day, night, Br day, night, near only, far only }
	local beams = {}
	local sb -- the four stream beams (their palm end moves when the wearer turns): { MoonCore, MoonFlow, VoidCore, VoidCrackle }
	do
		local function beam(name, a0, a1, key, mode, len, speed, w0, w1, c0, c1, color, le0, le1, br0, br1, tr, nearOnly, farOnly)
			local b = new("Beam", { Name = name, Attachment0 = a0, Attachment1 = a1, TextureMode = mode, TextureLength = len,
				TextureSpeed = speed * CONFIG.FLOW_SIGN, Width0 = w0, Width1 = w1, CurveSize0 = c0, CurveSize1 = c1, Color = ColorSequence.new(color),
				LightEmission = le0, LightInfluence = 0, Brightness = br0, FaceCamera = true, Segments = 20, ZOffset = 0,
				Transparency = NumberSequence.new(1), Enabled = not farOnly }, holder("Fx", CORE))
			if key then applyTex(b, key) end
			-- (the fade steps are made here, once: update only picks one; 21 steps, so a fade never jumps more than 5 %)
			local steps = {}
			for q = 0, 20 do
				local pts = {}
				for _, p in ipairs(tr) do table.insert(pts, { p[1], 1 - (1 - p[2]) * q / 20 }) end
				steps[q] = seq(pts)
			end
			table.insert(beams, { b, steps, 0, le0, le1, br0, br1, nearOnly, farOnly })
			return b
		end
		local WRAP, STRETCH = Enum.TextureMode.Wrap, Enum.TextureMode.Stretch
		local moonA0, voidA0 = palmFor(-assign, moonCarA), palmFor(assign, voidCarA)
		-- STUDIO-VERIFY: Beam TextureSpeed direction: the streams must flow from the orb INTO the palm and the ribbon must flow
		-- down onto the dais (all four are built source -> destination, so they share one sign; if they run backwards:
		-- attribute FLOW_SIGN = -1)
		local trCore = { { 0, 0.15 }, { 0.12, 0.05 }, { 0.88, 0.05 }, { 1, 0.30 } }
		sb = {
			beam("MoonCore", hosts.moonOut, moonA0, "stream", WRAP, 5, 0.8, 1.4, 0.30, 4.0, 0, WHITE, 0, 0.45, 1.6, 2.4, trCore),
			hi and beam("MoonFlow", hosts.moonOut, moonA0, "streak", WRAP, 7, 1.6, 0.5, 0.15, 4.3, 0, WHITE, 0.3, 0.9, 2.0, 2.6,
				{ { 0, 0.4 }, { 0.15, 0.2 }, { 0.85, 0.2 }, { 1, 0.6 } }, true),
			beam("VoidCore", hosts.voidOut, voidA0, "stream", WRAP, 5, 0.7, 1.6, 0.35, 3.0, 0, Color3.fromRGB(18, 18, 24), 0, 0, 1.0, 1.0, trCore),
			hi and beam("VoidCrackle", hosts.voidOut, voidA0, "line", STRETCH, 1, 0, 0.14, 0.10, 2.6, 0, WHITE, 0.2, 0.8, 1.8, 2.4,
				{ { 0, 0.3 }, { 0.1, 0.1 }, { 0.9, 0.1 }, { 1, 0.5 } }, true),
		}
		if hi then
			-- the ink ribbon: a whip-thin strand that curls out of the void and down into the pool (solid in its body, soft
			-- at the void end). (The te5 ribbon carries its own ink body and white hairlines, so it needs a white Beam
			-- Color; the fallback line is inked.)
			local te5r = isTe5("ribbon")
			local rb = beam("Ribbon", hosts.ribbonOut, hosts.ribbonIn, "ribbon", WRAP, 8, 0.5, 0.45, 1.3, 7.0, -8.0, te5r and WHITE or RIBBON_INK,
				0, 0, 1.0, 1.0, { { 0, 0.55 }, { 0.15, 0.15 }, { 0.85, 0.05 }, { 1, 0.35 } })
			if te5r then fixUps[rb] = function() rb.Color = ColorSequence.new(RIBBON_INK) end end
			beam("RibbonEdge", hosts.ribbonOut, hosts.ribbonIn, "line", STRETCH, 1, 0, 0.10, 0.10, 7.3, -8.3, WHITE, 0.2, 0.8, 1.8, 2.4,
				{ { 0, 0.3 }, { 0.1, 0.1 }, { 0.9, 0.1 }, { 1, 0.4 } }, true)
		end
		if hosts.beacon0 then
			-- (FAR_BEACON) a steady column seen only from far away: solid ink on the day sky, white at night, soft at the top.
			-- No texture (a solid band reads at 300 studs; a textured line thinned to a hairline). No pulse.
			hosts.beaconBeam = beam("Spire", hosts.beacon0, hosts.beacon1, nil, STRETCH, 1, 0, 8, 3, 0, 0, INK, 0, 1, 1, 2,
				{ { 0, 0.1 }, { 0.6, 0.15 }, { 1, 1 } }, false, true)
		end
		-- (entry [10]: one of the four palm streams, switched off in first person; [11]: the Enabled last written)
		for _, b in ipairs(beams) do
			b[10] = b[1] == sb[1] or b[1] == sb[2] or b[1] == sb[3] or b[1] == sb[4]
			b[11] = b[1].Enabled
		end
	end

	---------------------------------------------------------------- THE PARTICLES: every system has a job and a path
	local emitters = {} -- { emitter, on time, kind, live, written Enabled }
	local emitNight = {} -- { emitter, LE day, LE night, Br day, Br night }
	local em = {} -- the emitters that change after the build: bokeh (rate by night), smoke (thins out while moving)
	do
		local function pe(parent, key, tOn, props, le, br, kind)
			local p = Instance.new("ParticleEmitter")
			applyTex(p, key)
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
		-- (white particles glow just above the Bloom threshold by day: small steady glints read as light, not as grey specks.
		-- They grow, hold and shrink: never a flash)
		local WHITE_LE, WHITE_BR = { 0.3, 0.9 }, { 2.4, 3.0 }
		-- the streak texture: te5_streak is a thin capsule in a square cell, so it is drawn bigger than the fallback speck;
		-- STREAK_FLIP turns streaks that fly tail-first round (STUDIO-VERIFY: VelocityParallel puts the image's TOP forward)
		local stS = isTe5("streak5") and 2.2 or 1
		-- (a te5 texture that fails to load in the game: its emitter goes back to the size made for the fallback)
		local function sizeFix(p, scale, pts)
			if scale ~= 1 then fixUps[p] = function() p.Size = seq(pts) end end
			return p
		end
		local stRot = CONFIG.STREAK_FLIP and n(180) or n(0)
		-- (SWIRL_POINTS: if Roblox's Cylinder emitters spray over their flat caps, the swirl and the vortex fall back to one
		-- point emitter on the rim aimed at the axis; the host's spin still curls each particle's path into a spiral arm)
		local function rimPoint(host, r)
			return new("Attachment", { Name = "SwirlPoint", CFrame = CFrame.lookAt(Vector3.new(r, 0, 0), Vector3.zero) }, host)
		end
		-- P1: matter spirals in along the accretion disc and vanishes into the black core (straight inward motion inside a
		-- spinning host becomes a spiral). STUDIO-VERIFY: Cylinder + Surface + Inward emits on the curved side toward the
		-- axis (if not: attribute SWIRL_POINTS), and LockedToPart particles ride a host moved by BulkMoveTo
		local p1 = { Rate = rate(28, 12), Lifetime = n(1.1, 1.3), Speed = n(2.2, 2.6), Size = seq({ { 0, 1.5 }, { 1, 0.35 } }),
			Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.8, 0.05 }, { 1, 0.4 } }),
			Color = ColorSequence.new(WHITE, Color3.fromRGB(170, 174, 184)), LockedToPart = true, ZOffset = 0.3 }
		if CONFIG.SWIRL_POINTS then
			p1.EmissionDirection, p1.SpreadAngle = N_.Front, Vector2.new(0, 10)
			pe(rimPoint(hosts.swirl, 6.3), "mote", 1.2, p1, WHITE_LE, WHITE_BR)
		else
			p1.Shape, p1.ShapeStyle, p1.ShapeInOut, p1.EmissionDirection = CYL, SURFACE, INWARD, N_.Top
			pe(hosts.swirl, "mote", 1.2, p1, WHITE_LE, WHITE_BR)
		end
		-- P2: dust snows off the moon and falls away below it
		pe(moon, "mote", 1.6, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = rate(16, 5), Lifetime = n(3.0, 4.5),
			Speed = n(0.25, 0.6), Acceleration = Vector3.new(0, -1.1, 0), Drag = 0.4, Size = seq({ { 0, 0.18 }, { 0.2, 0.6, 0.15 }, { 1, 0.18 } }),
			Transparency = seq({ { 0, 1 }, { 0.12, 0.08 }, { 0.75, 0.15 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(238, 240, 246)),
			Rotation = n(0, 360), RotSpeed = n(-30, 30) }, { 0.2, 0.7 }, { 1.4, 2.2 })
		if hi then
			-- P3: metal shards break off the bezel at eleven and fly across the face into the void (tumbling flipbook)
			local shardScale = isTe5("shards5") and 1.3 or 1 -- (the te5 sliver fills about half its cell)
			sizeFix(pe(hosts.shardFeed, "shards5", 4.8, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Front, Rate = 7, Lifetime = n(2.9, 3.2),
				Speed = n(8.5, 9.5), SpreadAngle = Vector2.new(6, 6),
				Size = seq({ { 0, 0.6 * shardScale }, { 0.85, 0.9 * shardScale, 0.12 * shardScale }, { 1, 0.35 * shardScale } }),
				Transparency = seq({ { 0, 1 }, { 0.06, 0 }, { 0.9, 0 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(214, 218, 226)),
				Rotation = n(0, 360), RotSpeed = n(-120, 120), FlipbookFramerate = n(10, 14), FlipbookStartRandom = true }, { 0, 0.3 }, { 1, 1.6 }),
				shardScale, { { 0, 0.6 }, { 0.85, 0.9, 0.12 }, { 1, 0.35 } })
		end
		-- P4: the two opposite energies breathe: dense ink smoke boils off the void and grey-silver smoke off the moon,
		-- curling out and up round each orb (a dark corona that reads on the bright day sky, a pale one at night). Drawn 3
		-- studs further back, so the orbs' silhouettes stay crisp (the moon's opaque face hides what is born behind it).
		-- Thinner while the wearer travels, so no trail of puffs hangs on the path.
		local smS = isTe5("smoke5") and 1.3 or 1 -- (te5_smoke's curls are wispier than the pass-4 puff, so they are drawn bigger)
		em.smoke = sizeFix(pe(void, "smoke5", 1.0, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = rate(10, 4), Lifetime = n(3.5, 4.5),
			Speed = n(1.4, 2.4), Drag = 0.35, Acceleration = Vector3.new(0, 0.4, 0), Size = seq({ { 0, 5 * smS }, { 1, 14 * smS } }),
			Transparency = seq({ { 0, 1 }, { 0.2, 0.16 }, { 0.7, 0.45 }, { 1, 1 } }), Color = ColorSequence.new(SMOKE), Rotation = n(0, 360),
			RotSpeed = n(-25, 25), ZOffset = -3 }), smS, { { 0, 5 }, { 1, 14 } })
		em.smokeMoon = hi and sizeFix(pe(moon, "smoke5", 1.6, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = 5, Lifetime = n(3.5, 4.5),
			Speed = n(0.9, 1.5), Drag = 0.35, Acceleration = Vector3.new(0, 0.3, 0), Size = seq({ { 0, 3.5 * smS }, { 1, 9 * smS } }),
			Transparency = seq({ { 0, 1 }, { 0.2, 0.32 }, { 0.7, 0.55 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(176, 176, 178)),
			Rotation = n(0, 360), RotSpeed = n(-20, 20), ZOffset = -3 }, { 0.1, 0.4 }), smS, { { 0, 3.5 }, { 1, 9 } })
		-- P5: slow four-point glints bloom on the bezel metal and fade (grow, hold, shrink: never a flash).
		-- STUDIO-VERIFY: Disc ShapePartial = the inner-radius fraction (0.86 -> the annulus over the bezel), oriented by EmissionDirection
		local glintT = seq({ { 0, 0.1 }, { 1, 0.1 } })
		pe(hosts.rimGlint, "glint5", 3.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.86, EmissionDirection = N_.Back, Rate = rate(9, 3),
			Lifetime = n(1.6, 2.2), Size = seq({ { 0, 0 }, { 0.35, 1.9, 0.5 }, { 0.65, 1.9, 0.5 }, { 1, 0 } }), Transparency = glintT,
			LockedToPart = true, ZOffset = 1.0, Rotation = n(0, 90) }, { 0.5, 1 }, WHITE_BR)
		if hi then
			-- P13: time-dust orbits the bezel: glints born on the rim ride a ring that turns clockwise with the hands (locked
			-- to it), so the clock wears a slow halo of moving light
			pe(hosts.timeDust, "glint5", 4.4, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.88, EmissionDirection = N_.Back, Rate = 14,
				Lifetime = n(4, 5), Size = seq({ { 0, 0 }, { 0.3, 1.4, 0.3 }, { 0.7, 1.4, 0.3 }, { 1, 0 } }), Transparency = glintT,
				LockedToPart = true, ZOffset = 1.0, Rotation = n(0, 90), RotSpeed = n(-15, 15) }, { 0.5, 1 }, WHITE_BR)
			-- the event horizon's glow (above): three soft rings alive at once, Rate 1 x 3 s
			pe(hosts.horizon, "halo", 1.0, { Rate = 1, Lifetime = n(3, 3), Size = n(11.2, 11.2), LockedToPart = true,
				Transparency = seq({ { 0, 1 }, { 0.2, 0.12 }, { 0.8, 0.12 }, { 1, 1 } }), Rotation = n(0, 360), RotSpeed = n(-8, 8), ZOffset = 0.4 },
				{ 0.4, 1 }, { 1.6, 3.0 })
		end
		-- P6: three scales of air: silver dust (fewer, bigger: the old 1-4 px specks never read), mid glints, and big slow
		-- bokeh between the camera and the wearer (showcase framings only)
		pe(hosts.air, "mote", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(8, 4), Lifetime = n(6, 9), Speed = n(0.1, 0.3),
			SpreadAngle = Vector2.new(180, 180), Size = n(0.22, 0.40), Transparency = seq({ { 0, 1 }, { 0.2, 0.1 }, { 0.8, 0.15 }, { 1, 1 } }),
			Color = ColorSequence.new(Color3.fromRGB(226, 230, 240)) }, { 0.2, 0.8 }, { 1.4, 2.2 })
		pe(hosts.air, "glint5", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(5, 1.5), Lifetime = n(4, 6), Speed = n(0.2, 0.5),
			SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.3, 0.7, 0.2 }, { 0.7, 0.7, 0.2 }, { 1, 0 } }),
			Transparency = seq({ { 0, 1 }, { 0.3, 0.1 }, { 0.7, 0.1 }, { 1, 1 } }), Rotation = n(0, 90), RotSpeed = n(-20, 20) }, { 0.4, 1 }, WHITE_BR)
		em.bokeh = hi and pe(hosts.bokeh, "bokeh", 3.0, { Shape = BOX, ShapeStyle = VOLUME, Rate = 0.5, Lifetime = n(5, 7), Speed = n(0.1, 0.25),
			SpreadAngle = Vector2.new(180, 180), Size = n(1.2, 2.4), Transparency = seq({ { 0, 1 }, { 0.25, 0.72 }, { 0.75, 0.72 }, { 1, 1 } }),
			Color = ColorSequence.new(Color3.fromRGB(232, 236, 246)), Rotation = n(0, 360), RotSpeed = n(-4, 4) }, { 0.3, 0.8 }, { 1.2, 1.8 }, "bokeh")
		if hi then
			-- P7: one low mist bank at the ankles, only while standing on the ground
			pe(hosts.floor, "smoke5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, EmissionDirection = N_.Top, Rate = 2.5, Lifetime = n(6, 8),
				Speed = n(0.1, 0.25), Size = seq({ { 0, 8 }, { 1, 14 } }), Transparency = seq({ { 0, 1 }, { 0.3, 0.80 }, { 0.7, 0.82 }, { 1, 1 } }),
				Color = ColorSequence.new(MIST), LockedToPart = true, Rotation = n(0, 360), RotSpeed = n(-6, 6) }, nil, nil, "ground")
		end
		-- P8: motes rise off the turning arms and swirl with them; black ash flakes rise against them
		pe(hosts.floor, "mote", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top, Rate = rate(18, 8),
			Lifetime = n(2.6, 3.6), Speed = n(0.5, 1.2), Acceleration = Vector3.new(0, 0.35, 0), Drag = 0.2,
			Size = seq({ { 0, 0 }, { 0.2, 1.2, 0.3 }, { 1, 0 } }), Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.8, 0.15 }, { 1, 1 } }),
			LockedToPart = true, ZOffset = 0.2 }, WHITE_LE, WHITE_BR)
		if hi then
			-- (te5_ash is one charred flake; its random rotation and tumble make every particle a different shape)
			pe(hosts.floor, "ash5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top, Rate = 8,
				Lifetime = n(3, 4.5), Speed = n(0.8, 2.0), Acceleration = Vector3.new(0, 0.3, 0), Drag = 0.4, Size = n(0.4, 0.6),
				Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.75, 0.2 }, { 1, 1 } }), Color = ColorSequence.new(ASH), Rotation = n(0, 360),
				RotSpeed = n(-90, 90) })
			-- P9: a vortex funnel: streaks spiral inward and climb into the balance wheel
			local p9 = { Rate = 16, Lifetime = n(1.7, 2.0), Speed = n(2.8, 3.2), Acceleration = Vector3.new(0, 1.0, 0),
				Size = seq({ { 0, 0.42 * stS }, { 1, 0.1 * stS } }), Transparency = seq({ { 0, 1 }, { 0.12, 0.05 }, { 0.85, 0.1 }, { 1, 1 } }),
				LockedToPart = true, Orientation = VPAR, Rotation = stRot }
			if CONFIG.SWIRL_POINTS then
				p9.EmissionDirection, p9.SpreadAngle = N_.Front, Vector2.new(0, 10)
				sizeFix(pe(rimPoint(hosts.funnel, 5.3), "streak5", 4.8, p9, WHITE_LE, WHITE_BR), stS, { { 0, 0.42 }, { 1, 0.1 } })
			else
				p9.Shape, p9.ShapeStyle, p9.ShapeInOut, p9.EmissionDirection = CYL, SURFACE, INWARD, N_.Top
				sizeFix(pe(hosts.funnel, "streak5", 4.8, p9, WHITE_LE, WHITE_BR), stS, { { 0, 0.42 }, { 1, 0.1 } })
			end
		end
		-- P10: the palms drink the streams: silver streaks converge into one palm, ink streaks into the other (locked to the
		-- palm, so they still converge on it while the wearer walks). STUDIO-VERIFY: Sphere + Surface + Inward converges on
		-- the centre (fallback: Outward with a negative Speed)
		local function intake(host, color, le, br)
			sizeFix(pe(host, "streak5", 5.2, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = INWARD, Rate = rate(14, 6), Lifetime = n(0.85, 0.95),
				Speed = n(1.35, 1.45), Size = seq({ { 0, 0.3 * stS }, { 1, 0.05 * stS } }), Transparency = seq({ { 0, 1 }, { 0.25, 0.05 }, { 1, 0.2 } }),
				Color = ColorSequence.new(color), ZOffset = 0.2, Orientation = VPAR, Rotation = stRot, LockedToPart = true }, le, br),
				stS, { { 0, 0.3 }, { 1, 0.05 } })
		end
		intake(hosts.palmMoon, WHITE, WHITE_LE, WHITE_BR)
		intake(hosts.palmVoid, INK, nil, nil)
		-- P11: time drips off each sole onto the balance wheel below
		for _, a in ipairs({ soleL, soleR }) do
			if a then
				pe(a, "mote", 5.2, { EmissionDirection = N_.Bottom, Rate = rate(4, 2), Lifetime = n(0.6, 0.8), Speed = n(0.1, 0.3),
					SpreadAngle = Vector2.new(8, 8), Acceleration = Vector3.new(0, -5, 0), Size = seq({ { 0, 0.18 }, { 1, 0.08 } }),
					Transparency = seq({ { 0, 0.1 }, { 0.8, 0.2 }, { 1, 1 } }) }, WHITE_LE, WHITE_BR, "foot")
			end
		end
		-- P12: while the wearer flies or runs fast, silver streaks stream out behind the body (off when slow)
		sizeFix(pe(hosts.trail, "streak5", 5.2, { EmissionDirection = N_.Back, Rate = rate(14, 6), Lifetime = n(0.45, 0.6), Speed = n(4, 6),
			SpreadAngle = Vector2.new(10, 10), Size = seq({ { 0, 0.5 * stS }, { 1, 0.1 * stS } }),
			Transparency = seq({ { 0, 0.2 }, { 0.6, 0.3 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(226, 230, 240)),
			Orientation = VPAR, Rotation = stRot }, WHITE_LE, WHITE_BR, "speed"), stS, { { 0, 0.5 }, { 1, 0.1 } })
		-- which emitters belong to the parts that turn see-through while another wearer's aura is in your way (their smoke,
		-- swirl, dust, shards, glints, horizon and palm streaks must not stay solid across your character)
		local ghostHost = { [moon] = true, [void] = true }
		for _, h in ipairs({ "swirl", "rimGlint", "shardFeed", "horizon", "timeDust", "palmMoon", "palmVoid" }) do
			if hosts[h] then ghostHost[hosts[h]] = true end
		end
		for _, e in ipairs(emitters) do
			local par = e[1].Parent
			if par and par:IsA("Attachment") then par = par.Parent end
			e[6] = ghostHost[par] == true
		end
	end
	table.sort(emitters, function(a, b) return a[2] < b[2] end)

	-- lights: the moon's key light (above) and the wheel's underlight on the feet (night only, high quality)
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
	-- the solid parts that turn see-through while another wearer's aura stands between you and your camera: the clock and
	-- the orbs (ghostParts), and on their own the rings (ringParts: a visitor standing beside the wearer looks through
	-- their rings only, never through their clock). The rings also fade out on the near-camera rule.
	local ghostParts, ringParts = {}, {}
	for _, i in ipairs(solids) do
		if PH[i] == ARM or PH[i] == ARMD then
			table.insert(ringParts, PP[i])
		elseif PG[i] <= GHF or PG[i] == GMOONF then
			table.insert(ghostParts, PP[i])
		end
	end
	-- (Beams and ParticleEmitters carry a hidden LocalTransparencyModifier too; if it cannot be written, a ghosted aura's
	-- beams and smoke switch off instead)
	st.fxLtm = pcall(function()
		sb[1].LocalTransparencyModifier = 0
		emitters[1][1].LocalTransparencyModifier = 0
	end)
	-- this wearer's dais sits a hair above (or below) the others', so two pools side by side never share a plane (Roblox
	-- z-fights coplanar faces as a crawling shimmer). The layer surfaces repeat every 0.055 studs (engraving, base,
	-- floor), so the three lifts are a third of that apart: the owner 0, other players 0.018 or 0.037.
	do
		local uid = 0
		pcall(function()
			local plr = Players:GetPlayerFromCharacter(char)
			uid = plr and plr.UserId or #char.Name
		end)
		st.layer = ctx.isLocal and 0 or 0.0183 * (1 + uid % 2)
	end

	---------------------------------------------------------------- the wearer's own screen grade (real equips only)
	-- It starts with the first frame the player can actually see (not while the roll cutscene still holds the camera), eases
	-- back when the assembly ends, and never snaps: hiding or unequipping eases it out too.
	local grade
	st.gradeWanted = CONFIG.GRADE and ctx.isLocal and os.clock() - (spawnedAt[char] or 0) > 4
	local function gradeTo(target, dur, thenDestroy)
		if not grade then return end
		if liveGradeTween then liveGradeTween:Cancel() end
		liveGradeTween = TweenService:Create(grade, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), target)
		liveGradeTween:Play()
		if thenDestroy then
			gradeToken += 1
			local tok, g = gradeToken, grade
			grade = nil -- (this aura lets go of it; a new equip within the fade takes it over instead of stacking a second one)
			task.delay(dur + 0.05, function()
				if gradeToken == tok and liveGrade == g then
					g:Destroy()
					liveGrade, liveGradeTween = nil, nil
				end
			end)
		end
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
	st.ltmOn, st.hlF, st.lightsOn, st.haloZ, st.hlA, st.fb, st.lod = false, -1, false, 1, 0, 0, 1
	if age >= ASM_END then void.Size = voidSize else void.Size = voidSize * (0.6 / 8) end

	---------------------------------------------------------------- event writes (never per frame in steady state)
	local function refreshEmitters()
		for _, e in ipairs(emitters) do
			local want = e[4] and near and alphaOn
			local kind = e[3]
			if kind == "ground" then want = want and grounded
			elseif kind == "bokeh" then want = want and not bokehNear
			elseif kind == "foot" then want = want and visible and st.footOk and not st.seated -- (they live on the character)
			elseif kind == "speed" then want = want and st.speedOn end
			if e[6] and st.ghostGui and not st.fxLtm then want = false end -- (a ghosted aura without emitter LTM: smoke off)
			if want ~= e[5] then
				e[1].Enabled = want
				e[5] = want
			end
		end
	end
	-- the beams: the near-only ones fade out past ~110 studs (and the far beacon in), the palm streams switch off in first
	-- person (they would converge on hands just under the lens); written only when they change
	local function refreshBeams()
		local lod = st.lod
		for _, b in ipairs(beams) do
			local want = true
			if b[8] then want = lod > 0 elseif b[9] then want = lod < 1 end
			if b[10] and st.fpOn then want = false end
			if not b[9] and st.ghostGui and not st.fxLtm then want = false end
			if want ~= b[11] then
				b[1].Enabled = want
				b[11] = want
			end
		end
	end
	-- the beam fade steps: each beam's Transparency is one of its 21 precomputed sequences (no allocation)
	local function beamSteps(fb)
		st.fb = fb
		local lod = st.lod
		for _, b in ipairs(beams) do
			local f = fb
			if b[8] then f *= lod elseif b[9] then f *= 1 - lod end
			local q = clamp(math.floor(f * 20 + 0.5), 0, 20)
			if q ~= b[3] then
				b[1].Transparency = b[2][q]
				b[3] = q
			end
		end
	end
	-- the lights: brightness fades with the assembly, the night, the framework's alpha and the far-detail fade; written
	-- only when it changes; switched on and off only while dark (Brightness 0), so a light never pops
	local function lightLevels()
		local l = max(nq, 0) * st.lod
		if keyLight then
			local b = 1.5 * l * max(st.kf, 0)
			if b ~= st.kB then
				keyLight.Brightness = b
				st.kB = b
			end
		end
		if wheelLight then
			local b = 0.9 * l * max(st.wf, 0)
			if b ~= st.wB then
				wheelLight.Brightness = b
				st.wB = b
			end
		end
	end
	local function refreshLights()
		local on = visible and nq > 0 and st.lod > 0
		if on ~= st.lightsOn then
			st.lightsOn = on
			if keyLight then keyLight.Enabled = on end
			if wheelLight then wheelLight.Enabled = on end
		end
		refreshBeams()
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
	-- the Highlight's fill and outline strength (1 - transparency) at night factor q. The ink outline is for the bright sky
	-- at a distance: close up (Roblox's default zoom) the metal fills the view and reads by its own shading, so the outline
	-- eases off (czq: the camera-closeness factor in 0.05 steps)
	local function hlFill(q) return (1 - CONFIG.HIGHLIGHT_FILL) * (1 - q) + 0.20 * q end
	local function hlOut(q) return (1 - CONFIG.HIGHLIGHT_OUTLINE) * (1 - 0.6 * st.czq) * (1 - q) + 0.30 * q end
	-- the Highlight follows its fade (st.hlA: assembly x alpha), the night, the camera closeness and, for another player's
	-- aura, the far-detail fade; fill and outline are each written only when they moved (snapped exactly at the ends)
	local function toneLevels(thr)
		if not tone then return end
		local fh = st.hlA * (remote and st.lod or 1)
		local q = max(nq, 0)
		local fill, out = 1 - hlFill(q) * fh, 1 - hlOut(q) * fh
		local edge = fh <= 0 or fh >= 1
		if fill ~= st.hlF and (abs(fill - st.hlF) >= thr or edge) then
			tone.FillTransparency = fill
			st.hlF = fill
		end
		if out ~= st.hlO and (abs(out - st.hlO) >= thr or edge) then
			tone.OutlineTransparency = out
			st.hlO = out
		end
	end
	-- (one rule for the Highlight's slot: off while ghosted, and off for another player's aura once it is far away, which
	-- frees one of the client's 31 Highlights and its outline pass)
	local function toneOn()
		if tone then
			local on = not st.ghostGui and (ctx.isLocal or st.lod > 0)
			if tone.Enabled ~= on then tone.Enabled = on end
		end
	end
	local function applyLod()
		lightLevels()
		refreshLights()
		beamSteps(st.fb)
		toneLevels(0)
		toneOn()
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
		if hosts.beaconBeam then hosts.beaconBeam.Color = ColorSequence.new(INK:Lerp(WHITE, q)) end
		lightLevels()
		if em.bokeh then em.bokeh.Rate = 0.5 + 0.7 * q end
		if haloEntry then haloEntry[2] = 1 - (0.35 + 0.2 * q) * st.haloZ end
		if corona then
			coronaEntry[2] = 1 - 0.4 * q
			corona.Enabled = q > 0.05 and not st.ghostGui
		end
		if settled then
			-- (after the assembly the night values are written straight away; during it the fades pick them up)
			local a = alphaW
			if haloEntry then
				local tr = 1 - (1 - haloEntry[2]) * a
				if tr ~= haloEntry[5] then
					haloIm.ImageTransparency = tr
					haloEntry[5] = tr
				end
			end
			if coronaEntry then
				local tr = 1 - (1 - coronaEntry[2]) * a
				if tr ~= coronaEntry[5] then
					coronaEntry[1].ImageTransparency = tr
					coronaEntry[5] = tr
				end
			end
		end
		toneLevels(0)
		refreshLights()
	end
	-- the fades: every part, image, beam and light goes from invisible to its rest value in its own window (times the
	-- framework's fade-in alpha); a value is written only when it moved enough, and snapped exactly at the ends (no blinking)
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
		beamSteps(fb)
		local kf, wf = a, a
		if asm then kf, wf = a * smooth((age - 0.6) / 1.0), a * smooth((age - 4.6) / 1.0) end
		if abs(kf - st.kf) >= thr or abs(wf - st.wf) >= thr or ((kf <= 0 or kf >= 1) and kf ~= st.kf) or ((wf <= 0 or wf >= 1) and wf ~= st.wf) then
			st.kf, st.wf = kf, wf
			lightLevels()
		end
		-- (the silver tone comes in only once every silver part is solid: a Highlight paints a part that is still fading
		-- in at full strength, which would make the rising dais rim pop)
		st.hlA = asm and a * smooth((age - 5.65) / 0.7) or a
		toneLevels(thr)
	end
	-- another wearer's aura between you and your camera: its clock and orbs fade to a ghost in 3 steps (one burst of
	-- LocalTransparencyModifier writes per step, none while it holds) with their smoke, glints and streams, and its GUIs
	-- and silver tone switch off meanwhile
	local function setGhost(q)
		st.ghostQ = q
		local m = 0.75 * q
		for _, p in ipairs(ghostParts) do p.LocalTransparencyModifier = m end
		if st.fxLtm then
			for _, e in ipairs(emitters) do
				if e[6] then e[1].LocalTransparencyModifier = m end
			end
			for _, b in ipairs(beams) do
				if not b[9] then b[1].LocalTransparencyModifier = m end
			end
		end
		local off = q >= 0.5
		if off ~= st.ghostGui then
			st.ghostGui = off
			for _, g in ipairs(ghostGuis) do g.Enabled = not off end
			toneOn()
			if corona then corona.Enabled = nq > 0.05 and not off end
			if not st.fxLtm then
				refreshEmitters()
				refreshBeams()
			end
		end
	end
	-- the rings' see-through: their own ghost (another wearer's rings in your way) or the near-camera fade, whichever is more
	local function writeRings()
		local m = max(0.75 * st.armGQ, st.armQ)
		for _, p in ipairs(ringParts) do p.LocalTransparencyModifier = m end
	end
	local function segDist(p, a, ab, len2) -- distance from point p to the segment a -> a + ab
		local t = clamp((p - a):Dot(ab) / len2, 0, 1)
		return (a + ab * t - p).Magnitude
	end

	---------------------------------------------------------------- the frame
	function fx.update(dt, s)
		-- (hidden, e.g. under the roll cutscene's camera, or too far away: nothing advances, so the assembly and the grade
		-- wait for the player, whether or not the framework keeps calling update)
		if destroyed or not visible then return end
		if remote and not near then
			-- another player's aura past ~110 studs (about 40 px tall) runs every other frame, with both frames' time: the
			-- springs and spins stay exact and it costs half
			st.skipDt += dt
			st.skipN = 1 - st.skipN
			if st.skipN == 1 then return end
			dt, st.skipDt = st.skipDt, 0
		elseif st.skipDt > 0 then
			dt += st.skipDt
			st.skipDt = 0
		end
		if dt > 0.1 then dt = 0.1 end
		age += dt
		local asm = age < ASM_END
		local t, now, g = s.t, s.now, s.glide
		local cf = s.cf
		local O = cf.Position + Vector3.new(0, s.hover, 0)
		local a = s.alpha
		if type(a) ~= "number" or a ~= a then a = 1 end
		a = clamp(a, 0, 1)
		local on = a >= 0.6 -- (the emitters follow the framework's fade only: the reveal below starts from an empty sky anyway)
		if st.revealA < 1 then st.revealA = min(1, st.revealA + dt / 0.4) end -- (fading back in after a long hide)
		a *= st.revealA
		-- (the first frame after a long hide: the clock's swing, the zoom layout, the dais and the heights start where they
		-- belong instead of springing in from where they were when the aura was hidden)
		local snap = st.snap
		st.snap = false
		-- (shown again since the last frame: parent it now, so nothing is ever drawn at the positions it had when hidden)
		if st.pendingRoot then
			st.pendingRoot = false
			root.Parent = ctx.container
		end
		if st.pendingGroups then
			st.pendingGroups = false
			setGroups()
		end
		-- the wearer's own grade starts with the first frame they can see (never over a scripted camera, e.g. a cutscene)
		if st.gradeWanted and not st.gradeStarted then
			st.gradeStarted = true
			local camG = workspace.CurrentCamera
			if camG and camG.CameraType == Enum.CameraType.Scriptable then
				st.gradeStarted = false
			elseif camG then
				if liveGrade and liveGrade.Parent then
					grade = liveGrade -- (an earlier equip's grade still easing out: take it over, never stack a second one)
				else
					grade = new("ColorCorrectionEffect", { Name = "TheEndReveal" }, camG)
					liveGrade = grade
				end
				gradeToken += 1
				gradeTo(GRADE_ON, 1.2)
			end
		end
		if grade and not st.gradeOut and age >= 5.8 then
			st.gradeOut = true
			gradeTo(GRADE_OFF, 2.2, true)
		end

		-- 0. the wearer's state: how fast they travel (a teleport is ignored; on the ground only the horizontal speed counts,
		-- so a jump is not a flight), and whether they sit
		local lastO = st.lastO
		st.lastO = O
		if lastO then
			local dO = O - lastO
			if grounded then dO = Vector3.new(dO.X, 0, dO.Z) end
			local d = dO.Magnitude
			if d < 30 and dt > 0 then
				st.speed += (d / dt - st.speed) * (1 - exp(-6 * dt))
				if d / dt > 4 then
					local u = dO / d
					st.tdir = st.tdir and (st.tdir + (u - st.tdir) * (1 - exp(-4 * dt))) or u
				end
			end
		end
		local fast = (st.speedOn and st.speed > 8) or st.speed > 12
		if fast ~= st.speedOn then
			st.speedOn = fast
			refreshEmitters()
		end
		st.speedT += ((fast and 1 or 0) - st.speedT) * (1 - exp(-3 * dt))
		local seated = ctx.hum ~= nil and ctx.hum.Sit == true
		if seated ~= st.seated then
			st.seated = seated
			refreshEmitters()
		end
		st.sitT += ((seated and 1 or 0) - st.sitT) * (1 - exp(-5 * dt))

		-- 1. frames: the wearer (W), this client's viewer (V), the dais, the clock (K)
		local lv = cf.LookVector
		yawW = wrapPi(yawW + wrapPi(atan2(-lv.X, -lv.Z) - yawW) * (1 - exp(-5 * dt)))
		local W = CFrame.new(O) * CFrame.Angles(0, yawW, 0)
		local cam = workspace.CurrentCamera
		local camPos = lastCamPos
		if cam then
			camPos = cam.CFrame.Position
			lastCamPos = camPos
		end
		local v = O - camPos
		local dh = sqrt(v.X * v.X + v.Z * v.Z)
		-- how close the camera is (smoothed): under ZOOM_FAR studs the layout eases into its close-camera form, so at Roblox's
		-- default zoom the whole dial and both orbs are on screen; in first person the owner's clock rises into the sky
		st.zoomD = snap and dh or st.zoomD + (dh - st.zoomD) * (1 - exp(-3 * dt))
		local cz = smooth((CONFIG.ZOOM_FAR - st.zoomD) / (CONFIG.ZOOM_FAR - CONFIG.ZOOM_NEAR))
		local fp = (ctx.isLocal and CONFIG.FIRST_PERSON_LIFT) and smooth((4 - st.zoomD) / 2.5) or 0
		local czq = math.floor(cz * 20 + 0.5) / 20
		if czq ~= st.czq then
			st.czq = czq
			toneLevels(0) -- (the ink outline eases off close up)
		end
		if haloEntry then
			-- (the white ball's soft halo fades out as the camera comes close, where the leaning dial plane would cut it)
			local hz = math.floor((1 - smooth((cz - 0.3) / 0.4)) * 10 + 0.5) / 10
			if hz ~= st.haloZ then
				st.haloZ = hz
				haloEntry[2] = 1 - (0.35 + 0.2 * max(nq, 0)) * hz
				if settled then
					local tr = 1 - (1 - haloEntry[2]) * alphaW
					haloIm.ImageTransparency = tr
					haloEntry[5] = tr
				end
			end
		end
		local V
		if VIEWER then
			-- the clock swings to the far side of the wearer from this camera through a critically damped spring (no overshoot).
			-- In first person (the camera inside the wearer) "beyond the wearer" is where the camera looks, so the orbs hang
			-- beside and behind the view instead of filling it when the player turns; straight above it holds still
			if dh > 1.5 and dh > 0.2 * abs(v.Y) then
				yawTarget = atan2(-v.X, -v.Z)
			elseif cam and abs(v.Y) < 4 then
				local lk = cam.CFrame.LookVector
				if abs(lk.Y) < 0.97 then yawTarget = atan2(-lk.X, -lk.Z) end
			end
			if snap then psi, psiVel = yawTarget, 0 end
			local k = CONFIG.YAW_SPRING
			local x = wrapPi(psi - yawTarget)
			local e = exp(-k * dt)
			local tmp = (psiVel + k * x) * dt
			x = (x + tmp) * e
			psiVel = (psiVel - k * tmp) * e
			-- a fast camera swing never throws the clock and the orbs round into the lens: the spring runs on underneath, but
			-- the lag that is shown eases into a ceiling of YAW_LAG_MAX (and the spring itself stops at twice that)
			local L = rad(CONFIG.YAW_LAG_MAX)
			if x > 2 * L then
				x, psiVel = 2 * L, min(psiVel, 0)
			elseif x < -2 * L then
				x, psiVel = -2 * L, max(psiVel, 0)
			end
			psi = wrapPi(yawTarget + x)
			if psi ~= psi or psiVel ~= psiVel then psi, psiVel, x = yawTarget, 0, 0 end
			V = CFrame.new(O) * CFrame.Angles(0, yawTarget + L * math.tanh(x / L), 0)
		else
			V = W * FLIP
		end

		-- the dais: stays on the ground for walks and jumps (even Roblox's default 7.2-stud jump), floats under a flyer, and on
		-- a seat sits at the feet line instead of on the seat. It drops at once (no lag walking downhill), rises gently
		local feetY = cf.Position.Y - s.legLen
		local gnd = s.ground
		local hG = gnd and (feetY - gnd.Y)
		local isGrounded = hG ~= nil and hG < (grounded and CONFIG.AIR_ON or CONFIG.AIR_OFF)
		local target
		if isGrounded then
			if seated then
				target = min(gnd.Y, feetY)
			else
				target = gnd.Y
				lastGroundY = target
			end
		elseif CONFIG.DAIS_FLOAT or not lastGroundY then
			target = feetY + s.hover - 2.4
		else
			target = lastGroundY
		end
		if snap then daisY = nil end
		if daisY then daisY += (target - daisY) * (1 - exp(-(target < daisY and 30 or 8) * dt)) else daisY = target end
		local dY = daisY + st.layer
		local Gd = CFrame.new(O.X, dY, O.Z)
		-- the height the clock and the balance ride: a heavy spring, so a jump (or a step) does not throw a 28-stud watch
		-- up and down with the body; it catches up fast when flying or sitting
		if snap or not st.kY then
			st.kY, st.kYv = O.Y, 0
		else
			local kk = (isGrounded and not seated) and 4 or 12
			local x = st.kY - O.Y
			local e = exp(-kk * dt)
			local tmp = (st.kYv + kk * x) * dt
			x = (x + tmp) * e
			st.kYv = (st.kYv - kk * tmp) * e
			st.kY = O.Y + x
		end
		local Vk = V + Vector3.new(0, st.kY - O.Y, 0)

		-- the clock: lower, further back and leaning back when the camera is close; behind the seat when sitting; never into
		-- the dais (its lowest edge stays 0.24 above the dais rim's top, 0.54 above the floating galaxy layers)
		local sitT = st.sitT
		local Hc = CONFIG.CLOCK_HEIGHT - 0.5 * g - 3 * cz + 16 * fp - 3 * sitT
		local Dc = CONFIG.CLOCK_DIST + 2 * g + (remote and CLOSE.distRemote or CLOSE.dist) * cz + 6 * fp - 2 * sitT
		local tilt = rad(clamp(CONFIG.CLOCK_TILT + 14 * g + 4 * st.speedT + CLOSE.tilt * cz - 32 * fp, -10, 50))
		local minHc = dY + 1.2 - st.kY + 14.2 * cos(tilt) + 1.44 * sin(tilt)
		if Hc < minHc then Hc = minHc end
		local K = Vk * CFrame.new(0, Hc, -Dc) * CFrame.Angles(0, rad(9 + 5 * sin(TAU * t / 16)), 0) * CFrame.Angles(-tilt, 0, 0)
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
		GCF[GDUST] = K * CFrame.new(0, 0, 1.3) * CFrame.Angles(0, 0, -((rad(20) * now) % TAU)) -- (the time-dust ring turns clockwise)
		GCF[GCROWN] = crownY ~= 0 and K * CFrame.new(0, crownY, 0) or K

		-- 3. the dais layers and the balance wheel (just below the soles, never into the galaxy; on the dais when seated)
		local gdir = CONFIG.GALAXY_DIR
		GCF[GDAIS] = Gd
		GCF[GG0] = Gd * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, (rad(-6) * gdir * now) % TAU, 0)
		GCF[GG1] = Gd * CFrame.new(0, 0.42, 0) * CFrame.Angles(0, (rad(9) * gdir * now) % TAU, 0)
		GCF[GG2] = Gd * CFrame.new(0, 0.66, 0) * CFrame.Angles(0, (rad(-16) * gdir * now) % TAU, 0)
		GCF[GENG] = Gd * CFrame.new(0, 0.04, 0) * CFrame.Angles(0, (rad(2.5) * gdir * now) % TAU, 0)
		GCF[GFUNNEL] = Gd * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, (rad(-70) * CONFIG.FUNNEL_DIR * t) % TAU, 0)
		local wheelAngle = rad(160) * sin(TAU * t / 3.2) * (asm and smooth((age - 4.6) / 1.2) or 1)
		local wheelY = O.Y - s.legLen - 0.9
		wheelY += (dY + 1.2 - wheelY) * sitT
		if wheelY < dY + 1.2 then wheelY = dY + 1.2 end
		local Bw = CFrame.new(O.X, wheelY, O.Z) * CFrame.Angles(0, wheelAngle, 0)
		GCF[GWHEEL] = Bw

		-- 4. the armillary (body-anchored, upright: leaning it with the glide laid the dark equator across the head line from
		-- the follow camera); on equip each ring rises from lying flat on the dais. It lifts a little whenever a ring's lowest
		-- edge would dip into the galaxy layers (small avatars, slopes, sitting)
		local Wr = W.Rotation
		local R1 = Wr * CFrame.Angles(0, (rad(8) * t) % TAU, 0) * TILT33
		local R2 = R1 * CFrame.Angles(rad(57) + rad(18) * sin(TAU * t / 19), 0, 0)
		local R3 = R2 * CFrame.Angles(0, rad(23.4) + rad(14) * sin(TAU * t / 27 + 1.1), 0)
		local n1, n2, n3 = R1.ZVector.Y, R2.ZVector.Y, R3.ZVector.Y
		local drop = max(6.30 * sqrt(max(0, 1 - n1 * n1)) + 0.13 * abs(n1), 5.52 * sqrt(max(0, 1 - n2 * n2)) + 0.21 * abs(n2),
			4.90 * sqrt(max(0, 1 - n3 * n3)) + 0.11 * abs(n3))
		local baseY = 1.3 - 1.0 * sitT
		local liftT = max(0, dY + 0.96 - (O.Y + baseY - drop))
		st.lift = snap and liftT or st.lift + (liftT - st.lift) * (1 - exp(-6 * dt))
		if st.lift < liftT - 0.3 then st.lift = liftT - 0.3 end
		local A0p = O + Vector3.new(0, baseY + st.lift, 0)
		local F1 = CFrame.new(A0p) * R1
		local F2 = CFrame.new(A0p) * R2
		local F3 = CFrame.new(A0p) * R3
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
						local ang = SHARD_A[i]
						local sp = K * Vector3.new(14 * sin(ang), 14 * cos(ang), 0)
						c = CFrame.new(sp + (c.Position - sp) * easeOutBack(u)) * c.Rotation
					end
				end
				GCF[GSHARD0 + 1 + i] = c
			end
		end

		-- 5. the balance: moon and void on the viewer's left and right of an invisible beam, rocking like scales (closer in
		-- and a little behind the wearer when the camera is close, so both stay on screen)
		local sway = asm and smooth((age - 1.8) / 1.2) or 1
		-- (the void's centre stays >= 13.4 studs out horizontally, so its 13-stud disc always clears the rings' 6.3 reach)
		-- (in first person they move back beside the view: about 97° off the line of sight, outside the 102° field of view)
		local arm = 12.5 - CLOSE.arm * cz
		local orbZ = 1.5 - CLOSE.orbZ * cz + 12 * fp
		local Pv = Vk * CFrame.new(0, 6.0 - CLOSE.orbY * cz, orbZ) * CFrame.Angles(0, 0, rad(10) * sin(TAU * t / 10) * sway)
		local moonC = Pv * Vector3.new(-arm, 0, 0)
		local voidC = Pv * Vector3.new(arm, 0, 0)
		local focus = O + Vector3.new(0, 1, 0)
		if asm and age < 1.8 then
			local sp = Vk * Vector3.new(-arm, -9, orbZ) -- (the moon rises out of the dais)
			moonC = sp + (moonC - sp) * easeOutBack((age - 0.6) / 1.2)
		end
		GCF[GMOON] = CFrame.lookAt(moonC, focus)
		GCF[GVOID] = CFrame.lookAt(voidC, focus)
		if moonFace then
			-- (the face rides the camera ray, 4.4 studs in front of the moon's centre, turned to face the camera: +z toward
			-- it, as the clock frame, so the disc's Left face looks at the camera)
			local dmv = camPos - moonC
			local dmm = dmv.Magnitude
			local fdir = dmm > 1e-3 and dmv / dmm or -V.LookVector
			local fpos = moonC + fdir * 4.4
			GCF[GMOONF] = CFrame.lookAt(fpos, fpos - fdir, abs(fdir.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis)
		end
		-- the void's camera-facing details: the photon ring sits on the silhouette circle the camera sees (radius rt)
		local dv = camPos - voidC
		local dm = dv.Magnitude
		local nrm = dm > 1e-3 and dv / dm or -V.LookVector
		local dc = max(dm, 5)
		local up = abs(nrm.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis
		rt = 4 * sqrt(1 - 16 / (dc * dc))
		GCF[GPF] = CFrame.lookAt(voidC + nrm * (16 / dc), voidC, up)
		GCF[GHF] = CFrame.lookAt(voidC + nrm * 4.1, voidC, up)
		local Dk = CFrame.new(voidC) * V.Rotation * TILTACC
		local dir = CONFIG.ACC_DIR -- (the accretion texture's streaks wind clockwise outward: a counter-clockwise turn makes them trail)
		if asm then accExtra = (accExtra + rad(360 * exp(-3 * max(0, age - 0.3))) * dt * dir) % TAU end
		GCF[GACC] = Dk * CFrame.Angles(0, (rad(40) * now * dir + accExtra) % TAU, 0)
		GCF[GSWIRL] = Dk * CFrame.Angles(0, (rad(85) * now * dir) % TAU, 0)
		local az = atan2(voidC.X - O.X, voidC.Z - O.Z)
		GCF[GRIBEND] = Gd * CFrame.new(13.2 * sin(az), 0.3, 13.2 * cos(az)) * CFrame.Angles(0, az, 0)
		GCF[GFEED] = CFrame.lookAt(K * FEED_PT, voidC)

		-- 6. the air (turned to face the way the wearer travels: the speed trail streams out behind) and the palms
		local camDist = (camPos - O).Magnitude
		local td = st.tdir
		if td and td.Magnitude > 0.5 then
			local tu = td.Unit
			GCF[GAIR] = CFrame.lookAt(O, O + tu, abs(tu.Y) > 0.95 and W.LookVector or Vector3.yAxis) * CFrame.new(0, 4, 0)
		else
			GCF[GAIR] = CFrame.new(O + Vector3.new(0, 4, 0))
		end
		GCF[GBOKEH] = V * CFrame.new(0, 3.0, min(7.5, camDist - 4))
		-- (a hand replaced without a new character, e.g. by ApplyDescription, takes our attachment with it: fall back to the
		-- intake carriers and re-point the streams)
		if palmR and palmR.Parent == nil then palmR, st.repoint = nil, true end
		if palmL and palmL.Parent == nil then palmL, st.repoint = nil, true end
		local f = W.RightVector:Dot(V.RightVector)
		local flip = (f > 0.2 and assign ~= 1) and 1 or (f < -0.2 and assign ~= -1) and -1 or nil
		if flip then assign = flip end
		local moonSide = -assign
		local mA, vA = palmFor(moonSide, moonCarA), palmFor(-moonSide, voidCarA)
		GCF[GPALMM] = mA ~= moonCarA and CFrame.new(mA.WorldPosition) or W * CFrame.new(2.3 * moonSide, -0.3, -0.5)
		GCF[GPALMV] = vA ~= voidCarA and CFrame.new(vA.WorldPosition) or W * CFrame.new(-2.3 * moonSide, -0.3, -0.5)

		-- near-camera rules (with hysteresis), decided before the move so a group shown again moves this very frame: no rings
		-- or bokeh blobs across the lens. The rings fade out over 0.25 s in three steps before they leave the world, and come
		-- back fully see-through and fade in, so scrolling between 9 and 12 studs never snaps the biggest thing near the lens
		if CONFIG.NEAR_HIDE then
			local dA = (camPos - A0p).Magnitude
			if (not st.armWant and dA < CONFIG.NEAR_ARM_HIDE) or (st.armWant and dA > CONFIG.NEAR_ARM_SHOW) then
				st.armWant = not st.armWant
			end
			local tgt = st.armWant and 1 or 0
			if st.armF ~= tgt or (armHidden and not st.armWant) then
				if armHidden and not st.armWant then
					armHidden = false -- (back in the world at full see-through, at this frame's positions)
					setGroups()
				end
				local step = snap and 1 or dt / 0.25
				st.armF = tgt > st.armF and min(1, st.armF + step) or max(0, st.armF - step)
				local q = math.floor(st.armF * 3 + 0.5) / 3
				if q ~= st.armQ then
					st.armQ = q
					writeRings()
				end
				if st.armF >= 1 and not armHidden then
					armHidden = true
					setGroups()
				end
			end
			if (not bokehNear and camDist < CONFIG.NEAR_BOKEH_HIDE) or (bokehNear and camDist > CONFIG.NEAR_BOKEH_SHOW) then
				bokehNear = not bokehNear
				refreshEmitters()
			end
		end
		-- far detail (the framework's setDetail past ~110 studs): the lights, the near-only beams and another player's
		-- silver tone fade over 0.5 s instead of switching in one frame (at night a lit patch of plaza would pop)
		local lt = near and 1 or 0
		if st.lodF ~= lt then
			st.lodF = lt > st.lodF and min(1, st.lodF + dt / 0.5) or max(0, st.lodF - dt / 0.5)
			local lq = math.floor(st.lodF * 20 + 0.5) / 20
			if lq ~= st.lod then
				st.lod = lq
				applyLod()
			end
		end
		-- first person: the palm streams switch off (their ends sit just under the lens)
		local fpOn = fp > 0.5
		if fpOn ~= st.fpOn then
			st.fpOn = fpOn
			refreshBeams()
		end

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
		if flip or st.repoint then
			st.repoint = false
			sb[1].Attachment1 = mA
			if sb[2] then sb[2].Attachment1 = mA end
			sb[3].Attachment1 = vA
			if sb[4] then sb[4].Attachment1 = vA end
		end
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
			-- the assembly has ended (snap everything to rest) or the framework is fading the aura out (or back in)
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
		if isGrounded ~= grounded then
			grounded = isGrounded
			refreshEmitters()
		end
		-- the drips come back a second after the aura is shown again (a quick hide/show never blinks them)
		if not st.footOk and os.clock() - st.shownAt >= 1.1 then
			st.footOk = true
			refreshEmitters()
		end
		-- walking or flying: the void's ink smoke thins out, so no trail of puffs hangs along the path
		local slow = (st.smokeSlow and (g > 0.3 or st.speedOn)) or g > 0.6 or st.speedOn
		if slow ~= st.smokeSlow then
			st.smokeSlow = slow
			em.smoke.Rate = slow and (low and 1.5 or 2.5) or (low and 4 or 10)
			em.smoke.Lifetime = slow and n(2, 2.5) or n(3.5, 4.5)
			if em.smokeMoon then
				em.smokeMoon.Rate = slow and 1.5 or 5
				em.smokeMoon.Lifetime = slow and n(2, 2.5) or n(3.5, 4.5)
			end
		end
		if remote and CONFIG.GHOST_REMOTE and cam then
			-- someone else's aura between you and your camera: test the segment from the camera to your own focus against
			-- their clock disc and their orbs (those ghost together, with their GUIs, smoke and streams; enter at once, leave
			-- after 1.2 s clear) and, separately, against their rings (only the rings ghost: a friend standing beside the
			-- wearer looks through the rings, never through the clock; 0.6 s)
			local head = cam.Focus.Position
			local ab = head - camPos
			local len2 = ab:Dot(ab)
			local occ, occA = false, false
			if len2 > 1 then
				local Kp, nz = K.Position, K.LookVector
				local d0, d1 = (camPos - Kp):Dot(nz), (head - Kp):Dot(nz)
				if d0 * d1 < 0 then occ = (camPos + ab * (d0 / (d0 - d1)) - Kp).Magnitude < 14.5 end
				occ = occ or segDist(moonC, camPos, ab, len2) < 5.5 or segDist(voidC, camPos, ab, len2) < 7.0
				occA = segDist(A0p, camPos, ab, len2) < 6.5
			end
			if occ then st.ghostHold = 1.2 elseif st.ghostHold > 0 then st.ghostHold -= dt end
			local tgt = st.ghostHold > 0 and 1 or 0
			if st.ghost ~= tgt then
				st.ghost = tgt > st.ghost and min(1, st.ghost + 5 * dt) or max(0, st.ghost - 5 * dt)
				local q = math.floor(st.ghost * 3 + 0.5) / 3
				if q ~= st.ghostQ then setGhost(q) end
			end
			if occA then st.armHold = 0.6 elseif st.armHold > 0 then st.armHold -= dt end
			local tgtA = st.armHold > 0 and 1 or 0
			if st.armG ~= tgtA then
				st.armG = tgtA > st.armG and min(1, st.armG + 5 * dt) or max(0, st.armG - 5 * dt)
				local qa = math.floor(st.armG * 3 + 0.5) / 3
				if qa ~= st.armGQ then
					st.armGQ = qa
					writeRings()
				end
			end
		elseif not VIEWER and ctx.isLocal then
			-- body-anchored fallback: the owner sees through the clock while it stands between the camera and the head
			local head = O + Vector3.new(0, 2, 0)
			local nz = K.LookVector
			local d0, d1 = (camPos - K.Position):Dot(nz), (head - K.Position):Dot(nz)
			local cross = false
			if d0 * d1 < 0 then
				local hit = camPos + (head - camPos) * (d0 / (d0 - d1))
				cross = (hit - K.Position).Magnitude < 14
			end
			if cross ~= st.ltmOn then
				st.ltmOn = cross
				for _, p in ipairs(clockParts) do p.LocalTransparencyModifier = cross and 0.5 or 0 end
				-- (GUIs ignore LocalTransparencyModifier: the dial's inlay, star window and sub-dial switch off meanwhile)
				hosts.inlayGui.Enabled, hosts.subdialGui.Enabled, hosts.plateGui.Enabled = not cross, not cross, not cross
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
		if destroyed or on == visible then return end
		visible = on
		if on then
			-- (parented again by the next update, together with that frame's positions; after a long hide it fades back in
			-- instead of popping, and the foot drips wait a second)
			st.pendingRoot = true
			st.shownAt = os.clock()
			st.lastO = nil -- (the distance walked while hidden is not a speed)
			if st.hiddenAt and st.shownAt - st.hiddenAt > 0.5 then
				st.revealA, st.snap = 0, true
				if nq >= 0 then applyNight(nightStep()) end -- (dusk may have passed meanwhile; the reveal starts from nothing)
			end
		else
			root.Parent = nil
			st.pendingRoot = false
			st.hiddenAt = os.clock()
			st.footOk = false
			if grade then
				-- (never left on top of a cutscene or a hidden aura)
				st.gradeOut = true
				gradeTo(GRADE_OFF, 0.4, true)
			end
		end
		refreshEmitters()
		refreshLights()
	end

	function fx.setDetail(isNear)
		if destroyed then return end
		near = isNear
		if isNear then st.pendingGroups = true else setGroups() end -- (shown again by the next update, at fresh positions)
		refreshEmitters()
		refreshLights()
	end

	function fx.destroy()
		if destroyed then return end
		destroyed = true
		if grade then gradeTo(GRADE_OFF, 0.8, true) end -- (the screen eases back instead of snapping)
		for h = 1, 4 do
			for _, hp in ipairs(holders[h]) do hp[1]:Destroy() end -- (also the groups hidden by far LOD or the near rule)
		end
		root:Destroy()
		for _, o in ipairs(charStuff) do o:Destroy() end
		for _, tb in ipairs({ charStuff, act, actParts, acf, PP, solids, images, brights, emitters, emitNight, beams, clockParts, ghostParts, ringParts,
			ghostGuis, gearData }) do
			table.clear(tb)
		end
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
