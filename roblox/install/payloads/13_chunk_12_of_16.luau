-- AuraRNG Studio install kit | 13_chunk_12_of_16.luau | step 13: piece 12 of 16
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (198845 bytes, checksum 17952987).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "13_chunk_12_of_16.luau"
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

local K = 12
-- piece 12 of 16 of the new source (13228 bytes, checksum 934107283, long bracket level 0)
local DATA = [[
				PP[i].Transparency = tr
				PCUR[i] = tr
			end
		end
		for _, e in ipairs(images) do
			local f = a
			if asm then f *= smooth((age - e[3]) / (e[4] - e[3])) end
			local tr = 1 - (1 - e[2]) * f
			if tr ~= e[5] and (abs(tr - e[5]) >= thr or f <= 0 or f >= 1) then
				e[1].ImageTransparency = tr
				e[5] = tr
			end
		end
		beamSteps(a)
		local kf, wf = a, a
		if asm then kf, wf = a * smooth((age - 0.6) / 1.0), a * smooth((age - 4.6) / 1.0) end
		if abs(kf - st.kf) >= thr or abs(wf - st.wf) >= thr or ((kf <= 0 or kf >= 1) and kf ~= st.kf) or ((wf <= 0 or wf >= 1) and wf ~= st.wf) then
			st.kf, st.wf = kf, wf
			lightLevels()
		end
		-- (the silver tone comes in only once every silver part is solid: a Highlight paints a part that is still fading
		-- in at full strength, which would make the rising dais rim pop)
		st.hlA = asm and a * smooth((age - 5.65) / 0.7) or a
		toneLevels(thr)
	end
	-- another wearer's aura between you and your camera: its clock and orbs fade to a ghost in 3 steps (one burst of
	-- LocalTransparencyModifier writes per step, none while it holds) with their smoke, glints and streams, and its GUIs
	-- and silver tone switch off meanwhile
	local function setGhost(q)
		st.ghostQ = q
		local m = 0.75 * q
		for _, p in ipairs(ghostParts) do p.LocalTransparencyModifier = m end
		if st.fxLtm then
			for _, e in ipairs(emitters) do
				if e[6] then e[1].LocalTransparencyModifier = m end
			end
			for _, b in ipairs(beams) do
				if not b[9] then b[1].LocalTransparencyModifier = m end
			end
		end
		toneOn()
		local off = q >= 0.5
		if off ~= st.ghostGui then
			st.ghostGui = off
			for _, g in ipairs(ghostGuis) do g.Enabled = not off end
			if corona then corona.Enabled = nq > 0.05 and not off end
			if not st.fxLtm then
				refreshEmitters()
				refreshBeams()
			end
		end
	end
	-- the rings' see-through: their own ghost (another wearer's rings in your way) or the near-camera fade, whichever is more
	local function writeRings()
		local m = max(0.75 * st.armGQ, st.armQ)
		for _, p in ipairs(ringParts) do p.LocalTransparencyModifier = m end
		-- (a Highlight paints a see-through part at full strength, whatever its LocalTransparencyModifier: while the rings
		-- fade or ghost they leave the silver tone, two parent writes each way, so no grey outlined silhouette stays behind)
		-- STUDIO-VERIFY: a part moved out of the Highlight's Model loses the tone at once (zoom from 13 to 8 studs by day)
		local out = m > 0
		if out ~= st.ringsOut then
			st.ringsOut = out
			for h = ARM, ARMD do
				for _, hp in ipairs(holders[h]) do
					if hp[2] == mats.Silver or hp[2] == hosts.noTone then
						hp[2] = out and hosts.noTone or mats.Silver
						if hp[1].Parent then hp[1].Parent = hp[2] end
					end
				end
			end
		end
	end
	local function segDist(p, a, ab, len2) -- distance from point p to the segment a -> a + ab
		local t = clamp((p - a):Dot(ab) / len2, 0, 1)
		return (a + ab * t - p).Magnitude
	end

	---------------------------------------------------------------- (pass 5.2) the reveal: a buildup, one peak, an aftermath
	-- Called every frame while st.revOn (age only runs while the aura is shown, so it waits for the player like the
	-- assembly). Every value it drives is quantised and written only when its step changes; when it ends everything is
	-- left at its resting value and nothing more is written.
	do
		local rates = {} -- (each emitter's rate last written)
		local function rateTo(e, r, step)
			r = math.floor(r / step + 0.5) * step
			if rates[e] ~= r then
				rates[e] = r
				e.Rate = r
			end
		end
		-- a brightness boost on a GUI (k = 4: a brights entry) or a beam (k = 13: a beams entry), in 0.05 steps
		local function boost(entry, v, k)
			v = math.floor(v * 20 + 0.5) / 20
			if v ~= entry[k] then
				entry[k] = v
				local q = max(nq, 0)
				if k == 4 then
					entry[1].Brightness = entry[2] + (entry[3] - entry[2]) * q + v
				else
					entry[1].Brightness = entry[6] + (entry[7] - entry[6]) * q + v
				end
			end
		end
		local function seen(e, vis, a) -- an image the reveal owns: transparency in 0.05 steps
			local tq = math.floor((1 - vis * a) * 20 + 0.5) / 20
			if tq ~= e[5] then
				e[1].ImageTransparency = tq
				e[5] = tq
			end
		end
		-- the wearer's bloom goes and the field of view is given back to the camera it was taken from, if it is still ours.
		-- (Only once either has started: a hide before the buildup, e.g. under the roll cutscene, must not cancel them)
		local function screenOff()
			if st.bloom then
				st.bloom:Destroy()
				st.bloom = nil
			end
			st.bloomDone = true
			local cam = st.fovCam
			if st.fov0 and not st.pushDone and cam and cam.Parent and abs(cam.FieldOfView - st.fovW) <= 0.01 then
				cam.FieldOfView = st.fov0
			end
			st.pushDone = true
		end
		hosts.screenOff = screenOff
		hosts.reveal = function(a)
			if age >= REV_END then
				-- the end: everything at rest (the plots lit, no boosts, idle rates), the trail back under the ordinary fades
				st.revOn = false
				st.gearM, st.runM, st.trailA = 1, 1, nil
				if st.convOn then
					st.convOn = false
					refreshEmitters()
				end
				for _, l in ipairs(hosts.links) do boost(l[1], 0, 13) end
				if hosts.moonB then boost(hosts.moonB, 0, 4) end
				boost(hosts.coreB, 0, 4)
				if hosts.stageB then boost(hosts.stageB, 0, 4) end
				for _, pl in ipairs(hosts.plots) do
					if pl[2] ~= 5 then pl[1].Color, pl[2] = MAT.LUME[1], 5 end
				end
				if em.feed then rateTo(em.feed, 5, 1) end
				if em.air then rateTo(em.air, low and 5 or 14, 1) end
				if em.timeDust then rateTo(em.timeDust, 16, 1) end
				if hosts.trailE then
					seen(hosts.trailE, 1, a)
					table.insert(images, hosts.trailE)
				end
				if hosts.sweepGui then hosts.sweepGui.Enabled = false end
				screenOff()
				return
			end
			local bu = ss(REV_BUILD, PEAK, age) -- the buildup, 0 -> 1
			local pk = age >= PEAK and exp(-(age - PEAK) / 0.3) or 0 -- midnight's one pulse (gone in about a second)
			local ex = age < PEAK and bu or 1 - ss(PEAK + 0.3, REV_END - 0.4, age) -- how charged it all is
			local after = age >= PEAK and 1 - ss(PEAK, REV_END, age) or 0 -- the lively spell after midnight
			-- the gears race toward midnight, stop dead on the stroke for 0.4 s, then pick up their pace again; the runners
			-- race too
			st.gearM = age < PEAK and 1 + 2 * bu or (age < PEAK + 0.4 and 0 or ss(PEAK + 0.4, PEAK + 1.4, age))
			st.runM = 1 + 1.5 * ex
			-- the hour plots light one by one round the dial, I first and XII last, as the trail's sweep reaches them (Neon in
			-- five steps: no flash). plots[1] is XII
			for h, pl in ipairs(hosts.plots) do
				local idx = h == 1 and 12 or h - 1
				local stp = math.floor(clamp((age - (4.9 + 1.6 * idx / 12)) / 0.3, 0, 1) * 5 + 0.5)
				if stp ~= pl[2] then
					pl[2] = stp
					pl[1].Color = LUME_OFF:Lerp(MAT.LUME[1], stp / 5)
				end
			end
			-- the trail: sweeps the dial once in the buildup (5.0 -> 6.6, passing each plot as it lights), reaches XII at
			-- midnight and fades as it coasts on; it comes back on the seconds hand once the aftermath has calmed
			if hosts.trailE then
				if age < PEAK then
					seen(hosts.trailE, ss(4.75, 5.0, age), a)
					st.trailA = TAU * max(0, age - 5.0) / 1.6
				elseif age < PEAK + 1.0 then
					local u = age - PEAK
					seen(hosts.trailE, 1 - ss(0, 0.5, u), a)
					st.trailA = TAU + rad(225) * u - rad(112) * u * u
				else
					seen(hosts.trailE, ss(PEAK + 1.2, PEAK + 2.2, age), a)
					st.trailA = nil
				end
			end
			-- the stage: one golden sweep round its minute band from the start of the buildup to midnight, then gone
			if hosts.sweepE then
				seen(hosts.sweepE, ss(REV_BUILD, REV_BUILD + 0.4, age) * (1 - ss(PEAK, PEAK + 0.8, age)), a)
				st.sweepA = -TAU * max(0, age - REV_BUILD) / (PEAK - REV_BUILD)
			end
			-- light: the links surge at midnight; the moon brightens through the buildup and pulses once; so does the
			-- galaxy's heart; the stage brightens once, briefly
			for _, l in ipairs(hosts.links) do boost(l[1], 0.5 * ex + 1.4 * pk, 13) end
			if hosts.moonB then boost(hosts.moonB, 0.45 * ex + 0.9 * pk, 4) end
			boost(hosts.coreB, 0.8 * ex + 0.9 * pk, 4)
			if hosts.stageB then boost(hosts.stageB, 0.4 * pk, 4) end
			-- particles: streaks converge on the clock through the buildup, thickening; the moon's motes surge into it; the
			-- air and the time dust stay lively for a while after midnight; the void's smoke draws in close
			local conv = em.converge ~= nil and age >= REV_BUILD + 0.3 and age < PEAK
			if conv ~= st.convOn then
				st.convOn = conv
				refreshEmitters()
			end
			if em.converge then rateTo(em.converge, 10 + 50 * bu, 5) end
			if em.feed then rateTo(em.feed, 5 + 25 * ex, 5) end
			if em.air then rateTo(em.air, (low and 5 or 14) + (low and 4 or 16) * after, 2) end
			if em.timeDust then rateTo(em.timeDust, 16 + 14 * after, 2) end
			local sq = age < PEAK and math.floor(bu * 4 + 0.5) or 0
			if sq ~= st.smokeQ then
				st.smokeQ = sq
				local k = 1 - 0.75 * sq / 4
				em.smoke.Speed = n(1.4 * k, 2.4 * k)
			end
			-- midnight, once: the wave across the floor, the glints off the dial, the sparks off the floor, the moon's ring,
			-- the void's smoke blown out (only when its particles would be drawn at all)
			if age >= PEAK and not st.peakDone then
				st.peakDone = true
				if near and alphaOn and visible then
					em.wave:Emit(1)
					if em.waveFront then em.waveFront:Emit(40) end
					if em.burst then em.burst:Emit(44) end
					if em.flare then em.flare:Emit(1) end
					if em.lift then em.lift:Emit(30) end
					if em.moonPulse then em.moonPulse:Emit(1) end
					em.smoke.Speed = n(7, 10)
					em.smoke:Emit(low and 5 or 12)
				end
				em.smoke.Speed = n(1.4, 2.4)
			end
			-- the wearer's own screen (a real equip only): a soft bloom that builds and peaks at midnight, and a slight
			-- push-in (the field of view narrows 6 % and comes back). Both are let go of at once if anything else takes the
			-- camera or the field of view meanwhile. STUDIO-VERIFY: the field of view ends exactly where it started, and a
			-- game script that sets it meanwhile wins
			if st.ownReveal and not st.bloomDone and CONFIG.REVEAL_BLOOM and age >= REV_BUILD then
				local cam = workspace.CurrentCamera
				if not st.bloom then
					-- (it only ever starts at the start of the buildup, so it never pops in half way)
					if cam and bu < 0.1 and cam.CameraType ~= Enum.CameraType.Scriptable then
						st.bloom = new("BloomEffect", { Name = "TheEndBloom", Intensity = 0, Size = 28, Threshold = 2 }, cam)
					elseif bu >= 0.1 then
						st.bloomDone = true
					end
				end
				if st.bloom then
					local bi = 0.3 * (age < PEAK and bu or 1 - ss(PEAK, PEAK + 1.5, age)) + 0.7 * pk
					if age >= PEAK + 1.6 or not st.bloom.Parent then
						st.bloom:Destroy()
						st.bloom, st.bloomDone = nil, true
					elseif abs(bi - st.bloom.Intensity) >= 0.02 then
						st.bloom.Intensity = bi
					end
				end
			end
			if st.ownReveal and not st.pushDone and CONFIG.REVEAL_PUSH and age >= REV_BUILD then
				local cam = workspace.CurrentCamera
				if not cam or cam.CameraType == Enum.CameraType.Scriptable then
					-- (a cutscene took the camera: give the field of view back now, if the push had started and it is
					-- still ours)
					if st.fov0 then screenOff() end
				elseif not st.fov0 then
					-- (it only ever starts at the start of the buildup, so the view never jumps in half way)
					if bu < 0.05 then
						st.fov0, st.fovW, st.fovCam = cam.FieldOfView, cam.FieldOfView, cam
					else
						st.pushDone = true
					end
				elseif cam ~= st.fovCam or abs(cam.FieldOfView - st.fovW) > 0.01 then
					screenOff() -- (another camera, or something else changed it: it is theirs now, never touched again)
				elseif age >= REV_END - 0.4 then
					cam.FieldOfView = st.fov0
					st.pushDone = true
				else
					local f = st.fov0 * (1 - 0.06 * bu * (1 - ss(PEAK + 0.4, REV_END - 0.4, age)))
					if abs(f - st.fovW) > 0.005 then
						cam.FieldOfView = f
						st.fovW = cam.FieldOfView
					end
				end
			end
		end
	end

	---------------------------------------------------------------- the frame
	function fx.update(dt, s)
		-- (hidden, e.g. under the roll cutscene's camera, or too far away: nothing advances, so the assembly and the grade
		-- wait for the player, whether or not the framework keeps calling update)
		if destroyed or not visible then return end
		-- (a physics fling can hand us one NaN position: skip that frame instead of poisoning every spring for good)
		local p0 = s.cf.Position
		if p0.X ~= p0.X or p0.Y ~= p0.Y or p0.Z ~= p0.Z or s.hover ~= s.hover then return end
		if remote and not near then
			-- another player's aura past ~110 studs (about 40 px tall) runs every other frame, with both frames' time: the
			-- springs and spins stay exact and it costs half
			st.skipDt += dt
			st.skipN = 1 - st.skipN
			if st.skipN == 1 then return end
			dt, st.skipDt = st.skipDt, 0
		elseif st.skipDt > 0 then
			dt += st.skipDt
			st.skipDt = 0
		end
		if dt > 0.1 then dt = 0.1 end
		age += dt
		local asm = age < ASM_END
		local t, now, g = s.t, s.now, s.glide
		local cf = s.cf
		local O = cf.Position + Vector3.new(0, s.hover, 0)
		local a = s.alpha
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
