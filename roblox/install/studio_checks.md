# Testing THE END pass 5 in Studio

This is the pass-5 spec's Studio checklist (`docs/the-end/pass5-spec.md` §18.4 and §19) as concrete steps, for Milo's local
Claude Code with the Studio MCP. Nothing here has been run in Studio yet: the cloud only had a mock. Report what you
actually see.

How to run things:
- **Edit** snippets: `execute_luau` with `datamodel_type: "Edit"` (Play stopped).
- **Client** snippets: start Play (`start_stop_play` with `is_start: true`), then `execute_luau` with
  `datamodel_type: "Client"` (your own player in Play).
- **Screenshots:** call `screen_capture` right after a snippet returns. Show Milo small thumbnails, not full-size images,
  and say what changed in plain words.
- Change only the `UPPER_CASE` settings at the top of a snippet. Everything a Client snippet changes disappears when Play
  stops.
- Before any shot that will go in the repo, check it shows no username, chat or player list. The repo is public.

Context from the code (`roblox/ReplicatedStorage/AuraFX/TheEnd.lua`):
- The aura is a Model named `TheEnd_<character name>`. Its Highlight is `TheEndTone`, which covers only the silver parts.
  The wearer's screen grade is a ColorCorrection called `TheEndReveal` under the camera, made on real equips only.
- For the first 20 s after joining, the aura counts the character as "spawned": no grade, but the assembly still plays.
  The snippets wait until `time() >= 21`.
- If you change `Lighting.ClockTime` while the aura is worn, day and night ease over **about 20 s** (0.05 per second, so
  dusk never steps). Wait about 21 s before a night or day shot, or set the time **before** equipping.
- The AuraFX framework stops drawing auras while the camera is Scriptable, so every view here uses Roblox's normal Custom
  camera with a fixed zoom.
- CONFIG flags are attributes on the ModuleScript with the same name and type (`USE_FILM_MESHES`, `FILM_*`, `HIGHLIGHT`,
  `CLOCK_DIST`, `DEBUG`, ... see `local DEFAULTS` in the module). Since review round 1 the module reads them **at every
  build**: set an attribute (S8, or in Play from the command bar), then **unequip and equip** the aura. A wrong type, an
  unknown UPPER_CASE name (a typo) or a number out of range is reported with a warning (out-of-range numbers are clamped).
