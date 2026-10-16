-- AuraRNG Studio install kit | 90_install_from_file.luau | plan B: install from a file picked in a dialog
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (141659 bytes, checksum 402664341).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "90_install_from_file.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-141659-402664341-11-730820328"
local NEW_LEN, NEW_SUM = 141659, 402664341
local BEFORE_LEN, BEFORE_SUM, BEFORE_NAME = 35000, 489406639, "the pass-4 live version"
local SES = game:GetService("ScriptEditorService")
local SS = game:GetService("ServerStorage")

-- checksum of a text, the same one the repo tools print: x = (x * 131 + byte) % 1000000007 over its bytes
local function sum(s)
	local x = 0
	for i = 1, #s do
		x = (x * 131 + string.byte(s, i)) % 1000000007
	end
	return x
end

-- every result is one line: OK, FAIL or STOP, this file's name, then what happened
local function say(word, msg)
	return word .. " " .. FILE .. ": " .. msg
end

-- the module to install into (nil if it is missing)
local function findTarget()
	local o = game:GetService(TARGET[1])
	for i = 2, #TARGET do
		o = o and o:FindFirstChild(TARGET[i])
	end
	return o
end

-- which version a text is, by its length and checksum
local function describe(len, cs)
	if len == NEW_LEN and cs == NEW_SUM then
		return "the NEW version"
	elseif len == BEFORE_LEN and cs == BEFORE_SUM then
		return BEFORE_NAME
	end
	return "an unknown version"
end

-- a ModuleScript in ServerStorage.AuraRNG_Backups holding a text of this length and checksum (nil if none)
local function backupWith(len, cs)
	local bk = SS:FindFirstChild("AuraRNG_Backups")
	if not bk then
		return nil
	end
	for _, c in ipairs(bk:GetChildren()) do
		if c:IsA("ModuleScript") then
			local s = SES:GetEditorSource(c)
			if #s == len and sum(s) == cs then
				return c
			end
		end
	end
	return nil
end

