-- AuraRNG Studio install kit | 06_chunk_05_of_07.luau | step 6: piece 5 of 7
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (82580 bytes, checksum 413068034).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "06_chunk_05_of_07.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-82580-413068034-7-175648338"
local NEW_LEN, NEW_SUM = 82580, 413068034
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

local N = 7
local LENS = { 13394, 13390, 13386, 13387, 13372, 13337, 2314 }
local SUMS = { 747760660, 546838554, 282322451, 777563289, 713911797, 449542432, 103059902 }

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

local K = 5
-- piece 5 of 7 of the new source (13372 bytes, checksum 713911797, long bracket level 1)
local DATA = [=[
			props.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, v, e), NumberSequenceKeypoint.new(1, v, e) })
		end
		for k, v in pairs(props) do p[k] = v end
		p.LightEmission = le and le[1] or 0
		p.Brightness = br and br[1] or 1
		if le or br then table.insert(emitNight, { p, le and le[1] or 0, le and le[2] or 0, br and br[1] or 1, br and br[2] or 1 }) end
		p.Parent = parent
		table.insert(emitters, { p, tOn, kind, false, false })
		return p
	end
	local function rate(h, l) return low and l or h end
	local SPHERE, CYL, DISCSHAPE, BOX = Enum.ParticleEmitterShape.Sphere, Enum.ParticleEmitterShape.Cylinder, Enum.ParticleEmitterShape.Disc,
		Enum.ParticleEmitterShape.Box
	local SURFACE, VOLUME = Enum.ParticleEmitterShapeStyle.Surface, Enum.ParticleEmitterShapeStyle.Volume
	local INWARD, OUTWARD = Enum.ParticleEmitterShapeInOut.Inward, Enum.ParticleEmitterShapeInOut.Outward
	local VPAR = Enum.ParticleOrientation.VelocityParallel
	local N_ = Enum.NormalId
	local WHITE_LE, WHITE_BR = { 0.3, 0.9 }, { 1.6, 2.4 }
	-- P1: matter spirals in along the accretion disc and vanishes into the black core (straight inward motion inside a
	-- spinning host becomes a spiral). STUDIO-VERIFY: Cylinder + Surface + Inward emits on the curved side toward the axis,
	-- and LockedToPart particles ride a host moved by BulkMoveTo
	pe(swirlHost, "mote", 1.2, { Shape = CYL, ShapeStyle = SURFACE, ShapeInOut = INWARD, EmissionDirection = N_.Top, Rate = rate(34, 12),
		Lifetime = n(1.1, 1.3), Speed = n(2.2, 2.6), Size = seq({ { 0, 0.55 }, { 1, 0.18 } }),
		Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.8, 0.05 }, { 1, 0.4 } }),
		Color = ColorSequence.new(WHITE, Color3.fromRGB(170, 174, 184)), LockedToPart = true, ZOffset = 0.3 }, WHITE_LE, WHITE_BR)
	-- P2: dust snows off the moon and falls away below it
	pe(moon, "mote", 1.6, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = OUTWARD, Rate = rate(12, 5), Lifetime = n(3.0, 4.5),
		Speed = n(0.25, 0.6), Acceleration = Vector3.new(0, -1.1, 0), Drag = 0.4, Size = seq({ { 0, 0.14 }, { 0.2, 0.4, 0.12 }, { 1, 0.14 } }),
		Transparency = seq({ { 0, 1 }, { 0.12, 0.08 }, { 0.75, 0.15 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(238, 240, 246)),
		Rotation = n(0, 360), RotSpeed = n(-30, 30) }, { 0.2, 0.7 }, { 1.4, 2.2 })
	if hi then
		-- P3: metal shards break off the bezel at eleven and fly across the face into the void (tumbling flipbook)
		local shardScale = isTe5("shards5") and 1.3 or 1 -- (the te5 sliver fills about half its cell)
		pe(shardFeed, "shards5", 4.8, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Front, Rate = 5, Lifetime = n(2.9, 3.2),
			Speed = n(8.5, 9.5), SpreadAngle = Vector2.new(6, 6),
			Size = seq({ { 0, 0.6 * shardScale }, { 0.85, 0.9 * shardScale, 0.12 * shardScale }, { 1, 0.35 * shardScale } }),
			Transparency = seq({ { 0, 1 }, { 0.06, 0 }, { 0.9, 0 }, { 1, 1 } }), Color = ColorSequence.new(Color3.fromRGB(214, 218, 226)),
			Rotation = n(0, 360), RotSpeed = n(-120, 120), FlipbookFramerate = n(10, 14), FlipbookStartRandom = true }, { 0, 0.3 }, { 1, 1.6 })
	end
	-- P4: two-tone smoke curls off the rim: ink on the void side, silver on the moon side, drifting back and up
	pe(smokeVoid, "smoke5", 3.2, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Right, Rate = rate(7, 3), Lifetime = n(3.5, 4.5),
		Speed = n(0.6, 1.2), SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, 0.5, 0), Drag = 0.3,
		Size = seq({ { 0, 3 }, { 1, 7.5 } }), Transparency = seq({ { 0, 1 }, { 0.2, 0.30 }, { 0.7, 0.45 }, { 1, 1 } }),
		Color = ColorSequence.new(SMOKE), Rotation = n(0, 360), RotSpeed = n(-20, 20) })
	if hi then
		pe(smokeMoon, "smoke5", 3.2, { Shape = BOX, ShapeStyle = VOLUME, EmissionDirection = N_.Left, Rate = 5, Lifetime = n(3.5, 4.5),
			Speed = n(0.6, 1.2), SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, 0.5, 0), Drag = 0.3,
			Size = seq({ { 0, 3 }, { 1, 7 } }), Transparency = seq({ { 0, 1 }, { 0.2, 0.45 }, { 0.7, 0.6 }, { 1, 1 } }),
			Color = ColorSequence.new(Color3.fromRGB(196, 200, 210)), Rotation = n(0, 360), RotSpeed = n(-20, 20) }, { 0.1, 0.4 })
	end
	-- P5: slow four-point glints bloom on the bezel metal and fade (grow, hold, shrink: never a flash).
	-- STUDIO-VERIFY: Disc ShapePartial = the inner-radius fraction (0.86 -> the annulus over the bezel), oriented by EmissionDirection
	local glintT = seq({ { 0, 0.1 }, { 1, 0.1 } })
	pe(rimGlint, "glint5", 3.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.86, EmissionDirection = N_.Back, Rate = rate(3, 1.2),
		Lifetime = n(1.6, 2.2), Size = seq({ { 0, 0 }, { 0.35, 1.3, 0.35 }, { 0.65, 1.3, 0.35 }, { 1, 0 } }), Transparency = glintT,
		LockedToPart = true, ZOffset = 1.0, Rotation = n(0, 90) }, { 0.5, 1 }, WHITE_BR)
	if hi then
		for _, seg in ipairs({ meridian[0], meridian[9] }) do
			pe(seg, "glint5", 3.8, { Shape = BOX, ShapeStyle = VOLUME, Rate = 0.4, Lifetime = n(1.6, 2.2),
				Size = seq({ { 0, 0 }, { 0.35, 0.9, 0.25 }, { 0.65, 0.9, 0.25 }, { 1, 0 } }), Transparency = glintT, LockedToPart = true,
				ZOffset = 0.5, Rotation = n(0, 90) }, { 0.5, 1 }, WHITE_BR)
		end
	end
	-- P6: three scales of air: fine silver dust, mid glints, and big slow bokeh between the camera and the wearer
	pe(air, "mote", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(26, 10), Lifetime = n(6, 9), Speed = n(0.1, 0.3),
		SpreadAngle = Vector2.new(180, 180), Size = n(0.1, 0.26), Transparency = seq({ { 0, 1 }, { 0.2, 0.1 }, { 0.8, 0.15 }, { 1, 1 } }),
		Color = ColorSequence.new(Color3.fromRGB(226, 230, 240)) }, { 0.2, 0.8 }, { 1.4, 2.2 })
	pe(air, "glint5", 2.5, { Shape = BOX, ShapeStyle = VOLUME, Rate = rate(5, 1.5), Lifetime = n(4, 6), Speed = n(0.2, 0.5),
		SpreadAngle = Vector2.new(180, 180), Size = seq({ { 0, 0 }, { 0.3, 0.7, 0.2 }, { 0.7, 0.7, 0.2 }, { 1, 0 } }),
		Transparency = seq({ { 0, 1 }, { 0.3, 0.1 }, { 0.7, 0.1 }, { 1, 1 } }), Rotation = n(0, 90), RotSpeed = n(-20, 20) }, { 0.4, 1 }, WHITE_BR)
	local bokeh = hi and pe(bokehHost, "bokeh", 3.0, { Shape = BOX, ShapeStyle = VOLUME, Rate = 0.5, Lifetime = n(5, 7), Speed = n(0.1, 0.25),
		SpreadAngle = Vector2.new(180, 180), Size = n(1.2, 2.4), Transparency = seq({ { 0, 1 }, { 0.25, 0.72 }, { 0.75, 0.72 }, { 1, 1 } }),
		Color = ColorSequence.new(Color3.fromRGB(232, 236, 246)), Rotation = n(0, 360), RotSpeed = n(-4, 4) }, { 0.3, 0.8 }, { 1.2, 1.8 }, "bokeh")
	if hi then
		-- P7: one low mist bank at the ankles, only while standing on the ground
		pe(floor, "smoke5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, EmissionDirection = N_.Top, Rate = 2.5, Lifetime = n(6, 8),
			Speed = n(0.1, 0.25), Size = seq({ { 0, 8 }, { 1, 14 } }), Transparency = seq({ { 0, 1 }, { 0.3, 0.80 }, { 0.7, 0.82 }, { 1, 1 } }),
			Color = ColorSequence.new(MIST), LockedToPart = true, Rotation = n(0, 360), RotSpeed = n(-6, 6) }, nil, nil, "ground")
	end
	-- P8: motes rise off the turning arms and swirl with them; black ash flakes rise against them
	pe(floor, "mote", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top, Rate = rate(18, 8),
		Lifetime = n(2.6, 3.6), Speed = n(0.5, 1.2), Acceleration = Vector3.new(0, 0.35, 0), Drag = 0.2,
		Size = seq({ { 0, 0 }, { 0.2, 0.42, 0.12 }, { 1, 0 } }), Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.8, 0.15 }, { 1, 1 } }),
		LockedToPart = true, ZOffset = 0.2 }, WHITE_LE, WHITE_BR)
	if hi then
		-- STUDIO-VERIFY: te5_ash is 256² with a 2x2 flipbook; Roblox may only animate flipbooks on 1024² textures
		pe(floor, "ash5", 4.8, { Shape = DISCSHAPE, ShapeStyle = VOLUME, ShapePartial = 0.15, EmissionDirection = N_.Top, Rate = 7,
			Lifetime = n(3, 4.5), Speed = n(0.8, 2.0), Acceleration = Vector3.new(0, 0.3, 0), Drag = 0.4, Size = n(0.4, 0.6),
			Transparency = seq({ { 0, 1 }, { 0.15, 0.05 }, { 0.75, 0.2 }, { 1, 1 } }), Color = ColorSequence.new(ASH), Rotation = n(0, 360),
			RotSpeed = n(-90, 90) })
		-- P9: a vortex funnel: streaks spiral inward and climb into the balance wheel.
		-- STUDIO-VERIFY: te5_streak assumes VelocityParallel puts the texture's TOP along the velocity (flip the PNG if not)
		pe(funnel, "streak5", 4.8, { Shape = CYL, ShapeStyle = SURFACE, ShapeInOut = INWARD, EmissionDirection = N_.Top, Rate = 16,
			Lifetime = n(1.7, 2.0), Speed = n(2.8, 3.2), Acceleration = Vector3.new(0, 1.0, 0), Size = seq({ { 0, 0.42 }, { 1, 0.1 } }),
			Transparency = seq({ { 0, 1 }, { 0.12, 0.05 }, { 0.85, 0.1 }, { 1, 1 } }), LockedToPart = true, Orientation = VPAR }, WHITE_LE, WHITE_BR)
	end
	-- P10: the palms drink the streams: silver motes converge into one palm, ink motes into the other.
	-- STUDIO-VERIFY: Sphere + Surface + Inward converges on the centre (fallback: Outward with a negative Speed)
	local function intake(host, color, le, br)
		pe(host, "streak5", 5.2, { Shape = SPHERE, ShapeStyle = SURFACE, ShapeInOut = INWARD, Rate = rate(14, 6), Lifetime = n(0.85, 0.95),
			Speed = n(1.35, 1.45), Size = seq({ { 0, 0.3 }, { 1, 0.05 } }), Transparency = seq({ { 0, 1 }, { 0.25, 0.05 }, { 1, 0.2 } }),
			Color = ColorSequence.new(color), ZOffset = 0.2, Orientation = VPAR }, le, br)
	end
	intake(palmMoon, WHITE, WHITE_LE, WHITE_BR)
	intake(palmVoid, INK, nil, nil)
	-- P11: time drips off each sole onto the balance wheel below
	for _, a in ipairs({ soleL, soleR }) do
		if a then
			pe(a, "mote", 5.2, { EmissionDirection = N_.Bottom, Rate = rate(4, 2), Lifetime = n(0.6, 0.8), Speed = n(0.1, 0.3),
				SpreadAngle = Vector2.new(8, 8), Acceleration = Vector3.new(0, -5, 0), Size = seq({ { 0, 0.18 }, { 1, 0.08 } }),
				Transparency = seq({ { 0, 0.1 }, { 0.8, 0.2 }, { 1, 1 } }) }, WHITE_LE, WHITE_BR, "foot")
		end
	end
	table.sort(emitters, function(a, b) return a[2] < b[2] end)

	-- lights: the moon's key light (lights its top and rims the wearer) and the wheel's underlight on the feet (night only)
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

	---------------------------------------------------------------- the wearer's own screen grade (real equips only)
	local grade, gradeIn, gradeOut, gradeConn
	if CONFIG.GRADE and ctx.isLocal and os.clock() - (spawnedAt[char] or 0) > 4 and workspace.CurrentCamera then
		grade = new("ColorCorrectionEffect", { Name = "TheEndReveal" }, workspace.CurrentCamera)
		gradeIn = TweenService:Create(grade, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Saturation = -0.75, Brightness = -0.1, Contrast = 0.15, TintColor = Color3.fromRGB(232, 238, 255) })
		gradeIn:Play()
		task.delay(5.8, function()
			if destroyed or not (grade and grade.Parent) then return end
			gradeOut = TweenService:Create(grade, TweenInfo.new(2.2, Enum.EasingStyle.Sine), { Saturation = 0, Brightness = 0, Contrast = 0,
				TintColor = Color3.new(1, 1, 1) })
			gradeConn = gradeOut.Completed:Connect(function()
				if grade then
					grade:Destroy()
					grade = nil
				end
			end)
			gradeOut:Play()
		end)
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
	local ltmOn = false
	local hlF, hlO = -1, -1
	local dir = 1 -- (the accretion texture's streaks wind clockwise outward, so a counter-clockwise turn makes them trail)
	local SHARD_A = {}
	for i = 0, 7 do SHARD_A[i] = rad(300 + 20 * i) end
	local FEED_PT = Vector3.new(-10.72, 9.00, 0)
	if age >= ASM_END then void.Size = voidSize else void.Size = voidSize * (0.6 / 8) end

	---------------------------------------------------------------- event writes (never per frame in steady state)
	local function refreshEmitters()
		for _, e in ipairs(emitters) do
			local want = e[4] and near and alphaOn
			local kind = e[3]
			if kind == "ground" then want = want and grounded
			elseif kind == "bokeh" then want = want and not bokehNear
			elseif kind == "foot" then want = want and visible end -- (they live on the character, outside our model)
			if want ~= e[5] then
				e[1].Enabled = want
				e[5] = want
			end
		end
	end
	local keyOn, wheelOn, detailBeams = false, false, true
	local function refreshLights()
		local on = near and alphaOn and visible and nq > 0
		if (on and age >= 0.6) ~= keyOn then
			keyOn = not keyOn
			keyLight.Enabled = keyOn
		end
		if wheelLight and (on and age >= 4.6) ~= wheelOn then
			wheelOn = not wheelOn
			wheelLight.Enabled = wheelOn
		end
		if near ~= detailBeams then
			detailBeams = near
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "09_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