- Several Studio checks are **one attribute flip** instead of an edit + reinstall (the flips list is under "STUDIO-VERIFY
  items" below): `FLOW_SIGN`, `ACC_DIR`, `FUNNEL_DIR`, `GALAXY_DIR` (-1 reverses a flow or spin), `WEDGE_SWAP`,
  `STREAK_FLIP`, `FRONT_FACES`, `SWIRL_POINTS` (true fixes a wrong-looking result), `HIGHLIGHT_FILL` / `HIGHLIGHT_OUTLINE`
  (the silver tone's day strength), `YAW_LAG_MAX`, `ZOOM_FAR` / `ZOOM_NEAR`, `NEAR_ARM_HIDE` / `NEAR_ARM_SHOW`, `AIR_ON` /
  `AIR_OFF`. `FAR_BEACON = true` turns on a thin spire that only far-away players see (off until Milo says yes).

## The snippets

### S1. Frame a shot (Client)

This sets the time of day, can equip THE END, turns you toward the most open direction, and places the camera. `studio`
is the camera of the real pass-4 captures and of the cloud previews (`tools/harness/README.md`, Cameras): Custom camera,
zoom 40, focus on the HumanoidRootPart + 1.5 up, aimed once with
`CFrame.lookAt(p + f*38 + r*8 + (0,7,0), p + (0,6,0))`. Use it for every day/night comparison, so the shots line up
with `tools/baseline/pass4/` and the cloud renders.

```lua
-- Client (Play). Set the time, (optionally) equip THE END, face the most open direction, frame a view; then screen_capture.
local VIEW = "studio" -- studio | owner | owner25 | side | high | far | first | clock | void | reset
local CLOCK_TIME = 14 -- 14 = day, 0.5 = night, nil = leave it
local EQUIP = false -- true = equip THE END now (a real equip: the ~6.5 s assembly and your screen grade)
local TURN_TO_OPEN = true -- face the most open direction first, so walls and trees don't hide the aura
local WAIT = 1.5 -- seconds before returning (use 9 after an equip; 21 after changing the time while it is worn)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterPlayer = game:GetService("StarterPlayer")
local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:FindFirstChildOfClass("Humanoid")
local cam = workspace.CurrentCamera
while time() < 21 do
	task.wait(0.5)
end
if TURN_TO_OPEN and VIEW ~= "reset" then
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local best, bestD = 0, -1
	for k = 0, 23 do
		local a = k * math.pi / 12
		local res = workspace:Raycast(hrp.Position + Vector3.new(0, 3, 0), Vector3.new(math.sin(a), 0, math.cos(a)) * 80, params)
		local d = res and res.Distance or 80
		if d > bestD then
			best, bestD = a, d
		end
	end
	hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + Vector3.new(math.sin(best), 0, math.cos(best)))
	task.wait(0.3)
end
if CLOCK_TIME then
	Lighting.ClockTime = CLOCK_TIME
end
local function auraModel()
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and d.Name == "TheEnd_" .. char.Name then
			return d
		end
	end
	return nil
end
cam.CameraType = Enum.CameraType.Custom
cam.CameraSubject = hum
local p, f, r = hrp.Position, hrp.CFrame.LookVector, hrp.CFrame.RightVector
local up = Vector3.new(0, 1, 0)
local function frame(zoom, dir)
	plr.CameraMinZoomDistance, plr.CameraMaxZoomDistance = zoom, zoom
	local focus = p + Vector3.new(0, 1.5, 0)
	cam.CFrame = CFrame.lookAt(focus + dir.Unit * zoom, focus)
end
if VIEW == "studio" then
	plr.CameraMinZoomDistance, plr.CameraMaxZoomDistance = 40, 40
	cam.CFrame = CFrame.lookAt(p + f * 38 + r * 8 + Vector3.new(0, 7, 0), p + Vector3.new(0, 6, 0))
elseif VIEW == "owner" then
	frame(12.5, -f * 12.5 + up * 2.5) -- Roblox's default zoom, behind (the owner's usual view)
elseif VIEW == "owner25" then
	frame(25, -f * 25 + up * 6)
elseif VIEW == "side" then
	frame(40, r * 40 + up * 5)
elseif VIEW == "high" then
	frame(50, -f * 6 + up * 50) -- as steep as the Custom camera goes (about 80 degrees)
elseif VIEW == "far" then
	frame(130, f * 120 + r * 30 + up * 25) -- past the 110-stud detail range: particles stop, details drop
elseif VIEW == "first" then
	plr.CameraMinZoomDistance, plr.CameraMaxZoomDistance = 0.5, 0.5
	cam.CFrame = CFrame.lookAt(p + Vector3.new(0, 1.5, 0), p + Vector3.new(0, 1.5, 0) + f)
elseif VIEW == "clock" or VIEW == "void" then
	local m = auraModel()
	local part = m and m:FindFirstChild(VIEW == "clock" and "SubDial" or "Void", true)
	if not part then
		return "no " .. VIEW .. " part found (is THE END equipped?)"
	end
	local zoom = VIEW == "clock" and 24 or 14
	cam.CameraSubject = part -- still the Custom camera; the layout follows the camera, so capture quickly
	plr.CameraMinZoomDistance, plr.CameraMaxZoomDistance = zoom, zoom
	cam.CFrame = CFrame.lookAt(part.Position - cam.CFrame.LookVector * zoom + up * 3, part.Position)
elseif VIEW == "reset" then
	plr.CameraMinZoomDistance = StarterPlayer.CameraMinZoomDistance
	plr.CameraMaxZoomDistance = StarterPlayer.CameraMaxZoomDistance
end
if EQUIP then
	game:GetService("ReplicatedStorage").AuraRemotes.Equip:FireServer("The End")
end
task.wait(WAIT)
local m = auraModel()
return string.format("view %s, ClockTime %.2f, Aura attribute %s, aura model %s, camera %.1f studs from the root",
	VIEW, Lighting.ClockTime, tostring(char:GetAttribute("Aura")), m and (#m:GetDescendants() .. " instances") or "NOT FOUND",
	(cam.CFrame.Position - hrp.Position).Magnitude)
```

If THE END is already worn when Play starts, firing Equip again may not rebuild it. To see the assembly and grade again,
use the bench (S5) with `IS_LOCAL = true`, or equip another aura Milo owns and then The End.

### S2. Inspect the aura (Client)

This gives the counts against the budget, whether the clock is on the far side of the wearer from your camera, whether
the moon is on your left and the void on your right, the screen grade, frame time, and any `TheEnd` / `AuraFX` warnings
or errors in the Output.

```lua
-- Client (Play). What THE END is doing right now, as one line.
local WHO = nil -- nil = you; or a character / bench name, e.g. "TheEndBench1"
local SAMPLE = 2 -- seconds of frame-time sampling

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local plr = Players.LocalPlayer
local name = WHO or (plr.Character and plr.Character.Name)
local wearer = name and workspace:FindFirstChild(name, true)
local root = wearer and wearer:FindFirstChild("HumanoidRootPart")
local m
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Model") and d.Name == "TheEnd_" .. tostring(name) then
		m = d
		break
	end
end
if not (m and root) then
	return "no TheEnd_" .. tostring(name) .. " model (not equipped? hidden because the camera is far away or Scriptable?)"
end
local c = { parts = 0, emitters = 0, on = 0, rate = 0, guis = 0, beams = 0, lights = 0, lightsOn = 0, highlights = 0 }
for _, d in ipairs(m:GetDescendants()) do
	if d:IsA("BasePart") then
		c.parts += 1
	elseif d:IsA("ParticleEmitter") then
		c.emitters += 1
		if d.Enabled then
			c.on += 1
			c.rate += d.Rate
		end
	elseif d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
		c.guis += 1
	elseif d:IsA("Beam") then
		c.beams += 1
	elseif d:IsA("PointLight") then
		c.lights += 1
		if d.Enabled then
			c.lightsOn += 1
		end
	elseif d:IsA("Highlight") then
		c.highlights += 1
	end
end
local cam = workspace.CurrentCamera
local camPos, camRight = cam.CFrame.Position, cam.CFrame.RightVector
local O = root.Position
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function side(nm)
	local pt = m:FindFirstChild(nm, true)
	return pt and pt:IsA("BasePart") and pt.Position or nil
end
local clockC, moonC, voidC = side("SubDial"), side("Moon"), side("Void")
local far = clockC and (flat(clockC - O):Dot(flat(O - camPos)) > 0)
local moonLeft = moonC and (moonC - O):Dot(camRight) < 0
local voidRight = voidC and (voidC - O):Dot(camRight) > 0
local grade = cam:FindFirstChild("TheEndReveal")
local n, total, worst, t0 = 0, 0, 0, os.clock()
while os.clock() - t0 < SAMPLE do
	local dt = RunService.RenderStepped:Wait()
	n += 1
	total += dt
	worst = math.max(worst, dt)
end
local logs = {}
local okLog, history = pcall(function()
	return LogService:GetLogHistory()
end)
for _, e in ipairs(okLog and type(history) == "table" and history or {}) do
	if (e.messageType == Enum.MessageType.MessageWarning or e.messageType == Enum.MessageType.MessageError)
		and (string.find(e.message, "TheEnd", 1, true) or string.find(e.message, "AuraFX", 1, true)) then
		table.insert(logs, string.sub(e.message, 1, 160))
	end
end
while #logs > 5 do
	table.remove(logs, 1)
end
return string.format("%s: %d parts, %d emitters (%d on, rate %.0f/s), %d GUIs, %d beams, %d lights (%d on), %d highlight(s) | clock on the far side: %s, moon left: %s, void right: %s | grade: %s | frame %.1f ms avg, %.1f ms worst | ClockTime %.2f | %d warnings/errors%s",
	m.Name, c.parts, c.emitters, c.on, c.rate, c.guis, c.beams, c.lights, c.lightsOn, c.highlights, tostring(far), tostring(moonLeft),
	tostring(voidRight), grade and string.format("on (saturation %.2f)", grade.Saturation) or "none",
	1000 * total / math.max(n, 1), 1000 * worst, game:GetService("Lighting").ClockTime, #logs,
	#logs > 0 and (": " .. table.concat(logs, " || ")) or "")
```

Budget (spec §14). High quality: 360 parts, 17 emitters in the model (the other 2 of the spec's 19 are the foot drips
on the character, outside the model), total Rate under 200/s, 6 beams, 11 GUIs, 2 lights (on at night only) and
1 highlight. Low quality: 149 parts, 9 emitters (+2 foot drips), under 80/s, 2 beams, 7 GUIs, 1 light. (These are the
numbers S2 printed when it was run against the module in the cloud's mock world; Studio may differ.)

### S3. Move (Client)

```lua
-- Client (Play). Move so the aura has to follow: walk | fast | jump | sit | air | stop. Then screen_capture at once.
local MODE = "walk"

local StarterPlayer = game:GetService("StarterPlayer")
local char = game:GetService("Players").LocalPlayer.Character
local hum = char:FindFirstChildOfClass("Humanoid")
local hrp = char:FindFirstChild("HumanoidRootPart")
if MODE == "walk" or MODE == "fast" then
	hum.WalkSpeed = StarterPlayer.CharacterWalkSpeed * (MODE == "fast" and 2 or 1)
	hum:MoveTo(hrp.Position + hrp.CFrame.LookVector * 60)
	task.wait(1.5)
	return MODE .. ": moving for a few seconds (glide pose, armillary leans, clock steps back); screen_capture now"
elseif MODE == "jump" then
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
	task.wait(0.35)
	return "jump: in the air now (the dais must stay on the ground); screen_capture now"
elseif MODE == "sit" then
	hum.Sit = true
	task.wait(1)
	return "sitting; screen_capture now (MODE = \"jump\" stands up)"
elseif MODE == "air" then
	hrp.Anchored = true
	hrp.CFrame = hrp.CFrame + Vector3.new(0, 30, 0)
	task.delay(8, function()
		hrp.Anchored = false
	end)
	task.wait(2)
	return "held 30 studs up for 8 s (the dais should float under the feet); screen_capture now"
elseif MODE == "stop" then
	hum.WalkSpeed = StarterPlayer.CharacterWalkSpeed
	hum:MoveTo(hrp.Position)
	return "stopped"
end
return "unknown MODE"
```

### S4. Orbit the camera fast (Client)

```lua
-- Client (Play). Swing the camera round the wearer; screen_capture twice while it turns (about 0.5 s apart).
local SPEED = 120 -- degrees per second
local SECONDS = 6

local RunService = game:GetService("RunService")
local cam = workspace.CurrentCamera
local hrp = game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
local t0 = os.clock()
RunService:BindToRenderStep("TheEndOrbitTest", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if os.clock() - t0 > SECONDS then
		RunService:UnbindFromRenderStep("TheEndOrbitTest")
		return
	end
	local focus = hrp.Position + Vector3.new(0, 1.5, 0)
	local off = cam.CFrame.Position - focus
	cam.CFrame = CFrame.lookAt(focus + CFrame.Angles(0, math.rad(SPEED) * dt, 0) * off, focus)
end)
task.wait(1.5)
return "orbiting at " .. SPEED .. " deg/s for " .. SECONDS .. " s; screen_capture now"
```

### S5. Test bench: stand-in wearers (Client)

This builds THE END straight from the module on stand-ins in front of you and drives it the way the framework does. It
removes them after `SECONDS`, or when you run S6. Use it for another player's aura (`IS_LOCAL = false`: no grade, and the
clock still faces **your** camera), for low quality, for an R6 body, for several wearers at once, and to replay the
assembly. The stand-ins don't take the floating pose (the framework applies that to real wearers only), so they are
lifted by the hover height instead.

```lua
-- Client (Play). THE END on stand-in wearers in front of you, for SECONDS, then removed. Nothing is saved.
local QUALITY = "low" -- "high" or "low"
local RIG = "clone" -- "clone" = a copy of your avatar, "r6" = a plain grey R6 body
local IS_LOCAL = false -- true = as if it were yours (assembly + your screen grade)
local COUNT = 1 -- stand-ins side by side (3 for the several-wearers check)
local DIST = 30 -- studs in front of you
local SECONDS = 60

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer
local char = plr.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
if not hrp then
	return "no character yet"
end
local okReq, End = pcall(require, game:GetService("ReplicatedStorage"):WaitForChild("AuraFX"):WaitForChild("TheEnd"))
if not okReq then
	return "require failed: " .. tostring(End)
end
for _, o in ipairs(workspace:GetChildren()) do
	if string.match(o.Name, "^TheEndBench") then
		o:Destroy()
	end
end
local function r6body()
	local m = Instance.new("Model")
	local function part(nm, size, pos)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = nm, size, CFrame.new(pos), Color3.fromRGB(163, 162, 165)
		p.Parent = m
		return p
	end
	local rootPart = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.zero)
	rootPart.Transparency = 1
	part("Torso", Vector3.new(2, 2, 1), Vector3.zero)
	part("Head", Vector3.new(2, 1, 1), Vector3.new(0, 1.5, 0))
	part("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0))
	part("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0))
	part("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0))
	part("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0))
	local h = Instance.new("Humanoid")
	h.RigType = Enum.HumanoidRigType.R6
	h.RequiresNeck = false
	h.Parent = m
	m.PrimaryPart = rootPart
	return m
end
local function cloneBody()
	char.Archivable = true
	local m = char:Clone()
	char.Archivable = false
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or string.match(d.Name, "^TheEnd") then
			d:Destroy()
		end
	end
	return m
end
local hover = (End.pose and End.pose.hover) or 2.4
local f, r = hrp.CFrame.LookVector, hrp.CFrame.RightVector
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local benches, ignore = {}, { char }
for i = 1, COUNT do
	local m = RIG == "r6" and r6body() or cloneBody()
	m.Name = "TheEndBench" .. i
	local mh = m:FindFirstChild("HumanoidRootPart")
	local mhum = m:FindFirstChildOfClass("Humanoid")
	mhum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide = true, false
		end
	end
	local pos = hrp.Position + f * DIST + r * ((i - (COUNT + 1) / 2) * 18) + Vector3.new(0, hover, 0)
	m:PivotTo(CFrame.lookAt(pos, Vector3.new(hrp.Position.X, pos.Y, hrp.Position.Z)))
	m.Parent = workspace
	local folder = Instance.new("Folder")
	folder.Name = "TheEndBenchFx" .. i
	folder.Parent = workspace
	table.insert(ignore, m)
	table.insert(ignore, folder)
	local legLen = mhum.RigType == Enum.HumanoidRigType.R15 and (mhum.HipHeight + mh.Size.Y / 2) or 3
	local okB, fx = pcall(End.build, { char = m, hrp = mh, hum = mhum, quality = QUALITY, isLocal = IS_LOCAL, container = folder })
	if not okB then
		m:Destroy()
		folder:Destroy()
		return "build error: " .. tostring(fx)
	end
	table.insert(benches, { m = m, hrp = mh, fx = fx, folder = folder, alpha = 0, legLen = legLen, near = true })
end
params.FilterDescendantsInstances = ignore
local t0 = os.clock()
local function stop()
	RunService:UnbindFromRenderStep("TheEndBench")
	for _, b in ipairs(benches) do
		pcall(b.fx.destroy)
		b.m:Destroy()
		b.folder:Destroy()
	end
	table.clear(benches)
end
RunService:BindToRenderStep("TheEndBench", Enum.RenderPriority.Last.Value, function(dt: number)
	if os.clock() - t0 > SECONDS then
		stop()
		return
	end
	local camPos = workspace.CurrentCamera.CFrame.Position
	for _, b in ipairs(benches) do
		if not b.m.Parent then
			stop()
			return
		end
		b.alpha = math.min(1, b.alpha + dt / 0.9)
		local near = (camPos - b.hrp.Position).Magnitude < 110
		if near ~= b.near then
			b.near = near
			b.fx.setDetail(near)
		end
		local hit = workspace:Raycast(b.hrp.Position, Vector3.new(0, -60, 0), params)
		local ok, err = pcall(b.fx.update, dt, { cf = b.hrp.CFrame, hover = 0, glide = 0, t = os.clock(),
			now = workspace:GetServerTimeNow(), legLen = b.legLen, ground = hit and hit.Position or nil, alpha = b.alpha })
		if not ok then
			warn("TheEnd bench: update error: " .. tostring(err))
			stop()
			return
		end
	end
end)
task.wait(1)
return string.format("bench: %d stand-in(s) (%s, quality %s, isLocal %s) %d studs ahead for %d s. The assembly takes ~6.5 s; screen_capture then. S2 with WHO = \"TheEndBench1\" inspects one.",
	COUNT, RIG, QUALITY, tostring(IS_LOCAL), DIST, SECONDS)
```

### S6. Remove the bench now (Client)

```lua
-- Client (Play). Remove the bench stand-ins (their auras clean themselves up on the next frame).
local n = 0
for _, o in ipairs(workspace:GetChildren()) do
	if string.match(o.Name, "^TheEndBench%d+$") then
		o:Destroy()
		n += 1
	end
end
return "removed " .. n .. " stand-in(s)"
```

### S7. Highlight on/off (Client)

```lua
-- Client (Play). Turn THE END's silver-tone Highlight off or on, to compare the day colour (silver must not look cyan).
local ON = false

local n = 0
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Highlight") and d.Name == "TheEndTone" then
		d.Enabled = ON
		n += 1
	end
end
return string.format("TheEndTone %s on %d aura(s); screen_capture to compare", ON and "ON" or "OFF", n)
```

### S8. CONFIG flags (Edit)

```lua
-- Edit mode. Set / clear THE END's CONFIG overrides (attributes on the ModuleScript). Read at every build (equip).
local SET = {
	-- USE_FILM_MESHES = true, FILM_BEZEL = true,
	-- HIGHLIGHT = false, HIGHLIGHT_FILL = 0.55,
	-- FLOW_SIGN = -1, ACC_DIR = -1, FUNNEL_DIR = -1, GALAXY_DIR = -1,
	-- WEDGE_SWAP = true, STREAK_FLIP = true, FRONT_FACES = true, SWIRL_POINTS = true,
	-- FAR_BEACON = true,
	-- DEBUG = true,
}
local CLEAR = {} -- names to remove, e.g. { "FILM_BEZEL" }
local CLEAR_ALL = false -- true = remove every UPPER_CASE override (back to the defaults in the code)

local m = game:GetService("ReplicatedStorage"):FindFirstChild("AuraFX")
m = m and m:FindFirstChild("TheEnd")
if not m then
	return "ReplicatedStorage.AuraFX.TheEnd not found"
end
if CLEAR_ALL then
	for k in pairs(m:GetAttributes()) do
		if string.match(k, "^%u[%u%d_]*$") then
			m:SetAttribute(k, nil)
		end
	end
end
for _, k in ipairs(CLEAR) do
	m:SetAttribute(k, nil)
end
for k, v in pairs(SET) do
	m:SetAttribute(k, v)
end
local out = {}
for k, v in pairs(m:GetAttributes()) do
	table.insert(out, k .. "=" .. tostring(v))
end
table.sort(out)
return "TheEnd overrides: " .. (#out > 0 and table.concat(out, ", ") or "none (all defaults)")
```

Flags set in Edit mode are saved with the place, and a later install doesn't touch them. After testing, keep only the
ones Milo likes (`CLEAR_ALL = true` resets everything).

### S9. Do the te5 textures load? (Edit)

```lua
-- Edit mode. Asks the engine for every filled-in TEX5 id of the installed module and prints the result of each.
-- (Reads the module's Source, which Edit-mode execute_luau may do. If that is refused, paste the ids into IDS instead.)
local IDS = {} -- e.g. { mote = "rbxassetid://123", ... } (only needed if Source cannot be read)
local ok, src = pcall(function() return game:GetService("ReplicatedStorage").AuraFX.TheEnd.Source end)
local body = ok and string.match(src, "local TEX5 = (%b{})") or ""
local ids, keyOf = {}, {}
for k, v in pairs(IDS) do
	table.insert(ids, v)
	keyOf[v] = k
end
for k, v in string.gmatch(body, "(%w+) = \"([^\"]*)\"") do
	local d = string.match(v, "%d+")
	if d then
		local id = "rbxassetid://" .. d
		table.insert(ids, id)
		keyOf[id] = k
	end
end
local out = {}
game:GetService("ContentProvider"):PreloadAsync(ids, function(id, status)
	table.insert(out, string.format("%s %s", keyOf[id] or id, status.Name))
end)
table.sort(out)
return #ids == 0 and "TEX5 is empty (fallback textures)" or table.concat(out, ", ")
```

## The checklist

Start with `payloads/00_status.luau` (Edit). It should say `the NEW version`.

1. **Installed and compiling.** README step 2 finished with `OK ... installed`. In Play, S2 shows no `TheEnd` errors.
   Do steps 2-3 once with the **fallback textures** (TEX5 empty). Then upload te5 (`upload_textures.md`), install again,
   and repeat them.
2. **Reveal, day and night** (S1, then S2 each time). Start Play. Run S1 with `VIEW = "owner", CLOCK_TIME = 14,
   EQUIP = true, WAIT = 2`, and capture during the assembly: void, then moon, then the rings unfold, then the bezel sweeps
   in, gears, hands lock, and the dais wave. Your screen dims and cools, then comes back. There must be **no pulse and no
   flash**. Run S2: `grade: on`. Capture again at 9 s. Then take these, with `TURN_TO_OPEN = true` the first time:
   - `VIEW = "studio", CLOCK_TIME = 14, WAIT = 21` for day, then `CLOCK_TIME = 0.5, WAIT = 21` for night. Name them
     `real_day_studio.jpg` and `real_night_studio.jpg` if they go to `tools/baseline/pass5/`.
   - `VIEW = "owner"` (Roblox's default zoom, 12.5 studs: since review round 1 the clock steps back, drops a little and
     leans back as the camera comes in, and the orbs come behind you, so the whole dial with XII near the top, the moon
     and the void all fit on screen; check the moon against the stats panel), `"owner25"` (zoomed out to 25: the
     layout eases back to the 40-stud look), `"first"` (first person: the rings and bokeh hide, and the clock rises into
     the sky, out of the level view; look up to see it), and `"high"` (as steep as the camera goes: the clock holds still,
     and you see the crown and bow).
   - S4 orbit at 120 deg/s: the clock trails smoothly and shows its bezel band. No jitter, no snapping. Then flick the
     camera half a turn with the mouse as fast as you can: the clock and the orbs trail by at most ~22° (YAW_LAG_MAX) and
     never swing into the lens.
   - `VIEW = "far"`: past 110 studs the particles stop and details drop, but the shape still reads.
   - `VIEW = "clock"` and `"void"` close-ups: the bezel band is thick, the flutes, the chapter-ring step, gears at 3
     depths, hands above the dial; on the void, the photon ring hugging the silhouette with a gap, the lensed arc, the
     heart and veins, and the disc's near half crossing in front.
   - Then `VIEW = "reset"`.
3. **Movement** (S3, camera from S1 `owner25` or `studio`). `walk` and `fast`: the glide pose, the armillary leans, the
   clock drops, steps back and leans a little more, a short trail of silver streaks streams out behind you, and the void's
   smoke thins (no trail of puffs). `jump` with the place's real jump (JumpHeight 7.2 or JumpPower 50): the dais stays on
   the ground. **Sit on a bench or seat**: the dais stays on the floor (not on the seat), the clock stands behind the seat
   like a throne back, the balance wheel drops onto the dais and the foot drips stop. If your body still floats 2.4 above
   the seat, that is the framework's hover (tell the session: the framework should zero the hover while
   `Humanoid.Sit`). Walk **down a slope or stairs**: the dais keeps up (no lag), the rings never dip into it. `air`: the
   dais floats about 2.4 under the feet. Also try a short avatar (a small bundle): nothing cuts the dais. For R6, use S5 with `RIG = "r6", IS_LOCAL = true, QUALITY = "high"`. The palm streams and foot drips find the R6
   arms and legs.
4. **Day colour.** By day with `VIEW = "studio"`, run S7 `ON = false`, capture, then `ON = true`, capture. With the
   Highlight on, silver looks neutral, not cyan. The black void stays **pure black** in every shot.
5. **Low quality.** S5 with `QUALITY = "low"` (and `IS_LOCAL = true` to see the assembly). S2 with
   `WHO = "TheEndBench1"`: 149 parts, 12 emitters (the speed trail is off while you stand still), 2 beams, 8 GUIs,
   0 lights. It must still read as the clock, armillary,
   moon, void and dais. By hand: Test -> Device (a phone) or Esc -> Settings -> Graphics Quality 1-3, then rejoin. The
   framework picks low on phones and low graphics.
6. **Other players.** S5 with `IS_LOCAL = false, QUALITY = "high"`. The stand-in's clock stands on the far side of the
   stand-in **from your camera** (S2 says `clock on the far side: true`). Its assembly plays and there is no grade on your
   screen. Walk so the stand-in is **between you and your camera**: its clock, rings and orbs fade to a see-through ghost
   (in 3 quick steps) and come back 0.6 s after it is clear; your own character stays visible. For real: Milo can use Test -> Clients and Servers -> 2 players and watch Player1 equip from Player2's window.
7. **Flow directions** (watch it live, or compare two captures about 0.5 s apart). The streams flow from each orb **into**
   the palm, and the ribbon flows down from the void to the dais (all four use one sign: if they run backwards, S8
   `FLOW_SIGN = -1`). The accretion streaks trail their spin (else `ACC_DIR = -1`), the galaxy arms trail theirs (else
   `GALAXY_DIR = -1`), the floor vortex winds with the arms (else `FUNNEL_DIR = -1`). Re-equip after each flip.
8. **Particle shapes** (close-ups). The matter around the void spirals **inward**, and so does the funnel under the feet
   (if they spray as flat sheets over the disc: `SWIRL_POINTS = true`). The palm intake converges on the palm. The rim
   glints sit on the bezel annulus, not across the dial. Metal shards break off around 10-11 o'clock and fly into the
   void. Ink smoke boils off the void and silver smoke off the moon, both curling outward and up.
9. **Film-mesh flags.** For each of `FILM_BEZEL, FILM_DIAL, FILM_RETE, FILM_HANDS, FILM_GEARS, FILM_MOON, FILM_VOID`:
   stop Play, run S8 with `CLEAR_ALL = true` and `SET = { USE_FILM_MESHES = true, <FLAG> = true }`, start Play, run S1
   `VIEW = "studio", EQUIP = true, WAIT = 9`, capture and note what you see. If the film hands point at the hub, also set
   `FILM_HAND_FLIP = true`. Keep only the flags Milo likes (S8 again). Without the film meshes in
   `ReplicatedStorage.AuraCinema.Assets.TheEnd`, each flag silently falls back to the built clock.
10. **Performance.** S2's frame time before equipping, after equipping, and with S5 `COUNT = 2` (3 wearers on screen).
    The target is less than 1.5 ms more per frame for one wearer on the Mac. Then open the MicroProfiler (Ctrl+F6) in
    Play with 1 and with 3 wearers, on high and with the low graphics level, and write down: the Luau time of the aura's
    update (target under 0.6 ms per wearer on the Mac) and the `BulkMoveTo` and `Highlight` scopes (target under 1 ms
    together). If it is over, the next pass welds each rigid group to one root after the assembly and moves ~45 roots.
11. **Auto roll.** With Auto roll on and THE END equipped, watch a few normal rolls: if the roll animation switches the
    camera to Scriptable, the aura is hidden and shown again; since review round 1 it fades back in over 0.4 s (and the
    foot drips wait a second) instead of popping. Report anything that still pops.
12. **Textures load.** After the te5 upload, stop Play and run S9: every te5 id should say `Success`. (The module checks the same in the
    background and falls back to the pass-4 texture for any that fails, with a warning in the Output.)
13. **Wrap up.** Stop Play. Write the report (below). Update `docs/memory/aura-rng.md` (and the Mac project's
    `CHANGELOG.md`). Show Milo the thumbnails.

## STUDIO-VERIFY items

The module marks what only Studio can answer with `-- STUDIO-VERIFY:` comments. Get the current list with
`grep -n "STUDIO-VERIFY" roblox/ReplicatedStorage/AuraFX/TheEnd.lua`. Each comment says what's assumed and the fix if it's
wrong. The spec's list (§19) and how to see each one:

| item | how to see it | right if |
|---|---|---|
| Disc emitter ShapePartial = inner-radius fraction | close-up of the clock (rim glints) | glints only on the bezel ring (R 12.2-14.2), none across the dial |
| Inward Cylinder / Sphere emitters | `void` close-up; funnel under the feet; palms | void matter and funnel spiral inward; palm motes converge on the palm |
| LockedToPart on a spinning BulkMoveTo host | void and galaxy motes | motes swirl with the spin (spirals), not straight lines |
| Wedge orientation | `void` close-up: the heart's 4 spikes | solid four-point star; hollow or notched spikes mean the ±90° halves need swapping |
| SurfaceGui Face Back / Left mapping | `clock` close-up | inlay numerals face the viewer with XII up; the sub-dial face is on the front |
| Beam TextureSpeed direction | live view of the streams and ribbon | flow goes orb -> palm, and void -> dais |
| Highlight on a Model of 200+ parts | day `studio` shot, S7 on/off | the whole silver model is toned evenly; no part is missing it |
| Neon black under Bloom | night and day shots of the void | the void core is pure black, with no grey glow |
| PointLight on an attachment of a moving part | night shots, S1 `air` and `walk` | the moon's key light and the wheel underlight move with the aura |
| te5_streak orientation (VelocityParallel) | funnel, palm and speed-trail streaks, after the te5 upload | the bright end leads; if tail-first: S8 `STREAK_FLIP = true` |
| te5_ash 2x2 flipbook (now 1024², 512-px cells) | galaxy ash, after the te5 upload | four different single flakes; one flake must never show as 4 tiny ones |
| RenderFidelity on cloned film meshes | film flags on | no error in the Output (it's in a pcall) |
| Cylinder + Surface emitters and their end caps | void close-up; funnel under the feet | matter moves inward in rings; if it sprays as a flat sheet: `SWIRL_POINTS = true` |
| SurfaceGui Back face on the inlay / corona | `clock` close-up, night corona | if mirrored or on the wrong side: `FRONT_FACES = true` (pass 4's proven Front faces) |
| The moon's photographic face (te5_moon) | moon close-up and at the screen edge | a full moon, no grey ball poking out at its side; if one does, report it (the core is 6 studs, the face 9) |
| Neon colours stay neutral | night, Bloom on: compare the lume plots / heart with a white SmoothPlastic part | white, not pale blue |
| Moving PointLights | night, high quality | the moon's light moves smoothly on the ground (the module has no light on low quality) |
| Another wearer between you and your camera | 2 players, or S5 `IS_LOCAL = false` | their aura ghosts and returns; nothing of theirs stays opaque across your character |
| The speed trail direction | walk / fly fast | silver streaks stream out **behind** you; if they lead: `STREAK_FLIP = true` |

## Reporting back

Write `docs/the-end/pass5-studio-results.md` in the repo (template below). Keep shots that are worth comparing, after
checking no username or chat shows: `tools/baseline/pass5/real_<what>.jpg`, small JPEGs. Then update
`docs/memory/aura-rng.md`: what is installed now (bytes + checksum), the te5 ids, what worked, what didn't, Milo's words,
and what's next. Ask Milo before committing or pushing.

```markdown
# THE END pass 5: Studio results (YYYY-MM-DD, Mac)

Installed: ReplicatedStorage.AuraFX.TheEnd = <bytes> bytes, checksum <n> (make_payloads: <n> pieces, all OK; apply OK)
Backup: ServerStorage.AuraRNG_Backups.<name>  ·  textures: fallbacks | te5 (ids in textures/te5/uploaded.md)

## Checklist
| # | check | result (what was seen) | shot |
|---|---|---|---|
| 2 | reveal: no pulse/flash, grade dims and returns | | |
| 2 | day / night (studio camera) | | real_day_studio.jpg / real_night_studio.jpg |
| ... | | | |

## STUDIO-VERIFY
| item | result | fix applied (file:line) |
|---|---|---|

## Numbers (S2)
high: parts / emitters / rate / GUIs / beams / lights, frame ms before vs after equip, 3 wearers
low:  ...

## Warnings / errors in the Output
## Milo said
## Next
```
