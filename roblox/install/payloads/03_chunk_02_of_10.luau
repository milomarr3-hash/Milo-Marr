-- AuraRNG Studio install kit | 03_chunk_02_of_10.luau | step 3: piece 2 of 10
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (123861 bytes, checksum 523677650).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "03_chunk_02_of_10.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-123861-523677650-10-457228033"
local NEW_LEN, NEW_SUM = 123861, 523677650
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

local N = 10
local LENS = { 13381, 13376, 13386, 13381, 13350, 13333, 13298, 13314, 13338, 3704 }
local SUMS = { 138302907, 144820895, 284418912, 946852927, 737433606, 204697128, 129328051, 22255047, 37178664, 110492221 }

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
-- piece 2 of 10 of the new source (13376 bytes, checksum 144820895, long bracket level 0)
local DATA = [[
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "12_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
