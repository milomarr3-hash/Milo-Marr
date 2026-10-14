-- main: the module's global environment (Roblox globals over the real Luau builtins), the frame loop, the leak checks
-- after the final destroy, and the summary record the Python driver turns into report.md / report.json.
do
	local format = string.format
	local D = H.INST_DATA
	local v3 = H.v3

	-------------------------------------------------------------------------------------- globals the module sees
	local printed = 0
	local function modulePrint(...)
		local n = select("#", ...)
		local t = {}
		for i = 1, n do t[i] = tostring((select(i, ...))) end
		printed += 1
		if printed <= 200 then H.emit("print", { text = table.concat(t, " "), frame = H.FRAME, t = H.NOW }) end
	end
	local function moduleWarn(...)
		local n = select("#", ...)
		local t = {}
		for i = 1, n do t[i] = tostring((select(i, ...))) end
		H.recordWarning("module-warn", "warn(): " .. table.concat(t, " "))
	end
	local robloxDebug = table.freeze({
		traceback = debug.traceback, info = debug.info,
		profilebegin = function() end, profileend = function() end,
		setmemorycategory = function() end, resetmemorycategory = function() end, getmemorycategory = function() return "aura" end,
		dumpcodesize = function() end,
	})
	local robloxOs = table.freeze({
		clock = function() return H.vclock() end,
		time = function(t) if t then return os.time(t) end return math.floor(H.epochNow()) end,
		date = function(fmt, t) return os.date(fmt, t or math.floor(H.epochNow())) end,
		difftime = os.difftime,
	})
	local function robloxCollect(opt)
		if opt == "count" then return collectgarbage("count") end
		H.err("collectgarbage must be called with 'count'; use gcinfo() instead")
		return nil
	end

	function H.makeGlobals()
		local G = {}
		G.game = H.game
		G.workspace = H.workspace
		G.Workspace = H.workspace
		G.script = H.moduleScript
		G.plugin = nil
		G.shared = {}
		G._G = {}
		G.Instance, G.Vector3, G.Vector2, G.CFrame, G.Color3 = H.Instance, H.Vector3, H.Vector2, H.CFrame, H.Color3
		G.Vector3int16, G.Vector2int16, G.Region3, G.Region3int16, G.Ray = H.Vector3int16, H.Vector2int16, H.Region3, H.Region3int16, H.Ray
		G.ColorSequence, G.ColorSequenceKeypoint = H.ColorSequence, H.ColorSequenceKeypoint
		G.NumberSequence, G.NumberSequenceKeypoint, G.NumberRange = H.NumberSequence, H.NumberSequenceKeypoint, H.NumberRange
		G.UDim, G.UDim2, G.Rect, G.TweenInfo, G.Enum, G.Random = H.UDim, H.UDim2, H.Rect, H.TweenInfo, H.Enum, H.Random
		G.BrickColor, G.PhysicalProperties, G.Faces, G.Axes, G.Font = H.BrickColor, H.PhysicalProperties, H.Faces, H.Axes, H.Font
		G.DateTime, G.Content, G.RaycastParams, G.OverlapParams, G.PathWaypoint = H.DateTime, H.Content, H.RaycastParams, H.OverlapParams, H.PathWaypoint
		G.task = H.task
		G.wait, G.delay, G.spawn = H.wait, H.delay, H.spawn
		G.Wait, G.Delay, G.Spawn = H.wait, H.delay, H.spawn
		G.tick = function() return H.epochNow() end
		G.time = function() return H.vtime() end
		G.elapsedTime = function() return H.vclock() end
		G.ElapsedTime = G.elapsedTime
		G.os = robloxOs
		G.typeof = H.typeof
		G.type = H.robloxType
		G.print = modulePrint
		G.warn = moduleWarn
		G.require = H.harnessRequire
		G.debug = robloxDebug
		G.collectgarbage = robloxCollect
		G.gcinfo = function() return collectgarbage("count") end
		G.settings = function() return H.settingsObj end
		G.UserSettings = function() return H.userSettingsObj end
		G.version = function() return "0.742.0.7421053" end
		G.Version = G.version
		G.stats = function() return H.getService("Stats") end
		G.Stats = G.stats
		G.loadstring = nil -- (client scripts cannot use loadstring)
		G.SharedTable = nil
		G.ypcall = pcall
		return G
	end

	-------------------------------------------------------------------------------------- settings() / UserSettings()
	local function buildSettings()
		local gs = H.newInst("GlobalSettings")
		local function child(cls, name)
			local ci = H.getClass(cls)
			if not ci then return nil end
			local p, d = H.newInst(cls)
			d.name = name
			d.parent = gs
			table.insert(D[gs].children, p)
			return p
		end
		local rend = child("RenderSettings", "Rendering")
		if rend then D[rend].props.QualityLevel = H.enumItem("QualityLevel", "Automatic") end
		child("PhysicsSettings", "Physics")
		child("NetworkSettings", "Network")
		child("DebugSettings", "Diagnostics")
		child("LuaSettings", "Lua")
		H.hook("GlobalSettings").methods.GetService = function(_, name)
			for _, c in ipairs(D[gs].children) do if D[c].cls.name == name then return c end end
			H.err(format("'%s' is not a valid Service name", tostring(name)))
		end
		H.settingsObj = gs
		local us = H.newInst("UserSettings")
		local ugs = H.newInst("UserGameSettings")
		D[ugs].props.SavedQualityLevel = H.enumItem("SavedQualitySetting", H.CONFIG.quality == "low" and "QualityLevel2" or "Automatic")
		H.hook("UserSettings").methods.GetService = function(_, name)
			if name == "UserGameSettings" then return ugs end
			H.err(format("'%s' is not a valid Service name", tostring(name)))
		end
		H.userSettingsObj = us
	end

	-------------------------------------------------------------------------------------- RunService events
	local function fireRS(name, ...)
		local rs = H.SERVICES.RunService
		local d = rs and D[rs]
		local s = d and d.sig and d.sig[name]
		if s and H.signalHasListeners(s) then H.fireNow(s, ...) end
	end

	-------------------------------------------------------------------------------------- leak checks
	local function leakReport(gen)
		local leftovers, conns, threads, tweens = {}, {}, {}, {}
		for _, c in ipairs(H.CREATED) do
			if c.gen == gen then
				local d = D[c.p]
				if d and not d.destroyed and H.isDescendantOf(c.p, H.game) then
					leftovers[#leftovers + 1] = { path = H.fullName(c.p), class = d.cls.name, phase = c.phase }
				end
			end
		end
		local detached = {}
		for _, c in ipairs(H.CONNS) do
			local ctx = rawget(c, "_ctx")
			if ctx.gen == gen and rawget(c, "_on") then
				local sig = rawget(c, "_sig")
				local owner = rawget(sig, "_owner")
				local od = owner and D[owner]
				local entry = { signal = rawget(sig, "_name"), owner = od and H.fullName(owner) or "?", phase = ctx.phase }
				-- a connection on an object outside the DataModel (a finished Tween, a dropped Instance) is collected with it
				if od and not od.destroyed and owner ~= H.game and not H.isDescendantOf(owner, H.game) then
					detached[#detached + 1] = entry
				else
					conns[#conns + 1] = entry
				end
			end
		end
		for _, w in ipairs(H.waiting) do
			if w.ctx and w.ctx.gen == gen and coroutine.status(w.th) == "suspended" then
				threads[#threads + 1] = { dueIn = H.round(w.at - H.NOW, 2) }
			end
		end
		for _, t in ipairs(H.TWEENS) do
			local tw = D[t].tween
			if tw.ctx and tw.ctx.gen == gen then tweens[#tweens + 1] = H.fullName(tw.inst) end
		end
		local binds = {}
		for _, b in ipairs(H.RENDER_STEPS) do if b.ctx.gen == gen then binds[#binds + 1] = b.name end end
		return { gen = gen, leftoverInstances = leftovers, liveConnections = conns, detachedConnections = detached, pendingThreads = threads,
			playingTweens = tweens, renderStepBindings = binds }
	end
	local function moduleLevelConnections()
		local out = {}
		for _, c in ipairs(H.CONNS) do
			local ctx = rawget(c, "_ctx")
			if ctx.gen == 0 and rawget(c, "_on") then
				local sig = rawget(c, "_sig")
				local owner = rawget(sig, "_owner")
				out[#out + 1] = { signal = rawget(sig, "_name"), owner = owner and D[owner] and H.fullName(owner) or "?" }
			end
		end
		return out
	end

	local function timingStats(times)
		if #times == 0 then return nil end
		local s = table.clone(times)
		table.sort(s)
		local sum = 0
		for _, x in ipairs(s) do sum += x end
		local function pct(p) return s[math.max(1, math.min(#s, math.floor(#s * p + 0.5)))] * 1e6 end
		return { calls = #s, meanUs = sum / #s * 1e6, p50Us = pct(0.5), p95Us = pct(0.95), maxUs = s[#s] * 1e6 }
	end

	local function aggArray(kind, nFrames, nSteady)
		local out = {}
		for key, a in pairs(H.AGG[kind]) do
			out[#out + 1] = { key = key, cat = a.cat, avgPerFrame = nFrames > 0 and a.total / nFrames or 0, max = a.max,
				framesWritten = a.frames, steadyAvg = nSteady > 0 and a.sTotal / nSteady or 0, steadyMax = a.sMax,
				steadyFramesWritten = a.sFrames, total = a.total }
		end
		table.sort(out, function(a, b) return a.total > b.total end)
		return out
	end

	-------------------------------------------------------------------------------------- run one scenario
	function H.runScenario(name)
		local sc = H.SCENARIOS[name]
		if not sc then H.emit("fatal", { msg = "unknown scenario " .. tostring(name) }) return end
		local S = { name = name }
		for k, v in pairs(sc.cfg) do S[k] = v end
		H.CONFIG.quality = H.CONFIG.forceQuality or S.quality or "high"
		H.TIME_BASE = S.timeBase or 120
		math.randomseed(H.CONFIG.seed or 1)
		local seedState = H.CONFIG.seed or 1
		function H.nextSeed() seedState = (seedState * 16807) % 2147483647 return seedState end

		H.buildWorld({ clockTime = S.clock, film = S.film, touch = S.touch, moduleName = H.CONFIG.moduleName })
		buildSettings()
		H.localPlayer = H.makePlayer("Player1", 1001)
		sc.setup(S)
		H.flushDeferred()
		H.WANT_HISTORY = H.CONFIG.snapFrames ~= nil and next(H.CONFIG.snapFrames) ~= nil

		-- require the module (module-level code runs once, like the framework's first pcall(require, m))
		local def = H.requireAuraModule()
		if type(def) ~= "table" then
			if def ~= nil then H.recordError(format("the aura module must return a table (got %s)", H.typeof(def)), "", "load") end
		elseif type(def.build) ~= "function" then
			H.recordError("End.build is missing: the framework cannot build this aura", "", "load")
		else
			H.MODULE_DEF = def
			H.POSE = H.validatePose(def)
		end
		H.flushDeferred()

		local dt = H.DT
		local N = math.floor(S.duration / dt + 0.5)
		local equips = S.equipAt or {}
		local events = S.events or {}
		local census = {}
		local snapFrames = H.CONFIG.snapFrames or {}
		local censusAt = { [math.floor(1.5 / dt)] = "afterBuild", [math.floor(math.min(S.duration - 0.5, 10) / dt)] = "steady" }
		H.EMIT_FRAME = function() end

		local function frame(f, final)
			H.FRAME = f
			H.NOW = f * dt
			local t = H.NOW
			if not final then
				for _, e in ipairs(equips) do
					if not e.done and t >= e.t then e.done = true H.equip(e.rec) end
				end
				for _, e in ipairs(events) do
					if not e.done and t >= e.t then e.done = true e.fn() end
				end
				sc.step(S, t, dt)
				if H.CONFIG.camera then H.overrideCamera(S) end
			end
			H.stepScheduler()
			H.stepWaitForChild()
			fireRS("PreAnimation", dt)
			fireRS("Stepped", H.vtime(), dt)
			fireRS("PreSimulation", dt)
			fireRS("PostSimulation", dt)
			for _, b in ipairs(table.clone(H.RENDER_STEPS)) do
				local th = H.newThread(b.fn, "BindToRenderStep " .. b.name)
				H.threadInfo[th].ctx = b.ctx
				H.resume(th, dt)
			end
			fireRS("RenderStepped", dt)
			fireRS("PreRender", dt)
			H.frameRecs(dt)
			H.stepTweens()
			fireRS("Heartbeat", dt)
			H.flushDeferred()
			if f % 6 == 0 then H.sampleOcclusion() end
			if f % 30 == 0 and not final and H.isSteady() then H.sampleCuts() end
			H.sampleHistory()
			H.endFrameStats()
			if censusAt[f] and not final then census[censusAt[f]] = H.census() end
			if snapFrames[f] then H.snapshot(H.CONFIG.label or name) end
		end

		for f = 1, N do frame(f, false) end
		census.final = H.census()
		H.designLints()

		-- the end: unequip everything, let late callbacks run for 1.5 s, then look for leftovers
		local gens = {}
		for _, rec in ipairs(H.RECS) do
			if rec.fx then gens[#gens + 1] = rec.gen end
			H.unequip(rec)
		end
		for f = N + 1, N + 90 do frame(f, true) end
		H.flushDeferred()
		local leaks = {}
		local seenGen = {}
		for _, c in ipairs(H.CREATED) do
			if c.gen > 0 and not seenGen[c.gen] then seenGen[c.gen] = true leaks[#leaks + 1] = leakReport(c.gen) end
		end
		for _, g in ipairs(gens) do
			if not seenGen[g] then seenGen[g] = true leaks[#leaks + 1] = leakReport(g) end
		end

		-- unresolved WaitForChild calls never returned: in Studio that thread is stuck forever
		for _, w in ipairs(H.WFC) do
			if not w.done then
				H.recordError(format("Infinite yield: %s:WaitForChild(\"%s\") never returned (the child never appears in this scenario)",
					H.fullName(w.inst), w.name), w.tb, "WaitForChild")
			end
		end

		local nF, nS = H.frameCounts()
		local times, timesRemote = {}, {}
		for _, rec in ipairs(H.RECS) do
			for _, x in ipairs(rec.updateTimes) do
				if rec.isLocal then times[#times + 1] = x else timesRemote[#timesRemote + 1] = x end
			end
		end
		local unimpl = {}
		for k, n in pairs(H.unimplemented) do unimpl[#unimpl + 1] = { api = k, calls = n } end
		local warnings = {}
		for _, w in ipairs(H.WARNINGS) do
			warnings[#warnings + 1] = { code = w.code, msg = w.msg, count = w.count, frame = w.frame, t = w.t, tb = w.tb }
		end
		local errs = {}
		for _, e in ipairs(H.ERRORS) do
			errs[#errs + 1] = { msg = e.msg, tb = e.tb, where = e.where, frame = e.frame, t = e.t, count = e.count, lastFrame = e.lastFrame }
		end
		local assets = {}
		for id, a in pairs(H.ASSETS) do
			local props = {}
			for k in pairs(a.props) do props[#props + 1] = k end
			table.sort(props)
			assets[#assets + 1] = { id = id, count = a.count, props = props }
		end
		table.sort(assets, function(a, b) return a.id < b.id end)
		local series = {}
		for k, s in pairs(H.SER) do
			series[k] = H.obj({ avg = s.n > 0 and s.sum / s.n or 0, max = s.max, steadyAvg = s.sN > 0 and s.sSum / s.sN or 0, steadyMax = s.sMax })
		end
		local occ = { samples = H.OCC.samples, blocked = H.OCC.blocked, by = H.obj(H.OCC.by) }
		local cuts = { samples = H.CUTS.samples, hits = H.obj(H.CUTS.hits) }
		H.emit("summary", {
			scenario = H.CONFIG.label or name, desc = sc.desc, quality = H.CONFIG.quality, clock = S.clock, duration = S.duration,
			frames = nF, steadyFrames = nS, rig = S.rig or "R15",
			updateTiming = timingStats(times), updateTimingRemote = timingStats(timesRemote),
			buildMs = (H.BUILD_TIME or 0) * 1000,
			census = H.obj(census),
			writesUpdate = aggArray("update", nF, nS), writesCallback = aggArray("callback", nF, nS), writesTween = aggArray("tween", nF, nS),
			writesRedundant = aggArray("redundant", nF, nS),
			series = H.obj(series),
			occlusion = occ,
			billboardCuts = cuts,
			flicker = H.flickerReport(),
			leaks = leaks,
			moduleLevelConnections = moduleLevelConnections(),
			unimplemented = unimpl,
			warnings = warnings,
			errors = errs,
			assets = assets,
			prints = printed,
			wearers = #H.RECS,
		})
	end

	-------------------------------------------------------------------------------------- script mode (unit specs)
	-- runs a plain script (no End.build contract) in a default world for up to 10 virtual seconds
	function H.runScript(name)
		H.CONFIG.quality = "high"
		H.TIME_BASE = 120
		math.randomseed(H.CONFIG.seed or 1)
		local seedState = H.CONFIG.seed or 1
		function H.nextSeed() seedState = (seedState * 16807) % 2147483647 return seedState end
		H.buildWorld({ clockTime = 14, film = "present", moduleName = H.CONFIG.moduleName })
		buildSettings()
		H.localPlayer = H.makePlayer("Player1", 1001)
		local char, info = H.spawnCharacter(H.localPlayer, "R15", v3(0, 0, 0), 0)
		H.SCRIPT_CHAR = char
		H.flushDeferred()
		local out = H.runModule({ gen = 0, phase = "load", module = true }, H.MODULE_CHUNK)
		local dt = H.DT
		for f = 1, 600 do
			if out.done then break end
			H.FRAME = f
			H.NOW = f * dt
			H.stepScheduler()
			H.stepWaitForChild()
			H.stepTweens()
			H.flushDeferred()
		end
		if not out.done then
			H.recordError("script did not finish within 10 virtual seconds (still yielding)", "", "script")
		elseif not out.ok then
			H.reportThreadError(out.err, "script")
		end
		local errs, warnings = {}, {}
		for _, e in ipairs(H.ERRORS) do errs[#errs + 1] = { msg = e.msg, tb = e.tb, where = e.where, frame = e.frame, t = e.t, count = e.count } end
		for _, w in ipairs(H.WARNINGS) do warnings[#warnings + 1] = { code = w.code, msg = w.msg, count = w.count, tb = w.tb } end
		H.emit("summary", { scenario = name, desc = "script", frames = H.FRAME, steadyFrames = 0, errors = errs, warnings = warnings,
			leaks = {}, flicker = {}, unimplemented = {}, assets = {}, census = H.obj({}), series = H.obj({}) })
	end
end
