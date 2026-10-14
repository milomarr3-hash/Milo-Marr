-- AuraRNG Studio install kit | 07_chunk_06_of_07.luau | step 7: piece 6 of 7
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (82580 bytes, checksum 413068034).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "07_chunk_06_of_07.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-82580-413068034-7-175648338"
local NEW_LEN, NEW_SUM = 82580, 413068034
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

local N = 7
local LENS = { 13394, 13390, 13386, 13387, 13372, 13337, 2314 }
local SUMS = { 747760660, 546838554, 282322451, 777563289, 713911797, 449542432, 103059902 }

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
-- piece 6 of 7 of the new source (13337 bytes, checksum 449542432, long bracket level 1)
local DATA = [=[
			for _, b in ipairs(beams) do
				if b[8] then b[1].Enabled = near end
			end
		end
	end
	local function setGroups()
		local changed = false
		for h = 1, 4 do
			local show = not (hideD[h] and not near) and not (hideA[h] and armHidden)
			if show ~= shownH[h] then
				shownH[h] = show
				changed = true
				for _, hp in ipairs(holders[h]) do hp[1].Parent = show and hp[2] or nil end
			end
		end
		if changed then rebuildActive() end
	end
	-- day/night: every glowing value blends with the night factor, written only when the quantised factor changes
	local function applyNight(q)
		nq = q
		for _, b in ipairs(brights) do b[1].Brightness = b[2] + (b[3] - b[2]) * q end
		for _, e in ipairs(emitNight) do
			e[1].LightEmission = e[2] + (e[3] - e[2]) * q
			e[1].Brightness = e[4] + (e[5] - e[4]) * q
		end
		for _, b in ipairs(beams) do
			b[1].LightEmission = b[4] + (b[5] - b[4]) * q
			b[1].Brightness = b[6] + (b[7] - b[6]) * q
		end
		keyLight.Brightness = 1.5 * q
		if wheelLight then wheelLight.Brightness = 0.9 * q end
		if bokeh then bokeh.Rate = 0.5 + 0.7 * q end
		haloEntry[2] = 0.65 - 0.2 * q
		if corona then
			coronaEntry[2] = 1 - 0.4 * q
			corona.Enabled = q > 0.05
		end
		if settled then
			-- (after the assembly the night values are written straight away; during it the fades pick them up)
			local a = alphaW
			local tr = 1 - (1 - haloEntry[2]) * a
			if tr ~= haloEntry[5] then
				haloIm.ImageTransparency = tr
				haloEntry[5] = tr
			end
			if coronaEntry then
				tr = 1 - (1 - coronaEntry[2]) * a
				if tr ~= coronaEntry[5] then
					coronaEntry[1].ImageTransparency = tr
					coronaEntry[5] = tr
				end
			end
			if tone then
				hlF, hlO = 1 - (0.45 - 0.25 * q) * a, 1 - (0.65 - 0.35 * q) * a
				tone.FillTransparency, tone.OutlineTransparency = hlF, hlO
			end
		end
		refreshLights()
	end
	-- the fades: every part, image and beam goes from invisible to its rest value in its own window (times the framework's
	-- fade-in alpha); a value is written only when it moved enough, and snapped exactly at the ends (no blinking)
	local function fadeAll(a, asm, thr)
		for _, i in ipairs(solids) do
			local f = a
			if asm then
				local u = (age - PF0[i]) / (PF1[i] - PF0[i])
				f *= u <= 0 and 0 or u >= 1 and 1 or u * u * (3 - 2 * u)
			end
			local tr = 1 - f
			local cur = PCUR[i]
			if tr ~= cur and (abs(tr - cur) >= thr or tr <= 0 or tr >= 1) then
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
		local fb = a
		if asm then fb *= smooth((age - 4.6) / 0.8) end
		local q = math.floor(fb * 10 + 0.5)
		for _, b in ipairs(beams) do
			if q ~= b[3] then
				b[1].Transparency = b[2][q]
				b[3] = q
			end
		end
		if tone then
			local fh = a
			if asm then fh *= smooth((age - 3.6) / 0.6) end
			local fill, out = 1 - (0.45 - 0.25 * max(nq, 0)) * fh, 1 - (0.65 - 0.35 * max(nq, 0)) * fh
			if abs(fill - hlF) >= thr or (fh >= 1 and fill ~= hlF) or (fh <= 0 and fill ~= hlF) then
				tone.FillTransparency = fill
				tone.OutlineTransparency = out
				hlF, hlO = fill, out
			end
		end
	end

	---------------------------------------------------------------- the frame
	function fx.update(dt, s)
		if destroyed then return end
		if dt > 0.1 then dt = 0.1 end
		age += dt
		local asm = age < ASM_END
		local t, now, g = s.t, s.now, s.glide
		local cf = s.cf
		local O = cf.Position + Vector3.new(0, s.hover, 0)

		-- 1. frames: the wearer (W), this client's viewer (V), the clock (K)
		local lv = cf.LookVector
		yawW = wrapPi(yawW + wrapPi(atan2(-lv.X, -lv.Z) - yawW) * (1 - exp(-5 * dt)))
		local W = CFrame.new(O) * CFrame.Angles(0, yawW, 0)
		local cam = workspace.CurrentCamera
		local camPos = lastCamPos
		if cam then
			camPos = cam.CFrame.Position
			lastCamPos = camPos
		end
		local V
		if VIEWER then
			-- the clock swings to the far side of the wearer from this camera through a critically damped spring (no overshoot);
			-- it holds still when the camera is inside the wearer (first person) or straight above
			local v = O - camPos
			local dh = sqrt(v.X * v.X + v.Z * v.Z)
			if dh > 1.5 and dh > 0.2 * abs(v.Y) then yawTarget = atan2(-v.X, -v.Z) end
			local k = CONFIG.YAW_SPRING
			local x = wrapPi(psi - yawTarget)
			local e = exp(-k * dt)
			local tmp = (psiVel + k * x) * dt
			x = (x + tmp) * e
			psiVel = (psiVel - k * tmp) * e
			psi = wrapPi(yawTarget + x)
			if psi ~= psi or psiVel ~= psiVel then psi, psiVel = yawTarget, 0 end
			V = CFrame.new(O) * CFrame.Angles(0, psi, 0)
		else
			V = W * FLIP
		end
		local K = V * CFrame.new(0, CONFIG.CLOCK_HEIGHT - 0.5 * g, -(CONFIG.CLOCK_DIST + 2 * g))
			* CFrame.Angles(0, rad(9 + 5 * sin(TAU * t / 16)), 0) * CFrame.Angles(-rad(CONFIG.CLOCK_TILT + 14 * g), 0, 0)
		GCF[GK] = K

		-- 2. the clockwork: gears (meshed rates from the server clock), hands, crown
		for _, gd in ipairs(gearData) do
			local x, y, z = gd.cx, gd.cy, gd.cz
			if asm then
				-- spin up fast and wind down to the running pace (an integrated extra angle, so nothing jumps)
				gd.extra = (gd.extra + rad((gd.sign * 300 - gd.rate) * exp(-4 * max(0, age - gd.a0))) * dt) % TAU
				local u = (age - gd.a0) / (gd.a1 - gd.a0)
				if u < 1 then
					local kk = 1 - easeOutBack(u)
					x, y, z = x + (gd.sx - x) * kk, y + (gd.sy - y) * kk, z + (gd.sz - z) * kk
				end
			end
			GCF[gd.grp] = K * CFrame.new(x, y, z) * CFrame.Angles(0, 0, -((rad(gd.rate) * now + gd.extra) % TAU))
		end
		local th, tm, ts = 0, 0, rad(6 * (now % 60))
		local crownY = 0
		if asm then
			local kk = 1 - easeOutBack((age - 3.6) / 1.2)
			th, tm, ts = -rad(330) * kk, -rad(1050) * kk, ts - rad(720) * kk
			crownY = 6 * (1 - easeOutBack((age - 4.2) / 0.6))
		end
		GCF[GHOUR] = K * CFrame.Angles(0, 0, -th) * CFrame.new(0, 0, 0.85)
		GCF[GMIN] = K * CFrame.Angles(0, 0, -tm) * CFrame.new(0, 0, 1.15)
		GCF[GSEC] = K * CFrame.Angles(0, 0, -ts) * CFrame.new(0, 0, 1.42)
		GCF[GCROWN] = crownY ~= 0 and K * CFrame.new(0, crownY, 0) or K

		-- 3. the dais: stays on the ground for walks and jumps, floats under a flyer
		local feetY = cf.Position.Y - s.legLen
		local gnd = s.ground
		local isGrounded = gnd ~= nil and (feetY - gnd.Y) < 7
		local target
		if isGrounded then
			target = gnd.Y
			lastGroundY = target
		elseif CONFIG.DAIS_FLOAT or not lastGroundY then
			target = feetY + s.hover - 2.4
		else
			target = lastGroundY
		end
		daisY = daisY and daisY + (target - daisY) * (1 - exp(-8 * dt)) or target
		local Gd = CFrame.new(O.X, daisY, O.Z)
		GCF[GDAIS] = Gd
		GCF[GG0] = Gd * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, (rad(-6) * now) % TAU, 0)
		GCF[GG1] = Gd * CFrame.new(0, 0.42, 0) * CFrame.Angles(0, (rad(9) * now) % TAU, 0)
		GCF[GG2] = Gd * CFrame.new(0, 0.66, 0) * CFrame.Angles(0, (rad(-16) * now) % TAU, 0)
		GCF[GENG] = Gd * CFrame.new(0, 0.04, 0) * CFrame.Angles(0, (rad(2.5) * now) % TAU, 0)
		GCF[GFUNNEL] = Gd * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, (rad(-70) * t) % TAU, 0)
		local wheelAngle = rad(160) * sin(TAU * t / 3.2) * (asm and smooth((age - 4.6) / 1.2) or 1)
		local Bw = CFrame.new(O.X, O.Y - s.legLen - 0.35, O.Z) * CFrame.Angles(0, wheelAngle, 0)
		GCF[GWHEEL] = Bw
		GCF[GHAIR] = Bw * CFrame.new(0, 0.22, 0) * CFrame.Angles(0, -0.5 * wheelAngle, 0)

		-- 4. the armillary (body-anchored, leaning with the glide); on equip each ring rises from lying flat on the dais
		local A0 = W * CFrame.new(0, 1.3, 0) * CFrame.Angles(-rad(18 * g), 0, 0)
		local F1 = A0 * CFrame.Angles(0, (rad(8) * t) % TAU, 0) * TILT33
		local F2 = F1 * CFrame.Angles(rad(57) + rad(18) * sin(TAU * t / 19), 0, 0)
		local F3 = F2 * CFrame.Angles(0, rad(23.4) + rad(14) * sin(TAU * t / 27 + 1.1), 0)
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
						local a = SHARD_A[i]
						local sp = K * Vector3.new(14 * sin(a), 14 * cos(a), 0)
						c = CFrame.new(sp + (c.Position - sp) * easeOutBack(u)) * c.Rotation
					end
				end
				GCF[GSHARD + 1 + i] = c
			end
		end

		-- 5. the balance: moon and void on the viewer's left and right of an invisible beam, rocking like scales
		local sway = asm and smooth((age - 1.8) / 1.2) or 1
		local Pv = V * CFrame.new(0, 6.0, 1.5) * CFrame.Angles(0, 0, rad(10) * sin(TAU * t / 10) * sway)
		local moonC = Pv * Vector3.new(-12.5, 0, 0)
		local voidC = Pv * Vector3.new(12.5, 0, 0)
		local focus = O + Vector3.new(0, 1, 0)
		if asm and age < 1.8 then
			local sp = V * Vector3.new(-12.5, -9, 1.5) -- (the moon rises out of the dais)
			moonC = sp + (moonC - sp) * easeOutBack((age - 0.6) / 1.2)
		end
		GCF[GMOON] = CFrame.lookAt(moonC, focus)
		GCF[GVOID] = CFrame.lookAt(voidC, focus)
		-- the void's camera-facing details: the photon ring sits on the silhouette circle the camera sees (radius rt)
		local dv = camPos - voidC
		local dm = dv.Magnitude
		local nrm = dm > 1e-3 and dv / dm or -V.LookVector
		local dc = max(dm, 5)
		local up = abs(nrm.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis
		rt = 4 * sqrt(1 - 16 / (dc * dc))
		GCF[GPF] = CFrame.lookAt(voidC + nrm * (16 / dc), voidC, up)
		GCF[GHF] = CFrame.lookAt(voidC + nrm * 4.1, voidC, up)
		local Dk = CFrame.new(voidC) * V.Rotation * TILT15
		if asm then accExtra = (accExtra + rad(360 * exp(-3 * max(0, age - 0.3))) * dt * dir) % TAU end
		GCF[GACC] = Dk * CFrame.Angles(0, (rad(40) * now * dir + accExtra) % TAU, 0)
		GCF[GSWIRL] = Dk * CFrame.Angles(0, (rad(85) * now * dir) % TAU, 0)
		local az = atan2(voidC.X - O.X, voidC.Z - O.Z)
		GCF[GRIBEND] = Gd * CFrame.new(13.2 * sin(az), 0.3, 13.2 * cos(az)) * CFrame.Angles(0, az, 0)
		GCF[GFEED] = CFrame.lookAt(K * FEED_PT, voidC)

		-- 6. the air and the palms
		local camDist = (camPos - O).Magnitude
		GCF[GAIR] = CFrame.new(O + Vector3.new(0, 4, 0))
		GCF[GBOKEH] = V * CFrame.new(0, 3.0, min(7.5, camDist - 4))
		local f = W.RightVector:Dot(V.RightVector)
		local flip = (f > 0.2 and assign ~= 1) and 1 or (f < -0.2 and assign ~= -1) and -1 or nil
		if flip then assign = flip end
		local moonSide = -assign
		local mA, vA = palmFor(moonSide, moonCarA), palmFor(-moonSide, voidCarA)
		GCF[GPALMM] = mA ~= moonCarA and CFrame.new(mA.WorldPosition) or W * CFrame.new(2.3 * moonSide, -0.3, -0.5)
		GCF[GPALMV] = vA ~= voidCarA and CFrame.new(vA.WorldPosition) or W * CFrame.new(-2.3 * moonSide, -0.3, -0.5)

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
		if flip then
			B1.Attachment1 = mA
			if B2 then B2.Attachment1 = mA end
			B3.Attachment1 = vA
			if B4 then B4.Attachment1 = vA end
		end
		local a = s.alpha
		local on = a >= 0.6
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
			-- the assembly has ended (snap everything to rest) or the framework is fading the aura out
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
		-- near-camera rules (with hysteresis): no rings or bokeh blobs across the lens
		if CONFIG.NEAR_HIDE then
			local dA = (camPos - A0.Position).Magnitude
			if (not armHidden and dA < 7) or (armHidden and dA > 8) then
				armHidden = not armHidden
				setGroups()
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "09_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
