-- AuraRNG Studio install kit | 03_chunk_02_of_07.luau | step 3: piece 2 of 7
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (82580 bytes, checksum 413068034).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "03_chunk_02_of_07.luau"
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

local K = 2
-- piece 2 of 7 of the new source (13390 bytes, checksum 546838554, long bracket level 0)
local DATA = [[
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "09_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
