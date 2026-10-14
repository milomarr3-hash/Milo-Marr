-- AuraRNG Studio install kit | 09_apply.luau | step 9: join, check, compile, write, read back
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (82580 bytes, checksum 413068034).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "09_apply.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-82580-413068034-7-175648338"
local NEW_LEN, NEW_SUM = 82580, 413068034
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

local N = 7
local LENS = { 13394, 13390, 13386, 13387, 13372, 13337, 2314 }
local SUMS = { 747760660, 546838554, 282322451, 777563289, 713911797, 449542432, 103059902 }

-- the temporary holder ServerStorage.AuraRNG_Install: one StringValue per piece of the new source
local function chunkName(i)
	return string.format("chunk_%02d", i)
end
local function chunkFile(i)
	return string.format("%02d_chunk_%02d_of_%02d.luau", i + 1, i, N)
end
local function holder()
	local h = SS:FindFirstChild("AuraRNG_Install")
	if h and h:GetAttribute("RunId") == RUN then
		return h
	end
	return nil
end
local function chunkOk(h, i)
	local v = h:FindFirstChild(chunkName(i))
	return v ~= nil and v:IsA("StringValue") and #v.Value == LENS[i] and sum(v.Value) == SUMS[i]
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

	local h = holder()
	if not h then
		local other = SS:FindFirstChild("AuraRNG_Install")
		return say("FAIL", (other and "the install holder is from another payload set" or "there is no install holder")
			.. ". Run 01_backup.luau and every piece of this set first. Nothing changed.")
	end
	local parts = {}
	for i = 1, N do
		if not chunkOk(h, i) then
			return say("FAIL", string.format("piece %d is missing or damaged: run %s (and the pieces after it). Nothing changed.", i, chunkFile(i)))
		end
		parts[i] = h:FindFirstChild(chunkName(i)).Value
	end
	local src = table.concat(parts)
	if #src ~= NEW_LEN or sum(src) ~= NEW_SUM then
		return say("FAIL", string.format("the joined pieces are %d bytes, checksum %d, not %d, %d. Run 01_backup.luau and all pieces again. Nothing changed.",
			#src, sum(src), NEW_LEN, NEW_SUM))
	end
	local cur = SES:GetEditorSource(m)
	if cur == src then
		h:Destroy()
		return say("OK", string.format("already installed: %s is the new version (%d bytes, checksum %d). Temporary holder removed.", TARGET_NAME, NEW_LEN, NEW_SUM))
	end
	local b = backupWith(#cur, sum(cur))
	if not b then
		return say("FAIL", string.format("the live %s (%d bytes, checksum %d) is not in ServerStorage.AuraRNG_Backups: it changed after 01_backup.luau ran. Run 01_backup.luau again, then this. Nothing changed.",
			TARGET_NAME, #cur, sum(cur)))
	end
	local done, why = writeAndCheck(m, src, cur)
	if not done then
		return say("FAIL", why .. " The holder is kept, so this can be run again.")
	end
	h:Destroy()
	return say("OK", string.format("installed: %s is now %d bytes, checksum %d (compiled, written, read back from the editor and checked). The previous version is saved as %s. Temporary holder removed. Next: test in Play (studio_checks.md).",
		TARGET_NAME, NEW_LEN, NEW_SUM, b:GetFullName()))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
