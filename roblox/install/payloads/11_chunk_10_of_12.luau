-- AuraRNG Studio install kit | 11_chunk_10_of_12.luau | step 11: piece 10 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (151582 bytes, checksum 322184148).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "11_chunk_10_of_12.luau"
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

local K = 10
-- piece 10 of 12 of the new source (13300 bytes, checksum 674174262, long bracket level 0)
local DATA = [[
					st.tdir = st.tdir and (st.tdir + (u - st.tdir) * (1 - exp(-4 * dt))) or u
				end
			end
		end
		local fast = (st.speedOn and st.speed > 8) or st.speed > 12
		if fast ~= st.speedOn then
			st.speedOn = fast
			refreshEmitters()
		end
		st.speedT += ((fast and 1 or 0) - st.speedT) * (1 - exp(-3 * dt))
		local seated = ctx.hum ~= nil and ctx.hum.Sit == true
		if seated ~= st.seated then
			st.seated = seated
			refreshEmitters()
		end
		st.sitT += ((seated and 1 or 0) - st.sitT) * (1 - exp(-5 * dt))

		-- 1. frames: the wearer (W), this client's viewer (V), the dais, the clock (K)
		local lv = cf.LookVector
		yawW = wrapPi(yawW + wrapPi(atan2(-lv.X, -lv.Z) - yawW) * (1 - exp(-5 * dt)))
		local W = CFrame.new(O) * CFrame.Angles(0, yawW, 0)
		local cam = workspace.CurrentCamera
		local camPos = lastCamPos
		if cam then
			local cp = cam.CFrame.Position
			if cp.X == cp.X and cp.Y == cp.Y and cp.Z == cp.Z then
				camPos = cp
				lastCamPos = cp
			end
		end
		local v = O - camPos
		local dh = sqrt(v.X * v.X + v.Z * v.Z)
		-- how close the camera is (smoothed): under ZOOM_FAR studs the layout eases into its close-camera form, so at Roblox's
		-- default zoom the whole dial and both orbs are on screen; in first person the owner's clock rises into the sky
		st.zoomD = snap and dh or st.zoomD + (dh - st.zoomD) * (1 - exp(-3 * dt))
		local cz = smooth((CONFIG.ZOOM_FAR - st.zoomD) / (CONFIG.ZOOM_FAR - CONFIG.ZOOM_NEAR))
		local fp = (ctx.isLocal and CONFIG.FIRST_PERSON_LIFT) and smooth((4 - st.zoomD) / 2.5) or 0
		local czq = math.floor(cz * 20 + 0.5) / 20
		if czq ~= st.czq then
			st.czq = czq
			toneLevels(0) -- (close up the ink outline eases off and the silver fill strengthens)
			-- (the floor's twinkles: one size step at a time, each a band past its threshold, so a camera resting near one
			-- never flips them back and forth)
			local mi = st.moteI
			while mi < 5 and czq >= MOTE_T[mi] + 0.05 do mi += 1 end
			while mi > 1 and czq <= MOTE_T[mi - 1] - 0.05 do mi -= 1 end
			if mi ~= st.moteI then
				st.moteI = mi
				em.motes.Size = hosts.moteSizes[mi]
			end
			if hosts.lensTop then
				-- (the lensed band slims as the camera comes close: at the default zoom a full-width band reads as a crescent)
				local k = 1 - 0.45 * czq
				hosts.lensTop.Width0, hosts.lensTop.Width1 = 1.5 * k, 1.5 * k
				hosts.lensBot.Width0, hosts.lensBot.Width1 = 0.8 * k, 0.8 * k
			end
		end
		if haloEntry then
			-- (the white ball's soft halo fades out as the camera comes close, where the leaning dial plane would cut it)
			local hz = math.floor((1 - smooth((cz - 0.3) / 0.4)) * 10 + 0.5) / 10
			if hz ~= st.haloZ then
				st.haloZ = hz
				haloEntry[2] = 1 - (0.35 + 0.2 * max(nq, 0)) * hz
				if settled then
					local tr = 1 - (1 - haloEntry[2]) * alphaW
					haloIm.ImageTransparency = tr
					haloEntry[5] = tr
				end
			end
		end
		local V
		if VIEWER then
			-- the clock swings to the far side of the wearer from this camera through a critically damped spring (no overshoot).
			-- In first person (the camera inside the wearer) "beyond the wearer" is where the camera looks, so the orbs hang
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
