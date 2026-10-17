-- AuraRNG Studio install kit | 04_chunk_03_of_16.luau | step 4: piece 3 of 16
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (198845 bytes, checksum 17952987).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "04_chunk_03_of_16.luau"
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

local K = 3
-- piece 3 of 16 of the new source (13228 bytes, checksum 425714260, long bracket level 0)
local DATA = [[
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
-- (pass 5.2) the reveal: the machine assembles (to ASM_END), the buildup starts as the dais lands (REV_BUILD), midnight
-- strikes at PEAK (the minute hand locks at XII and the one pulse goes out) and the aftermath settles by REV_END
local ASM_END, REV_BUILD, PEAK, REV_END = 7.0, 4.6, 6.6, 9.8
-- the energy links' ports on the bezel's band (K frame): where the moon's light comes in, where it leaves for the void and
-- where it falls to the floor
local PORT_IX, PORT_III, PORT_VI = Vector3.new(-13.2, 0, 1.3), Vector3.new(13.2, 0, 1.3), Vector3.new(0, -13.2, 1.3)
local SPIRAL_OUT = CFrame.new(0, 0, -13.2) -- (where the galaxy's spiral arms are fed, on the pool's edge)
-- (pass 5.2) where the new layers ride: the bezel's engraving just over its band, the trail just over the inlay, the burst
-- ring a little in front of the hands (its axis along the dial's), the galaxy's rings and fine swirl between the floor's
-- layers, the spiral host over them, the stage sweep just over the stage, and the moon's ring of glints tipped steeply
local BAND_Z, TRAIL_Z = CFrame.new(0, 0, 1.19), CFrame.new(0, 0, 0.15)
local BURST_TILT = CFrame.new(0, 0, 1.6) * CFrame.Angles(math.rad(90), 0, 0)
local RINGS_Y, FINE_Y, SPIRAL_Y, SWEEP_Y = CFrame.new(0, 0.30, 0), CFrame.new(0, 0.54, 0), CFrame.new(0, 0.9, 0), CFrame.new(0, 0.10, 0)
local MRING_TILT = CFrame.Angles(math.rad(68), 0, math.rad(-14))
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
-- where this client's own clock hub is (the owner's build writes it every frame): another wearer's clock and orbs step
-- back behind it instead of standing in front of your own clock
local ownerHub = nil
local GRADE_ON = { Saturation = -0.75, Brightness = -0.1, Contrast = 0.15, TintColor = Color3.fromRGB(232, 238, 255) }
local GRADE_OFF = { Saturation = 0, Brightness = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) }
-- where the time shards leave the bezel on equip (K angles), and the bezel point at eleven the metal shards break off from
local SHARD_A = {}
for i = 0, 7 do SHARD_A[i] = math.rad(300 + 20 * i) end
local FEED_PT = Vector3.new(-10.72, 9.00, 0)
-- the camera closeness (in 0.05 steps) at which the floor's twinkles step down a size (each step under 20 %)
local MOTE_T = { 0.3, 0.45, 0.6, 0.75 }
local DOWN9 = Vector3.new(0, -9, 0) -- (the dais's slope rays)
local SWIRL_UP = CFrame.new(0, 0.3, 0)
-- (pass 5.1) the star halo's ring leans like a planet's: tipped forward 12 degrees and over 8 (its far edge clears the
-- ground), so from every side one half of it passes in front of the aura and the other behind; the helix hub sits at
-- the feet
local HALO_TILT = CFrame.new(0, 1.2, 0) * CFrame.Angles(math.rad(12), 0, math.rad(-8))
local HELIX_FEET = Vector3.new(0, -2.9, 0)
-- the hairlines (the photon ring's thickness, the seconds needle's width) by distance band: under 50 studs, 50-95, beyond.
-- A 0.13-stud line is under a pixel past ~85 studs; drawn without anti-aliasing (phones, low graphics) it breaks into a
-- crawling stair-step, so it thickens in two steps (5 studs of margin each way: no back and forth)
local HAIR = { { 0.13, 0.12 }, { 0.22, 0.2 }, { 0.36, 0.3 } }
local function hairBand(d, b)
	if b < 3 and d > (b == 1 and 50 or 95) then return b + 1 end
	if b > 1 and d < (b == 2 and 45 or 90) then return b - 1 end
	return b
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "18_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
