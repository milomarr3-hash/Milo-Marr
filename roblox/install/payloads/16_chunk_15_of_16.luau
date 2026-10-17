-- AuraRNG Studio install kit | 16_chunk_15_of_16.luau | step 16: piece 15 of 16
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (198845 bytes, checksum 17952987).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "16_chunk_15_of_16.luau"
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

local K = 15
-- piece 15 of 16 of the new source (13201 bytes, checksum 814892809, long bracket level 1)
local DATA = [=[
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
			em.smoke.Rate = slow and (low and 1 or 1.5) or (low and 4 or 8)
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
			if occA then st.armHold = 0.6 elseif st.armHold > 0 then st.armHold -= dt end
			local tgtA = st.armHold > 0 and 1 or 0
			if st.armG ~= tgtA then
				st.armG = tgtA > st.armG and min(1, st.armG + 5 * dt) or max(0, st.armG - 5 * dt)
				local qa = math.floor(st.armG * 3 + 0.5) / 3
				if qa ~= st.armGQ then
					st.armGQ = qa
					writeRings()
				end
			end
		elseif not VIEWER and ctx.isLocal then
			-- body-anchored fallback: the owner sees through the clock while it stands between the camera and the head
			local head = O + Vector3.new(0, 2, 0)
			local nz = K.LookVector
			local d0, d1 = (camPos - K.Position):Dot(nz), (head - K.Position):Dot(nz)
			local cross = false
			if d0 * d1 < 0 then
				local hit = camPos + (head - camPos) * (d0 / (d0 - d1))
				cross = (hit - K.Position).Magnitude < 14
			end
			if cross ~= st.ltmOn then
				st.ltmOn = cross
				for _, p in ipairs(clockParts) do p.LocalTransparencyModifier = cross and 0.5 or 0 end
				-- (GUIs ignore LocalTransparencyModifier: the dial's inlay, star window and sub-dial switch off meanwhile)
				hosts.inlayGui.Enabled, hosts.subdialGui.Enabled, hosts.plateGui.Enabled = not cross, not cross, not cross
				if hosts.bandGui then hosts.bandGui.Enabled = not cross end
				if hosts.trailGui then hosts.trailGui.Enabled = not cross end
			end
		end
		-- (a state that went NaN anyway, e.g. a physics fling the guard above did not catch: start everything again where it
		-- belongs next frame, instead of every part drifting off for the rest of the session)
		if st.zoomD ~= st.zoomD or st.kY ~= st.kY or daisY ~= daisY or st.lift ~= st.lift or st.fitD ~= st.fitD or st.yieldD ~= st.yieldD
			or st.gn.Y ~= st.gn.Y then
			st.snap, st.fitD, st.yieldD, st.yieldT, st.gn, st.gnT = true, 0, 0, 0, Vector3.yAxis, Vector3.yAxis
		end
		nightClock += dt
		if nightClock >= CONFIG.NIGHT_INTERVAL then
			nightClock = 0
			local q = nightStep()
			if q ~= nq then
				-- (at most 0.05 per tick, so dusk never steps)
				if q > nq + 0.05 then q = math.floor((nq + 0.05) * 20 + 0.5) / 20
				elseif q < nq - 0.05 then q = math.floor((nq - 0.05) * 20 + 0.5) / 20 end
				applyNight(q)
			end
		end
	end

	function fx.setVisible(on)
		if destroyed or on == visible then return end
		visible = on
		if on then
			-- (parented again by the next update, together with that frame's positions; after a long hide it fades back in
			-- instead of popping, and the body's wisps and sparks wait a second)
			st.pendingRoot = true
			st.shownAt = os.clock()
			st.lastO = nil -- (the distance walked while hidden is not a speed)
			if st.hiddenAt and st.shownAt - st.hiddenAt > 0.5 then
				st.revealA, st.snap = 0, true
				if nq >= 0 then applyNight(nightStep()) end -- (dusk may have passed meanwhile; the reveal starts from nothing)
			end
		else
			root.Parent = nil
			st.pendingRoot = false
			st.hiddenAt = os.clock()
			if not remote then ownerHub = nil end -- (other wearers no longer step back for a clock you cannot see)
			st.footOk = false
			if grade then
				-- (never left on top of a cutscene or a hidden aura)
				st.gradeOut = true
				gradeTo(GRADE_OFF, 0.4, true)
			end
			if st.bloom or st.fov0 then hosts.screenOff() end -- (pass 5.2: nor the reveal's bloom or push-in, once started)
		end
		refreshEmitters()
		refreshLights()
	end

	function fx.setDetail(isNear)
		if destroyed then return end
		near = isNear
		if isNear then st.pendingGroups = true else setGroups() end -- (shown again by the next update, at fresh positions)
		refreshEmitters()
		refreshLights()
	end

	function fx.destroy()
		if destroyed then return end
		destroyed = true
		if grade then gradeTo(GRADE_OFF, 0.8, true) end -- (the screen eases back instead of snapping)
		hosts.screenOff() -- (pass 5.2: the reveal's bloom goes and the field of view is given back)
		if ctx.isLocal then
			ownGone, ownGoneChar[1] = os.clock(), char -- (a respawn's rebuild within seconds is not an equip: no grade)
			ownerHub = nil
		end
		for h = 1, 4 do
			for _, hp in ipairs(holders[h]) do hp[1]:Destroy() end -- (also the groups hidden by far LOD or the near rule)
		end
		root:Destroy()
		for _, o in ipairs(charStuff) do o:Destroy() end
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "18_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
