-- AuraRNG Studio install kit | 08_chunk_07_of_16.luau | step 8: piece 7 of 16
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (198845 bytes, checksum 17952987).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "08_chunk_07_of_16.luau"
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

local K = 7
-- piece 7 of 16 of the new source (13219 bytes, checksum 924487494, long bracket level 0)
local DATA = [[
			motion(i, CFrame.new(L.Position * 0.05) * L.Rotation, 0.9, 0.6)
			fadeWin(i, 0.9, 1.1)
		end
		local wa = CONFIG.WEDGE_SWAP and -90 or 90
		for _, sp in ipairs({ { 0, 1.3 }, { 180, 1.3 }, { 90, 0.9 }, { 270, 0.9 } }) do
			if hi then
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
		surface(core, Enum.NormalId.Top, midCanvas, 1.5, 2.2, "galaxyCore", 4.0, 4.6) -- (pass 5.2: 2.2 at night, was 2.6: the bulge blew out to white)
		hosts.coreB = brights[#brights] -- (pass 5.2: the galaxy's heart brightens in the buildup and at midnight)
		-- (pass 5.2) the vortex in layers, each turning its own way at its own pace: the broad slow floor (-6 deg/s), rings of
		-- energy (+4), the arms against it (+9), a fine fast swirl (-30) and the bright core (-16). The two new layers have no
		-- pass-4 look-alike: they come with their te5 textures
		if hi and isTe5("energyRings") then
			hosts.rings = carrier("EnergyRings", DETAIL, G2.RINGS, Vector3.new(28, 0.05, 28))
			surface(hosts.rings, Enum.NormalId.Top, 1024, 1.2, 2.2, "energyRings", 4.4, 5.4)
		end
		if hi and isTe5("galaxySwirl") then
			hosts.fine = carrier("GalaxySwirl", DETAIL, G2.FINE, Vector3.new(18, 0.05, 18))
			surface(hosts.fine, Enum.NormalId.Top, 1024, 1.3, 1.7, "galaxySwirl", 4.4, 5.4)
		end
		-- the stage: an engraved clock ring 56 studs across round the pool (Roman numerals 3 studs tall, a minute track with
		-- batons). Kept at every distance: from far away it is the aura's footprint. (pass 5.2) Gold markings on a black
		-- base, "the gold-and-black circular platform": te5_engraving is grey and takes the gold tint (its base stays
		-- black); it no longer glows at night (1.25, under the Bloom threshold), so its detail never washes out, and it
		-- brightens once, briefly, at midnight
		if hi then
			local eng = carrier("Engraving", CORE, GENG, Vector3.new(56, 0.05, 56))
			surface(eng, Enum.NormalId.Top, 1024, 1.0, 1.25, "engraving", 4.2, 5.2, GOLD)
			hosts.stageB = brights[#brights]
			-- (pass 5.2) in the reveal a golden light sweeps once round the stage's minute band (te5_trail, 56 studs: its arc
			-- lands on the band), lighting the markings as it passes
			if isTe5("trail") then
				hosts.sweepGui, hosts.sweepE = surface(carrier("StageSweep", CORE, G2.SWEEP, Vector3.new(56, 0.05, 56)), Enum.NormalId.Top, 1024, 1.5, 2.5,
					"trail", 0, 0, Color3.fromRGB(255, 232, 186), true)
			end
		end
		-- the floor's particles (mist, motes, ash) rise from their own invisible disc just above the top floor layer, so they
		-- draw over the galaxy whether Roblox sorts a particle by its emitter's part or by the particles themselves
		-- (STUDIO-VERIFY: by day, close up, the twinkles and ash are never hidden under the floor's SurfaceGuis)
		hosts.floorFx = carrier("FloorFx", CORE, GG0, Vector3.new(29.6, 0.05, 29.6), CFrame.new(0, 0.8, 0))
		-- (pass 5.2) the floor's wave at midnight starts at the centre, a stud above the floor layers (it lies flat and grows
		-- across the stage: P24); the spiral arms are fed from two points that circle the pool's edge (P20, high quality)
		hosts.wave = carrier("WaveHost", CORE, GDAIS, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 1.0, 0))
		if hi then
			hosts.spiral = carrier("SpiralHost", CORE, G2.SPIRAL, Vector3.new(1, 0.05, 1))
			hosts.spiralA = new("Attachment", { Name = "ArmA", CFrame = SPIRAL_OUT }, hosts.spiral)
			hosts.spiralB = new("Attachment", { Name = "ArmB", CFrame = CFrame.Angles(0, pi, 0) * SPIRAL_OUT }, hosts.spiral)
		end
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
	-- (pass 5.2) the links' far ends: on the moon, facing IX (it aims straight at IX, for the motes; the beam leaves it
	-- bowed up 20 degrees), on the void, facing III, and on the floor, in front of the clock (each beam arrives along its
	-- end's x axis)
	if CONFIG.LINKS then
		hosts.linkMoon = carrier("LinkMoon", CORE, G2.LINKM, Vector3.new(0.2, 0.2, 0.2))
		hosts.linkMoonA = new("Attachment", { Name = "LinkOut", CFrame = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0.342, -0.94), Vector3.new(0, 0.94, 0.342)) },
			hosts.linkMoon)
		hosts.linkVoid = carrier("LinkVoid", CORE, G2.LINKV, Vector3.new(0.2, 0.2, 0.2))
		hosts.linkVoidA = new("Attachment", { Name = "LinkIn", CFrame = CFrame.fromMatrix(Vector3.zero, -Vector3.zAxis, Vector3.yAxis) }, hosts.linkVoid)
		if hi then
			hosts.linkFloor = carrier("LinkFloor", CORE, G2.LINKF, Vector3.new(0.2, 0.2, 0.2))
			hosts.linkFloorA = new("Attachment", { Name = "LinkIn", CFrame = CFrame.fromMatrix(Vector3.zero, -Vector3.zAxis, Vector3.yAxis) }, hosts.linkFloor)
		end
	end
	if hi then
		-- (pass 5.2) a tilted ring of glints orbiting the moon (P22); the void's infall shell, turning with its disc (P23);
		-- the dial's burst ring at the hub, turning slowly, its axis along the dial's (P25: the glints that burst off the
		-- dial at midnight slow down and stay in orbit round it); the converging streaks' shell round the clock (P26)
		hosts.moonRing = carrier("MoonRing", CORE, G2.MRING, Vector3.new(14, 0.2, 14))
		hosts.infall = carrier("Infall", CORE, G2.INFALL, Vector3.new(18, 18, 18))
		hosts.burst = carrier("BurstRing", CORE, G2.BURST, Vector3.new(2, 0.2, 2))
		hosts.converge = carrier("Converge", CORE, GK, Vector3.new(30, 30, 30), CFrame.new(0, 0, 1.5))
	end

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
