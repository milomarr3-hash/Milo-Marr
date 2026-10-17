-- classes_services: DataModel/GetService, Lighting, Players/Player, Humanoid/Animator/AnimationTrack, RunService,
-- TweenService/Tween (virtual-time interpolation), Debris, CollectionService, HttpService (JSON only; HTTP is OFF),
-- ContentProvider, UserInputService, GuiService and other small services.
do
	local format, err, typeof = string.format, H.err, H.typeof
	local D = H.INST_DATA
	local v3, c3, v2 = H.v3, H.c3, H.v2
	local Vector3 = H.Vector3
	local E = function(en, it) return H.enumItem(en, it) end
	local floor, sin, cos, pi, sqrt = math.floor, math.sin, math.cos, math.pi, math.sqrt

	-------------------------------------------------------------------------------------- DataModel / services
	local SP = H.hook("ServiceProvider")
	H.SERVICES = {}
	local function getService(dm, name)
		if type(name) ~= "string" then H.badArg(1, "GetService", "string", name) end
		local s = H.SERVICES[name]
		if s then return s end
		local ci = H.getClass(name)
		if not ci or not ci.service then err(format("'%s' is not a valid Service name", name)) end
		local p, d = H.newInst(name)
		d.name = name
		H.SERVICES[name] = p
		local prevReady = H.WORLD_READY
		H.WORLD_READY = false
		H.setParent(p, d, dm)
		H.WORLD_READY = prevReady
		if H.onServiceCreated then H.onServiceCreated(name, p) end
		return p
	end
	H.getService = function(name) return getService(H.game, name) end
	SP.methods.GetService = getService
	SP.methods.getService = getService
	SP.methods.service = getService
	SP.methods.FindService = function(dm, name) return H.SERVICES[name] end
	local DM = H.hook("DataModel")
	DM.methods.IsLoaded = function() return true end
	DM.methods.BindToClose = function() err("BindToClose can only be called on the server.") end
	DM.methods.GetObjects = function() err("GetObjects is not available to game scripts") end
	DM.get.PlaceId = function() return 132315219934780 end
	DM.get.GameId = function() return 1 end
	DM.get.JobId = function() return "00000000-0000-0000-0000-000000000000" end
	DM.get.CreatorId = function() return 1 end
	DM.get.PlaceVersion = function() return 1 end

	-------------------------------------------------------------------------------------- Lighting
	local LT = H.hook("Lighting")
	LT.defaults.ClockTime = 14
	LT.get.TimeOfDay = function(l, d)
		local ct = d.props.ClockTime or 14
		local h = floor(ct)
		local m = floor((ct - h) * 60)
		local s = floor(((ct - h) * 60 - m) * 60 + 0.5)
		return format("%02d:%02d:%02d", h, m, s)
	end
	LT.set.TimeOfDay = function(l, d, v)
		local h, m, s = v:match("^(%d+):?(%d*):?(%d*)$")
		if not h then err(format("Unable to assign property TimeOfDay. Invalid time string \"%s\"", v)) end
		d.props.ClockTime = (tonumber(h) + (tonumber(m) or 0) / 60 + (tonumber(s) or 0) / 3600) % 24
	end
	LT.set.ClockTime = function(l, d, v) d.props.ClockTime = v % 24 end
	LT.methods.GetMinutesAfterMidnight = function(l) return (D[l].props.ClockTime or 14) * 60 end
	LT.methods.SetMinutesAfterMidnight = function(l, m) D[l].props.ClockTime = (m / 60) % 24 end
	local function sunDir(ct)
		local a = (ct - 6) / 24 * 2 * pi -- 6h = sunrise in the east (+X), 12h overhead-ish, 18h west
		local tilt = math.rad(41.7)
		local x, y = cos(a), sin(a)
		return v3(x, y * cos(tilt), y * sin(tilt)).Unit
	end
	LT.methods.GetSunDirection = function(l) return sunDir(D[l].props.ClockTime or 14) end
	LT.methods.GetMoonDirection = function(l) return -sunDir(D[l].props.ClockTime or 14) end
	LT.methods.GetMoonPhase = function() return 0.5 end

	-------------------------------------------------------------------------------------- Players / Player
	local PL = H.hook("Players")
	PL.get.LocalPlayer = function() return H.localPlayer end
	PL.methods.GetPlayers = function()
		local out = {}
		for _, c in ipairs(D[H.getService("Players")].children) do if D[c].cls.name == "Player" then out[#out + 1] = c end end
		return out
	end
	PL.methods.GetPlayerFromCharacter = function(_, char)
		for _, p in ipairs(PL.methods.GetPlayers()) do if D[p].props.Character == char then return p end end
		return nil
	end
	PL.methods.GetPlayerByUserId = function(_, id)
		for _, p in ipairs(PL.methods.GetPlayers()) do if D[p].props.UserId == id then return p end end
		return nil
	end
	PL.methods.GetUserThumbnailAsync = function(_, id) return "rbxthumb://type=AvatarHeadShot&id=" .. tostring(id) .. "&w=150&h=150", true end
	PL.methods.GetNameFromUserIdAsync = function(_, id) return "Player" .. tostring(id) end
	PL.methods.GetUserIdFromNameAsync = function() return 1 end
	PL.methods.GetFriendsAsync = function() err("harness: GetFriendsAsync is not supported") end
	local PLR = H.hook("Player")
	PLR.methods.GetMouse = function(p)
		local d = D[p]
		if not d.mouse then d.mouse = (H.newInst("PlayerMouse")) end
		return d.mouse
	end
	PLR.methods.Kick = function() err("harness: Player:Kick was called") end
	PLR.methods.LoadCharacter = function() err("LoadCharacter can only be called by the backend server") end
	PLR.methods.HasAppearanceLoaded = function() return true end
	PLR.methods.DistanceFromCharacter = function(p, point)
		local ch = D[p].props.Character
		local hrp = ch and H.rawFind(ch, "HumanoidRootPart")
		if not hrp then return 0 end
		return (H.rawGet(hrp, "Position") - point).Magnitude
	end
	PLR.methods.GetNetworkPing = function() return 0.05 end
	PLR.methods.GetRankInGroup = function() return 0 end
	PLR.methods.GetRoleInGroup = function() return "Guest" end
	PLR.methods.IsInGroup = function() return false end
	PLR.methods.IsFriendsWith = function() return false end
	PLR.methods.IsVerified = function() return false end
	PLR.methods.GetJoinData = function() return {} end
	PLR.defaults.CameraMaxZoomDistance = 400
	PLR.defaults.CameraMinZoomDistance = 0.5
	PLR.defaults.AccountAge = 400
	function H.rawFind(p, name)
		for _, c in ipairs(D[p].children) do if D[c].name == name then return c end end
		return nil
	end

	-------------------------------------------------------------------------------------- Humanoid / Animator
	local HM = H.hook("Humanoid")
	HM.get.RootPart = function(h, d)
		local ch = d.parent
		return ch and H.rawFind(ch, "HumanoidRootPart") or nil
	end
	HM.defaults.MoveDirection = Vector3.zero
	HM.defaults.FloorMaterial = E("Material", "Plastic")
	HM.methods.GetState = function(h) return D[h].state or E("HumanoidStateType", "Running") end
	HM.methods.ChangeState = function(h, st) D[h].state = H.coerceEnum("HumanoidStateType", st) end
	HM.methods.GetStateEnabled = function() return true end
	HM.methods.SetStateEnabled = function() end
	HM.methods.MoveTo = function() end
	HM.methods.Move = function() end
	HM.methods.TakeDamage = function(h, n) local d = D[h] d.props.Health = math.max(0, (d.props.Health or 100) - n) end
	HM.methods.UnequipTools = function() end
	HM.methods.EquipTool = function() end
	HM.methods.GetAccessories = function(h)
		local ch = D[h].parent
		local out = {}
		if ch then for _, c in ipairs(D[ch].children) do if D[c].cls.isa.Accessory then out[#out + 1] = c end end end
		return out
	end
	HM.methods.GetPlayingAnimationTracks = function() return {} end
	HM.methods.ApplyDescription = function() err("harness: Humanoid:ApplyDescription is not supported") end
	HM.methods.GetAppliedDescription = function() return (H.newInst("HumanoidDescription")) end
	HM.methods.GetBodyPartR15 = function(h, part)
		local n = D[part].name
		local map = { Head = "Head", UpperTorso = "UpperTorso", LowerTorso = "LowerTorso", LeftFoot = "LeftFoot", LeftLowerLeg = "LeftLowerLeg",
			LeftUpperLeg = "LeftUpperLeg", RightFoot = "RightFoot", RightLowerLeg = "RightLowerLeg", RightUpperLeg = "RightUpperLeg",
			LeftHand = "LeftHand", LeftLowerArm = "LeftLowerArm", LeftUpperArm = "LeftUpperArm", RightHand = "RightHand",
			RightLowerArm = "RightLowerArm", RightUpperArm = "RightUpperArm", HumanoidRootPart = "RootPart" }
		return E("BodyPartR15", map[n] or "Unknown")
	end
	HM.methods.GetLimb = function() return E("Limb", "Unknown") end
	HM.methods.GetMoveVelocity = function(h) return (D[h].props.MoveDirection or Vector3.zero) * (D[h].props.WalkSpeed or 16) end
	local function animTrack(anim)
		local t, td = H.newInst("AnimationTrack")
		td.props.Animation = anim
		td.playing = false
		return t
	end
	local LA = function(_, anim)
		if not (anim and D[anim] and D[anim].cls.isa.Animation) then H.badArg(1, "LoadAnimation", "Animation", anim) end
		return animTrack(anim)
	end
	HM.methods.LoadAnimation = LA
	H.hook("Animator").methods.LoadAnimation = LA
	H.hook("Animator").methods.GetPlayingAnimationTracks = function() return {} end
	H.hook("Animator").methods.StepAnimations = function() end
	local AT = H.hook("AnimationTrack")
	AT.methods.Play = function(t) D[t].playing = true end
	AT.methods.Stop = function(t) D[t].playing = false end
	AT.methods.AdjustSpeed = function(t, s) D[t].props.Speed = s end
	AT.methods.AdjustWeight = function() end
	AT.methods.GetMarkerReachedSignal = function(t, name) return H.getSignal(t, D[t], "Marker:" .. tostring(name)) end
	AT.methods.GetTimeOfKeyframe = function() return 0 end
	AT.get.IsPlaying = function(t, d) return d.playing == true end
	AT.get.Length = function() return 1 end

	-------------------------------------------------------------------------------------- RunService
	local RS = H.hook("RunService")
	RS.methods.IsClient = function() return true end
	RS.methods.IsServer = function() return false end
	RS.methods.IsStudio = function() return true end
	RS.methods.IsRunning = function() return true end
	RS.methods.IsRunMode = function() return false end
	RS.methods.IsEdit = function() return false end
	H.RENDER_STEPS = {}
	RS.methods.BindToRenderStep = function(rs, name, priority, fn)
		if type(name) ~= "string" then H.badArg(1, "BindToRenderStep", "string", name) end
		if type(fn) ~= "function" then H.badArg(3, "BindToRenderStep", "function", fn) end
		table.insert(H.RENDER_STEPS, { name = name, priority = priority, fn = fn, ctx = H.CTX })
		table.sort(H.RENDER_STEPS, function(a, b) return a.priority < b.priority end)
	end
	RS.methods.UnbindFromRenderStep = function(rs, name)
		for i = #H.RENDER_STEPS, 1, -1 do if H.RENDER_STEPS[i].name == name then table.remove(H.RENDER_STEPS, i) end end
	end
	RS.methods.Pause = function() end
	RS.methods.Run = function() end
	RS.methods.Stop = function() end

	-------------------------------------------------------------------------------------- TweenService / Tween
	local function easeIn(style, t)
		if style == "Linear" then return t
		elseif style == "Sine" then return 1 - cos(t * pi / 2)
		elseif style == "Quad" then return t * t
		elseif style == "Cubic" then return t * t * t
		elseif style == "Quart" then return t ^ 4
		elseif style == "Quint" then return t ^ 5
		elseif style == "Exponential" then return t == 0 and 0 or 2 ^ (10 * t - 10)
		elseif style == "Circular" then return 1 - sqrt(1 - t * t)
		elseif style == "Back" then local c1 = 1.70158 return (c1 + 1) * t ^ 3 - c1 * t * t
		elseif style == "Elastic" then
			if t == 0 or t == 1 then return t end
			return -(2 ^ (10 * t - 10)) * sin((t * 10 - 10.75) * (2 * pi / 3))
		elseif style == "Bounce" then
			local u = 1 - t
			local n1, d1 = 7.5625, 2.75
			local o
			if u < 1 / d1 then o = n1 * u * u
			elseif u < 2 / d1 then u -= 1.5 / d1 o = n1 * u * u + 0.75
			elseif u < 2.5 / d1 then u -= 2.25 / d1 o = n1 * u * u + 0.9375
			else u -= 2.625 / d1 o = n1 * u * u + 0.984375 end
			return 1 - o
		end
		return t
	end
	local function ease(style, dir, t)
		if dir == "In" then return easeIn(style, t) end
		if dir == "Out" then return 1 - easeIn(style, 1 - t) end
		if t < 0.5 then return easeIn(style, t * 2) / 2 end
		return 1 - easeIn(style, (1 - t) * 2) / 2
	end
	H.ease = ease
	local TWEENABLE = { number = true, int = true, boolean = true, CFrame = true, Rect = true, Color3 = true, UDim = true, UDim2 = true,
		Vector2 = true, Vector2int16 = true, Vector3 = true }
	local function lerpValue(a, b, t)
		local ta = typeof(a)
		if ta == "number" then return a + (b - a) * t end
		if ta == "boolean" or ta == "EnumItem" then if t >= 1 then return b end return a end
		if ta == "UDim" then return H.udim(a.Scale + (b.Scale - a.Scale) * t, a.Offset + (b.Offset - a.Offset) * t) end
		if ta == "Rect" then return H.Rect.new(a.Min:Lerp(b.Min, t), a.Max:Lerp(b.Max, t)) end
		return a:Lerp(b, t)
	end
	H.TWEENS = {}
	local TS = H.hook("TweenService")
	TS.methods.Create = function(ts, inst, info, goals)
		local idata = D[inst]
		if not idata then H.badArg(1, "Create", "Instance", inst) end
		if typeof(info) ~= "TweenInfo" then H.badArg(2, "Create", "TweenInfo", info) end
		if type(goals) ~= "table" or D[goals] then H.badArg(3, "Create", "table", goals) end
		local list = {}
		for k, v in pairs(goals) do
			local m = idata.cls.members[k]
			if not m or m.kind ~= "p" then
				err(format("TweenService:Create no property named '%s' for object '%s'", tostring(k), idata.name))
			end
			local ty = m.ty or "any"
			local isEnum = ty:sub(1, 2) == "E:"
			if not (TWEENABLE[ty] or isEnum) then
				err(format("TweenService:Create property named '%s' on object '%s' is not a data type that can be tweened", k, idata.name))
			end
			local ok, cv = m.check(v)
			if not ok then
				err(format("TweenService:Create property named '%s' cannot be tweened due to type mismatch (property is a '%s', but given type is '%s')",
					k, isEnum and "EnumItem" or ty, typeof(v)))
			end
			if m.ro or m.wr then err(format("TweenService:Create property named '%s' on object '%s' is read only", k, idata.name)) end
			list[#list + 1] = { k = k, m = m, goal = cv }
		end
		local tw, td = H.newInst("Tween")
		H.trackCreated(tw, td)
		td.props.Instance = inst
		td.props.TweenInfo = info
		td.props.PlaybackState = E("PlaybackState", "Begin")
		td.tween = { inst = inst, info = info, goals = list, state = "Begin", ctx = H.CTX }
		return tw
	end
	TS.methods.GetValue = function(ts, alpha, style, dir)
		local s, d2 = H.coerceEnum("EasingStyle", style), H.coerceEnum("EasingDirection", dir)
		if not s then H.badArg(2, "GetValue", "Enum.EasingStyle", style) end
		if not d2 then H.badArg(3, "GetValue", "Enum.EasingDirection", dir) end
		return ease(s.Name, d2.Name, math.clamp(alpha, 0, 1))
	end
	TS.methods.SmoothDamp = function(ts, cur, target, vel, smooth)
		return cur + (target - cur) * 0.1, vel
	end
	local TB = H.hook("TweenBase")
	TB.get.PlaybackState = function(t, d) return d.props.PlaybackState or E("PlaybackState", "Begin") end
	local function finish(t, td, stateName)
		local tw = td.tween
		tw.state = stateName
		td.props.PlaybackState = E("PlaybackState", stateName)
		local i = table.find(H.TWEENS, t)
		if i then table.remove(H.TWEENS, i) end
		local idata = D[tw.inst]
		if idata and idata.tweening then
			for _, g in ipairs(tw.goals) do if idata.tweening[g.k] == t then idata.tweening[g.k] = nil end end
		end
		local s = td.sig and td.sig.Completed
		if s then H.fire(s, E("PlaybackState", stateName)) end
	end
	TB.methods.Play = function(t)
		local td = D[t]
		local tw = td.tween
		if not tw then return end
		if tw.state == "Playing" then return end
		local idata = D[tw.inst]
		if tw.state ~= "Paused" then
			tw.t0 = H.NOW
			tw.starts = {}
			tw.rep = 0
			tw.reversing = false
		else
			tw.t0 = H.NOW - (tw.pausedAt or 0)
		end
		-- a newer tween on the same property cancels the older one (Roblox behaviour)
		idata.tweening = idata.tweening or {}
		for _, g in ipairs(tw.goals) do
			local other = idata.tweening[g.k]
			if other and other ~= t and D[other].tween.state == "Playing" then finish(other, D[other], "Cancelled") end
			idata.tweening[g.k] = t
			if tw.starts[g.k] == nil then tw.starts[g.k] = H.rawGet(tw.inst, g.k) end
		end
		tw.state = "Playing"
		td.props.PlaybackState = E("PlaybackState", "Playing")
		if not table.find(H.TWEENS, t) then table.insert(H.TWEENS, t) end
	end
	TB.methods.Pause = function(t)
		local td = D[t]
		local tw = td.tween
		if tw and tw.state == "Playing" then
			tw.state = "Paused"
			tw.pausedAt = H.NOW - tw.t0
			td.props.PlaybackState = E("PlaybackState", "Paused")
			local i = table.find(H.TWEENS, t)
			if i then table.remove(H.TWEENS, i) end
		end
	end
	TB.methods.Cancel = function(t)
		local td = D[t]
		local tw = td.tween
		if tw and (tw.state == "Playing" or tw.state == "Paused") then
			finish(t, td, "Cancelled")
		end
	end
	-- advance every playing tween (called once per frame, after the aura's update)
	function H.stepTweens()
		if #H.TWEENS == 0 then return end
		local prevWT = H.WT
		H.WT = H.FW.tween
		for _, t in ipairs(table.clone(H.TWEENS)) do
			local td = D[t]
			local tw = td.tween
			local idata = D[tw.inst]
			if not idata or idata.destroyed then
				finish(t, td, "Cancelled")
			else
				local info = tw.info
				local el = H.NOW - tw.t0 - info.DelayTime
				if el >= 0 then
					local dur = math.max(info.Time, 1e-6)
					local cycle = el / dur
					local done = false
					local a = cycle
					local total = info.RepeatCount < 0 and math.huge or (info.RepeatCount + 1) * (info.Reverses and 2 or 1)
					if cycle >= total then
						done = true
						a = info.Reverses and 0 or 1
					else
						local k = floor(cycle)
						a = cycle - k
						if info.Reverses and k % 2 == 1 then a = 1 - a end
					end
					local e = ease(info.EasingStyle.Name, info.EasingDirection.Name, math.clamp(a, 0, 1))
					for _, g in ipairs(tw.goals) do
						local v = lerpValue(tw.starts[g.k], g.goal, e)
						H.setProp(tw.inst, idata, g.m, g.k, v)
					end
					if done then finish(t, td, "Completed") end
				end
			end
		end
		H.WT = prevWT
	end

	-------------------------------------------------------------------------------------- Debris
	H.hook("Debris").methods.AddItem = function(_, inst, life)
		if not D[inst] then H.badArg(1, "AddItem", "Instance", inst) end
		local th = coroutine.create(function() H.destroy(inst) end)
		H.threadInfo[th] = { ctx = { gen = 0, phase = "engine", module = false } }
		H.schedule(th, H.NOW + (life or 10), nil)
	end
	H.hook("Debris").methods.addItem = H.hook("Debris").methods.AddItem

	-------------------------------------------------------------------------------------- CollectionService
	local CS = H.hook("CollectionService")
	H.TAGGED = {}
	H.onTagAdded = function(p, tag)
		H.TAGGED[tag] = H.TAGGED[tag] or setmetatable({}, { __mode = "k" })
		H.TAGGED[tag][p] = true
		local cs = H.SERVICES.CollectionService
		local s = cs and D[cs].tagAdded and D[cs].tagAdded[tag]
		if s then H.fire(s, p) end
	end
	H.onTagRemoved = function(p, tag)
		if H.TAGGED[tag] then H.TAGGED[tag][p] = nil end
		local cs = H.SERVICES.CollectionService
		local s = cs and D[cs].tagRemoved and D[cs].tagRemoved[tag]
		if s then H.fire(s, p) end
	end
	CS.methods.AddTag = function(_, inst, tag) H.hook("Instance").methods.AddTag(inst, tag) end
	CS.methods.RemoveTag = function(_, inst, tag) H.hook("Instance").methods.RemoveTag(inst, tag) end
	CS.methods.HasTag = function(_, inst, tag) return H.hook("Instance").methods.HasTag(inst, tag) end
	CS.methods.GetTags = function(_, inst) return H.hook("Instance").methods.GetTags(inst) end
	CS.methods.GetTagged = function(_, tag)
		local out = {}
		for p in pairs(H.TAGGED[tag] or {}) do if not D[p].destroyed then out[#out + 1] = p end end
		return out
	end
	CS.methods.GetAllTags = function()
		local out = {}
		for t in pairs(H.TAGGED) do out[#out + 1] = t end
		return out
	end
	CS.methods.GetInstanceAddedSignal = function(cs, tag)
		local d = D[cs]
		d.tagAdded = d.tagAdded or {}
		d.tagAdded[tag] = d.tagAdded[tag] or H.newSignal("InstanceAdded:" .. tag, cs)
		return d.tagAdded[tag]
	end
	CS.methods.GetInstanceRemovedSignal = function(cs, tag)
		local d = D[cs]
		d.tagRemoved = d.tagRemoved or {}
		d.tagRemoved[tag] = d.tagRemoved[tag] or H.newSignal("InstanceRemoved:" .. tag, cs)
		return d.tagRemoved[tag]
	end

	-------------------------------------------------------------------------------------- HttpService (JSON only)
	local HS = H.hook("HttpService")
	HS.defaults.HttpEnabled = false
	local function httpOff()
		H.recordError("HttpService request attempted: HTTP requests are OFF in Milo's place and must stay off", debug.traceback(), "http")
		err("Http requests are not enabled. Enable via game settings")
	end
	HS.methods.GetAsync, HS.methods.PostAsync, HS.methods.RequestAsync = httpOff, httpOff, httpOff
	HS.methods.JSONEncode = function(_, v)
		local function check(x, depth)
			if depth > 100 then err("Can't convert to JSON (too deep)") end
			local t = typeof(x)
			if t == "table" then for k, val in pairs(x) do check(val, depth + 1) end
			elseif t ~= "number" and t ~= "string" and t ~= "boolean" and t ~= "nil" then err("Can't convert to JSON") end
		end
		check(v, 0)
		return H.json(v)
	end
	local function jsonDecode(s)
		local i = 1
		local function ws() i = s:find("[^ \t\r\n]", i) or (#s + 1) end
		local parse
		local function str()
			local out = {}
			i += 1
			while true do
				local c = s:sub(i, i)
				if c == "" then err("Can't parse JSON") end
				if c == '"' then i += 1 break end
				if c == "\\" then
					local n = s:sub(i + 1, i + 1)
					local map = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
					if n == "u" then out[#out + 1] = utf8.char(tonumber(s:sub(i + 2, i + 5), 16)) i += 6
					else out[#out + 1] = map[n] or n i += 2 end
				else
					out[#out + 1] = c
					i += 1
				end
			end
			return table.concat(out)
		end
		function parse()
			ws()
			local c = s:sub(i, i)
			if c == "{" then
				local t = {}
				i += 1
				ws()
				if s:sub(i, i) == "}" then i += 1 return t end
				while true do
					ws()
					local k = str()
					ws()
					i += 1 -- :
					t[k] = parse()
					ws()
					local d = s:sub(i, i)
					i += 1
					if d == "}" then return t end
				end
			elseif c == "[" then
				local t = {}
				i += 1
				ws()
				if s:sub(i, i) == "]" then i += 1 return t end
				while true do
					t[#t + 1] = parse()
					ws()
					local d = s:sub(i, i)
					i += 1
					if d == "]" then return t end
				end
			elseif c == '"' then return str()
			elseif s:sub(i, i + 3) == "true" then i += 4 return true
			elseif s:sub(i, i + 4) == "false" then i += 5 return false
			elseif s:sub(i, i + 3) == "null" then i += 4 return nil
			else
				local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
				if not num or num == "" then err("Can't parse JSON") end
				i += #num
				return tonumber(num)
			end
		end
		return parse()
	end
	HS.methods.JSONDecode = function(_, s)
		if type(s) ~= "string" then H.badArg(1, "JSONDecode", "string", s) end
		return jsonDecode(s)
	end
	HS.methods.GenerateGUID = function(_, wrap)
		local r = H.Random.new(H.nextSeed())
		local hex = "0123456789ABCDEF"
		local function h(n) local o = {} for k = 1, n do local x = r:NextInteger(1, 16) o[k] = hex:sub(x, x) end return table.concat(o) end
		local g = format("%s-%s-4%s-%s-%s", h(8), h(4), h(3), h(4), h(12))
		if wrap == false then return g end
		return "{" .. g .. "}"
	end
	HS.methods.UrlEncode = function(_, s) return (tostring(s):gsub("[^%w%-_%.~]", function(c) return format("%%%02X", c:byte()) end)) end

	-------------------------------------------------------------------------------------- misc services
	H.hook("ContentProvider").methods.PreloadAsync = function(_, list, cb)
		if type(list) ~= "table" then H.badArg(1, "PreloadAsync", "table", list) end
		local th, isMain = coroutine.running()
		if not isMain and coroutine.isyieldable() then
			H.schedule(th, H.NOW + H.DT, nil)
			coroutine.yield()
		end
		if cb then
			for _, x in ipairs(list) do
				local id = type(x) == "string" and x or (D[x] and "rbxassetid://0") or tostring(x)
				cb(id, E("AssetFetchStatus", "Success"))
			end
		end
	end
	H.hook("ContentProvider").get.RequestQueueSize = function() return 0 end
	local UIS = H.hook("UserInputService")
	UIS.methods.GetLastInputType = function() return E("UserInputType", "MouseMovement") end
	UIS.methods.GetMouseLocation = function() return v2(960, 456) end
	UIS.methods.IsKeyDown = function() return false end
	UIS.methods.IsMouseButtonPressed = function() return false end
	UIS.methods.GetKeysPressed = function() return {} end
	UIS.methods.GetConnectedGamepads = function() return {} end
	UIS.methods.GetPlatform = function() return E("Platform", "OSX") end
	UIS.methods.GetFocusedTextBox = function() return nil end
	H.hook("GuiService").methods.GetGuiInset = function() return v2(0, 58), v2(0, 0) end
	H.hook("GuiService").methods.IsTenFootInterface = function() return false end
	H.hook("StarterGui").methods.SetCore = function() end
	H.hook("StarterGui").methods.GetCore = function() return nil end
	H.hook("StarterGui").methods.SetCoreGuiEnabled = function() end
	H.hook("StarterGui").methods.GetCoreGuiEnabled = function() return true end
	H.hook("TextService").methods.GetTextSize = function(_, text, size) return v2(#tostring(text) * size * 0.5, size) end
	H.hook("MarketplaceService").methods.UserOwnsGamePassAsync = function() return false end
	H.hook("MarketplaceService").methods.PlayerOwnsAsset = function() return false end
	H.hook("SoundService").methods.PlayLocalSound = function() end
	H.hook("Sound").methods.Play = function() end
	H.hook("Sound").methods.Stop = function() end
	H.hook("Sound").methods.Pause = function() end
	H.hook("Sound").methods.Resume = function() end

	-------------------------------------------------------------------------------------- effects
	H.hook("ParticleEmitter").methods.Emit = function(pe, n)
		n = n == nil and 16 or H.numArg(n, 1, "Emit")
		local sf = H.STATS_FRAME
		sf.emitted = (sf.emitted or 0) + n
		local d = D[pe]
		d.bursts = d.bursts or {}
		table.insert(d.bursts, { t = H.NOW, n = n })
	end
	H.hook("ParticleEmitter").methods.Clear = function() end
	H.hook("ParticleEmitter").methods.FastForward = function() end
	H.hook("Beam").methods.SetTextureOffset = function() end
	H.hook("Trail").methods.Clear = function() end
	H.hook("Fire").defaults.Enabled = true
	H.hook("Sparkles").defaults.Enabled = true
	H.hook("Smoke").defaults.Enabled = true

	-------------------------------------------------------------------------------------- scripts
	local LS = H.hook("LuaSourceContainer")
	LS.methods.GetHash = function() return "harness" end
end
