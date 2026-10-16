-- AuraRNG Studio install kit | 07_chunk_06_of_12.luau | step 7: piece 6 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (154908 bytes, checksum 840125961).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "07_chunk_06_of_12.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-154908-840125961-12-402748328"
local NEW_LEN, NEW_SUM = 154908, 840125961
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
local LENS = { 13303, 13296, 13287, 13167, 13232, 13273, 13188, 13300, 13244, 13299, 13292, 9027 }
local SUMS = { 67409079, 948660274, 266404745, 816058228, 63700756, 500498415, 756191201, 562959745, 92959190, 314875523, 46584231, 495884184 }

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

local K = 6
-- piece 6 of 12 of the new source (13273 bytes, checksum 500498415, long bracket level 0)
local DATA = [[
			local arms = carrier("GalaxyArms", DETAIL, GG1, Vector3.new(21, 0.05, 21))
			surface(arms, Enum.NormalId.Top, 1024, 1.4, 2.4, "galaxyArms", 4.2, 5.2)
		end
		local core = carrier("GalaxyCore", CORE, GG2, Vector3.new(12, 0.05, 12))
		surface(core, Enum.NormalId.Top, midCanvas, 1.5, 2.6, "galaxyCore", 4.0, 4.6)
		-- the stage: an engraved clock ring 56 studs across round the pool (inked Roman numerals 3 studs tall, a minute track
		-- with lume ticks), solid ink and white lines on the ground. Kept at every distance: from far away it is the aura's
		-- footprint. The ink carries the day; it glows at night
		if hi then
			local eng = carrier("Engraving", CORE, GENG, Vector3.new(56, 0.05, 56))
			surface(eng, Enum.NormalId.Top, 1024, 1.0, 2.0, "engraving", 4.2, 5.2)
		end
		-- the floor's particles (mist, motes, ash) rise from their own invisible disc just above the top floor layer, so they
		-- draw over the galaxy whether Roblox sorts a particle by its emitter's part or by the particles themselves
		-- (STUDIO-VERIFY: by day, close up, the twinkles and ash are never hidden under the floor's SurfaceGuis)
		hosts.floorFx = carrier("FloorFx", CORE, GG0, Vector3.new(29.6, 0.05, 29.6), CFrame.new(0, 0.8, 0))
		-- the rim: fluted blocks (bright silver and satin) rising in a wave round the pool on equip
		local NR = low and 16 or 24
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
		if CONFIG.FAR_BEACON then
			-- (the wheel's hub is a cylinder standing upright and stays level on a slope: its local +X is world up. The column
			-- starts above the bow, so it never crosses the dial, and climbs to 280 studs)
			hosts.beacon0 = new("Attachment", { Name = "BeaconFoot", Position = Vector3.new(37, 0, 0) }, wheelHub)
			hosts.beacon1 = new("Attachment", { Name = "BeaconTop", Position = Vector3.new(279, 0, 0) }, wheelHub)
		end
		-- the slope rays (below) see only the ground: never an aura (anyone's) or the wearer, never a non-collidable part
		hosts.gp = RaycastParams.new()
		hosts.gp.FilterType = Enum.RaycastFilterType.Exclude
		hosts.gp.FilterDescendantsInstances = ctx.container and { ctx.container, char, root } or { char, root }
		hosts.gp.RespectCanCollide = true
	end

	---------------------------------------------------------------- THE AIR and the palm intake carriers
	-- (the air volume turns to face the way the wearer travels, so the speed trail streams out behind)
	hosts.air = carrier("AirVolume", CORE, GAIR, Vector3.new(44, 22, 44)) -- (the sparkle field fills the space round the whole aura)
	hosts.trail = new("Attachment", { Name = "Trail", Position = Vector3.new(0, -4, 0) }, hosts.air)
	hosts.bokeh = hi and carrier("BokehHost", DETAIL, GBOKEH, Vector3.new(18, 10, 5))
	hosts.palmMoon = carrier("PalmMoon", CORE, GPALMM, Vector3.new(2.6, 2.6, 2.6))
	hosts.palmVoid = carrier("PalmVoid", CORE, GPALMV, Vector3.new(2.6, 2.6, 2.6))
	-- (pass 5.1) the star halo: a ring of stardust 32 to 42 studs across turning round the whole aura on a tilt (P15:
	-- out beyond Roblox's default follow camera, 12.5-16 studs back, so its stars never sail past the lens); the helix hub:
	-- two points 3.1 studs out that turn round the body at the feet, each trailing a strand that climbs it (P16)
	hosts.halo = hi and carrier("StarHalo", CORE, GHALO, Vector3.new(42, 0.3, 42))
	hosts.helix = carrier("HelixHub", CORE, GHELIX, Vector3.new(1, 1, 1))
	hosts.strandMoon = new("Attachment", { Name = "StrandMoon", Position = Vector3.new(3.1, 0, 0) }, hosts.helix)
	hosts.strandVoid = new("Attachment", { Name = "StrandVoid", Position = Vector3.new(-3.1, 0, 0) }, hosts.helix)

	-- the Highlight: one per aura, on the Silver model only (neutral silver by day plus an ink contour on the bright sky).
	-- STUDIO-VERIFY: a Highlight on a Model of 200+ parts. Its strength is the HIGHLIGHT_FILL / HIGHLIGHT_OUTLINE attributes.
	-- Its fill leans a touch warm: it is a correction filter that cancels the cyan the day sky puts on Metal. Roblox draws at
	-- most 31 Highlights per client, so on low quality only the owner's aura has one, and a far-away wearer's switches off.
	local tone
	if CONFIG.HIGHLIGHT and (hi or (CONFIG.HIGHLIGHT_LOW and ctx.isLocal)) then
		tone = new("Highlight", { Name = "TheEndTone", Adornee = mats.Silver, FillColor = Color3.fromRGB(216, 212, 208), FillTransparency = 1,
			OutlineColor = Color3.fromRGB(10, 10, 14), OutlineTransparency = 1, DepthMode = Enum.HighlightDepthMode.Occluded }, mats.Silver)
	end

	---------------------------------------------------------------- THE CHARACTER: palms (and the body wrap's emitters, below)
	local charStuff = {}
	local palmR, palmL
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
		-- STUDIO-VERIFY: Beam TextureSpeed direction: the streams must flow from the orb INTO the palm (all four are built
		-- source -> destination, so they share one sign; if they run backwards: attribute FLOW_SIGN = -1). The lensed band
		-- shares the sign: it drifts slowly left to right over the top (either way reads)
		local trCore = { { 0, 0.15 }, { 0.12, 0.05 }, { 0.88, 0.05 }, { 1, 0.30 } }
		sb = {
			beam("MoonCore", hosts.moonOut, moonA0, "stream", WRAP, 5, 0.8, 1.4, 0.30, 4.0, 0, WHITE, 0, 0.45, 1.6, 2.4, trCore),
			hi and beam("MoonFlow", hosts.moonOut, moonA0, "streak", WRAP, 7, 1.6, 0.5, 0.15, 4.3, 0, WHITE, 0.3, 0.9, 2.0, 2.6,
				{ { 0, 0.4 }, { 0.15, 0.2 }, { 0.85, 0.2 }, { 1, 0.6 } }, true),
			beam("VoidCore", hosts.voidOut, voidA0, "stream", WRAP, 5, 0.7, 1.6, 0.35, 3.0, 0, Color3.fromRGB(18, 18, 24), 0, 0, 1.0, 1.0, trCore),
			hi and beam("VoidCrackle", hosts.voidOut, voidA0, "line", STRETCH, 1, 0, 0.14, 0.10, 2.6, 0, WHITE, 0.2, 0.8, 1.8, 2.4,
				{ { 0, 0.3 }, { 0.1, 0.1 }, { 0.9, 0.1 }, { 1, 0.5 } }, true),
		}
		if hosts.horizon then
			-- the lensed disc (the black hole's signature): the far side of the accretion disc, bent by the void's gravity, a
			-- bright band arching over the top of the shadow and a thinner one under it. Both hang on the camera-facing
			-- horizon carrier, so they hug the silhouette from every side; slimmer when the camera is close
			local function lens(name, sg, w, br)
				local a0 = new("Attachment", { Name = name .. "0", CFrame = CFrame.fromMatrix(Vector3.new(-4.45, 0, 0), Vector3.new(0, sg, 0), Vector3.new(-sg, 0, 0)) }, hosts.horizon)
				local a1 = new("Attachment", { Name = name .. "1", CFrame = CFrame.fromMatrix(Vector3.new(4.45, 0, 0), Vector3.new(0, -sg, 0), Vector3.new(sg, 0, 0)) }, hosts.horizon)
				return beam(name, a0, a1, "stream", WRAP, 6, 0.4, w, w, 6.0, 6.0, WHITE, 0.2, 0.8, br, br + 1.0,
					{ { 0, 1 }, { 0.15, 0.05 }, { 0.85, 0.05 }, { 1, 1 } })
			end
			hosts.lensTop = lens("LensTop", 1, 1.5, 2.0)
			hosts.lensBot = lens("LensBottom", -1, 0.8, 1.8)
		end
		if hosts.beacon0 then
			-- (FAR_BEACON) a steady column seen only from far away: solid ink on the day sky, white at night, soft at the top.
			-- No texture (a solid band reads at 300 studs; a textured line thinned to a hairline). No pulse.
			hosts.beaconBeam = beam("Spire", hosts.beacon0, hosts.beacon1, nil, STRETCH, 1, 0, 8, 3, 0, 0, INK, 0, 1, 1, 2,
				{ { 0, 0.1 }, { 0.6, 0.15 }, { 1, 1 } }, false, true)
		end
		-- (entry [10]: one of the four palm streams, switched off in first person; [11]: the Enabled last written; [12]: when
		-- it fades in on equip: the lens with the void's heart, the streams once the dais is down)
		for _, b in ipairs(beams) do
			b[10] = b[1] == sb[1] or b[1] == sb[2] or b[1] == sb[3] or b[1] == sb[4]
			b[11] = b[1].Enabled
			b[12] = (b[1] == hosts.lensTop or b[1] == hosts.lensBot) and 0.9 or 4.6
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
