-- AuraRNG Studio install kit | 03_chunk_02_of_12.luau | step 3: piece 2 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (148303 bytes, checksum 731942170).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "03_chunk_02_of_12.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-148303-731942170-12-824555251"
local NEW_LEN, NEW_SUM = 148303, 731942170
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

local N = 12
local LENS = { 13300, 13224, 13240, 13242, 13194, 13235, 13276, 13235, 13290, 13298, 13282, 2487 }
local SUMS = { 825733820, 782681153, 524531706, 656635892, 998587156, 867606918, 526087852, 254541497, 6651690, 395645774, 897444566, 313496838 }

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

local K = 2
-- piece 2 of 12 of the new source (13224 bytes, checksum 782681153, long bracket level 0)
local DATA = [[
				if fixUps[o] then pcall(fixUps[o], o) end
			end
		end
	end
	local function onStatus(id, status)
		local ks = keysOf[id]
		if not ks or status == Enum.AssetFetchStatus.Success then return end
		if status ~= Enum.AssetFetchStatus.Failure and not retried[id] then
			retried[id] = true
			task.delay(20, function()
				pcall(function() game:GetService("ContentProvider"):PreloadAsync({ id }, onStatus) end)
			end)
			return
		end
		dead[id] = status
		for _, k in ipairs(ks) do failKey(k, id, status) end
	end
	function preloadUsed()
		local ids = {}
		for k in pairs(usedKeys) do
			local id = idOf(TEX5[k], k)
			if id and not string.match(id, "^pending:") then
				local ks = keysOf[id]
				if not ks then
					ks = {}
					keysOf[id] = ks
				end
				if not table.find(ks, k) then table.insert(ks, k) end
				if dead[id] then
					failKey(k, id, dead[id]) -- (another key with this id already failed to load)
				elseif not asked[id] then
					asked[id] = true
					table.insert(ids, id)
				end
			end
		end
		if #ids > 0 then
			task.spawn(function()
				pcall(function() game:GetService("ContentProvider"):PreloadAsync(ids, onStatus) end)
			end)
		end
	end
end

-- particle and beam colours (as pass 4) and a few more for pass 5
local WHITE = Color3.fromRGB(248, 249, 255)
local INK = Color3.fromRGB(5, 5, 8)
local SMOKE = Color3.fromRGB(14, 14, 19)
local MIST = Color3.fromRGB(205, 209, 220)
local ASH = Color3.fromRGB(16, 16, 20)
-- solid parts: colour, material, reflectance and the sub-model they live in (the Highlight covers only "Silver").
-- The silvers are neutral, a hair warm: the cyan day sky already tints Metal blue (a cool token read as baby-blue
-- plastic), and at night, with no sky tint, they read plain grey-silver.
local MAT = {
	SILVER = { Color3.fromRGB(186, 184, 183), Enum.Material.Metal, 0.08, "Silver" },
	BRIGHT = { Color3.fromRGB(226, 224, 223), Enum.Material.Metal, 0.12, "Silver" },
	STEEL = { Color3.fromRGB(44, 46, 51), Enum.Material.SmoothPlastic, 0, "Dark" },
	DEEP = { Color3.fromRGB(30, 31, 35), Enum.Material.SmoothPlastic, 0, "Dark" },
	BASE = { Color3.fromRGB(12, 12, 16), Enum.Material.SmoothPlastic, 0, "Dark" },
	VOID = { Color3.fromRGB(0, 0, 0), Enum.Material.Neon, 0, "Dark" },
	LUME = { Color3.fromRGB(240, 240, 242), Enum.Material.Neon, 0, "Lume" }, -- (neutral: Neon saturates any tint)
	ARC = { Color3.fromRGB(210, 210, 212), Enum.Material.Neon, 0, "Lume" },
	MOON = { Color3.fromRGB(234, 236, 240), Enum.Material.SmoothPlastic, 0, "Silver" }, -- (the film-mesh moon only)
	-- a darker satin silver for every other flute (bezel, dais rim) and the equator band: metal reads as metal when it has
	-- light and dark structure, not one flat value
	SATIN = { Color3.fromRGB(143, 141, 140), Enum.Material.Metal, 0.08, "Silver" },
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
	-- the owner's clock steps back along the view until this point of the watch (studs above its hub) is inside the top of
	-- the frame, at any zoom and camera tilt: 9.6 = the XII numeral (the hands at midnight), 22.4 = the whole watch with
	-- its bow (smaller at the default zoom), 0 = off
	FRAME_TOP = 9.6,
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
	-- where the ring of the pass-2 "rim" texture peaks, as a fraction of the image's half-width (measure it on the Mac:
	-- studio_checks.md). Until te5_halo is uploaded the night corona, the void's horizon glow and the moon halo use "rim",
	-- and they are scaled so its ring lands where te5_halo's does (0.73)
	RIM_R = 0.86,
	-- Studio checks that are one attribute flip each (see roblox/install/studio_checks.md):
	FLOW_SIGN = 1, -- -1 if the streams flow out of the palms (and the void's lensed band runs against the accretion disc)
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
	NEAR_BOKEH_SHOW = { 0.5, 61 }, NIGHT_INTERVAL = { 0.25, 10 }, FRAME_TOP = { 0, 24 }, RIM_R = { 0.5, 0.98 },
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
local min, max, clamp, pi, asin, tan = math.min, math.max, math.clamp, math.pi, math.asin, math.tan
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
-- little more; the orbs come down and move back and a little out, so at the default zoom the moon is about the dial's
-- size beside it (not a huge disc under the HUD) and the theme reads first
local CLOSE = { dist = 32, distRemote = 16, tilt = 24, arm = -2, orbY = 5, orbZ = 18 }

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

-- the wearer's equip grade lives here (one per client), so a quick re-equip takes it over instead of stacking a second one;
-- gradeOwner is the build that took it last (only that one eases it out)
local liveGrade, liveGradeTween, gradeToken, gradeOwner = nil, nil, 0, nil
-- when this client's own THE END was last taken away, and from which character (a respawn rebuilds it on a new character
-- within seconds: that is not an equip, so no grade)
local ownGone, ownGoneChar = nil, setmetatable({}, { __mode = "v" }) -- (weak: an old character is never kept alive)
]]

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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "14_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
