-- instance: the Instance model. Classes, members, enums and defaults come from the generated API table;
-- behaviour that needs more than "store the value" lives in class hooks (classes.luau).
do
	local format, err, typeof, find = string.format, H.err, H.typeof, table.find
	local nativeType = H.nativeType
	local API_CLASSES = H.API.classes

	local D = setmetatable({}, { __mode = "k" }) -- proxy -> data
	H.INST_DATA = D

	-------------------------------------------------------------------------------------- hooks registry
	local HOOKS = {}
	H.HOOKS = HOOKS
	function H.hook(className)
		local h = HOOKS[className]
		if not h then
			h = { get = {}, set = {}, methods = {}, defaults = {}, init = nil, lint = {} }
			HOOKS[className] = h
		end
		return h
	end

	-------------------------------------------------------------------------------------- value checkers
	-- each returns (ok, value) or (false, message)
	local CHECK = {}
	CHECK.number = function(v)
		local t = nativeType(v)
		if t == "number" then return true, v end
		if t == "string" then local n = tonumber(v) if n then return true, n end end
		return false, "number expected, got " .. typeof(v)
	end
	CHECK.int = function(v)
		local ok, n = CHECK.number(v)
		if not ok then return false, n end
		if n >= 0 then return true, math.floor(n) end
		return true, math.ceil(n)
	end
	CHECK.string = function(v)
		local t = nativeType(v)
		if t == "string" then return true, v end
		if t == "number" then return true, tostring(v) end
		return false, "string expected, got " .. typeof(v)
	end
	CHECK.Content = CHECK.string
	CHECK.ContentObj = function(v)
		if H.isContent(v) then return true, v end
		if nativeType(v) == "string" then return true, H.contentFromString(v) end
		return false, "Content expected, got " .. typeof(v)
	end
	CHECK.boolean = function(v)
		if nativeType(v) == "boolean" then return true, v end
		return false, "bool expected, got " .. typeof(v)
	end
	CHECK.any = function(v) return true, v end
	local function dataChecker(ty)
		return function(v)
			if typeof(v) == ty then return true, v end
			return false, ty .. " expected, got " .. typeof(v)
		end
	end
	local function enumChecker(en)
		return function(v)
			local it = H.coerceEnum(en, v)
			if it then return true, it end
			if H.isEnumItem(v) then
				return false, format("EnumItem of type %s cannot be assigned to a property of type Enum.%s", tostring(v.EnumType), en)
			end
			local t = nativeType(v)
			if t == "string" then return false, format("Invalid value \"%s\" for enum %s", v, en) end
			if t == "number" then return false, format("Invalid value %s for enum %s", tostring(v), en) end
			return false, format("EnumItem, number or string expected, got %s", typeof(v))
		end
	end
	local function refChecker(cls)
		return function(v)
			if v == nil then return true, nil end
			local d = D[v]
			if not d then return false, cls .. " expected, got " .. typeof(v) end
			if d.cls.isa[cls] then return true, v end
			return false, cls .. " expected, got " .. d.cls.name
		end
	end
	local checkerCache = {}
	local function getChecker(ty)
		local c = checkerCache[ty]
		if c then return c end
		if CHECK[ty] then c = CHECK[ty]
		elseif ty:sub(1, 2) == "E:" then c = enumChecker(ty:sub(3))
		elseif ty:sub(1, 2) == "I:" then c = refChecker(ty:sub(3))
		elseif ty == "" then c = CHECK.any
		else c = dataChecker(ty) end
		checkerCache[ty] = c
		return c
	end
	H.getChecker = getChecker

	-------------------------------------------------------------------------------------- classes
	local classCache = {}
	local unimplemented = {}
	H.unimplemented = unimplemented
	local function stub(className, mname)
		return function(self, ...)
			if not D[self] then err(format("Expected ':' not '.' calling member function %s", mname)) end
			local key = className .. ":" .. mname
			unimplemented[key] = (unimplemented[key] or 0) + 1
			return nil
		end
	end
	local function hasFlag(fl, c) return fl:find(c, 1, true) ~= nil end
	-- props whose rapid back-and-forth changes would read as flicker
	local FLICKER = { Transparency = true, ImageTransparency = true, Brightness = true, LightEmission = true, Enabled = true,
		BackgroundTransparency = true, TextTransparency = true, FillTransparency = true, OutlineTransparency = true, Visible = true,
		Range = true }

	local function getClass(name)
		local ci = classCache[name]
		if ci ~= nil then return ci end
		local src = API_CLASSES[name]
		if not src then classCache[name] = false return false end
		local lines = string.split(src, "\n")
		local super, flags = lines[1]:match("^(.-)|(.*)$")
		local parent = super ~= "" and getClass(super) or nil
		ci = { name = name, creatable = hasFlag(flags, "c"), service = hasFlag(flags, "s"), members = {}, isa = { [name] = true },
			parent = parent, inits = {} }
		local members = ci.members
		if parent then
			for k in pairs(parent.isa) do ci.isa[k] = true end
			for k, pd in pairs(parent.members) do
				local d = table.clone(pd)
				d.key = name .. "." .. k
				d.owner = ci
				members[k] = d
			end
			for _, f in ipairs(parent.inits) do ci.inits[#ci.inits + 1] = f end
		end
		for i = 2, #lines do
			local kind, mname, ty, fl, def = lines[i]:match("^(%a)|([^|]*)|([^|]*)|([^|]*)|(.*)$")
			if kind then
				members[mname] = { kind = kind, name = mname, ty = ty, ro = hasFlag(fl, "r"), wr = hasFlag(fl, "R"),
					x = hasFlag(fl, "x"), dep = hasFlag(fl, "d"), yields = hasFlag(fl, "y"), defStr = def, key = name .. "." .. mname,
					owner = ci, declared = name, flick = FLICKER[mname] == true }
			end
		end
		-- this class's hooks (inherited hooks were copied with the parent's members)
		local h = HOOKS[name]
		if h then
			for k, fn in pairs(h.get) do
				local d = members[k]
				if d then d.get = fn else members[k] = { kind = "p", name = k, ty = "any", get = fn, key = name .. "." .. k, owner = ci, declared = name, defStr = "", synthetic = true } end
			end
			for k, fn in pairs(h.set) do
				local d = members[k]
				if d then d.set = fn end
			end
			for k, fn in pairs(h.methods) do
				local d = members[k]
				if d then d.fn = fn else members[k] = { kind = "f", name = k, fn = fn, key = name .. ":" .. k, owner = ci, declared = name } end
			end
			for k, v in pairs(h.defaults) do
				local d = members[k]
				if d then d.defVal = v; d.hasDef = true end
			end
			for k, fn in pairs(h.lint) do
				local d = members[k]
				if d then d.lint = fn end
			end
			if h.init then ci.inits[#ci.inits + 1] = h.init end
		end
		local typeLints = H.TYPE_LINTS or {}
		for k, d in pairs(members) do
			if d.kind == "p" then
				d.check = getChecker(d.ty or "")
				if not d.lint then d.lint = typeLints[d.ty or ""] end
			elseif d.kind == "f" and not d.fn then
				d.fn = stub(name, k)
			end
		end
		classCache[name] = ci
		return ci
	end
	H.getClass = getClass

	local function defaultOf(d)
		if d.hasDef then return d.defVal end
		local v = H.parseDefault(d.ty or "", d.defStr)
		d.defVal, d.hasDef = v, true
		return v
	end
	H.defaultOf = defaultOf

	-------------------------------------------------------------------------------------- naming
	local function fullName(p)
		local parts = {}
		local cur = p
		while cur do
			local d = D[cur]
			if d.cls.name == "DataModel" then break end
			table.insert(parts, 1, d.name)
			cur = d.parent
		end
		return table.concat(parts, ".")
	end
	H.fullName = fullName

	-------------------------------------------------------------------------------------- signals on instances
	local function getSignal(p, d, name)
		local s = d.sig
		if not s then s = {} d.sig = s end
		local sig = s[name]
		if not sig then
			sig = H.newSignal(name, p)
			s[name] = sig
		end
		return sig
	end
	H.getSignal = getSignal
	local function fireIf(d, name, ...)
		local s = d.sig and d.sig[name]
		if s then H.fire(s, ...) end
	end
	H.fireIf = fireIf
	local function propChanged(p, d, prop)
		if d.sig then
			local c = d.sig.Changed
			if c then H.fire(c, prop) end
		end
		local ps = d.psig and d.psig[prop]
		if ps then H.fire(ps) end
	end
	H.propChanged = propChanged

	-------------------------------------------------------------------------------------- proxies
	local INST_MT = {}
	local nextId = 0
	H.CREATED = {} -- instances created by the module: { p, gen, phase, frame }

	local instIndex, instNewindex
	local function newInst(className)
		local ci = getClass(className)
		if not ci then err(format("harness: unknown class %s", tostring(className))) end
		local p = setmetatable({}, INST_MT)
		nextId += 1
		local d = { cls = ci, props = {}, children = {}, parent = nil, name = className, id = nextId, destroyed = false, locked = false }
		D[p] = d
		for _, f in ipairs(ci.inits) do f(p, d) end
		return p, d
	end
	H.newInst = newInst

	local function trackCreated(p, d)
		local ctx = H.CTX
		if ctx.module then
			H.CREATED[#H.CREATED + 1] = { p = p, gen = ctx.gen, phase = ctx.phase, frame = H.FRAME }
			d.created = ctx
			if ctx.phase == "update" or ctx.phase == "callback" then
				H.STATS_FRAME.newInstances = (H.STATS_FRAME.newInstances or 0) + 1
			end
		end
	end
	H.trackCreated = trackCreated

	instIndex = function(p, k)
		local d = D[p]
		local m = d.cls.members[k]
		if m then
			local kind = m.kind
			if kind == "p" then
				if m.x then err(format("The current thread cannot access '%s' (lacking capability)", k)) end
				local g = m.get
				if g then return g(p, d, m) end
				local v = d.props[k]
				if v == nil then return defaultOf(m) end
				return v
			elseif kind == "f" then
				if m.x then err(format("The current thread cannot access '%s' (lacking capability)", k)) end
				return m.fn
			elseif kind == "e" then
				return getSignal(p, d, k)
			end
		end
		if type(k) == "string" then
			for _, c in ipairs(d.children) do
				if D[c].name == k then return c end
			end
		end
		err(format("%s is not a valid member of %s \"%s\"", tostring(k), d.cls.name, fullName(p)))
		return nil
	end

	-- the write path (used by module writes, tweens and internal setters alike)
	local function setProp(p, d, m, k, v)
		local ok, cv = m.check(v)
		if not ok then err(format("Unable to assign property %s. %s", k, cv)) end
		if m.lint then cv = m.lint(p, d, cv, m) end
		local wt = H.WT
		if wt then
			wt[m] = (wt[m] or 0) + 1
			local rw = H.WT_REDUNDANT
			if rw then
				local old = d.props[k]
				if old == nil and not m.set then old = defaultOf(m) end
				if old == cv and not m.set then rw[m] = (rw[m] or 0) + 1 end
			end
			if m.flick then H.observeFlicker(p, d, k, cv) end
		end
		local s = m.set
		if s then
			s(p, d, cv, m)
		else
			d.props[k] = cv
		end
		if d.sig or d.psig then propChanged(p, d, k) end
	end
	H.setProp = setProp

	instNewindex = function(p, k, v)
		local d = D[p]
		local m = d.cls.members[k]
		if not m then
			err(format("%s is not a valid member of %s \"%s\"", tostring(k), d.cls.name, fullName(p)))
		end
		if m.kind ~= "p" then err(format("Unable to assign property %s. Property is read only", k)) end
		if m.x then err(format("The current thread cannot access '%s' (lacking capability)", k)) end
		if m.ro then err(format("Unable to assign property %s. Property is read only", k)) end
		if m.wr then err(format("Unable to assign property %s. Script write access is restricted", k)) end
		setProp(p, d, m, k, v)
	end

	INST_MT.__index = instIndex
	INST_MT.__newindex = instNewindex
	INST_MT.__tostring = function(p) return D[p].name end
	INST_MT.__metatable = "The metatable is locked"
	INST_MT.__iter = function() err("attempt to iterate over an Instance value") end
	INST_MT.__len = function() err("attempt to get length of an Instance value") end
	INST_MT.__call = function() err("attempt to call an Instance value") end
	INST_MT.__concat = function(a, b) err(format("attempt to concatenate %s with %s", typeof(a), typeof(b))) end

	-- internal property access that skips validation and counting (harness-owned writes)
	function H.rawSet(p, k, v)
		local d = D[p]
		local m = d.cls.members[k]
		if m and m.set then m.set(p, d, v, m) else d.props[k] = v end
		if d.sig or d.psig then propChanged(p, d, k) end
	end
	function H.rawGet(p, k)
		local d = D[p]
		local m = d.cls.members[k]
		if m and m.get then return m.get(p, d, m) end
		local v = d.props[k]
		if v == nil and m then return defaultOf(m) end
		return v
	end

	-------------------------------------------------------------------------------------- hierarchy
	local function isDescendantOf(p, anc)
		local cur = D[p].parent
		while cur do
			if cur == anc then return true end
			cur = D[cur].parent
		end
		return false
	end
	H.isDescendantOf = isDescendantOf
	local function forDescendants(p, fn)
		for _, c in ipairs(D[p].children) do
			fn(c)
			forDescendants(c, fn)
		end
	end
	H.forDescendants = forDescendants

	H.WFC = {} -- pending WaitForChild calls
	local function childArrived(parent, pd, child, name)
		local ws = pd.wfc
		if not ws then return end
		local list = ws[name]
		if not list then return end
		ws[name] = nil
		for _, w in ipairs(list) do
			if not w.done then
				w.done = true
				H.deferThread(w.th, table.pack(child)) -- (resumed at the next resumption point, like Roblox)
			end
		end
	end
	H.childArrived = childArrived

	local function setParent(p, d, v)
		if v ~= nil and not D[v] then err(format("Unable to assign property Parent. Instance expected, got %s", typeof(v))) end
		if d.locked then
			err(format("The Parent property of %s is locked, current parent: %s, new parent %s", d.name,
				d.parent and D[d.parent].name or "NULL", v and D[v].name or "NULL"))
		end
		local old = d.parent
		if v == old then return end
		if d.cls.service and H.WORLD_READY then err(format("The Parent property of %s is locked", d.name)) end
		if v then
			local a = v
			while a do
				if a == p then err(format("Attempt to set parent of %s to %s would result in circular reference", fullName(p), fullName(v))) end
				a = D[a].parent
			end
		end
		if old then
			local od = D[old]
			local i = find(od.children, p)
			if i then table.remove(od.children, i) end
			-- removal events up the old ancestry
			fireIf(od, "ChildRemoved", p)
			local a = old
			while a do
				local ad = D[a]
				if ad.sig and ad.sig.DescendantRemoving then
					H.fire(ad.sig.DescendantRemoving, p)
					forDescendants(p, function(c) H.fire(ad.sig.DescendantRemoving, c) end)
				end
				a = ad.parent
			end
		end
		d.parent = v
		if v then
			local vd = D[v]
			vd.children[#vd.children + 1] = p
			fireIf(vd, "ChildAdded", p)
			local a = v
			while a do
				local ad = D[a]
				if ad.sig and ad.sig.DescendantAdded then
					H.fire(ad.sig.DescendantAdded, p)
					forDescendants(p, function(c) H.fire(ad.sig.DescendantAdded, c) end)
				end
				a = ad.parent
			end
			if vd.wfc then childArrived(v, vd, p, d.name) end
		end
		fireIf(d, "AncestryChanged", p, v)
		forDescendants(p, function(c) local cd = D[c] if cd.sig then fireIf(cd, "AncestryChanged", p, v) end end)
		if d.sig or d.psig then propChanged(p, d, "Parent") end
		if H.onReparent then H.onReparent(p, d, old, v) end
	end
	H.setParent = setParent

	local function destroy(p)
		local d = D[p]
		if d.destroyed then return end
		if d.sig and d.sig.Destroying then H.fireNow(d.sig.Destroying) end
		if d.parent then setParent(p, d, nil) end
		d.locked = true
		d.destroyed = true
		d.destroyedFrame = H.FRAME
		if d.sig then for _, s in pairs(d.sig) do H.disconnectAll(s) end end
		if d.psig then for _, s in pairs(d.psig) do H.disconnectAll(s) end end
		if d.asig then for _, s in pairs(d.asig) do H.disconnectAll(s) end end
		for _, c in ipairs(table.clone(d.children)) do destroy(c) end
		if H.onDestroy then H.onDestroy(p, d) end
	end
	H.destroy = destroy

	local function cloneTree(p, map)
		local d = D[p]
		if d.props.Archivable == false then return nil end
		if d.cls.service or d.cls.name == "DataModel" or d.cls.name == "Player" or d.cls.name == "Terrain" then return nil end
		local c, cd = newInst(d.cls.name)
		cd.name = d.name
		for k, v in pairs(d.props) do cd.props[k] = v end
		if d.attrs then cd.attrs = table.clone(d.attrs) end
		if d.tags then cd.tags = table.clone(d.tags) end
		if d.cloneExtra then d.cloneExtra(d, cd) end
		map[p] = c
		trackCreated(c, cd)
		for _, child in ipairs(d.children) do
			local cc = cloneTree(child, map)
			if cc then
				local ccd = D[cc]
				ccd.parent = c
				cd.children[#cd.children + 1] = cc
			end
		end
		return c
	end
	local function clone(p)
		local map = {}
		local c = cloneTree(p, map)
		if not c then return nil end
		-- references inside the cloned tree point at the clones
		for _, cc in pairs(map) do
			local cd = D[cc]
			for k, v in pairs(cd.props) do
				if type(v) == "table" and D[v] and map[v] then cd.props[k] = map[v] end
			end
			if H.onCloned then H.onCloned(cc, cd) end
		end
		return c
	end
	H.clone = clone

	-------------------------------------------------------------------------------------- Instance methods
	local function self_(p, fname)
		local d = D[p]
		if not d then err(format("Expected ':' not '.' calling member function %s", fname)) end
		return d
	end
	local IM = H.hook("Instance").methods
	local IG = H.hook("Instance").get
	local IS = H.hook("Instance").set
	local ISM = H.hook("Object")
	ISM.get.ClassName = function(p, d) return d.cls.name end
	ISM.get.className = ISM.get.ClassName
	ISM.methods.IsA = function(p, cname)
		local d = self_(p, "IsA")
		if type(cname) ~= "string" then H.badArg(1, "IsA", "string", cname) end
		return d.cls.isa[cname] == true
	end
	ISM.methods.isA = ISM.methods.IsA
	ISM.methods.GetPropertyChangedSignal = function(p, prop)
		local d = self_(p, "GetPropertyChangedSignal")
		local m = d.cls.members[prop]
		if not m or m.kind ~= "p" then err(format("%s is not a valid property name.", tostring(prop))) end
		local ps = d.psig
		if not ps then ps = {} d.psig = ps end
		local s = ps[prop]
		if not s then s = H.newSignal(prop .. "Changed", p) ps[prop] = s end
		return s
	end
	IG.Name = function(p, d) return d.name end
	IS.Name = function(p, d, v)
		d.name = v
		local par = d.parent
		if par then
			local pd = D[par]
			if pd.wfc then childArrived(par, pd, p, v) end
		end
	end
	IG.Parent = function(p, d) return d.parent end
	IS.Parent = function(p, d, v) setParent(p, d, v) end
	H.hook("Instance").defaults.Archivable = true

	IM.GetChildren = function(p) local d = self_(p, "GetChildren") return table.clone(d.children) end
	IM.getChildren = IM.GetChildren
	IM.children = IM.GetChildren
	IM.GetDescendants = function(p)
		self_(p, "GetDescendants")
		local out = {}
		forDescendants(p, function(c) out[#out + 1] = c end)
		return out
	end
	IM.FindFirstChild = function(p, name, recursive)
		local d = self_(p, "FindFirstChild")
		if name == nil then err("Argument 1 missing or nil") end
		name = tostring(name)
		for _, c in ipairs(d.children) do if D[c].name == name then return c end end
		if recursive then
			for _, c in ipairs(d.children) do
				local r = IM.FindFirstChild(c, name, true)
				if r then return r end
			end
		end
		return nil
	end
	IM.findFirstChild = IM.FindFirstChild
	IM.FindFirstDescendant = function(p, name) return IM.FindFirstChild(p, name, true) end
	IM.FindFirstChildOfClass = function(p, cname)
		local d = self_(p, "FindFirstChildOfClass")
		for _, c in ipairs(d.children) do if D[c].cls.name == cname then return c end end
		return nil
	end
	IM.FindFirstChildWhichIsA = function(p, cname, recursive)
		local d = self_(p, "FindFirstChildWhichIsA")
		for _, c in ipairs(d.children) do if D[c].cls.isa[cname] then return c end end
		if recursive then
			for _, c in ipairs(d.children) do
				local r = IM.FindFirstChildWhichIsA(c, cname, true)
				if r then return r end
			end
		end
		return nil
	end
	IM.FindFirstAncestor = function(p, name)
		local cur = self_(p, "FindFirstAncestor").parent
		while cur do if D[cur].name == name then return cur end cur = D[cur].parent end
		return nil
	end
	IM.FindFirstAncestorOfClass = function(p, cname)
		local cur = self_(p, "FindFirstAncestorOfClass").parent
		while cur do if D[cur].cls.name == cname then return cur end cur = D[cur].parent end
		return nil
	end
	IM.FindFirstAncestorWhichIsA = function(p, cname)
		local cur = self_(p, "FindFirstAncestorWhichIsA").parent
		while cur do if D[cur].cls.isa[cname] then return cur end cur = D[cur].parent end
		return nil
	end
	IM.IsDescendantOf = function(p, anc)
		self_(p, "IsDescendantOf")
		if anc == nil then return false end
		return isDescendantOf(p, anc)
	end
	IM.isDescendantOf = IM.IsDescendantOf
	IM.IsAncestorOf = function(p, desc)
		self_(p, "IsAncestorOf")
		if desc == nil then return false end
		return isDescendantOf(desc, p)
	end
	IM.GetFullName = function(p) self_(p, "GetFullName") return fullName(p) end
	IM.GetDebugId = function(p) return format("H_%d", self_(p, "GetDebugId").id) end
	IM.GetActor = function(p) self_(p, "GetActor") return nil end
	IM.Destroy = function(p) self_(p, "Destroy") destroy(p) end
	IM.destroy = IM.Destroy
	IM.Remove = function(p)
		local d = self_(p, "Remove")
		if d.parent then setParent(p, d, nil) end
	end
	IM.remove = IM.Remove
	IM.ClearAllChildren = function(p)
		local d = self_(p, "ClearAllChildren")
		for _, c in ipairs(table.clone(d.children)) do destroy(c) end
	end
	IM.Clone = function(p) self_(p, "Clone") return clone(p) end
	IM.clone = IM.Clone
	IM.IsPropertyModified = function(p, prop)
		local d = self_(p, "IsPropertyModified")
		return d.props[prop] ~= nil
	end
	IM.ResetPropertyToDefault = function(p, prop)
		local d = self_(p, "ResetPropertyToDefault")
		d.props[prop] = nil
	end
	IM.WaitForChild = function(p, name, timeout)
		local d = self_(p, "WaitForChild")
		if type(name) ~= "string" then H.badArg(1, "WaitForChild", "string", name) end
		for _, c in ipairs(d.children) do if D[c].name == name then return c end end
		local th, isMain = coroutine.running()
		if isMain or not coroutine.isyieldable() then err("attempt to yield across metamethod/C-call boundary (WaitForChild)") end
		local w = { th = th, inst = p, name = name, t0 = H.NOW, timeout = timeout and H.numArg(timeout, 2, "WaitForChild") or nil,
			done = false, warned = false, ctx = H.CTX, tb = debug.traceback(nil, 2) }
		d.wfc = d.wfc or {}
		d.wfc[name] = d.wfc[name] or {}
		table.insert(d.wfc[name], w)
		H.WFC[#H.WFC + 1] = w
		return coroutine.yield()
	end
	IM.waitForChild = IM.WaitForChild
	function H.stepWaitForChild()
		for _, w in ipairs(H.WFC) do
			if not w.done then
				local age = H.NOW - w.t0
				if w.timeout then
					if age >= w.timeout then
						w.done = true
						H.resume(w.th, nil)
					end
				elseif age >= 5 and not w.warned then
					w.warned = true
					H.recordWarning("infinite-yield", format("Infinite yield possible on '%s:WaitForChild(\"%s\")'", fullName(w.inst), w.name), w.tb)
				end
			end
		end
	end

	-- attributes
	local ATTR_TYPES = { string = true, boolean = true, number = true, UDim = true, UDim2 = true, BrickColor = true, Color3 = true,
		Vector2 = true, Vector3 = true, CFrame = true, NumberSequence = true, ColorSequence = true, NumberRange = true, Rect = true,
		Font = true, EnumItem = true }
	IM.SetAttribute = function(p, name, value)
		local d = self_(p, "SetAttribute")
		if type(name) ~= "string" then H.badArg(1, "SetAttribute", "string", name) end
		if #name > 100 then err("Attribute name is too long (max 100 characters)") end
		if name:match("[^%w_]") then err(format("Attribute name '%s' contains invalid characters (letters, digits and _ only)", name)) end
		if name:sub(1, 3) == "RBX" then err("Attribute names starting with 'RBX' are reserved") end
		if value ~= nil and not ATTR_TYPES[typeof(value)] then
			err(format("%s is not a supported attribute type", typeof(value)))
		end
		d.attrs = d.attrs or {}
		local old = d.attrs[name]
		d.attrs[name] = value
		if old ~= value then
			if d.sig and d.sig.AttributeChanged then H.fire(d.sig.AttributeChanged, name) end
			if d.asig and d.asig[name] then H.fire(d.asig[name]) end
		end
	end
	IM.GetAttribute = function(p, name)
		local d = self_(p, "GetAttribute")
		return d.attrs and d.attrs[name]
	end
	IM.GetAttributes = function(p)
		local d = self_(p, "GetAttributes")
		return d.attrs and table.clone(d.attrs) or {}
	end
	IM.GetAttributeChangedSignal = function(p, name)
		local d = self_(p, "GetAttributeChangedSignal")
		d.asig = d.asig or {}
		local s = d.asig[name]
		if not s then s = H.newSignal("AttributeChanged:" .. tostring(name), p) d.asig[name] = s end
		return s
	end
	-- tags
	IM.AddTag = function(p, tag)
		local d = self_(p, "AddTag")
		d.tags = d.tags or {}
		if not table.find(d.tags, tag) then table.insert(d.tags, tag) if H.onTagAdded then H.onTagAdded(p, tag) end end
	end
	IM.RemoveTag = function(p, tag)
		local d = self_(p, "RemoveTag")
		local i = d.tags and table.find(d.tags, tag)
		if i then table.remove(d.tags, i) if H.onTagRemoved then H.onTagRemoved(p, tag) end end
	end
	IM.HasTag = function(p, tag) local d = self_(p, "HasTag") return d.tags ~= nil and table.find(d.tags, tag) ~= nil end
	IM.GetTags = function(p) local d = self_(p, "GetTags") return d.tags and table.clone(d.tags) or {} end

	-------------------------------------------------------------------------------------- Instance library
	local Instance = {}
	function Instance.new(className, parent)
		if type(className) ~= "string" then H.badArg(1, "new", "string", className) end
		local ci = getClass(className)
		if not ci or not ci.creatable or ci.service then
			err(format("Unable to create an Instance of type \"%s\"", className))
		end
		local p, d = newInst(className)
		trackCreated(p, d)
		if parent ~= nil then
			H.recordWarning("instance-new-parent", "Instance.new(className, parent) sets Parent before the other properties (slower; Roblox recommends setting Parent last)")
			setParent(p, d, parent)
		end
		return p
	end
	function Instance.fromExisting(p)
		local d = D[p]
		if not d then H.badArg(1, "fromExisting", "Instance", p) end
		local c, cd = newInst(d.cls.name)
		cd.name = d.name
		for k, v in pairs(d.props) do cd.props[k] = v end
		trackCreated(c, cd)
		return c
	end
	H.Instance = table.freeze(Instance)
end
