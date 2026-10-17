-- world: builds the DataModel the aura runs in: services, a plaza ground part, the camera, Lighting (the place's
-- Bloom), ReplicatedStorage.AuraFX.TheEnd (the module's `script`), optional fake AuraCinema film meshes, players and
-- R15 / R6 characters with Roblox's joint names and attachments.
do
	local D = H.INST_DATA
	local v3, cf, c3 = H.v3, H.cf, H.c3
	local CFrame, Vector3 = H.CFrame, H.Vector3
	local E = function(en, it) return H.enumItem(en, it) end
	local rawSet = H.rawSet

	local function make(class, props, parent)
		local p, d = H.newInst(class)
		if props then
			for k, v in pairs(props) do
				if k == "Name" then d.name = v else rawSet(p, k, v) end
			end
		end
		if parent then H.setParent(p, d, parent) end
		return p, d
	end
	H.make = make

	function H.buildWorld(opts)
		H.WORLD_READY = false
		local game, gd = H.newInst("DataModel")
		gd.name = "Place1"
		H.game = game
		local svc = H.getService
		local ws = svc("Workspace")
		H.workspace = ws
		for _, n in ipairs({ "Players", "Lighting", "ReplicatedStorage", "ReplicatedFirst", "StarterGui", "StarterPack", "StarterPlayer",
			"SoundService", "RunService", "TweenService", "Debris", "CollectionService", "HttpService", "UserInputService",
			"ContentProvider", "GuiService", "TextService", "Teams", "Chat", "LocalizationService", "TestService" }) do
			svc(n)
		end
		local uis = H.SERVICES.UserInputService
		rawSet(uis, "TouchEnabled", opts.touch == true)
		rawSet(uis, "KeyboardEnabled", opts.touch ~= true)
		rawSet(uis, "MouseEnabled", opts.touch ~= true)
		rawSet(uis, "GamepadEnabled", false)
		rawSet(uis, "VREnabled", false)

		-- workspace: terrain, the plaza ground (the only thing a ray can hit), the camera, the aura container
		local terrain = make("Terrain", { Name = "Terrain", Anchored = true }, ws)
		rawSet(ws, "Terrain", terrain)
		H.plaza = make("Part", { Name = "Plaza", Size = v3(2048, 1, 2048), CFrame = cf(0, -0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), Anchored = true,
			Material = E("Material", "Sand"), Color = c3(0.86, 0.78, 0.6) }, ws)
		local cam = make("Camera", { Name = "Camera", FieldOfView = 70, CameraType = E("CameraType", "Custom"),
			CFrame = cf(0, 10, 20, 1, 0, 0, 0, 1, 0, 0, 0, 1) }, ws)
		rawSet(ws, "CurrentCamera", cam)
		H.camera = cam
		H.container = make("Folder", { Name = "AuraFX_Auras" }, ws)

		-- lighting: the place's bloom (Intensity 1, Size 24, Threshold ~2), a sky, atmosphere
		local L = H.SERVICES.Lighting
		rawSet(L, "ClockTime", opts.clockTime or 14)
		rawSet(L, "Brightness", 3)
		rawSet(L, "Ambient", c3(0.27, 0.27, 0.3))
		rawSet(L, "OutdoorAmbient", c3(0.5, 0.5, 0.55))
		make("BloomEffect", { Name = "Bloom", Intensity = 1, Size = 24, Threshold = 2 }, L)
		make("Sky", { Name = "Sky" }, L)
		make("Atmosphere", { Name = "Atmosphere", Density = 0.3 }, L)

		-- the aura module lives at ReplicatedStorage.AuraFX.TheEnd (script)
		local RS = H.SERVICES.ReplicatedStorage
		local auraFX = make("ModuleScript", { Name = "AuraFX" }, RS)
		H.frameworkModule = auraFX
		H.moduleScript = make("ModuleScript", { Name = opts.moduleName or "TheEnd" }, auraFX)
		if opts.film then H.buildFilmTree(RS, opts.film) end

		-- players
		local players = H.SERVICES.Players
		H.WORLD_READY = true
		return game
	end

	-- fake film meshes: ReplicatedStorage.AuraCinema.Assets.TheEnd (deliberately varied native sizes/orientations)
	function H.buildFilmTree(RS, mode)
		local cin = make("Folder", { Name = "AuraCinema" }, RS)
		local assets = make("Folder", { Name = "Assets" }, cin)
		local te = make("Folder", { Name = "TheEnd" }, assets)
		if mode ~= "present" then return end
		local function mesh(name, size, ori, meshSize, mat, color, id, tex, parent)
			local p, d = make("MeshPart", { Name = name, Size = size, Anchored = true, Material = E("Material", mat), Color = color,
				CFrame = cf(0, 600, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) * CFrame.fromOrientation(math.rad(ori[1]), math.rad(ori[2]), math.rad(ori[3])) }, parent)
			d.props.MeshId = "rbxassetid://" .. id
			d.props.TextureID = tex and ("rbxassetid://" .. tex) or ""
			d.props.MeshSize = meshSize
			d.props.RenderFidelity = E("RenderFidelity", "Precise")
			return p
		end
		local steel = c3(0.69, 0.71, 0.75)
		mesh("RingG", v3(28.6, 28.6, 2.2), { 0, 0, 0 }, v3(2.86, 2.86, 0.22), "Metal", steel, "70000000001", nil, te)
		mesh("Dial", v3(1.1, 24.4, 24.4), { 0, 90, 0 }, v3(0.11, 2.44, 2.44), "SmoothPlastic", c3(0.19, 0.2, 0.22), "70000000002", "70000000102", te)
		mesh("Astrolabe", v3(21, 0.6, 21), { 0, 0, 0 }, v3(4.2, 0.12, 4.2), "Metal", steel, "70000000003", nil, te)
		mesh("Hand", v3(0.8, 11.5, 0.3), { 0, 0, 180 }, v3(0.16, 2.3, 0.06), "Metal", c3(0.85, 0.86, 0.9), "70000000004", nil, te)
		mesh("Gear", v3(6, 6, 0.9), { 0, 0, 15 }, v3(1, 1, 0.15), "Metal", c3(0.24, 0.25, 0.27), "70000000005", nil, te)
		local ob = make("Folder", { Name = "Oblivion" }, te)
		mesh("Moon", v3(9.2, 9.2, 9.2), { 12, 40, 0 }, v3(2, 2, 2), "SmoothPlastic", c3(0.9, 0.9, 0.92), "70000000006", "70000000106", ob)
		mesh("SmoothSphere", v3(2, 2, 2), { 0, 0, 0 }, v3(1, 1, 1), "SmoothPlastic", c3(0.05, 0.05, 0.06), "70000000007", nil, ob)
	end

	-------------------------------------------------------------------------------------- characters
	-- R15 rest pose built around the HumanoidRootPart (HipHeight 2: the HRP centre is 3 studs above the feet)
	local R15_PARTS = {
		{ "HumanoidRootPart", v3(2, 2, 1), v3(0, 0, 0) },
		{ "LowerTorso", v3(2, 0.4, 1), v3(0, -0.6, 0) },
		{ "UpperTorso", v3(2, 1.6, 1), v3(0, 0.4, 0) },
		{ "Head", v3(1.2, 1.2, 1.2), v3(0, 1.8, 0) },
		{ "LeftUpperArm", v3(1, 1.169, 1), v3(-1.5, 0.585, 0) }, { "LeftLowerArm", v3(1, 1.052, 1), v3(-1.5, -0.425, 0) },
		{ "LeftHand", v3(1, 0.3, 1), v3(-1.5, -1.05, 0) },
		{ "RightUpperArm", v3(1, 1.169, 1), v3(1.5, 0.585, 0) }, { "RightLowerArm", v3(1, 1.052, 1), v3(1.5, -0.425, 0) },
		{ "RightHand", v3(1, 0.3, 1), v3(1.5, -1.05, 0) },
		{ "LeftUpperLeg", v3(1, 1.217, 1), v3(-0.5, -1.142, 0) }, { "LeftLowerLeg", v3(1, 1.193, 1), v3(-0.5, -2.203, 0) },
		{ "LeftFoot", v3(1, 0.3, 1), v3(-0.5, -2.85, 0) },
		{ "RightUpperLeg", v3(1, 1.217, 1), v3(0.5, -1.142, 0) }, { "RightLowerLeg", v3(1, 1.193, 1), v3(0.5, -2.203, 0) },
		{ "RightFoot", v3(1, 0.3, 1), v3(0.5, -2.85, 0) },
	}
	-- name, part0, part1, joint position (HRP space)
	local R15_JOINTS = {
		{ "Root", "HumanoidRootPart", "LowerTorso", v3(0, -0.6, 0) },
		{ "Waist", "LowerTorso", "UpperTorso", v3(0, -0.4, 0) },
		{ "Neck", "UpperTorso", "Head", v3(0, 1.2, 0) },
		{ "LeftShoulder", "UpperTorso", "LeftUpperArm", v3(-1.25, 0.95, 0) }, { "LeftElbow", "LeftUpperArm", "LeftLowerArm", v3(-1.5, 0.05, 0) },
		{ "LeftWrist", "LeftLowerArm", "LeftHand", v3(-1.5, -0.9, 0) },
		{ "RightShoulder", "UpperTorso", "RightUpperArm", v3(1.25, 0.95, 0) }, { "RightElbow", "RightUpperArm", "RightLowerArm", v3(1.5, 0.05, 0) },
		{ "RightWrist", "RightLowerArm", "RightHand", v3(1.5, -0.9, 0) },
		{ "LeftHip", "LowerTorso", "LeftUpperLeg", v3(-0.5, -0.75, 0) }, { "LeftKnee", "LeftUpperLeg", "LeftLowerLeg", v3(-0.5, -1.7, 0) },
		{ "LeftAnkle", "LeftLowerLeg", "LeftFoot", v3(-0.5, -2.7, 0) },
		{ "RightHip", "LowerTorso", "RightUpperLeg", v3(0.5, -0.75, 0) }, { "RightKnee", "RightUpperLeg", "RightLowerLeg", v3(0.5, -1.7, 0) },
		{ "RightAnkle", "RightLowerLeg", "RightFoot", v3(0.5, -2.7, 0) },
	}
	-- extra (non-rig) attachments: part, name, position (HRP space)
	local R15_ATTS = {
		{ "HumanoidRootPart", "RootAttachment", v3(0, 0, 0) },
		{ "LowerTorso", "WaistCenterAttachment", v3(0, -0.6, 0) }, { "LowerTorso", "WaistFrontAttachment", v3(0, -0.6, -0.5) },
		{ "LowerTorso", "WaistBackAttachment", v3(0, -0.6, 0.5) },
		{ "UpperTorso", "BodyFrontAttachment", v3(0, 0.4, -0.5) }, { "UpperTorso", "BodyBackAttachment", v3(0, 0.4, 0.5) },
		{ "UpperTorso", "LeftCollarAttachment", v3(-1, 1.2, 0) }, { "UpperTorso", "RightCollarAttachment", v3(1, 1.2, 0) },
		{ "UpperTorso", "NeckAttachment", v3(0, 1.2, 0) },
		{ "Head", "FaceCenterAttachment", v3(0, 1.8, 0) }, { "Head", "FaceFrontAttachment", v3(0, 1.8, -0.6) },
		{ "Head", "HairAttachment", v3(0, 2.4, 0) }, { "Head", "HatAttachment", v3(0, 2.4, 0) },
		{ "LeftUpperArm", "LeftShoulderAttachment", v3(-1.5, 1.17, 0) }, { "RightUpperArm", "RightShoulderAttachment", v3(1.5, 1.17, 0) },
		{ "LeftHand", "LeftGripAttachment", v3(-1.5, -1.15, 0) }, { "RightHand", "RightGripAttachment", v3(1.5, -1.15, 0) },
		{ "LeftFoot", "LeftFootAttachment", v3(-0.5, -3, 0) }, { "RightFoot", "RightFootAttachment", v3(0.5, -3, 0) },
	}
	local R6_PARTS = {
		{ "HumanoidRootPart", v3(2, 2, 1), v3(0, 0, 0) }, { "Torso", v3(2, 2, 1), v3(0, 0, 0) }, { "Head", v3(2, 1, 1), v3(0, 1.5, 0) },
		{ "Left Arm", v3(1, 2, 1), v3(-1.5, 0, 0) }, { "Right Arm", v3(1, 2, 1), v3(1.5, 0, 0) },
		{ "Left Leg", v3(1, 2, 1), v3(-0.5, -2, 0) }, { "Right Leg", v3(1, 2, 1), v3(0.5, -2, 0) },
	}
	local R6_JOINTS = {
		{ "RootJoint", "HumanoidRootPart", "Torso", v3(0, 0, 0) }, { "Neck", "Torso", "Head", v3(0, 1, 0) },
		{ "Left Shoulder", "Torso", "Left Arm", v3(-1, 0.5, 0) }, { "Right Shoulder", "Torso", "Right Arm", v3(1, 0.5, 0) },
		{ "Left Hip", "Torso", "Left Leg", v3(-0.5, -1, 0) }, { "Right Hip", "Torso", "Right Leg", v3(0.5, -1, 0) },
	}
	local R6_ATTS = {
		{ "HumanoidRootPart", "RootAttachment", v3(0, 0, 0) }, { "Torso", "BodyFrontAttachment", v3(0, 0, -0.5) },
		{ "Torso", "BodyBackAttachment", v3(0, 0, 0.5) }, { "Torso", "NeckAttachment", v3(0, 1, 0) },
		{ "Torso", "WaistCenterAttachment", v3(0, -1, 0) }, { "Torso", "WaistFrontAttachment", v3(0, -1, -0.5) },
		{ "Torso", "WaistBackAttachment", v3(0, -1, 0.5) }, { "Torso", "LeftCollarAttachment", v3(-1, 1, 0) },
		{ "Torso", "RightCollarAttachment", v3(1, 1, 0) },
		{ "Head", "FaceCenterAttachment", v3(0, 1.5, 0) }, { "Head", "FaceFrontAttachment", v3(0, 1.5, -0.5) },
		{ "Head", "HairAttachment", v3(0, 2, 0) }, { "Head", "HatAttachment", v3(0, 2, 0) },
		{ "Left Arm", "LeftShoulderAttachment", v3(-1.5, 1, 0) }, { "Right Arm", "RightShoulderAttachment", v3(1.5, 1, 0) },
		{ "Left Arm", "LeftGripAttachment", v3(-1.5, -1, 0) }, { "Right Arm", "RightGripAttachment", v3(1.5, -1, 0) },
		{ "Left Leg", "LeftFootAttachment", v3(-0.5, -3, 0) }, { "Right Leg", "RightFootAttachment", v3(0.5, -3, 0) },
	}
	local COLORS = {
		Head = c3(0.92, 0.78, 0.62), UpperTorso = c3(0.95, 0.6, 0.15), LowerTorso = c3(0.95, 0.6, 0.15), Torso = c3(0.95, 0.6, 0.15),
	}
	local function partColor(name)
		if COLORS[name] then return COLORS[name] end
		if name:find("Arm") or name:find("Hand") then return c3(0.92, 0.78, 0.62) end
		return c3(0.1, 0.1, 0.12)
	end

	-- builds a character Model standing on the ground at `pos` facing -Z (rotated by yaw)
	function H.buildCharacter(name, rig, pos, yaw)
		local r15 = rig ~= "R6"
		local char = make("Model", { Name = name })
		local base = CFrame.new(pos.X, pos.Y + 3, pos.Z) * CFrame.Angles(0, yaw or 0, 0)
		local parts = {}
		for _, e in ipairs(r15 and R15_PARTS or R6_PARTS) do
			local nm, size, off = e[1], e[2], e[3]
			local cls = (r15 and nm ~= "HumanoidRootPart") and "MeshPart" or "Part"
			local p = make(cls, { Name = nm, Size = size, CFrame = base * CFrame.new(off.X, off.Y, off.Z), Color = partColor(nm),
				Anchored = false, CanCollide = nm == "HumanoidRootPart" or nm:find("Torso") ~= nil, Transparency = nm == "HumanoidRootPart" and 1 or 0,
				Massless = false }, char)
			parts[nm] = p
		end
		local joints = {}
		for _, j in ipairs(r15 and R15_JOINTS or R6_JOINTS) do
			local jn, p0n, p1n, at = j[1], j[2], j[3], j[4]
			local p0, p1 = parts[p0n], parts[p1n]
			local jcf = base * CFrame.new(at.X, at.Y, at.Z)
			local c0 = H.rawGet(p0, "CFrame"):Inverse() * jcf
			local c1 = H.rawGet(p1, "CFrame"):Inverse() * jcf
			local m, md = make("Motor6D", { Name = jn, C0 = c0, C1 = c1 }, r15 and p1 or p0)
			md.props.Part0, md.props.Part1 = p0, p1
			md.props.Transform = H.CF_IDENT
			H.registerJoint(m, md)
			joints[jn] = m
			if r15 then
				local rig0 = jn:gsub("^Root$", "Root") .. "RigAttachment"
				make("Attachment", { Name = rig0, CFrame = c0 }, p0)
				make("Attachment", { Name = rig0, CFrame = c1 }, p1)
			end
		end
		for _, a in ipairs(r15 and R15_ATTS or R6_ATTS) do
			local p = parts[a[1]]
			local w = base * CFrame.new(a[3].X, a[3].Y, a[3].Z)
			make("Attachment", { Name = a[2], CFrame = H.rawGet(p, "CFrame"):Inverse() * w }, p)
		end
		local hum = make("Humanoid", { Name = "Humanoid", RigType = E("HumanoidRigType", r15 and "R15" or "R6"), HipHeight = r15 and 2 or 0,
			WalkSpeed = 16, Health = 100, MaxHealth = 100, DisplayName = name }, char)
		make("Animator", { Name = "Animator" }, hum)
		make("LocalScript", { Name = "Animate" }, char)
		make("Script", { Name = "Health" }, char)
		make("BodyColors", { Name = "Body Colors" }, char)
		make("Decal", { Name = "face", Texture = "rbxasset://textures/face.png" }, parts.Head)
		-- one accessory (hair), welded to the head the way Roblox does it
		local acc = make("Accessory", { Name = "HairAccessory" }, char)
		local handle = make("MeshPart", { Name = "Handle", Size = v3(1.4, 0.8, 1.4), CFrame = H.rawGet(parts.Head, "CFrame") * CFrame.new(0, 0.6, 0.1),
			Color = c3(0.15, 0.1, 0.08), CanCollide = false, Massless = true }, acc)
		local weld, wd = make("Weld", { Name = "AccessoryWeld", C0 = CFrame.new(0, -0.6, -0.1), C1 = H.CF_IDENT }, handle)
		wd.props.Part0, wd.props.Part1 = handle, parts.Head
		H.registerJoint(weld, wd)
		D[char].props.PrimaryPart = parts.HumanoidRootPart
		return char, { parts = parts, joints = joints, hum = hum, hrp = parts.HumanoidRootPart, r15 = r15 }
	end

	function H.makePlayer(name, userId)
		local players = H.SERVICES.Players
		local p, d = make("Player", { Name = name, DisplayName = name, UserId = userId }, players)
		make("PlayerGui", { Name = "PlayerGui" }, p)
		make("Backpack", { Name = "Backpack" }, p)
		make("PlayerScripts", { Name = "PlayerScripts" }, p)
		H.fireIf(D[players], "PlayerAdded", p)
		return p
	end
	function H.spawnCharacter(player, rig, pos, yaw)
		local name = D[player].name
		local char, info = H.buildCharacter(name, rig, pos, yaw)
		D[player].props.Character = char
		H.setParent(char, D[char], H.workspace)
		if player == H.localPlayer then D[H.camera].props.CameraSubject = info.hum end
		H.fireIf(D[player], "CharacterAdded", char)
		return char, info
	end
end
