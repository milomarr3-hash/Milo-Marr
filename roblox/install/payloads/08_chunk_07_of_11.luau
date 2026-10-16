-- AuraRNG Studio install kit | 08_chunk_07_of_11.luau | step 8: piece 7 of 11
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (141659 bytes, checksum 402664341).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "08_chunk_07_of_11.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-141659-402664341-11-730820328"
local NEW_LEN, NEW_SUM = 141659, 402664341
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

local N = 11
local LENS = { 13243, 13273, 13303, 13189, 13236, 13281, 13225, 13249, 13287, 13321, 9052 }
local SUMS = { 563366530, 792637773, 818557759, 655489799, 441189153, 861752101, 374124160, 158431880, 132410676, 886213953, 397877975 }

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
-- piece 7 of 11 of the new source (13225 bytes, checksum 374124160, long bracket level 1)
local DATA = [=[
			Color = ColorSequence.new(WHITE, Color3.fromRGB(170, 174, 184)), LockedToPart = true, ZOffset = 0.3 }
		if CONFIG.SWIRL_POINTS then
			p1.EmissionDirection, p1.SpreadAngle = N_.Front, Vector2.new(0, 10)
			pe(rimPoint(hosts.swirl, 6.3), "mote", 1.2, p1, WHITE_LE, WHITE_BR)
		else
			p1.Shape, p1.ShapeStyle, p1.ShapeInOut, p1.EmissionDirection = CYL, SURFACE, INWARD, N_.Top
			pe(hosts.swirl, "mote", 1.2, p1, WHITE_LE, WHITE_BR)
		end
		-- P2: dust snows off the moon and falls away below it (halved while the wearer travels)
		em.dust = pe(moon, "mote", 1.6, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = rate(10, 5), Lifetime = n(3.0, 4.5),
			Speed = n(0.25, 0.6), Acceleration = Vector3.new(0, -1.1, 0), Drag = 0.4, Size = seq({ { 0, 0.18 }, { 0.2, 0.6, 0.15 }, { 1, 0.18 } }),
			Transparency = seq({ { 0, 1 }, { 0.12, 0.08 }, { 0.75, 0.15 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(238, 240, 246)),
			Rotation = n(0, 360), RotSpeed = n(-30, 30) }, { 0.2, 0.7 }, { 1.4, 2.2 })
		if hi then
			-- P3: metal shards break off the bezel at eleven and fly across the face into the void (tumbling flipbook)
			local shardScale = isTe5("shards5") and 1.3 or 1 -- (the te5 sliver fills about half its cell)
			sizeFix(pe(hosts.shardFeed, "shards5", 4.8, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Front, Rate = 7, Lifetime = n(2.9, 3.2),
				Speed = n(8.5, 9.5), SpreadAngle = Vector2.new(6, 6),
				Size = seq({ { 0, 0.6 * shardScale }, { 0.85, 0.9 * shardScale, 0.12 * shardScale }, { 1, 0.35 * shardScale } }),
				Transparency = seq({ { 0, 1 }, { 0.06, 0 }, { 0.9, 0 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(214, 218, 226)),
				Rotation = n(0, 360), RotSpeed = n(-120, 120), FlipbookFramerate = n(10, 14), FlipbookStartRandom = true }, { 0, 0.3 }, { 1, 1.6 }),
				shardScale, { { 0, 0.6 }, { 0.85, 0.9, 0.12 }, { 1, 0.35 } })
		end
		-- P4: the two opposite energies breathe: dense ink smoke boils off the void and grey-silver smoke off the moon,
		-- curling out and up round each orb (a dark corona that reads on the bright day sky, a pale one at night). Drawn 3
		-- studs further back, so the orbs' silhouettes stay crisp (the moon's opaque face hides what is born behind it).
		-- While the wearer travels the void's smoke thins and goes short-lived and the moon's stops, so no smog patches
		-- hang along the path. (te5_smoke's billows fill their cells like the pass-4 puff: both are drawn the same size)
		em.smoke = pe(void, "smoke5", 1.0, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = rate(10, 4), Lifetime = n(3.5, 4.5),
			Speed = n(1.4, 2.4), Drag = 0.35, Acceleration = Vector3.new(0, 0.4, 0), Size = seq({ { 0, 5 }, { 1, 14 } }),
			Transparency = seq({ { 0, 1 }, { 0.2, 0.16 }, { 0.7, 0.45 }, { 1, 1 } }), Color = ColorSequence.new(SMOKE), Rotation = n(0, 360),
			RotSpeed = n(-25, 25), ZOffset = -3 })
		em.smokeMoon = hi and pe(moon, "smoke5", 1.6, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = 5, Lifetime = n(3.5, 4.5),
			Speed = n(0.9, 1.5), Drag = 0.35, Acceleration = Vector3.new(0, 0.3, 0), Size = seq({ { 0, 3.5 }, { 1, 9 } }),
			Transparency = seq({ { 0, 1 }, { 0.2, 0.32 }, { 0.7, 0.55 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(176, 176, 178)),
			Rotation = n(0, 360), RotSpeed = n(-20, 20), ZOffset = -3 }, { 0.1, 0.4 })
		local glintT = seq({ { 0, 0.1 }, { 1, 0.1 } }) -- (a glint grows, holds and shrinks through its size: never a flash)
		if hi then
			-- P13: time-dust orbits the bezel: glints born just round its rim ride a ring that turns clockwise with the hands
			-- (locked to it), so the clock wears a slow halo of moving light. (Round the rim, not on it: under the silver
			-- tone a white glint on the bezel hardly reads by day; against the sky and the dark gears it does)
			pe(hosts.timeDust, "glint5", 4.4, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.9, EmissionDirection = N_.Back, Rate = 20,
				Lifetime = n(4, 5), Size = seq({ { 0, 0 }, { 0.3, 1.7, 0.35 }, { 0.7, 1.7, 0.35 }, { 1, 0 } }), Transparency = glintT,
				LockedToPart = true, ZOffset = 1.0, Rotation = n(0, 90), RotSpeed = n(-15, 15) }, { 0.5, 1 }, WHITE_BR)
			-- the event horizon's glow (above): three soft rings alive at once, Rate 1 x 3 s (sized for te5_halo's ring;
			-- the fallback's ring sits elsewhere in its image, so it is drawn at hs)
			local hz = pe(hosts.horizon, "halo", 1.0, { Rate = 1, Lifetime = n(3, 3), Size = n(11.2 * hosts.hs, 11.2 * hosts.hs), LockedToPart = true,
				Transparency = seq({ { 0, 1 }, { 0.2, 0.12 }, { 0.8, 0.12 }, { 1, 1 } }), Rotation = n(0, 360), RotSpeed = n(-8, 8), ZOffset = 0.4 },
				{ 0.4, 1 }, { 1.6, 3.0 })
			if hosts.hs == 1 then fixUps[hz] = function(o) o.Size = NumberSequence.new(8.18 / CONFIG.RIM_R) end end
		end
		-- P6: three scales of air round the wearer: a field of slow four-point sparkles (they read from 40 studs, as pass
		-- 4's did), smaller glints, and big slow bokeh between the camera and the wearer (showcase framings only)
		pe(hosts.air, "glint5", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(14, 4), Lifetime = n(3, 4.5), Speed = n(0.1, 0.3),
			SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.3, 1.1, 0.3 }, { 0.7, 1.1, 0.3 }, { 1, 0 } }), Transparency = glintT,
			Rotation = n(0, 90), RotSpeed = n(-15, 15) }, WHITE_LE, WHITE_BR)
		pe(hosts.air, "glint5", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(5, 1.5), Lifetime = n(4, 6), Speed = n(0.2, 0.5),
			SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.3, 0.7, 0.2 }, { 0.7, 0.7, 0.2 }, { 1, 0 } }),
			Transparency = seq({ { 0, 1 }, { 0.3, 0.1 }, { 0.7, 0.1 }, { 1, 1 } }), Rotation = n(0, 90), RotSpeed = n(-20, 20) }, { 0.4, 1 }, WHITE_BR)
		em.bokeh = hi and pe(hosts.bokeh, "bokeh", 3.0, { Shape = BOX, ShapeStyle = VOLUME, Rate = 0.5, Lifetime = n(5, 7), Speed = n(0.1, 0.25),
			SpreadAngle = Vector2.new(180, 180), Size = n(1.2, 2.4), Transparency = seq({ { 0, 1 }, { 0.25, 0.72 }, { 0.75, 0.72 }, { 1, 1 } }),
			Color = ColorSequence.new(Color3.fromRGB(232, 236, 246)), Rotation = n(0, 360), RotSpeed = n(-4, 4) }, { 0.3, 0.8 }, { 1.2, 1.8 }, "bokeh")
		if hi then
			-- P7: a low mist bank round the pool's rim, only while standing on the ground (ShapePartial 0.8: the outer fifth
			-- of the disc, so the galaxy inside stays clear)
			pe(hosts.floorFx, "smoke5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.8, EmissionDirection = N_.Top, Rate = 2.5,
				Lifetime = n(6, 8), Speed = n(0.1, 0.25), Size = seq({ { 0, 8 }, { 1, 14 } }), Transparency = seq({ { 0, 1 }, { 0.3, 0.80 }, { 0.7, 0.82 }, { 1, 1 } }),
				Color = ColorSequence.new(MIST), LockedToPart = true, Rotation = n(0, 360), RotSpeed = n(-6, 6) }, nil, nil, "ground")
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
			-- (te5_ash is one charred flake; its random rotation and tumble make every particle a different shape)
			em.ash = pe(hosts.floorFx, "ash5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top, Rate = 8,
				Lifetime = n(3, 4.5), Speed = n(0.8, 2.0), Acceleration = Vector3.new(0, 0.3, 0), Drag = 0.4, Size = n(0.4, 0.6),
				Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.75, 0.2 }, { 1, 1 } }), Color = ColorSequence.new(ASH), Rotation = n(0, 360),
				RotSpeed = n(-90, 90) })
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
				em.wisps = pe(torso, "smoke5", 5.2, { Shape = BOX, ShapeStyle = SURFACE, EmissionDirection = N_.Top, Rate = rate(7, 3), Lifetime = n(1.6, 2.2),
					Speed = n(1.5, 2.5), SpreadAngle = Vector2.new(20, 20), Acceleration = Vector3.new(0, 1, 0), Size = seq({ { 0, 1.2 }, { 1, 3.4 } }),
					Transparency = seq({ { 0, 1 }, { 0.2, 0.32 }, { 0.6, 0.55 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(200, 202, 208)),
					ZOffset = -1.5, Rotation = n(0, 360), RotSpeed = n(-40, 40) }, { 0.2, 0.6 }, { 1.2, 2.0 }, "body")
				table.insert(charStuff, em.wisps)
				table.insert(charStuff, pe(torso, "glint5", 5.2, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Top, Rate = rate(14, 6),
					Lifetime = n(1.4, 2.0), Speed = n(1.5, 3.0), SpreadAngle = Vector2.new(25, 25), Acceleration = Vector3.new(0, 1.5, 0),
					Size = seq({ { 0, 0 }, { 0.25, 1.3, 0.3 }, { 0.75, 1.3, 0.3 }, { 1, 0 } }), Transparency = glintT, Rotation = n(0, 90),
					RotSpeed = n(-30, 30), ZOffset = 0.5 }, { 0.5, 1 }, WHITE_BR, "body"))
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
		for _, h in ipairs({ "swirl", "shardFeed", "horizon", "timeDust", "palmMoon", "palmVoid" }) do
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "13_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
