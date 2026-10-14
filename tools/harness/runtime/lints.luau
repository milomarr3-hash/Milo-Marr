-- lints: error/warning recording, property lints (asset id formats, the monochrome palette lock, Roblox clamps),
-- and flicker detection (fast back-and-forth changes of brightness/transparency/enabled).
do
	local format, typeof = string.format, H.typeof
	local D = H.INST_DATA

	-------------------------------------------------------------------------------------- errors / warnings
	H.ERRORS, H.ERROR_KEYS = {}, {}
	H.WARNINGS, H.WARNING_KEYS = {}, {}
	local function firstLines(tb, n)
		if not tb then return "" end
		local out, i = {}, 0
		for line in tb:gmatch("[^\n]+") do
			i += 1
			if i > n then break end
			out[#out + 1] = line
		end
		return table.concat(out, "\n")
	end
	function H.recordError(msg, tb, where)
		local key = msg .. "|" .. firstLines(tb, 3)
		local e = H.ERROR_KEYS[key]
		if e then
			e.count += 1
			e.lastFrame = H.FRAME
			return
		end
		e = { msg = msg, tb = tb or "", where = where or (H.CTX and H.CTX.phase) or "?", frame = H.FRAME, t = H.NOW, count = 1,
			lastFrame = H.FRAME, gen = H.CTX and H.CTX.gen or 0 }
		H.ERROR_KEYS[key] = e
		H.ERRORS[#H.ERRORS + 1] = e
		H.emit("error", { msg = msg, tb = tb or "", where = e.where, frame = e.frame, t = e.t })
	end
	function H.recordWarning(code, msg, tb)
		local key = code .. "|" .. msg
		local w = H.WARNING_KEYS[key]
		if w then
			w.count += 1
			return
		end
		tb = tb or debug.traceback(nil, 2)
		w = { code = code, msg = msg, tb = tb, frame = H.FRAME, t = H.NOW, count = 1 }
		H.WARNING_KEYS[key] = w
		H.WARNINGS[#H.WARNINGS + 1] = w
	end

	-------------------------------------------------------------------------------------- asset ids
	H.ASSETS = {}
	local function assetLint(p, d, v, m)
		if v == "" then return v end
		local ok = v:match("^rbxassetid://%d+$") or v:match("^rbxasset://.+") or v:match("^rbxthumb://.+")
			or v:match("^https?://www%.roblox%.com/asset/%?id=%d+$") or v:match("^https?://assetdelivery%.roblox%.com/v1/asset/%?id=%d+$")
			or v:match("^rbxhttp://.+")
		if not ok then
			H.recordWarning("asset-id", format("%s = \"%s\" is not a Roblox asset id format (expected rbxassetid://<number>)", m.key, v))
		end
		local a = H.ASSETS[v]
		if not a then a = { count = 0, props = {} } H.ASSETS[v] = a end
		a.count += 1
		a.props[m.key] = true
		return v
	end

	-------------------------------------------------------------------------------------- monochrome palette (THE END)
	local function monoCheck(c, where)
		if not (H.CONFIG and H.CONFIG.mono) then return end
		local h, s, v = H.toHSV(c)
		if s > 0.15 and v > 0.12 then
			H.recordWarning("palette", format("%s uses colour (%d, %d, %d) (saturation %.2f): outside THE END's black/white/silver lock",
				where, math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5), s))
		end
	end
	local function colorLint(p, d, v, m) monoCheck(v, m.key) return v end
	local function cseqLint(p, d, v, m)
		for _, k in ipairs(v.Keypoints) do monoCheck(k.Value, m.key) end
		return v
	end

	H.TYPE_LINTS = { Content = assetLint, Color3 = colorLint, ColorSequence = cseqLint }

	-------------------------------------------------------------------------------------- class-specific lints / clamps
	local PE = H.hook("ParticleEmitter").lint
	PE.Lifetime = function(p, d, v)
		if v.Max > 20 or v.Min < 0 then
			H.recordWarning("lifetime-clamp", format("ParticleEmitter.Lifetime %s: Roblox clamps particle lifetime to 0..20 s", tostring(v)))
			return H.nrange(math.clamp(v.Min, 0, 20), math.clamp(v.Max, 0, 20))
		end
		return v
	end
	local function unit01(cls, prop)
		return function(p, d, v)
			if v < 0 or v > 1 then
				H.recordWarning("range", format("%s.%s = %s is outside 0..1 (clamped when drawn)", cls, prop, H.fmtn(v)))
			end
			return v
		end
	end
	PE.LightEmission = unit01("ParticleEmitter", "LightEmission")
	PE.LightInfluence = unit01("ParticleEmitter", "LightInfluence")
	PE.Rate = function(p, d, v)
		if v > 500 then H.recordWarning("rate", format("ParticleEmitter.Rate = %s is very high (each particle costs fill-rate on phones)", H.fmtn(v))) end
		if v < 0 then H.recordWarning("rate", "ParticleEmitter.Rate is negative (treated as 0)") end
		return v
	end
	PE.TimeScale = unit01("ParticleEmitter", "TimeScale")
	local BM = H.hook("Beam").lint
	BM.Segments = function(p, d, v)
		if v < 1 or v > 1000 then
			H.recordWarning("segments", format("Beam.Segments = %d clamped to 1..1000", v))
			return math.clamp(v, 1, 1000)
		end
		return v
	end
	BM.LightEmission = unit01("Beam", "LightEmission")
	BM.LightInfluence = unit01("Beam", "LightInfluence")
	H.hook("Trail").lint.LightEmission = unit01("Trail", "LightEmission")
	H.hook("Trail").lint.Lifetime = function(p, d, v)
		if v > 20 then H.recordWarning("trail-lifetime", "Trail.Lifetime above 20 s is clamped") return 20 end
		return v
	end
	local function lightRange(cls)
		return function(p, d, v)
			if v > 60 then
				H.recordWarning("light-range", format("%s.Range = %s: Roblox caps light range at 60", cls, H.fmtn(v)))
				return 60
			end
			return v
		end
	end
	H.hook("PointLight").lint.Range = lightRange("PointLight")
	H.hook("SpotLight").lint.Range = lightRange("SpotLight")
	H.hook("SurfaceLight").lint.Range = lightRange("SurfaceLight")
	H.hook("Light").lint.Shadows = function(p, d, v)
		if v then H.recordWarning("light-shadows", format("%s.Shadows = true (shadow-casting lights are expensive; use sparingly)", d.cls.name)) end
		return v
	end
	H.hook("SurfaceGui").lint.CanvasSize = function(p, d, v)
		if v.X > 2048 or v.Y > 2048 then
			H.recordWarning("canvas", format("SurfaceGui.CanvasSize %s is larger than 2048 px (very expensive; textures max out at 1024)", tostring(v)))
		end
		return v
	end

	-------------------------------------------------------------------------------------- flicker
	-- a back-and-forth change (a "reversal") with a swing of at least 0.08; many reversals per second = flicker
	local function scalar(v)
		local t = type(v)
		if t == "number" then return v end
		if t == "boolean" then return v and 1 or 0 end
		local ty = typeof(v)
		if ty == "NumberSequence" then
			local s, n = 0, 0
			for _, k in ipairs(v.Keypoints) do s += k.Value n += 1 end
			return s / n
		end
		return nil
	end
	function H.observeFlicker(p, d, k, v)
		local x = scalar(v)
		if not x then return end
		local f = d.flk
		if not f then f = {} d.flk = f end
		local s = f[k]
		if not s then f[k] = { last = x, dir = 0, ext = x, rev = {}, path = H.fullName(p), bool = type(v) == "boolean" } return end
		local dx = x - s.last
		if dx ~= 0 then
			local dir = dx > 0 and 1 or -1
			if s.dir ~= 0 and dir ~= s.dir then
				if math.abs(s.last - s.ext) >= 0.08 then table.insert(s.rev, H.NOW) end
				s.ext = s.last
			elseif s.dir == 0 then
				s.ext = s.last
			end
			s.dir = dir
			if type(v) == "boolean" then table.insert(s.rev, H.NOW) end
		end
		s.last = x
	end
	-- after a run: anything that reversed 3+ times inside one second is reported
	function H.flickerReport()
		local out = {}
		for _, c in ipairs(H.CREATED) do
			local d = D[c.p]
			if d and d.flk then
				for k, s in pairs(d.flk) do
					local r = s.rev
					local best, i0 = 0, 1
					for i = 1, #r do
						while r[i] - r[i0] > 1.0 do i0 += 1 end
						best = math.max(best, i - i0 + 1)
					end
					-- numbers: 3 reversals in a second (1.5 cycles); on/off switches: 4 changes (2 full blinks)
					if best >= (s.bool and 4 or 3) then
						out[#out + 1] = { path = s.path, class = d.cls.name, prop = k, perSecond = best, total = #r }
					end
				end
			end
		end
		return out
	end
end
