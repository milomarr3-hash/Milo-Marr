-- AuraRNG Studio install kit | 00_status.luau | read-only status (run any time)
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (123861 bytes, checksum 523677650).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "00_status.luau"
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

local function main()
	local lines = {}
	table.insert(lines, game:GetService("RunService"):IsRunning() and "mode PLAY (stop Play before installing)" or "mode Edit")
	local m = findTarget()
	if m and m:IsA("LuaSourceContainer") then
		local src = SES:GetEditorSource(m)
		local cs = sum(src)
		table.insert(lines, string.format("%s is %d bytes, checksum %d = %s", TARGET_NAME, #src, cs, describe(#src, cs)))
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
