-- AuraRNG Studio install kit | 06_chunk_05_of_16.luau | step 6: piece 5 of 16
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (198845 bytes, checksum 17952987).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "06_chunk_05_of_16.luau"
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

local K = 5
-- piece 5 of 16 of the new source (13231 bytes, checksum 135632818, long bracket level 1)
local DATA = [=[
		hosts.inlay = carrier("Inlay", CORE, GK, Vector3.new(24.4, 24.4, 0.05), CFrame.new(0, 0, 0.12) * frontL)
		-- (pass 5.2: te5_dial_inlay's numerals and track are bevelled metal, shaded 170-255: drawn at 1.0 by day so the bevel
		-- shows instead of clipping to flat white; at night 1.8, crisp white just under the Bloom threshold, so the numerals
		-- stay sharp and the glow comes from the trail, the plots and the time dust)
		local il5 = isTe5("dialInlay")
		local ie
		hosts.inlayGui, ie = surface(hosts.inlay, frontFace, hiCanvas, il5 and 1.0 or 1.6, il5 and 1.8 or 2.6, "dialInlay", 3.4, 4.2)
		if il5 then
			-- (if it fails to load in the game, pass 4's flat dial comes back at its own brightness)
			local be = brights[#brights]
			fixUps[ie[1]] = function()
				be[2], be[3] = 1.6, 2.6
				be[1].Brightness = 1.6 + 1.0 * nightStep() + be[4]
			end
		end
		-- raised lume plots at the hours, on the minute track. (pass 5.2) They land dark and light one by one round the dial
		-- in the reveal's buildup, I first and XII last, at midnight (hosts.plots: XII is [1])
		if hi then
			for h = 0, 11 do
				local k = solid("Plot", "LUME", DETAIL, GK, "Block", Vector3.new(0.42, 0.55, 0.18), radial(h * 30, 11.85, 0.21))
				motion(k, radial(h * 30, 11.85, 3.21), 3.4 + 0.04 * h, 0.3)
				fadeWin(k, 3.4 + 0.04 * h, 3.5 + 0.04 * h)
				PP[k].Color = LUME_OFF
				hosts.plots[h + 1] = { PP[k], 0 }
			end
			-- (pass 5.2) a polished flange round the star window: a bright edge between the chapter ring and the deep sky
			for i = 0, 23 do
				local th = (i + 0.5) * 15
				local k = solid("Flange", "BRIGHT", DETAIL, GK, "Block", Vector3.new(2 * 9.57 * math.tan(rad(7.5)) + 0.02, 0.24, 0.22), radial(th, 9.45, 0.23))
				local a = 2.3 + 0.9 * i / 24
				motion(k, radial(th, 9.45, -2.77), a, 0.6)
				fadeWin(k, a, a + 0.25)
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
					motion(i, radial(phi, 2.355 * 2.2, zk), 3.0 + 0.04 * k, 0.5)
					fadeWin(i, 3.0 + 0.04 * k, 3.15 + 0.04 * k)
				end
			end
		end
		-- the sub-dial: a dark guilloché disc at the centre. STUDIO-VERIFY: SurfaceGui Face = Left is the cylinder's -X end,
		-- which faces the viewer after the 90° turn (canvas right = the viewer's right)
		-- (pass 5.2: it turns slowly clockwise under the still central star, an engine running beneath the face)
		local subdial = PP[solid("SubDial", "DEEP", CORE, G2.SUB, "Cylinder", Vector3.new(0.30, 6.5, 6.5), CFrame.new(0, 0, 0.57) * DISC)]
		motion(NP, CFrame.new(0, 0, -1.43) * DISC, 3.2, 0.4)
		fadeWin(NP, 3.2, 3.4)
		hosts.subdialGui = surface(subdial, Enum.NormalId.Left, midCanvas, 1.4, 2.2, "subdial", 3.2, 3.4)
		-- (pass 5.2) the central star: an eight-point compass star on the sub-dial, long points to XII, III, VI and IX and
		-- short ones between (low quality: the four long ones). Each point is two flat facets, bright silver on its
		-- counter-clockwise half and gunmetal on its clockwise half, so it reads like a cut star catching the light. They
		-- grow out of the hub as the sub-dial lands. STUDIO-VERIFY: the facets come out solid, not hollow (the wedge
		-- orientation, as the void's heart: attribute WEDGE_SWAP)
		do
			local wa = CONFIG.WEDGE_SWAP and -90 or 90
			for p = 0, 7, low and 2 or 1 do
				local long = p % 2 == 0
				local len, w, z = long and 4.6 or 2.9, long and 0.75 or 0.55, long and 0.76 or 0.745
				local S = CFrame.Angles(0, 0, -rad(p * 45))
				for side = -1, 1, 2 do
					local L = S * CFrame.new(side * w / 2, len / 2, z) * CFrame.Angles(0, rad(-side * wa), 0)
					local i = solid("StarFacet", side < 0 and "BRIGHT" or "GUN", CORE, GK, "Wedge", Vector3.new(0.06, len, w), L)
					motion(i, CFrame.new(L.Position * 0.05) * L.Rotation, 3.25 + 0.03 * p, 0.55)
					fadeWin(i, 3.25 + 0.03 * p, 3.45 + 0.03 * p)
				end
			end
		end
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
		-- (len: tip-to-tail length for a film mesh, mid: its centre; the rest are the procedural parts' sizes and heights;
		-- pass 5.2: ring/ringY/eye: the Breguet moon near the tip, and the lume strip now stops short of it)
		for _, hd in ipairs({
			{ grp = GHOUR, len = 8.55, mid = 2.67, w = 0.55, shaft = 5.6, shaftY = 3.4, tip = 0.70, tipY = 6.45, tail = 1.6, tailY = -0.8,
				lumeW = 0.24, lumeL = 2.6, lumeY = 2.6, ring = 1.30, ringY = 4.75, eye = 0.72 },
			{ grp = GMIN, len = 11.17, mid = 3.58, w = 0.40, shaft = 8.0, shaftY = 4.6, tip = 0.52, tipY = 8.8, tail = 2.0, tailY = -1.0,
				lumeW = 0.16, lumeL = 4.5, lumeY = 4.0, ring = 0.96, ringY = 7.0, eye = 0.52 },
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
				if hi then
					handPart("Tail", "SILVER", CORE, hd.grp, "Block", Vector3.new(hd.w, hd.tail, 0.16), Vector3.new(0, hd.tailY, 0))
					-- (pass 5.2) a Breguet moon: a polished ring near the tip with a dark eye, which reads as a hole the dark
					-- dial shows through
					handPart("BreguetRing", "BRIGHT", CORE, hd.grp, "Cylinder", Vector3.new(0.18, hd.ring, hd.ring), Vector3.new(0, hd.ringY, 0.01), DISC)
					handPart("BreguetEye", "BASE", CORE, hd.grp, "Cylinder", Vector3.new(0.04, hd.eye, hd.eye), Vector3.new(0, hd.ringY, 0.12), DISC)
				end
			end
			if hi then handPart("Lume", "LUME", CORE, hd.grp, "Block", Vector3.new(hd.lumeW, hd.lumeL, 0.05), Vector3.new(0, hd.lumeY, 0.105)) end
		end
	end
	hosts.needle = PP[handPart("Needle", "SILVER", CORE, GSEC, "Block", Vector3.new(HAIR[low and 2 or 1][2], 12.2, 0.08), Vector3.new(0, 3.5, 0))]
	if hi then
		handPart("Weight", "BRIGHT", CORE, GSEC, "Cylinder", Vector3.new(0.08, 0.9, 0.9), Vector3.new(0, -2.0, 0), DISC)
		handPart("SecondsTip", "LUME", CORE, GSEC, "Ball", Vector3.new(0.26, 0.26, 0.26), Vector3.new(0, 9.6, 0))
	end
	-- the hub stack over the hands: a dark base, a bright cap and a lume jewel
	handPart("Hub", "STEEL", CORE, GK, "Cylinder", Vector3.new(0.30, 1.30, 1.30), Vector3.new(0, 0, 1.62), DISC)
	handPart("HubCap", "BRIGHT", CORE, GK, "Cylinder", Vector3.new(0.20, 0.85, 0.85), Vector3.new(0, 0, 1.85), DISC)
	if hi then handPart("Jewel", "LUME", CORE, GK, "Ball", Vector3.new(0.45, 0.45, 0.45), Vector3.new(0, 0, 1.98)) end
	-- (pass 5.2) the seconds hand's trail: a comet arc of light on the minute track that rides the hand round (te5_trail;
	-- head at the hand, tail behind it), lighting each hour as it passes. In the reveal's buildup it leaves the hand and
	-- sweeps the dial once, lighting the plots, and reaches XII at midnight; then it fades and comes back on the hand.
	-- It rides a little above the inlay, so its light lies over the track (the plots stand up through it).
	-- STUDIO-VERIFY: the comet's head is at the hand and its tail behind (it shares the inlay's face convention)
	if hi and isTe5("trail") then
		hosts.secTrail = carrier("SecondsTrail", CORE, G2.TRAIL, Vector3.new(25, 25, 0.05), frontL)
		hosts.trailGui, hosts.trailE = surface(hosts.secTrail, frontFace, hiCanvas, 1.4, 2.4, "trail", 0, 0, nil, true)
		hosts.trailB = brights[#brights]
		table.insert(ghostGuis, hosts.trailGui)
	end
	-- (pass 5.2) the energy links' ports on the bezel's band: the moon's link comes in at IX, the void's leaves at III and
	-- the floor's falls from VI (each beam leaves or arrives along its port's x axis); a signature sparkle glints at XII
	hosts.ports = carrier("LinkPorts", CORE, GK, Vector3.new(0.2, 0.2, 0.2))
	hosts.portIX = new("Attachment", { Name = "PortIX", CFrame = CFrame.fromMatrix(PORT_IX, Vector3.new(0.898, 0, -0.44), Vector3.yAxis) }, hosts.ports)
	hosts.portIII = new("Attachment", { Name = "PortIII", CFrame = CFrame.fromMatrix(PORT_III, Vector3.new(0.898, 0, 0.44), Vector3.yAxis) }, hosts.ports)
	hosts.portVI = new("Attachment", { Name = "PortVI", CFrame = CFrame.fromMatrix(PORT_VI, Vector3.new(0, -0.8, 0.6), Vector3.new(0, 0.6, 0.8)) }, hosts.ports)
	hosts.portXII = new("Attachment", { Name = "PortXII", Position = Vector3.new(0, 13.2, 1.4) }, hosts.ports)

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
