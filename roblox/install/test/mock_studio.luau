--!nocheck
-- A tiny mock of the Roblox Studio APIs the install payloads use, for the luau CLI (no Roblox needed):
-- game:GetService (ReplicatedStorage, ServerStorage, ScriptEditorService, RunService, StudioService), Instance.new (Folder,
-- StringValue, ModuleScript), Name/Parent/ClassName/Value/Source, FindFirstChild, GetChildren, IsA, Clone, Destroy,
-- GetFullName, Get/SetAttribute (Roblox's name and type rules), ScriptEditorService:GetEditorSource/UpdateSourceAsync, and
-- StudioService:PromptImportFileAsync returning a File with GetBinaryContents. loadstring, os.date and os.time are the
-- luau CLI's own. Unknown members raise Roblox-style errors, so a typo in a payload fails here like it would in Studio.
--
-- MOCK (a global) holds switches the tests flip to make Studio misbehave:
--   MOCK.running            RunService:IsRunning() (Play mode)
--   MOCK.updateFilter(s)    what UpdateSourceAsync really stores (e.g. drop the last newline); nil = exact
--   MOCK.updateFails        UpdateSourceAsync raises an error
--   MOCK.valueFilter(s)     what StringValue.Value really stores; nil = exact
--   MOCK.cloneDropsSource   Clone() gives a ModuleScript an empty source (like a script with unsynced drafts)
--   MOCK.pickFile           what PromptImportFileAsync returns: nil (cancelled) or { name = ..., data = ... }
--   MOCK.writes             count of instance changes (Parent/Name/Value/Source/attribute writes, new, destroy)

MOCK = { running = false, writes = 0 }

local Instances = setmetatable({}, { __mode = "k" }) -- proxy -> state
local CLASSES = {
	DataModel = { "DataModel", "Instance" },
	Folder = { "Folder", "Instance" },
	StringValue = { "StringValue", "ValueBase", "Instance" },
	ModuleScript = { "ModuleScript", "LuaSourceContainer", "Instance" },
	Script = { "Script", "BaseScript", "LuaSourceContainer", "Instance" },
	ReplicatedStorage = { "ReplicatedStorage", "Instance" },
	ServerStorage = { "ServerStorage", "Instance" },
	ScriptEditorService = { "ScriptEditorService", "Instance" },
	RunService = { "RunService", "Instance" },
	StudioService = { "StudioService", "Instance" },
	File = { "File", "Instance" },
}
local CREATABLE = { Folder = true, StringValue = true, ModuleScript = true, Script = true }

local methods = {}
local newProxy

local function st(self)
	local s = Instances[self]
	if not s then
		error("Expected ':' not '.' calling member function", 3)
	end
	return s
end

local function fullName(s)
	local names = {}
	while s and s.class ~= "DataModel" do
		table.insert(names, 1, s.Name)
		s = s.Parent and Instances[s.Parent]
	end
	return table.concat(names, ".")
end

local function setParent(self, s, p)
	if s.destroyed then
		error("The Parent property of " .. s.Name .. " is locked, current parent: NULL, new parent " .. (p and Instances[p].Name or "NULL"), 3)
	end
	if p ~= nil and not Instances[p] then
		error("Unable to assign property Parent. Instance expected, got " .. type(p), 3)
	end
	local q = p
	while q do
		if q == self then
			error("Attempt to set " .. fullName(s) .. " as its own parent", 3)
		end
		q = Instances[q].Parent
	end
	if s.Parent then
		local sib = Instances[s.Parent].children
		for i, c in ipairs(sib) do
			if c == self then
				table.remove(sib, i)
				break
			end
		end
	end
	s.Parent = p
	if p then
		table.insert(Instances[p].children, self)
	end
	MOCK.writes += 1
end

function methods.FindFirstChild(self, name, recursive)
	local s = st(self)
	if type(name) ~= "string" then
		error("Argument 1 missing or nil", 2)
	end
	for _, c in ipairs(s.children) do
		if Instances[c].Name == name then
			return c
		end
	end
	if recursive then
		for _, c in ipairs(s.children) do
			local f = methods.FindFirstChild(c, name, true)
			if f then
				return f
			end
		end
	end
	return nil
end

function methods.GetChildren(self)
	return table.clone(st(self).children)
end

function methods.GetDescendants(self)
	local out = {}
	local function walk(o)
		for _, c in ipairs(Instances[o].children) do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end

function methods.IsA(self, class)
	for _, c in ipairs(CLASSES[st(self).class]) do
		if c == class then
			return true
		end
	end
	return false
end

function methods.GetFullName(self)
	return fullName(st(self))
end

local function checkAttrName(name)
	if type(name) ~= "string" or #name == 0 or #name > 100 or not string.match(name, "^[%w_]+$") or string.sub(name, 1, 3) == "RBX" then
		error("Attribute name '" .. tostring(name) .. "' is invalid", 3)
	end
end

function methods.SetAttribute(self, name, value)
	local s = st(self)
	checkAttrName(name)
	local t = type(value)
	if not (t == "nil" or t == "string" or t == "number" or t == "boolean") then
		error("Attribute value type " .. t .. " is not supported", 2)
	end
	s.attributes[name] = value
	MOCK.writes += 1
end

function methods.GetAttribute(self, name)
	checkAttrName(name)
	return st(self).attributes[name]
end

function methods.GetAttributes(self)
	return table.clone(st(self).attributes)
end

function methods.Destroy(self)
	local s = st(self)
	if s.service then
		error("The Parent property of " .. s.Name .. " is locked", 2)
	end
	for _, c in ipairs(table.clone(s.children)) do
		methods.Destroy(c)
	end
	if s.Parent then
		setParent(self, s, nil)
	end
	s.destroyed = true
	MOCK.writes += 1
end

function methods.Clone(self)
	local s = st(self)
	if s.Archivable == false then
		return nil
	end
	local c = newProxy(s.class)
	local cs = Instances[c]
	cs.Name = s.Name
	cs.Value = s.Value
	cs.source = s.source
	if MOCK.cloneDropsSource and s.class == "ModuleScript" then
		cs.source = ""
	end
	cs.attributes = table.clone(s.attributes)
	for _, ch in ipairs(s.children) do
		local cc = methods.Clone(ch)
		if cc then
			setParent(cc, Instances[cc], c)
		end
	end
	MOCK.writes += 1
	return c
end

-- services
local services = {}

function methods.GetService(self, name)
	local s = st(self)
	if s.class ~= "DataModel" then
		error("GetService is not a valid member of " .. s.class, 2)
	end
	local svc = services[name]
	if not svc then
		error("'" .. tostring(name) .. "' is not a valid Service name", 2)
	end
	return svc
end

function methods.GetEditorSource(self, script)
	local s = st(self)
	assert(s.class == "ScriptEditorService", "GetEditorSource is not a valid member of " .. s.class)
	local ss = script and Instances[script]
	if not ss or not (ss.class == "ModuleScript" or ss.class == "Script") then
		error("Unable to cast value to Object", 2)
	end
	return ss.source
end

function methods.UpdateSourceAsync(self, script, callback)
	local s = st(self)
	assert(s.class == "ScriptEditorService", "UpdateSourceAsync is not a valid member of " .. s.class)
	local ss = script and Instances[script]
	if not ss or not (ss.class == "ModuleScript" or ss.class == "Script") then
		error("Unable to cast value to Object", 2)
	end
	if type(callback) ~= "function" then
		error("Unable to cast value to function", 2)
	end
	if MOCK.updateFails then
		error("UpdateSourceAsync: the script editor is busy (mock failure)", 2)
	end
	local new = callback(ss.source)
	if type(new) ~= "string" then
		error("UpdateSourceAsync callback must return a string", 2)
	end
	ss.source = MOCK.updateFilter and MOCK.updateFilter(new) or new
	MOCK.writes += 1
end

function methods.IsRunning(self)
	assert(st(self).class == "RunService")
	return MOCK.running
end

function methods.IsEdit(self)
	assert(st(self).class == "RunService")
	return not MOCK.running
end

function methods.PromptImportFileAsync(self, filter)
	assert(st(self).class == "StudioService")
	if filter ~= nil and type(filter) ~= "table" then
		error("Unable to cast value to Array", 2)
	end
	local p = MOCK.pickFile
	if not p then
		return nil
	end
	local f = newProxy("File")
	Instances[f].Name = p.name
	Instances[f].data = p.data
	return f
end

function methods.GetBinaryContents(self)
	local s = st(self)
	assert(s.class == "File")
	return s.data
end

-- properties every class has; per-class extras below
local PROPS = { Name = true, Parent = true, ClassName = true, Archivable = true }
local EXTRA = { StringValue = { Value = true }, ModuleScript = { Source = true }, Script = { Source = true }, File = { Size = true } }
local METHODS_OF = {
	DataModel = { GetService = true },
	ScriptEditorService = { GetEditorSource = true, UpdateSourceAsync = true },
	RunService = { IsRunning = true, IsEdit = true },
	StudioService = { PromptImportFileAsync = true },
	File = { GetBinaryContents = true },
}
local COMMON = { FindFirstChild = true, GetChildren = true, GetDescendants = true, IsA = true, GetFullName = true,
	SetAttribute = true, GetAttribute = true, GetAttributes = true, Destroy = true, Clone = true }

local mt = {}
mt.__index = function(self, k)
	local s = st(self)
	if PROPS[k] then
		if k == "ClassName" then
			return s.class
		end
		return s[k]
	end
	local ex = EXTRA[s.class]
	if ex and ex[k] then
		if k == "Source" then
			return s.source
		elseif k == "Size" then
			return #s.data
		end
		return s[k]
	end
	if COMMON[k] or (METHODS_OF[s.class] and METHODS_OF[s.class][k]) then
		return methods[k]
	end
	-- children by name (game.ReplicatedStorage.AuraFX.TheEnd)
	local c = methods.FindFirstChild(self, k)
	if c then
		return c
	end
	error(tostring(k) .. " is not a valid member of " .. s.class .. ' "' .. fullName(s) .. '"', 2)
end
mt.__newindex = function(self, k, v)
	local s = st(self)
	if k == "Parent" then
		if s.service then
			error("The Parent property of " .. s.Name .. " is locked", 2)
		end
		setParent(self, s, v)
		return
	elseif k == "Name" then
		if type(v) ~= "string" then
			error("Unable to assign property Name. string expected, got " .. type(v), 2)
		end
		s.Name = v
	elseif k == "Archivable" then
		s.Archivable = v
	elseif k == "ClassName" then
		error("Unable to assign property ClassName. Property is read only", 2)
	elseif k == "Value" and s.class == "StringValue" then
		if type(v) ~= "string" then
			error("Unable to assign property Value. string expected, got " .. type(v), 2)
		end
		s.Value = MOCK.valueFilter and MOCK.valueFilter(v) or v
	elseif k == "Source" and (s.class == "ModuleScript" or s.class == "Script") then
		s.source = v
	else
		error(tostring(k) .. " is not a valid member of " .. s.class .. ' "' .. fullName(s) .. '"', 2)
	end
	MOCK.writes += 1
end
mt.__tostring = function(self)
	return Instances[self].Name
end

newProxy = function(class)
	local p = setmetatable({}, mt)
	Instances[p] = { class = class, Name = class, children = {}, attributes = {}, Value = class == "StringValue" and "" or nil,
		source = (class == "ModuleScript" or class == "Script") and "" or nil, Archivable = true }
	return p
end

Instance = {
	new = function(class, parent)
		if not CREATABLE[class] then
			error('Unable to create an Instance of type "' .. tostring(class) .. '"', 2)
		end
		local p = newProxy(class)
		if parent then
			setParent(p, Instances[p], parent)
		end
		MOCK.writes += 1
		return p
	end,
}

game = newProxy("DataModel")
Instances[game].Name = "Game"
for _, name in ipairs({ "ReplicatedStorage", "ServerStorage", "ScriptEditorService", "RunService", "StudioService" }) do
	local svc = newProxy(name)
	Instances[svc].Name = name
	Instances[svc].service = true
	setParent(svc, Instances[svc], game)
	services[name] = svc
end
workspace = nil

-- helpers for the tests (not used by payloads)
MOCK.state = function(o)
	return Instances[o]
end
MOCK.path = function(path)
	local o = game
	for part in string.gmatch(path, "[^%.]+") do
		o = o and methods.FindFirstChild(o, part)
	end
	return o
end
MOCK.makeModule = function(parentPath, name, source)
	local p = MOCK.path(parentPath)
	assert(p, "no " .. parentPath)
	local m = newProxy("ModuleScript")
	Instances[m].Name = name
	Instances[m].source = source
	setParent(m, Instances[m], p)
	return m
end
MOCK.makeFolder = function(parentPath, name)
	local p = MOCK.path(parentPath)
	local f = newProxy("Folder")
	Instances[f].Name = name
	setParent(f, Instances[f], p)
	return f
end
MOCK.sourceOf = function(path)
	local o = MOCK.path(path)
	return o and Instances[o].source
end
MOCK.tree = function(path)
	local o = MOCK.path(path)
	if not o then
		return "-"
	end
	local out = {}
	for _, c in ipairs(Instances[o].children) do
		local s = Instances[c]
		table.insert(out, s.Name .. ":" .. s.class)
	end
	table.sort(out)
	return table.concat(out, ",")
end
