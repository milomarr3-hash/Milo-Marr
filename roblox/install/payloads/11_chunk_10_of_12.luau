-- AuraRNG Studio install kit | 11_chunk_10_of_12.luau | step 11: piece 10 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (148303 bytes, checksum 731942170).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "11_chunk_10_of_12.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-148303-731942170-12-824555251"
local NEW_LEN, NEW_SUM = 148303, 731942170
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
local LENS = { 13300, 13224, 13240, 13242, 13194, 13235, 13276, 13235, 13290, 13298, 13282, 2487 }
local SUMS = { 825733820, 782681153, 524531706, 656635892, 998587156, 867606918, 526087852, 254541497, 6651690, 395645774, 897444566, 313496838 }

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
-- piece 10 of 12 of the new source (13298 bytes, checksum 395645774, long bracket level 0)
local DATA = [[
			-- beside and behind the view instead of filling it when the player turns; straight above it holds still
			if dh > 1.5 and dh > 0.2 * abs(v.Y) then
				yawTarget = atan2(-v.X, -v.Z)
			elseif cam and abs(v.Y) < 4 then
				local lk = cam.CFrame.LookVector
				if abs(lk.Y) < 0.97 then yawTarget = atan2(-lk.X, -lk.Z) end
			end
			if snap then psi, psiVel = yawTarget, 0 end
			local k = CONFIG.YAW_SPRING
			local x = wrapPi(psi - yawTarget)
			local e = exp(-k * dt)
			local tmp = (psiVel + k * x) * dt
			x = (x + tmp) * e
			psiVel = (psiVel - k * tmp) * e
			-- a fast camera swing never throws the clock and the orbs round into the lens: the spring runs on underneath, but
			-- the lag that is shown eases into a ceiling of YAW_LAG_MAX (and the spring itself stops at twice that)
			local L = rad(CONFIG.YAW_LAG_MAX)
			if x > 2 * L then
				x, psiVel = 2 * L, min(psiVel, 0)
			elseif x < -2 * L then
				x, psiVel = -2 * L, max(psiVel, 0)
			end
			psi = wrapPi(yawTarget + x)
			if psi ~= psi or psiVel ~= psiVel then psi, psiVel, x = yawTarget, 0, 0 end
			V = CFrame.new(O) * CFrame.Angles(0, yawTarget + L * math.tanh(x / L), 0)
		else
			V = W * FLIP
		end

		-- the dais: stays on the ground for walks and jumps (even Roblox's default 7.2-stud jump), floats under a flyer, and on
		-- a seat sits at the feet line instead of on the seat. It drops at once (no lag walking downhill), rises gently
		local feetY = cf.Position.Y - s.legLen
		local gnd = s.ground
		local hG = gnd and (feetY - gnd.Y)
		local isGrounded = hG ~= nil and hG < (grounded and CONFIG.AIR_ON or CONFIG.AIR_OFF)
		local target
		if isGrounded then
			if seated then
				target = min(gnd.Y, feetY)
			else
				target = gnd.Y
				lastGroundY = target
			end
		elseif CONFIG.DAIS_FLOAT or not lastGroundY then
			target = feetY + s.hover - 2.4
		else
			target = lastGroundY
		end
		if target ~= target then target = daisY or O.Y - 3 end
		if snap then daisY = nil end
		if daisY then daisY += (target - daisY) * (1 - exp(-(target < daisY and 30 or 8) * dt)) else daisY = target end
		local dY = daisY + st.layer
		-- on a slope (a hillside, a beach, a ramp) the pool lies along the ground: a plane through three rays round the
		-- wearer, every 0.2 s while standing on it, accepted only when it is a clean slope through the ground under the
		-- wearer (stairs, cliff edges, other players: it stays level). It tilts over smoothly; flying or seated it is level
		if isGrounded and not seated then
			st.gpT -= dt
			if st.gpT <= 0 then
				st.gpT = 0.2
				local nT = Vector3.yAxis
				local gp = hosts.gp
				local h1 = workspace:Raycast(Vector3.new(O.X + 9 * sin(yawW), dY + 4, O.Z + 9 * cos(yawW)), DOWN9, gp)
				local h2 = h1 and workspace:Raycast(Vector3.new(O.X + 9 * sin(yawW + 2.0944), dY + 4, O.Z + 9 * cos(yawW + 2.0944)), DOWN9, gp)
				local h3 = h2 and workspace:Raycast(Vector3.new(O.X + 9 * sin(yawW + 4.1888), dY + 4, O.Z + 9 * cos(yawW + 4.1888)), DOWN9, gp)
				if h3 then
					local p1 = h1.Position
					local nn = (h2.Position - p1):Cross(h3.Position - p1)
					if nn.Magnitude > 1e-3 then
						nn = nn.Unit
						if nn.Y < 0 then nn = -nn end
						if nn.Y >= 0.94 and abs((gnd - p1):Dot(nn)) < 0.6 then nT = nn end -- (at most 20°, through the ground underfoot)
					end
				end
				st.gnT = nT
			end
		else
			st.gnT = Vector3.yAxis
		end
		local gn = snap and st.gnT or st.gn + (st.gnT - st.gn) * (1 - exp(-4 * dt))
		gn = gn.Magnitude > 1e-3 and gn.Unit or Vector3.yAxis
		st.gn = gn
		local slopeT = gn.Y < 0.99996 and sqrt(1 - gn.Y * gn.Y) / gn.Y or 0 -- (tan of the tilt; under 0.5° it stays level)
		local Gd = CFrame.new(O.X, dY, O.Z)
		if slopeT > 0 then Gd *= CFrame.fromAxisAngle(Vector3.yAxis:Cross(gn).Unit, math.acos(gn.Y)) end
		-- the height the clock and the balance ride: a heavy spring, so a jump (or a step) does not throw a 28-stud watch
		-- up and down with the body; it catches up fast when flying or sitting
		if snap or not st.kY then
			st.kY, st.kYv = O.Y, 0
		else
			local kk = (isGrounded and not seated) and 4 or 12
			local x = st.kY - O.Y
			local e = exp(-kk * dt)
			local tmp = (st.kYv + kk * x) * dt
			x = (x + tmp) * e
			st.kYv = (st.kYv - kk * tmp) * e
			st.kY = O.Y + x
		end
		local Vk = V + Vector3.new(0, st.kY - O.Y, 0)

		-- the clock: lower, further back and leaning back when the camera is close; behind the seat when sitting; never into
		-- the dais (its lowest edge stays 0.24 above the dais rim's top, 0.54 above the floating galaxy layers)
		local sitT = st.sitT
		local Hc = CONFIG.CLOCK_HEIGHT - 0.5 * g - 3 * cz + 16 * fp - 3 * sitT
		local Dc = CONFIG.CLOCK_DIST + 2 * g + (remote and CLOSE.distRemote or CLOSE.dist) * cz + 6 * fp - 2 * sitT
		local tilt = rad(clamp(CONFIG.CLOCK_TILT + 14 * g + 4 * st.speedT + CLOSE.tilt * cz - 32 * fp, -10, 50))
		-- (its lowest point is the bezel's back edge when it leans back, its front edge when it leans forward)
		local minHc = dY + 1.2 - st.kY + 14.2 * cos(tilt) + (tilt >= 0 and 1.44 or 1.12) * abs(sin(tilt))
		if Hc < minHc then Hc = minHc end
		-- the owner's camera: the clock steps back along the view until FRAME_TOP above its hub (the XII numeral: the hands
		-- at midnight) is inside the top of the frame, at every zoom and camera tilt players use; looking steeply down it
		-- settles at most CLOSE.dist further back. It glides there (never jumps) and is off in first person
		local ft = (ctx.isLocal and cam) and CONFIG.FRAME_TOP or 0
		if ft > 0 then
			local lim = min(1.45, asin(clamp(cam.CFrame.LookVector.Y, -1, 1)) + rad(cam.FieldOfView) * 0.455) -- (the frame's top edge, less a margin)
			local push = clamp((st.kY + Hc + ft * cos(tilt) - camPos.Y) / max(tan(lim), 0.05) - dh - ft * sin(tilt) - Dc, 0,
				CLOSE.dist + 1.1 * max(0, ft - 9.6)) * (1 - fp)
			st.fitD = snap and push or st.fitD + (push - st.fitD) * (1 - exp(-3 * dt))
			Dc += st.fitD
		end
		-- on a slope that rises behind the wearer it stands on the rising ground, at most 4 studs up (higher would lift it
		-- out of the view; a steeper hill may hide its foot)
		local vl = V.LookVector
		if slopeT > 0 then
			local rise = -(gn.X * vl.X + gn.Z * vl.Z) / gn.Y
			if rise > 0 and Hc < minHc + min(4, rise * Dc) then Hc = minHc + min(4, rise * Dc) end
		end
		-- another wearer's clock and orbs step back behind your own clock instead of standing in front of it (decided
		-- below, one frame late: a spring, so they glide)
		Dc += st.yieldD
		local K = Vk * CFrame.new(0, Hc, -Dc) * CFrame.Angles(0, rad(9 + 5 * sin(TAU * t / 16)), 0) * CFrame.Angles(-tilt, 0, 0)
		GCF[GK] = K
		if not remote then ownerHub = K.Position end

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
