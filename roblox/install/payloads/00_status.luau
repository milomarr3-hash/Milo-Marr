-- AuraRNG Studio install kit | 00_status.luau | read-only status (run any time)
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (148303 bytes, checksum 731942170).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "00_status.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-148303-731942170-12-824555251"
local NEW_LEN, NEW_SUM = 148303, 731942170
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

local N = 12
local LENS = { 13300, 13224, 13240, 13242, 13194, 13235, 13276, 13235, 13290, 13298, 13282, 2487 }
local SUMS = { 825733820, 782681153, 524531706, 656635892, 998587156, 867606918, 526087852, 254541497, 6651690, 395645774, 897444566, 313496838 }

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
	local lines = {}
	table.insert(lines, game:GetService("RunService"):IsRunning() and "mode PLAY (stop Play before installing)" or "mode Edit")
	local m = findTarget()
	if m and m:IsA("LuaSourceContainer") then
		local src = SES:GetEditorSource(m)
		local cs = sum(src)
		table.insert(lines, string.format("%s is %d bytes, checksum %d = %s", TARGET_NAME, #src, cs, describe(#src, cs)))
		table.insert(lines, overrides(m))
	else
		table.insert(lines, TARGET_NAME .. " NOT FOUND")
	end
	local bk = SS:FindFirstChild("AuraRNG_Backups")
	if bk then
		local list = {}
		for _, c in ipairs(bk:GetChildren()) do
			if c:IsA("ModuleScript") then
				local s = SES:GetEditorSource(c)
				table.insert(list, string.format("%s (%d bytes, %s)", c.Name, #s, describe(#s, sum(s))))
			end
		end
		table.insert(lines, "backups: " .. (#list > 0 and table.concat(list, "; ") or "none"))
	else
		table.insert(lines, "backups: no ServerStorage.AuraRNG_Backups yet")
	end
	local h = SS:FindFirstChild("AuraRNG_Install")
	if not h then
		table.insert(lines, "install holder: none (no install in progress)")
	elseif h:GetAttribute("RunId") ~= RUN then
		table.insert(lines, "install holder: from ANOTHER payload set (this set's 01_backup.luau resets it)")
	else
		local good = 0
		for i = 1, N do
			if chunkOk(h, i) then
				good += 1
			end
		end
		table.insert(lines, string.format("install holder: this payload set, %d/%d pieces stored", good, N))
	end
	return say("OK", table.concat(lines, " | "))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
