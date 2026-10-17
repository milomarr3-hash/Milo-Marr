-- AuraRNG Studio install kit | 03_chunk_02_of_16.luau | step 3: piece 2 of 16
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (198845 bytes, checksum 17952987).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "03_chunk_02_of_16.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-198845-17952987-16-151465783"
local NEW_LEN, NEW_SUM = 198845, 17952987
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

local N = 16
local LENS = { 13242, 13165, 13228, 13140, 13231, 13214, 13219, 13150, 13223, 13242, 13241, 13228, 13234, 13175, 13201, 712 }
local SUMS = { 137879888, 580038089, 425714260, 382625152, 135632818, 823280755, 924487494, 162546552, 917082428, 106838554, 486110360, 934107283, 670841394, 102157393, 814892809, 773373630 }

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
-- piece 2 of 16 of the new source (13165 bytes, checksum 580038089, long bracket level 1)
local DATA = [=[
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
-- fixUps[o](o) puts back what the build chose because the te5 texture was there (a colour, a brightness, a size). (The
-- hook gets the object as its argument: a weak-keyed entry whose value held its own key would never be collected)
local texUsers = setmetatable({}, { __mode = "k" })
local fixUps = setmetatable({}, { __mode = "k" })
local usedKeys = {} -- (te5 keys some build on this client draws: only those are asked for)
local function applyTex(o, key)
	local id, layout, mode = T(key)
	if o:IsA("ImageLabel") then
		o.Image = id
		local c = CROP[key]
		if c then
			local fb = not isTe5(key)
			o.ImageRectOffset, o.ImageRectSize = fb and c[1] or Vector2.zero, fb and c[2] or Vector2.zero
		end
	elseif o:IsA("Beam") then
		o.Texture = id
	elseif o:IsA("ParticleEmitter") then
		o.Texture = id
		o.FlipbookLayout = Enum.ParticleFlipbookLayout[layout]
		if layout ~= "None" then o.FlipbookMode = Enum.ParticleFlipbookMode[mode] end
	end
	if TEX5[key] then
		texUsers[o] = key
		usedKeys[key] = true
	end
end
-- ask the engine for the te5 textures a build actually draws, once each (in the background: never blocks require or
-- build; a low-quality build never asks for the six textures only high quality uses, so a phone does not hold them). One
-- that does not load (wrong id, still in moderation, rejected) is reported and swapped for its pass-4 fallback everywhere,
-- for every key that shares its id. A slow phone or a cold cache can time out: that id is asked for once more 20 s later
-- before anything is swapped.
local preloadUsed
do
	local asked, keysOf, retried, dead = {}, {}, {}, {}
	local function failKey(k, id, status)
		if failed[k] then return end
		failed[k] = true
		warn(string.format("TheEnd: te5 texture %s (%s) did not load (%s); using its pass-4 fallback", k, id, tostring(status)))
		for o, ok in pairs(texUsers) do
			if ok == k then
				pcall(applyTex, o, k)
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
	-- (pass 5.2) gunmetal: the dark facets of the central star. A dark metal under the cyan sky turns teal, so it is a
	-- satin plastic outside the silver tone, a step lighter than the steel round it
	GUN = { Color3.fromRGB(66, 68, 74), Enum.Material.SmoothPlastic, 0, "Dark" },
}
-- (pass 5.2) an hour plot before it lights up on equip (a dark Neon does not glow), and the stage's gold (Milo: "the
-- gold-and-black circular platform"; te5_engraving is grey and takes this tint, so its black base stays black)
local LUME_OFF = Color3.fromRGB(52, 52, 56)
local GOLD = Color3.fromRGB(228, 196, 132)

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
	-- (pass 5.2) the energy links between the moon, the clock, the void and the floor's vortex; and during the equip
	-- reveal, on the wearer's own screen only, a soft bloom at the peak and a slight camera push-in (the field of view
	-- narrows 6 % and comes back; it lets go at once if anything else changes the field of view meanwhile)
	LINKS = true, REVEAL_BLOOM = true, REVEAL_PUSH = true,
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "18_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
