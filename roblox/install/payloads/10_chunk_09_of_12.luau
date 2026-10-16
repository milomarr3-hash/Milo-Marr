-- AuraRNG Studio install kit | 10_chunk_09_of_12.luau | step 10: piece 9 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (154908 bytes, checksum 840125961).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "10_chunk_09_of_12.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-154908-840125961-12-402748328"
local NEW_LEN, NEW_SUM = 154908, 840125961
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
local LENS = { 13303, 13296, 13287, 13167, 13232, 13273, 13188, 13300, 13244, 13299, 13292, 9027 }
local SUMS = { 67409079, 948660274, 266404745, 816058228, 63700756, 500498415, 756191201, 562959745, 92959190, 314875523, 46584231, 495884184 }

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
-- piece 9 of 12 of the new source (13244 bytes, checksum 92959190, long bracket level 0)
local DATA = [[
	end)
	-- this wearer's dais sits a hair above (or below) the others', so two pools side by side never share a plane (Roblox
	-- z-fights coplanar faces as a crawling shimmer). The layer surfaces repeat every 0.055 studs (engraving, base,
	-- floor), so the three lifts are a third of that apart: your own pool on top (0.037), other players 0 or 0.018, so where
	-- two pools overlap yours is the one you see.
	do
		local uid = 0
		pcall(function()
			local plr = Players:GetPlayerFromCharacter(char)
			uid = plr and plr.UserId or #char.Name
		end)
		st.layer = ctx.isLocal and 0.0366 or 0.0183 * (uid % 2)
	end

	---------------------------------------------------------------- the wearer's own screen grade (real equips only)
	-- It starts with the first frame the player can actually see (not while the roll cutscene still holds the camera), eases
	-- back when the assembly ends, and never snaps: hiding or unequipping eases it out too.
	local grade
	st.gradeWanted, st.builtAt = CONFIG.GRADE and ctx.isLocal, os.clock()
	local function gradeTo(target, dur, thenDestroy)
		if not grade then return end
		if gradeOwner ~= st then
			grade = nil -- (another build took the grade over since: it is theirs to ease out)
			return
		end
		if liveGradeTween then liveGradeTween:Cancel() end
		liveGradeTween = TweenService:Create(grade, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), target)
		liveGradeTween:Play()
		if thenDestroy then
			gradeToken += 1
			local tok, g = gradeToken, grade
			grade = nil -- (this aura lets go of it; a new equip within the fade takes it over instead of stacking a second one)
			task.delay(dur + 0.05, function()
				if gradeToken == tok and liveGrade == g then
					g:Destroy()
					liveGrade, liveGradeTween, gradeOwner = nil, nil, nil
				end
			end)
		end
	end

	---------------------------------------------------------------- state
	local fx = {}
	local remote = not ctx.isLocal
	local age = (CONFIG.ASSEMBLY and (CONFIG.ASSEMBLY_REMOTE or not remote)) and 0 or ASM_END
	local VIEWER = CONFIG.VIEWER_ANCHOR
	local near, visible, armHidden, bokehNear, grounded = true, true, false, false, true
	local alphaW, alphaOn, settled = -1, false, false
	local nq, nightClock = -1, 0
	local nextEmit = 1
	local accExtra, voidD = 0, (age >= ASM_END) and 8 or 0.6
	local rt = 3.9
	local daisY, lastGroundY = nil, nil
	st.ltmOn, st.hlF, st.lightsOn, st.haloZ, st.hlA, st.fb, st.lod = false, -1, false, 1, 0, 0, 1
	if age >= ASM_END then void.Size = voidSize else void.Size = voidSize * (0.6 / 8) end

	---------------------------------------------------------------- event writes (never per frame in steady state)
	local function refreshEmitters()
		for _, e in ipairs(emitters) do
			local want = e[4] and near and alphaOn
			local kind = e[3]
			if kind == "ground" then want = want and grounded
			elseif kind == "bokeh" then want = want and not bokehNear
			elseif kind == "body" then want = want and visible and st.footOk and not st.fpOn -- (they live on the character)
			elseif kind == "nearcam" then want = want and not st.fpOn -- (the funnel and palm streaks and the air's sparkles: round the lens)
			elseif kind == "speed" then want = want and st.speedOn end
			if e[6] and st.ghostGui and not st.fxLtm then want = false end -- (a ghosted aura without emitter LTM: smoke off)
			if want ~= e[5] then
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
