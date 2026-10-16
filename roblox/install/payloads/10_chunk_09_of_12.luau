-- AuraRNG Studio install kit | 10_chunk_09_of_12.luau | step 10: piece 9 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (148303 bytes, checksum 731942170).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "10_chunk_09_of_12.luau"
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

local K = 9
-- piece 9 of 12 of the new source (13290 bytes, checksum 6651690, long bracket level 0)
local DATA = [[
	-- the Highlight follows its fade (st.hlA: assembly x alpha), the night, the camera closeness and, for another player's
	-- aura, the far-detail fade; fill and outline are each written only when they moved (snapped exactly at the ends)
	local function toneLevels(thr)
		if not tone then return end
		local fh = st.hlA * (remote and st.lod or 1)
		local q = max(nq, 0)
		local fill, out = 1 - hlFill(q) * fh, 1 - hlOut(q) * fh
		local edge = fh <= 0 or fh >= 1
		if fill ~= st.hlF and (abs(fill - st.hlF) >= thr or edge) then
			tone.FillTransparency = fill
			st.hlF = fill
		end
		if out ~= st.hlO and (abs(out - st.hlO) >= thr or edge) then
			tone.OutlineTransparency = out
			st.hlO = out
		end
	end
	-- (one rule for the Highlight's slot: off while ghosted, and off for another player's aura once it is far away, which
	-- frees one of the client's 31 Highlights and its outline pass)
	local function toneOn()
		if tone then
			local on = st.ghostQ <= 0 and (ctx.isLocal or st.lod > 0) -- (off from the first ghost step: it would paint the ghost solid)
			if tone.Enabled ~= on then tone.Enabled = on end
		end
	end
	local function applyLod()
		lightLevels()
		refreshLights()
		beamSteps(st.fb)
		toneLevels(0)
		toneOn()
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
		if hosts.beaconBeam then hosts.beaconBeam.Color = ColorSequence.new(INK:Lerp(WHITE, q)) end
		lightLevels()
		if em.bokeh then em.bokeh.Rate = 0.5 + 0.7 * q end
		if haloEntry then haloEntry[2] = 1 - (0.35 + 0.2 * q) * st.haloZ end
		if corona then
			coronaEntry[2] = 1 - 0.4 * q
			corona.Enabled = q > 0.05 and not st.ghostGui
		end
		if settled then
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
		if st.gradeWanted and not st.gradeStarted and age < 4.5 then -- (not when the assembly is nearly over)
			st.gradeStarted = true
			local camG = workspace.CurrentCamera
			-- (not for a character that has just spawned or respawned: a reset rebuilds the aura on the new character, which
			-- is not an equip. Decided here rather than at build, when every CharacterAdded handler has run; and with a
			-- 12 s window, as the framework may build only once the avatar has loaded)
			local sa = spawnedAt[char]
			if (sa and st.builtAt - sa < 12) or (ownGone and ownGoneChar[1] ~= char and st.builtAt - ownGone < 15) then
				st.gradeWanted = false
			elseif camG and camG.CameraType == Enum.CameraType.Scriptable then
				st.gradeStarted = false
			elseif camG then
				if liveGrade and liveGrade.Parent then
					grade = liveGrade -- (an earlier equip's grade still easing out: take it over, never stack a second one)
				else
					grade = new("ColorCorrectionEffect", { Name = "TheEndReveal" }, camG)
					liveGrade = grade
				end
				gradeOwner = st
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
		-- (a teleport, to another island or a lobby pad: everything starts where it belongs instead of springing across)
		if lastO and ((O - lastO).Magnitude >= 30 or abs(O.Y - lastO.Y) > 8) then snap = true end
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
