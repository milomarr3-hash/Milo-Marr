-- AuraRNG Studio install kit | 04_chunk_03_of_10.luau | step 4: piece 3 of 10
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (123861 bytes, checksum 523677650).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "04_chunk_03_of_10.luau"
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

local K = 3
-- piece 3 of 10 of the new source (13386 bytes, checksum 284418912, long bracket level 0)
local DATA = [[
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
