-- AuraRNG Studio install kit | 07_chunk_06_of_10.luau | step 7: piece 6 of 10
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (123861 bytes, checksum 523677650).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "07_chunk_06_of_10.luau"
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

local K = 6
-- piece 6 of 10 of the new source (13333 bytes, checksum 204697128, long bracket level 0)
local DATA = [[
		-- down onto the dais (all four are built source -> destination, so they share one sign; if they run backwards:
		-- attribute FLOW_SIGN = -1)
		local trCore = { { 0, 0.15 }, { 0.12, 0.05 }, { 0.88, 0.05 }, { 1, 0.30 } }
		sb = {
			beam("MoonCore", hosts.moonOut, moonA0, "stream", WRAP, 5, 0.8, 1.4, 0.30, 4.0, 0, WHITE, 0, 0.45, 1.6, 2.4, trCore),
			hi and beam("MoonFlow", hosts.moonOut, moonA0, "streak", WRAP, 7, 1.6, 0.5, 0.15, 4.3, 0, WHITE, 0.3, 0.9, 2.0, 2.6,
				{ { 0, 0.4 }, { 0.15, 0.2 }, { 0.85, 0.2 }, { 1, 0.6 } }, true),
			beam("VoidCore", hosts.voidOut, voidA0, "stream", WRAP, 5, 0.7, 1.6, 0.35, 3.0, 0, Color3.fromRGB(18, 18, 24), 0, 0, 1.0, 1.0, trCore),
			hi and beam("VoidCrackle", hosts.voidOut, voidA0, "line", STRETCH, 1, 0, 0.14, 0.10, 2.6, 0, WHITE, 0.2, 0.8, 1.8, 2.4,
				{ { 0, 0.3 }, { 0.1, 0.1 }, { 0.9, 0.1 }, { 1, 0.5 } }, true),
		}
		if hi then
			-- the ink ribbon: a whip-thin strand that curls out of the void and down into the pool (solid in its body, soft
			-- at the void end). (The te5 ribbon carries its own ink body and white hairlines, so it needs a white Beam
			-- Color; the fallback line is inked.)
			local te5r = isTe5("ribbon")
			local rb = beam("Ribbon", hosts.ribbonOut, hosts.ribbonIn, "ribbon", WRAP, 8, 0.5, 0.45, 1.3, 7.0, -8.0, te5r and WHITE or RIBBON_INK,
				0, 0, 1.0, 1.0, { { 0, 0.55 }, { 0.15, 0.15 }, { 0.85, 0.05 }, { 1, 0.35 } })
			if te5r then fixUps[rb] = function() rb.Color = ColorSequence.new(RIBBON_INK) end end
			beam("RibbonEdge", hosts.ribbonOut, hosts.ribbonIn, "line", STRETCH, 1, 0, 0.10, 0.10, 7.3, -8.3, WHITE, 0.2, 0.8, 1.8, 2.4,
				{ { 0, 0.3 }, { 0.1, 0.1 }, { 0.9, 0.1 }, { 1, 0.4 } }, true)
		end
		if hosts.beacon0 then
			-- (FAR_BEACON) a steady column seen only from far away: solid ink on the day sky, white at night, soft at the top.
			-- No texture (a solid band reads at 300 studs; a textured line thinned to a hairline). No pulse.
			hosts.beaconBeam = beam("Spire", hosts.beacon0, hosts.beacon1, nil, STRETCH, 1, 0, 8, 3, 0, 0, INK, 0, 1, 1, 2,
				{ { 0, 0.1 }, { 0.6, 0.15 }, { 1, 1 } }, false, true)
		end
		-- (entry [10]: one of the four palm streams, switched off in first person; [11]: the Enabled last written)
		for _, b in ipairs(beams) do
			b[10] = b[1] == sb[1] or b[1] == sb[2] or b[1] == sb[3] or b[1] == sb[4]
			b[11] = b[1].Enabled
		end
	end

	---------------------------------------------------------------- THE PARTICLES: every system has a job and a path
	local emitters = {} -- { emitter, on time, kind, live, written Enabled }
	local emitNight = {} -- { emitter, LE day, LE night, Br day, Br night }
	local em = {} -- the emitters that change after the build: bokeh (rate by night), smoke (thins out while moving)
	do
		local function pe(parent, key, tOn, props, le, br, kind)
			local p = Instance.new("ParticleEmitter")
			applyTex(p, key)
			p.LightInfluence = 0
			p.VelocityInheritance = 0
			p.Color = ColorSequence.new(WHITE)
			p.Speed = n(0)
			p.Rotation = n(0)
			p.RotSpeed = n(0)
			p.Enabled = false
			local sz = props.Size
			if typeof(sz) == "NumberRange" then -- (a size range: a steady size with a random spread)
				local v, e = (sz.Min + sz.Max) / 2, (sz.Max - sz.Min) / 2
				props.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, v, e), NumberSequenceKeypoint.new(1, v, e) })
			end
			for k, v in pairs(props) do p[k] = v end
			p.LightEmission = le and le[1] or 0
			p.Brightness = br and br[1] or 1
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
			if scale ~= 1 then fixUps[p] = function() p.Size = seq(pts) end end
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
		-- P2: dust snows off the moon and falls away below it
		pe(moon, "mote", 1.6, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = rate(16, 5), Lifetime = n(3.0, 4.5),
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
		-- Thinner while the wearer travels, so no trail of puffs hangs on the path.
		local smS = isTe5("smoke5") and 1.3 or 1 -- (te5_smoke's curls are wispier than the pass-4 puff, so they are drawn bigger)
		em.smoke = sizeFix(pe(void, "smoke5", 1.0, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = rate(10, 4), Lifetime = n(3.5, 4.5),
			Speed = n(1.4, 2.4), Drag = 0.35, Acceleration = Vector3.new(0, 0.4, 0), Size = seq({ { 0, 5 * smS }, { 1, 14 * smS } }),
			Transparency = seq({ { 0, 1 }, { 0.2, 0.16 }, { 0.7, 0.45 }, { 1, 1 } }), Color = ColorSequence.new(SMOKE), Rotation = n(0, 360),
			RotSpeed = n(-25, 25), ZOffset = -3 }), smS, { { 0, 5 }, { 1, 14 } })
		em.smokeMoon = hi and sizeFix(pe(moon, "smoke5", 1.6, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = 5, Lifetime = n(3.5, 4.5),
			Speed = n(0.9, 1.5), Drag = 0.35, Acceleration = Vector3.new(0, 0.3, 0), Size = seq({ { 0, 3.5 * smS }, { 1, 9 * smS } }),
			Transparency = seq({ { 0, 1 }, { 0.2, 0.32 }, { 0.7, 0.55 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(176, 176, 178)),
			Rotation = n(0, 360), RotSpeed = n(-20, 20), ZOffset = -3 }, { 0.1, 0.4 }), smS, { { 0, 3.5 }, { 1, 9 } })
		-- P5: slow four-point glints bloom on the bezel metal and fade (grow, hold, shrink: never a flash).
		-- STUDIO-VERIFY: Disc ShapePartial = the inner-radius fraction (0.86 -> the annulus over the bezel), oriented by EmissionDirection
		local glintT = seq({ { 0, 0.1 }, { 1, 0.1 } })
		pe(hosts.rimGlint, "glint5", 3.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.86, EmissionDirection = N_.Back, Rate = rate(9, 3),
			Lifetime = n(1.6, 2.2), Size = seq({ { 0, 0 }, { 0.35, 1.9, 0.5 }, { 0.65, 1.9, 0.5 }, { 1, 0 } }), Transparency = glintT,
			LockedToPart = true, ZOffset = 1.0, Rotation = n(0, 90) }, { 0.5, 1 }, WHITE_BR)
		if hi then
			-- P13: time-dust orbits the bezel: glints born on the rim ride a ring that turns clockwise with the hands (locked
			-- to it), so the clock wears a slow halo of moving light
			pe(hosts.timeDust, "glint5", 4.4, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.88, EmissionDirection = N_.Back, Rate = 14,
				Lifetime = n(4, 5), Size = seq({ { 0, 0 }, { 0.3, 1.4, 0.3 }, { 0.7, 1.4, 0.3 }, { 1, 0 } }), Transparency = glintT,
				LockedToPart = true, ZOffset = 1.0, Rotation = n(0, 90), RotSpeed = n(-15, 15) }, { 0.5, 1 }, WHITE_BR)
			-- the event horizon's glow (above): three soft rings alive at once, Rate 1 x 3 s
			pe(hosts.horizon, "halo", 1.0, { Rate = 1, Lifetime = n(3, 3), Size = n(11.2, 11.2), LockedToPart = true,
				Transparency = seq({ { 0, 1 }, { 0.2, 0.12 }, { 0.8, 0.12 }, { 1, 1 } }), Rotation = n(0, 360), RotSpeed = n(-8, 8), ZOffset = 0.4 },
				{ 0.4, 1 }, { 1.6, 3.0 })
		end
		-- P6: three scales of air: silver dust (fewer, bigger: the old 1-4 px specks never read), mid glints, and big slow
		-- bokeh between the camera and the wearer (showcase framings only)
		pe(hosts.air, "mote", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(8, 4), Lifetime = n(6, 9), Speed = n(0.1, 0.3),
			SpreadAngle = Vector2.new(180, 180), Size = n(0.22, 0.40), Transparency = seq({ { 0, 1 }, { 0.2, 0.1 }, { 0.8, 0.15 }, { 1, 1 } }),
			Color = ColorSequence.new(Color3.fromRGB(226, 230, 240)) }, { 0.2, 0.8 }, { 1.4, 2.2 })
		pe(hosts.air, "glint5", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(5, 1.5), Lifetime = n(4, 6), Speed = n(0.2, 0.5),
			SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.3, 0.7, 0.2 }, { 0.7, 0.7, 0.2 }, { 1, 0 } }),
			Transparency = seq({ { 0, 1 }, { 0.3, 0.1 }, { 0.7, 0.1 }, { 1, 1 } }), Rotation = n(0, 90), RotSpeed = n(-20, 20) }, { 0.4, 1 }, WHITE_BR)
		em.bokeh = hi and pe(hosts.bokeh, "bokeh", 3.0, { Shape = BOX, ShapeStyle = VOLUME, Rate = 0.5, Lifetime = n(5, 7), Speed = n(0.1, 0.25),
			SpreadAngle = Vector2.new(180, 180), Size = n(1.2, 2.4), Transparency = seq({ { 0, 1 }, { 0.25, 0.72 }, { 0.75, 0.72 }, { 1, 1 } }),
			Color = ColorSequence.new(Color3.fromRGB(232, 236, 246)), Rotation = n(0, 360), RotSpeed = n(-4, 4) }, { 0.3, 0.8 }, { 1.2, 1.8 }, "bokeh")
		if hi then
			-- P7: one low mist bank at the ankles, only while standing on the ground
			pe(hosts.floor, "smoke5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, EmissionDirection = N_.Top, Rate = 2.5, Lifetime = n(6, 8),
				Speed = n(0.1, 0.25), Size = seq({ { 0, 8 }, { 1, 14 } }), Transparency = seq({ { 0, 1 }, { 0.3, 0.80 }, { 0.7, 0.82 }, { 1, 1 } }),
				Color = ColorSequence.new(MIST), LockedToPart = true, Rotation = n(0, 360), RotSpeed = n(-6, 6) }, nil, nil, "ground")
		end
		-- P8: motes rise off the turning arms and swirl with them; black ash flakes rise against them
		pe(hosts.floor, "mote", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top, Rate = rate(18, 8),
			Lifetime = n(2.6, 3.6), Speed = n(0.5, 1.2), Acceleration = Vector3.new(0, 0.35, 0), Drag = 0.2,
			Size = seq({ { 0, 0 }, { 0.2, 1.2, 0.3 }, { 1, 0 } }), Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.8, 0.15 }, { 1, 1 } }),
			LockedToPart = true, ZOffset = 0.2 }, WHITE_LE, WHITE_BR)
		if hi then
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "12_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
