-- AuraRNG Studio install kit | 02_chunk_01_of_07.luau | step 2: piece 1 of 7
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (82580 bytes, checksum 413068034).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "02_chunk_01_of_07.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-82580-413068034-7-175648338"
local NEW_LEN, NEW_SUM = 82580, 413068034
local BEFORE_LEN, BEFORE_SUM, BEFORE_NAME = 35000, 489406639, "the pass-4 live version"
local SES = game:GetService("ScriptEditorService")
local SS = game:GetService("ServerStorage")

-- checksum of a text, the same one the repo tools print: x = (x * 131 + byte) % 1000000007 over its bytes
local function sum(s)
	local x = 0
	for i = 1, #s do
		x = (x * 131 + string.byte(s, i)) % 1000000007
	end
	return x
end

-- every result is one line: OK, FAIL or STOP, this file's name, then what happened
local function say(word, msg)
	return word .. " " .. FILE .. ": " .. msg
end

-- the module to install into (nil if it is missing)
local function findTarget()
	local o = game:GetService(TARGET[1])
	for i = 2, #TARGET do
		o = o and o:FindFirstChild(TARGET[i])
	end
	return o
end

-- which version a text is, by its length and checksum
local function describe(len, cs)
	if len == NEW_LEN and cs == NEW_SUM then
		return "the NEW version"
	elseif len == BEFORE_LEN and cs == BEFORE_SUM then
		return BEFORE_NAME
	end
	return "an unknown version"
end

local N = 7
local LENS = { 13394, 13390, 13386, 13387, 13372, 13337, 2314 }
local SUMS = { 747760660, 546838554, 282322451, 777563289, 713911797, 449542432, 103059902 }

-- the temporary holder ServerStorage.AuraRNG_Install: one StringValue per piece of the new source
local function chunkName(i)
	return string.format("chunk_%02d", i)
end
local function chunkFile(i)
	return string.format("%02d_chunk_%02d_of_%02d.luau", i + 1, i, N)
end
local function holder()
	local h = SS:FindFirstChild("AuraRNG_Install")
	if h and h:GetAttribute("RunId") == RUN then
		return h
	end
	return nil
end
local function chunkOk(h, i)
	local v = h:FindFirstChild(chunkName(i))
	return v ~= nil and v:IsA("StringValue") and #v.Value == LENS[i] and sum(v.Value) == SUMS[i]
end

local K = 1
-- piece 1 of 7 of the new source (13394 bytes, checksum 747760660, long bracket level 1)
local DATA = [=[
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
]=]

local function main()
	if game:GetService("RunService"):IsRunning() then
		return say("STOP", "Studio is in Play mode. Stop Play, then run this again in Edit mode. Nothing changed.")
	end
	if #DATA ~= LENS[K] or sum(DATA) ~= SUMS[K] then
		return say("FAIL", string.format("piece %d arrived changed (%d bytes, checksum %d; it should be %d bytes, checksum %d): the text of this payload was altered when it was sent. Nothing stored. Send the file again exactly as it is (tabs, spaces, blank lines and the last line all count).",
			K, #DATA, sum(DATA), LENS[K], SUMS[K]))
	end
	if not findTarget() then
		return say("FAIL", TARGET_NAME .. " was not found. Nothing stored.")
	end
	local h = holder()
	if not h then
		return say("FAIL", "no install holder for this payload set. Run 01_backup.luau of this same set first.")
	end
	for i = 1, K - 1 do
		if not chunkOk(h, i) then
			return say("FAIL", string.format("piece %d is missing or damaged: run %s first (pieces go in order). Nothing stored.", i, chunkFile(i)))
		end
	end
	local v = h:FindFirstChild(chunkName(K))
	local again = v ~= nil
	if v and not v:IsA("StringValue") then
		v:Destroy()
		v = nil
	end
	if not v then
		v = Instance.new("StringValue")
		v.Name = chunkName(K)
	end
	v.Value = DATA
	v.Parent = h
	if #v.Value ~= LENS[K] or sum(v.Value) ~= SUMS[K] then
		return say("FAIL", string.format("the StringValue changed piece %d (%d bytes stored of %d). Tell Milo; nothing was installed.", K, #v.Value, LENS[K]))
	end
	local have = 0
	for i = 1, N do
		if chunkOk(h, i) then
			have += 1
		end
	end
	return say("OK", string.format("piece %d/%d stored%s (%d bytes, checksum %d). The holder has %d/%d. Next: %s",
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "09_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
