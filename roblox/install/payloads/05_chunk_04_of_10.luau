-- AuraRNG Studio install kit | 05_chunk_04_of_10.luau | step 5: piece 4 of 10
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (123861 bytes, checksum 523677650).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "05_chunk_04_of_10.luau"
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

local K = 4
-- piece 4 of 10 of the new source (13381 bytes, checksum 946852927, long bracket level 1)
local DATA = [=[
					motion(i, radial(phi, 2.355 * 2.2, zk), 3.0 + 0.04 * k, 0.5)
					fadeWin(i, 3.0 + 0.04 * k, 3.15 + 0.04 * k)
				end
			end
		end
		-- the sub-dial: a dark guilloché disc at the centre. STUDIO-VERIFY: SurfaceGui Face = Left is the cylinder's -X end,
		-- which faces the viewer after the 90° turn (canvas right = the viewer's right)
		local subdial = PP[solid("SubDial", "DEEP", CORE, GK, "Cylinder", Vector3.new(0.30, 6.5, 6.5), CFrame.new(0, 0, 0.57) * DISC)]
		motion(NP, CFrame.new(0, 0, -1.43) * DISC, 3.2, 0.4)
		fadeWin(NP, 3.2, 3.4)
		hosts.subdialGui = surface(subdial, Enum.NormalId.Left, midCanvas, 1.4, 2.2, "subdial", 3.2, 3.4)
		-- the movement plate: a solid black disc closing the skeleton dial from behind (it used to be open air: grass, paths
		-- and sky showed through the clock). A window into deep space turns on it with the centre wheel; only the big gears'
		-- teeth now show past the rim. It rides the centre wheel GE's frame (K z -0.95), so it sits at K z -1.40, between GE's
		-- back face (-1.30) and the big gears (<= -1.60), and slides in with GE.
		local plate = PP[solid("Backplate", "BASE", CORE, GGEAR0 + 5, "Cylinder", Vector3.new(0.10, 24.6, 24.6), CFrame.new(0, 0, -0.45) * DISC)]
		fadeWin(NP, 3.0, 3.3)
		-- (te5_star_window is a dark star field; until it is uploaded the plate borrows the pass-4 galaxy, which is much
		-- brighter, so it glows less)
		local sw = isTe5("starWindow")
		local pe5
		hosts.plateGui, pe5 = surface(plate, Enum.NormalId.Left, hiCanvas, sw and 1.1 or 0.7, sw and 2.0 or 1.1, "starWindow", 3.0, 3.4)
		if sw then
			-- (if te5_star_window fails to load in the game, the bright pass-4 galaxy takes its place: dim it as above)
			local be = brights[#brights]
			fixUps[pe5[1]] = function()
				be[2], be[3] = 0.7, 1.1
				be[1].Brightness = 0.7 + 0.4 * nightStep()
			end
		end
		table.insert(ghostGuis, hosts.inlayGui)
		table.insert(ghostGuis, hosts.subdialGui)
		table.insert(ghostGuis, hosts.plateGui)
	end

	-- the hands: hour and minute locked at XII (midnight, the end), the seconds hand sweeping smoothly; raised above the dial
	local function handPart(name, tok, h, grp, shape, size, pos, rot)
		local i = solid(name, tok, h, grp, shape, size, CFrame.new(pos) * (rot or IDENT))
		fadeWin(i, 3.6, 3.8)
		return i
	end
	do
		local R45 = CFrame.Angles(0, 0, rad(45))
		local filmHand = film("FILM_HANDS", "Hand")
		-- (len: tip-to-tail length for a film mesh, mid: its centre; the rest are the procedural parts' sizes and heights)
		for _, hd in ipairs({
			{ grp = GHOUR, len = 8.55, mid = 2.67, w = 0.55, shaft = 5.6, shaftY = 3.4, tip = 0.70, tipY = 6.45, tail = 1.6, tailY = -0.8,
				lumeW = 0.24, lumeL = 4.6, lumeY = 3.6 },
			{ grp = GMIN, len = 11.17, mid = 3.58, w = 0.40, shaft = 8.0, shaftY = 4.6, tip = 0.52, tipY = 8.8, tail = 2.0, tailY = -1.0,
				lumeW = 0.16, lumeL = 6.2, lumeY = 4.9 },
		}) do
			local done = false
			if filmHand then
				local sz, rot = fitHand(filmHand, hd.len)
				local flip = CONFIG.FILM_HAND_FLIP and CFrame.Angles(0, 0, pi) or IDENT
				local k = sz and filmSolid(filmHand, sz, "Hand", "SILVER", CORE, hd.grp, CFrame.new(0, hd.mid, 0) * flip * rot)
				if k then
					fadeWin(k, 3.6, 3.8)
					done = true
				end
			end
			if not done then
				handPart("Shaft", "SILVER", CORE, hd.grp, "Block", Vector3.new(hd.w, hd.shaft, 0.16), Vector3.new(0, hd.shaftY, 0))
				handPart("Tip", "SILVER", CORE, hd.grp, "Block", Vector3.new(hd.tip, hd.tip, 0.16), Vector3.new(0, hd.tipY, 0), R45)
				if hi then handPart("Tail", "SILVER", CORE, hd.grp, "Block", Vector3.new(hd.w, hd.tail, 0.16), Vector3.new(0, hd.tailY, 0)) end
			end
			if hi then handPart("Lume", "LUME", CORE, hd.grp, "Block", Vector3.new(hd.lumeW, hd.lumeL, 0.05), Vector3.new(0, hd.lumeY, 0.105)) end
		end
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
	do
		local filmGear = film("FILM_GEARS", "Gear")
		for gi, G in ipairs(GEARS) do
			local name, cx, cy, cz, Dt, Dr, K, d, wt, web, spokes, rate, onLow = table.unpack(G)
			if hi or onLow then
				local grp = GGEAR0 + gi
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
				-- on equip: the big four slide out from behind the dial, the centre wheel from behind, the small two from the
				-- front; all spin up fast and wind down to their running pace
				local sx, sy, sz2
				if big then sx, sy, sz2 = 0.3 * cx, 0.3 * cy, -4 elseif gi == 5 then sx, sy, sz2 = cx, cy, cz - 3 else sx, sy, sz2 = cx, cy, cz + 3 end
				table.insert(gearData, { grp = grp, cx = cx, cy = cy, cz = cz, sx = sx, sy = sy, sz = sz2, rate = rate, a0 = a, a1 = a + (big and 1.0 or 0.6),
					sign = rate < 0 and -1 or 1, extra = 0 })
			end
		end
	end

	-- the crown and the bow above XII (kept at every distance: the bow is the clock's silhouette from far away)
	do
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
				crownPart("Bow", "Cylinder", Vector3.new(1.662, 0.55, 0.55), CFrame.new(2.283 * cos(b), 19.6 + 2.283 * sin(b), -0.2) * CFrame.Angles(0, 0, b + rad(90)))
			end
		end
	end

	-- the night corona: a soft ring of light just outside the bezel (night only, rim-only, behind the clock). Kept at every
	-- distance: at night it is the clock's glow from across the plaza
	local corona, coronaEntry
	if hi then
		local cp = carrier("Corona", CORE, GK, Vector3.new(44, 44, 0.05), CFrame.new(0, 0, -3.2) * frontL) -- (ring peak R 16.3: seen from the front, 3.2 studs back, it lands just outside the bezel)
		corona, coronaEntry = surface(cp, frontFace, 512, 1.8, nil, "halo", 5.0, 6.0, Color3.fromRGB(240, 240, 242))
		corona.Enabled = false
		coronaEntry[2] = 1
	end
	-- the clock's emitter hosts: the bezel annulus (glints) and the shard feed at eleven (the rim smoke moved onto the void)
	hosts.rimGlint = carrier("RimGlint", CORE, GK, Vector3.new(28.4, 28.4, 0.2), CFrame.new(0, 0, 1.05))
	hosts.timeDust = hi and carrier("TimeDust", CORE, GDUST, Vector3.new(29.4, 29.4, 0.2)) -- (a ring turning with the hands: P13)
	hosts.shardFeed = hi and carrier("ShardFeed", DETAIL, GFEED, Vector3.new(2, 2, 2))

	---------------------------------------------------------------- THE ARMILLARY: three gimballed rings round the wearer
	-- flat bands made of segments; every other segment is a hair thicker so the overlaps never z-fight
	do
		local function ring(name, tok, h, grp, N, R, w, t, f0)
			for i = 0, N - 1 do
				local th = (i + 0.5) * 360 / N
				local k = solid(name, tok, h, grp, "Block", Vector3.new(2 * (R + w / 2) * math.tan(rad(180 / N)) + 0.02, w, t + (i % 2 == 0 and 0.02 or -0.02)),
					radial(th, R, 0))
				fadeWin(k, f0, f0 + 0.3)
			end
		end
		-- (a slimmer silver meridian, so the body reads through the cage; a satin-silver equator bracelet with twelve lume hours)
		ring("Meridian", "SILVER", ARM, GF1, low and 14 or 18, 6.0, 0.40, 0.24, 1.0)
		ring("Equator", "SATIN", ARM, GF2, low and 14 or 18, 5.3, 0.20, 0.4, 1.3)
		if hi then
			for k = 0, 11 do -- twelve lume hours on the equator band's outer face
				local i = solid("Hour", "LUME", ARMD, GF2, "Block", Vector3.new(0.14, 0.10, 0.32), radial(k * 30, 5.45, 0))
				fadeWin(i, 1.3, 1.6)
			end
			ring("Ecliptic", "SILVER", ARM, GF3, 16, 4.6, 0.45, 0.20, 1.6)
			for _, x in ipairs({ 5.58, -5.58 }) do -- pins: equator to meridian
				local i = solid("Pin", "BRIGHT", ARMD, GF1, "Cylinder", Vector3.new(0.55, 0.30, 0.30), CFrame.new(x, 0, 0))
				fadeWin(i, 1.0, 1.3)
			end
			for _, y in ipairs({ 5.01, -5.01 }) do -- pins: ecliptic to equator
				local i = solid("Pin", "BRIGHT", ARMD, GF2, "Cylinder", Vector3.new(0.45, 0.30, 0.30), CFrame.new(0, y, 0) * VERT)
				fadeWin(i, 1.3, 1.6)
			end
			-- the time shards: eight slivers riding the inside of the ecliptic like beads on a wire, tumbling as they go
			for i = 0, 7 do
				local k = solid("TimeShard", i % 2 == 0 and "BRIGHT" or "LUME", ARMD, GSHARD0 + 1 + i, "Wedge", Vector3.new(0.14, 0.7 + 0.15 * (i % 3), 0.40), IDENT)
				fadeWin(k, 5.0 + 0.06 * i, 5.2 + 0.06 * i)
			end
		end
	end

	---------------------------------------------------------------- THE BALANCE: the moon and the void, rocking like scales
	-- the moon, tidally locked to the wearer: a grey core (it carries the dust, the smoke, the stream and the key light, and
	-- casts the shadow) behind its face, an opaque 9-stud disc 4.4 studs toward the camera that turns to face it every
	-- frame. The face is solid geometry, so it writes depth: no Highlight contour, smoke or ring behind it can paint over it
	-- (a BillboardGui face could not stop that). With te5_moon: the photographic full moon on a grey disc. Until it is
	-- uploaded: pass 4's glowing moon on a white Neon disc (a pearl that glows at night).
	local moon, haloIm, haloEntry
	local moonFace = false
	do
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
			moonFace = true
			moon = PP[solid("Moon", "MOONCORE", CORE, GMOON, "Ball", Vector3.new(6, 6, 6), IDENT)]
			fadeWin(NP, 0.6, 0.9)
			local t5 = isTe5("moon")
			hosts.moonFace = PP[solid("MoonFace", t5 and "MOONCORE" or "LUME", CORE, GMOONF, "Cylinder", Vector3.new(0.1, 9, 9), DISC)]
			fadeWin(NP, 0.6, 0.9)
			-- STUDIO-VERIFY: SurfaceGui Face = Left on the face disc (the cylinder's -X end turns to the camera), not mirrored
			local fg, fe = surface(hosts.moonFace, Enum.NormalId.Left, hiCanvas, 1.25, 2.6, "moon", 0.6, 0.9)
			table.insert(ghostGuis, fg)
			if t5 then
				-- (te5_moon failed to load in the game: pass 4's moon needs the white disc behind it)
				local fd = hosts.moonFace
				fixUps[fe[1]] = function()
					fd.Color, fd.Material = MAT.LUME[1], MAT.LUME[2]
				end
			end
		end
		moon.CastShadow = CONFIG.SHADOWS and hi
		hosts.moonOut = new("Attachment", { Name = "StreamOut", CFrame = CFrame.new(0, 0, moonFace and -3.95 or -4.55) * CFrame.Angles(0, 0, rad(90)) }, moon)
		-- a thin halo round the moon's rim (15 studs: the face is 4.4 studs nearer the camera, so it looks bigger than the
		-- core). It sits 2 studs behind the core, so the face hides its inner edge; not further,
		-- or on the clock side it would reach the inlay plane and get cut (keeps >= 0.4 from every GUI plane)
		local halo = new("BillboardGui", { Name = "Halo", Size = UDim2.new(15, 0, 15, 0), StudsOffset = Vector3.new(0, 0, -2.0), LightInfluence = 0,
			Brightness = 1.0, MaxDistance = 400, AlwaysOnTop = false }, moon)
		haloIm = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ImageColor3 = Color3.fromRGB(240, 240, 244),
			ImageTransparency = 1 }, halo)
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "12_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
