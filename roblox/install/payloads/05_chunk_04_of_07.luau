-- AuraRNG Studio install kit | 05_chunk_04_of_07.luau | step 5: piece 4 of 7
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (82580 bytes, checksum 413068034).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "05_chunk_04_of_07.luau"
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

local K = 4
-- piece 4 of 7 of the new source (13387 bytes, checksum 777563289, long bracket level 0)
local DATA = [[
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
