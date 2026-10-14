-- AuraRNG Studio install kit | 04_chunk_03_of_07.luau | step 4: piece 3 of 7
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (82580 bytes, checksum 413068034).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "04_chunk_03_of_07.luau"
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

local K = 3
-- piece 3 of 7 of the new source (13386 bytes, checksum 282322451, long bracket level 0)
local DATA = [[
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
	-- Brightness, not alpha). STUDIO-VERIFY: SurfaceGui Face = Back draws on the +Z face (toward the viewer), XII up.
	local inlay = carrier("Inlay", CORE, GK, Vector3.new(24.4, 24.4, 0.05), CFrame.new(0, 0, 0.12))
	surface(inlay, Enum.NormalId.Back, hiCanvas, 1.6, 2.6, "dialInlay", 3.4, 4.2)
	-- raised lume plots at the hours, on the minute track
	if hi then
		for h = 0, 11 do
			local k = solid("Plot", "LUME", DETAIL, GK, "Block", Vector3.new(0.42, 0.55, 0.18), radial(h * 30, 11.85, 0.21))
			motion(k, radial(h * 30, 11.85, 3.21), 3.4 + 0.04 * h, 0.3)
			fadeWin(k, 3.4 + 0.04 * h, 3.5 + 0.04 * h)
		end
	end
	-- the rete: an openwork twelve-point star of silver bars over the open dial (the bars alternate in depth at the crossings)
	if hi then
		local filmRete = film("FILM_RETE", "Astrolabe")
		fsz, frot = nil, nil
		if filmRete then fsz, frot = fitDisc(filmRete, 18.2, 0.24) end
		k0 = fsz and filmSolid(filmRete, fsz, "Rete", "SILVER", DETAIL, GK, CFrame.new(0, 0, 0.27) * frot)
		if k0 then
			motion(k0, CFrame.new(0, 0, 3.27) * CFrame.Angles(0, 0, rad(60)) * frot, 3.0, 0.6)
			fadeWin(k0, 3.0, 3.15)
		else
			for k = 0, 11 do
				local phi = (k + 2.5) * 30
				local zk = k % 2 == 0 and 0.25 or 0.29
				local i = solid("Rete", "SILVER", DETAIL, GK, "Block", Vector3.new(17.58, 0.26, 0.20), radial(phi, 2.355, zk))
				motion(i, radial(phi, 2.355 * 2.2, zk), 3.0 + 0.04 * k, 0.5)
				fadeWin(i, 3.0 + 0.04 * k, 3.15 + 0.04 * k)
			end
		end
	end
	-- the sub-dial: a dark guilloché disc at the centre. STUDIO-VERIFY: SurfaceGui Face = Left is the cylinder's -X end, which
	-- faces the viewer after the 90° turn (canvas right = the viewer's right)
	local subdial = PP[solid("SubDial", "DEEP", CORE, GK, "Cylinder", Vector3.new(0.30, 6.5, 6.5), CFrame.new(0, 0, 0.57) * DISC)]
	motion(NP, CFrame.new(0, 0, -1.43) * DISC, 3.2, 0.4)
	fadeWin(NP, 3.2, 3.4)
	surface(subdial, Enum.NormalId.Left, midCanvas, 1.4, 2.2, "subdial", 3.2, 3.4)

	-- the hands: hour and minute locked at XII (midnight, the end), the seconds hand sweeping smoothly; raised above the dial
	local function handPart(name, tok, h, grp, shape, size, pos, rot)
		local i = solid(name, tok, h, grp, shape, size, CFrame.new(pos) * (rot or IDENT))
		fadeWin(i, 3.6, 3.8)
		return i
	end
	local R45 = CFrame.Angles(0, 0, rad(45))
	local filmHand = film("FILM_HANDS", "Hand")
	for _, hd in ipairs({ { GHOUR, 8.55, 2.67, 0.55, 5.6, 3.4, 0.70, 6.45, 1.6, -0.8, 0.24, 4.6, 3.6 },
		{ GMIN, 11.17, 3.58, 0.40, 8.0, 4.6, 0.52, 8.8, 2.0, -1.0, 0.16, 6.2, 4.9 } }) do
		local grp = hd[1]
		local done = false
		if filmHand then
			local sz, rot = fitHand(filmHand, hd[2])
			local flip = CONFIG.FILM_HAND_FLIP and CFrame.Angles(0, 0, pi) or IDENT
			local k = sz and filmSolid(filmHand, sz, "Hand", "SILVER", CORE, grp, CFrame.new(0, hd[3], 0) * flip * rot)
			if k then
				fadeWin(k, 3.6, 3.8)
				done = true
			end
		end
		if not done then
			handPart("Shaft", "SILVER", CORE, grp, "Block", Vector3.new(hd[4], hd[5], 0.16), Vector3.new(0, hd[6], 0))
			handPart("Tip", "SILVER", CORE, grp, "Block", Vector3.new(hd[7], hd[7], 0.16), Vector3.new(0, hd[8], 0), R45)
			if hi then handPart("Tail", "SILVER", CORE, grp, "Block", Vector3.new(hd[4], hd[9], 0.16), Vector3.new(0, hd[10], 0)) end
		end
		if hi then handPart("Lume", "LUME", CORE, grp, "Block", Vector3.new(hd[11], hd[12], 0.05), Vector3.new(0, hd[13], 0.105)) end
	end
	handPart("Needle", "SILVER", CORE, GSEC, "Block", Vector3.new(0.12, 12.2, 0.08), Vector3.new(0, 3.5, 0))
	if hi then
		handPart("Weight", "BRIGHT", CORE, GSEC, "Cylinder", Vector3.new(0.08, 0.9, 0.9), Vector3.new(0, -2.0, 0), DISC)
		handPart("SecondsTip", "LUME", CORE, GSEC, "Ball", Vector3.new(0.26, 0.26, 0.26), Vector3.new(0, 9.6, 0))
	end
	-- the hub stack over the hands: a dark base, a bright cap and a lume jewel
	handPart("Hub", "STEEL", CORE, GK, "Cylinder", Vector3.new(0.30, 1.30, 1.30), Vector3.new(0, 0, 1.62), DISC)
	handPart("HubCap", "BRIGHT", CORE, GK, "Cylinder", Vector3.new(0.20, 0.85, 0.85), Vector3.new(0, 0, 1.85), DISC)
	if hi then handPart("Jewel", "LUME", CORE, GK, "Ball", Vector3.new(0.45, 0.45, 0.45), Vector3.new(0, 0, 1.98)) end

	-- the gears: silver discs with a dark web, a bright hub, teeth (bars across the whole gear: only their ends show past the
	-- rim) and two spokes; four big ones behind the rim, a centre wheel behind the sub-dial, two small ones on the dial
	local gearData = {}
	local filmGear = film("FILM_GEARS", "Gear")
	for gi, G in ipairs(GEARS) do
		local name, cx, cy, cz, Dt, Dr, K, d, wt, web, spokes, rate, onLow = table.unpack(G)
		if hi or onLow then
			local grp = GGEAR + gi
			local h = (gi >= 6) and DETAIL or CORE
			local big = gi <= 4
			local a = big and 2.6 or 3.0
			local f1 = big and 2.9 or 3.2
			local function gp(nm, tok, shape, size, L)
				local i = solid(name .. nm, tok, h, grp, shape, size, L)
				fadeWin(i, a, f1)
			end
			local done = false
			if filmGear then
				local sz, rot = fitDisc(filmGear, Dt, d)
				local k = sz and filmSolid(filmGear, sz, name, "SILVER", h, grp, rot)
				if k then
					fadeWin(k, a, f1)
					done = true
				end
			end
			if not done then
				gp("Disc", "SILVER", "Cylinder", Vector3.new(d, Dr, Dr), DISC)
				if web and hi then gp("Web", "STEEL", "Cylinder", Vector3.new(d + 0.04, 0.74 * Dr, 0.74 * Dr), DISC) end
				for j = 0, K - 1 do
					gp("Tooth", "SILVER", "Block", Vector3.new(wt, Dt, d - 0.06), CFrame.Angles(0, 0, -rad(j * 180 / K)))
				end
				if spokes and hi then
					gp("Spoke", "SILVER", "Block", Vector3.new(0.11 * Dr, 0.72 * Dr, d + 0.08), CFrame.Angles(0, 0, rad(45)))
					gp("Spoke", "SILVER", "Block", Vector3.new(0.11 * Dr, 0.72 * Dr, d + 0.08), CFrame.Angles(0, 0, rad(135)))
				end
			end
			if gi >= 6 then
				gp("Hub", "BRIGHT", "Cylinder", Vector3.new(d + 0.10, 0.30 * Dr, 0.30 * Dr), DISC)
			else
				gp("Hub", "BRIGHT", "Cylinder", Vector3.new(d + 0.3, 0.22 * Dr, 0.22 * Dr), DISC)
			end
			-- on equip: the big four slide out from behind the dial, the centre wheel from behind, the small two from the front;
			-- all spin up fast and wind down to their running pace
			local sx, sy, sz2
			if big then sx, sy, sz2 = 0.3 * cx, 0.3 * cy, -4 elseif gi == 5 then sx, sy, sz2 = cx, cy, cz - 3 else sx, sy, sz2 = cx, cy, cz + 3 end
			table.insert(gearData, { grp = grp, cx = cx, cy = cy, cz = cz, sx = sx, sy = sy, sz = sz2, rate = rate, a0 = a, a1 = a + (big and 1.0 or 0.6),
				sign = rate < 0 and -1 or 1, extra = 0 })
		end
	end

	-- the crown and the bow above XII
	local function crownPart(name, shape, size, L)
		local i = solid(name, "BRIGHT", CORE, GCROWN, shape, size, L)
		fadeWin(i, 4.2, 4.4)
		return i
	end
	crownPart("Stem", "Cylinder", Vector3.new(1.4, 1.1, 1.1), CFrame.new(0, 14.6, -0.2) * VERT)
	crownPart("Crown", "Cylinder", Vector3.new(1.5, 2.6, 2.6), CFrame.new(0, 16.0, -0.2) * VERT)
	if hi then
		crownPart("Cap", "Ball", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 16.85, -0.2))
		for j = 0, 9 do
			local b = rad((j + 0.5) * 36)
			local i = solid("Bow", "BRIGHT", DETAIL, GCROWN, "Cylinder", Vector3.new(1.662, 0.55, 0.55),
				CFrame.new(2.283 * cos(b), 19.6 + 2.283 * sin(b), -0.2) * CFrame.Angles(0, 0, b + rad(90)))
			fadeWin(i, 4.2, 4.4)
		end
	end

	-- the night corona: a soft ring of light just outside the bezel (night only, rim-only, behind the clock)
	local corona, coronaEntry
	if hi then
		local cp = carrier("Corona", DETAIL, GK, Vector3.new(44, 44, 0.05), CFrame.new(0, 0, -3.2)) -- (ring peak R 16.3: seen from the front, 3.2 studs back, it lands just outside the bezel)
		corona, coronaEntry = surface(cp, Enum.NormalId.Back, 512, 1.8, nil, "halo", 5.0, 6.0, Color3.fromRGB(236, 240, 248))
		corona.Enabled = false
		coronaEntry[2] = 1
	end
	-- the clock's emitter hosts: the bezel annulus (glints), the two rim smoke banks, the shard feed at eleven
	local rimGlint = carrier("RimGlint", CORE, GK, Vector3.new(28.4, 28.4, 0.2), CFrame.new(0, 0, 1.05))
	local smokeVoid = carrier("SmokeVoid", CORE, GK, Vector3.new(4, 22, 3), CFrame.new(12.6, 0, -1.2))
	local smokeMoon = hi and carrier("SmokeMoon", CORE, GK, Vector3.new(4, 22, 3), CFrame.new(-12.6, 0, -1.2))
	local shardFeed = hi and carrier("ShardFeed", DETAIL, GFEED, Vector3.new(2, 2, 2))

	---------------------------------------------------------------- THE ARMILLARY: three gimballed rings round the wearer
	-- flat bands made of segments; every other segment is a hair thicker so the overlaps never z-fight
	local meridian = {}
	local function ring(name, tok, h, grp, N, R, w, t, f0)
		for i = 0, N - 1 do
			local th = (i + 0.5) * 360 / N
			local k = solid(name, tok, h, grp, "Block", Vector3.new(2 * (R + w / 2) * math.tan(rad(180 / N)) + 0.02, w, t + (i % 2 == 0 and 0.02 or -0.02)),
				radial(th, R, 0))
			fadeWin(k, f0, f0 + 0.3)
			if grp == GF1 then meridian[i] = PP[k] end
		end
	end
	ring("Meridian", "SILVER", ARM, GF1, low and 12 or 18, 6.0, 0.55, 0.24, 1.0)
	ring("Equator", "STEEL", ARM, GF2, low and 12 or 18, 5.3, 0.20, 0.4, 1.3)
	if hi then
		for k = 0, 11 do -- twelve lume hours on the equator band's outer face
			local i = solid("Hour", "LUME", ARMD, GF2, "Block", Vector3.new(0.14, 0.06, 0.32), radial(k * 30, 5.43, 0))
			fadeWin(i, 1.3, 1.6)
		end
		ring("Ecliptic", "SILVER", ARM, GF3, 16, 4.6, 0.45, 0.20, 1.6)
		for _, x in ipairs({ 5.56, -5.56 }) do -- pins: equator to meridian
			local i = solid("Pin", "BRIGHT", ARMD, GF1, "Cylinder", Vector3.new(0.45, 0.30, 0.30), CFrame.new(x, 0, 0))
			fadeWin(i, 1.0, 1.3)
		end
		for _, y in ipairs({ 5.01, -5.01 }) do -- pins: ecliptic to equator
			local i = solid("Pin", "BRIGHT", ARMD, GF2, "Cylinder", Vector3.new(0.45, 0.30, 0.30), CFrame.new(0, y, 0) * VERT)
			fadeWin(i, 1.3, 1.6)
		end
		-- the time shards: eight slivers riding the inside of the ecliptic like beads on a wire, tumbling as they go
		for i = 0, 7 do
			local k = solid("TimeShard", i % 2 == 0 and "BRIGHT" or "LUME", ARMD, GSHARD + 1 + i, "Wedge", Vector3.new(0.14, 0.7 + 0.15 * (i % 3), 0.40), IDENT)
			fadeWin(k, 5.0 + 0.06 * i, 5.2 + 0.06 * i)
		end
	end

	---------------------------------------------------------------- THE BALANCE: the moon and the void, rocking like scales
	-- the moon: a solid white ball with grey crater rims, tidally locked to the wearer (its +X faces the viewer)
	local moon
	local filmMoon = film("FILM_MOON", "Moon", true)
	if filmMoon then
		local sz = fitSphere(filmMoon, 9)
		local k = sz and filmSolid(filmMoon, sz, "Moon", "MOON", CORE, GMOON, IDENT)
		if k then
			moon = PP[k]
			fadeWin(k, 0.6, 0.9)
		end
	end
	if not moon then
		moon = PP[solid("Moon", "MOON", CORE, GMOON, "Ball", Vector3.new(9, 9, 9), IDENT)]
		fadeWin(NP, 0.6, 0.9)
		for _, c in ipairs(CRATERS) do
			if hi or c[3] then
				local u = c[1].Unit
				local dia = c[2]
				local f = sqrt(4.5 * 4.5 - (0.175 * dia) ^ 2)
				local i = solid("Crater", "CRATER", DETAIL, GMOON, "Cylinder", Vector3.new(0.4, dia, dia),
					CFrame.new(u * (f - 0.2)) * (CFrame.lookAt(Vector3.zero, u) * CFrame.Angles(0, rad(90), 0)).Rotation)
				fadeWin(i, 0.6, 0.9)
			end
		end
	end
	moon.CastShadow = CONFIG.SHADOWS and hi
	local moonOut = new("Attachment", { Name = "StreamOut", CFrame = CFrame.new(0, 0, -4.55) * CFrame.Angles(0, 0, rad(90)) }, moon)
	local keyAtt = new("Attachment", { Name = "KeyLight", Position = Vector3.new(0, 4.5, -5.5) }, moon)
	-- STUDIO-VERIFY: a PointLight on an attachment of a part moved by BulkMoveTo follows it every frame
	local keyLight = new("PointLight", { Name = "Key", Range = 22, Color = Color3.fromRGB(226, 232, 246), Brightness = 0, Shadows = false, Enabled = false }, keyAtt)
	-- a thin halo round the moon's rim (the only billboard). It sits 2 studs behind the ball, so the ball hides its inner
	-- edge; not further, or on the clock side it would reach the inlay plane and get cut (keeps >= 0.4 from every GUI plane)
	local halo = new("BillboardGui", { Name = "Halo", Size = UDim2.new(13, 0, 13, 0), StudsOffset = Vector3.new(0, 0, -2.0), LightInfluence = 0,
		Brightness = 1.0, MaxDistance = 400, AlwaysOnTop = false }, moon)
	local haloIm = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = (T("halo")),
		ImageColor3 = Color3.fromRGB(236, 240, 248), ImageTransparency = 1 }, halo)
	local haloEntry = { haloIm, 0.65, 1.4, 2.2, 1 }
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
