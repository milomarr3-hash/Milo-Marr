-- AuraRNG Studio install kit | 15_chunk_14_of_16.luau | step 15: piece 14 of 16
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (198845 bytes, checksum 17952987).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "15_chunk_14_of_16.luau"
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

local K = 14
-- piece 14 of 16 of the new source (13175 bytes, checksum 102157393, long bracket level 0)
local DATA = [[
		-- toward midnight and stop dead on the stroke: an integrated extra angle, so nothing jumps)
		local gm = st.gearM
		for _, gd in ipairs(gearData) do
			local x, y, z = gd.cx, gd.cy, gd.cz
			if gm ~= 1 then gd.extra = (gd.extra + rad(gd.rate) * (gm - 1) * dt) % TAU end
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
			-- (pass 5.2) the hands spin in to five to midnight; the minute hand then steps to XII a minute at a time, each
			-- step a quick tick that seats with a hair of overshoot, and the fifth tick is midnight: the peak. The hour hand
			-- creeps its last 2.5 degrees meanwhile
			local kk = 1 - easeOutBack((age - 3.6) / 1.2)
			local mt = 0
			for j = 0, 4 do mt += easeOutBack((age - (PEAK - 1.6 + 0.4 * j)) / 0.14) end
			th = -rad(330) * kk - rad(2.5) * (1 - smooth((age - 5.0) / 1.6))
			tm, ts = -rad(1050) * kk - rad(6) * (5 - mt), ts - rad(720) * kk
			crownY = 6 * (1 - easeOutBack((age - 4.2) / 0.6))
		end
		GCF[GHOUR] = K * CFrame.Angles(0, 0, -th) * CFrame.new(0, 0, 0.85)
		GCF[GMIN] = K * CFrame.Angles(0, 0, -tm) * CFrame.new(0, 0, 1.15)
		GCF[GSEC] = K * CFrame.Angles(0, 0, -ts) * CFrame.new(0, 0, 1.42)
		GCF[GDUST] = K * CFrame.new(0, 0, 1.3) * CFrame.Angles(0, 0, -((rad(20) * now) % TAU)) -- (the time-dust ring turns clockwise)
		GCF[GCROWN] = crownY ~= 0 and K * CFrame.new(0, crownY, 0) or K
		-- (pass 5.2) the bezel's engraving creeps round anticlockwise, a degree a second; the trail rides the seconds hand
		-- (or the reveal's sweep); the burst ring turns slowly round the dial's axis
		if hosts.band then GCF[G2.BAND] = K * CFrame.Angles(0, 0, (rad(1) * now) % TAU) * BAND_Z end
		GCF[G2.SUB] = K * CFrame.Angles(0, 0, -((rad(3) * now) % TAU))
		if hosts.secTrail then GCF[G2.TRAIL] = K * CFrame.Angles(0, 0, -(st.trailA or ts)) * TRAIL_Z end
		if hosts.burst then GCF[G2.BURST] = K * BURST_TILT * CFrame.Angles(0, (rad(30) * t) % TAU, 0) end

		-- 3. the dais layers and the balance wheel (just below the soles, never into the galaxy; on the dais when seated)
		local gdir = CONFIG.GALAXY_DIR
		GCF[GDAIS] = Gd
		GCF[GG0] = Gd * CFrame.new(0, 0.15, 0) * CFrame.Angles(0, (rad(-6) * gdir * now) % TAU, 0)
		GCF[GG1] = Gd * CFrame.new(0, 0.42, 0) * CFrame.Angles(0, (rad(9) * gdir * now) % TAU, 0)
		GCF[GG2] = Gd * CFrame.new(0, 0.66, 0) * CFrame.Angles(0, (rad(-16) * gdir * now) % TAU, 0)
		GCF[GENG] = Gd * CFrame.new(0, 0.04, 0) * CFrame.Angles(0, (rad(2.5) * gdir * now) % TAU, 0)
		-- (pass 5.2) the rings of energy turn slowly one way, the fine swirl fast the other; the spiral arms' host turns
		-- clockwise while their two feeds circle the other way a little faster, so the arms stand still on the floor (they
		-- keep step with it) and the motes stream in along them; the stage sweep turns once in the reveal
		if hosts.rings then GCF[G2.RINGS] = Gd * RINGS_Y * CFrame.Angles(0, (rad(4) * gdir * now) % TAU, 0) end
		if hosts.fine then GCF[G2.FINE] = Gd * FINE_Y * CFrame.Angles(0, (rad(-30) * gdir * now) % TAU, 0) end
		if hosts.sweepGui then GCF[G2.SWEEP] = Gd * SWEEP_Y * CFrame.Angles(0, st.sweepA * gdir, 0) end
		if hosts.spiral then
			GCF[G2.SPIRAL] = Gd * SPIRAL_Y * CFrame.Angles(0, (rad(-42) * gdir * t) % TAU, 0)
			if near then
				local ph = (rad(36) * gdir * t) % TAU
				hosts.spiralA.CFrame = CFrame.Angles(0, ph, 0) * SPIRAL_OUT
				hosts.spiralB.CFrame = CFrame.Angles(0, ph + pi, 0) * SPIRAL_OUT
			end
		end
		GCF[GFUNNEL] = Gd * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, (rad(-70) * CONFIG.FUNNEL_DIR * t) % TAU, 0)
		local wheelAngle = rad(160) * sin(TAU * t / 3.2) * (asm and smooth((age - 4.6) / 1.2) or 1)
		local wheelY = O.Y - s.legLen - 0.9
		wheelY += (dY + 1.2 - wheelY) * sitT
		if wheelY < dY + 1.2 + 2.5 * slopeT then wheelY = dY + 1.2 + 2.5 * slopeT end
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
		local drop = max(6.23 * sqrt(max(0, 1 - n1 * n1)) + 0.09 * abs(n1), 5.54 * sqrt(max(0, 1 - n2 * n2)) + 0.17 * abs(n2),
			4.79 * sqrt(max(0, 1 - n3 * n3)) + 0.08 * abs(n3))
		local baseY = 1.3 - 1.0 * sitT
		local liftT = max(0, dY + 0.96 + 6.3 * slopeT - (O.Y + baseY - drop))
		st.lift = snap and liftT or st.lift + (liftT - st.lift) * (1 - exp(-6 * dt))
		if st.lift < liftT - 0.3 then st.lift = liftT - 0.3 end
		local A0p = O + Vector3.new(0, baseY + st.lift, 0)
		local F1 = CFrame.new(A0p) * R1
		local F2 = CFrame.new(A0p) * R2
		local F3 = CFrame.new(A0p) * R3
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
			-- (pass 5.2) the runners ride the meridian and the equator wherever they are (rising or not), racing in the reveal
			st.run1 = (st.run1 + rad(80) * st.runM * dt) % TAU
			st.run2 = (st.run2 + rad(64) * st.runM * dt) % TAU
			GCF[G2.RUN1] = GCF[GF1] * CFrame.Angles(0, 0, -st.run1)
			GCF[G2.RUN2] = GCF[GF2] * CFrame.Angles(0, 0, st.run2)
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
			-- (pass 5.2: the face librates, rocking 4 degrees either way over 47 s, as the real Moon nods)
			GCF[GMOONF] = CFrame.lookAt(fpos, fpos - fdir, abs(fdir.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis) * CFrame.Angles(0, 0, rad(4) * sin(TAU * t / 47))
		end
		if hosts.moonRing then GCF[G2.MRING] = CFrame.new(moonC) * V.Rotation * MRING_TILT * CFrame.Angles(0, (rad(25) * t) % TAU, 0) end
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
			local hl = low and 2.25 or 1.14
			for _, k in ipairs(hosts.photon) do
				local hy = HAIR[pb][1] * hosts.photonF[k]
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
		-- (pass 5.2) matter falls into the void from all round, turning with its disc
		if hosts.infall then GCF[G2.INFALL] = Dk * SWIRL_UP * CFrame.Angles(0, (rad(60) * now * dir) % TAU, 0) end
		-- the energy links' far ends: on the moon facing IX, on the void facing III, on the floor in front of the clock. Each
		-- link's bow (and the moon's motes' speed) follows its length, written when it changes by a stud or more
		if hosts.linkMoon then
			local ix, iii = K * PORT_IX, K * PORT_III
			local dmi, div = ix - moonC, voidC - iii
			local lm, lvv = dmi.Magnitude, div.Magnitude
			if lm > 0.5 then GCF[G2.LINKM] = CFrame.lookAt(moonC + dmi / lm * 2.9, ix) end
			if lvv > 0.5 then GCF[G2.LINKV] = CFrame.lookAt(voidC - div / lvv * 3.9, voidC) end
			if abs(lm - st.linkLm) >= 1 then
				st.linkLm = lm
				hosts.moonLink.CurveSize0, hosts.moonLink.CurveSize1 = 0.25 * lm, 0.18 * lm
				if em.feed then em.feed.Speed = n(lm / 2.3) end
			end
			if abs(lvv - st.linkLv) >= 1 then
				st.linkLv = lvv
				hosts.voidLink.CurveSize0, hosts.voidLink.CurveSize1 = 0.2 * lvv, 0.25 * lvv
			end
			if hosts.linkFloor then
				local kp = K.Position
				local fd = Vector3.new(kp.X - O.X, 0, kp.Z - O.Z)
				fd = fd.Magnitude > 0.5 and fd.Unit or Vector3.new(vl.X, 0, vl.Z).Unit
				local fpt = Vector3.new(O.X, dY + 0.9, O.Z) + fd * 7
				GCF[G2.LINKF] = CFrame.lookAt(fpt, fpt - fd - Vector3.yAxis)
				local lf = (K * PORT_VI - fpt).Magnitude
				if abs(lf - st.linkLf) >= 1 then
					st.linkLf = lf
					hosts.floorLink.CurveSize0, hosts.floorLink.CurveSize1 = 0.3 * lf, 0.2 * lf
				end
			end
		end

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
