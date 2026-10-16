-- AuraRNG Studio install kit | 08_chunk_07_of_12.luau | step 8: piece 7 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (151582 bytes, checksum 322184148).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "08_chunk_07_of_12.luau"
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

local K = 7
-- piece 7 of 12 of the new source (13230 bytes, checksum 300795074, long bracket level 0)
local DATA = [[
			if le or br then table.insert(emitNight, { p, le and le[1] or 0, le and le[2] or 0, br and br[1] or 1, br and br[2] or 1 }) end
			p.Parent = parent
			table.insert(emitters, { p, tOn, kind, false, false })
			return p
		end
		local function rate(h, l) return low and l or h end
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
		-- (pass 5.1: te5_mote is a soft point of light whose bright core is smaller than the old disc: drawn 1.2x)
		local mS = isTe5("mote") and 1.2 or 1
		local p1 = { Rate = rate(28, 12), Lifetime = n(1.1, 1.3), Speed = n(2.2, 2.6), Size = seq({ { 0, 1.5 * mS }, { 1, 0.35 * mS } }),
			Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.8, 0.05 }, { 1, 0.4 } }),
			Color = ColorSequence.new(WHITE, Color3.fromRGB(170, 174, 184)), LockedToPart = true, ZOffset = 0.3 }
		if CONFIG.SWIRL_POINTS then
			p1.EmissionDirection, p1.SpreadAngle = N_.Front, Vector2.new(0, 10)
			sizeFix(pe(rimPoint(hosts.swirl, 6.3), "mote", 1.2, p1, WHITE_LE, WHITE_BR), mS, { { 0, 1.5 }, { 1, 0.35 } })
		else
			p1.Shape, p1.ShapeStyle, p1.ShapeInOut, p1.EmissionDirection = CYL, SURFACE, INWARD, N_.Top
			sizeFix(pe(hosts.swirl, "mote", 1.2, p1, WHITE_LE, WHITE_BR), mS, { { 0, 1.5 }, { 1, 0.35 } })
		end
		-- P2: dust snows off the moon and falls away below it (halved while the wearer travels)
		em.dust = pe(moon, "mote", 1.6, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = rate(10, 5), Lifetime = n(3.0, 4.5),
			Speed = n(0.25, 0.6), Acceleration = Vector3.new(0, -1.1, 0), Drag = 0.4,
			Size = seq({ { 0, 0.18 * mS }, { 0.2, 0.6 * mS, 0.15 * mS }, { 1, 0.18 * mS } }),
			Transparency = seq({ { 0, 1 }, { 0.12, 0.08 }, { 0.75, 0.15 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(238, 240, 246)),
			Rotation = n(0, 360), RotSpeed = n(-30, 30) }, { 0.2, 0.7 }, { 1.4, 2.2 })
		sizeFix(em.dust, mS, { { 0, 0.18 }, { 0.2, 0.6, 0.15 }, { 1, 0.18 } })
		if hi then
			-- P3: metal shards break off the bezel at eleven and fly across the face into the void (tumbling flipbook: te5_shards
			-- is a ray-traced blade of polished steel whose highlights glide across it as it turns)
			local shardScale = isTe5("shards5") and 1.6 or 1 -- (the te5 blade spans about a third of its cell and turns edge-on)
			sizeFix(pe(hosts.shardFeed, "shards5", 4.8, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Front, Rate = 7, Lifetime = n(2.9, 3.2),
				Speed = n(8.5, 9.5), SpreadAngle = Vector2.new(6, 6),
				Size = seq({ { 0, 0.6 * shardScale }, { 0.85, 0.9 * shardScale, 0.12 * shardScale }, { 1, 0.35 * shardScale } }),
				Transparency = seq({ { 0, 1 }, { 0.06, 0 }, { 0.9, 0 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(214, 218, 226)),
				Rotation = n(0, 360), RotSpeed = n(-120, 120), FlipbookFramerate = n(10, 14), FlipbookStartRandom = true }, { 0, 0.3 }, { 1, 1.6 }),
				shardScale, { { 0, 0.6 }, { 0.85, 0.9, 0.12 }, { 1, 0.35 } })
			-- P18 (pass 5.1): where the shards break off, hot flecks spray out of the break and fall away (short-lived, each a
			-- fleck with a hairline tail that points the way it flies)
			pe(hosts.shardFeed, "spark5", 4.8, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Front, Rate = 10, Lifetime = n(0.35, 0.6),
				Speed = n(6, 10), SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, -12, 0), Drag = 1.5,
				Size = seq({ { 0, 0.6 }, { 1, 0.25 } }), Transparency = seq({ { 0, 0 }, { 0.7, 0.1 }, { 1, 1 } }), Orientation = VPAR,
				Rotation = stRot }, { 0.5, 1 }, WHITE_BR)
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
		-- (pass 5.1: a twinkle's flipbook blooms, holds and shrinks the star itself, so its size and transparency stay steady
		-- with just a soft start and end)
		local TWINKLE_T = seq({ { 0, 1 }, { 0.1, 0.05 }, { 0.9, 0.05 }, { 1, 1 } })
		if hi then
			-- P13: time-dust orbits the bezel: glints born just round its rim ride a ring that turns clockwise with the hands
			-- (locked to it), so the clock wears a slow halo of moving light. (Round the rim, not on it: under the silver
			-- tone a white glint on the bezel hardly reads by day; against the sky and the dark gears it does)
			pe(hosts.timeDust, "twinkle", 4.4, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.9, EmissionDirection = N_.Back, Rate = 20,
				Lifetime = n(3, 4), Size = seq({ { 0, 1.6, 0.35 }, { 1, 1.6, 0.35 } }), Transparency = TWINKLE_T,
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
		pe(hosts.air, "twinkle", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(18, 5), Lifetime = n(2, 3), Speed = n(0.1, 0.3),
			SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 1.2, 0.3 }, { 1, 1.2, 0.3 } }), Transparency = TWINKLE_T,
			Rotation = n(0, 90), RotSpeed = n(-15, 15) }, WHITE_LE, WHITE_BR, "nearcam")
		-- (pass 5.1: the finer scale is stardust: clusters of glitter whose grains swell and fade each on their own beat)
		pe(hosts.air, "stardust", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(4, 1.5), Lifetime = n(4, 6), Speed = n(0.1, 0.3),
			SpreadAngle = Vector2.new(180, 180), Size = n(1.8, 2.6), Transparency = seq({ { 0, 1 }, { 0.25, 0.3 }, { 0.75, 0.3 }, { 1, 1 } }),
			Rotation = n(0, 360), RotSpeed = n(-10, 10), FlipbookFramerate = n(6, 9), FlipbookStartRandom = true }, { 0.4, 0.9 }, { 2.0, 2.6 },
			"nearcam")
		em.bokeh = hi and pe(hosts.bokeh, "bokeh", 3.0, { Shape = BOX, ShapeStyle = VOLUME, Rate = 0.5, Lifetime = n(5, 7), Speed = n(0.1, 0.25),
			SpreadAngle = Vector2.new(180, 180), Size = n(1.2, 2.4), Transparency = seq({ { 0, 1 }, { 0.25, 0.72 }, { 0.75, 0.72 }, { 1, 1 } }),
			Color = ColorSequence.new(Color3.fromRGB(232, 236, 246)), Rotation = n(0, 360), RotSpeed = n(-4, 4) }, { 0.3, 0.8 }, { 1.2, 1.8 }, "bokeh")
		-- P15 (pass 5.1): the star halo: a tilted ring of stardust orbits the whole aura 16 to 21 studs out, born on the
		-- outer part of its disc (ShapePartial: the inner radius) and locked to it, so the stars orbit with the ring and never
		-- trail behind a walking wearer. Half the ring passes in front of the aura and half behind the clock: a planet's ring
		-- of moving light round everything. Each star is a twinkle (the flipbook blooms, holds and shrinks it), so the ring
		-- glitters without any brightness pulse
		if hi then
			em.halo = pe(hosts.halo, "twinkle", 3.6, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.76, EmissionDirection = N_.Top,
				Rate = 30, Lifetime = n(3.5, 4.5), Speed = n(0.05, 0.2), SpreadAngle = Vector2.new(25, 25),
				Size = seq({ { 0, 1.7, 0.4 }, { 1, 1.7, 0.4 } }), Transparency = seq({ { 0, 1 }, { 0.1, 0.02 }, { 0.9, 0.02 }, { 1, 1 } }),
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
			Speed = n(2.6, 2.9), SpreadAngle = Vector2.new(4, 4), Drag = 0.3, Size = seq({ { 0, 1.0 }, { 0.5, 1.7 }, { 1, 0.8 } }),
			Transparency = seq({ { 0, 1 }, { 0.1, 0.1 }, { 0.7, 0.35 }, { 1, 1 } }), Color = ColorSequence.new(INK), Rotation = n(0, 360),
			RotSpeed = n(-40, 40), ZOffset = 0.3 }, nil, nil, "nearcam")
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
