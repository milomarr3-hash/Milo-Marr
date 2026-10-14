-- scenarios: deterministic test situations. Each one sets the world up, then step(t, dt) moves the wearer(s) and the
-- camera and fires events (destroy, re-equip, visibility toggles, respawn). The ground is a plaza at y = 0.
do
	local D = H.INST_DATA
	local v3 = H.v3
	local CFrame, Vector3 = H.CFrame, H.Vector3
	local sin, cos, rad, pi, exp, min, max = math.sin, math.cos, math.rad, math.pi, math.exp, math.min, math.max
	local E = function(en, it) return H.enumItem(en, it) end

	-------------------------------------------------------------------------------------- helpers
	local function placeWearer(rec, pos, yaw, moveDir)
		local d = D[rec.hrp]
		d.props.CFrame = CFrame.new(pos.X, pos.Y, pos.Z) * CFrame.Angles(0, yaw, 0)
		H.propagate(rec.hrp)
		D[rec.hum].props.MoveDirection = moveDir or Vector3.zero
		local onGround = pos.Y <= 3.05
		D[rec.hum].props.FloorMaterial = onGround and E("Material", "Sand") or E("Material", "Air")
		D[rec.hum].state = onGround and (moveDir and moveDir.Magnitude > 0 and E("HumanoidStateType", "Running") or E("HumanoidStateType", "Running"))
			or E("HumanoidStateType", "Freefall")
	end
	H.placeWearer = placeWearer
	local camState = nil
	local function setCamera(pos, look, smooth, dt)
		local target = CFrame.lookAt(pos, look)
		if smooth and camState then
			local a = 1 - exp(-(dt or H.DT) * smooth)
			target = camState:Lerp(target, a)
		end
		camState = target
		local cd = D[H.camera]
		cd.props.CFrame = target
		cd.props.Focus = CFrame.new(look)
		if cd.sig or cd.psig then H.propChanged(H.camera, cd, "CFrame") end
	end
	H.setCamera = setCamera
	-- Roblox's default follow camera: behind the character's facing, up a little, looking at the CameraSubject focus. The
	-- PlayerModule's focus is HumanoidRootPart + (0, 1.5, 0) (R15 head offset); the aura's hover moves the body through the
	-- Root joint, not the HumanoidRootPart, so the focus does not rise with it (checked against the real pass-4 Studio
	-- captures: with this focus the "studio" camera puts the wearer's feet and the clock where the screenshots have them)
	local function followCam(rec, dist, height, dt, sideYaw)
		local hcf = H.rawGet(rec.hrp, "CFrame")
		local yaw = math.atan2(-hcf.LookVector.X, -hcf.LookVector.Z) + (sideYaw or 0)
		local off = CFrame.Angles(0, yaw, 0) * v3(0, height, dist)
		local focus = hcf.Position + v3(0, 1.5, 0)
		setCamera(focus + off, focus, 6, dt)
	end
	H.followCam = followCam

	-- camera override (run_aura.py --camera SPEC, or a scenario name with an @SPEC suffix such as day_idle@front34): the
	-- scenario runs as usual, then the camera is put where the spec says, relative to the main wearer, every frame. The aura
	-- sees this camera (a viewer-anchored clock is placed for it), and the snapshot's camera is the render camera.
	--   kind "orbit":   the preview renderer's view presets (tools/preview/web/views.js): azimuth from the wearer's front
	--                   toward their right, elevation, distance, aimed at body + ty (body = HumanoidRootPart + hover)
	--   kind "subject": Roblox's Custom camera as the Mac session's Studio captures set it up: CameraSubject focus =
	--                   HumanoidRootPart + (0, 1.5, 0) (PlayerModule R15 head offset), Zoom studs out along
	--                   front * f + right * r + up * u (CameraMin/MaxZoomDistance pinned to Zoom, a camera CFrame set once)
	function H.overrideCamera(S)
		local spec = H.CONFIG.camera
		local rec = S.rec
		if not spec or not rec or D[rec.hrp] == nil then return end
		local hcf = H.rawGet(rec.hrp, "CFrame")
		local lk = hcf.LookVector
		local f = v3(lk.X, 0, lk.Z)
		if f.Magnitude < 1e-6 then f = v3(0, 0, -1) end
		f = f.Unit
		local r = f:Cross(v3(0, 1, 0)).Unit
		if spec.kind == "subject" then
			local focus = hcf.Position + v3(0, 1.5, 0)
			local dir = (f * spec.f + r * spec.r + v3(0, spec.u, 0)).Unit
			setCamera(focus + dir * spec.zoom, focus)
		else
			local body = hcf.Position + v3(0, rec.hover or 0, 0)
			local az, el = rad(spec.az), rad(spec.el)
			local horiz = f * cos(az) + r * sin(az)
			local dir = horiz * cos(el) + v3(0, sin(el), 0)
			local target = body + v3(0, spec.ty, 0)
			setCamera(target + dir * spec.d, target)
		end
		if spec.fov then
			local cd = D[H.camera]
			cd.props.FieldOfView = spec.fov
		end
	end

	-------------------------------------------------------------------------------------- scenario table
	local SC = {}
	H.SCENARIOS = SC
	H.SCENARIO_ORDER = {}
	local function def(name, desc, cfg, setup, step)
		SC[name] = { name = name, desc = desc, cfg = cfg, setup = setup, step = step }
		table.insert(H.SCENARIO_ORDER, name)
	end

	-- the usual single local wearer standing at the origin facing -Z
	local function oneWearer(S, rig)
		local lp = H.localPlayer
		local char, info = H.spawnCharacter(lp, rig or S.rig, v3(0, 0, 0), 0)
		local rec = H.newRec(lp, char, info, true)
		placeWearer(rec, v3(0, 3, 0), 0)
		return rec
	end

	def("day_idle", "Day (ClockTime 14), wearer idle, default follow camera 16 studs behind and 6 up",
		{ duration = 16, clock = 14 },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt) placeWearer(S.rec, v3(0, 3, 0), 0) followCam(S.rec, 16, 6, dt) end)

	def("night_idle", "Night (ClockTime 0.3), wearer idle, follow camera behind",
		{ duration = 12, clock = 0.3 },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt) placeWearer(S.rec, v3(0, 3, 0), 0) followCam(S.rec, 16, 6, dt) end)

	def("showcase_front", "Day, camera in front of the wearer ~34 studs out and 8 up (how Milo frames his screenshots)",
		{ duration = 12, clock = 14 },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt) placeWearer(S.rec, v3(0, 3, 0), 0) setCamera(v3(0, 11, -34), v3(0, 7, 0)) end)

	def("camera_orbit", "Day, the camera circles the wearer once (radius 30, 8 up) over 20 s",
		{ duration = 20, clock = 14 },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt)
			placeWearer(S.rec, v3(0, 3, 0), 0)
			local a = t / 20 * 2 * pi
			setCamera(v3(30 * sin(a), 11, 30 * cos(a)), v3(0, 5, 0))
		end)

	def("glide", "Day, idle 2 s, then walks forward on a gentle curve at WalkSpeed 16 (glide ramps 0->1), stops at 12 s",
		{ duration = 16, clock = 14 },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } S.pos = v3(0, 3, 0) S.yaw = 0 end,
		function(S, t, dt)
			local moving = t >= 2 and t < 12
			local md = nil
			if moving then
				S.yaw += rad(9) * dt -- slow left turn
				local look = v3(-sin(S.yaw), 0, -cos(S.yaw))
				S.pos += look * 16 * dt
				md = look
			end
			placeWearer(S.rec, S.pos, S.yaw, md)
			followCam(S.rec, 16, 6, dt)
		end)

	def("air", "Day, the wearer rises from the ground at 8 studs/s from t = 2 (ground ray of 60 studs loses the floor near t = 9)",
		{ duration = 14, clock = 14 },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt)
			local y = 3 + max(0, t - 2) * 8
			placeWearer(S.rec, v3(0, y, 0), 0)
			followCam(S.rec, 18, 6, dt)
		end)

	def("dusk", "ClockTime sweeps 17.0 -> 19.5 (sunset into night) while idle: tests day/night blending",
		{ duration = 16, clock = 17 },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt)
			D[H.SERVICES.Lighting].props.ClockTime = 17 + 2.5 * t / 16
			placeWearer(S.rec, v3(0, 3, 0), 0)
			followCam(S.rec, 16, 6, dt)
		end)

	def("low_quality", "Day, quality = \"low\" (phones / low graphics), touch device",
		{ duration = 12, clock = 14, quality = "low", touch = true },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt) placeWearer(S.rec, v3(0, 3, 0), 0) followCam(S.rec, 16, 6, dt) end)

	def("remote_wearer", "Another player (isLocal = false) wears it; the local player stands 30 studs away looking at them",
		{ duration = 12, clock = 14 },
		function(S)
			local lp = H.localPlayer
			local myChar, myInfo = H.spawnCharacter(lp, "R15", v3(0, 0, 30), 0)
			S.me = { hrp = myInfo.hrp, hum = myInfo.hum, info = myInfo, char = myChar }
			placeWearer(S.me, v3(0, 3, 30), 0)
			local other = H.makePlayer("Player2", 1002)
			local char, info = H.spawnCharacter(other, "R15", v3(0, 0, 0), math.pi)
			S.rec = H.newRec(other, char, info, false)
			placeWearer(S.rec, v3(0, 3, 0), math.pi)
			S.equipAt = { { rec = S.rec, t = 0.1 } }
		end,
		function(S, t, dt)
			placeWearer(S.me, v3(0, 3, 30), 0)
			placeWearer(S.rec, v3(0, 3, 0), math.pi)
			setCamera(v3(0, 9, 44), v3(0, 6, 0))
		end)

	def("far", "Camera pulls back: 20 -> 150 studs (setDetail false past 110) -> 400 (setVisible false past 320) -> back to 20",
		{ duration = 16, clock = 14 },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt)
			placeWearer(S.rec, v3(0, 3, 0), 0)
			local dist
			if t < 3 then dist = 20
			elseif t < 5 then dist = 20 + (t - 3) / 2 * 130
			elseif t < 9 then dist = 150
			elseif t < 10 then dist = 150 + (t - 9) * 250
			elseif t < 12 then dist = 400
			elseif t < 13 then dist = 400 - (t - 12) * 380
			else dist = 20 end
			setCamera(v3(0, 6 + dist * 0.15, dist), v3(0, 5, 0))
		end)

	def("toggle_visible", "Camera goes Scriptable 3-5 s (framework hides the aura), then rapid hide/show at 8.0/8.1/8.2/8.3 s",
		{ duration = 12, clock = 14 },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt)
			placeWearer(S.rec, v3(0, 3, 0), 0)
			local cam = D[H.camera]
			local scriptable = (t >= 3 and t < 5) or (t >= 8.0 and t < 8.1) or (t >= 8.2 and t < 8.3)
			cam.props.CameraType = E("CameraType", scriptable and "Scriptable" or "Custom")
			followCam(S.rec, 16, 6, dt)
		end)

	def("destroy_mid_assembly", "Unequipped 2 s after equipping (mid assembly); runs on to 8 s so late callbacks fire",
		{ duration = 8, clock = 14 },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } S.events = { { t = 2.1, fn = function() H.unequip(S.rec) end } } end,
		function(S, t, dt) placeWearer(S.rec, v3(0, 3, 0), 0) followCam(S.rec, 16, 6, dt) end)

	def("reequip", "Equip, unequip at 4 s, equip again at 5 s (module-level state must not break the second build)",
		{ duration = 14, clock = 14 },
		function(S)
			S.rec = oneWearer(S)
			S.equipAt = { { rec = S.rec, t = 0.1 }, { rec = S.rec, t = 5.0 } }
			S.events = { { t = 4.0, fn = function() H.unequip(S.rec) end } }
		end,
		function(S, t, dt) placeWearer(S.rec, v3(0, 3, 0), 0) followCam(S.rec, 16, 6, dt) end)

	def("respawn", "The wearer dies at 6 s: the framework destroys the aura, a new character spawns and it is built again",
		{ duration = 14, clock = 14 },
		function(S)
			S.rec = oneWearer(S)
			S.equipAt = { { rec = S.rec, t = 0.1 } }
			S.events = { { t = 6.0, fn = function()
				local old = S.rec
				H.unequip(old)
				H.fireIf(D[old.hum], "Died")
				H.fireIf(D[H.localPlayer], "CharacterRemoving", old.char)
				H.destroy(old.char)
				local i = table.find(H.RECS, old)
				if i then table.remove(H.RECS, i) end
				local char, info = H.spawnCharacter(H.localPlayer, "R15", v3(0, 0, 0), 0)
				S.rec = H.newRec(H.localPlayer, char, info, true)
				placeWearer(S.rec, v3(0, 3, 0), 0)
				S.lateEquip = { rec = S.rec, t = 6.3 }
			end } }
		end,
		function(S, t, dt)
			if S.lateEquip and t >= S.lateEquip.t then H.equip(S.lateEquip.rec) S.lateEquip = nil end
			placeWearer(S.rec, v3(0, 3, 0), 0)
			followCam(S.rec, 16, 6, dt)
		end)

	def("join_wearing", "The player just joined already wearing it (time() < 20): the equip-only screen grade must not run",
		{ duration = 10, clock = 14, timeBase = 3 },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt) placeWearer(S.rec, v3(0, 3, 0), 0) followCam(S.rec, 16, 6, dt) end)

	def("r6_character", "Day, an R6 character (Torso, Left Arm ...; RootJoint / Left Shoulder joints, HipHeight 0)",
		{ duration = 12, clock = 14, rig = "R6" },
		function(S) S.rec = oneWearer(S, "R6") S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt) placeWearer(S.rec, v3(0, 3, 0), 0) followCam(S.rec, 16, 6, dt) end)

	def("film_meshes_present", "ReplicatedStorage.AuraCinema.Assets.TheEnd holds fake film meshes (RingG, Dial, Astrolabe, Hand, Gear, Oblivion.Moon/SmoothSphere)",
		{ duration = 12, clock = 14, film = "present" },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt) placeWearer(S.rec, v3(0, 3, 0), 0) followCam(S.rec, 16, 6, dt) end)

	def("film_meshes_absent", "ReplicatedStorage.AuraCinema.Assets.TheEnd exists but is empty (the fallback path)",
		{ duration = 12, clock = 14, film = "empty" },
		function(S) S.rec = oneWearer(S) S.equipAt = { { rec = S.rec, t = 0.1 } } end,
		function(S, t, dt) placeWearer(S.rec, v3(0, 3, 0), 0) followCam(S.rec, 16, 6, dt) end)

	def("crowd", "Six wearers at once (the local player + 5 others in a ring of radius 25): per-client cost scaling",
		{ duration = 12, clock = 14 },
		function(S)
			S.recs = {}
			S.rec = oneWearer(S)
			S.recs[1] = S.rec
			S.equipAt = { { rec = S.rec, t = 0.1 } }
			for i = 1, 5 do
				local a = i / 5 * 2 * pi
				local pos = v3(25 * sin(a), 0, 25 * cos(a))
				local pl = H.makePlayer("Player" .. (i + 1), 1001 + i)
				local char, info = H.spawnCharacter(pl, "R15", pos, a)
				local rec = H.newRec(pl, char, info, false)
				placeWearer(rec, pos + v3(0, 3, 0), a)
				rec.homePos, rec.homeYaw = pos + v3(0, 3, 0), a
				S.recs[#S.recs + 1] = rec
				table.insert(S.equipAt, { rec = rec, t = 0.1 + i * 0.4 })
			end
		end,
		function(S, t, dt)
			placeWearer(S.rec, v3(0, 3, 0), 0)
			for i = 2, #S.recs do placeWearer(S.recs[i], S.recs[i].homePos, S.recs[i].homeYaw) end
			setCamera(v3(0, 30, 60), v3(0, 4, 0))
		end)
end
