-- AuraRNG Studio install kit | 12_chunk_11_of_12.luau | step 12: piece 11 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (151582 bytes, checksum 322184148).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "12_chunk_11_of_12.luau"
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

local K = 11
-- piece 11 of 12 of the new source (13204 bytes, checksum 959073682, long bracket level 1)
local DATA = [=[
		GCF[GF1], GCF[GF2], GCF[GF3] = F1, F2, F3
		if asm then
			-- (for the owner's close camera the rings wait flat on the dais until the hands have locked at XII, then close
			-- round the wearer as the finale: risen earlier, the meridian would stand across the dial during the lock.
			-- Decided once, at the first frame the player sees, so a zoom during the assembly never makes them jump)
			if st.r0 == nil then st.r0 = (ctx.isLocal and cz > 0.5) and 3.5 or 0 end
			local r0 = st.r0
			local flat = Gd * FLAT
			if age < 2.4 + r0 then GCF[GF1] = lerpCF(flat, F1, easeOutBack((age - 1.0 - r0) / 1.4)) end
			if age < 2.7 + r0 then GCF[GF2] = lerpCF(flat, F2, easeOutBack((age - 1.3 - r0) / 1.4)) end
			if age < 3.0 + r0 then GCF[GF3] = lerpCF(flat, F3, easeOutBack((age - 1.6 - r0) / 1.4)) end
		end
		if hi then
			local F3c = GCF[GF3] -- (the shards ride the ecliptic where it is, rising or not)
			for i = 0, 7 do
				local c = F3c * CFrame.Angles(0, 0, -((rad(i * 45 + 22.5) + rad(22) * t) % TAU)) * CFrame.new(0, 4.0, 0)
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

		-- 5. the balance: moon and void on the viewer's left and right of an invisible beam, rocking like scales (lower, a
		-- little wider and well behind the wearer when the camera is close, so the moon sits beside the dial at about its
		-- size, clear of the HUD; another wearer's step back behind your clock with it)
		local sway = asm and smooth((age - 1.8) / 1.2) or 1
		-- (the void's centre stays >= 13.4 studs out horizontally, so its 13-stud disc always clears the rings' 6.3 reach)
		-- (in first person they move back beside the view: about 97° off the line of sight, outside the 102° field of view)
		local arm = 12.5 - CLOSE.arm * cz
		local orbZ = 1.5 - CLOSE.orbZ * cz * (1 - fp) + 1.5 * fp - st.yieldD
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
		-- (the hairlines' distance steps: event writes, only when a band changes)
		local pb = max(hairBand(dm, st.pBand), low and 2 or 1)
		if pb ~= st.pBand then
			st.pBand = pb
			local hy = HAIR[pb][1]
			local hl = low and 2.25 or 1.14
			for _, k in ipairs(hosts.photon) do
				PP[k].Size = Vector3.new(hl, hy, 0.12)
				PRR[k] = 0.115 + hy / 2
			end
		end
		local nb = max(hairBand((camPos - K.Position).Magnitude, st.nBand), low and 2 or 1)
		if nb ~= st.nBand then
			st.nBand = nb
			hosts.needle.Size = Vector3.new(HAIR[nb][2], 12.2, 0.08)
		end
		GCF[GPF] = CFrame.lookAt(voidC + nrm * (16 / dc), voidC, up)
		GCF[GHF] = CFrame.lookAt(voidC + nrm * 4.1, voidC, up)
		local Dk = CFrame.new(voidC) * V.Rotation * TILTACC
		local dir = CONFIG.ACC_DIR -- (the accretion texture's streaks wind clockwise outward: a counter-clockwise turn makes them trail)
		if asm then accExtra = (accExtra + rad(360 * exp(-3 * max(0, age - 0.3))) * dt * dir) % TAU end
		GCF[GACC] = Dk * CFrame.Angles(0, (rad(40) * now * dir + accExtra) % TAU, 0)
		-- (the swirl's carrier rides 0.3 studs above the accretion disc's plane, toward the viewer: its particles sort over
		-- the disc and the void however Roblox keys an emitter, at its part or at its particles)
		GCF[GSWIRL] = Dk * SWIRL_UP * CFrame.Angles(0, (rad(85) * now * dir) % TAU, 0)
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
		-- (pass 5.1) the star halo turns slowly on its tilt; the helix hub spins round the body from the feet
		if hosts.halo then GCF[GHALO] = W * HALO_TILT * CFrame.Angles(0, (rad(14) * now) % TAU, 0) end
		GCF[GHELIX] = CFrame.new(O + HELIX_FEET) * CFrame.Angles(0, (rad(220) * now) % TAU, 0)
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
		if st.nearHide then
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
		-- first person: the palm streams, the palm and funnel streaks and the body's wisps and sparks switch off (they sit
		-- just under or round the lens), and fewer ash flakes drift across the bottom of the view
		local fpOn = fp > 0.5
		if fpOn ~= st.fpOn then
			st.fpOn = fpOn
			refreshBeams()
			refreshEmitters()
			if em.ash then em.ash.Rate = fpOn and 3 or 8 end
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
						L = PROT[i] * CFrame.new(0, rt + rr + (PRS[i] - rt - rr) * kk, 0)
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
		-- the body's wisps and sparks come back a second after the aura is shown again (a quick hide/show never blinks them)
		if not st.footOk and os.clock() - st.shownAt >= 1.1 then
			st.footOk = true
			refreshEmitters()
		end
		-- walking or flying: the void's ink smoke thins out and dies young, the moon's smoke and the body's wisps stop and
		-- the moon dust halves, so no smog patches hang along the path (the body's sparks and the speed trail stream out
		-- behind instead)
		local slow = (st.smokeSlow and (g > 0.3 or st.speedOn)) or g > 0.6 or st.speedOn
		if slow ~= st.smokeSlow then
			st.smokeSlow = slow
			em.smoke.Rate = slow and (low and 1 or 1.5) or (low and 4 or 10)
			em.smoke.Lifetime = slow and n(1.0, 1.4) or n(3.5, 4.5)
			if em.smokeMoon then em.smokeMoon.Rate = slow and 0 or 5 end
			em.dust.Rate = (low and 5 or 10) * (slow and 0.5 or 1)
			if em.wisps then em.wisps.Rate = slow and 0 or (low and 3 or 7) end
			-- (the helix's strands: thin while travelling, so they leave a short glittering wake, not a long trail)
			em.strandMoon.Rate = (low and 14 or 34) * (slow and 0.35 or 1)
			em.strandVoid.Rate = slow and 0 or (low and 8 or 18)
		end
		if remote and cam and ownerHub then
			-- another wearer's clock or orbs in front of your own clock (a friend beside or behind you): theirs step back
			-- along your view (a spring) until they stand 12 studs behind your clock, smaller and still solid. Tested at
			-- where they would stand without stepping back, and held 1.5 s, so they never swing back and forth
			local ab = ownerHub - camPos
			local len2 = ab:Dot(ab)
			local y0 = st.yieldD
			local Kp0, nz = K.Position - vl * y0, K.LookVector
			local hit = false
			if len2 > 1 then
				local d0, d1 = (camPos - Kp0):Dot(nz), (ownerHub - Kp0):Dot(nz)
				if d0 * d1 < 0 then hit = (camPos + ab * (d0 / (d0 - d1)) - Kp0).Magnitude < 14.5 end
				hit = hit or segDist(moonC - vl * y0, camPos, ab, len2) < 5.5 or segDist(voidC - vl * y0, camPos, ab, len2) < 7.0
			end
			if hit then
				st.yieldHold = 1.5
				st.yieldT = clamp((ownerHub - Kp0):Dot(vl) + 12, 0, 48)
			elseif st.yieldHold > 0 then
				st.yieldHold -= dt
				if st.yieldHold <= 0 then st.yieldT = 0 end
			end
			st.yieldD = snap and st.yieldT or st.yieldD + (st.yieldT - st.yieldD) * (1 - exp(-3 * dt))
		end
		if remote and st.ghostRemote and cam then
			-- someone else's aura between you and your camera: test the segment from the camera to your own focus against
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
