-- AuraRNG Studio install kit | 10_chunk_09_of_16.luau | step 10: piece 9 of 16
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (198845 bytes, checksum 17952987).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "10_chunk_09_of_16.luau"
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

local K = 9
-- piece 9 of 16 of the new source (13223 bytes, checksum 917082428, long bracket level 0)
local DATA = [[
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
		-- (pass 5.1: te5_billow is ray-marched smoke with its light baked in from the upper left and real self-shadowing: a
		-- dense puff that billows out in rolling lobes and thins into veils over its life. It starts small in its cell and is
		-- opaque until it thins itself, so it is born bigger and denser than the pass-4 puff, kept near upright (the baked
		-- light must stay above), and the ink is lifted a little so its billows read. Each smoke below takes the pass-4
		-- puff's own settings if its te5 texture is missing or fails to load in the game)
		local function propsFix(p, old, ln)
			fixUps[p] = function(o)
				for k, v in pairs(old) do o[k] = v end
				o.LightEmission, o.Brightness = ln[1], ln[3]
				for _, e in ipairs(emitNight) do
					if e[1] == o then e[2], e[3], e[4], e[5] = ln[1], ln[2], ln[3], ln[4] end
				end
			end
			return p
		end
		local bil = isTe5("billow")
		-- (pass 5.2: 8 a second, not 10: fewer, separate billows with gaps between them, and thin ink tendrils curling
		-- through the gaps, P30)
		em.smoke = pe(void, "billow", 1.0, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = rate(8, 4), Lifetime = n(3.5, 4.5),
			Speed = n(1.4, 2.4), Drag = 0.35, Acceleration = Vector3.new(0, 0.4, 0),
			Size = bil and seq({ { 0, 7 }, { 0.5, 11.5 }, { 1, 14 } }) or seq({ { 0, 5 }, { 1, 14 } }),
			Transparency = bil and seq({ { 0, 1 }, { 0.07, 0 }, { 0.8, 0.06 }, { 1, 1 } }) or seq({ { 0, 1 }, { 0.18, 0.08 }, { 0.7, 0.32 }, { 1, 1 } }),
			Color = ColorSequence.new(bil and Color3.fromRGB(24, 24, 30) or SMOKE), Rotation = bil and n(-20, 20) or n(0, 360),
			RotSpeed = bil and n(-6, 6) or n(-25, 25), ZOffset = -3 }, nil, bil and { 1, 2.2 } or nil)
		if bil then
			propsFix(em.smoke, { Size = seq({ { 0, 5 }, { 1, 14 } }), Transparency = seq({ { 0, 1 }, { 0.18, 0.08 }, { 0.7, 0.32 }, { 1, 1 } }),
				Color = ColorSequence.new(SMOKE), Rotation = n(0, 360), RotSpeed = n(-25, 25) }, { 0, 0, 1, 1 })
		end
		em.smokeMoon = hi and pe(moon, "billow", 1.6, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = 5, Lifetime = n(3.5, 4.5),
			Speed = n(0.9, 1.5), Drag = 0.35, Acceleration = Vector3.new(0, 0.3, 0),
			Size = bil and seq({ { 0, 5 }, { 0.5, 8 }, { 1, 10 } }) or seq({ { 0, 3.5 }, { 1, 9 } }),
			Transparency = bil and seq({ { 0, 1 }, { 0.08, 0.12 }, { 0.8, 0.25 }, { 1, 1 } }) or seq({ { 0, 1 }, { 0.2, 0.32 }, { 0.7, 0.55 }, { 1, 1 } }),
			Color = ColorSequence.new(Color3.fromRGB(176, 176, 178)), Rotation = bil and n(-20, 20) or n(0, 360),
			RotSpeed = bil and n(-5, 5) or n(-20, 20), ZOffset = -3 }, bil and { 0, 0.3 } or { 0.1, 0.4 }, bil and { 1, 1.4 } or nil)
		if bil and em.smokeMoon then
			propsFix(em.smokeMoon, { Size = seq({ { 0, 3.5 }, { 1, 9 } }), Transparency = seq({ { 0, 1 }, { 0.2, 0.32 }, { 0.7, 0.55 }, { 1, 1 } }),
				Rotation = n(0, 360), RotSpeed = n(-20, 20) }, { 0.1, 0.4, 1, 1 })
		end
		local glintT = seq({ { 0, 0.1 }, { 1, 0.1 } }) -- (a glint grows, holds and shrinks through its size: never a flash)
		-- (pass 5.1: a twinkle's flipbook blooms, holds and shrinks the star itself, so its size and transparency stay steady
		-- with just a soft start and end)
		local TWINKLE_T = seq({ { 0, 1 }, { 0.1, 0.05 }, { 0.9, 0.05 }, { 1, 1 } })
		if hi then
			-- P13: time-dust orbits the bezel: glints born just round its rim ride a ring that turns clockwise with the hands
			-- (locked to it), so the clock wears a slow halo of moving light. (Round the rim, not on it: under the silver
			-- tone a white glint on the bezel hardly reads by day; against the sky and the dark gears it does)
			-- (pass 5.2: a calmer 16 at rest; the reveal's aftermath lifts it for a while)
			em.timeDust = pe(hosts.timeDust, "twinkle", 4.4, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.9, EmissionDirection = N_.Back, Rate = 16,
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
		-- (pass 5.2: a quieter 14 at rest, more in the reveal's aftermath)
		em.air = pe(hosts.air, "twinkle", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(14, 5), Lifetime = n(2, 3), Speed = n(0.1, 0.3),
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
