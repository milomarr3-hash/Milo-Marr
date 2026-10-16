-- AuraRNG Studio install kit | 08_chunk_07_of_10.luau | step 8: piece 7 of 10
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (123861 bytes, checksum 523677650).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "08_chunk_07_of_10.luau"
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

local K = 7
-- piece 7 of 10 of the new source (13298 bytes, checksum 129328051, long bracket level 1)
local DATA = [=[
			-- (te5_ash is one charred flake; its random rotation and tumble make every particle a different shape)
			pe(hosts.floor, "ash5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top, Rate = 8,
				Lifetime = n(3, 4.5), Speed = n(0.8, 2.0), Acceleration = Vector3.new(0, 0.3, 0), Drag = 0.4, Size = n(0.4, 0.6),
				Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.75, 0.2 }, { 1, 1 } }), Color = ColorSequence.new(ASH), Rotation = n(0, 360),
				RotSpeed = n(-90, 90) })
			-- P9: a vortex funnel: streaks spiral inward and climb into the balance wheel
			local p9 = { Rate = 16, Lifetime = n(1.7, 2.0), Speed = n(2.8, 3.2), Acceleration = Vector3.new(0, 1.0, 0),
				Size = seq({ { 0, 0.42 * stS }, { 1, 0.1 * stS } }), Transparency = seq({ { 0, 1 }, { 0.12, 0.05 }, { 0.85, 0.1 }, { 1, 1 } }),
				LockedToPart = true, Orientation = VPAR, Rotation = stRot }
			if CONFIG.SWIRL_POINTS then
				p9.EmissionDirection, p9.SpreadAngle = N_.Front, Vector2.new(0, 10)
				sizeFix(pe(rimPoint(hosts.funnel, 5.3), "streak5", 4.8, p9, WHITE_LE, WHITE_BR), stS, { { 0, 0.42 }, { 1, 0.1 } })
			else
				p9.Shape, p9.ShapeStyle, p9.ShapeInOut, p9.EmissionDirection = CYL, SURFACE, INWARD, N_.Top
				sizeFix(pe(hosts.funnel, "streak5", 4.8, p9, WHITE_LE, WHITE_BR), stS, { { 0, 0.42 }, { 1, 0.1 } })
			end
		end
		-- P10: the palms drink the streams: silver streaks converge into one palm, ink streaks into the other (locked to the
		-- palm, so they still converge on it while the wearer walks). STUDIO-VERIFY: Sphere + Surface + Inward converges on
		-- the centre (fallback: Outward with a negative Speed)
		local function intake(host, color, le, br)
			sizeFix(pe(host, "streak5", 5.2, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = INWARD, Rate = rate(14, 6), Lifetime = n(0.85, 0.95),
				Speed = n(1.35, 1.45), Size = seq({ { 0, 0.3 * stS }, { 1, 0.05 * stS } }), Transparency = seq({ { 0, 1 }, { 0.25, 0.05 }, { 1, 0.2 } }),
				Color = ColorSequence.new(color), ZOffset = 0.2, Orientation = VPAR, Rotation = stRot, LockedToPart = true }, le, br),
				stS, { { 0, 0.3 }, { 1, 0.05 } })
		end
		intake(hosts.palmMoon, WHITE, WHITE_LE, WHITE_BR)
		intake(hosts.palmVoid, INK, nil, nil)
		-- P11: time drips off each sole onto the balance wheel below
		for _, a in ipairs({ soleL, soleR }) do
			if a then
				pe(a, "mote", 5.2, { EmissionDirection = N_.Bottom, Rate = rate(4, 2), Lifetime = n(0.6, 0.8), Speed = n(0.1, 0.3),
					SpreadAngle = Vector2.new(8, 8), Acceleration = Vector3.new(0, -5, 0), Size = seq({ { 0, 0.18 }, { 1, 0.08 } }),
					Transparency = seq({ { 0, 0.1 }, { 0.8, 0.2 }, { 1, 1 } }) }, WHITE_LE, WHITE_BR, "foot")
			end
		end
		-- P12: while the wearer flies or runs fast, silver streaks stream out behind the body (off when slow)
		sizeFix(pe(hosts.trail, "streak5", 5.2, { EmissionDirection = N_.Back, Rate = rate(14, 6), Lifetime = n(0.45, 0.6), Speed = n(4, 6),
			SpreadAngle = Vector2.new(10, 10), Size = seq({ { 0, 0.5 * stS }, { 1, 0.1 * stS } }),
			Transparency = seq({ { 0, 0.2 }, { 0.6, 0.3 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(226, 230, 240)),
			Orientation = VPAR, Rotation = stRot }, WHITE_LE, WHITE_BR, "speed"), stS, { { 0, 0.5 }, { 1, 0.1 } })
		-- which emitters belong to the parts that turn see-through while another wearer's aura is in your way (their smoke,
		-- swirl, dust, shards, glints, horizon and palm streaks must not stay solid across your character)
		local ghostHost = { [moon] = true, [void] = true }
		for _, h in ipairs({ "swirl", "rimGlint", "shardFeed", "horizon", "timeDust", "palmMoon", "palmVoid" }) do
			if hosts[h] then ghostHost[hosts[h]] = true end
		end
		for _, e in ipairs(emitters) do
			local par = e[1].Parent
			if par and par:IsA("Attachment") then par = par.Parent end
			e[6] = ghostHost[par] == true
		end
	end
	table.sort(emitters, function(a, b) return a[2] < b[2] end)

	-- lights: the moon's key light (above) and the wheel's underlight on the feet (night only, high quality)
	local wheelLight = hi and new("PointLight", { Name = "Underlight", Range = 12, Color = Color3.fromRGB(230, 234, 246), Brightness = 0,
		Shadows = false, Enabled = false }, wheelHub)

	---------------------------------------------------------------- the move list (one BulkMoveTo per frame)
	local act, actParts, acf = table.create(NP), table.create(NP), table.create(NP)
	local nAct = 0
	local function rebuildActive()
		table.clear(act)
		table.clear(actParts)
		table.clear(acf)
		nAct = 0
		for i = 1, NP do
			if shownH[PH[i]] then
				nAct += 1
				act[nAct], actParts[nAct], acf[nAct] = i, PP[i], IDENT
			end
		end
	end
	rebuildActive()
	-- the solid parts that turn see-through while another wearer's aura stands between you and your camera: the clock and
	-- the orbs (ghostParts), and on their own the rings (ringParts: a visitor standing beside the wearer looks through
	-- their rings only, never through their clock). The rings also fade out on the near-camera rule.
	local ghostParts, ringParts = {}, {}
	for _, i in ipairs(solids) do
		if PH[i] == ARM or PH[i] == ARMD then
			table.insert(ringParts, PP[i])
		elseif PG[i] <= GHF or PG[i] == GMOONF then
			table.insert(ghostParts, PP[i])
		end
	end
	-- (Beams and ParticleEmitters carry a hidden LocalTransparencyModifier too; if it cannot be written, a ghosted aura's
	-- beams and smoke switch off instead)
	st.fxLtm = pcall(function()
		sb[1].LocalTransparencyModifier = 0
		emitters[1][1].LocalTransparencyModifier = 0
	end)
	-- this wearer's dais sits a hair above (or below) the others', so two pools side by side never share a plane (Roblox
	-- z-fights coplanar faces as a crawling shimmer). The layer surfaces repeat every 0.055 studs (engraving, base,
	-- floor), so the three lifts are a third of that apart: the owner 0, other players 0.018 or 0.037.
	do
		local uid = 0
		pcall(function()
			local plr = Players:GetPlayerFromCharacter(char)
			uid = plr and plr.UserId or #char.Name
		end)
		st.layer = ctx.isLocal and 0 or 0.0183 * (1 + uid % 2)
	end

	---------------------------------------------------------------- the wearer's own screen grade (real equips only)
	-- It starts with the first frame the player can actually see (not while the roll cutscene still holds the camera), eases
	-- back when the assembly ends, and never snaps: hiding or unequipping eases it out too.
	local grade
	st.gradeWanted = CONFIG.GRADE and ctx.isLocal and os.clock() - (spawnedAt[char] or 0) > 4
	local function gradeTo(target, dur, thenDestroy)
		if not grade then return end
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
					liveGrade, liveGradeTween = nil, nil
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
			elseif kind == "foot" then want = want and visible and st.footOk and not st.seated -- (they live on the character)
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
	-- the beam fade steps: each beam's Transparency is one of its 21 precomputed sequences (no allocation)
	local function beamSteps(fb)
		st.fb = fb
		local lod = st.lod
		for _, b in ipairs(beams) do
			local f = fb
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
	local function hlFill(q) return (1 - CONFIG.HIGHLIGHT_FILL) * (1 - q) + 0.20 * q end
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
			local on = not st.ghostGui and (ctx.isLocal or st.lod > 0)
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "12_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
