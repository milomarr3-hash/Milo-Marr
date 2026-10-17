-- EXPECT clean
-- SCENARIOS: film_meshes_present,film_meshes_absent,dusk,camera_orbit,respawn,low_quality,remote_wearer,toggle_visible,glide
-- ARGS: --mono
-- Test module: a correct aura using the APIs pass 5 is expected to use (film meshes, Highlight, a viewer-anchored clock,
-- welded assemblies moved by BulkMoveTo, a night factor from Lighting.ClockTime, palm attachments, trails, bursts).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local rad, sin, cos, exp, clamp = math.rad, math.sin, math.cos, math.exp, math.clamp

local SILVER = Color3.fromRGB(222, 228, 240)
local INK = Color3.fromRGB(5, 5, 8)

local End = {}
End.pose = {
	hover = 2.4, bob = 0.28, bobSpeed = 1.4,
	idle = { Root = { 2, 0, 0 }, LeftShoulder = { 6, 0, -24 }, RightShoulder = { 6, 0, 24 } },
	glide = { Root = { -18, 0, 0 } },
	breathe = { Waist = { 1.5, 0, 0 } },
	suppress = { Root = 0.6, LeftShoulder = 0.7, RightShoulder = 0.7 },
}

-- the film's meshes if the place has them (ReplicatedStorage.AuraCinema.Assets.TheEnd), else plain parts
local function filmMesh(name)
	local cin = RS:FindFirstChild("AuraCinema")
	local kit = cin and cin:FindFirstChild("Assets") and cin.Assets:FindFirstChild("TheEnd")
	local m = kit and kit:FindFirstChild(name, true)
	if m and m:IsA("MeshPart") then return m:Clone() end
	return nil
end

