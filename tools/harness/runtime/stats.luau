-- stats: per-frame write counters, instance census, particle estimates, camera-occlusion sampling, emitter/trail host
-- history, snapshot frames (the SHARED SNAPSHOT CONTRACT, see tools/harness/SNAPSHOT.md) and the end-of-run summary.
do
	local format = string.format
	local D = H.INST_DATA
	local v3 = H.v3
	local IDENT = H.CF_IDENT

	H.FW = { update = {}, callback = {}, tween = {} }
	H.FWR = {}
	H.BUILD_WRITES = {}
	H.LOAD_WRITES = {}
	H.STATS_FRAME = {}
	local AGG = { update = {}, callback = {}, tween = {}, redundant = {} }
	H.AGG = AGG
	local SER = {} -- per-frame series: name -> { sum, max, n, sSum, sMax, sN }
	H.SER = SER
	local nFrames, nSteady = 0, 0

	local function category(m)
		local isa = m.owner.isa
		if isa.GuiBase2d or isa.UIComponent or isa.UIBase then return "gui" end
		if isa.BasePart then return "part" end
		if isa.ParticleEmitter or isa.Beam or isa.Trail or isa.Light or isa.Highlight or isa.PostEffect or isa.Attachment or isa.GuiBase3d then
			return "effect"
		end
		return "other"
	end
	local function series(name, v, steady)
		local s = SER[name]
		if not s then s = { sum = 0, max = 0, n = 0, sSum = 0, sMax = 0, sN = 0 } SER[name] = s end
		s.sum += v
		s.n += 1
		if v > s.max then s.max = v end
		if steady then
			s.sSum += v
			s.sN += 1
			if v > s.sMax then s.sMax = v end
		end
	end

	function H.isSteady()
		local any = false
		for _, rec in ipairs(H.RECS) do
			if rec.fx and rec.builtAt then
				any = true
				if H.NOW - rec.builtAt < (H.CONFIG.steadyAfter or 7) then return false end
			end
		end
		if not any then return false end
		if H.LAST_TOGGLE_T and H.NOW - H.LAST_TOGGLE_T < 1 then return false end
		return true
	end

	function H.endFrameStats()
		local active = H.UPDATED_THIS_FRAME
		H.UPDATED_THIS_FRAME = false
		local steady = active and H.isSteady()
		if active then
			nFrames += 1
			if steady then nSteady += 1 end
		end
		for kind, tbl in pairs(H.FW) do
			local agg = AGG[kind]
			for m, n in pairs(tbl) do
				local a = agg[m.key]
				if not a then
					a = { key = m.key, cat = category(m), total = 0, max = 0, frames = 0, sTotal = 0, sFrames = 0, sMax = 0 }
					agg[m.key] = a
				end
				a.total += n
				a.frames += 1
				if n > a.max then a.max = n end
				if steady then
					a.sTotal += n
					a.sFrames += 1
					if n > a.sMax then a.sMax = n end
				end
			end
			table.clear(tbl)
		end
		for m, n in pairs(H.FWR) do
			local a = AGG.redundant[m.key]
			if not a then a = { key = m.key, cat = category(m), total = 0, max = 0, frames = 0, sTotal = 0, sFrames = 0, sMax = 0 } AGG.redundant[m.key] = a end
			a.total += n
			a.frames += 1
			if n > a.max then a.max = n end
			if steady then a.sTotal += n a.sFrames += 1 if n > a.sMax then a.sMax = n end end
		end
		table.clear(H.FWR)
		if active then
			local sf = H.STATS_FRAME
			series("bulkMoved", sf.bulkMoved or 0, steady)
			series("bulkCalls", sf.bulkCalls or 0, steady)
			series("newInstances", sf.newInstances or 0, steady)
			series("emitBurst", sf.emitted or 0, steady)
		end
		table.clear(H.STATS_FRAME)
	end
	function H.frameCounts() return nFrames, nSteady end

	-------------------------------------------------------------------------------------- what is drawn
	-- instances that render: the aura container's descendants plus anything the module created elsewhere in Workspace
	-- (attachments on the character, effects under the camera) and post effects it created under Lighting/Camera
	function H.renderables()
		local list, seen = {}, {}
		local inWorld = H.isDescendantOf(H.container, H.workspace)
		if inWorld then
			H.forDescendants(H.container, function(c) if not seen[c] then seen[c] = true list[#list + 1] = c end end)
		end
		for _, c in ipairs(H.CREATED) do
			local p = c.p
			local d = D[p]
			if d and not d.destroyed and not seen[p] and not H.isDescendantOf(p, H.container) then
				if H.isDescendantOf(p, H.workspace) or (d.cls.isa.PostEffect and H.isDescendantOf(p, H.game)) or d.cls.isa.Atmosphere then
					seen[p] = true
					list[#list + 1] = p
					H.forDescendants(p, function(cc) if not seen[cc] then seen[cc] = true list[#list + 1] = cc end end)
				end
			end
		end
		return list, inWorld
	end

	local function meanLifetime(d)
		local l = d.props.Lifetime or H.nrange(5, 10)
		return (l.Min + l.Max) / 2
	end
	local function meanSeq(s)
		if not s then return 1 end
		local sum, n = 0, 0
		for _, k in ipairs(s.Keypoints) do sum += k.Value n += 1 end
		return sum / n
	end
	local function hostOk(d)
		local par = d.parent
		if not par then return false end
		local pd = D[par]
		return pd.cls.isa.BasePart or pd.cls.isa.Attachment
	end
	local function enabledInTree(p)
		-- LayerCollector / effects disabled by an ancestor GUI etc. are not handled; Enabled is per instance
		return H.rawGet(p, "Enabled") ~= false
	end

	function H.census()
		local list, inWorld = H.renderables()
		local byClass = {}
		local c = { total = 0, baseParts = 0, emitters = 0, emittersEnabled = 0, rateSum = 0, alive = 0, particleArea = 0,
			beams = 0, beamsEnabled = 0, beamSegments = 0, guis = 0, guisEnabled = 0, images = 0, canvasPixels = 0, lights = 0,
			lightsEnabled = 0, shadowLights = 0, highlights = 0, trails = 0, attachments = 0, decals = 0, meshParts = 0,
			opaqueParts = 0, inWorld = inWorld }
		local hiAlive = {}
		for _, p in ipairs(list) do
			local d = D[p]
			local cn = d.cls.name
			byClass[cn] = (byClass[cn] or 0) + 1
			c.total += 1
			local isa = d.cls.isa
			if isa.BasePart then
				c.baseParts += 1
				if isa.MeshPart then c.meshParts += 1 end
				if (d.props.Transparency or 0) < 0.5 then c.opaqueParts += 1 end
			elseif isa.ParticleEmitter then
				c.emitters += 1
				if enabledInTree(p) and hostOk(d) then
					c.emittersEnabled += 1
					local rate = math.max(0, d.props.Rate or 20)
					local life = meanLifetime(d)
					local alive = rate * life
					c.rateSum += rate
					c.alive += alive
					local sz = meanSeq(d.props.Size)
					c.particleArea += alive * sz * sz
					hiAlive[#hiAlive + 1] = { path = H.fullName(p), alive = alive, rate = rate, life = life }
				end
			elseif isa.Beam then
				c.beams += 1
				if d.props.Enabled ~= false then c.beamsEnabled += 1 end
				c.beamSegments += d.props.Segments or 10
			elseif isa.SurfaceGui or isa.BillboardGui then
				c.guis += 1
				if d.props.Enabled ~= false then c.guisEnabled += 1 end
				if isa.SurfaceGui then
					local cs = d.props.CanvasSize or H.v2(800, 600)
					c.canvasPixels += cs.X * cs.Y
				end
			elseif isa.ImageLabel or isa.ImageButton then
				c.images += 1
			elseif isa.Light then
				c.lights += 1
				if d.props.Enabled ~= false then c.lightsEnabled += 1 end
				if d.props.Shadows then c.shadowLights += 1 end
			elseif isa.Highlight then
				c.highlights += 1
			elseif isa.Trail then
				c.trails += 1
			elseif isa.Attachment then
				c.attachments += 1
			elseif isa.Decal then
				c.decals += 1
			end
		end
		table.sort(hiAlive, function(a, b) return a.alive > b.alive end)
		local top = {}
		for i = 1, math.min(5, #hiAlive) do top[i] = hiAlive[i] end
		c.topEmitters = top
		c.byClass = H.obj(byClass)
		return c
	end

	-------------------------------------------------------------------------------------- camera occlusion
	-- does something solid of the aura sit between the camera and the wearer's head? (the pass-4 clock did, from behind)
	H.OCC = { samples = 0, blocked = 0, by = {} }
	function H.sampleOcclusion()
		local rec = H.RECS[1]
		if not (rec and rec.fx and rec.isLocal and rec.visible) then return end
		local head = H.rawFind(rec.char, "Head")
		if not head then return end
		local camPos = H.rawGet(H.camera, "CFrame").Position
		local headPos = H.rawGet(head, "CFrame").Position
		local seg = headPos - camPos
		local len = seg.Magnitude
		if len < 1 then return end
		local dir = seg / len
		H.OCC.samples += 1
		local blockers = {}
		local list = H.renderables()
		for _, p in ipairs(list) do
			local d = D[p]
			if d.cls.isa.BasePart then
				local solid = (d.props.Transparency or 0) < 0.5 and (d.props.LocalTransparencyModifier or 0) < 0.5
				if not solid then
					for _, ch in ipairs(d.children) do
						local cd = D[ch]
						if cd.cls.isa.SurfaceGui and cd.props.Enabled ~= false then
							for _, im in ipairs(cd.children) do
								local imd = D[im]
								if imd.cls.isa.ImageLabel and (imd.props.ImageTransparency or 0) < 0.5 and imd.props.Visible ~= false then solid = true end
							end
						end
					end
				end
				if solid then
					local tHit = H.rayPart(camPos, dir, len - 0.8, p)
					if tHit then blockers[#blockers + 1] = d.name end
				end
			end
		end
		if #blockers > 0 then
			H.OCC.blocked += 1
			for _, n in ipairs(blockers) do H.OCC.by[n] = (H.OCC.by[n] or 0) + 1 end
		end
	end

	-------------------------------------------------------------------------------------- design lints from the project's lessons
	-- (1) a BillboardGui whose sprite crosses a SurfaceGui plane gets cut in Roblox;
	-- (2) THE END's opacity rule (pass-5 art direction): nothing over 6 studs with a uniform transparency of 0.3..0.8
	local function billboardInfo(p, d)
		local host = d.props.Adornee or d.parent
		local hd = host and D[host]
		if not hd then return nil end
		local pos
		if hd.cls.isa.BasePart then pos = (hd.props.CFrame or IDENT).Position
		elseif hd.cls.isa.Attachment then pos = H.attachmentWorldCF(host).Position
		else return nil end
		local sz = d.props.Size
		if not sz then return nil end
		local r = math.max(sz.X.Scale, sz.Y.Scale) / 2
		local swo = d.props.StudsOffsetWorldSpace
		if swo then pos += swo end
		return pos, r
	end
	local function solidImage(gui)
		for _, c in ipairs(D[gui].children) do
			local cd = D[c]
			if (cd.cls.isa.ImageLabel or cd.cls.isa.ImageButton) and (cd.props.ImageTransparency or 0) < 0.95 then return cd end
		end
		return nil
	end
	H.CUTS = { samples = 0, hits = {} }
	local Vector3 = H.Vector3
	-- the billboard's quad as Roblox draws it: centred on its host (+ world offset + camera-space offset), facing the camera
	local function billboardQuad(p, d, camCF)
		local pos, r = billboardInfo(p, d)
		if not pos then return nil end
		local so = d.props.StudsOffset
		if so then pos += camCF:VectorToWorldSpace(so) end
		local sz = d.props.Size
		local n = camCF.Position - pos
		if n.Magnitude < 1e-6 then return nil end
		n = n.Unit
		local right = Vector3.yAxis:Cross(n)
		if right.Magnitude < 1e-6 then right = Vector3.xAxis else right = right.Unit end
		local up = n:Cross(right).Unit
		-- (round sprites fade out towards the edges: only the inner half is tested)
		return { c = pos, r = right, u = up, hw = sz.X.Scale / 2 * 0.5, hh = sz.Y.Scale / 2 * 0.5, w = sz.X.Scale }
	end
	function H.sampleCuts()
		local list = H.renderables()
		local planes, bbs = {}, {}
		local camCF = H.rawGet(H.camera, "CFrame")
		for _, p in ipairs(list) do
			local d = D[p]
			if d.cls.isa.SurfaceGui and d.props.Enabled ~= false and solidImage(p) then
				local host = d.props.Adornee or d.parent
				if host and D[host].cls.isa.BasePart then planes[#planes + 1] = host end
			elseif d.cls.isa.BillboardGui and d.props.Enabled ~= false then
				local im = solidImage(p)
				local q = im and (im.props.ImageTransparency or 0) < 0.3 and billboardQuad(p, d, camCF)
				if q and q.hw > 0.25 and q.hh > 0.25 then
					q.name = string.format("%s's %.1f-stud sprite", d.parent and D[d.parent].name or "?", q.w)
					q.host = d.parent
					bbs[#bbs + 1] = q
				end
			end
		end
		if #planes == 0 or #bbs == 0 then return end
		H.CUTS.samples += 1
		local seen = {}
		for _, q in ipairs(bbs) do
			for _, part in ipairs(planes) do
				local pd = D[part]
				local c, sz = pd.props.CFrame or IDENT, pd.props.Size or v3(1, 1, 1)
				-- the plane: the part's thinnest axis is its normal; the other two give the face rectangle
				local axes = { { c.XVector, sz.X }, { c.YVector, sz.Y }, { c.ZVector, sz.Z } }
				table.sort(axes, function(a, b) return a[2] < b[2] end)
				local nrm, e1, h1, e2, h2 = axes[1][1], axes[2][1], axes[2][2] / 2, axes[3][1], axes[3][2] / 2
				if axes[1][2] < 0.5 and part ~= q.host then
					local p0 = c.Position
					local hit = false
					local N = 8
					local step = math.max(q.hw, q.hh) * 2 / N
					for i = 0, N do
						for j = 0, N do
							local pt = q.c + q.r * ((i / N * 2 - 1) * q.hw) + q.u * ((j / N * 2 - 1) * q.hh)
							local rel = pt - p0
							if math.abs(rel:Dot(nrm)) < step * 0.5 and math.abs(rel:Dot(e1)) < h1 and math.abs(rel:Dot(e2)) < h2 then
								hit = true
								break
							end
						end
						if hit then break end
					end
					if hit then
						local key = q.name .. "|" .. pd.name
						if not seen[key] then
							seen[key] = true
							H.CUTS.hits[key] = (H.CUTS.hits[key] or 0) + 1
						end
					end
				end
			end
		end
	end
	-- path below the aura's root (e.g. "Shards.SurfaceGui"), so every wearer's copy reports once
	local function relPath(p)
		local parts = {}
		local cur = p
		while cur do
			local d = D[cur]
			if d.parent == H.container then break end
			table.insert(parts, 1, d.name)
			cur = d.parent
		end
		return table.concat(parts, ".")
	end
	function H.designLints()
		if not (H.CONFIG and H.CONFIG.mono) then return end
		local list = H.renderables()
		local function ghost(tr) return tr >= 0.3 and tr <= 0.8 end
		local recordWarning = H.recordWarning
		local function warnLayer(p, what, size, tr)
			recordWarning("translucent-layer", string.format("%s: a %.0f-stud %s at transparency %.2f (opacity rule: nothing over 6 studs at 0.3..0.8)",
				relPath(p), size, what, tr), "")
		end
		for _, p in ipairs(list) do
			local d = D[p]
			local isa = d.cls.isa
			if isa.BasePart then
				local sz = d.props.Size or v3(4, 1, 2)
				local big = math.max(sz.X, sz.Y, sz.Z)
				if big > 6 and ghost(d.props.Transparency or 0) then warnLayer(p, "part", big, d.props.Transparency) end
			elseif isa.SurfaceGui and d.props.Enabled ~= false then
				local host = d.props.Adornee or d.parent
				local hd = host and D[host]
				if hd and hd.cls.isa.BasePart then
					local sz = hd.props.Size or v3(1, 1, 1)
					local big = math.max(sz.X, sz.Y, sz.Z)
					local im = solidImage(p)
					if im and big > 6 and ghost(im.props.ImageTransparency or 0) then warnLayer(p, "image layer", big, im.props.ImageTransparency) end
				end
			elseif isa.BillboardGui and d.props.Enabled ~= false then
				local _, r = billboardInfo(p, d)
				local im = solidImage(p)
				if r and im and r * 2 > 6 and ghost(im.props.ImageTransparency or 0) then warnLayer(p, "sprite", r * 2, im.props.ImageTransparency) end
			elseif isa.Beam and d.props.Enabled ~= false then
				local w = math.max(d.props.Width0 or 1, d.props.Width1 or 1)
				local t = d.props.Transparency
				if w > 6 and t then
					local mn, mx = 1, 0
					for _, k in ipairs(t.Keypoints) do mn, mx = math.min(mn, k.Value), math.max(mx, k.Value) end
					if mx - mn < 0.15 and ghost((mn + mx) / 2) or (ghost(mn) and ghost(mx)) then warnLayer(p, "wide beam", w, (mn + mx) / 2) end
				end
			end
		end
	end

	-------------------------------------------------------------------------------------- history (for snapshot particles/trails)
	local HIST_DT = 0.1
	local lastHist = -1
	function H.sampleHistory()
		if not H.WANT_HISTORY then return end
		if H.NOW - lastHist < HIST_DT - 1e-6 then return end
		lastHist = H.NOW
		local list = H.renderables()
		for _, p in ipairs(list) do
			local d = D[p]
			if d.cls.isa.ParticleEmitter or d.cls.isa.Trail then
				local hist = d.hist
				if not hist then hist = { t = {}, cf = {}, en = {} } d.hist = hist end
				local host
				if d.cls.isa.ParticleEmitter then
					local par = d.parent
					if par then
						local pd = D[par]
						if pd.cls.isa.BasePart then host = pd.props.CFrame or IDENT
						elseif pd.cls.isa.Attachment then host = H.attachmentWorldCF(par) end
					end
				else
					local a0, a1 = d.props.Attachment0, d.props.Attachment1
					if a0 and a1 and D[a0] and D[a1] then
						local w0, w1 = H.attachmentWorldCF(a0), H.attachmentWorldCF(a1)
						host = { w0.X, w0.Y, w0.Z, w1.X, w1.Y, w1.Z }
					end
				end
				if host then
					table.insert(hist.t, H.NOW)
					table.insert(hist.cf, host)
					table.insert(hist.en, d.props.Enabled ~= false)
					if #hist.t > 210 then
						table.remove(hist.t, 1) table.remove(hist.cf, 1) table.remove(hist.en, 1)
					end
				end
			end
		end
	end

	-------------------------------------------------------------------------------------- snapshot
	local function cfArr(c)
		c = c or IDENT
		return { c.X, c.Y, c.Z, c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9] }
	end
	local function v3Arr(v) if not v then return nil end return { v.X, v.Y, v.Z } end
	local function rgb(c) if not c then return { 255, 255, 255 } end return { c.R * 255, c.G * 255, c.B * 255 } end
	local function nseqArr(s)
		local out = {}
		if s then for i, k in ipairs(s.Keypoints) do out[i] = { k.Time, k.Value, k.Envelope } end end
		return out
	end
	local function cseqArr(s)
		local out = {}
		if s then for i, k in ipairs(s.Keypoints) do out[i] = { k.Time, k.Value.R * 255, k.Value.G * 255, k.Value.B * 255 } end end
		return out
	end
	local function u2Arr(u) if not u then return { 0, 0, 0, 0 } end return { u.X.Scale, u.X.Offset, u.Y.Scale, u.Y.Offset } end
	local function v2Arr(v) if not v then return { 0, 0 } end return { v.X, v.Y } end
	-- a UICorner inside a GuiObject: its CornerRadius as [scale, offset] (nil: square corners)
	local function cornerOf(c)
		for _, ch in ipairs(D[c].children or {}) do
			if D[ch] and D[ch].cls.isa.UICorner then
				local r = H.rawGet(ch, "CornerRadius")
				return { r.Scale, r.Offset }
			end
		end
		return nil
	end
	local NULL = H.NULL
	local function nn(v) if v == nil then return NULL end return v end
	local function en(v) return v and v.Name or NULL end
	local function g(p, k) return H.rawGet(p, k) end
	local function shapeOf(d)
		local isa = d.cls.isa
		if isa.MeshPart or isa.PartOperation then return "Mesh" end
		if isa.WedgePart then return "Wedge" end
		if isa.CornerWedgePart then return "CornerWedge" end
		if isa.Part then
			local s = d.props.Shape
			return s and s.Name or "Block"
		end
		return "Block"
	end
	local function hostPart(p)
		local cur = D[p].parent
		while cur do
			local cd = D[cur]
			if cd.cls.isa.BasePart then return cur end
			cur = cd.parent
		end
		return nil
	end

	function H.snapshot(scenario)
		local list, inWorld = H.renderables()
		local rec = H.RECS[1]
		local snap = {
			version = 1, scenario = scenario, frame = H.FRAME, t = H.NOW, clockTime = g(H.SERVICES.Lighting, "ClockTime"),
			quality = H.CONFIG.quality or "high", auraInWorld = inWorld,
			camera = H.obj({ cf = cfArr(g(H.camera, "CFrame")), fov = g(H.camera, "FieldOfView"), viewport = { H.VIEWPORT.X, H.VIEWPORT.Y },
				cameraType = en(g(H.camera, "CameraType")), preset = H.CONFIG.cameraName }),
			parts = {}, attachments = {}, beams = {}, guis = {}, emitters = {}, trails = {}, lights = {}, highlights = {}, effects = {},
		}
		-- the plaza's top (the scenario's ground: a seat or a slope does not move it), so the renderer draws the floor there
		if H.plaza and D[H.plaza] and not D[H.plaza].destroyed then
			local pc, ps = g(H.plaza, "CFrame"), g(H.plaza, "Size")
			local up = pc.UpVector
			if up.Y < 0.99999 then
				-- (a tilted plaza, e.g. the slope scenario: its top surface's centre and normal, so the renderer tilts the ground)
				local top = pc * Vector3.new(0, ps.Y / 2, 0)
				snap.world = H.obj({ groundY = top.Y, groundTop = v3Arr(top), groundUp = v3Arr(up) })
			else
				snap.world = H.obj({ groundY = pc.Position.Y + ps.Y / 2 })
			end
		end
		if rec then
			local s = rec.lastS
			snap.wearer = H.obj({ cf = cfArr(g(rec.hrp, "CFrame")), hover = rec.hover, glide = rec.g, legLen = s and s.legLen or 3,
				ground = rec.ground and v3Arr(rec.ground) or NULL, isLocal = rec.isLocal, rig = rec.info.r15 and "R15" or "R6", alpha = rec.alpha })
			snap.characters = {}
			for ri, r in ipairs(H.RECS) do
				if not D[r.char].destroyed then
					local parts = {}
					H.forDescendants(r.char, function(p)
						local d = D[p]
						if d.cls.isa.BasePart then
							parts[#parts + 1] = H.obj({ name = d.name, class = d.cls.name, size = v3Arr(d.props.Size), cf = cfArr(d.props.CFrame),
								color = rgb(d.props.Color), transparency = d.props.Transparency or 0 })
						end
					end)
					snap.characters[ri] = H.obj({ name = D[r.char].name, wearer = r.equipped, parts = parts })
				end
			end
		end
		local attSeen = {}
		local function addAtt(a)
			if not a or not D[a] or attSeen[a] then return end
			attSeen[a] = true
			local d = D[a]
			local host = d.parent and D[d.parent].cls.isa.BasePart and d.parent or nil
			snap.attachments[#snap.attachments + 1] = H.obj({ id = d.id, path = H.fullName(a), hostId = host and D[host].id or NULL,
				worldCf = cfArr(H.attachmentWorldCF(a)) })
		end
		for _, p in ipairs(list) do
			local d = D[p]
			local isa = d.cls.isa
			local pr = d.props
			if isa.BasePart then
				local e = { id = d.id, path = H.fullName(p), class = d.cls.name, shape = shapeOf(d), size = v3Arr(g(p, "Size")),
					cf = cfArr(pr.CFrame), color = rgb(g(p, "Color")), material = en(g(p, "Material")), transparency = g(p, "Transparency"),
					localTransparencyModifier = g(p, "LocalTransparencyModifier"), reflectance = g(p, "Reflectance"),
					meshId = isa.MeshPart and nn(pr.MeshId) or NULL, textureId = isa.MeshPart and nn(pr.TextureID) or NULL,
					parentPath = d.parent and H.fullName(d.parent) or NULL, castShadow = g(p, "CastShadow") }
				if isa.MeshPart then e.meshSize = v3Arr(pr.MeshSize) end
				for _, ch in ipairs(d.children) do
					local cd = D[ch]
					if cd.cls.isa.SpecialMesh then
						e.specialMesh = H.obj({ meshType = en(g(ch, "MeshType")), meshId = g(ch, "MeshId"), textureId = g(ch, "TextureId"),
							scale = v3Arr(g(ch, "Scale")), offset = v3Arr(g(ch, "Offset")) })
					elseif cd.cls.isa.Decal then
						e.decals = e.decals or {}
						table.insert(e.decals, H.obj({ class = cd.cls.name, face = en(g(ch, "Face")), texture = g(ch, "Texture"),
							color = rgb(g(ch, "Color3")), transparency = g(ch, "Transparency") }))
					elseif cd.cls.isa.SurfaceAppearance then
						e.surfaceAppearance = H.obj({ colorMap = g(ch, "ColorMap") })
					end
				end
				snap.parts[#snap.parts + 1] = H.obj(e)
			elseif isa.Attachment then
				addAtt(p)
			elseif isa.Beam then
				local a0, a1 = pr.Attachment0, pr.Attachment1
				addAtt(a0) addAtt(a1)
				snap.beams[#snap.beams + 1] = H.obj({ path = H.fullName(p), a0 = a0 and D[a0].id or NULL, a1 = a1 and D[a1].id or NULL,
					curve0 = g(p, "CurveSize0"), curve1 = g(p, "CurveSize1"), width0 = g(p, "Width0"), width1 = g(p, "Width1"),
					segments = g(p, "Segments"), faceCamera = g(p, "FaceCamera"), texture = g(p, "Texture"), textureMode = en(g(p, "TextureMode")),
					textureLength = g(p, "TextureLength"), textureSpeed = g(p, "TextureSpeed"), color = cseqArr(g(p, "Color")),
					transparency = nseqArr(g(p, "Transparency")), lightEmission = g(p, "LightEmission"), lightInfluence = g(p, "LightInfluence"),
					brightness = g(p, "Brightness"), zOffset = g(p, "ZOffset"), enabled = g(p, "Enabled"),
					localTransparencyModifier = g(p, "LocalTransparencyModifier") })
			elseif isa.SurfaceGui or isa.BillboardGui then
				local host = pr.Adornee or d.parent
				local hostAtt = nil
				if host and D[host].cls.isa.Attachment then hostAtt = host host = D[host].parent end
				if host and not D[host].cls.isa.BasePart then host = hostPart(p) end
				local images, texts = {}, {}
				H.forDescendants(p, function(c)
					local cd = D[c]
					if (cd.cls.isa.ImageLabel or cd.cls.isa.ImageButton) then
						images[#images + 1] = H.obj({ image = g(c, "Image"), color = rgb(g(c, "ImageColor3")), transparency = g(c, "ImageTransparency"),
							rotation = g(c, "Rotation"), size = u2Arr(g(c, "Size")), position = u2Arr(g(c, "Position")),
							anchor = { g(c, "AnchorPoint").X, g(c, "AnchorPoint").Y }, visible = g(c, "Visible"), zIndex = g(c, "ZIndex"),
							backgroundTransparency = g(c, "BackgroundTransparency"), backgroundColor = rgb(g(c, "BackgroundColor3")),
							rectOffset = v2Arr(g(c, "ImageRectOffset")), rectSize = v2Arr(g(c, "ImageRectSize")), corner = cornerOf(c) })
					elseif cd.cls.isa.TextLabel then
						texts[#texts + 1] = H.obj({ text = g(c, "Text"), color = rgb(g(c, "TextColor3")), transparency = g(c, "TextTransparency"),
							size = u2Arr(g(c, "Size")), position = u2Arr(g(c, "Position")), visible = g(c, "Visible") })
					end
				end)
				local e = { kind = d.cls.name, path = H.fullName(p), hostId = host and D[host].id or NULL, hostAttachmentId = hostAtt and D[hostAtt].id or NULL,
					brightness = g(p, "Brightness"), lightInfluence = g(p, "LightInfluence"), alwaysOnTop = g(p, "AlwaysOnTop"),
					enabled = g(p, "Enabled"), images = images, texts = texts }
				if hostAtt then addAtt(hostAtt) end
				e.hostCf = host and cfArr(D[host].props.CFrame) or NULL
				e.face, e.canvas, e.sizeStuds, e.studsOffset, e.studsOffsetWorldSpace, e.maxDistance = NULL, NULL, NULL, NULL, NULL, NULL
				if isa.SurfaceGui then
					e.face = en(g(p, "Face"))
					local cs = g(p, "CanvasSize")
					e.canvas = { cs.X, cs.Y }
					e.sizingMode = en(g(p, "SizingMode"))
					e.pixelsPerStud = g(p, "PixelsPerStud")
					e.zOffset = g(p, "ZOffset")
				else
					local sz = g(p, "Size")
					e.sizeStuds = { sz.X.Scale, sz.Y.Scale }
					e.sizeOffsetPx = { sz.X.Offset, sz.Y.Offset }
					e.studsOffset = v3Arr(g(p, "StudsOffset"))
					e.studsOffsetWorldSpace = v3Arr(g(p, "StudsOffsetWorldSpace"))
					e.extentsOffset = v3Arr(g(p, "ExtentsOffset"))
					local md = g(p, "MaxDistance")
					e.maxDistance = (md and md < 1e15) and md or NULL
				end
				snap.guis[#snap.guis + 1] = H.obj(e)
			elseif isa.ParticleEmitter then
				local par = d.parent
				local pd = par and D[par]
				local e = { path = H.fullName(p), hostId = (pd and pd.cls.isa.BasePart) and pd.id or NULL,
					hostAttachmentId = (pd and pd.cls.isa.Attachment) and pd.id or NULL, enabled = g(p, "Enabled"), texture = g(p, "Texture"),
					localTransparencyModifier = g(p, "LocalTransparencyModifier"),
					rate = g(p, "Rate"), lifetime = { g(p, "Lifetime").Min, g(p, "Lifetime").Max }, speed = { g(p, "Speed").Min, g(p, "Speed").Max },
					spreadAngle = { g(p, "SpreadAngle").X, g(p, "SpreadAngle").Y }, emissionDirection = en(g(p, "EmissionDirection")),
					shape = en(g(p, "Shape")), shapeStyle = en(g(p, "ShapeStyle")), shapeInOut = en(g(p, "ShapeInOut")), shapePartial = g(p, "ShapePartial"),
					size = nseqArr(g(p, "Size")), transparency = nseqArr(g(p, "Transparency")), color = cseqArr(g(p, "Color")),
					lightEmission = g(p, "LightEmission"), lightInfluence = g(p, "LightInfluence"), brightness = g(p, "Brightness"),
					acceleration = v3Arr(g(p, "Acceleration")), drag = g(p, "Drag"), lockedToPart = g(p, "LockedToPart"),
					rotation = { g(p, "Rotation").Min, g(p, "Rotation").Max }, rotSpeed = { g(p, "RotSpeed").Min, g(p, "RotSpeed").Max },
					zOffset = g(p, "ZOffset"), orientation = en(g(p, "Orientation")), flipbookLayout = en(g(p, "FlipbookLayout")),
					flipbookMode = en(g(p, "FlipbookMode")), flipbookFramerate = { g(p, "FlipbookFramerate").Min, g(p, "FlipbookFramerate").Max },
					flipbookStartRandom = g(p, "FlipbookStartRandom"), squash = pr.Squash and nseqArr(pr.Squash) or NULL, timeScale = g(p, "TimeScale"),
					velocityInheritance = g(p, "VelocityInheritance") }
				if pd and pd.cls.isa.Attachment then addAtt(par) end
				if d.hist then
					local h = {}
					for i = 1, #d.hist.t do
						local c = d.hist.cf[i]
						h[i] = { d.hist.t[i], c.X, c.Y, c.Z, c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], d.hist.en[i] and 1 or 0 }
					end
					e.hostHistory = h
				end
				if d.bursts then
					local b = {}
					for _, x in ipairs(d.bursts) do if H.NOW - x.t < 20 then b[#b + 1] = { x.t, x.n } end end
					e.bursts = b
				end
				if pd and pd.cls.isa.BasePart then e.hostSize = v3Arr(pd.props.Size) e.hostCf = cfArr(pd.props.CFrame) end
				if pd and pd.cls.isa.Attachment then e.hostCf = cfArr(H.attachmentWorldCF(par)) end
				snap.emitters[#snap.emitters + 1] = H.obj(e)
			elseif isa.Trail then
				local a0, a1 = pr.Attachment0, pr.Attachment1
				addAtt(a0) addAtt(a1)
				local e = { path = H.fullName(p), a0 = a0 and D[a0].id or NULL, a1 = a1 and D[a1].id or NULL, enabled = g(p, "Enabled"),
					texture = g(p, "Texture"), textureMode = en(g(p, "TextureMode")), textureLength = g(p, "TextureLength"), lifetime = g(p, "Lifetime"),
					minLength = g(p, "MinLength"), maxLength = g(p, "MaxLength"), widthScale = nseqArr(g(p, "WidthScale")), color = cseqArr(g(p, "Color")),
					transparency = nseqArr(g(p, "Transparency")), lightEmission = g(p, "LightEmission"), lightInfluence = g(p, "LightInfluence"),
					brightness = g(p, "Brightness"), faceCamera = g(p, "FaceCamera") }
				if d.hist then
					local h = {}
					for i = 1, #d.hist.t do local c = d.hist.cf[i] h[i] = { d.hist.t[i], c[1], c[2], c[3], c[4], c[5], c[6] } end
					e.history = h
				end
				snap.trails[#snap.trails + 1] = H.obj(e)
			elseif isa.Light then
				local par = d.parent
				local pd = par and D[par]
				local hostId = pd and pd.cls.isa.BasePart and pd.id or nil
				local hostAtt = pd and pd.cls.isa.Attachment and pd.id or nil
				local hostCf = pd and pd.cls.isa.BasePart and cfArr(pd.props.CFrame) or nil
				if hostAtt then addAtt(par) hostId = pd.parent and D[pd.parent].id or nil hostCf = cfArr(H.attachmentWorldCF(par)) end
				snap.lights[#snap.lights + 1] = H.obj({ class = d.cls.name, path = H.fullName(p), hostId = nn(hostId), hostAttachmentId = nn(hostAtt),
					color = rgb(g(p, "Color")), brightness = g(p, "Brightness"), range = g(p, "Range"), enabled = g(p, "Enabled"),
					shadows = g(p, "Shadows"), angle = (isa.SpotLight or isa.SurfaceLight) and g(p, "Angle") or NULL,
					face = (isa.SpotLight or isa.SurfaceLight) and en(g(p, "Face")) or NULL, hostCf = nn(hostCf) })
			elseif isa.Highlight then
				local ad = pr.Adornee or d.parent
				snap.highlights[#snap.highlights + 1] = H.obj({ path = H.fullName(p), adorneePath = ad and H.fullName(ad) or NULL,
					adorneeId = ad and D[ad].id or NULL, fillColor = rgb(g(p, "FillColor")), fillTransparency = g(p, "FillTransparency"),
					outlineColor = rgb(g(p, "OutlineColor")), outlineTransparency = g(p, "OutlineTransparency"), depthMode = en(g(p, "DepthMode")),
					enabled = g(p, "Enabled") })
			elseif isa.PostEffect or isa.Atmosphere or isa.Sky then
				local props = {}
				for k, v in pairs(pr) do
					local tv = H.typeof(v)
					if tv == "number" or tv == "boolean" or tv == "string" then props[k] = v
					elseif tv == "Color3" then props[k] = rgb(v)
					elseif tv == "EnumItem" then props[k] = v.Name end
				end
				snap.effects[#snap.effects + 1] = H.obj({ class = d.cls.name, path = H.fullName(p), parentPath = d.parent and H.fullName(d.parent) or NULL,
					props = H.obj(props) })
			end
		end
		H.emit("snapshot", { snap = snap })
	end
end
