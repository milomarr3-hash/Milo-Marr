-- AuraRNG Studio install kit | 09_chunk_08_of_10.luau | step 9: piece 8 of 10
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (123861 bytes, checksum 523677650).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "09_chunk_08_of_10.luau"
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

local K = 8
-- piece 8 of 10 of the new source (13314 bytes, checksum 22255047, long bracket level 0)
local DATA = [[
			-- (after the assembly the night values are written straight away; during it the fades pick them up)
			local a = alphaW
			if haloEntry then
				local tr = 1 - (1 - haloEntry[2]) * a
				if tr ~= haloEntry[5] then
					haloIm.ImageTransparency = tr
					haloEntry[5] = tr
				end
			end
			if coronaEntry then
				local tr = 1 - (1 - coronaEntry[2]) * a
				if tr ~= coronaEntry[5] then
					coronaEntry[1].ImageTransparency = tr
					coronaEntry[5] = tr
				end
			end
		end
		toneLevels(0)
		refreshLights()
	end
	-- the fades: every part, image, beam and light goes from invisible to its rest value in its own window (times the
	-- framework's fade-in alpha); a value is written only when it moved enough, and snapped exactly at the ends (no blinking)
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
		beamSteps(fb)
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
		local off = q >= 0.5
		if off ~= st.ghostGui then
			st.ghostGui = off
			for _, g in ipairs(ghostGuis) do g.Enabled = not off end
			toneOn()
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
	end
	local function segDist(p, a, ab, len2) -- distance from point p to the segment a -> a + ab
		local t = clamp((p - a):Dot(ab) / len2, 0, 1)
		return (a + ab * t - p).Magnitude
	end

	---------------------------------------------------------------- the frame
	function fx.update(dt, s)
		-- (hidden, e.g. under the roll cutscene's camera, or too far away: nothing advances, so the assembly and the grade
		-- wait for the player, whether or not the framework keeps calling update)
		if destroyed or not visible then return end
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
		if type(a) ~= "number" or a ~= a then a = 1 end
		a = clamp(a, 0, 1)
		local on = a >= 0.6 -- (the emitters follow the framework's fade only: the reveal below starts from an empty sky anyway)
		if st.revealA < 1 then st.revealA = min(1, st.revealA + dt / 0.4) end -- (fading back in after a long hide)
		a *= st.revealA
		-- (the first frame after a long hide: the clock's swing, the zoom layout, the dais and the heights start where they
		-- belong instead of springing in from where they were when the aura was hidden)
		local snap = st.snap
		st.snap = false
		-- (shown again since the last frame: parent it now, so nothing is ever drawn at the positions it had when hidden)
		if st.pendingRoot then
			st.pendingRoot = false
			root.Parent = ctx.container
		end
		if st.pendingGroups then
			st.pendingGroups = false
			setGroups()
		end
		-- the wearer's own grade starts with the first frame they can see (never over a scripted camera, e.g. a cutscene)
		if st.gradeWanted and not st.gradeStarted then
			st.gradeStarted = true
			local camG = workspace.CurrentCamera
			if camG and camG.CameraType == Enum.CameraType.Scriptable then
				st.gradeStarted = false
			elseif camG then
				if liveGrade and liveGrade.Parent then
					grade = liveGrade -- (an earlier equip's grade still easing out: take it over, never stack a second one)
				else
					grade = new("ColorCorrectionEffect", { Name = "TheEndReveal" }, camG)
					liveGrade = grade
				end
				gradeToken += 1
				gradeTo(GRADE_ON, 1.2)
			end
		end
		if grade and not st.gradeOut and age >= 5.8 then
			st.gradeOut = true
			gradeTo(GRADE_OFF, 2.2, true)
		end

		-- 0. the wearer's state: how fast they travel (a teleport is ignored; on the ground only the horizontal speed counts,
		-- so a jump is not a flight), and whether they sit
		local lastO = st.lastO
		st.lastO = O
		if lastO then
			local dO = O - lastO
			if grounded then dO = Vector3.new(dO.X, 0, dO.Z) end
			local d = dO.Magnitude
			if d < 30 and dt > 0 then
				st.speed += (d / dt - st.speed) * (1 - exp(-6 * dt))
				if d / dt > 4 then
					local u = dO / d
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
			camPos = cam.CFrame.Position
			lastCamPos = camPos
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
			toneLevels(0) -- (the ink outline eases off close up)
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
		if snap then daisY = nil end
		if daisY then daisY += (target - daisY) * (1 - exp(-(target < daisY and 30 or 8) * dt)) else daisY = target end
		local dY = daisY + st.layer
		local Gd = CFrame.new(O.X, dY, O.Z)
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
		local minHc = dY + 1.2 - st.kY + 14.2 * cos(tilt) + 1.44 * sin(tilt)
		if Hc < minHc then Hc = minHc end
		local K = Vk * CFrame.new(0, Hc, -Dc) * CFrame.Angles(0, rad(9 + 5 * sin(TAU * t / 16)), 0) * CFrame.Angles(-tilt, 0, 0)
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "12_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
