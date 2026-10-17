-- scheduler: virtual time, the task library (spawn/defer/delay/wait/cancel), deprecated wait/delay/spawn,
-- RBXScriptSignal / RBXScriptConnection with connection tracking, and the deferred event queue.
do
	local format, err, typeof = string.format, H.err, H.typeof
	local co_create, co_resume, co_status, co_running, co_yield, co_close =
		coroutine.create, coroutine.resume, coroutine.status, coroutine.running, coroutine.yield, coroutine.close

	H.NOW = 0 -- virtual seconds since the scenario started
	H.FRAME = 0
	H.DT = 1 / 60
	H.TIME_BASE = 120 -- time() when the scenario starts (the player has been in the game a while)
	H.CLOCK_BASE = 5000 -- os.clock() at the start (client uptime)
	H.EPOCH_BASE = 1792000000 -- tick()/os.time()/server clock at the start
	function H.epochNow() return H.EPOCH_BASE + H.NOW end
	function H.vclock() return H.CLOCK_BASE + H.NOW end
	function H.vtime() return H.TIME_BASE + H.NOW end

	-- context: which build generation / phase the running code belongs to (for leak attribution)
	H.CTX = { gen = 0, phase = "harness", module = false }
	local function withCtx(ctx, fn, ...)
		local prev = H.CTX
		H.CTX = ctx
		local r = table.pack(fn(...))
		H.CTX = prev
		return table.unpack(r, 1, r.n)
	end
	H.withCtx = withCtx

	-- error capture: every module-originated thread runs inside xpcall with this handler
	function H.errHandler(e)
		return { msg = tostring(e), tb = debug.traceback(nil, 2) }
	end
	local function reportThreadError(e, where)
		if type(e) == "table" and e.msg then
			H.recordError(e.msg, e.tb, where)
		else
			H.recordError(tostring(e), debug.traceback(), where)
		end
	end
	H.reportThreadError = reportThreadError

	local threadInfo = setmetatable({}, { __mode = "k" }) -- thread -> { ctx }
	H.threadInfo = threadInfo

	local function wrap(fn, where)
		return function(...)
			local ok, e = xpcall(fn, H.errHandler, ...)
			if not ok then reportThreadError(e, where) end
		end
	end

	-- resume a thread under its own context
	-- depth of engine -> script calls in progress; deferred work runs only when it is back to 0 (control returned to
	-- the engine), never in the middle of module code (e.g. when a task.spawn'ed thread finishes)
	H.DEPTH = 0
	local flush -- (H.flushDeferred, set below)
	local function resume(th, ...)
		if co_status(th) ~= "suspended" then return end
		H.DEPTH += 1
		local info = threadInfo[th]
		local prev, prevWT, prevR = H.CTX, H.WT, H.WT_REDUNDANT
		if info then
			H.CTX = info.ctx
			-- writes made by the module's own threads (task.*, event handlers) count as "callback" writes
			if info.ctx.module and H.FW then
				H.WT = info.ctx.phase == "load" and H.LOAD_WRITES or H.FW.callback
				H.WT_REDUNDANT = nil
			elseif not info.ctx.module then
				H.WT, H.WT_REDUNDANT = nil, nil
			end
		end
		local ok, e = co_resume(th, ...)
		H.CTX, H.WT, H.WT_REDUNDANT = prev, prevWT, prevR
		H.DEPTH -= 1
		if not ok then reportThreadError(e, "thread") end
		-- a resumption point: deferred events and task.defer threads run as soon as the running thread yields or ends
		if H.DEPTH == 0 then flush() end
	end
	H.resume = resume

	local function newThread(fn, where)
		local th = co_create(wrap(fn, where))
		threadInfo[th] = { ctx = H.CTX }
		return th
	end
	H.newThread = newThread

	-- waiting threads (task.wait / task.delay / wait / delay): { th, at, args, seq }
	local waiting = {}
	local seq = 0
	H.waiting = waiting
	local function schedule(th, at, args)
		seq += 1
		waiting[#waiting + 1] = { th = th, at = at, args = args, seq = seq, ctx = H.CTX }
	end
	H.schedule = schedule

	-- deferred queue (task.defer, deferred signal handlers)
	local deferred = {}
	local function defer(th, args)
		deferred[#deferred + 1] = { th = th, args = args }
	end
	H.deferThread = defer
	local flushing = false
	function H.flushDeferred()
		if H.DEPTH > 0 or flushing then return end
		flushing = true
		local guard = 0
		while #deferred > 0 do
			guard += 1
			if guard > 80 then
				H.recordWarning("deferred", "More than 80 nested task.defer/deferred-event re-entries in one frame (Roblox stops at 80: 'Maximum event re-entrancy depth exceeded')")
				table.clear(deferred)
				break
			end
			local batch = table.clone(deferred)
			table.clear(deferred)
			for _, d in ipairs(batch) do
				if d.args then resume(d.th, table.unpack(d.args, 1, d.args.n)) else resume(d.th) end
			end
		end
		flushing = false
	end

	flush = H.flushDeferred

	-- called once per frame by the main loop: resume due threads in order
	function H.stepScheduler()
		local now = H.NOW
		local due = {}
		local keep = {}
		for _, w in ipairs(waiting) do
			if w.at <= now + 1e-9 then due[#due + 1] = w else keep[#keep + 1] = w end
		end
		if #due == 0 then return end
		table.clear(waiting)
		for i, w in ipairs(keep) do waiting[i] = w end
		table.sort(due, function(a, b) if a.at ~= b.at then return a.at < b.at end return a.seq < b.seq end)
		for _, w in ipairs(due) do
			if w.args then resume(w.th, table.unpack(w.args, 1, w.args.n)) else resume(w.th) end
		end
		H.flushDeferred()
	end
	function H.pendingThreads(gen)
		local n = 0
		for _, w in ipairs(waiting) do
			if (gen == nil or (w.ctx and w.ctx.gen == gen)) and co_status(w.th) == "suspended" then n += 1 end
		end
		return n
	end

	local function needYield(fname)
		local th, isMain = co_running()
		if isMain or not coroutine.isyieldable() then
			err(format("attempt to yield across metamethod/C-call boundary (%s)", fname))
		end
		return th
	end

	local task = {}
	function task.spawn(f, ...)
		local th
		if type(f) == "function" then
			th = newThread(f, "task.spawn")
		elseif type(f) == "thread" then
			th = f
		else
			H.badArg(1, "spawn", "function or thread", f)
		end
		resume(th, ...)
		return th
	end
	function task.defer(f, ...)
		local th
		if type(f) == "function" then th = newThread(f, "task.defer")
		elseif type(f) == "thread" then th = f
		else H.badArg(1, "defer", "function or thread", f) end
		defer(th, table.pack(...))
		return th
	end
	function task.delay(t, f, ...)
		t = H.numArg(t, 1, "delay")
		local th
		if type(f) == "function" then th = newThread(f, "task.delay")
		elseif type(f) == "thread" then th = f
		else H.badArg(2, "delay", "function or thread", f) end
		schedule(th, H.NOW + math.max(t, 0), table.pack(...))
		return th
	end
	function task.wait(t)
		t = H.numArg(t, 1, "wait", 0)
		local th = needYield("task.wait")
		local start = H.NOW
		schedule(th, H.NOW + math.max(t, H.DT * 0.5), nil)
		co_yield()
		return H.NOW - start
	end
	function task.cancel(th)
		if type(th) ~= "thread" then H.badArg(1, "cancel", "thread", th) end
		for i = #waiting, 1, -1 do if waiting[i].th == th then table.remove(waiting, i) end end
		for i = #deferred, 1, -1 do if deferred[i].th == th then table.remove(deferred, i) end end
		if co_status(th) == "suspended" then co_close(th) end
	end
	function task.synchronize() end
	function task.desynchronize() end
	H.task = table.freeze(task)

	-- deprecated globals (still present in Roblox)
	function H.wait(t)
		t = H.numArg(t, 1, "wait", 0.03)
		local th = needYield("wait")
		local start = H.NOW
		schedule(th, H.NOW + math.max(t, 0.03), nil)
		co_yield()
		return H.NOW - start, H.vclock()
	end
	function H.delay(t, f)
		t = H.numArg(t, 1, "delay", 0.03)
		local th = newThread(function() f(H.NOW, H.vclock()) end, "delay")
		schedule(th, H.NOW + math.max(t, 0.03), nil)
	end
	function H.spawn(f)
		local th = newThread(function() f(H.NOW, H.vclock()) end, "spawn")
		schedule(th, H.NOW + 0.03, nil)
	end

	--------------------------------------------------------------------------------------------- signals
	local SIGM, SIGMethods = {}, {}
	local CONM, CONMethods = {}, {}
	H.TYPEOF[SIGM] = "RBXScriptSignal"
	H.TYPEOF[CONM] = "RBXScriptConnection"
	SIGM.__index = function(s, k)
		local m = SIGMethods[k]
		if m then return m end
		err(format("%s is not a valid member of RBXScriptSignal", tostring(k)))
		return nil
	end
	SIGM.__newindex = function(_, k) err(format("%s cannot be assigned to", tostring(k))) end
	SIGM.__tostring = function(s) return "Signal " .. rawget(s, "_name") end
	CONM.__index = function(c, k)
		if k == "Connected" then return rawget(c, "_on") end
		local m = CONMethods[k]
		if m then return m end
		err(format("%s is not a valid member of RBXScriptConnection", tostring(k)))
		return nil
	end
	CONM.__newindex = function(_, k) err(format("%s cannot be assigned to", tostring(k))) end
	CONM.__tostring = function() return "Connection" end

	H.CONNS = {} -- every connection the module made: for leak checks
	local function newSignal(name, owner, onConnect)
		return setmetatable({ _name = name, _owner = owner, _conns = {}, _waiters = {}, _onConnect = onConnect }, SIGM)
	end
	H.newSignal = newSignal

	local function connect(s, fn, once)
		if type(fn) ~= "function" then err("Attempt to connect failed: Passed value is not a function") end
		local c = setmetatable({ _sig = s, _fn = fn, _on = true, _once = once, _ctx = H.CTX, _frame = H.FRAME, _t = H.NOW }, CONM)
		local list = rawget(s, "_conns")
		list[#list + 1] = c
		if H.CTX.module then H.CONNS[#H.CONNS + 1] = c end
		local oc = rawget(s, "_onConnect")
		if oc then oc(s) end
		return c
	end
	H.connectInternal = function(s, fn) -- harness-side connections are never counted as the module's
		local prev = H.CTX
		H.CTX = { gen = 0, phase = "harness", module = false }
		local c = connect(s, fn, false)
		H.CTX = prev
		return c
	end
	function SIGMethods.Connect(s, fn)
		if getmetatable(s) ~= SIGM then err("Expected ':' not '.' calling member function Connect") end
		return connect(s, fn, false)
	end
	SIGMethods.connect = SIGMethods.Connect
	SIGMethods.ConnectParallel = SIGMethods.Connect
	function SIGMethods.Once(s, fn)
		if getmetatable(s) ~= SIGM then err("Expected ':' not '.' calling member function Once") end
		return connect(s, fn, true)
	end
	function SIGMethods.Wait(s)
		local th = needYield("Wait")
		local w = rawget(s, "_waiters")
		w[#w + 1] = th
		return co_yield()
	end
	SIGMethods.wait = SIGMethods.Wait
	local function disconnect(c)
		if not rawget(c, "_on") then return end
		rawset(c, "_on", false)
		local list = rawget(rawget(c, "_sig"), "_conns")
		local i = table.find(list, c)
		if i then table.remove(list, i) end
	end
	H.disconnect = disconnect
	function CONMethods.Disconnect(c) disconnect(c) end
	CONMethods.disconnect = CONMethods.Disconnect

	function H.signalHasListeners(s)
		return #rawget(s, "_conns") > 0 or #rawget(s, "_waiters") > 0
	end
	function H.disconnectAll(s)
		for _, c in ipairs(table.clone(rawget(s, "_conns"))) do disconnect(c) end
		table.clear(rawget(s, "_waiters"))
	end
	-- fire now: each handler runs in its own thread (like Roblox), errors are captured
	local function fireNow(s, ...)
		local list = rawget(s, "_conns")
		if #list > 0 then
			for _, c in ipairs(table.clone(list)) do
				if rawget(c, "_on") then
					if rawget(c, "_once") then disconnect(c) end
					local prev = H.CTX
					H.CTX = rawget(c, "_ctx")
					local th = newThread(rawget(c, "_fn"), "event " .. rawget(s, "_name"))
					H.CTX = prev
					resume(th, ...)
				end
			end
		end
		local w = rawget(s, "_waiters")
		if #w > 0 then
			local ws = table.clone(w)
			table.clear(w)
			for _, th in ipairs(ws) do resume(th, ...) end
		end
	end
	H.fireNow = fireNow
	-- deferred (Roblox's default SignalBehavior): handlers run at the next resumption point
	function H.fire(s, ...)
		if #rawget(s, "_conns") == 0 and #rawget(s, "_waiters") == 0 then return end
		local args = table.pack(...)
		local th = co_create(function() fireNow(s, table.unpack(args, 1, args.n)) end)
		threadInfo[th] = { ctx = { gen = 0, phase = "engine", module = false } }
		defer(th, nil)
	end
end