-- copies the module into ServerStorage.AuraRNG_Backups (made if missing) as <Name>_<YYYYMMDD>_<why>, or _2, _3 ... when
-- that name is taken (nothing there is ever deleted), then checks the copy holds the same text
local function makeBackup(m, src, why)
	local bk = SS:FindFirstChild("AuraRNG_Backups")
	if not bk then
		bk = Instance.new("Folder")
		bk.Name = "AuraRNG_Backups"
		bk.Parent = SS
	end
	local d = os.date("*t")
	local base = string.format("%s_%04d%02d%02d_%s", m.Name, d.year, d.month, d.day, why)
	local name, k = base, 1
	while bk:FindFirstChild(name) do
		k += 1
		name = base .. "_" .. k
	end
	local c = m:Clone() or Instance.new("ModuleScript")
	c.Name = name
	c:SetAttribute("AuraRNG_BackupOf", m:GetFullName())
	c:SetAttribute("AuraRNG_Length", #src)
	c:SetAttribute("AuraRNG_Checksum", sum(src))
	c:SetAttribute("AuraRNG_SavedAt", os.time())
	c.Parent = bk
	if SES:GetEditorSource(c) ~= src then
		SES:UpdateSourceAsync(c, function()
			return src
		end)
	end
	return c, SES:GetEditorSource(c) == src
end

-- the first byte where two texts differ
local function firstDiff(a, b)
	for i = 1, math.min(#a, #b) do
		if string.byte(a, i) ~= string.byte(b, i) then
			return i
		end
	end
	return math.min(#a, #b) + 1
end

-- compiles NEW, writes it into the module through the script editor, reads it back and compares; if it did not come out
-- exactly right, puts OLD back. -> true, or false and what happened
local function writeAndCheck(m, new, old)
	if type(loadstring) ~= "function" then
		return false, "loadstring is not available here, so the new text cannot be compile-checked. Nothing changed. Run this with the Studio MCP execute_luau (Edit) or the Command Bar."
	end
	local f, err = loadstring(new, "=" .. m.Name)
	if not f then
		return false, "the new text does not compile: " .. tostring(err) .. ". Nothing changed."
	end
	local ok, e = pcall(function()
		SES:UpdateSourceAsync(m, function()
			return new
		end)
	end)
	local now = SES:GetEditorSource(m)
	if ok and now == new then
		return true
	end
	local why = ok and "it read back different" or ("UpdateSourceAsync failed: " .. tostring(e))
	local detail = string.format("(read back %d bytes, checksum %d; wanted %d, %d; first difference at byte %d)",
		#now, sum(now), #new, sum(new), firstDiff(now, new))
	if now ~= old then
		pcall(function()
			SES:UpdateSourceAsync(m, function()
				return old
			end)
		end)
	end
	local back = SES:GetEditorSource(m) == old
	return false, why .. " " .. detail .. ". " .. (back and "The previous version is in place (checked)."
		or "WARNING: the previous version could not be put back: run 99_rollback.luau.")
end

local LABEL = "pass5"
-- CONFIG overrides are attributes on the module (UPPER_CASE names). They survive an install and a rollback, and every
-- build reads them, so a flip left over from an earlier Studio test would silently change the new version: list them.
local function overrides(m)
	local out = {}
	local ok, attrs = pcall(function() return m:GetAttributes() end)
	if ok and type(attrs) == "table" then
		for k, v in pairs(attrs) do
			if type(k) == "string" and string.match(k, "^[%u%d_]+$") then table.insert(out, k .. "=" .. tostring(v)) end
		end
	end
	table.sort(out)
	if #out == 0 then return "CONFIG overrides on the module: none" end
	return "CONFIG overrides on the module: " .. table.concat(out, ", ")
		.. " (not set by you this session? clear them: studio_checks.md S8 CLEAR_ALL)"
end

local function main()
	if game:GetService("RunService"):IsRunning() then
		return say("STOP", "Studio is in Play mode. Stop Play, then run this again in Edit mode. Nothing changed.")
	end
	local m = findTarget()
	if not m then
		return say("FAIL", TARGET_NAME .. " was not found. Nothing changed. Is Milo's place open in Studio?")
	end
	if not m:IsA("ModuleScript") then
		return say("FAIL", TARGET_NAME .. " is a " .. m.ClassName .. ", not a ModuleScript. Nothing changed.")
	end

	local cur = SES:GetEditorSource(m)
	if #cur == NEW_LEN and sum(cur) == NEW_SUM then
		return say("OK", "already installed: " .. TARGET_NAME .. " is the new version. Nothing to do. " .. overrides(m))
	end
	-- 1) back up what is live now (once)
	local b = backupWith(#cur, sum(cur))
	if not b then
		local same
		b, same = makeBackup(m, cur, "before_" .. LABEL)
		if not same then
			return say("FAIL", "made " .. b:GetFullName() .. " but its text does not match. Stop here and tell Milo; nothing was installed.")
		end
	end
	-- 2) Milo picks the new file in a dialog on the Mac
	local StudioService = game:GetService("StudioService")
	local okP, file = pcall(function()
		return StudioService:PromptImportFileAsync({ "lua", "luau", "txt" })
	end)
	if not okP then
		okP, file = pcall(function()
			return StudioService:PromptImportFileAsync()
		end)
	end
	if not okP then
		return say("FAIL", "the file dialog could not open: " .. tostring(file) .. ". Nothing installed (backup " .. b.Name .. " kept).")
	end
	if not file then
		return say("STOP", "no file was picked. Nothing installed (backup " .. b.Name .. " kept).")
	end
	local src = file:GetBinaryContents()
	if #src ~= NEW_LEN or sum(src) ~= NEW_SUM then
		return say("FAIL", string.format("the picked file %s is %d bytes, checksum %d, but %s is %d bytes, checksum %d. Pick that file from the up-to-date repo (git pull), or re-run make_payloads.py if the module changed. Nothing installed.",
			tostring(file.Name), #src, sum(src), "roblox/ReplicatedStorage/AuraFX/TheEnd.lua", NEW_LEN, NEW_SUM))
	end
	-- 3) compile, write, read back
	local done, why = writeAndCheck(m, src, cur)
	if not done then
		return say("FAIL", why)
	end
	return say("OK", string.format("installed from %s: %s is now %d bytes, checksum %d (compiled, written, read back and checked). The previous version is saved as %s. %s.",
		tostring(file.Name), TARGET_NAME, NEW_LEN, NEW_SUM, b:GetFullName(), overrides(m)))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
