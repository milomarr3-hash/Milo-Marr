-- AuraRNG Studio install kit | 99_rollback.luau | rollback: put the backup back
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (151582 bytes, checksum 322184148).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "99_rollback.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-151582-322184148-12-938307881"
local NEW_LEN, NEW_SUM = 151582, 322184148
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

-- Which backup to put back. nil = the backup holding the pass-4 live version: 35000 bytes, checksum 489406639 if there is one, else the newest backup this kit made
-- of this module. To pick another, put its name here (00_status.luau lists them), e.g. "TheEnd_20261014_before_pass5".
local BACKUP_NAME = nil

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

	local bk = SS:FindFirstChild("AuraRNG_Backups")
	if not bk then
		return say("FAIL", "there is no ServerStorage.AuraRNG_Backups, so there is nothing to roll back to. Nothing changed.")
	end
	local b
	if BACKUP_NAME then
		b = bk:FindFirstChild(BACKUP_NAME)
		if not (b and b:IsA("ModuleScript")) then
			return say("FAIL", "no ModuleScript named " .. BACKUP_NAME .. " in ServerStorage.AuraRNG_Backups. Nothing changed.")
		end
	else
		if BEFORE_LEN then
			b = backupWith(BEFORE_LEN, BEFORE_SUM)
		end
		if not b then
			local best = -1
			for _, c in ipairs(bk:GetChildren()) do
				if c:IsA("ModuleScript") and c:GetAttribute("AuraRNG_BackupOf") == TARGET_NAME then
					local t = c:GetAttribute("AuraRNG_SavedAt") or 0
					local s = SES:GetEditorSource(c)
					if t > best and not (#s == NEW_LEN and sum(s) == NEW_SUM) then
						b, best = c, t
					end
				end
			end
		end
		if not b then
			return say("FAIL", "no backup of " .. TARGET_NAME .. " found in ServerStorage.AuraRNG_Backups. Nothing changed.")
		end
	end
	local src = SES:GetEditorSource(b)
	local wantLen, wantSum = b:GetAttribute("AuraRNG_Length"), b:GetAttribute("AuraRNG_Checksum")
	if wantLen and (#src ~= wantLen or sum(src) ~= wantSum) then
		return say("FAIL", string.format("backup %s holds %d bytes, checksum %d, but was saved as %d, %d. Nothing changed.", b.Name, #src, sum(src), wantLen, wantSum))
	end
	local cur = SES:GetEditorSource(m)
	if cur == src then
		return say("OK", string.format("already rolled back: %s holds the text of %s (%d bytes, checksum %d, %s).", TARGET_NAME, b.Name, #src, sum(src), describe(#src, sum(src))))
	end
	-- keep the version being replaced too (unless a backup already holds it)
	local kept = backupWith(#cur, sum(cur))
	if not kept then
		local same
		kept, same = makeBackup(m, cur, "replaced_by_rollback")
		if not same then
			return say("FAIL", "could not save the current version before rolling back (" .. kept.Name .. " differs). Nothing changed.")
		end
	end
	local done, why = writeAndCheck(m, src, cur)
	if not done then
		return say("FAIL", why)
	end
	return say("OK", string.format("rolled back: %s now holds %s (%d bytes, checksum %d, %s), read back and checked. The replaced version is saved as %s.",
		TARGET_NAME, b.Name, #src, sum(src), describe(#src, sum(src)), kept.Name))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
