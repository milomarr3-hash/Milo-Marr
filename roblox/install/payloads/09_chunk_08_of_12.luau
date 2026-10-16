-- AuraRNG Studio install kit | 09_chunk_08_of_12.luau | step 9: piece 8 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (151582 bytes, checksum 322184148).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "09_chunk_08_of_12.luau"
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

local K = 8
-- piece 8 of 12 of the new source (13284 bytes, checksum 332029237, long bracket level 1)
local DATA = [=[
		-- P17 (pass 5.1): stars twinkle inside the clock's star window, between the rete's bars (locked to the dial, so they
		-- stay in the face however the clock turns to its viewer)
		if hi and hosts.inlay then
			pe(hosts.inlay, "twinkle", 4.4, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0, EmissionDirection = N_.Front,
				Rate = 5, Lifetime = n(2.6, 3.4), Speed = n(0), Size = seq({ { 0, 1.0, 0.3 }, { 1, 1.0, 0.3 } }),
				Transparency = seq({ { 0, 1 }, { 0.12, 0 }, { 0.88, 0 }, { 1, 1 } }), LockedToPart = true, Rotation = n(0, 90),
				ZOffset = 0.6 }, { 0.6, 1 }, { 2.2, 3.0 })
		end
		if hi then
			-- P7: a low mist bank round the pool's rim, only while standing on the ground (ShapePartial 0.8: the outer fifth
			-- of the disc, so the galaxy inside stays clear)
			pe(hosts.floorFx, "smoke5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.8, EmissionDirection = N_.Top, Rate = 2.5,
				Lifetime = n(6, 8), Speed = n(0.1, 0.25), Size = seq({ { 0, 8 }, { 1, 14 } }), Transparency = seq({ { 0, 1 }, { 0.3, 0.80 }, { 0.7, 0.82 }, { 1, 1 } }),
				Color = ColorSequence.new(MIST), LockedToPart = true, Rotation = n(0, 360), RotSpeed = n(-6, 6) }, nil, nil, "ground")
		end
		-- P8: starlight rises off the turning arms and swirls with them, in slow four-point twinkles (grow, hold, shrink);
		-- black ash flakes rise against them. At Roblox's default zoom, where the floor is a few studs from the lens, the
		-- twinkles are drawn smaller (five sizes made here, each step under 20 %, changed only when the zoom moves a step
		-- past a threshold: never a jump or a pulse on the floor)
		hosts.moteSizes = {}
		for k = 1, 5 do
			local pk = 1.3 - 0.1625 * (k - 1) -- (1.3, 1.14, 0.98, 0.81, 0.65)
			hosts.moteSizes[k] = seq({ { 0, 0 }, { 0.25, pk, 0.3 * pk / 1.3 }, { 0.75, pk, 0.3 * pk / 1.3 }, { 1, 0 } })
		end
		em.motes = pe(hosts.floorFx, "glint5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top,
			Rate = rate(18, 8), Lifetime = n(2.6, 3.6), Speed = n(0.5, 1.2), Acceleration = Vector3.new(0, 0.35, 0), Drag = 0.2,
			Size = hosts.moteSizes[1], Transparency = glintT, Rotation = n(0, 90), RotSpeed = n(-20, 20),
			LockedToPart = true, ZOffset = 0.2 }, WHITE_LE, WHITE_BR)
		if hi then
			-- (pass 5.1: te5_ash is an ember flake tumbling through 16 frames: charred black, burning white-hot along one
			-- side, so it is drawn white (an ASH tint would put the burn out); the pass-4 ash it falls back to is drawn ASH)
			local ember = isTe5("ash5")
			em.ash = pe(hosts.floorFx, "ash5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top, Rate = 8,
				Lifetime = n(3, 4.5), Speed = n(0.8, 2.0), Acceleration = Vector3.new(0, 0.3, 0), Drag = 0.4,
				Size = ember and n(0.56, 0.84) or n(0.4, 0.6), Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.75, 0.2 }, { 1, 1 } }),
				Color = ColorSequence.new(ember and WHITE or ASH), Rotation = n(0, 360), RotSpeed = n(-90, 90), FlipbookFramerate = n(8, 12),
				FlipbookStartRandom = true }, ember and { 0, 0 } or nil, ember and { 1.6, 3.2 } or nil)
			if ember then
				-- (if the ember fails to load in the game, the pass-4 ash comes back black, unlit and its old size)
				fixUps[em.ash] = function(o)
					o.Color, o.Size, o.Brightness = ColorSequence.new(ASH), seq({ { 0, 0.5, 0.1 }, { 1, 0.5, 0.1 } }), 1
					for _, e in ipairs(emitNight) do
						if e[1] == o then e[4], e[5] = 1, 1 end
					end
				end
			end
			-- P9: a vortex funnel: streaks spiral inward and climb into the balance wheel (off in first person: the camera
			-- sits right inside it)
			local p9 = { Rate = 16, Lifetime = n(1.7, 2.0), Speed = n(2.8, 3.2), Acceleration = Vector3.new(0, 1.0, 0),
				Size = seq({ { 0, 0.42 * stS }, { 1, 0.1 * stS } }), Transparency = seq({ { 0, 1 }, { 0.12, 0.05 }, { 0.85, 0.1 }, { 1, 1 } }),
				LockedToPart = true, Orientation = VPAR, Rotation = stRot }
			if CONFIG.SWIRL_POINTS then
				p9.EmissionDirection, p9.SpreadAngle = N_.Front, Vector2.new(0, 10)
				sizeFix(pe(rimPoint(hosts.funnel, 5.3), "streak5", 4.8, p9, WHITE_LE, WHITE_BR, "nearcam"), stS, { { 0, 0.42 }, { 1, 0.1 } })
			else
				p9.Shape, p9.ShapeStyle, p9.ShapeInOut, p9.EmissionDirection = CYL, SURFACE, INWARD, N_.Top
				sizeFix(pe(hosts.funnel, "streak5", 4.8, p9, WHITE_LE, WHITE_BR, "nearcam"), stS, { { 0, 0.42 }, { 1, 0.1 } })
			end
		end
		-- P10: the palms drink the streams: silver streaks converge into one palm, ink streaks into the other (locked to the
		-- palm, so they still converge on it while the wearer walks; off in first person, where the palms are just under the
		-- lens). STUDIO-VERIFY: Sphere + Surface + Inward converges on the centre (fallback: Outward with a negative Speed)
		local function intake(host, color, le, br)
			sizeFix(pe(host, "streak5", 5.2, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = INWARD, Rate = rate(14, 6), Lifetime = n(0.85, 0.95),
				Speed = n(1.35, 1.45), Size = seq({ { 0, 0.3 * stS }, { 1, 0.05 * stS } }), Transparency = seq({ { 0, 1 }, { 0.25, 0.05 }, { 1, 0.2 } }),
				Color = ColorSequence.new(color), ZOffset = 0.2, Orientation = VPAR, Rotation = stRot, LockedToPart = true }, le, br, "nearcam"),
				stS, { { 0, 0.3 }, { 1, 0.05 } })
		end
		intake(hosts.palmMoon, WHITE, WHITE_LE, WHITE_BR)
		intake(hosts.palmVoid, INK, nil, nil)
		-- P11: the wearer burns with the aura: silver wisps rise off the shoulders and back (not while travelling: no smog
		-- trail), and sparks stream up the body (they keep going while travelling and stream out behind like a comet's
		-- tail). Silver, not ink: from every camera the wearer stands against the black dial, where ink would vanish. They
		-- live on the character's torso (destroy() removes them) and switch off in first person
		do
			local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
			if torso and torso:IsA("BasePart") then
				em.wisps = pe(torso, "smoke5", 5.2, { Shape = BOX, ShapeStyle = SURFACE, EmissionDirection = N_.Top, Rate = rate(7, 3), Lifetime = n(1.6, 2.2),
					Speed = n(1.5, 2.5), SpreadAngle = Vector2.new(20, 20), Acceleration = Vector3.new(0, 1, 0), Size = seq({ { 0, 1.2 }, { 1, 3.4 } }),
					Transparency = seq({ { 0, 1 }, { 0.2, 0.32 }, { 0.6, 0.55 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(200, 202, 208)),
					ZOffset = -1.5, Rotation = n(0, 360), RotSpeed = n(-40, 40) }, { 0.2, 0.6 }, { 1.2, 2.0 }, "body")
				table.insert(charStuff, em.wisps)
				-- (pass 5.1: the body's sparks are hot flecks with hairline tails, streaking up the body the way they fly)
				table.insert(charStuff, pe(torso, "spark5", 5.2, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Top, Rate = rate(16, 6),
					Lifetime = n(0.8, 1.2), Speed = n(2.5, 4.5), SpreadAngle = Vector2.new(25, 25), Acceleration = Vector3.new(0, 2.5, 0),
					Size = seq({ { 0, 0.75 }, { 1, 0.35 } }), Transparency = seq({ { 0, 0.05 }, { 0.7, 0.15 }, { 1, 1 } }), Orientation = VPAR,
					Rotation = stRot, ZOffset = 0.5 }, { 0.5, 1 }, WHITE_BR, "body"))
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
		for _, h in ipairs({ "swirl", "shardFeed", "horizon", "timeDust", "palmMoon", "palmVoid", "inlay" }) do
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "14_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
