-- AuraRNG Studio install kit | 08_chunk_07_of_12.luau | step 8: piece 7 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (148303 bytes, checksum 731942170).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "08_chunk_07_of_12.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-148303-731942170-12-824555251"
local NEW_LEN, NEW_SUM = 148303, 731942170
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
local LENS = { 13300, 13224, 13240, 13242, 13194, 13235, 13276, 13235, 13290, 13298, 13282, 2487 }
local SUMS = { 825733820, 782681153, 524531706, 656635892, 998587156, 867606918, 526087852, 254541497, 6651690, 395645774, 897444566, 313496838 }

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
-- piece 7 of 12 of the new source (13276 bytes, checksum 526087852, long bracket level 0)
local DATA = [[
		local SPHERE, CYL, DISCSHAPE, BOX = Enum.ParticleEmitterShape.Sphere, Enum.ParticleEmitterShape.Cylinder, Enum.ParticleEmitterShape.Disc,
			Enum.ParticleEmitterShape.Box
		local SURFACE, VOLUME = Enum.ParticleEmitterShapeStyle.Surface, Enum.ParticleEmitterShapeStyle.Volume
		local INWARD, OUTWARD = Enum.ParticleEmitterShapeInOut.Inward, Enum.ParticleEmitterShapeInOut.Outward
		local VPAR = Enum.ParticleOrientation.VelocityParallel
		local N_ = Enum.NormalId
		-- (white particles glow just above the Bloom threshold by day: small steady glints read as light, not as grey specks.
		-- They grow, hold and shrink: never a flash)
		local WHITE_LE, WHITE_BR = { 0.3, 0.9 }, { 2.4, 3.0 }
		-- the streak texture: te5_streak is a thin capsule in a square cell, so it is drawn bigger than the fallback speck;
		-- STREAK_FLIP turns streaks that fly tail-first round (STUDIO-VERIFY: VelocityParallel puts the image's TOP forward)
		local stS = isTe5("streak5") and 2.2 or 1
		-- (a te5 texture that fails to load in the game: its emitter goes back to the size made for the fallback)
		local function sizeFix(p, scale, pts)
			if scale ~= 1 then fixUps[p] = function(o) o.Size = seq(pts) end end
			return p
		end
		local stRot = CONFIG.STREAK_FLIP and n(180) or n(0)
		-- (SWIRL_POINTS: if Roblox's Cylinder emitters spray over their flat caps, the swirl and the vortex fall back to one
		-- point emitter on the rim aimed at the axis; the host's spin still curls each particle's path into a spiral arm)
		local function rimPoint(host, r)
			return new("Attachment", { Name = "SwirlPoint", CFrame = CFrame.lookAt(Vector3.new(r, 0, 0), Vector3.zero) }, host)
		end
		-- P1: matter spirals in along the accretion disc and vanishes into the black core (straight inward motion inside a
		-- spinning host becomes a spiral). STUDIO-VERIFY: Cylinder + Surface + Inward emits on the curved side toward the
		-- axis (if not: attribute SWIRL_POINTS), and LockedToPart particles ride a host moved by BulkMoveTo
		local p1 = { Rate = rate(28, 12), Lifetime = n(1.1, 1.3), Speed = n(2.2, 2.6), Size = seq({ { 0, 1.5 }, { 1, 0.35 } }),
			Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.8, 0.05 }, { 1, 0.4 } }),
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
			Transparency = seq({ { 0, 1 }, { 0.18, 0.08 }, { 0.7, 0.32 }, { 1, 1 } }), Color = ColorSequence.new(SMOKE), Rotation = n(0, 360),
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
		-- 4's did), smaller glints, and big slow bokeh between the camera and the wearer (showcase framings only). In first
		-- person the camera sits inside the air volume, so its sparkles stay off there
		pe(hosts.air, "glint5", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(14, 4), Lifetime = n(3, 4.5), Speed = n(0.1, 0.3),
			SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.3, 1.1, 0.3 }, { 0.7, 1.1, 0.3 }, { 1, 0 } }), Transparency = glintT,
			Rotation = n(0, 90), RotSpeed = n(-15, 15) }, WHITE_LE, WHITE_BR, "nearcam")
		pe(hosts.air, "glint5", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(5, 1.5), Lifetime = n(4, 6), Speed = n(0.2, 0.5),
			SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.3, 0.7, 0.2 }, { 0.7, 0.7, 0.2 }, { 1, 0 } }),
			Transparency = seq({ { 0, 1 }, { 0.3, 0.1 }, { 0.7, 0.1 }, { 1, 1 } }), Rotation = n(0, 90), RotSpeed = n(-20, 20) }, { 0.4, 1 }, WHITE_BR, "nearcam")
		em.bokeh = hi and pe(hosts.bokeh, "bokeh", 3.0, { Shape = BOX, ShapeStyle = VOLUME, Rate = 0.5, Lifetime = n(5, 7), Speed = n(0.1, 0.25),
			SpreadAngle = Vector2.new(180, 180), Size = n(1.2, 2.4), Transparency = seq({ { 0, 1 }, { 0.25, 0.72 }, { 0.75, 0.72 }, { 1, 1 } }),
			Color = ColorSequence.new(Color3.fromRGB(232, 236, 246)), Rotation = n(0, 360), RotSpeed = n(-4, 4) }, { 0.3, 0.8 }, { 1.2, 1.8 }, "bokeh")
		-- P15 (pass 5.1): the star halo: a tilted ring of stardust orbits the wearer between the rings and the orbs, born on
		-- the outer part of its disc (ShapePartial: the inner radius) and locked to it, so the stars orbit with the ring and
		-- never trail behind a walking wearer. Half the ring passes in front of the wearer, the dial and the orbs and half
		-- behind them: a layer of moving depth through the whole aura. Each star is a twinkle (the flipbook blooms, holds and
		-- shrinks it), so the ring glitters without any brightness pulse
		if hi then
			em.halo = pe(hosts.halo, "twinkle", 3.6, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.55, EmissionDirection = N_.Top,
				Rate = 26, Lifetime = n(6, 8), Speed = n(0.05, 0.2), SpreadAngle = Vector2.new(25, 25),
				Size = seq({ { 0, 0.62, 0.18 }, { 1, 0.62, 0.18 } }), Transparency = seq({ { 0, 1 }, { 0.1, 0.02 }, { 0.9, 0.02 }, { 1, 1 } }),
				LockedToPart = true, Rotation = n(0, 90), RotSpeed = n(-8, 8), ZOffset = 0.2 }, WHITE_LE, WHITE_BR, "nearcam")
		end
		-- P16 (pass 5.1): the duality helix: two points turn round the body at 150 degrees a second and leave a strand each,
		-- so a silver strand of light and an ink strand of smoke braid up round the wearer from the feet to above the head
		-- (not locked: each particle stays where it was born and climbs, which is what draws the spiral). While the wearer
		-- travels the strands thin out, so they don't hang far behind (see the travelling flip)
		em.strandMoon = pe(hosts.strandMoon, "twinkle", 5.2, { EmissionDirection = N_.Top, Rate = rate(30, 12), Lifetime = n(2.0, 2.3),
			Speed = n(2.6, 2.9), SpreadAngle = Vector2.new(4, 4), Drag = 0.3, Size = seq({ { 0, 0.6 }, { 0.6, 0.5 }, { 1, 0.15 } }),
			Transparency = seq({ { 0, 1 }, { 0.06, 0.02 }, { 0.75, 0.15 }, { 1, 1 } }), Rotation = n(0, 90), RotSpeed = n(-30, 30),
			ZOffset = 0.4 }, WHITE_LE, WHITE_BR, "nearcam")
		em.strandVoid = pe(hosts.strandVoid, "wisp", 5.2, { EmissionDirection = N_.Top, Rate = rate(18, 8), Lifetime = n(2.0, 2.3),
			Speed = n(2.6, 2.9), SpreadAngle = Vector2.new(4, 4), Drag = 0.3, Size = seq({ { 0, 0.8 }, { 0.5, 1.5 }, { 1, 0.7 } }),
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
