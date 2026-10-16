-- AuraRNG Studio install kit | 10_chunk_09_of_12.luau | step 10: piece 9 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (151582 bytes, checksum 322184148).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "10_chunk_09_of_12.luau"
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

local K = 9
-- piece 9 of 12 of the new source (13301 bytes, checksum 56580994, long bracket level 0)
local DATA = [[
				e[1].Enabled = want
				e[5] = want
			end
		end
	end
	-- the beams: the near-only ones fade out past ~110 studs (and the far beacon in), the palm streams switch off in first
	-- person (they would converge on hands just under the lens); written only when they change
	local function refreshBeams()
		local lod = st.lod
		for _, b in ipairs(beams) do
			local want = true
			if b[8] then want = lod > 0 elseif b[9] then want = lod < 1 end
			if b[10] and st.fpOn then want = false end
			if not b[9] and st.ghostGui and not st.fxLtm then want = false end
			if want ~= b[11] then
				b[1].Enabled = want
				b[11] = want
			end
		end
	end
	-- the beam fade steps: each beam's Transparency is one of its 21 precomputed sequences (no allocation); fa is the
	-- framework's fade, and while the aura assembles each beam fades in over 0.8 s from its own time
	local function beamSteps(fa)
		st.fb = fa
		local lod = st.lod
		local asm = age < ASM_END
		for _, b in ipairs(beams) do
			local f = fa
			if asm then f *= smooth((age - b[12]) / 0.8) end
			if b[8] then f *= lod elseif b[9] then f *= 1 - lod end
			local q = clamp(math.floor(f * 20 + 0.5), 0, 20)
			if q ~= b[3] then
				b[1].Transparency = b[2][q]
				b[3] = q
			end
		end
	end
	-- the lights: brightness fades with the assembly, the night, the framework's alpha and the far-detail fade; written
	-- only when it changes; switched on and off only while dark (Brightness 0), so a light never pops
	local function lightLevels()
		local l = max(nq, 0) * st.lod
		if keyLight then
			local b = 1.5 * l * max(st.kf, 0)
			if b ~= st.kB then
				keyLight.Brightness = b
				st.kB = b
			end
		end
		if wheelLight then
			local b = 0.9 * l * max(st.wf, 0)
			if b ~= st.wB then
				wheelLight.Brightness = b
				st.wB = b
			end
		end
	end
	local function refreshLights()
		local on = visible and nq > 0 and st.lod > 0
		if on ~= st.lightsOn then
			st.lightsOn = on
			if keyLight then keyLight.Enabled = on end
			if wheelLight then wheelLight.Enabled = on end
		end
		refreshBeams()
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
	-- the Highlight's fill and outline strength (1 - transparency) at night factor q. The ink outline is for the bright sky
	-- at a distance: close up (Roblox's default zoom) the metal fills the view and reads by its own shading, so the outline
	-- eases off (czq: the camera-closeness factor in 0.05 steps)
	-- (by day the close camera sees the rings and bezel against the cyan sky and grass, which lift green as much as blue:
	-- the fill strengthens close up, in the same zoom steps, so the silver stays neutral)
	local function hlFill(q) return min(1, (1 - CONFIG.HIGHLIGHT_FILL) * (1 + 0.45 * st.czq)) * (1 - q) + 0.20 * q end
	local function hlOut(q) return (1 - CONFIG.HIGHLIGHT_OUTLINE) * (1 - 0.6 * st.czq) * (1 - q) + 0.30 * q end
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
