-- classes_parts: BasePart / Part / MeshPart, Attachment, Model, joints (Weld, Motor6D, WeldConstraint) with assembly
-- propagation, Camera, Workspace (BulkMoveTo, Raycast, server time) and defaults the API dump leaves out.
do
	local format, err, typeof = string.format, H.err, H.typeof
	local D = H.INST_DATA
	local v3, cf, c3, udim2, v2 = H.v3, H.cf, H.c3, H.udim2, H.v2
	local CFrame, Vector3 = H.CFrame, H.Vector3
	local rad, deg, sqrt, abs, mmin, mmax, tan = math.rad, math.deg, math.sqrt, math.abs, math.min, math.max, math.tan
	local cfMul = H.cfMul
	local IDENT = H.CF_IDENT
	local E = function(en, it) return H.enumItem(en, it) end

	-------------------------------------------------------------------------------------- defaults (abstract classes)
	local function defaults(cls, t) local h = H.hook(cls) for k, v in pairs(t) do h.defaults[k] = v end end
	defaults("BasePart", {
		Anchored = false, CanCollide = true, CanQuery = true, CanTouch = true, CastShadow = true, Locked = false, Massless = false,
		Color = c3(163 / 255, 162 / 255, 165 / 255), Material = E("Material", "Plastic"), Reflectance = 0, Transparency = 0,
		CFrame = IDENT, PivotOffset = IDENT, Size = v3(4, 1, 2), CollisionGroup = "Default", RootPriority = 0, MaterialVariant = "",
		AssemblyLinearVelocity = Vector3.zero, AssemblyAngularVelocity = Vector3.zero, LocalTransparencyModifier = 0,
		TopSurface = E("SurfaceType", "Smooth"), BottomSurface = E("SurfaceType", "Smooth"), FrontSurface = E("SurfaceType", "Smooth"),
		BackSurface = E("SurfaceType", "Smooth"), LeftSurface = E("SurfaceType", "Smooth"), RightSurface = E("SurfaceType", "Smooth"),
		EnableFluidForces = true, AudioCanCollide = true,
	})
	defaults("CornerWedgePart", { Size = v3(2, 2, 2) })
	defaults("MeshPart", { Size = v3(1, 1, 1) })
	defaults("TrussPart", { Size = v3(2, 2, 2) })
	defaults("SpawnLocation", { Size = v3(12, 1, 12) })
	defaults("Instance", { Archivable = true })
	defaults("GuiObject", {
		Active = false, AnchorPoint = v2(0, 0), AutomaticSize = E("AutomaticSize", "None"), BackgroundColor3 = c3(163 / 255, 162 / 255, 165 / 255),
		BackgroundTransparency = 0, BorderColor3 = c3(27 / 255, 42 / 255, 53 / 255), BorderMode = E("BorderMode", "Outline"),
		BorderSizePixel = 1, ClipsDescendants = false, Interactable = true, LayoutOrder = 0, Position = udim2(0, 0, 0, 0), Rotation = 0,
		Selectable = false, SelectionOrder = 0, Size = udim2(0, 100, 0, 100), SizeConstraint = E("SizeConstraint", "RelativeXY"),
		Visible = true, ZIndex = 1,
	})
	defaults("GuiBase2d", { AutoLocalize = true, SelectionGroup = false })
	defaults("LayerCollector", { Enabled = true, ResetOnSpawn = true, ZIndexBehavior = E("ZIndexBehavior", "Sibling") })
	defaults("SurfaceGuiBase", { Active = true, Face = E("NormalId", "Front") })
	defaults("Light", { Brightness = 1, Color = c3(1, 1, 1), Enabled = true, Shadows = false })
	defaults("PointLight", { Range = 8 })
	defaults("SpotLight", { Range = 16, Angle = 90, Face = E("NormalId", "Front") })
	defaults("SurfaceLight", { Range = 16, Angle = 90, Face = E("NormalId", "Front") })
	defaults("PostEffect", { Enabled = true })
	defaults("FaceInstance", { Face = E("NormalId", "Front") })
	defaults("DataModelMesh", { Offset = Vector3.zero, Scale = v3(1, 1, 1), VertexColor = v3(1, 1, 1) })
	defaults("JointInstance", { Active = true, C0 = IDENT, C1 = IDENT, Enabled = true })
	defaults("TriangleMeshPart", { CollisionFidelity = E("CollisionFidelity", "Default"), FluidFidelity = E("FluidFidelity", "Automatic") })

	-------------------------------------------------------------------------------------- joints / assemblies
	-- part data gets d.joints = { joint proxies }; moving a part moves everything jointed to it
	local function jointParts(jd)
		return jd.props.Part0, jd.props.Part1
	end
	local function unregisterJoint(j, jd)
		for _, part in ipairs({ jd.regP0, jd.regP1 }) do
			local pd = part and D[part]
			if pd and pd.joints then
				local i = table.find(pd.joints, j)
				if i then table.remove(pd.joints, i) end
			end
		end
		jd.regP0, jd.regP1 = nil, nil
	end
	local function registerJoint(j, jd)
		unregisterJoint(j, jd)
		local p0, p1 = jointParts(jd)
		if not (p0 and p1) or jd.destroyed then return end
		if jd.props.Enabled == false then return end
		local d0, d1 = D[p0], D[p1]
		d0.joints = d0.joints or {}
		d1.joints = d1.joints or {}
		table.insert(d0.joints, j)
		table.insert(d1.joints, j)
		jd.regP0, jd.regP1 = p0, p1
		if jd.cls.name == "WeldConstraint" then
			local c0 = H.rawGet(p0, "CFrame")
			local c1 = H.rawGet(p1, "CFrame")
			jd.offset = c0:Inverse() * c1
		end
		-- lint: an anchored aura part welded to the character anchors the character; unmassless parts add weight
		local char = H.WEARER_CHARS
		if char then
			for _, pair in ipairs({ { p0, p1 }, { p1, p0 } }) do
				local a, b = pair[1], pair[2]
				for c in pairs(char) do
					if H.isDescendantOf(a, c) and not H.isDescendantOf(b, c) then
						if H.rawGet(b, "Anchored") then
							H.recordWarning("weld-anchors-character", format("%s joins anchored part %s to the character (%s): this anchors the character in Roblox",
								jd.cls.name, H.fullName(b), H.fullName(a)))
						elseif not H.rawGet(b, "Massless") then
							H.recordWarning("weld-mass", format("%s joins %s to the character without Massless = true (it adds mass to the character)",
								jd.cls.name, H.fullName(b)))
						end
					end
				end
			end
		end
	end
	H.registerJoint = registerJoint
	local function jointOther(j, jd, from)
		local p0, p1 = jd.regP0, jd.regP1
		local fromCF = D[from].props.CFrame or IDENT
		if jd.cls.name == "WeldConstraint" then
			local off = jd.offset or IDENT
			if from == p0 then return p1, cfMul(fromCF, off) end
			return p0, cfMul(fromCF, off:Inverse())
		end
		local c0 = jd.props.C0 or IDENT
		local c1 = jd.props.C1 or IDENT
		local tr = jd.props.Transform or IDENT
		if from == p0 then
			return p1, cfMul(cfMul(cfMul(fromCF, c0), tr), c1:Inverse())
		end
		return p0, cfMul(cfMul(cfMul(fromCF, c1), tr:Inverse()), c0:Inverse())
	end
	-- move `p` and propagate through its joints (breadth first, each part once)
	local function propagate(p)
		local queue, seen = { p }, { [p] = true }
		local i = 1
		while queue[i] do
			local cur = queue[i]
			i += 1
			local cd = D[cur]
			if cd.joints then
				for _, j in ipairs(cd.joints) do
					local jd = D[j]
					local other, ocf = jointOther(j, jd, cur)
					if other and not seen[other] then
						seen[other] = true
						D[other].props.CFrame = ocf
						queue[#queue + 1] = other
					end
				end
			end
		end
	end
	H.propagate = propagate
	local function setPartCF(p, d, v)
		d.props.CFrame = v
		if d.joints then propagate(p) end
	end
	H.setPartCF = setPartCF

	for _, jc in ipairs({ "JointInstance", "WeldConstraint" }) do
		local h = H.hook(jc)
		h.set.Part0 = function(j, jd, v) jd.props.Part0 = v registerJoint(j, jd) end
		h.set.Part1 = function(j, jd, v) jd.props.Part1 = v registerJoint(j, jd) end
		h.set.Enabled = function(j, jd, v) jd.props.Enabled = v registerJoint(j, jd) end
	end
	H.hook("JointInstance").set.C0 = function(j, jd, v) jd.props.C0 = v if jd.regP0 then propagate(jd.regP0) end end
	H.hook("JointInstance").set.C1 = function(j, jd, v) jd.props.C1 = v if jd.regP0 then propagate(jd.regP0) end end
	H.hook("Motor6D").set.Transform = function(j, jd, v) jd.props.Transform = v end
	H.hook("Motor6D").defaults.Transform = IDENT
	H.hook("WeldConstraint").defaults.Enabled = true
	H.hook("WeldConstraint").get.Active = function(j, jd) return jd.regP0 ~= nil end

	-------------------------------------------------------------------------------------- BasePart
	local BP = H.hook("BasePart")
	BP.set.CFrame = function(p, d, v) setPartCF(p, d, v) end
	BP.get.Position = function(p, d) local c = d.props.CFrame or IDENT return v3(c.X, c.Y, c.Z) end
	BP.set.Position = function(p, d, v)
		local c = d.props.CFrame or IDENT
		setPartCF(p, d, cf(v.X, v.Y, v.Z, c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9]))
	end
	local function orient(c) local x, y, z = c:ToOrientation() return v3(deg(x), deg(y), deg(z)) end
	BP.get.Orientation = function(p, d) return orient(d.props.CFrame or IDENT) end
	BP.set.Orientation = function(p, d, v)
		local c = d.props.CFrame or IDENT
		local r = CFrame.fromOrientation(rad(v.X), rad(v.Y), rad(v.Z))
		setPartCF(p, d, cf(c.X, c.Y, c.Z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9]))
	end
	BP.get.Rotation = function(p, d) local x, y, z = (d.props.CFrame or IDENT):ToEulerAnglesXYZ() return v3(deg(x), deg(y), deg(z)) end
	BP.set.Rotation = function(p, d, v)
		local c = d.props.CFrame or IDENT
		local r = CFrame.Angles(rad(v.X), rad(v.Y), rad(v.Z))
		setPartCF(p, d, cf(c.X, c.Y, c.Z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9]))
	end
	local function fixSize(d, v)
		local x, y, z = v.X, v.Y, v.Z
		local cx, cy, cz = mmin(mmax(x, 0.001), 2048), mmin(mmax(y, 0.001), 2048), mmin(mmax(z, 0.001), 2048)
		if cx ~= x or cy ~= y or cz ~= z then
			H.recordWarning("size-clamp", format("%s Size %s clamped to Roblox's 0.001..2048 range", d.cls.name, tostring(v)))
		end
		local shape = d.props.Shape
		if shape and shape.Name == "Ball" then
			local m = mmin(cx, cy, cz)
			cx, cy, cz = m, m, m
		elseif shape and shape.Name == "Cylinder" then
			local m = mmin(cy, cz)
			cy, cz = m, m
		end
		return v3(cx, cy, cz)
	end
	BP.set.Size = function(p, d, v) d.props.Size = fixSize(d, v) end
	H.hook("Part").set.Shape = function(p, d, v)
		d.props.Shape = v
		if d.props.Size then d.props.Size = fixSize(d, d.props.Size) end
	end
	H.hook("Part").defaults.Shape = E("PartType", "Block")
	BP.get.Mass = function(p, d) local s = d.props.Size or v3(4, 1, 2) return s.X * s.Y * s.Z * 0.7 end
	BP.get.AssemblyMass = BP.get.Mass
	BP.get.AssemblyRootPart = function(p) return p end
	BP.get.ExtentsSize = function(p, d) return d.props.Size or v3(4, 1, 2) end
	BP.get.ExtentsCFrame = function(p, d) return d.props.CFrame or IDENT end
	BP.get.CenterOfMass = function(p, d) local c = d.props.CFrame or IDENT return v3(c.X, c.Y, c.Z) end
	BP.get.AssemblyCenterOfMass = BP.get.CenterOfMass
	BP.methods.GetPivot = function(p) local d = D[p] return cfMul(d.props.CFrame or IDENT, d.props.PivotOffset or IDENT) end
	BP.methods.PivotTo = function(p, target)
		if not H.isCF(target) then H.badArg(1, "PivotTo", "CFrame", target) end
		local d = D[p]
		setPartCF(p, d, cfMul(target, (d.props.PivotOffset or IDENT):Inverse()))
	end
	BP.methods.GetMass = function(p) return BP.get.Mass(p, D[p]) end
	BP.methods.GetConnectedParts = function(p)
		local out, seen, q = {}, { [p] = true }, { p }
		local i = 1
		while q[i] do
			local cd = D[q[i]]
			i += 1
			for _, j in ipairs(cd.joints or {}) do
				local jd = D[j]
				for _, o in ipairs({ jd.regP0, jd.regP1 }) do
					if o and not seen[o] then seen[o] = true q[#q + 1] = o out[#out + 1] = o end
				end
			end
		end
		return out
	end
	BP.methods.GetJoints = function(p) return table.clone(D[p].joints or {}) end
	BP.methods.GetTouchingParts = function() return {} end
	BP.methods.GetVelocityAtPosition = function() return Vector3.zero end
	BP.methods.CanCollideWith = function() return false end
	BP.methods.IsGrounded = function(p) return D[p].props.Anchored == true end
	BP.methods.ApplyImpulse = function() end
	BP.methods.ApplyAngularImpulse = function() end
	BP.methods.ApplyImpulseAtPosition = function() end
	BP.methods.GetRootPart = function(p) return p end
	BP.methods.SetNetworkOwner = function() err("Network Ownership API can only be called from the Server.") end
	BP.methods.GetNetworkOwner = function() err("Network Ownership API can only be called from the Server.") end
	local function csg() err("CSG (UnionAsync/SubtractAsync/IntersectAsync) cannot run on a client at runtime: build unions in Studio (Edit mode) and clone them") end
	BP.methods.UnionAsync, BP.methods.SubtractAsync, BP.methods.IntersectAsync = csg, csg, csg
	BP.methods.Resize = function() return false end
	BP.methods.BreakJoints = function(p)
		for _, j in ipairs(table.clone(D[p].joints or {})) do H.destroy(j) end
	end
	BP.methods.GetClosestPointOnSurface = function(p, pos) return pos end

	-------------------------------------------------------------------------------------- Attachment
	local AT = H.hook("Attachment")
	local function parentCF(d)
		local par = d.parent
		if par then
			local pd = D[par]
			if pd.cls.isa.BasePart then return pd.props.CFrame or IDENT end
			if pd.cls.isa.Attachment then return H.attachmentWorldCF(par) end
		end
		return IDENT
	end
	function H.attachmentWorldCF(a)
		local d = D[a]
		return cfMul(parentCF(d), d.props.CFrame or IDENT)
	end
	AT.defaults.CFrame = IDENT
	AT.defaults.Visible = false
	AT.get.Position = function(a, d) local c = d.props.CFrame or IDENT return v3(c.X, c.Y, c.Z) end
	AT.set.Position = function(a, d, v)
		local c = d.props.CFrame or IDENT
		d.props.CFrame = cf(v.X, v.Y, v.Z, c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9])
	end
	AT.get.Orientation = function(a, d) return orient(d.props.CFrame or IDENT) end
	AT.set.Orientation = function(a, d, v)
		local c = d.props.CFrame or IDENT
		local r = CFrame.fromOrientation(rad(v.X), rad(v.Y), rad(v.Z))
		d.props.CFrame = cf(c.X, c.Y, c.Z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
	end
	AT.get.Axis = function(a, d) return (d.props.CFrame or IDENT).XVector end
	AT.get.SecondaryAxis = function(a, d) return (d.props.CFrame or IDENT).YVector end
	local function fromAxes(pos, ax, sec)
		ax = ax.Unit
		local z = ax:Cross(sec)
		if z.Magnitude < 1e-6 then
			sec = abs(ax.Y) < 0.9 and Vector3.yAxis or Vector3.xAxis
			z = ax:Cross(sec)
		end
		z = z.Unit
		local y = z:Cross(ax).Unit
		return CFrame.fromMatrix(pos, ax, y, z)
	end
	AT.set.Axis = function(a, d, v) local c = d.props.CFrame or IDENT d.props.CFrame = fromAxes(c.Position, v, c.YVector) end
	AT.set.SecondaryAxis = function(a, d, v) local c = d.props.CFrame or IDENT d.props.CFrame = fromAxes(c.Position, c.XVector, v) end
	AT.get.WorldCFrame = function(a, d) return cfMul(parentCF(d), d.props.CFrame or IDENT) end
	AT.set.WorldCFrame = function(a, d, v) d.props.CFrame = cfMul(parentCF(d):Inverse(), v) end
	AT.get.WorldPosition = function(a, d) return AT.get.WorldCFrame(a, d).Position end
	AT.set.WorldPosition = function(a, d, v)
		local local_ = parentCF(d):PointToObjectSpace(v)
		AT.set.Position(a, d, local_)
	end
	AT.get.WorldOrientation = function(a, d) return orient(AT.get.WorldCFrame(a, d)) end
	AT.set.WorldOrientation = function(a, d, v)
		local w = AT.get.WorldCFrame(a, d)
		local r = CFrame.fromOrientation(rad(v.X), rad(v.Y), rad(v.Z))
		AT.set.WorldCFrame(a, d, cf(w.X, w.Y, w.Z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9]))
	end
	AT.get.WorldAxis = function(a, d) return AT.get.WorldCFrame(a, d).XVector end
	AT.get.WorldSecondaryAxis = function(a, d) return AT.get.WorldCFrame(a, d).YVector end
	AT.set.WorldAxis = function(a, d, v) local pc = parentCF(d) AT.set.Axis(a, d, pc:VectorToObjectSpace(v)) end
	AT.set.WorldSecondaryAxis = function(a, d, v) local pc = parentCF(d) AT.set.SecondaryAxis(a, d, pc:VectorToObjectSpace(v)) end
	AT.methods.GetAxis = function(a) return AT.get.Axis(a, D[a]) end
	AT.methods.GetSecondaryAxis = function(a) return AT.get.SecondaryAxis(a, D[a]) end
	AT.methods.SetAxis = function(a, v) AT.set.Axis(a, D[a], v) end
	AT.methods.SetSecondaryAxis = function(a, v) AT.set.SecondaryAxis(a, D[a], v) end
	AT.methods.GetConstraints = function() return {} end

	-------------------------------------------------------------------------------------- Model / PVInstance
	local function descendantParts(m)
		local out = {}
		H.forDescendants(m, function(c) if D[c].cls.isa.BasePart then out[#out + 1] = c end end)
		return out
	end
	H.descendantParts = descendantParts
	local function boundingBox(m)
		local parts = descendantParts(m)
		if #parts == 0 then return IDENT, Vector3.zero end
		local mn, mx = v3(math.huge, math.huge, math.huge), v3(-math.huge, -math.huge, -math.huge)
		for _, p in ipairs(parts) do
			local d = D[p]
			local c, s = d.props.CFrame or IDENT, d.props.Size or v3(4, 1, 2)
			for _, sx in ipairs({ -0.5, 0.5 }) do for _, sy in ipairs({ -0.5, 0.5 }) do for _, sz in ipairs({ -0.5, 0.5 }) do
				local w = c * v3(s.X * sx, s.Y * sy, s.Z * sz)
				mn, mx = mn:Min(w), mx:Max(w)
			end end end
		end
		local center = (mn + mx) / 2
		return CFrame.new(center), mx - mn
	end
	local MD = H.hook("Model")
	local function modelPivot(m, d)
		local pp = d.props.PrimaryPart
		if pp and D[pp] and H.isDescendantOf(pp, m) then return BP.methods.GetPivot(pp) end
		if d.props.WorldPivot then return d.props.WorldPivot end
		return (boundingBox(m))
	end
	MD.methods.GetPivot = function(m) return modelPivot(m, D[m]) end
	MD.methods.PivotTo = function(m, target)
		if not H.isCF(target) then H.badArg(1, "PivotTo", "CFrame", target) end
		local d = D[m]
		local cur = modelPivot(m, d)
		local delta = cfMul(target, cur:Inverse())
		local seen = {}
		for _, p in ipairs(descendantParts(m)) do
			if not seen[p] then
				local pd = D[p]
				pd.props.CFrame = cfMul(delta, pd.props.CFrame or IDENT)
				seen[p] = true
			end
		end
		if d.props.WorldPivot then d.props.WorldPivot = target end
	end
	MD.methods.SetPrimaryPartCFrame = function(m, target)
		local d = D[m]
		if not d.props.PrimaryPart then err("Model:SetPrimaryPartCFrame() failed because no PrimaryPart has been set, or the PrimaryPart no longer exists. Please set Model.PrimaryPart before using this.") end
		MD.methods.PivotTo(m, target)
	end
	MD.methods.GetPrimaryPartCFrame = function(m)
		local pp = D[m].props.PrimaryPart
		if not pp then err("Model:GetPrimaryPartCFrame() failed because no PrimaryPart has been set") end
		return D[pp].props.CFrame or IDENT
	end
	MD.methods.GetBoundingBox = function(m) return boundingBox(m) end
	MD.methods.GetExtentsSize = function(m) local _, s = boundingBox(m) return s end
	MD.methods.MoveTo = function(m, pos) MD.methods.PivotTo(m, CFrame.new(pos) * modelPivot(m, D[m]).Rotation) end
	MD.methods.TranslateBy = function(m, delta) MD.methods.PivotTo(m, modelPivot(m, D[m]) + delta) end
	MD.methods.GetScale = function(m) return D[m].scale or 1 end
	MD.methods.ScaleTo = function(m, s)
		local d = D[m]
		local cur = d.scale or 1
		local k = s / cur
		local piv = modelPivot(m, d)
		for _, p in ipairs(descendantParts(m)) do
			local pd = D[p]
			local rel = piv:ToObjectSpace(pd.props.CFrame or IDENT)
			pd.props.CFrame = piv * (rel - rel.Position + rel.Position * k)
			pd.props.Size = (pd.props.Size or v3(4, 1, 2)) * k
		end
		d.scale = s
	end
	MD.get.WorldPivot = function(m, d) return modelPivot(m, d) end
	MD.set.WorldPivot = function(m, d, v) d.props.WorldPivot = v end
	H.hook("PVInstance").methods.GetPivot = function(p) return IDENT end
	H.hook("PVInstance").methods.PivotTo = function() end

	-------------------------------------------------------------------------------------- Camera
	local CAM = H.hook("Camera")
	H.VIEWPORT = v2(1920, 913) -- (the Studio window in Milo's captures)
	CAM.get.ViewportSize = function() return H.VIEWPORT end
	CAM.get.NearPlaneZ = function() return -0.1 end
	CAM.defaults.FieldOfView = 70
	CAM.set.FieldOfView = function(c, d, v) d.props.FieldOfView = mmin(mmax(v, 1), 120) end
	local function project(c, d, w)
		local cam = d.props.CFrame or IDENT
		local rel = cam:PointToObjectSpace(w)
		local depth = -rel.Z
		local fov = rad(d.props.FieldOfView or 70)
		local th = tan(fov / 2)
		local vw, vh = H.VIEWPORT.X, H.VIEWPORT.Y
		local aspect = vw / vh
		local nx = rel.X / (depth * th * aspect)
		local ny = rel.Y / (depth * th)
		local x, y = (nx + 1) / 2 * vw, (1 - ny) / 2 * vh
		local on = depth > 0 and x >= 0 and x <= vw and y >= 0 and y <= vh
		return v3(x, y, depth), on
	end
	H.projectPoint = project
	CAM.methods.WorldToViewportPoint = function(c, w)
		if not H.isV3(w) then H.badArg(1, "WorldToViewportPoint", "Vector3", w) end
		return project(c, D[c], w)
	end
	CAM.methods.WorldToScreenPoint = function(c, w)
		local p, on = project(c, D[c], w)
		return v3(p.X, p.Y - 58, p.Z), on
	end
	local function pixelRay(c, x, y, depth)
		local d = D[c]
		local cam = d.props.CFrame or IDENT
		local fov = rad(d.props.FieldOfView or 70)
		local th = tan(fov / 2)
		local vw, vh = H.VIEWPORT.X, H.VIEWPORT.Y
		local nx, ny = (x / vw) * 2 - 1, 1 - (y / vh) * 2
		local dir = cam:VectorToWorldSpace(v3(nx * th * (vw / vh), ny * th, -1)).Unit
		return H.Ray.new(cam.Position + dir * (depth or 0), dir)
	end
	CAM.methods.ViewportPointToRay = function(c, x, y, depth) return pixelRay(c, x, y, depth) end
	CAM.methods.ScreenPointToRay = function(c, x, y, depth) return pixelRay(c, x, y + 58, depth) end
	CAM.methods.GetPartsObscuringTarget = function() return {} end
	CAM.methods.GetRenderCFrame = function(c) return D[c].props.CFrame or IDENT end
	CAM.methods.GetRoll = function() return 0 end
	CAM.methods.SetRoll = function() end
	CAM.methods.ZoomToExtents = function() end
	CAM.methods.Interpolate = function() end
	CAM.methods.GetLargestCutoffDistance = function() return 0 end

	-------------------------------------------------------------------------------------- Workspace
	local WS = H.hook("Workspace")
	WS.defaults.Gravity = 196.2
	WS.get.DistributedGameTime = function() return H.vtime() end
	WS.methods.GetServerTimeNow = function() return H.epochNow() end
	WS.methods.GetRealPhysicsFPS = function() return 60 end
	WS.methods.GetNumAwakeParts = function() return 0 end
	WS.methods.GetPhysicsThrottling = function() return 100 end
	WS.methods.BulkMoveTo = function(ws, parts, cfs, mode)
		if type(parts) ~= "table" or H.INST_DATA[parts] then err("Unable to cast value to Objects") end
		if type(cfs) ~= "table" then err("Unable to cast Array to CoordinateFrame list") end
		local n = #parts
		if #cfs ~= n then err(format("BulkMoveTo: partList (%d) and cframeList (%d) must have the same number of elements", n, #cfs)) end
		if mode ~= nil and not H.coerceEnum("BulkMoveMode", mode) then err("Unable to cast value to std::string (BulkMoveMode)") end
		for i = 1, n do
			local p, c = parts[i], cfs[i]
			local pd = D[p]
			if not pd or not pd.cls.isa.BasePart then err(format("BulkMoveTo: partList[%d] is not a BasePart (got %s)", i, typeof(p))) end
			if not H.isCF(c) then err(format("BulkMoveTo: cframeList[%d] is not a CFrame (got %s)", i, typeof(c))) end
		end
		for i = 1, n do
			local p = parts[i]
			local pd = D[p]
			pd.props.CFrame = cfs[i]
			if pd.joints then propagate(p) end
			if pd.psig and pd.psig.CFrame then H.fire(pd.psig.CFrame) end
		end
		local sf = H.STATS_FRAME
		sf.bulkMoved = (sf.bulkMoved or 0) + n
		sf.bulkCalls = (sf.bulkCalls or 0) + 1
	end

	-- ray tests against parts (Block / Ball / Cylinder as an X-axis cylinder approximated by its box) -----------------
	local function rayBox(o, dir, c, s, maxT)
		local lo = c:PointToObjectSpace(o)
		local ld = c:VectorToObjectSpace(dir)
		local tmin, tmax = 0, maxT
		local hx, hy, hz = s.X / 2, s.Y / 2, s.Z / 2
		local axisHit = 0
		for i, pair in ipairs({ { lo.X, ld.X, hx }, { lo.Y, ld.Y, hy }, { lo.Z, ld.Z, hz } }) do
			local oo, dd, h = pair[1], pair[2], pair[3]
			if abs(dd) < 1e-12 then
				if oo < -h or oo > h then return nil end
			else
				local t1, t2 = (-h - oo) / dd, (h - oo) / dd
				if t1 > t2 then t1, t2 = t2, t1 end
				if t1 > tmin then tmin = t1 axisHit = i * (dd > 0 and -1 or 1) end
				if t2 < tmax then tmax = t2 end
				if tmin > tmax then return nil end
			end
		end
		local n = ({ [1] = v3(1, 0, 0), [-1] = v3(-1, 0, 0), [2] = v3(0, 1, 0), [-2] = v3(0, -1, 0), [3] = v3(0, 0, 1), [-3] = v3(0, 0, -1) })[axisHit] or v3(0, 1, 0)
		return tmin, c:VectorToWorldSpace(n)
	end
	local function raySphere(o, dir, center, r, maxT)
		local oc = o - center
		local b = oc:Dot(dir)
		local cc = oc:Dot(oc) - r * r
		local disc = b * b - cc
		if disc < 0 then return nil end
		local t = -b - sqrt(disc)
		if t < 0 then t = -b + sqrt(disc) end
		if t < 0 or t > maxT then return nil end
		return t, (o + dir * t - center).Unit
	end
	function H.rayPart(o, dir, maxT, p)
		local d = D[p]
		local c, s = d.props.CFrame or IDENT, d.props.Size or v3(4, 1, 2)
		local shape = d.props.Shape
		if shape and shape.Name == "Ball" then return raySphere(o, dir, c.Position, s.X / 2, maxT) end
		return rayBox(o, dir, c, s, maxT)
	end
	WS.methods.Raycast = function(ws, origin, direction, params)
		if not H.isV3(origin) then H.badArg(1, "Raycast", "Vector3", origin) end
		if not H.isV3(direction) then H.badArg(2, "Raycast", "Vector3", direction) end
		if params ~= nil and getmetatable(params) ~= H.RaycastParamsMT then H.badArg(3, "Raycast", "RaycastParams", params) end
		local len = direction.Magnitude
		if len == 0 then return nil end
		local dir = direction / len
		local filter = params and params.FilterDescendantsInstances or {}
		local include = params and params.FilterType.Name == "Include"
		local respectCollide = params and params.RespectCanCollide
		local best, bestT, bestN = nil, math.huge, nil
		H.forDescendants(ws, function(p)
			local d = D[p]
			if not d.cls.isa.BasePart or d.cls.name == "Terrain" then return end
			if d.props.CanQuery == false then return end
			if respectCollide and d.props.CanCollide == false then return end
			local inFilter = false
			for _, f in ipairs(filter) do if f == p or H.isDescendantOf(p, f) then inFilter = true break end end
			if include ~= inFilter then return end
			local t, n = H.rayPart(origin, dir, len, p)
			if t and t < bestT then best, bestT, bestN = p, t, n end
		end)
		if not best then return nil end
		H.STATS_FRAME.raycastHits = (H.STATS_FRAME.raycastHits or 0) + 1
		return H.raycastResult(best, origin + dir * bestT, bestN, H.rawGet(best, "Material"), bestT)
	end
	local function legacyRay(ws, ray, ignore)
		local params = H.RaycastParams.new()
		if ignore then params.FilterDescendantsInstances = type(ignore) == "table" and not D[ignore] and ignore or { ignore } end
		local r = WS.methods.Raycast(ws, ray.Origin, ray.Direction, params)
		if r then return r.Instance, r.Position, r.Normal, r.Material end
		return nil, ray.Origin + ray.Direction, Vector3.zero, E("Material", "Air")
	end
	WS.methods.FindPartOnRay = legacyRay
	WS.methods.FindPartOnRayWithIgnoreList = legacyRay
	WS.methods.FindPartOnRayWithWhitelist = function(ws, ray) return nil, ray.Origin + ray.Direction, Vector3.zero, E("Material", "Air") end
	WS.methods.Spherecast = function() return nil end
	WS.methods.Blockcast = function() return nil end
	WS.methods.Shapecast = function() return nil end
	WS.methods.GetPartBoundsInBox = function() return {} end
	WS.methods.GetPartBoundsInRadius = function() return {} end
	WS.methods.GetPartsInPart = function() return {} end
	WS.methods.ArePartsTouchingOthers = function() return false end
	WS.methods.FindPartsInRegion3 = function() return {} end
end
