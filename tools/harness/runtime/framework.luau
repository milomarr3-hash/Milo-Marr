-- framework: mimics the client aura framework (ReplicatedStorage.AuraFX) as documented in the project memory:
-- requires the aura module once, validates End.pose, builds per wearer (ctx = { char, hrp, hum, quality, isLocal,
-- container }), calls fx.update(dt, s) every frame (s = { cf, hover, glide, t, now, legLen, ground, alpha }),
-- setDetail(false) past 110 studs, setVisible(false) past 320 studs or while the camera is Scriptable, destroy on unequip.
-- It also applies End.pose to the mock rig (Motor6D.Transform) so snapshots show the floating pose.
do
	local format, err = string.format, H.err
	local D = H.INST_DATA
	local v3, cf = H.v3, H.cf
	local CFrame, Vector3 = H.CFrame, H.Vector3
	local exp, sin, rad, min = math.exp, math.sin, math.rad, math.min
	local realClock = H.realClock

	H.RECS = {}
	local nextGen = 0
	H.MODULE_DEF = nil

	-------------------------------------------------------------------------------------- module loading (require)
	local loaded = false
	local result = nil
	-- run module code in a fresh thread under ctx; returns ok, values (or yields -> scheduler finishes it)
	local function runModule(ctx, fn, ...)
		local out = { done = false }
		local args = table.pack(...)
		local th = coroutine.create(function()
			local r = table.pack(xpcall(fn, H.errHandler, table.unpack(args, 1, args.n)))
			out.done = true
			out.ok = r[1]
			if r[1] then out.values = { table.unpack(r, 2, r.n) } else out.err = r[2] end
		end)
		H.threadInfo[th] = { ctx = ctx }
		local prev = H.CTX
		H.CTX = ctx
		H.DEPTH += 1
		local ok, e = coroutine.resume(th)
		H.DEPTH -= 1
		H.CTX = prev
		if not ok then out.done, out.ok, out.err = true, false, { msg = tostring(e), tb = debug.traceback(th) } end
		out.th = th
		H.flushDeferred()
		return out
	end
	H.runModule = runModule

	function H.requireAuraModule()
		if loaded then return result end
		loaded = true
		local ctx = { gen = 0, phase = "load", module = true }
		local prevWT = H.WT
		H.WT = H.LOAD_WRITES
		local out = runModule(ctx, H.MODULE_CHUNK)
		H.WT = prevWT
		if not out.done then
			H.recordError("the aura module yielded while being required (require must return immediately; Roblox errors 'Requested module experienced an error while loading' if it never returns)", "", "load")
			return nil
		end
		if not out.ok then
			H.reportThreadError(out.err, "load")
			H.recordError("Requested module experienced an error while loading", "", "load")
			return nil
		end
		local n = #out.values
		if n ~= 1 then
			H.recordError(format("Module code did not return exactly one value (returned %d)", n), "", "load")
			return nil
		end
		result = out.values[1]
		return result
	end

	function H.harnessRequire(target)
		if target == H.moduleScript then return H.requireAuraModule() end
		if target == H.frameworkModule then
			-- the real framework is not available here: hand back a stub and report the gap (not an aura error)
			H.unimplemented["require(ReplicatedStorage.AuraFX)"] = (H.unimplemented["require(ReplicatedStorage.AuraFX)"] or 0) + 1
			return setmetatable({}, { __index = function(_, k)
				local key = "AuraFX." .. tostring(k)
				H.unimplemented[key] = (H.unimplemented[key] or 0) + 1
				return nil
			end })
		end
		if type(target) == "number" then err("require(assetId) cannot be used from a client script") end
		if D[target] and D[target].cls.name == "ModuleScript" and H.EXTRA_MODULES and H.EXTRA_MODULES[D[target].name] then
			return H.EXTRA_MODULES[D[target].name]()
		end
		err("Attempted to call require with invalid argument(s).")
		return nil
	end

	-------------------------------------------------------------------------------------- End.pose validation
	local R15_JOINTS = { Root = true, Waist = true, Neck = true, LeftShoulder = true, LeftElbow = true, LeftWrist = true,
		RightShoulder = true, RightElbow = true, RightWrist = true, LeftHip = true, LeftKnee = true, LeftAnkle = true,
		RightHip = true, RightKnee = true, RightAnkle = true }
	H.R6_MAP = { Root = "RootJoint", Neck = "Neck", LeftShoulder = "Left Shoulder", RightShoulder = "Right Shoulder",
		LeftHip = "Left Hip", RightHip = "Right Hip" }
	local DEFAULT_POSE = { hover = 0, bob = 0, bobSpeed = 1, idle = {}, glide = {}, breathe = {}, suppress = {} }
	function H.validatePose(def)
		local pose = def.pose
		if pose == nil then
			H.recordWarning("pose", "End.pose is missing: the framework falls back to no hover and no pose")
			return DEFAULT_POSE
		end
		if type(pose) ~= "table" then
			H.recordError(format("End.pose must be a table (got %s)", H.typeof(pose)), "", "pose")
			return DEFAULT_POSE
		end
		local out = { idle = {}, glide = {}, breathe = {}, suppress = {} }
		for _, k in ipairs({ "hover", "bob", "bobSpeed" }) do
			local v = pose[k]
			if v == nil then
				H.recordWarning("pose", format("End.pose.%s is missing (framework default used)", k))
				out[k] = DEFAULT_POSE[k]
			elseif type(v) ~= "number" or v ~= v then
				H.recordError(format("End.pose.%s must be a number (got %s)", k, H.typeof(v)), "", "pose")
				out[k] = DEFAULT_POSE[k]
			else
				out[k] = v
			end
		end
		if out.hover > 8 or out.hover < -1 then H.recordWarning("pose", format("End.pose.hover = %s studs looks wrong (pass 4 used 2.4)", H.fmtn(out.hover))) end
		for _, set in ipairs({ "idle", "glide", "breathe" }) do
			local t = pose[set]
			if t ~= nil then
				if type(t) ~= "table" then
					H.recordError(format("End.pose.%s must be a table of joint = { x, y, z } degrees", set), "", "pose")
				else
					for jn, ang in pairs(t) do
						if not R15_JOINTS[jn] then
							H.recordWarning("pose", format("End.pose.%s.%s is not an R15 Motor6D name (typo? the framework will ignore it)", set, tostring(jn)))
						elseif type(ang) ~= "table" or type(ang[1]) ~= "number" or type(ang[2]) ~= "number" or type(ang[3]) ~= "number" then
							H.recordError(format("End.pose.%s.%s must be { x, y, z } (three numbers, degrees)", set, jn), "", "pose")
						else
							if math.abs(ang[1]) > 180 or math.abs(ang[2]) > 180 or math.abs(ang[3]) > 180 then
								H.recordWarning("pose", format("End.pose.%s.%s has an angle beyond 180 degrees (radians by mistake?)", set, jn))
							end
							out[set][jn] = ang
						end
					end
				end
			end
		end
		local sup = pose.suppress
		if sup ~= nil then
			if type(sup) ~= "table" then
				H.recordError("End.pose.suppress must be a table of joint = 0..1", "", "pose")
			else
				for jn, v in pairs(sup) do
					if not R15_JOINTS[jn] then
						H.recordWarning("pose", format("End.pose.suppress.%s is not an R15 Motor6D name", tostring(jn)))
					elseif type(v) ~= "number" or v < 0 or v > 1 then
						H.recordError(format("End.pose.suppress.%s must be a number from 0 to 1", jn), "", "pose")
					else
						out.suppress[jn] = v
					end
				end
			end
		end
		return out
	end

	-------------------------------------------------------------------------------------- wearers
	function H.newRec(player, char, info, isLocal)
		local rec = { player = player, char = char, info = info, hrp = info.hrp, hum = info.hum, isLocal = isLocal, fx = nil,
			alpha = 0, g = 0, hover = 0, near = true, visible = true, updateTimes = {}, equipped = false }
		table.insert(H.RECS, rec)
		H.WEARER_CHARS = H.WEARER_CHARS or {}
		H.WEARER_CHARS[char] = true
		return rec
	end

	local function legLen(rec)
		local hrpSize = H.rawGet(rec.hrp, "Size")
		if rec.info.r15 then return H.rawGet(rec.hum, "HipHeight") + hrpSize.Y / 2 end
		local leg = H.rawFind(rec.char, "Left Leg")
		return hrpSize.Y / 2 + (leg and H.rawGet(leg, "Size").Y or 2)
	end

	local function validateFx(fx)
		if type(fx) ~= "table" then
			H.recordError(format("End.build(ctx) must return the fx table (got %s)", H.typeof(fx)), "", "build")
			return false
		end
		local ok = true
		for _, k in ipairs({ "update", "setVisible", "setDetail", "destroy" }) do
			if type(fx[k]) ~= "function" then
				H.recordError(format("fx.%s is missing (the framework calls it)", k), "", "build")
				ok = false
			end
		end
		return ok
	end

	function H.equip(rec)
		local def = H.MODULE_DEF
		if not def then return end
		nextGen += 1
		rec.gen = nextGen
		rec.ctxBuild = { gen = nextGen, phase = "build", module = true }
		rec.ctxUpdate = { gen = nextGen, phase = "update", module = true }
		rec.ctxCall = { gen = nextGen, phase = "call", module = true }
		rec.alpha, rec.g, rec.hover, rec.near, rec.visible = 0, 0, 0, true, true
		rec.builtAt = H.NOW
		rec.equipped = true
		local ctx = { char = rec.char, hrp = rec.hrp, hum = rec.hum, quality = H.CONFIG.quality or "high", isLocal = rec.isLocal,
			container = H.container }
		local prevWT = H.WT
		H.WT = H.BUILD_WRITES
		local t0 = realClock()
		local out = runModule(rec.ctxBuild, def.build, ctx)
		H.BUILD_TIME = (H.BUILD_TIME or 0) + (realClock() - t0)
		H.WT = prevWT
		H.flushDeferred()
		if not out.done then
			H.recordWarning("build-yield", "End.build yielded (task.wait/WaitForChild inside build): the framework's pcall blocks until it returns, and nothing is drawn meanwhile")
			rec.pendingBuild = out
			return
		end
		if not out.ok then
			H.reportThreadError(out.err, "build")
			rec.fx = nil
			return
		end
		if validateFx(out.values[1]) then rec.fx = out.values[1] end
		H.emit("event", { what = "build", gen = nextGen, t = H.NOW, frame = H.FRAME, ok = rec.fx ~= nil })
	end

	local function call(rec, name, ...)
		if not rec.fx then return end
		local fn = rec.fx[name]
		if type(fn) ~= "function" then return end
		rec.ctxCall.phase = name
		local prevWT = H.WT
		H.WT = H.FW.callback
		local out = runModule(rec.ctxCall, fn, ...)
		H.WT = prevWT
		if out.done and not out.ok then H.reportThreadError(out.err, name) end
		if not out.done then H.recordWarning("call-yield", format("fx.%s yielded", name)) end
	end
	H.callFx = call

	function H.unequip(rec)
		if rec.pendingBuild and rec.pendingBuild.done then rec.pendingBuild = nil end
		if rec.fx then
			call(rec, "destroy")
			H.emit("event", { what = "destroy", gen = rec.gen, t = H.NOW, frame = H.FRAME })
		end
		rec.destroyedGen = rec.gen
		rec.destroyedAt = H.NOW
		rec.fx = nil
		rec.equipped = false
		H.flushDeferred()
	end

	function H.setVisibleRec(rec, on)
		if rec.visible == on then return end
		rec.visible = on
		call(rec, "setVisible", on)
		H.LAST_TOGGLE_T = H.NOW
	end
	function H.setDetailRec(rec, near)
		if rec.near == near then return end
		rec.near = near
		call(rec, "setDetail", near)
		H.LAST_TOGGLE_T = H.NOW
	end

	-------------------------------------------------------------------------------------- pose on the rig
	local function poseRig(rec, pose, t)
		local g = rec.g
		local joints = rec.info.joints
		local r15 = rec.info.r15
		for jn in pairs(R15_JOINTS) do
			local name = r15 and jn or H.R6_MAP[jn]
			local m = name and joints[name]
			if m then
				local a = pose.idle[jn]
				local b = pose.glide[jn]
				local br = pose.breathe[jn]
				local x, y, z = 0, 0, 0
				if a then x, y, z = a[1], a[2], a[3] end
				if b then x, y, z = x + (b[1] - x) * g, y + (b[2] - y) * g, z + (b[3] - z) * g end
				if br then
					local w = sin(t * 1.3)
					x, y, z = x + br[1] * w, y + br[2] * w, z + br[3] * w
				end
				local tr = CFrame.Angles(rad(x), rad(y), rad(z))
				if jn == "Root" then tr = CFrame.new(0, rec.hover, 0) * tr end
				D[m].props.Transform = tr
			end
		end
		H.propagate(rec.hrp)
	end

	-------------------------------------------------------------------------------------- per frame
	local groundParams
	function H.frameRecs(dt)
		local pose = H.POSE or DEFAULT_POSE
		local t = H.vclock()
		local cam = H.camera
		local camCF = H.rawGet(cam, "CFrame")
		local scriptable = H.rawGet(cam, "CameraType").Name == "Scriptable"
		-- a screen grade (ColorCorrectionEffect under the camera) that stays on while a scripted camera (the roll cutscene)
		-- holds the screen dims the cutscene: allowed only while it eases out in the first 0.6 s
		if scriptable then
			H.SCRIPTABLE_SINCE = H.SCRIPTABLE_SINCE or t
			if t - H.SCRIPTABLE_SINCE > 0.6 then
				for _, ch in ipairs(D[cam].children) do
					if D[ch] and not D[ch].destroyed and D[ch].cls.isa.ColorCorrectionEffect then
						H.recordWarning("grade-over-cutscene", "a ColorCorrectionEffect (" .. D[ch].name .. ") stays under the camera while a "
							.. "Scriptable camera (e.g. the roll cutscene) holds the screen: it dims the cutscene")
					end
				end
			end
		else
			H.SCRIPTABLE_SINCE = nil
		end
		for _, rec in ipairs(H.RECS) do
			if rec.pendingBuild and rec.pendingBuild.done then
				local out = rec.pendingBuild
				rec.pendingBuild = nil
				if out.ok then if validateFx(out.values[1]) then rec.fx = out.values[1] end else H.reportThreadError(out.err, "build") end
			end
			if rec.equipped and not D[rec.char].destroyed then
				local hrpCF = H.rawGet(rec.hrp, "CFrame")
				local md = H.rawGet(rec.hum, "MoveDirection")
				local moving = md.Magnitude > 0.1
				rec.g += ((moving and 1 or 0) - rec.g) * (1 - exp(-dt * 3))
				rec.hoverBase = (rec.hoverBase or 0) + (pose.hover - (rec.hoverBase or 0)) * (1 - exp(-dt * 4))
				rec.hover = rec.hoverBase + pose.bob * sin(t * pose.bobSpeed)
				rec.alpha = min(1, rec.alpha + dt / 0.9)
				poseRig(rec, pose, t)
				-- ground under the wearer (the framework's ray ignores the character and the auras)
				groundParams = groundParams or H.RaycastParams.new()
				groundParams.FilterDescendantsInstances = { rec.char, H.container }
				local prevCtx = H.CTX
				H.CTX = { gen = 0, phase = "harness", module = false }
				local hit = H.hook("Workspace").methods.Raycast(H.workspace, hrpCF.Position, v3(0, -60, 0), groundParams)
				H.CTX = prevCtx
				H.STATS_FRAME.raycastHits = nil
				rec.ground = hit and hit.Position or nil
				-- distance culling and the Scriptable-camera pause
				local dist = (camCF.Position - hrpCF.Position).Magnitude
				local visible = dist < 320 and not scriptable
				local near = dist < 110
				if rec.fx then
					if visible ~= rec.visible then H.setVisibleRec(rec, visible) end
					if near ~= rec.near then H.setDetailRec(rec, near) end
				end
				-- (H.UPDATE_WHILE_HIDDEN: a framework that keeps calling update while the aura is hidden; the real one is not in
				-- this repo, so both behaviours are tested: see the equip_in_cutscene scenarios)
				if rec.fx and (rec.visible or H.UPDATE_WHILE_HIDDEN) then
					local s = { cf = hrpCF, hover = rec.hover, glide = rec.g, t = t, now = H.epochNow(), legLen = legLen(rec),
						ground = rec.ground, alpha = rec.alpha }
					rec.lastS = s
					local prevWT, prevR = H.WT, H.WT_REDUNDANT
					H.WT, H.WT_REDUNDANT = H.FW.update, H.FWR
					local t0 = realClock()
					local out = runModule(rec.ctxUpdate, rec.fx.update, dt, s)
					local el = realClock() - t0
					H.WT, H.WT_REDUNDANT = prevWT, prevR
					rec.updateTimes[#rec.updateTimes + 1] = el
					H.UPDATED_THIS_FRAME = true
					if not out.done then
						H.recordWarning("update-yield", "fx.update yielded (task.wait inside update?): the next frame's update starts before this one finishes")
					elseif not out.ok then
						H.reportThreadError(out.err, "update")
					end
				end
			end
		end
	end
end
