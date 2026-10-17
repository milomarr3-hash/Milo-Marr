-- AuraRNG Studio install kit | 05_chunk_04_of_16.luau | step 5: piece 4 of 16
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (198845 bytes, checksum 17952987).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "05_chunk_04_of_16.luau"
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

local K = 4
-- piece 4 of 16 of the new source (13140 bytes, checksum 382625152, long bracket level 0)
local DATA = [[
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
	local GDAIS, GG0, GG1, GG2, GENG, GWHEEL, GFUNNEL = 30, 31, 32, 33, 34, 35, 37
	local GHALO, GHELIX = 36, 38 -- (pass 5.1: the star halo's turning ring, the helix hub)
	local GFEED, GAIR, GBOKEH, GPALMM, GPALMV, GMOONF, GDUST = 39, 40, 41, 42, 43, 44, 45
	-- (pass 5.2, as constants in one table: End.build has no registers to spare for 14 more locals) the bezel's engraved
	-- band; the lume trail; the links' moon, void and floor ends; the two runners; the galaxy's spiral host, fine swirl,
	-- energy rings and stage sweep; the dial's burst ring; the void's infall shell; the moon's ring of glints
	local G2 = { BAND = 46, TRAIL = 47, LINKM = 48, LINKV = 49, LINKF = 50, RUN1 = 51, RUN2 = 52, SPIRAL = 53, FINE = 54,
		RINGS = 55, SWEEP = 56, BURST = 57, INFALL = 58, MRING = 59, SUB = 60 }
	local GCF = table.create(60, IDENT)
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
		snap = false, kY = nil, kYv = 0, layer = 0, lodF = 1, armF = 0, armQ = 0, armWant = false, armG = 0, armGQ = 0,
		armHold = 0, fpOn = false, skipN = 0, skipDt = 0, czq = 0, hlO = -1, kB = -1, wB = -1, fxLtm = false, moteI = 1,
		-- (round 3) gn/gnT/gpT: the dais's ground plane (normal, target, ray timer); fitD: how far the owner's clock steps back
		-- to keep XII in frame; yieldD/yieldT/yieldHold: another wearer's clock stepping back behind yours; r0: the rings'
		-- rise delay for the owner's close camera (decided at the first visible frame); ringsOut: the rings out of the
		-- silver tone while they fade; nearHide/ghostRemote: those flags as this build read them
		gn = Vector3.yAxis, gnT = Vector3.yAxis, gpT = 0, fitD = 0, yieldD = 0, yieldT = 0, yieldHold = 0, r0 = nil, ringsOut = false,
		nearHide = CONFIG.NEAR_HIDE, ghostRemote = CONFIG.GHOST_REMOTE, pBand = low and 2 or 1, nBand = low and 2 or 1,
		-- (pass 5.2) the reveal: revOn while it runs; gearM/runM: the gears' and runners' pace; trailA/sweepA: the trail's
		-- and the stage sweep's angles (trailA nil: the trail rides the seconds hand); convOn: the converging streaks;
		-- smokeQ: the void smoke's draw-in step; peakDone: midnight has struck; run1/run2: the runners' angles; linkLm/Lv/Lf:
		-- the links' lengths last written; ownReveal: the wearer's own real equip (bloom, push); bloom, fov0/fovW: the
		-- screen effects
		revOn = false, gearM = 1, runM = 1, trailA = nil, sweepA = 0, convOn = false, smokeQ = 0, peakDone = false, run1 = 0, run2 = 0,
		linkLm = -9, linkLv = -9, linkLf = -9, ownReveal = false, bloom = nil, bloomDone = false, fov0 = nil, fovW = nil, fovCam = nil,
		pushDone = false,
	}

	-- the part registry: part, group, rest transform in the group, hide group; the assembly's start transform and motion
	-- window; the fade window; the photon ring keeps a radius that follows the void's silhouette
	local PP, PG, PL, PH, PS, PM0, PM1, PF0, PF1, PCUR = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
	local PROT, PRR, PRS = {}, {}, {}
	local NP = 0
	local solids = {} -- parts that fade in (rest Transparency 0)
	local clockParts = {} -- (for the body-anchored fallback's see-through rule)
	local function reg(p, grp, L, h)
		NP += 1
		PP[NP], PG[NP], PL[NP], PH[NP] = p, grp, L, h
		if grp <= GGEAR0 + 7 or grp == G2.SUB then table.insert(clockParts, p) end
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
	-- (own: the reveal writes this image's transparency itself, so it stays out of the fades; brights entries carry a
	-- fourth value, the reveal's brightness boost, 0 at rest)
	local function surface(host, face, canvas, b0, b1, key, f0, f1, color, own)
		local g = new("SurfaceGui", { Face = face, SizingMode = Enum.SurfaceGuiSizingMode.FixedSize, CanvasSize = Vector2.new(canvas, canvas),
			LightInfluence = 0, Brightness = b0, AlwaysOnTop = false }, host)
		local im = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ImageColor3 = color or Color3.new(1, 1, 1),
			ImageTransparency = 1 }, g)
		applyTex(im, key)
		local e = { im, 0, f0, f1, 1 }
		if not own then table.insert(images, e) end
		if b1 then table.insert(brights, { g, b0, b1, 0 }) end
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
	local hosts = { plots = {} } -- invisible carriers and attachments the emitters, beams and lights hang on (one table: saves registers)
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
			-- (pass 5.2) a near-black band set into the bezel's face between bright lips of flute (silver | black | silver),
			-- engraved with a fine degree scale and the hours' stars on its own plane, which turns a degree a second: the
			-- scale creeps round like the sky. The band is solid and outside the silver tone, so the tone never paints over
			-- its engraving; until te5_bezel_band is uploaded it is a plain dark inset. Each segment flies in with its flute
			if hi then
				for i = 0, 31 do
					local th = (i + 0.5) * 11.25
					local k = solid("BezelBand", "DEEP", CORE, GK, "Block", Vector3.new(2 * 13.62 * math.tan(rad(5.625)) + 0.02, 0.92, 0.20),
						radial(th, 13.16, 1.07))
					local a = 2.0 + 0.9 * i / 32
					motion(k, radial(th + 40, 20.16, -2.93), a, 0.7)
					fadeWin(k, a, a + 0.25)
				end
				if isTe5("bezelBand") then
					hosts.band = carrier("BezelEngraving", CORE, G2.BAND, Vector3.new(27.4, 27.4, 0.05), frontL)
					hosts.bandGui = surface(hosts.band, frontFace, hiCanvas, 1.3, 1.8, "bezelBand", 3.0, 3.6, Color3.fromRGB(236, 236, 240))
					table.insert(ghostGuis, hosts.bandGui)
				end
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
