-- AuraRNG Studio install kit | 01_backup.luau | step 1: check + back up + prepare the holder
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (123861 bytes, checksum 523677650).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "01_backup.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-123861-523677650-10-457228033"
local NEW_LEN, NEW_SUM = 123861, 523677650
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

local N = 10
local LENS = { 13381, 13376, 13386, 13381, 13350, 13333, 13298, 13314, 13338, 3704 }
local SUMS = { 138302907, 144820895, 284418912, 946852927, 737433606, 204697128, 129328051, 22255047, 37178664, 110492221 }

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

local LABEL = "pass5"

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

	local src = SES:GetEditorSource(m)
	local len, cs = #src, sum(src)
	local what = describe(len, cs)
	if what == "an unknown version" then
		what = "an UNKNOWN version (not " .. BEFORE_NAME .. ", not the new file; it is backed up all the same)"
	end
	local note
	if len == NEW_LEN and cs == NEW_SUM then
		note = "No backup needed: the new version is already installed (the other payloads would only confirm it)"
	else
		local b = backupWith(len, cs)
		if b then
			note = "Already backed up as " .. b:GetFullName()
		else
			local c, same = makeBackup(m, src, "before_" .. LABEL)
			if not same then
				return say("FAIL", "made " .. c:GetFullName() .. " but its text does not match " .. TARGET_NAME
					.. ". Stop here and tell Milo; " .. TARGET_NAME .. " was not changed.")
			end
			note = "Backed up to " .. c:GetFullName() .. " (text checked)"
		end
	end
	-- the temporary holder the next payloads fill (pieces left over from another payload set are cleared)
	local h = SS:FindFirstChild("AuraRNG_Install")
	if h and not h:IsA("Folder") then
		return say("FAIL", "ServerStorage.AuraRNG_Install exists but is a " .. h.ClassName .. ", not a Folder. Rename it and run this again.")
	end
	local cleared = 0
	if h and h:GetAttribute("RunId") ~= RUN then
		for _, v in ipairs(h:GetChildren()) do
			if v:IsA("StringValue") and string.match(v.Name, "^chunk_%d+$") then
				v:Destroy()
				cleared += 1
			end
		end
	end
	if not h then
		h = Instance.new("Folder")
		h.Name = "AuraRNG_Install"
		h.Parent = SS
	end
	h:SetAttribute("RunId", RUN)
	h:SetAttribute("Target", TARGET_NAME)
	h:SetAttribute("Pieces", N)
	h:SetAttribute("Length", NEW_LEN)
	h:SetAttribute("Checksum", NEW_SUM)
	local have = 0
	for i = 1, N do
		if chunkOk(h, i) then
			have += 1
		end
	end
	return say("OK", string.format("%s is %d bytes, checksum %d: %s. %s. Holder ServerStorage.AuraRNG_Install ready, %d/%d pieces stored%s. Next: %s",
		TARGET_NAME, len, cs, what, note, have, N, cleared > 0 and (" (cleared " .. cleared .. " old pieces)") or "", chunkFile(1)))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
