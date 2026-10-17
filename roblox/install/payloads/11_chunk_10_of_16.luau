-- AuraRNG Studio install kit | 11_chunk_10_of_16.luau | step 11: piece 10 of 16
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (198845 bytes, checksum 17952987).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "11_chunk_10_of_16.luau"
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

local K = 10
-- piece 10 of 16 of the new source (13242 bytes, checksum 106838554, long bracket level 0)
local DATA = [[
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
		-- (pass 5.2) particles with jobs and timing. At rest: motes drift down the moon's link into the clock (P19), motes
		-- stream in along two spiral arms over the galaxy (P20), a slow glint gives the void's heart its glow and rays
		-- (P21), glints orbit the moon on a tilted ring (P22), matter spirals into the void from all round (P23), and a few
		-- big signature sparkles glint at XII and at the links' ports (P31). The reveal adds streaks converging on the clock
		-- in the buildup (P26) and, once, at midnight: the floor's wave (P24), glints bursting off the dial that slow into
		-- orbit round it (P25), sparks lifting off the floor (P27) and a ring off the moon (P28). The moon gets a broad soft
		-- glow (P29) and the void thin ink tendrils between its billows (P30).
		-- STUDIO-VERIFY: the wave lies flat on the floor (VelocityPerpendicular with its velocity straight up); the dial's
		-- glints burst out in the dial's plane (Cylinder + Outward on a carrier whose axis is the dial's); the spiral arms
		-- stand still on the floor while their motes stream in (attachments moved every frame on a turning host)
		em.wave = pe(hosts.wave, "shockwave", 0, { EmissionDirection = N_.Top, Rate = 0, Lifetime = n(1.7), Speed = n(0.05), LockedToPart = true,
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Size = seq({ { 0, 3 }, { 1, 65 } }), -- (its ring is 0.86 of its size: 56 studs at the end)
			Transparency = seq({ { 0, 1 }, { 0.05, 0.05 }, { 0.45, 0.3 }, { 1, 1 } }) }, { 0.4, 1 }, { 1.6, 2.6 }, "burst")
		if hi then
			if hosts.linkMoon then
				em.feed = pe(hosts.linkMoon, "mote", 4.8, { EmissionDirection = N_.Front, Rate = 5, Lifetime = n(2.2, 2.4), Speed = n(6), SpreadAngle = Vector2.new(5, 5),
					Size = seq({ { 0, 0 }, { 0.15, 0.55 * mS, 0.15 * mS }, { 0.85, 0.45 * mS }, { 1, 0 } }),
					Transparency = seq({ { 0, 1 }, { 0.12, 0.1 }, { 0.85, 0.2 }, { 1, 1 } }), LockedToPart = true, ZOffset = 0.3 }, WHITE_LE, WHITE_BR)
				sizeFix(em.feed, mS, { { 0, 0 }, { 0.15, 0.55, 0.15 }, { 0.85, 0.45 }, { 1, 0 } })
			end
			for _, a in ipairs({ hosts.spiralA, hosts.spiralB }) do
				sizeFix(pe(a, "mote", 4.8, { EmissionDirection = N_.Back, Rate = 9, Lifetime = n(4.2, 4.6), Speed = n(2.4, 2.6), SpreadAngle = Vector2.new(3, 3),
					Size = seq({ { 0, 0 }, { 0.12, 0.6 * mS, 0.12 * mS }, { 0.8, 0.45 * mS }, { 1, 0 } }),
					Transparency = seq({ { 0, 1 }, { 0.1, 0.1 }, { 0.85, 0.25 }, { 1, 1 } }), LockedToPart = true, ZOffset = 0.3 }, WHITE_LE, WHITE_BR),
					mS, { { 0, 0 }, { 0.12, 0.6, 0.12 }, { 0.8, 0.45 }, { 1, 0 } })
			end
			pe(new("Attachment", { Name = "Glint" }, hosts.heart), "glint5", 1.1, { Rate = 1, Lifetime = n(2.4), Size = n(3.0, 3.6),
				Transparency = seq({ { 0, 1 }, { 0.3, 0.12 }, { 0.7, 0.12 }, { 1, 1 } }), Rotation = n(-8, 8), RotSpeed = n(-3, 3), LockedToPart = true,
				ZOffset = 1.0 }, { 0.4, 1 }, { 2.2, 3.0 })
			pe(hosts.moonRing, "twinkle", 1.6, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.86, EmissionDirection = N_.Top, Rate = 6,
				Lifetime = n(3, 4), Size = seq({ { 0, 0.75, 0.2 }, { 1, 0.75, 0.2 } }), Transparency = TWINKLE_T, LockedToPart = true, Rotation = n(0, 90),
				ZOffset = 0.5 }, WHITE_LE, WHITE_BR)
			sizeFix(pe(hosts.infall, "mote", 1.4, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = INWARD, Rate = 12, Lifetime = n(1.4, 1.5),
				Speed = n(5.2, 5.8), Size = seq({ { 0, 0.5 * mS }, { 1, 0.2 * mS } }), Transparency = seq({ { 0, 1 }, { 0.2, 0.15 }, { 1, 0.4 } }),
				LockedToPart = true, ZOffset = 0.3 }, WHITE_LE, WHITE_BR), mS, { { 0, 0.5 }, { 1, 0.2 } })
			em.burst = pe(hosts.burst, "glint5", 0, { Shape = CYL, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, EmissionDirection = N_.Top, Rate = 0,
				Lifetime = n(4.5, 6), Speed = n(13, 19), Drag = 1.7, LockedToPart = true, Size = seq({ { 0, 0 }, { 0.04, 1.8, 0.35 }, { 0.75, 1.1, 0.2 }, { 1, 0 } }),
				Transparency = seq({ { 0, 0 }, { 0.75, 0.15 }, { 1, 1 } }), Rotation = n(0, 90), RotSpeed = n(-25, 25), ZOffset = 0.8 }, { 0.5, 1 }, WHITE_BR, "burst")
			-- (the stroke itself: one star flares at the hub and shrinks away in about half a second, the only flash there is)
			em.flare = pe(new("Attachment", { Name = "Flare", Position = Vector3.new(0, 0, 2.2) }, hosts.ports), "glint5", 0, { Rate = 0,
				Lifetime = n(0.7), Size = seq({ { 0, 3 }, { 0.12, 16 }, { 0.45, 9 }, { 1, 0 } }), Transparency = seq({ { 0, 0 }, { 0.6, 0.2 }, { 1, 1 } }),
				Rotation = n(0), RotSpeed = n(20), LockedToPart = true, ZOffset = 1.5 }, { 0.8, 1 }, { 3.0, 3.5 }, "burst")
			em.converge = sizeFix(pe(hosts.converge, "streak5", 0, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = INWARD, Rate = 10,
				Lifetime = n(1.6, 1.8), Speed = n(7.5, 8.2), Size = seq({ { 0, 0.5 * stS }, { 1, 0.12 * stS } }),
				Transparency = seq({ { 0, 1 }, { 0.2, 0.1 }, { 0.9, 0.3 }, { 1, 1 } }), Orientation = VPAR, Rotation = stRot, LockedToPart = true, ZOffset = 0.5 },
				WHITE_LE, WHITE_BR, "converge"), stS, { { 0, 0.5 }, { 1, 0.12 } })
			-- (the wave's front, as streaks racing out along the floor with it at its own 16 studs a second: the ring lies flat,
			-- so from a low camera this is what reads)
			em.waveFront = sizeFix(pe(hosts.wave, "streak5", 0, { Shape = CYL, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, EmissionDirection = N_.Top,
				Rate = 0, Lifetime = n(1.5, 1.6), Speed = n(15.5, 16.5), LockedToPart = true, Size = seq({ { 0, 0.7 * stS }, { 1, 0.3 * stS } }),
				Transparency = seq({ { 0, 0 }, { 0.7, 0.25 }, { 1, 1 } }), Orientation = VPAR, Rotation = stRot }, WHITE_LE, WHITE_BR, "burst"),
				stS, { { 0, 0.7 }, { 1, 0.3 } })
			em.lift = pe(hosts.floorFx, "glint5", 0, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.2, EmissionDirection = N_.Top, Rate = 0,
				Lifetime = n(3, 4.5), Speed = n(5, 9), Drag = 1.5, LockedToPart = true, Size = seq({ { 0, 0 }, { 0.06, 0.9, 0.25 }, { 0.8, 0.65 }, { 1, 0 } }),
				Transparency = seq({ { 0, 0 }, { 0.8, 0.15 }, { 1, 1 } }), Rotation = n(0, 90), RotSpeed = n(-20, 20), ZOffset = 0.3 }, WHITE_LE, WHITE_BR, "burst")
			local mc = new("Attachment", { Name = "Centre" }, moon)
			em.moonPulse = pe(mc, "shockwave", 0, { Rate = 0, Lifetime = n(1.0), Size = seq({ { 0, 9 }, { 1, 26 } }),
				Transparency = seq({ { 0, 0.2 }, { 0.35, 0.45 }, { 1, 1 } }), LockedToPart = true, ZOffset = -1 }, { 0.5, 1 }, { 1.8, 2.8 }, "burst")
			pe(mc, "softGlow", 0.9, { Rate = 1, Lifetime = n(3), Size = n(18), Transparency = seq({ { 0, 1 }, { 0.33, 0.84 }, { 0.67, 0.84 }, { 1, 1 } }),
				Color = ColorSequence.new(Color3.fromRGB(232, 236, 246)), LockedToPart = true, ZOffset = -2.5 }, { 0, 0.6 }, { 1, 1.5 })
			pe(void, "wisp", 1.2, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = 5, Lifetime = n(2.6, 3.4), Speed = n(1.6, 2.6),
				Drag = 0.25, Acceleration = Vector3.new(0, 0.3, 0), Size = seq({ { 0, 2.4 }, { 0.5, 4.6 }, { 1, 5.4 } }),
				Transparency = seq({ { 0, 1 }, { 0.12, 0.15 }, { 0.7, 0.45 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(28, 28, 32)),
				Rotation = n(0, 360), RotSpeed = n(-30, 30), ZOffset = -2.5 })
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