local function solid(name, size, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Parent = parent
	return p
end

local function nightFactor()
	local ct = Lighting.ClockTime
	local function ss(a, b, x) local u = clamp((x - a) / (b - a), 0, 1) return u * u * (3 - 2 * u) end
	return math.max(ss(17.5, 19, ct), 1 - ss(5, 6.5, ct))
end

function End.build(ctx)
	local low = ctx.quality == "low"
	local model = Instance.new("Model")
	model.Name = "TheEnd_" .. ctx.char.Name

	-- the bezel: the film's ring if present (scaled from its native size), else a block stand-in
	local bezel = filmMesh("RingG")
	if bezel then
		local s = 28 / math.max(bezel.Size.X, bezel.Size.Y)
		bezel.Size = bezel.Size * s
		bezel.Anchored, bezel.CanCollide, bezel.CanQuery, bezel.CanTouch = true, false, false, false
		bezel.Color = SILVER
		bezel.Parent = model
	else
		bezel = solid("Bezel", Vector3.new(28, 28, 2.4), SILVER, Enum.Material.Metal, model)
	end
	bezel.Name = "Bezel"
	model.PrimaryPart = bezel
	-- gears welded to the bezel: they ride along when the bezel moves
	local gears = {}
	for i = 1, (low and 3 or 6) do
		local g = filmMesh("Gear") or solid("Gear", Vector3.new(6, 6, 0.9), Color3.fromRGB(60, 62, 68), Enum.Material.Metal, model)
		g.Name = "Gear" .. i
		g.Anchored, g.CanCollide, g.CanQuery, g.CanTouch = true, false, false, false
		g.Parent = model
		local a = i / 6 * math.pi * 2
		g.CFrame = bezel.CFrame * CFrame.new(13 * cos(a), 13 * sin(a), 1.8)
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = bezel, g
		w.Parent = g
		gears[i] = g
	end
	-- an inlaid dial face (opaque white lines, no transparency stacking)
	local face = Instance.new("SurfaceGui")
	face.Face = Enum.NormalId.Front
	face.LightInfluence = 0
	face.Brightness = 1.6
	face.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	face.CanvasSize = Vector2.new(1024, 1024)
	face.Parent = bezel
	local im = Instance.new("ImageLabel")
	im.BackgroundTransparency = 1
	im.Size = UDim2.fromScale(1, 1)
	im.Image = "rbxassetid://138970147678654"
	im.ImageColor3 = Color3.new(1, 1, 1)
	im.Parent = face

	-- the moon (solid) and the void (neon black) with a key light, and an accretion disc
	local moon = filmMesh("Moon") or solid("Moon", Vector3.new(9, 9, 9), Color3.fromRGB(230, 230, 235), Enum.Material.SmoothPlastic, model)
	moon.Name = "Moon"
	moon.Anchored, moon.CanCollide, moon.CanQuery, moon.CanTouch = true, false, false, false
	moon.Size = Vector3.new(9, 9, 9)
	moon.Parent = model
	local key = Instance.new("PointLight")
	key.Range = 22
	key.Brightness = 0
	key.Color = Color3.fromRGB(232, 238, 255)
	key.Parent = moon
	local void = solid("Void", Vector3.new(8, 8, 8), INK, Enum.Material.Neon, model)
	void.Shape = Enum.PartType.Ball
	local disc = solid("Disc", Vector3.new(0.2, 22, 22), INK, Enum.Material.SmoothPlastic, model)
	disc.Shape = Enum.PartType.Cylinder

	-- palm streams: attachments on the hands, beams to the orbs, a trail on the moon
	local rightHand = ctx.char:FindFirstChild("RightHand") or ctx.char:FindFirstChild("Right Arm")
	local grip = rightHand and (rightHand:FindFirstChild("RightGripAttachment") or rightHand)
	local palm = Instance.new("Attachment")
	palm.Name = "TheEndPalm"
	palm.Parent = model -- (kept in the aura's own model: an attachment under a Model is not drawn, so it is only a marker)
	local moonA = Instance.new("Attachment")
	moonA.Parent = moon
	local handA
	if grip and grip:IsA("Attachment") then
		handA = Instance.new("Attachment")
		handA.Name = "TheEndPalmStream"
		handA.CFrame = grip.CFrame
		handA.Parent = rightHand
	end
	local stream = Instance.new("Beam")
	stream.Attachment0, stream.Attachment1 = moonA, handA
	stream.Width0, stream.Width1 = 0.6, 0.15
	stream.FaceCamera = true
	stream.Color = ColorSequence.new(SILVER)
	stream.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.4) })
	stream.LightEmission = 0.25
	stream.Texture = "rbxassetid://111152711897982"
	stream.Parent = moon
	local tA0, tA1 = Instance.new("Attachment"), Instance.new("Attachment")
	tA0.Position, tA1.Position = Vector3.new(0, 1, 0), Vector3.new(0, -1, 0)
	tA0.Parent, tA1.Parent = moon, moon
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = tA0, tA1
	trail.Lifetime = 0.6
	trail.Color = ColorSequence.new(SILVER)
	trail.Transparency = NumberSequence.new(0.3, 1)
	trail.Enabled = not low
	trail.Parent = moon

	-- matter spiralling into the void (purposeful particles) and a burst when the clock locks
	local inflow = Instance.new("ParticleEmitter")
	inflow.Texture = "rbxassetid://109765380822041"
	inflow.Rate = low and 12 or 30
	inflow.Lifetime = NumberRange.new(1.2, 1.8)
	inflow.Speed = NumberRange.new(-6, -4)
	inflow.Shape = Enum.ParticleEmitterShape.Sphere
	inflow.ShapeInOut = Enum.ParticleEmitterShapeInOut.InAndOut
	inflow.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4, 0.1), NumberSequenceKeypoint.new(1, 0) })
	inflow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.05), NumberSequenceKeypoint.new(1, 0.2) })
	inflow.Color = ColorSequence.new(SILVER, Color3.new(1, 1, 1))
	inflow.LightEmission = 0.25
	inflow.Parent = void
	local burst = Instance.new("ParticleEmitter")
	burst.Rate = 0
	burst.Texture = "rbxassetid://16956515291"
	burst.Lifetime = NumberRange.new(0.8, 1.2)
	burst.Parent = bezel

	-- one Highlight per aura model neutralises the cyan sky tint on metal
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(205, 208, 215)
	hl.OutlineColor = Color3.fromRGB(10, 10, 14)
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Adornee = model
	hl.Parent = model

	model:SetAttribute("Aura", "TheEnd")
	CollectionService:AddTag(model, "AuraModel")

	local moving = { bezel, moon, void, disc }
	local cfs = table.create(#moving)
	local fx = {}
	local yaw, age, nf, nfT, locked = nil, 0, -1, -10, false
	function fx.update(dt, s)
		age += dt
		local body = s.cf.Position + Vector3.new(0, s.hover, 0)
		-- viewer-anchored clock: on the far side of the wearer from the camera, through a spring
		local cam = workspace.CurrentCamera
		local away = body - cam.CFrame.Position
		local target = math.atan2(-away.X, -away.Z)
		yaw = yaw or target
		local diff = (target - yaw + math.pi) % (2 * math.pi) - math.pi
		yaw += diff * (1 - exp(-dt / 0.7 * 4))
		local W = CFrame.new(body) * CFrame.Angles(0, yaw, 0)
		-- (W looks away from the camera: the clock goes 7 studs further along -Z, turned round so its face looks back at us)
		cfs[1] = W * CFrame.new(0, 8.5, -7) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(rad(-8), 0, 0) * CFrame.Angles(0, 0, -s.now % (2 * math.pi))
		local sway = rad(22) * sin(s.t * 2 * math.pi / 10)
		cfs[2] = W * CFrame.Angles(0, 0, sway) * CFrame.new(-11, 4.5, -1.5)
		cfs[3] = W * CFrame.Angles(0, 0, sway) * CFrame.new(11, 4.5, -1.5)
		cfs[4] = cfs[3] * CFrame.Angles(0, 0, rad(75))
		workspace:BulkMoveTo(moving, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		-- night factor written about once a second, only when it changes
		if s.t - nfT >= 1 then
			nfT = s.t
			local n = math.floor(nightFactor() * 20 + 0.5) / 20
			if n ~= nf then
				nf = n
				face.Brightness = 1.6 + n
				key.Brightness = 1.5 * n
				hl.FillTransparency = 0.55 + 0.25 * n
			end
		end
		if not locked and age > 4 then
			locked = true
			burst:Emit(24)
		end
		-- the owner's own view is never blocked: fade the clock locally when it crosses the camera -> head line
		if ctx.isLocal then
			local m = (cam.CFrame.Position - body).Magnitude < 6 and 0.5 or 0
			if bezel.LocalTransparencyModifier ~= m then bezel.LocalTransparencyModifier = m end
		end
	end
	function fx.setVisible(on) model.Parent = on and ctx.container or nil end
	function fx.setDetail(isNear)
		inflow.Enabled = isNear
		trail.Enabled = isNear and not low
	end
	function fx.destroy()
		model:Destroy()
		if handA then handA:Destroy() end
	end
	model.Parent = ctx.container
	return fx
end

return End
