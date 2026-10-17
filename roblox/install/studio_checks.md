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
  Review round 3: `FRAME_TOP` (how much of the watch the owner's camera always keeps in frame: 9.6 = up to XII, the
  default; 22.4 = the whole watch with its bow; 0 = off) and `RIM_R` (where the pass-2 "rim" texture's ring peaks, check
  14: the night corona, the void's horizon glow and the moon halo are scaled by it until te5_halo is uploaded).

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

Budget (spec §14, review round 3). High quality: 360 parts, 17 emitters in the model (the other 2 of the spec's 19 are
the body's wisps and sparks on the character's torso, outside the model), total Rate under 200/s, 6 beams, 11 GUIs,
2 lights (on at night only) and 1 highlight. Low quality: 150 parts, 10 emitters (+2 on the torso), under 80/s, 2 beams,
8 GUIs, no lights. (These are the module's numbers in the cloud's mock world; Studio may differ.)

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
removes them after `SECONDS`, or when you run S6. **It runs its own copy of the module** (`require` from `execute_luau`
runs as a plugin, with its own module cache), which shares nothing with the aura the game's framework loaded: not the screen
grade, not the texture fallback. So **unequip THE END before using `IS_LOCAL = true`** (two "own" auras would share one
grade), and check the grade (start, take-over, ease-out) and the te5 load fallback only with real equips (S1 `EQUIP = true`,
S9). Use it for another player's aura (`IS_LOCAL = false`: no grade, and the
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
	-- FRAME_TOP = 22.4, RIM_R = 0.8,
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

Start with `payloads/00_status.luau` (Edit). It should say `the NEW version`. It also lists the module's **CONFIG overrides**
(attributes): they survive an install and a rollback and change every build. If it lists any you did not set in this session
(a flip left over from an earlier test), clear them first: S8 with `CLEAR_ALL = true`.

1. **Installed and compiling.** README step 2 finished with `OK ... installed`. In Play, S2 shows no `TheEnd` errors.
   Do steps 2-3 once with the **fallback textures** (TEX5 empty). Then upload te5 (`upload_textures.md`), install again,
   and repeat them.
2. **Reveal, day and night** (S1, then S2 each time). Start Play. Run S1 with `VIEW = "owner", CLOCK_TIME = 14,
   EQUIP = true, WAIT = 2`, and capture during the assembly: void, then moon, then the bezel sweeps in, gears, hands
   spin in, and the dais wave. At this close zoom the rings lie flat on the dais until the hands have reached five to
   midnight, then rise and close round you (review round 3: risen earlier, the meridian stood across the dial).
   **Pass 5.2's reveal** (about 4.6 s to 10 s after equipping; captures at 5.5, 6.7, 7.2 and 9 s): the energy links light
   up along their length (moon to IX, III to the void, VI down to the floor), the hour plots light one by one round the
   dial, I first and XII last, the gears race, the void's smoke draws in close, streaks converge on the clock, a golden
   light sweeps once round the stage. The minute hand ticks from XI to XII a minute at a time; the fifth tick is
   midnight: the gears stop dead for a moment and **one soft pulse** goes out (a ring off the moon, a wave across the
   floor with streaks racing out with it, glints off the dial that slow into orbit, sparks lifting off the floor, the
   void's smoke blown out), then everything settles. Your screen dims and cools, blooms softly at midnight and the
   view pushes in a little (the field of view narrows about 6 %), then all of it comes back exactly. That one pulse is
   the only one: **no other pulse, strobe or flash**, before or after, and the hands visibly lock at XII **inside the
   frame**. Run S2: `grade: on`. Capture again at 11 s. Then take these, with `TURN_TO_OPEN = true` the first time:
   - `VIEW = "studio", CLOCK_TIME = 14, WAIT = 21` for day, then `CLOCK_TIME = 0.5, WAIT = 21` for night. Name them
     `real_day_studio.jpg` and `real_night_studio.jpg` if they go to `tools/baseline/pass5/`.
   - `VIEW = "owner"` (Roblox's default zoom, 12.5 studs: the clock stands 32 studs further back, drops a little and
     leans back as the camera comes in, and the orbs come down and move well behind you, so the whole dial with XII, the
     moon (about the dial's size, beside it, clear of the stats panel) and the void fit on screen. At **every** zoom the
     dial and the hands at XII stay in frame: the clock steps back along the view as needed (review round 3); scroll
     slowly from 12.5 to 60 studs and tilt the camera up and down: the clock glides back and forth smoothly and never jumps.
     To see the crown and bow, tilt the camera up a little or scroll out past ~50 studs, or try S8 `FRAME_TOP = 22.4`
     (the whole watch, smaller at the default zoom) and ask Milo which he likes. Close up the ink outline on the silver is
     lighter and the silver fill stronger (no pale-cyan rings)), `"owner25"` (zoomed out
     to 25: the layout eases back to the 40-stud look), `"first"` (first person: the rings fade out, the clock rises into
     the sky; **turn left and right**: since review round 2 the clock and the orbs follow where you look, so the void and
     the moon never fill the view, the palm streams, the funnel and palm streaks, the air's sparkles and the body's wisps
     and sparks are off: no needles or flakes across the lens), and `"high"` (as steep as the camera goes: the clock
     holds still, and you see the crown and bow). Zoom slowly between 8 and 13 studs: the rings fade out and back in
     three soft steps (never snap), and **no grey or outlined ring silhouette** stays behind while they fade (review round 3
     takes the fading rings out of the silver Highlight).
   - S4 orbit at 120 deg/s: the clock trails smoothly and shows its bezel band. No jitter, no snapping. Then flick the
     camera half a turn with the mouse as fast as you can: the clock and the orbs trail by at most ~22° (YAW_LAG_MAX) and
     never swing into the lens.
   - `VIEW = "far"`: past 110 studs the particles stop and details drop, but the shape still reads.
   - `VIEW = "clock"` and `"void"` close-ups: the bezel band is thick, the flutes, the chapter-ring step, gears at 3
     depths, hands above the dial; on the void, the thin photon ring hugging the silhouette with a gap, the **lensed
     disc** (review round 3: a bright band arching over the black shadow and a thinner one under it, like the film
     Interstellar's black hole; no ink stick down to the dais any more), the small heart, the soft horizon glow at night,
     the disc's near half crossing in front, and dense ink smoke boiling off it (black on the day sky, not teal). On the moon: the face is
     whole (nothing silver painted over it where it overlaps the bezel), and its smoke does not veil it grey.
   - Then `VIEW = "reset"`.
3. **Movement** (S3, camera from S1 `owner25` or `studio`). Standing still, silver wisps rise off your shoulders and back
   and sparks stream up your body (review round 3). `walk` and `fast`: the glide pose (the armillary stays upright
   since review round 2: your head stays visible from the follow camera), the clock drops, steps back and leans a little more, a short trail of silver streaks streams out behind you, the wisps stop
   and the sparks stream out behind like a comet's tail, and the smoke thins and dies young (no grey smog patches left
   hanging 20-30 studs behind you). `jump` with the place's real jump (JumpHeight 7.2 or JumpPower 50): the dais stays on
   the ground, and the clock and the orbs barely move (they ride a heavy spring: no 28-stud watch bouncing on every jump). **Sit on a bench or seat**: the dais stays on the floor (not on the seat), the clock stands behind the seat
   like a throne back and the balance wheel drops onto the dais. If your body still floats 2.4 above
   the seat, that is the framework's hover (tell the session: the framework should zero the hover while
   `Humanoid.Sit`). Walk **down a slope or stairs**: the dais keeps up (no lag), the rings never dip into it. **Stand still
   on a slope of about 10°** (a hill, the beach): since review round 3 the pool and the engraved stage tilt to lie along
   the ground (no black plate half buried in the hill on one side and floating on the other); on stairs and at a cliff
   edge they stay level. **Teleport** (a pad, or `plr.Character:PivotTo(...)` 60 studs up from the command bar): the
   clock and the orbs arrive with you at once (they do not slide across the sky). `air`: the
   dais floats about 2.4 under the feet. Also try a short avatar (a small bundle): nothing cuts the dais. For R6, use S5 with `RIG = "r6", IS_LOCAL = true, QUALITY = "high"`. The palm streams find the R6
   arms and the body's wisps rise from the R6 Torso.
4. **Day colour.** By day with `VIEW = "studio"`, run S7 `ON = false`, capture, then `ON = true`, capture. With the
   Highlight on, silver looks neutral, not cyan or baby-blue (review round 2 made the silvers neutral). Then an A/B of the
   fill strength: S8 `HIGHLIGHT_FILL = 0.8` (weaker fill: the metal keeps more of its own light and dark), re-equip,
   capture, compare with the default 0.65, and keep the one Milo likes. The black void stays **pure black** in every shot.
5. **Low quality.** S5 with `QUALITY = "low"` (and `IS_LOCAL = true` to see the assembly). S2 with
   `WHO = "TheEndBench1"`: 163 parts, 12 emitters in the model, 10 on (+2 on the torso; the speed trail is off while
   you stand still, the floor's wave only fires at midnight), 4 beams (the two streams and two energy links), 8 GUIs,
   0 lights. It must still read as the clock (with the four-point central star), armillary,
   moon, void and dais. The meridian reads as a ring, not a lumpy polygon (review round 3: 18 segments on low), and the
   void's heart is a round pinpoint (no slit pupil). By hand: Test -> Device (a phone) or Esc -> Settings -> Graphics Quality 1-3, then rejoin. The
   framework picks low on phones and low graphics.
6. **Other players.** S5 with `IS_LOCAL = false, QUALITY = "high"`. The stand-in's clock stands on the far side of the
   stand-in **from your camera** (S2 says `clock on the far side: true`). Its assembly plays and there is no grade on your
   screen. Walk so the stand-in is **between you and your camera**: its clock and orbs fade to a see-through ghost (in 3
   quick steps), together with its smoke and streams, and come back 1.2 s after it is clear; your own character stays
   visible. Then stand **beside** it (5 studs to its side): only its rings go see-through, as glass with no grey or
   outlined silhouette across your body; its clock, orbs and dial stay solid. With **two real players both wearing THE
   END** (Test -> Clients and Servers -> 2 players; S5's stand-ins run their own copy of the module, so they cannot see
   your aura), stand side by side and then one behind the other: **the other player's clock and orbs step back behind
   your own clock** (review round 3), so yours is never hidden; theirs glides back, smaller, and stays solid. With two wearers 10 studs apart, orbit the camera
   and look where the two galaxy pools and engraved stages overlap: **no crawling shimmer**, and **your own pool is on
   top** and stays on top as you orbit (review round 3 lifts your own pool above everyone else's). If the two swap as
   you orbit, write it down: the next pass hides the overlapping part of the other pool instead. For real: Milo can use Test -> Clients and Servers -> 2 players and watch Player1 equip from Player2's window.
7. **Flow directions** (watch it live, or compare two captures about 0.5 s apart). The streams flow from each orb **into**
   the palm (all four use one sign: if they run backwards, S8 `FLOW_SIGN = -1`; the void's lensed bands share the sign
   and read either way). The accretion streaks trail their spin (else `ACC_DIR = -1`), the galaxy arms trail theirs (else
   `GALAXY_DIR = -1`), the floor vortex winds with the arms (else `FUNNEL_DIR = -1`). Re-equip after each flip.
8. **Particle shapes** (close-ups). The matter around the void spirals **inward**, and so does the funnel under the feet
   (if they spray as flat sheets over the disc: `SWIRL_POINTS = true`). The palm intake converges on the palm. The
   time-dust glints ride a ring just outside the bezel (none across the dial). Metal shards break off around 10-11 o'clock
   and fly into the void. Ink smoke boils off the void and silver smoke off the moon, both curling outward and up. The
   floor rises in slow four-point twinkles (not white pearls), a field of sparkles fills the air round the whole aura,
   and the mist banks round the pool's rim, not across the galaxy.
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
    Also: count the Highlights in a 2-player test with Milo's other auras equipped (`local n = 0 for _, d in
    game:GetDescendants() do if d:IsA("Highlight") and d.Enabled then n += 1 end end print(n)`): Roblox draws at most 31;
    THE END uses one for your own aura, and other players' only while near (none on low quality). With 3 wearers 150 studs
    away, the MicroProfiler should show their updates at half rate. And the texture memory: F9 -> Memory ->
    GraphicsTexture before and after equipping, on a phone (Test -> Device) at graphics level 1-3; if THE END adds more than
    ~40 MB on low, the next pass uploads 512² variants of the inlay, floor and star window for low quality.
11. **Auto roll.** With Auto roll on and THE END equipped, watch a few normal rolls: if the roll animation switches the
    camera to Scriptable, the aura is hidden and shown again; since review round 1 it fades back in over 0.4 s (and the
    body's wisps and sparks wait a second) instead of popping. Report anything that still pops. **Then roll THE END itself** (or equip
    it while a roll film plays): run S2 while the film plays: it must print `grade: none` (the grade and the assembly wait
    for the first frame you can see, whether or not the framework keeps updating hidden auras), and after the film the whole
    assembly plays in front of you.
12. **Textures load.** After the te5 upload, stop Play and run S9: every te5 id should say `Success`. (The module checks the same in the
    background and falls back to the pass-4 texture for any that fails, with a warning in the Output; a time-out is asked for
    once more 20 s later.) Fallback test: set `TEX5.moon` to a bad id in a scratch copy, equip: the face must come back as
    pass 4's moon, cropped round and dimmer (0.75 by day), not a white plate; set `TEX5.halo` to a bad id: the night
    corona must still glow just outside the bezel (not a separate circle further out).
13. **Reset with THE END on** (review round 3). Reset your character (Esc -> Reset) with THE END equipped, and run S2 as
    soon as you respawn: it must print `grade: none` (a respawn rebuilds the aura; it is not an equip). Then unequip and
    equip it again on the same character: `grade: on`.
14. **The pass-2 rim texture** (before the te5 upload; review round 3). Until te5_halo is uploaded, the night corona, the
    void's horizon glow and the moon halo draw the pass-2 `rim` texture, and the module sizes them by where its ring
    peaks (`RIM_R`, a guess of 0.86 of the half-width). Measure it on the Mac: `python3 -c "from PIL import Image; import
    numpy as n; a=n.asarray(Image.open('PATH/TO/rim.png').convert('RGBA')).astype(float)[...,3]; h,w=a.shape;
    y,x=n.mgrid[:h,:w]; r=n.hypot(x-(w-1)/2,y-(h-1)/2)/(w/2); b=n.round(r*50).astype(int); m=[a[b==k].mean() if (b==k).any()
    else 0 for k in range(50)]; print('RIM_R =', m.index(max(m))/50)"` with the pass-2 rim PNG from `aura_work/tex3`.
    If it is not about 0.86, set the attribute (S8 `RIM_R = <value>`). At night before te5: the corona glows just outside
    the bezel (not a separate thin circle) and the void's horizon glow touches its black edge.
15. **Hairlines far away** (review round 3). On a phone (Test -> Device) or at graphics level 3-5, watch a wearer from 60
    to 150 studs while the camera moves: the void's photon ring and the seconds hand stay steady lines (they thicken in two
    steps with distance), never a crawling stair-step.
16. **The far beacon** (Milo decides). Stand 200 studs from a wearer (S5 stand-in, `IS_LOCAL = false`), by day and by
    night. One screenshot with `FAR_BEACON` off (the default) and one with it on (S8 `FAR_BEACON = true`, re-equip).
    Show Milo both and ask which he wants: it changes what everyone in the server sees. Write his answer in the report and
    set the attribute to match.
17. **Pass 5.2 details** (with the te5 textures uploaded; captures with S1 `VIEW = "clock"`, `"void"` and `"studio"`).
    The bezel has a **dark band** between bright silver lips, engraved with a fine degree scale that creeps round
    anticlockwise (a degree a second), never painted over grey by the silver tone. A polished ring frames the star window.
    The **central star** is eight solid faceted points (bright silver on one half, gunmetal on the other), not hollow
    (if hollow: `WEDGE_SWAP = true`, which also fixes the void's heart); the sub-dial turns slowly under it. The hour and
    minute hands each have a **Breguet moon** (a ring with a dark eye) near the tip. A soft **comet of light rides the
    seconds hand** round the minute track, head at the hand, tail behind it, lighting the hours as it passes. A bright
    segment of light runs round the meridian and the equator. The **void's photon ring** is thickest and whitest on the
    side facing the clock and a fine hair on the far side; its heart has a slow glint with rays; thin ink tendrils curl
    between the smoke's billows, which now have gaps; matter spirals into the void from every side. The moon wears a broad
    soft glow (a pale haze by day), a ring of glints orbits it, and its face rocks a few degrees over ~47 s. Over the
    galaxy: a **fine fast swirl** (its arms trail its spin, like the floor's: else `GALAXY_DIR` for all of them), **rings of
    energy** turning slowly with a bright boundary ring, and motes streaming in along **two spiral arms** that stand still
    on the floor (if they spin like wheels or point like spokes, write it down). The **stage is gold on black**, readable by
    day and night, never glowing so much the detail goes (at night 1.25, under the Bloom threshold). The three **energy
    links** are thin threads with soft pearls of light gliding along them; by day only the pearls may read, which is
    intended (restrained). In first person they are off.
18. **Wrap up.** Stop Play. Write the report (below). Update `docs/memory/aura-rng.md` (and the Mac project's
    `CHANGELOG.md`). Show Milo the thumbnails.

## STUDIO-VERIFY items

The module marks what only Studio can answer with `-- STUDIO-VERIFY:` comments. Get the current list with
`grep -n "STUDIO-VERIFY" roblox/ReplicatedStorage/AuraFX/TheEnd.lua`. Each comment says what's assumed and the fix if it's
wrong. The spec's list (§19) and how to see each one:

| item | how to see it | right if |
|---|---|---|
| Disc emitter ShapePartial = inner-radius fraction | close-up of the clock (the time-dust ring, ShapePartial 0.9) and the dais (the mist, 0.8) | glints only on a ring just outside the bezel (R 14.2-15.8), none across the dial; the mist banks round the pool's rim, not across the galaxy |
| Inward Cylinder / Sphere emitters | `void` close-up; funnel under the feet; palms | void matter and funnel spiral inward; palm motes converge on the palm |
| LockedToPart on a spinning BulkMoveTo host | void and galaxy motes | motes swirl with the spin (spirals), not straight lines |
| Wedge orientation | `void` close-up: the heart's 4 spikes | solid four-point star; hollow or notched spikes mean the ±90° halves need swapping |
| SurfaceGui Face Back / Left mapping | `clock` close-up | inlay numerals face the viewer with XII up; the sub-dial face is on the front |
| Beam TextureSpeed direction | live view of the streams | flow goes orb -> palm (the void's lensed bands share the sign; either way reads) |
| Highlight on a Model of 200+ parts | day `studio` shot, S7 on/off | the whole silver model is toned evenly; no part is missing it |
| Neon black under Bloom | night and day shots of the void | the void core is pure black, with no grey glow |
| PointLight on an attachment of a moving part | night shots, S1 `air` and `walk` | the moon's key light and the wheel underlight move with the aura |
| te5_streak orientation (VelocityParallel) | funnel, palm and speed-trail streaks, after the te5 upload | the bright end leads; if tail-first: S8 `STREAK_FLIP = true` |
| te5_ash (review round 2: one 256² flake, no flipbook) | galaxy ash, after the te5 upload | single black flakes tumbling, each at its own angle; never 4 tiny flakes in one |
| RenderFidelity on cloned film meshes | film flags on | no error in the Output (it's in a pcall) |
| Cylinder + Surface emitters and their end caps | void close-up; funnel under the feet | matter moves inward in rings; if it sprays as a flat sheet: `SWIRL_POINTS = true` |
| SurfaceGui Back face on the inlay / corona | `clock` close-up, night corona | if mirrored or on the wrong side: `FRONT_FACES = true` (pass 4's proven Front faces) |
| The moon's face disc (review round 2: an opaque part turned to the camera, SurfaceGui on its Left face, a UICorner on the image) | moon close-up, at the screen edge, and where it overlaps the bezel | te5: the real moon, **not mirrored** (the big dark maria upper left), whole even where it overlaps the bezel (no silver painted over it), no grey veil of its own smoke; before te5: pass 4's moon cropped to a round disc, no square corners or white ring round it |
| Neon colours stay neutral | night, Bloom on: compare the lume plots / heart with a white SmoothPlastic part | white, not pale blue |
| Moving PointLights | night, high quality | the moon's light moves smoothly on the ground (the module has no light on low quality) |
| Another wearer between you and your camera | 2 players, or S5 `IS_LOCAL = false` | their aura ghosts and returns; nothing of theirs stays opaque across your character: **no dark smoke or ink stream** either (beams and particles take `LocalTransparencyModifier` since review round 2) |
| Another wearer beside you | 2 players side by side | only their rings ghost; their clock, orbs and dial GUIs stay solid |
| Two pools side by side | 2 or 3 wearers 10 studs apart, orbit the camera | no crawling seam where the galaxy pools / engravings overlap; your own pool is on top and does not swap as you orbit (if it swaps, Roblox sorts the SurfaceGuis per object: report it) |
| The far-detail switch at ~110 studs (night) | walk away from a wearer past 110 studs and back | the lit patch under the moon fades in 0.5 s, never pops; the thin streams fade too |
| The time-dust ring | clock at 30-40 studs, day and night | a slow ring of small glints just outside the bezel, turning clockwise with the hands; no flashing |
| The speed trail direction | walk / fly fast | silver streaks stream out **behind** you; if they lead: `STREAK_FLIP = true` |
| (round 3) A Highlight on parts with `LocalTransparencyModifier` | by day zoom slowly from 13 to 8 studs; and S5 `IS_LOCAL = false` with the stand-in 5 studs beside you | the rings fade with no grey or ink-outlined silhouette left behind and nothing snaps; the stand-in's ghosted rings read as glass, with no ink edges across your body (the module moves fading rings out of the Highlight; this checks that it is enough) |
| (round 3) The owner's frame fit | scroll from 12.5 to 60 studs, tilt the camera up and down | XII always in frame; the clock glides back and forth, never jumps; at 40 studs from the `studio` camera it stands where it always did |
| (round 3) The rings wait for the hands at the default zoom | equip at 12.5 studs | the rings lie flat on the dais while the hands spin and lock at XII, then rise; at 30+ studs they rise first, as before |
| (round 3) The dais on a slope | stand on a ~10° hill or the beach, then on stairs | the pool and the stage lie along the slope; on stairs and cliff edges they stay level; no tilting back and forth |
| (round 3) The void's lensed bands | `void` close-up, day and night | a bright band arching over the shadow and a thinner one under it, flowing smoothly; not cut by the accretion disc's plane; slimmer at the default zoom |
| (round 3) Particle sorting | day close-ups of the floor and the void | the floor's twinkles and ash draw over the galaxy floor, and the swirl over the accretion disc (their carriers sit above those planes, so this should hold whichever way Roblox sorts) |
| (round 3) Hairlines without anti-aliasing | phone / graphics 3-5, a wearer 60-150 studs away, camera moving | the photon ring and the seconds hand do not crawl |
| (round 3) Texture memory per build | phone, F9 -> Memory -> GraphicsTexture with one wearer on low | lower than round 2's measurement: low builds no longer load the six high-only te5 textures |
| (round 3) The silver tint at the default zoom | by day, `VIEW = "owner"` | the rings read silver, not pale cyan (the fill strengthens close up); if still cool, the next pass warms the day FillColor to (220, 212, 206) while the camera is close |
| (round 3) The ink smoke by day | `void` and `owner` views, ClockTime 14 | the void's smoke reads as black ink on the sky, not a teal haze (te5_smoke is a dense billow now) |
| (round 3) The pass-2 rim radius (`RIM_R`) | check 14 | the night corona hugs the bezel before the te5 upload |
| (5.2) One pulse, at midnight only | check 2, captures from 4.5 to 11 s after equipping | the hands tick from XI to XII; exactly one pulse, on the fifth tick; nothing else flashes, before or after |
| (5.2) The wearer's screen is given back | S2 before equipping, during the reveal and at 12 s; `print(workspace.CurrentCamera.FieldOfView)` | `TheEndBloom` is under the Camera only during the reveal and gone after; the field of view is exactly what it was before; `Lighting` is never touched; nothing happens on another player's screen |
| (5.2) The push-in lets go | with a script or the command bar, set `workspace.CurrentCamera.FieldOfView = 80` during the buildup | the aura stops touching the field of view at once and leaves it at 80 |
| (5.2) The central star's facets (WedgeParts) | `clock` close-up | eight solid points, bright on the half to the left of each point's tip; hollow ones mean `WEDGE_SWAP = true` (the void's heart uses the same flag) |
| (5.2) The bezel band | `clock` close-up, day | the dark band sits just proud of the flutes all round (no flicker against them), its engraving crisp and white, not greyed by the silver tone; it creeps round anticlockwise |
| (5.2) The seconds hand's trail | `clock` close-up, watch a few seconds | the comet's head is at the seconds hand and its tail behind it (if it leads: the dial's GUIs are mirrored too, see `FRONT_FACES`) |
| (5.2) The energy links | `studio` and `owner` views, day and night | thin bowed threads from the moon into IX, from III into the void, from VI down to the floor, pearls gliding along them; none crosses the moon's face or the dial; they light up along their length in the reveal |
| (5.2) The floor's wave (VelocityPerpendicular) | night, `studio` and `owner` views at midnight | one flat ring grows from under you to the stage's edge in ~1.7 s, lying on the floor (not standing up facing you), streaks racing out with it |
| (5.2) The dial's glints (Cylinder + Outward on a carrier turned to the dial) | `clock` view at midnight | glints burst outward in the dial's plane, slow down and orbit round it for a few seconds; if they fly at the camera, write it down |
| (5.2) The spiral arms (attachments moved every frame) | `owner` view, look down at the pool | two arms of motes stand still on the floor and stream in toward the centre |
| (5.2) The gold stage | day and night, `studio` and `owner` views | gold markings on a black base, crisp; the golden sweep in the reveal goes round head first |
| (5.2) The photon ring's highlight | `void` close-up | thickest and whitest on the side facing the clock, a fine hair on the far side |
| (5.2) Particles in front of silver under the Highlight | by day, `clock` view at midnight | the flare at the hub and the glints over the rete still read (the silver tone's fill composites over particles in front of silver parts; the flare is big so its rays reach the dark dial) |
| (5.2) Cost | check 10 with pass 5.2 | 454 parts (163 low), ~41 emitters (13 low): the frame time and MicroProfiler numbers, compared with pass 5.1 if you have them |

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
| 2 | reveal: one pulse at midnight only; the grade, bloom and push-in come and go | | |
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
