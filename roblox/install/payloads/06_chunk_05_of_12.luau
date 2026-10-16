-- AuraRNG Studio install kit | 06_chunk_05_of_12.luau | step 6: piece 5 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (155147 bytes, checksum 484396720).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "06_chunk_05_of_12.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-155147-484396720-12-73384217"
local NEW_LEN, NEW_SUM = 155147, 484396720
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
local LENS = { 13303, 13296, 13287, 13167, 13290, 13271, 13256, 13301, 13240, 13302, 13264, 9170 }
local SUMS = { 67409079, 948660274, 266404745, 816058228, 379904796, 918623796, 659321254, 309794145, 464118196, 901135989, 725623781, 681290935 }

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
-- piece 5 of 12 of the new source (13290 bytes, checksum 379904796, long bracket level 1)
local DATA = [=[
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
			for j = 0, 7 do
				local b = rad((j + 0.5) * 45)
				crownPart("Bow", "Cylinder", Vector3.new(2.05, 0.55, 0.55), CFrame.new(2.283 * cos(b), 19.6 + 2.283 * sin(b), -0.2) * CFrame.Angles(0, 0, b + rad(90)))
			end
		end
	end

	-- the night corona: a soft ring of light just outside the bezel (night only, rim-only, behind the clock). Kept at every
	-- distance: at night it is the clock's glow from across the plaza
	-- (the corona, the void's horizon glow and the moon halo are sized for te5_halo, whose ring peaks at 0.73 of its
	-- half-width. Until it is uploaded, or if it fails to load, the pass-2 "rim" texture stands in: hs scales them so its
	-- ring, at RIM_R, lands in the same place)
	hosts.hs = isTe5("halo") and 1 or 0.73 / CONFIG.RIM_R
	local corona, coronaEntry
	if hi then
		local cp = carrier("Corona", CORE, GK, Vector3.new(44, 44, 0.05) * hosts.hs, CFrame.new(0, 0, -3.2) * frontL) -- (ring peak R 16.3: seen from the front, 3.2 studs back, it lands just outside the bezel)
		corona, coronaEntry = surface(cp, frontFace, 512, 1.8, nil, "halo", 5.0, 6.0, Color3.fromRGB(240, 240, 242))
		corona.Enabled = false
		coronaEntry[2] = 1
		if hosts.hs == 1 then
			fixUps[coronaEntry[1]] = function(o) o.Parent.Parent.Size = Vector3.new(44, 44, 0.05) * (0.73 / CONFIG.RIM_R) end
		end
	end
	-- the clock's emitter hosts: the shard feed at eleven (the rim smoke moved onto the void) and the time-dust ring
	hosts.timeDust = hi and carrier("TimeDust", CORE, GDUST, Vector3.new(31.6, 31.6, 0.2)) -- (a ring turning with the hands: P13)
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
		-- fine silver wire rings with many short segments, so they read round (no kinks or joints) from Roblox's default
		-- zoom, and slim, so the body reads through the cage; a satin-silver equator bracelet with twelve lume hours. (On low
		-- the parts go to the meridian, the biggest silver shape on a phone's screen)
		ring("Meridian", "SILVER", ARM, GF1, low and 18 or 28, 6.0, 0.26, 0.15, 1.0)
		ring("Equator", "SATIN", ARM, GF2, low and 14 or 22, 5.3, 0.20, 0.32, 1.3)
		if hi then
			for k = 0, 11 do -- twelve lume hours on the equator band's outer face
				local i = solid("Hour", "LUME", ARMD, GF2, "Block", Vector3.new(0.14, 0.10, 0.28), radial(k * 30, 5.45, 0))
				fadeWin(i, 1.3, 1.6)
			end
			ring("Ecliptic", "SILVER", ARM, GF3, 24, 4.6, 0.28, 0.14, 1.6)
			for _, x in ipairs({ 5.6, -5.6 }) do -- pins: equator to meridian
				local i = solid("Pin", "BRIGHT", ARMD, GF1, "Cylinder", Vector3.new(0.62, 0.26, 0.26), CFrame.new(x, 0, 0))
				fadeWin(i, 1.0, 1.3)
			end
			for _, y in ipairs({ 4.97, -4.97 }) do -- pins: ecliptic to equator
				local i = solid("Pin", "BRIGHT", ARMD, GF2, "Cylinder", Vector3.new(0.52, 0.26, 0.26), CFrame.new(0, y, 0) * VERT)
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
	-- uploaded: pass 4's moon, cropped round, on the same grey disc.
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
			hosts.moonFace = PP[solid("MoonFace", "MOONCORE", CORE, GMOONF, "Cylinder", Vector3.new(0.1, 9, 9), DISC)]
			fadeWin(NP, 0.6, 0.9)
			-- STUDIO-VERIFY: SurfaceGui Face = Left on the face disc (the cylinder's -X end turns to the camera), not mirrored;
			-- and the UICorner rounds the image (a SurfaceGui on a cylinder's end is drawn on its square face)
			-- (pass 4's moon is a paler, softer image than te5_moon: drawn as brightly its maria would wash out into a white
			-- plate, so it glows less. Pass 5.1's te5_moon is a rendered globe with real maria, rays and crater relief; at
			-- night it is drawn at 2.0, just over the place's Bloom threshold: a soft glow that keeps the bright highland
			-- craters from blowing out to white)
			local m5 = isTe5("moon")
			local fg, fe = surface(hosts.moonFace, Enum.NormalId.Left, hiCanvas, m5 and 1.25 or 0.75, m5 and 2.0 or 1.25, "moon", 0.6, 0.9)
			new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fe[1])
			table.insert(ghostGuis, fg)
			if m5 then
				local be = brights[#brights]
				fixUps[fe[1]] = function()
					be[2], be[3] = 0.75, 1.25
					be[1].Brightness = 0.75 + 0.5 * nightStep()
				end
			end
		end
		moon.CastShadow = CONFIG.SHADOWS and hi
		-- the silver stream leaves from behind the face's rim on the wearer's side (lower right as the viewer sees it), first
		-- rising a little toward the wearer, so it never crosses the moon's face (the disc's local z is the viewer's right,
		-- its y up, its +x away from the camera)
		hosts.moonOut = moonFace and new("Attachment", { Name = "StreamOut", CFrame = CFrame.fromMatrix(Vector3.new(0.1, -1.77, 3.81),
			Vector3.new(0, 0.34, 0.94), Vector3.new(1, 0, 0)) }, hosts.moonFace)
			or new("Attachment", { Name = "StreamOut", CFrame = CFrame.new(0, 0, -4.55) * CFrame.Angles(0, 0, rad(90)) }, moon)
		-- a thin halo round the moon's rim (15 studs: the face is 4.4 studs nearer the camera, so it looks bigger than the
		-- core). It sits 2 studs behind the core, so the face hides its inner edge; not further,
		-- or on the clock side it would reach the inlay plane and get cut (keeps >= 0.4 from every GUI plane)
		local hd = 15 * hosts.hs
		local halo = new("BillboardGui", { Name = "Halo", Size = UDim2.new(hd, 0, hd, 0), StudsOffset = Vector3.new(0, 0, -2.0), LightInfluence = 0,
			Brightness = 1.0, MaxDistance = 400, AlwaysOnTop = false }, moon)
		haloIm = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ImageColor3 = Color3.fromRGB(240, 240, 244),
			ImageTransparency = 1 }, halo)
		applyTex(haloIm, "halo")
		if hosts.hs == 1 then
			fixUps[haloIm] = function(o) o.Parent.Size = UDim2.new(10.95 / CONFIG.RIM_R, 0, 10.95 / CONFIG.RIM_R, 0) end
		end
		haloEntry = { haloIm, 0.65, 1.4, 2.2, 1 }
		table.insert(images, haloEntry)
		table.insert(brights, { halo, 1.0, 1.6 })
		table.insert(ghostGuis, halo)
	end
	-- the moon's key light (high quality only: on phones' voxel lighting a moving light steps in 4-stud blocks).
	-- STUDIO-VERIFY: a PointLight on an attachment of a part moved by BulkMoveTo follows it every frame
	local keyLight = hi and new("PointLight", { Name = "Key", Range = 26, Color = Color3.fromRGB(230, 232, 240), Brightness = 0, Shadows = false,
		Enabled = false }, new("Attachment", { Name = "KeyLight", Position = Vector3.new(0, 4.5, -5.5) }, moon))

	-- the void: a pure-black Neon ball. STUDIO-VERIFY: Neon black renders pure black under the place's Bloom
	local void
	local voidSize = Vector3.new(8, 8, 8)
	do
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
	end
	if not void then
		void = PP[solid("Void", "VOID", CORE, GVOID, "Ball", Vector3.new(8, 8, 8), IDENT)]
		fadeWin(NP, 0, 0.4)
	end
	void.CastShadow = CONFIG.SHADOWS and hi
	hosts.voidOut = new("Attachment", { Name = "StreamOut", CFrame = CFrame.new(0, 0, -4.05) * CFrame.Angles(0, 0, rad(90)) }, void)
	do
		-- the accretion disc: opaque white-hot streaks with black dust lanes, tilted 24° toward the viewer, its near half in
		-- front of the core. (Top face only: the disc always tilts toward the viewer, so its underside is never seen.)
		local accretion = carrier("Accretion", CORE, GACC, Vector3.new(13, 0.05, 13))
		table.insert(ghostGuis, (surface(accretion, Enum.NormalId.Top, hiCanvas, 1.6, 2.4, "accretion", 0.3, 1.1)))
		hosts.swirl = carrier("VoidSwirl", CORE, GSWIRL, Vector3.new(13, 0.3, 13))
		-- the event horizon's glow: one emitter on the silhouette plane (camera-facing, like the photon ring) keeps three
		-- soft rings alive at once, overlapping into a steady glow that hugs the black edge (no pulse; never a billboard,
		-- which the accretion plane would cut)
		hosts.horizon = hi and carrier("Horizon", CORE, GPF, Vector3.new(0.2, 0.2, 0.2))
		-- the photon ring: a lume hairline that always hugs the black silhouette as the camera sees it (from any distance;
		-- it thickens with distance in steps, HAIR below, so it never breaks into a crawling stair-step without anti-aliasing)
		local N = low and 12 or 24
		hosts.photon = {}
		for i = 0, N - 1 do
			local th = (i + 0.5) * 360 / N
			local k = solid("PhotonRing", "LUME", CORE, GPF, "Block", Vector3.new(low and 2.25 or 1.14, HAIR[low and 2 or 1][1], 0.12), IDENT)
			PROT[k], PRR[k], PRS[k] = CFrame.Angles(0, 0, -rad(th)), 0.115 + HAIR[low and 2 or 1][1] / 2, 11
			table.insert(hosts.photon, k)
			PS[k], PM0[k], PM1[k] = true, 0.25 + 0.6 * i / N, 0.85 + 0.6 * i / N
			fadeWin(k, 0.25 + 0.6 * i / N, 0.45 + 0.6 * i / N)
		end
		-- (the lensed disc, the far side of the accretion disc bent over and under the shadow, is two beams: below)
		-- the heart: a small brilliant four-point star just in front of the core (a pinpoint of light inside the lensed band,
		-- not a sticker; on low just the lume ball: a single pair of spikes read as a slit pupil).
		-- STUDIO-VERIFY: Roblox wedge orientation (right angle at -Y, +Z); if the spikes come out hollow: attribute WEDGE_SWAP
		local hb = solid("Heart", "LUME", CORE, GHF, "Ball", Vector3.new(0.70, 0.70, 0.70), IDENT)
		fadeWin(hb, 0.9, 1.1)
		local function grow(i, L)
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
