-- AuraRNG Studio install kit | 09_chunk_08_of_16.luau | step 9: piece 8 of 16
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (198845 bytes, checksum 17952987).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "09_chunk_08_of_16.luau"
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

local K = 8
-- piece 8 of 16 of the new source (13150 bytes, checksum 162546552, long bracket level 0)
local DATA = [[
	---------------------------------------------------------------- THE STREAMS (beams)
	-- { beam, faded transparency steps, written step, LE day, night, Br day, night, near only, far only }
	local beams = {}
	local sb -- the four stream beams (their palm end moves when the wearer turns): { MoonCore, MoonFlow, VoidCore, VoidCrackle }
	do
		local function beam(name, a0, a1, key, mode, len, speed, w0, w1, c0, c1, color, le0, le1, br0, br1, tr, nearOnly, farOnly)
			local b = new("Beam", { Name = name, Attachment0 = a0, Attachment1 = a1, TextureMode = mode, TextureLength = len,
				TextureSpeed = speed * CONFIG.FLOW_SIGN, Width0 = w0, Width1 = w1, CurveSize0 = c0, CurveSize1 = c1, Color = ColorSequence.new(color),
				LightEmission = le0, LightInfluence = 0, Brightness = br0, FaceCamera = true, Segments = 20, ZOffset = 0,
				Transparency = NumberSequence.new(1), Enabled = not farOnly }, holder("Fx", CORE))
			if key then applyTex(b, key) end
			-- (the fade steps are made here, once: update only picks one; 21 steps, so a fade never jumps more than 5 %)
			local steps = {}
			for q = 0, 20 do
				local pts = {}
				for _, p in ipairs(tr) do table.insert(pts, { p[1], 1 - (1 - p[2]) * q / 20 }) end
				steps[q] = seq(pts)
			end
			table.insert(beams, { b, steps, 0, le0, le1, br0, br1, nearOnly, farOnly })
			return b
		end
		local WRAP, STRETCH = Enum.TextureMode.Wrap, Enum.TextureMode.Stretch
		local moonA0, voidA0 = palmFor(-assign, moonCarA), palmFor(assign, voidCarA)
		-- STUDIO-VERIFY: Beam TextureSpeed direction: the streams must flow from the orb INTO the palm (all four are built
		-- source -> destination, so they share one sign; if they run backwards: attribute FLOW_SIGN = -1). The lensed band
		-- shares the sign: it drifts slowly left to right over the top (either way reads)
		local trCore = { { 0, 0.15 }, { 0.12, 0.05 }, { 0.88, 0.05 }, { 1, 0.30 } }
		sb = {
			beam("MoonCore", hosts.moonOut, moonA0, "stream", WRAP, 5, 0.8, 1.4, 0.30, 4.0, 0, WHITE, 0, 0.45, 1.6, 2.4, trCore),
			hi and beam("MoonFlow", hosts.moonOut, moonA0, "streak", WRAP, 7, 1.6, 0.5, 0.15, 4.3, 0, WHITE, 0.3, 0.9, 2.0, 2.6,
				{ { 0, 0.4 }, { 0.15, 0.2 }, { 0.85, 0.2 }, { 1, 0.6 } }, true),
			beam("VoidCore", hosts.voidOut, voidA0, "stream", WRAP, 5, 0.7, 1.6, 0.35, 3.0, 0, Color3.fromRGB(18, 18, 24), 0, 0, 1.0, 1.0, trCore),
			hi and beam("VoidCrackle", hosts.voidOut, voidA0, "line", STRETCH, 1, 0, 0.14, 0.10, 2.6, 0, WHITE, 0.2, 0.8, 1.8, 2.4,
				{ { 0, 0.3 }, { 0.1, 0.1 }, { 0.9, 0.1 }, { 1, 0.5 } }, true),
		}
		if hosts.horizon then
			-- the lensed disc (the black hole's signature): the far side of the accretion disc, bent by the void's gravity, a
			-- bright band arching over the top of the shadow and a thinner one under it. Both hang on the camera-facing
			-- horizon carrier, so they hug the silhouette from every side; slimmer when the camera is close
			local function lens(name, sg, w, br)
				local a0 = new("Attachment", { Name = name .. "0", CFrame = CFrame.fromMatrix(Vector3.new(-4.45, 0, 0), Vector3.new(0, sg, 0), Vector3.new(-sg, 0, 0)) }, hosts.horizon)
				local a1 = new("Attachment", { Name = name .. "1", CFrame = CFrame.fromMatrix(Vector3.new(4.45, 0, 0), Vector3.new(0, -sg, 0), Vector3.new(sg, 0, 0)) }, hosts.horizon)
				return beam(name, a0, a1, "stream", WRAP, 6, 0.4, w, w, 6.0, 6.0, WHITE, 0.2, 0.8, br, br + 1.0,
					{ { 0, 1 }, { 0.15, 0.05 }, { 0.85, 0.05 }, { 1, 1 } })
			end
			hosts.lensTop = lens("LensTop", 1, 1.5, 2.0)
			hosts.lensBot = lens("LensBottom", -1, 0.8, 1.8)
		end
		if hosts.beacon0 then
			-- (FAR_BEACON) a steady column seen only from far away: solid ink on the day sky, white at night, soft at the top.
			-- No texture (a solid band reads at 300 studs; a textured line thinned to a hairline). No pulse.
			hosts.beaconBeam = beam("Spire", hosts.beacon0, hosts.beacon1, nil, STRETCH, 1, 0, 8, 3, 0, 0, INK, 0, 1, 1, 2,
				{ { 0, 0.1 }, { 0.6, 0.15 }, { 1, 1 } }, false, true)
		end
		-- (pass 5.2) the energy links: three thin tapered threads of light, each with pearls of light gliding along it
		-- (te5_link; the pass-2 streak until it is uploaded): the moon's light into the clock at IX, out of the clock at III
		-- into the void (white going to ink as the void swallows it), and from VI down to the floor's vortex. Faint and
		-- thin at rest; in the reveal each lights up along its length, from its source, one after another, and they surge
		-- at midnight. They bow a little (their ends leave and arrive along the ports' axes; update keeps the bow in
		-- proportion to their length) and are off in first person and far away
		local links = {}
		if hosts.linkMoon then
			local function growSteps(tr)
				local function at(x) -- (the profile's transparency at x)
					for j = 2, #tr do
						if x <= tr[j][1] then
							local p, q = tr[j - 1], tr[j]
							return p[2] + (q[2] - p[2]) * (x - p[1]) / (q[1] - p[1])
						end
					end
					return tr[#tr][2]
				end
				local steps = { [0] = seq({ { 0, 1 }, { 1, 1 } }) }
				for q = 1, 20 do
					local f = q / 20 * 1.1 -- (the front: shown up to f, soft over the last tenth; past 1 at q = 20)
					local pts = { { 0, at(0) } }
					for j = 2, #tr - 1 do
						if tr[j][1] < f - 0.1 then table.insert(pts, tr[j]) end
					end
					if f - 0.1 > 0 and f - 0.1 < 1 then table.insert(pts, { f - 0.1, at(f - 0.1) }) end
					if f < 1 then table.insert(pts, { f, 1 }) end
					table.insert(pts, { 1, f < 1 and 1 or at(1) })
					steps[q] = seq(pts)
				end
				return steps
			end
			local trLink = { { 0, 1 }, { 0.08, 0.3 }, { 0.92, 0.3 }, { 1, 1 } }
			local function link(name, a0, a1, w0, w1, color, t0)
				local b = beam(name, a0, a1, "link", WRAP, 7, 0.5, w0, w1, 3, 3, WHITE, 0.2, 0.9, 1.6, 2.4, trLink, true)
				b.Segments = 24
				if color then b.Color = color end
				local e = beams[#beams]
				e[2] = growSteps(trLink)
				table.insert(links, { e, t0 })
				return b
			end
			hosts.moonLink = link("LinkMoon", hosts.linkMoonA, hosts.portIX, 0.9, 0.3, nil, REV_BUILD)
			hosts.voidLink = link("LinkVoid", hosts.portIII, hosts.linkVoidA, 0.7, 0.3, ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE),
				ColorSequenceKeypoint.new(0.55, Color3.fromRGB(150, 150, 158)), ColorSequenceKeypoint.new(1, INK) }), REV_BUILD + 0.6)
			if hosts.linkFloor then hosts.floorLink = link("LinkFloor", hosts.portVI, hosts.linkFloorA, 0.7, 0.3, nil, REV_BUILD + 1.0) end
		end
		-- (entry [10]: one of the four palm streams, switched off in first person; [11]: the Enabled last written; [12]: when
		-- it fades in on equip: the lens with the void's heart, the streams once the dais is down; [13]: the reveal's
		-- brightness boost, 0 at rest)
		for _, b in ipairs(beams) do
			b[10] = b[1] == sb[1] or b[1] == sb[2] or b[1] == sb[3] or b[1] == sb[4]
			b[11] = b[1].Enabled
			b[12] = (b[1] == hosts.lensTop or b[1] == hosts.lensBot) and 0.9 or 4.6
			b[13] = 0
		end
		for _, l in ipairs(links) do l[1][10], l[1][12] = true, l[2] end
		hosts.links = links
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
