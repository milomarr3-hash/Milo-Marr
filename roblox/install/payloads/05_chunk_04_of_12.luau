-- AuraRNG Studio install kit | 05_chunk_04_of_12.luau | step 5: piece 4 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (151582 bytes, checksum 322184148).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "05_chunk_04_of_12.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-151582-322184148-12-938307881"
local NEW_LEN, NEW_SUM = 151582, 322184148
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
local LENS = { 13269, 13222, 13287, 13307, 13252, 13232, 13230, 13284, 13301, 13300, 13204, 5694 }
local SUMS = { 882737169, 754366057, 266404745, 785979457, 290862805, 645616522, 300795074, 332029237, 56580994, 674174262, 959073682, 306083532 }

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
-- piece 4 of 12 of the new source (13307 bytes, checksum 785979457, long bracket level 1)
local DATA = [=[
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
	-- (the silver rings' parts move here, outside the Highlight's Silver model, while they fade or ghost)
	hosts.noTone = new("Model", { Name = "SilverRings" }, root)
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
			local NC = low and 16 or 18 -- (its inner edge is dark on the dark star window and the inlay covers its face: 18 is enough)
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
	hosts.needle = PP[handPart("Needle", "SILVER", CORE, GSEC, "Block", Vector3.new(HAIR[low and 2 or 1][2], 12.2, 0.08), Vector3.new(0, 3.5, 0))]
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "14_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
