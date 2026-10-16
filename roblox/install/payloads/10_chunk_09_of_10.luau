-- AuraRNG Studio install kit | 10_chunk_09_of_10.luau | step 10: piece 9 of 10
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (123861 bytes, checksum 523677650).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "10_chunk_09_of_10.luau"
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

local K = 9
-- piece 9 of 10 of the new source (13338 bytes, checksum 37178664, long bracket level 1)
local DATA = [=[
		GCF[GDUST] = K * CFrame.new(0, 0, 1.3) * CFrame.Angles(0, 0, -((rad(20) * now) % TAU)) -- (the time-dust ring turns clockwise)
		GCF[GCROWN] = crownY ~= 0 and K * CFrame.new(0, crownY, 0) or K

		-- 3. the dais layers and the balance wheel (just below the soles, never into the galaxy; on the dais when seated)
		local gdir = CONFIG.GALAXY_DIR
		GCF[GDAIS] = Gd
		GCF[GG0] = Gd * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, (rad(-6) * gdir * now) % TAU, 0)
		GCF[GG1] = Gd * CFrame.new(0, 0.42, 0) * CFrame.Angles(0, (rad(9) * gdir * now) % TAU, 0)
		GCF[GG2] = Gd * CFrame.new(0, 0.66, 0) * CFrame.Angles(0, (rad(-16) * gdir * now) % TAU, 0)
		GCF[GENG] = Gd * CFrame.new(0, 0.04, 0) * CFrame.Angles(0, (rad(2.5) * gdir * now) % TAU, 0)
		GCF[GFUNNEL] = Gd * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, (rad(-70) * CONFIG.FUNNEL_DIR * t) % TAU, 0)
		local wheelAngle = rad(160) * sin(TAU * t / 3.2) * (asm and smooth((age - 4.6) / 1.2) or 1)
		local wheelY = O.Y - s.legLen - 0.9
		wheelY += (dY + 1.2 - wheelY) * sitT
		if wheelY < dY + 1.2 then wheelY = dY + 1.2 end
		local Bw = CFrame.new(O.X, wheelY, O.Z) * CFrame.Angles(0, wheelAngle, 0)
		GCF[GWHEEL] = Bw

		-- 4. the armillary (body-anchored, upright: leaning it with the glide laid the dark equator across the head line from
		-- the follow camera); on equip each ring rises from lying flat on the dais. It lifts a little whenever a ring's lowest
		-- edge would dip into the galaxy layers (small avatars, slopes, sitting)
		local Wr = W.Rotation
		local R1 = Wr * CFrame.Angles(0, (rad(8) * t) % TAU, 0) * TILT33
		local R2 = R1 * CFrame.Angles(rad(57) + rad(18) * sin(TAU * t / 19), 0, 0)
		local R3 = R2 * CFrame.Angles(0, rad(23.4) + rad(14) * sin(TAU * t / 27 + 1.1), 0)
		local n1, n2, n3 = R1.ZVector.Y, R2.ZVector.Y, R3.ZVector.Y
		local drop = max(6.30 * sqrt(max(0, 1 - n1 * n1)) + 0.13 * abs(n1), 5.52 * sqrt(max(0, 1 - n2 * n2)) + 0.21 * abs(n2),
			4.90 * sqrt(max(0, 1 - n3 * n3)) + 0.11 * abs(n3))
		local baseY = 1.3 - 1.0 * sitT
		local liftT = max(0, dY + 0.96 - (O.Y + baseY - drop))
		st.lift = snap and liftT or st.lift + (liftT - st.lift) * (1 - exp(-6 * dt))
		if st.lift < liftT - 0.3 then st.lift = liftT - 0.3 end
		local A0p = O + Vector3.new(0, baseY + st.lift, 0)
		local F1 = CFrame.new(A0p) * R1
		local F2 = CFrame.new(A0p) * R2
		local F3 = CFrame.new(A0p) * R3
		GCF[GF1], GCF[GF2], GCF[GF3] = F1, F2, F3
		if asm then
			local flat = Gd * FLAT
			if age < 2.4 then GCF[GF1] = lerpCF(flat, F1, easeOutBack((age - 1.0) / 1.4)) end
			if age < 2.7 then GCF[GF2] = lerpCF(flat, F2, easeOutBack((age - 1.3) / 1.4)) end
			if age < 3.0 then GCF[GF3] = lerpCF(flat, F3, easeOutBack((age - 1.6) / 1.4)) end
		end
		if hi then
			for i = 0, 7 do
				local c = F3 * CFrame.Angles(0, 0, -((rad(i * 45 + 22.5) + rad(22) * t) % TAU)) * CFrame.new(0, 4.0, 0)
					* CFrame.Angles((t * rad(50 + 15 * i)) % TAU, (t * rad(35 - 7 * i)) % TAU, 0)
				if asm then
					local u = (age - 5.0 - 0.06 * i) / 0.8
					if u < 1 then
						local ang = SHARD_A[i]
						local sp = K * Vector3.new(14 * sin(ang), 14 * cos(ang), 0)
						c = CFrame.new(sp + (c.Position - sp) * easeOutBack(u)) * c.Rotation
					end
				end
				GCF[GSHARD0 + 1 + i] = c
			end
		end

		-- 5. the balance: moon and void on the viewer's left and right of an invisible beam, rocking like scales (closer in
		-- and a little behind the wearer when the camera is close, so both stay on screen)
		local sway = asm and smooth((age - 1.8) / 1.2) or 1
		-- (the void's centre stays >= 13.4 studs out horizontally, so its 13-stud disc always clears the rings' 6.3 reach)
		-- (in first person they move back beside the view: about 97° off the line of sight, outside the 102° field of view)
		local arm = 12.5 - CLOSE.arm * cz
		local orbZ = 1.5 - CLOSE.orbZ * cz + 12 * fp
		local Pv = Vk * CFrame.new(0, 6.0 - CLOSE.orbY * cz, orbZ) * CFrame.Angles(0, 0, rad(10) * sin(TAU * t / 10) * sway)
		local moonC = Pv * Vector3.new(-arm, 0, 0)
		local voidC = Pv * Vector3.new(arm, 0, 0)
		local focus = O + Vector3.new(0, 1, 0)
		if asm and age < 1.8 then
			local sp = Vk * Vector3.new(-arm, -9, orbZ) -- (the moon rises out of the dais)
			moonC = sp + (moonC - sp) * easeOutBack((age - 0.6) / 1.2)
		end
		GCF[GMOON] = CFrame.lookAt(moonC, focus)
		GCF[GVOID] = CFrame.lookAt(voidC, focus)
		if moonFace then
			-- (the face rides the camera ray, 4.4 studs in front of the moon's centre, turned to face the camera: +z toward
			-- it, as the clock frame, so the disc's Left face looks at the camera)
			local dmv = camPos - moonC
			local dmm = dmv.Magnitude
			local fdir = dmm > 1e-3 and dmv / dmm or -V.LookVector
			local fpos = moonC + fdir * 4.4
			GCF[GMOONF] = CFrame.lookAt(fpos, fpos - fdir, abs(fdir.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis)
		end
		-- the void's camera-facing details: the photon ring sits on the silhouette circle the camera sees (radius rt)
		local dv = camPos - voidC
		local dm = dv.Magnitude
		local nrm = dm > 1e-3 and dv / dm or -V.LookVector
		local dc = max(dm, 5)
		local up = abs(nrm.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis
		rt = 4 * sqrt(1 - 16 / (dc * dc))
		GCF[GPF] = CFrame.lookAt(voidC + nrm * (16 / dc), voidC, up)
		GCF[GHF] = CFrame.lookAt(voidC + nrm * 4.1, voidC, up)
		local Dk = CFrame.new(voidC) * V.Rotation * TILTACC
		local dir = CONFIG.ACC_DIR -- (the accretion texture's streaks wind clockwise outward: a counter-clockwise turn makes them trail)
		if asm then accExtra = (accExtra + rad(360 * exp(-3 * max(0, age - 0.3))) * dt * dir) % TAU end
		GCF[GACC] = Dk * CFrame.Angles(0, (rad(40) * now * dir + accExtra) % TAU, 0)
		GCF[GSWIRL] = Dk * CFrame.Angles(0, (rad(85) * now * dir) % TAU, 0)
		local az = atan2(voidC.X - O.X, voidC.Z - O.Z)
		GCF[GRIBEND] = Gd * CFrame.new(13.2 * sin(az), 0.3, 13.2 * cos(az)) * CFrame.Angles(0, az, 0)
		GCF[GFEED] = CFrame.lookAt(K * FEED_PT, voidC)

		-- 6. the air (turned to face the way the wearer travels: the speed trail streams out behind) and the palms
		local camDist = (camPos - O).Magnitude
		local td = st.tdir
		if td and td.Magnitude > 0.5 then
			local tu = td.Unit
			GCF[GAIR] = CFrame.lookAt(O, O + tu, abs(tu.Y) > 0.95 and W.LookVector or Vector3.yAxis) * CFrame.new(0, 4, 0)
		else
			GCF[GAIR] = CFrame.new(O + Vector3.new(0, 4, 0))
		end
		GCF[GBOKEH] = V * CFrame.new(0, 3.0, min(7.5, camDist - 4))
		-- (a hand replaced without a new character, e.g. by ApplyDescription, takes our attachment with it: fall back to the
		-- intake carriers and re-point the streams)
		if palmR and palmR.Parent == nil then palmR, st.repoint = nil, true end
		if palmL and palmL.Parent == nil then palmL, st.repoint = nil, true end
		local f = W.RightVector:Dot(V.RightVector)
		local flip = (f > 0.2 and assign ~= 1) and 1 or (f < -0.2 and assign ~= -1) and -1 or nil
		if flip then assign = flip end
		local moonSide = -assign
		local mA, vA = palmFor(moonSide, moonCarA), palmFor(-moonSide, voidCarA)
		GCF[GPALMM] = mA ~= moonCarA and CFrame.new(mA.WorldPosition) or W * CFrame.new(2.3 * moonSide, -0.3, -0.5)
		GCF[GPALMV] = vA ~= voidCarA and CFrame.new(vA.WorldPosition) or W * CFrame.new(-2.3 * moonSide, -0.3, -0.5)

		-- near-camera rules (with hysteresis), decided before the move so a group shown again moves this very frame: no rings
		-- or bokeh blobs across the lens. The rings fade out over 0.25 s in three steps before they leave the world, and come
		-- back fully see-through and fade in, so scrolling between 9 and 12 studs never snaps the biggest thing near the lens
		if CONFIG.NEAR_HIDE then
			local dA = (camPos - A0p).Magnitude
			if (not st.armWant and dA < CONFIG.NEAR_ARM_HIDE) or (st.armWant and dA > CONFIG.NEAR_ARM_SHOW) then
				st.armWant = not st.armWant
			end
			local tgt = st.armWant and 1 or 0
			if st.armF ~= tgt or (armHidden and not st.armWant) then
				if armHidden and not st.armWant then
					armHidden = false -- (back in the world at full see-through, at this frame's positions)
					setGroups()
				end
				local step = snap and 1 or dt / 0.25
				st.armF = tgt > st.armF and min(1, st.armF + step) or max(0, st.armF - step)
				local q = math.floor(st.armF * 3 + 0.5) / 3
				if q ~= st.armQ then
					st.armQ = q
					writeRings()
				end
				if st.armF >= 1 and not armHidden then
					armHidden = true
					setGroups()
				end
			end
			if (not bokehNear and camDist < CONFIG.NEAR_BOKEH_HIDE) or (bokehNear and camDist > CONFIG.NEAR_BOKEH_SHOW) then
				bokehNear = not bokehNear
				refreshEmitters()
			end
		end
		-- far detail (the framework's setDetail past ~110 studs): the lights, the near-only beams and another player's
		-- silver tone fade over 0.5 s instead of switching in one frame (at night a lit patch of plaza would pop)
		local lt = near and 1 or 0
		if st.lodF ~= lt then
			st.lodF = lt > st.lodF and min(1, st.lodF + dt / 0.5) or max(0, st.lodF - dt / 0.5)
			local lq = math.floor(st.lodF * 20 + 0.5) / 20
			if lq ~= st.lod then
				st.lod = lq
				applyLod()
			end
		end
		-- first person: the palm streams switch off (their ends sit just under the lens)
		local fpOn = fp > 0.5
		if fpOn ~= st.fpOn then
			st.fpOn = fpOn
			refreshBeams()
		end

		-- 7. every part = its group's frame x its rest transform (eased from its start pose while it assembles)
		for j = 1, nAct do
			local i = act[j]
			local L = PL[i]
			local rr = PRR[i]
			if rr then L = PROT[i] * CFrame.new(0, rt + rr, 0) end
			if asm then
				local S = PS[i]
				if S and age < PM1[i] then
					local kk = 1 - easeOutBack((age - PM0[i]) / (PM1[i] - PM0[i]))
					if rr then
						local r0 = PRS[i] or (rt + PRSO[i])
						L = PROT[i] * CFrame.new(0, rt + rr + (r0 - rt - rr) * kk, 0)
					else
						L = lerpCF(L, S, kk)
					end
				end
			end
			acf[j] = GCF[PG[i]] * L
		end
		workspace:BulkMoveTo(actParts, acf, Enum.BulkMoveMode.FireCFrameChanged)

		-- 8. event writes only
		if flip or st.repoint then
			st.repoint = false
			sb[1].Attachment1 = mA
			if sb[2] then sb[2].Attachment1 = mA end
			sb[3].Attachment1 = vA
			if sb[4] then sb[4].Attachment1 = vA end
		end
		if on ~= alphaOn then
			alphaOn = on
			refreshEmitters()
			refreshLights()
		end
		if asm then
			-- the void condenses out of a point (Size writes on this one part, during the assembly only)
			local d = 0.6 + 7.4 * easeOutBack(age / 1.2)
			if abs(d - voidD) >= 0.01 or (d == 8 and voidD ~= 8) then
				voidD = d
				void.Size = voidSize * (d / 8)
			end
			fadeAll(a, true, 0.03)
			alphaW = a
			-- the emitters switch on in turn as their part of the machine locks in
			local e = emitters[nextEmit]
			if e and age >= e[2] then
				while e and age >= e[2] do
					e[4] = true
					nextEmit += 1
					e = emitters[nextEmit]
				end
				refreshEmitters()
				refreshLights()
			end
		elseif not settled or a ~= alphaW then
			-- the assembly has ended (snap everything to rest) or the framework is fading the aura out (or back in)
			if not settled then
				settled = true
				if voidD ~= 8 then
					voidD = 8
					void.Size = voidSize
				end
				for _, e in ipairs(emitters) do e[4] = true end
				nextEmit = #emitters + 1
				refreshEmitters()
				refreshLights()
				fadeAll(a, false, 0.03)
			else
				fadeAll(a, false, 0.04)
			end
			alphaW = a
		end
		if isGrounded ~= grounded then
			grounded = isGrounded
			refreshEmitters()
		end
		-- the drips come back a second after the aura is shown again (a quick hide/show never blinks them)
		if not st.footOk and os.clock() - st.shownAt >= 1.1 then
			st.footOk = true
			refreshEmitters()
		end
		-- walking or flying: the void's ink smoke thins out, so no trail of puffs hangs along the path
		local slow = (st.smokeSlow and (g > 0.3 or st.speedOn)) or g > 0.6 or st.speedOn
		if slow ~= st.smokeSlow then
			st.smokeSlow = slow
			em.smoke.Rate = slow and (low and 1.5 or 2.5) or (low and 4 or 10)
			em.smoke.Lifetime = slow and n(2, 2.5) or n(3.5, 4.5)
			if em.smokeMoon then
				em.smokeMoon.Rate = slow and 1.5 or 5
				em.smokeMoon.Lifetime = slow and n(2, 2.5) or n(3.5, 4.5)
			end
		end
		if remote and CONFIG.GHOST_REMOTE and cam then
			-- someone else's aura between you and your camera: test the segment from the camera to your own focus against
			-- their clock disc and their orbs (those ghost together, with their GUIs, smoke and streams; enter at once, leave
			-- after 1.2 s clear) and, separately, against their rings (only the rings ghost: a friend standing beside the
			-- wearer looks through the rings, never through the clock; 0.6 s)
			local head = cam.Focus.Position
			local ab = head - camPos
			local len2 = ab:Dot(ab)
			local occ, occA = false, false
			if len2 > 1 then
				local Kp, nz = K.Position, K.LookVector
				local d0, d1 = (camPos - Kp):Dot(nz), (head - Kp):Dot(nz)
				if d0 * d1 < 0 then occ = (camPos + ab * (d0 / (d0 - d1)) - Kp).Magnitude < 14.5 end
				occ = occ or segDist(moonC, camPos, ab, len2) < 5.5 or segDist(voidC, camPos, ab, len2) < 7.0
				occA = segDist(A0p, camPos, ab, len2) < 6.5
			end
			if occ then st.ghostHold = 1.2 elseif st.ghostHold > 0 then st.ghostHold -= dt end
			local tgt = st.ghostHold > 0 and 1 or 0
			if st.ghost ~= tgt then
				st.ghost = tgt > st.ghost and min(1, st.ghost + 5 * dt) or max(0, st.ghost - 5 * dt)
				local q = math.floor(st.ghost * 3 + 0.5) / 3
				if q ~= st.ghostQ then setGhost(q) end
			end
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "12_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
