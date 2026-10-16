-- AuraRNG Studio install kit | 09_chunk_08_of_12.luau | step 9: piece 8 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (155147 bytes, checksum 484396720).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "09_chunk_08_of_12.luau"
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

local K = 8
-- piece 8 of 12 of the new source (13301 bytes, checksum 309794145, long bracket level 1)
local DATA = [=[
				LockedToPart = true, Rotation = n(0, 90), RotSpeed = n(-8, 8), ZOffset = 0.2 }, WHITE_LE, WHITE_BR, "nearcam")
			-- (and clusters of glitter ride the same ring between the stars: each cluster's grains swell and fade on their own
			-- beats, which gives the ring a glittering body that reads from across the plaza)
			pe(hosts.halo, "stardust", 3.6, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.76, EmissionDirection = N_.Top,
				Rate = 8, Lifetime = n(4, 6), Speed = n(0.05, 0.15), Size = n(3.0, 4.0),
				Transparency = seq({ { 0, 1 }, { 0.2, 0.25 }, { 0.8, 0.25 }, { 1, 1 } }), LockedToPart = true, Rotation = n(0, 360),
				RotSpeed = n(-6, 6), FlipbookFramerate = n(6, 9), FlipbookStartRandom = true }, { 0.4, 0.9 }, { 2.0, 2.6 }, "nearcam")
		end
		-- P16 (pass 5.1): the duality helix: two points turn round the body at 220 degrees a second and leave a strand each,
		-- so a silver ribbon of light and an ink ribbon of smoke braid up round the wearer from the feet to above the head,
		-- about one and a half turns each (not locked: each particle stays where it was born and climbs, which is what draws
		-- the spiral; born 0.4 studs apart, so each strand reads as one ribbon). While the wearer travels the strands thin
		-- out, so they don't hang far behind (see the travelling flip)
		em.strandMoon = pe(hosts.strandMoon, "mote", 5.2, { EmissionDirection = N_.Top, Rate = rate(34, 14), Lifetime = n(2.0, 2.3),
			Speed = n(2.6, 2.9), SpreadAngle = Vector2.new(4, 4), Drag = 0.3, Size = seq({ { 0, 1.0 }, { 0.7, 0.8 }, { 1, 0 } }),
			Transparency = seq({ { 0, 1 }, { 0.06, 0.02 }, { 0.75, 0.15 }, { 1, 1 } }), ZOffset = 0.4 }, WHITE_LE, WHITE_BR, "nearcam")
		em.strandVoid = pe(hosts.strandVoid, "wisp", 5.2, { EmissionDirection = N_.Top, Rate = rate(18, 8), Lifetime = n(2.0, 2.3),
			Speed = n(2.6, 2.9), SpreadAngle = Vector2.new(4, 4), Drag = 0.3, Size = seq({ { 0, 1.4 }, { 0.5, 2.4 }, { 1, 1.1 } }),
			Transparency = seq({ { 0, 1 }, { 0.1, 0.1 }, { 0.7, 0.35 }, { 1, 1 } }), Color = ColorSequence.new(INK), Rotation = n(0, 360),
			RotSpeed = n(-40, 40), ZOffset = 0.3 }, nil, nil, "nearcam")
		-- P17 (pass 5.1): stars twinkle inside the clock's star window, between the rete's bars (locked to the dial, so they
		-- stay in the face however the clock turns to its viewer)
		if hi and hosts.inlay then
			pe(hosts.inlay, "twinkle", 4.4, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0, EmissionDirection = N_.Front,
				Rate = 5, Lifetime = n(2.6, 3.4), Speed = n(0), Size = seq({ { 0, 1.0, 0.3 }, { 1, 1.0, 0.3 } }),
				Transparency = seq({ { 0, 1 }, { 0.12, 0 }, { 0.88, 0 }, { 1, 1 } }), LockedToPart = true, Rotation = n(0, 90),
				ZOffset = 0.6 }, { 0.6, 1 }, { 2.2, 3.0 })
		end
		if hi then
			-- P7: a low mist bank round the pool's rim, only while standing on the ground (ShapePartial 0.8: the outer fifth
			-- of the disc, so the galaxy inside stays clear)
			-- (pass 5.1: te5_mistbank is one soft low fog bank, densest along its middle and thinning upward in layers: a
			-- single image, because a 6-8 s particle would step through a flipbook. Kept level: the bank is wide and flat)
			local mb = isTe5("mistbank")
			local mist = pe(hosts.floorFx, "mistbank", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.8, EmissionDirection = N_.Top,
				Rate = 2.5, Lifetime = n(6, 8), Speed = n(0.1, 0.25), Size = mb and seq({ { 0, 9 }, { 1, 15 } }) or seq({ { 0, 8 }, { 1, 14 } }),
				Transparency = mb and seq({ { 0, 1 }, { 0.3, 0.55 }, { 0.7, 0.6 }, { 1, 1 } }) or seq({ { 0, 1 }, { 0.3, 0.80 }, { 0.7, 0.82 }, { 1, 1 } }),
				Color = ColorSequence.new(MIST), LockedToPart = true, Rotation = mb and n(-4, 4) or n(0, 360),
				RotSpeed = mb and n(-2, 2) or n(-6, 6) }, nil, nil, "ground")
			if mb then
				propsFix(mist, { Size = seq({ { 0, 8 }, { 1, 14 } }), Transparency = seq({ { 0, 1 }, { 0.3, 0.80 }, { 0.7, 0.82 }, { 1, 1 } }),
					Rotation = n(0, 360), RotSpeed = n(-6, 6) }, { 0, 0, 1, 1 })
			end
		end
		-- P8: starlight rises off the turning arms and swirls with them, in slow four-point twinkles (grow, hold, shrink);
		-- black ash flakes rise against them. At Roblox's default zoom, where the floor is a few studs from the lens, the
		-- twinkles are drawn smaller (five sizes made here, each step under 20 %, changed only when the zoom moves a step
		-- past a threshold: never a jump or a pulse on the floor)
		hosts.moteSizes = {}
		for k = 1, 5 do
			local pk = 1.3 - 0.1625 * (k - 1) -- (1.3, 1.14, 0.98, 0.81, 0.65)
			hosts.moteSizes[k] = seq({ { 0, 0 }, { 0.25, pk, 0.3 * pk / 1.3 }, { 0.75, pk, 0.3 * pk / 1.3 }, { 1, 0 } })
		end
		em.motes = pe(hosts.floorFx, "glint5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top,
			Rate = rate(18, 8), Lifetime = n(2.6, 3.6), Speed = n(0.5, 1.2), Acceleration = Vector3.new(0, 0.35, 0), Drag = 0.2,
			Size = hosts.moteSizes[1], Transparency = glintT, Rotation = n(0, 90), RotSpeed = n(-20, 20),
			LockedToPart = true, ZOffset = 0.2 }, WHITE_LE, WHITE_BR)
		if hi then
			-- (pass 5.1: te5_ash is an ember flake tumbling through 16 frames: charred black, burning white-hot along one
			-- side, so it is drawn white (an ASH tint would put the burn out); the pass-4 ash it falls back to is drawn ASH)
			local ember = isTe5("ash5")
			em.ash = pe(hosts.floorFx, "ash5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top, Rate = 8,
				Lifetime = n(3, 4.5), Speed = n(0.8, 2.0), Acceleration = Vector3.new(0, 0.3, 0), Drag = 0.4,
				Size = ember and n(0.56, 0.84) or n(0.4, 0.6), Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.75, 0.2 }, { 1, 1 } }),
				Color = ColorSequence.new(ember and WHITE or ASH), Rotation = n(0, 360), RotSpeed = n(-90, 90), FlipbookFramerate = n(8, 12),
				FlipbookStartRandom = true }, ember and { 0, 0 } or nil, ember and { 1.6, 3.2 } or nil)
			if ember then
				-- (if the ember fails to load in the game, the pass-4 ash comes back black, unlit and its old size)
				fixUps[em.ash] = function(o)
					o.Color, o.Size, o.Brightness = ColorSequence.new(ASH), seq({ { 0, 0.5, 0.1 }, { 1, 0.5, 0.1 } }), 1
					for _, e in ipairs(emitNight) do
						if e[1] == o then e[4], e[5] = 1, 1 end
					end
				end
			end
			-- P9: a vortex funnel: streaks spiral inward and climb into the balance wheel (off in first person: the camera
			-- sits right inside it)
			local p9 = { Rate = 16, Lifetime = n(1.7, 2.0), Speed = n(2.8, 3.2), Acceleration = Vector3.new(0, 1.0, 0),
				Size = seq({ { 0, 0.42 * stS }, { 1, 0.1 * stS } }), Transparency = seq({ { 0, 1 }, { 0.12, 0.05 }, { 0.85, 0.1 }, { 1, 1 } }),
				LockedToPart = true, Orientation = VPAR, Rotation = stRot }
			if CONFIG.SWIRL_POINTS then
				p9.EmissionDirection, p9.SpreadAngle = N_.Front, Vector2.new(0, 10)
				sizeFix(pe(rimPoint(hosts.funnel, 5.3), "streak5", 4.8, p9, WHITE_LE, WHITE_BR, "nearcam"), stS, { { 0, 0.42 }, { 1, 0.1 } })
			else
				p9.Shape, p9.ShapeStyle, p9.ShapeInOut, p9.EmissionDirection = CYL, SURFACE, INWARD, N_.Top
				sizeFix(pe(hosts.funnel, "streak5", 4.8, p9, WHITE_LE, WHITE_BR, "nearcam"), stS, { { 0, 0.42 }, { 1, 0.1 } })
			end
		end
		-- P10: the palms drink the streams: silver streaks converge into one palm, ink streaks into the other (locked to the
		-- palm, so they still converge on it while the wearer walks; off in first person, where the palms are just under the
		-- lens). STUDIO-VERIFY: Sphere + Surface + Inward converges on the centre (fallback: Outward with a negative Speed)
		local function intake(host, color, le, br)
			sizeFix(pe(host, "streak5", 5.2, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = INWARD, Rate = rate(14, 6), Lifetime = n(0.85, 0.95),
				Speed = n(1.35, 1.45), Size = seq({ { 0, 0.3 * stS }, { 1, 0.05 * stS } }), Transparency = seq({ { 0, 1 }, { 0.25, 0.05 }, { 1, 0.2 } }),
				Color = ColorSequence.new(color), ZOffset = 0.2, Orientation = VPAR, Rotation = stRot, LockedToPart = true }, le, br, "nearcam"),
				stS, { { 0, 0.3 }, { 1, 0.05 } })
		end
		intake(hosts.palmMoon, WHITE, WHITE_LE, WHITE_BR)
		intake(hosts.palmVoid, INK, nil, nil)
		-- P11: the wearer burns with the aura: silver wisps rise off the shoulders and back (not while travelling: no smog
		-- trail), and sparks stream up the body (they keep going while travelling and stream out behind like a comet's
		-- tail). Silver, not ink: from every camera the wearer stands against the black dial, where ink would vanish. They
		-- live on the character's torso (destroy() removes them) and switch off in first person
		do
			local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
			if torso and torso:IsA("BasePart") then
				-- (pass 5.1: te5_wisp is a faint tuft drawn up into curling incense-like tendrils; it starts small in its cell and
				-- rises to the top of it, so it is drawn bigger and near upright, with less night glow than the old puff)
				local wsp = isTe5("wisp")
				em.wisps = pe(torso, "wisp", 5.2, { Shape = BOX, ShapeStyle = SURFACE, EmissionDirection = N_.Top, Rate = rate(7, 3), Lifetime = n(1.6, 2.2),
					Speed = n(1.5, 2.5), SpreadAngle = Vector2.new(20, 20), Acceleration = Vector3.new(0, 1, 0),
					Size = wsp and seq({ { 0, 2.2 }, { 1, 4.6 } }) or seq({ { 0, 1.2 }, { 1, 3.4 } }),
					Transparency = wsp and seq({ { 0, 1 }, { 0.2, 0.1 }, { 0.75, 0.2 }, { 1, 1 } }) or seq({ { 0, 1 }, { 0.2, 0.32 }, { 0.6, 0.55 }, { 1, 1 } }),
					Color = ColorSequence.new(Color3.fromRGB(200, 202, 208)), ZOffset = -1.5, Rotation = wsp and n(-15, 15) or n(0, 360),
					RotSpeed = wsp and n(-10, 10) or n(-40, 40) }, wsp and { 0.2, 0.4 } or { 0.2, 0.6 }, wsp and { 1.2, 1.4 } or { 1.2, 2.0 }, "body")
				if wsp then
					propsFix(em.wisps, { Size = seq({ { 0, 1.2 }, { 1, 3.4 } }), Transparency = seq({ { 0, 1 }, { 0.2, 0.32 }, { 0.6, 0.55 }, { 1, 1 } }),
						Rotation = n(0, 360), RotSpeed = n(-40, 40) }, { 0.2, 0.6, 1.2, 2.0 })
				end
				table.insert(charStuff, em.wisps)
				-- (pass 5.1: the body's sparks are hot flecks with hairline tails, streaking up the body the way they fly)
				table.insert(charStuff, pe(torso, "spark5", 5.2, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Top, Rate = rate(16, 6),
					Lifetime = n(0.8, 1.2), Speed = n(2.5, 4.5), SpreadAngle = Vector2.new(25, 25), Acceleration = Vector3.new(0, 2.5, 0),
					Size = seq({ { 0, 0.75 }, { 1, 0.35 } }), Transparency = seq({ { 0, 0.05 }, { 0.7, 0.15 }, { 1, 1 } }), Orientation = VPAR,
					Rotation = stRot, ZOffset = 0.5 }, { 0.5, 1 }, WHITE_BR, "body"))
			end
		end
		-- P12: while the wearer flies or runs fast, silver streaks stream out behind the body (off when slow)
		sizeFix(pe(hosts.trail, "streak5", 5.2, { EmissionDirection = N_.Back, Rate = rate(14, 6), Lifetime = n(0.45, 0.6), Speed = n(4, 6),
			SpreadAngle = Vector2.new(10, 10), Size = seq({ { 0, 0.5 * stS }, { 1, 0.1 * stS } }),
			Transparency = seq({ { 0, 0.2 }, { 0.6, 0.3 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(226, 230, 240)),
			Orientation = VPAR, Rotation = stRot }, WHITE_LE, WHITE_BR, "speed"), stS, { { 0, 0.5 }, { 1, 0.1 } })
		-- which emitters belong to the parts that turn see-through while another wearer's aura is in your way (their smoke,
		-- swirl, dust, shards, glints, horizon and palm streaks must not stay solid across your character)
		local ghostHost = { [moon] = true, [void] = true }
		for _, h in ipairs({ "swirl", "shardFeed", "horizon", "timeDust", "palmMoon", "palmVoid", "inlay" }) do
			if hosts[h] then ghostHost[hosts[h]] = true end
		end
		for _, e in ipairs(emitters) do
			local par = e[1].Parent
			if par and par:IsA("Attachment") then par = par.Parent end
			e[6] = ghostHost[par] == true
		end
	end
	table.sort(emitters, function(a, b) return a[2] < b[2] end)

	-- lights: the moon's key light (above) and the wheel's underlight on the feet (night only, high quality)
	local wheelLight = hi and new("PointLight", { Name = "Underlight", Range = 12, Color = Color3.fromRGB(230, 234, 246), Brightness = 0,
		Shadows = false, Enabled = false }, wheelHub)

	---------------------------------------------------------------- the move list (one BulkMoveTo per frame)
	local act, actParts, acf = table.create(NP), table.create(NP), table.create(NP)
	local nAct = 0
	local function rebuildActive()
		table.clear(act)
		table.clear(actParts)
		table.clear(acf)
		nAct = 0
		for i = 1, NP do
			if shownH[PH[i]] then
				nAct += 1
				act[nAct], actParts[nAct], acf[nAct] = i, PP[i], IDENT
			end
		end
	end
	rebuildActive()
	-- the solid parts that turn see-through while another wearer's aura stands between you and your camera: the clock and
	-- the orbs (ghostParts), and on their own the rings (ringParts: a visitor standing beside the wearer looks through
	-- their rings only, never through their clock). The rings also fade out on the near-camera rule.
	local ghostParts, ringParts = {}, {}
	for _, i in ipairs(solids) do
		if PH[i] == ARM or PH[i] == ARMD then
			table.insert(ringParts, PP[i])
		elseif PG[i] <= GHF or PG[i] == GMOONF then
			table.insert(ghostParts, PP[i])
		end
	end
	-- (Beams and ParticleEmitters carry a hidden LocalTransparencyModifier too; if it cannot be written, a ghosted aura's
	-- beams and smoke switch off instead)
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
