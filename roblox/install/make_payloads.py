#!/usr/bin/env python3
"""Turn an aura module file into small Studio install payloads (execute_luau scripts), each <= 20 KB.

    python3 roblox/install/make_payloads.py roblox/ReplicatedStorage/AuraFX/TheEnd.lua

writes roblox/install/payloads/ (old NN_*.luau files there are replaced):

    00_status.luau            read-only: what is installed, which backups exist, install progress (run any time)
    01_backup.luau            checks ReplicatedStorage.AuraFX.TheEnd, backs it up once into ServerStorage.AuraRNG_Backups,
                              and prepares the temporary holder ServerStorage.AuraRNG_Install
    02_chunk_01_of_NN.luau .. one piece of the new source each (<= 18 KB per payload by default), stored in the holder; each
                              checks its own text and every earlier piece
    NN_apply.luau             joins the pieces, checks length + checksum, compiles them (loadstring), writes the module with
                              ScriptEditorService:UpdateSourceAsync, reads it back and checks again, removes the holder
    90_install_from_file.luau plan B: one small payload that installs from a file Milo picks in a dialog (no big payloads)
    99_rollback.luau          puts the backup back (the pass-4 live version by default)
    manifest.json             order, sizes and the expected result of each payload

Every payload returns one line starting with "OK <file>:", "FAIL <file>:" or "STOP <file>:". Nothing is ever deleted from
ServerStorage.AuraRNG_Backups. Checksum: x = (x * 131 + byte) % 1000000007 over the file's bytes, x starting at 0 (the same
number the Mac session's install scripts printed). Standard library only (runs on the Mac's python3).

Options: --target ReplicatedStorage.AuraFX.TheEnd (default: from the file name), --label pass5 (backup name
<Name>_<YYYYMMDD>_before_<label>), --before FILE|none (the version expected to be live now; default <Name>.pass4-live.lua
next to the module), --out DIR, --max-bytes 18000 (per payload; <= 20000), --max-json 25000 (as a JSON string),
--chunk-bytes N (force the piece size; tests), --allow-cr (keep CR bytes; they are escaped), --check (exit 1 if the
payloads in --out are not what this module produces), --quiet.
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
MOD = 1000000007


def checksum(data: bytes) -> int:
	x = 0
	for b in data:
		x = (x * 131 + b) % MOD
	return x


def rel(path: str) -> str:
	"""Repo-relative path for messages and the manifest (no absolute paths: the repo is public)."""
	p = os.path.abspath(path)
	if p == REPO or p.startswith(REPO + os.sep):
		return os.path.relpath(p, REPO).replace(os.sep, "/")
	return os.path.basename(p)


def luau_str(s: str) -> str:
	"""A safe one-line Luau string literal."""
	out = ['"']
	for ch in s:
		o = ord(ch)
		if ch == "\\":
			out.append("\\\\")
		elif ch == '"':
			out.append('\\"')
		elif ch == "\n":
			out.append("\\n")
		elif o < 32 or o == 127:
			out.append("\\%03d" % o)
		else:
			out.append(ch)
	out.append('"')
	return "".join(out)


def check_source(data: bytes, allow_cr: bool) -> str:
	"""Refuse texts Studio's editor might change on the way in (so the read-back check would fail)."""
	if data.startswith(b"\xef\xbb\xbf"):
		return "the file starts with a UTF-8 BOM; remove it (Studio's editor would drop it and the checksum would not match)"
	if b"\x00" in data:
		return "the file contains NUL bytes; it is not a Luau source file"
	try:
		data.decode("utf-8", errors="strict")
	except UnicodeDecodeError as e:
		return f"the file is not valid UTF-8 (byte {e.start}); Studio would change it"
	if b"\r" in data and not allow_cr:
		return ("the file has CR (Windows) line endings; convert them to LF (Studio's editor may normalise them, so the "
				"read-back check would fail), or pass --allow-cr to try anyway")
	if not data:
		return "the file is empty"
	if re.search(rb'"pending:\w+"', data):
		return ("the module still holds a \"pending:<key>\" texture placeholder (the preview renderer's stand-in for a te5 PNG "
				"that is not uploaded); in Roblox that is not an asset id. Use the repo's module, or fill TEX5 with "
				"roblox/install/patch_tex5.py")
	return ""


def split_chunks(data: bytes, max_bytes: int):
	"""Pieces of at most max_bytes, cut after a newline when possible and never inside a UTF-8 character."""
	if max_bytes < 16:
		raise ValueError("piece size too small")
	chunks, i, n = [], 0, len(data)
	while i < n:
		if n - i <= max_bytes:
			chunks.append(data[i:])
			break
		end = i + max_bytes
		cut = data.rfind(b"\n", i + max_bytes // 2, end)
		if cut != -1:
			cut += 1
		else:
			cut = end
			while cut > i and (data[cut] & 0xC0) == 0x80:  # a UTF-8 continuation byte: step back to the character start
				cut -= 1
			if cut == i:
				raise ValueError("cannot cut the text on a character boundary")
		chunks.append(data[i:cut])
		i = cut
	return chunks


def needs_escapes(chunk: bytes) -> bool:
	return any((b < 32 and b not in (9, 10)) or b == 127 for b in chunk)


def long_bracket_level(chunk: bytes) -> int:
	"""Smallest level L so that ]=*L] first appears exactly where the string is meant to end."""
	level = 0
	while True:
		close = b"]" + b"=" * level + b"]"
		if (chunk + close).find(close) == len(chunk):
			return level
		level += 1


def encode_chunk(chunk: bytes):
	"""-> (Luau expression that evaluates to exactly these bytes, description)."""
	if not needs_escapes(chunk):
		level = long_bracket_level(chunk)
		eq = "=" * level
		# Luau drops the first newline right after the opening bracket, so one is always put there
		return "[" + eq + "[\n" + chunk.decode("utf-8") + "]" + eq + "]", f"long bracket level {level}"
	# control bytes (CR, form feed ...): one escaped string per source line inside table.concat; bytes >= 128 stay raw
	# UTF-8 (pieces are never cut inside a character, so each line decodes)
	lines = chunk.split(b"\n")
	lines = [ln + b"\n" for ln in lines[:-1]] + ([lines[-1]] if lines[-1] else [])
	out_lines = []
	for ln in lines:
		buf = bytearray(b'"')
		for b in ln:
			if b == 92:
				buf += b"\\\\"
			elif b == 34:
				buf += b'\\"'
			elif b == 10:
				buf += b"\\n"
			elif b == 9:
				buf += b"\t"
			elif b < 32 or b == 127:
				buf += ("\\%03d" % b).encode()
			else:
				buf.append(b)
		buf += b'"'
		out_lines.append("\t" + buf.decode("utf-8") + ",")
	return "table.concat({\n" + "\n".join(out_lines) + "\n})", "escaped strings"


# ------------------------------------------------------------------------------------------------ Luau building blocks

HEAD = """-- AuraRNG Studio install kit | @@FILE@@ | @@ROLE@@
-- Target @@TARGET@@. Made by roblox/install/make_payloads.py from @@SRCPATH@@ (@@NEW_LEN@@ bytes, checksum @@NEW_SUM@@).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = @@FILE_Q@@
local TARGET = { @@TARGET_PARTS@@ }
local TARGET_NAME = @@TARGET_Q@@
local RUN = @@RUN_Q@@
local NEW_LEN, NEW_SUM = @@NEW_LEN@@, @@NEW_SUM@@
local BEFORE_LEN, BEFORE_SUM, BEFORE_NAME = @@BEFORE_LEN@@, @@BEFORE_SUM@@, @@BEFORE_NAME_Q@@
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
"""

GUARDS = """	if game:GetService("RunService"):IsRunning() then
		return say("STOP", "Studio is in Play mode. Stop Play, then run this again in Edit mode. Nothing changed.")
	end
	local m = findTarget()
	if not m then
		return say("FAIL", TARGET_NAME .. " was not found. Nothing changed. Is Milo's place open in Studio?")
	end
	if not m:IsA("ModuleScript") then
		return say("FAIL", TARGET_NAME .. " is a " .. m.ClassName .. ", not a ModuleScript. Nothing changed.")
	end
"""

BACKUPS = """
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
"""

WRITE = """
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
"""

HOLDER = """
local N = @@N@@
local LENS = { @@LENS@@ }
local SUMS = { @@SUMS@@ }

-- the temporary holder ServerStorage.AuraRNG_Install: one StringValue per piece of the new source
local function chunkName(i)
	return string.format("chunk_@@FMT@@", i)
end
local function chunkFile(i)
	return string.format("%02d_chunk_@@FMT@@_of_@@FMT@@.luau", i + 1, i, N)
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
"""

TAIL = """
local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
"""

STATUS_MAIN = """
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
"""

BACKUP_MAIN = """
local LABEL = @@LABEL_Q@@

local function main()
@@GUARDS@@
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
"""

CHUNK_MAIN = """
local K = @@K@@
-- piece @@K@@ of @@N@@ of the new source (@@CLEN@@ bytes, checksum @@CSUM@@, @@ENC@@)
local DATA = @@DATA@@

local function main()
	if game:GetService("RunService"):IsRunning() then
		return say("STOP", "Studio is in Play mode. Stop Play, then run this again in Edit mode. Nothing changed.")
	end
	if #DATA ~= LENS[K] or sum(DATA) ~= SUMS[K] then
		return say("FAIL", string.format("piece %d arrived changed (%d bytes, checksum %d; it should be %d bytes, checksum %d): the text of this payload was altered when it was sent. Nothing stored. Send the file again exactly as it is (tabs, spaces, blank lines and the last line all count).",
			K, #DATA, sum(DATA), LENS[K], SUMS[K]))
	end
	if not findTarget() then
		return say("FAIL", TARGET_NAME .. " was not found. Nothing stored.")
	end
	local h = holder()
	if not h then
		return say("FAIL", "no install holder for this payload set. Run 01_backup.luau of this same set first.")
	end
	for i = 1, K - 1 do
		if not chunkOk(h, i) then
			return say("FAIL", string.format("piece %d is missing or damaged: run %s first (pieces go in order). Nothing stored.", i, chunkFile(i)))
		end
	end
	local v = h:FindFirstChild(chunkName(K))
	local again = v ~= nil
	if v and not v:IsA("StringValue") then
		v:Destroy()
		v = nil
	end
	if not v then
		v = Instance.new("StringValue")
		v.Name = chunkName(K)
	end
	v.Value = DATA
	v.Parent = h
	if #v.Value ~= LENS[K] or sum(v.Value) ~= SUMS[K] then
		return say("FAIL", string.format("the StringValue changed piece %d (%d bytes stored of %d). Tell Milo; nothing was installed.", K, #v.Value, LENS[K]))
	end
	local have = 0
	for i = 1, N do
		if chunkOk(h, i) then
			have += 1
		end
	end
	return say("OK", string.format("piece %d/%d stored%s (%d bytes, checksum %d). The holder has %d/%d. Next: %s",
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or @@APPLY_Q@@))
end
"""

APPLY_MAIN = """
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
@@GUARDS@@
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
		return say("OK", string.format("already installed: %s is the new version (%d bytes, checksum %d). Temporary holder removed. %s", TARGET_NAME, NEW_LEN, NEW_SUM, overrides(m)))
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
	return say("OK", string.format("installed: %s is now %d bytes, checksum %d (compiled, written, read back from the editor and checked). The previous version is saved as %s. Temporary holder removed. %s. Next: test in Play (studio_checks.md).",
		TARGET_NAME, NEW_LEN, NEW_SUM, b:GetFullName(), overrides(m)))
end
"""

FROMFILE_MAIN = """
local LABEL = @@LABEL_Q@@
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
@@GUARDS@@
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
			tostring(file.Name), #src, sum(src), @@SRCPATH_Q@@, NEW_LEN, NEW_SUM))
	end
	-- 3) compile, write, read back
	local done, why = writeAndCheck(m, src, cur)
	if not done then
		return say("FAIL", why)
	end
	return say("OK", string.format("installed from %s: %s is now %d bytes, checksum %d (compiled, written, read back and checked). The previous version is saved as %s. %s.",
		tostring(file.Name), TARGET_NAME, NEW_LEN, NEW_SUM, b:GetFullName(), overrides(m)))
end
"""

ROLLBACK_MAIN = """
-- Which backup to put back. nil = the backup holding @@BEFORE_DESC@@ if there is one, else the newest backup this kit made
-- of this module. To pick another, put its name here (00_status.luau lists them), e.g. "TheEnd_20261014_before_pass5".
local BACKUP_NAME = nil

local function main()
@@GUARDS@@
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
"""


def fill(text: str, values: dict) -> str:
	def rep(m):
		k = m.group(1)
		if k not in values:
			raise KeyError(f"template value {k} missing")
		return str(values[k])
	return re.sub(r"@@([A-Z_]+)@@", rep, text)


def build(src_path, data, target, label, before, max_bytes, max_json, chunk_bytes, allow_cr):
	"""-> (files dict name -> text, manifest dict)."""
	err = check_source(data, allow_cr)
	if err:
		raise SystemExit(f"make_payloads: {rel(src_path)}: {err}")
	parts = target.split(".")
	if len(parts) < 2 or not all(re.fullmatch(r"[A-Za-z_][A-Za-z0-9_ ]*", p) for p in parts):
		raise SystemExit(f"make_payloads: bad --target {target!r} (want e.g. ReplicatedStorage.AuraFX.TheEnd)")
	if not re.fullmatch(r"[A-Za-z0-9_-]{1,40}", label):
		raise SystemExit(f"make_payloads: bad --label {label!r} (letters, digits, _ and - only)")
	name = parts[-1]
	new_len, new_sum = len(data), checksum(data)
	if before:
		bdata = open(before, "rb").read()
		b_len, b_sum, b_name = len(bdata), checksum(bdata), f"the {label}-before version ({rel(before)})"
		if os.path.basename(before).endswith(".pass4-live.lua"):
			b_name = "the pass-4 live version"
	else:
		b_len = b_sum = None
		b_name = "the expected old version"
	base = {
		"ROLE": "", "TARGET": target, "SRCPATH": rel(src_path), "NEW_LEN": new_len, "NEW_SUM": new_sum,
		"TARGET_PARTS": ", ".join(luau_str(p) for p in parts), "TARGET_Q": luau_str(target),
		"BEFORE_LEN": "nil" if b_len is None else b_len, "BEFORE_SUM": "nil" if b_sum is None else b_sum,
		"BEFORE_NAME_Q": luau_str(b_name), "LABEL_Q": luau_str(label), "SRCPATH_Q": luau_str(rel(src_path)),
		"BEFORE_DESC": (f"{b_name}: {b_len} bytes, checksum {b_sum}" if b_len is not None else "the expected old version"),
	}

	def holder_block(n, lens, sums, width):
		return fill(HOLDER, {"N": n, "LENS": ", ".join(map(str, lens)), "SUMS": ", ".join(map(str, sums)),
							 "FMT": "%0" + str(width) + "d"})

	def make_set(max_piece):
		chunks = split_chunks(data, max_piece)
		n = len(chunks)
		if n > 87:
			raise SystemExit("make_payloads: too many pieces (> 87); raise --max-bytes")
		width = max(2, len(str(n)))
		lens = [len(c) for c in chunks]
		sums = [checksum(c) for c in chunks]
		run = f"{name}-{new_len}-{new_sum}-{n}-{checksum(','.join(map(str, lens)).encode())}"
		v = dict(base, RUN_Q=luau_str(run))
		hb = holder_block(n, lens, sums, width)
		chunk_file = lambda i: "%02d_chunk_%0*d_of_%0*d.luau" % (i + 1, width, i, width, n)
		apply_file = "%02d_apply.luau" % (n + 2)
		guards = GUARDS
		files, meta = {}, []

		def emit(file, role, body, kind, expect, extra):
			text = fill(HEAD, dict(v, FILE=file, ROLE=role, FILE_Q=luau_str(file))) + body + TAIL
			files[file] = text
			meta.append(dict({"file": file, "kind": kind, "expect": expect}, **extra))

		emit("00_status.luau", "read-only status (run any time)",
			 hb + fill(STATUS_MAIN, v), "status", r"^OK 00_status\.luau: ",
			 {"does": "Read-only. Reports Edit/Play mode, the target's length + checksum and which version it is, the "
					  "backups in ServerStorage.AuraRNG_Backups, and how many pieces of this set the holder has."})
		emit("01_backup.luau", "step 1: check + back up + prepare the holder",
			 hb + BACKUPS + fill(BACKUP_MAIN, dict(v, GUARDS=guards)), "backup", r"^OK 01_backup\.luau: ",
			 {"does": f"Checks {target} exists (reports its length + checksum and whether it is {b_name}), backs it up "
					  f"once to ServerStorage.AuraRNG_Backups.{name}_<YYYYMMDD>_before_{label} (folder made if missing, "
					  "nothing deleted, copy checked), and prepares ServerStorage.AuraRNG_Install for this payload set.",
			  "onFail": "Read the message: FAIL here changes nothing in the module. STOP = Studio is in Play mode."})
		for i, c in enumerate(chunks, 1):
			lit, enc = encode_chunk(c)
			body = hb + fill(CHUNK_MAIN, dict(v, K=i, N=n, CLEN=len(c), CSUM=sums[i - 1], ENC=enc, DATA=lit,
											  APPLY_Q=luau_str(apply_file)))
			emit(chunk_file(i), f"step {i + 1}: piece {i} of {n}", body, "chunk",
				 r"^OK %s: piece %d/%d stored" % (re.escape(chunk_file(i)), i, n),
				 {"chunk": {"index": i, "of": n, "bytes": len(c), "checksum": sums[i - 1], "encoding": enc},
				  "does": f"Stores piece {i}/{n} of the new source in ServerStorage.AuraRNG_Install after checking its "
						  "own text and every earlier piece.",
				  "onFail": "'arrived changed' = the payload text was altered in transit: send the file again exactly. "
							"'missing or damaged' = run the named earlier payload first. Nothing is installed by this step."})
		emit(apply_file, f"step {n + 2}: join, check, compile, write, read back", hb + BACKUPS + WRITE
			 + fill(APPLY_MAIN, dict(v, GUARDS=guards)), "apply",
			 r"^OK %s: (installed|already installed)" % re.escape(apply_file),
			 {"does": f"Joins the {n} pieces, checks length {new_len} + checksum {new_sum}, checks the live text is in a "
					  "backup, compiles with loadstring, writes with ScriptEditorService:UpdateSourceAsync, reads it back "
					  "with GetEditorSource and checks length + checksum again (on any mismatch it puts the old text back), "
					  "then removes ServerStorage.AuraRNG_Install.",
			  "onFail": "The module is left as it was (or put back, checked). Report the message to Milo."})
		emit("90_install_from_file.luau", "plan B: install from a file picked in a dialog",
			 BACKUPS + WRITE + fill(FROMFILE_MAIN, dict(v, GUARDS=guards)), "alternative",
			 r"^OK 90_install_from_file\.luau: (installed|already installed)",
			 {"does": "Plan B (no big payloads): backs up the live module like 01, opens a file dialog on the Mac "
					  f"(StudioService:PromptImportFileAsync), checks the picked file is {rel(src_path)} ({new_len} bytes, "
					  f"checksum {new_sum}), then compiles, writes, reads back and checks like the apply step. Needs "
					  "someone at the Mac to pick the file. Also the easiest way to install by hand (paste it into the "
					  "Command Bar)."})
		emit("99_rollback.luau", "rollback: put the backup back",
			 BACKUPS + WRITE + fill(ROLLBACK_MAIN, dict(v, GUARDS=guards)), "rollback",
			 r"^OK 99_rollback\.luau: (rolled back|already rolled back)",
			 {"does": "Puts a backup's text back into the module (default: the backup holding "
					  f"{base['BEFORE_DESC']}; else the newest backup this kit made), after saving the current text as "
					  f"{name}_<YYYYMMDD>_replaced_by_rollback unless a backup already holds it. Compiles, writes, reads "
					  "back and checks. Set BACKUP_NAME at the top to pick another backup."})
		order = ["01_backup.luau"] + [chunk_file(i) for i in range(1, n + 1)] + [apply_file]
		return files, meta, order, run, n, lens, sums

	if chunk_bytes:
		piece = chunk_bytes
	else:
		piece = max_bytes - 4600
	for _ in range(40):
		files, meta, order, run, n, lens, sums = make_set(piece)
		worst = 0
		for f, t in files.items():
			raw = len(t.encode("utf-8"))
			js = len(json.dumps(t, ensure_ascii=True)) - 2
			worst = max(worst, raw - max_bytes, js - max_json)
		if worst <= 0:
			break
		if chunk_bytes:
			raise SystemExit(f"make_payloads: --chunk-bytes {chunk_bytes} makes a payload {worst} bytes over the limit")
		piece -= worst + 64
		if piece < 1000:
			raise SystemExit("make_payloads: cannot fit the payloads under the size limits")
	for mrow in meta:
		t = files[mrow["file"]]
		mrow["bytes"] = len(t.encode("utf-8"))
		mrow["jsonBytes"] = len(json.dumps(t, ensure_ascii=True)) - 2
		mrow["step"] = order.index(mrow["file"]) + 1 if mrow["file"] in order else None
	manifest = {
		"about": "AuraRNG Studio install kit: execute_luau payloads (Studio EDIT mode) that install one module file. "
				 "Run 'order' one by one; each must return a line matching its 'expect'. See roblox/install/README.md.",
		"generatedBy": "roblox/install/make_payloads.py",
		"source": {"path": rel(src_path), "bytes": new_len, "checksum": new_sum, "lines": data.count(b"\n")},
		"target": target,
		"label": label,
		"backupName": f"ServerStorage.AuraRNG_Backups.{name}_<YYYYMMDD>_before_{label}",
		"holder": "ServerStorage.AuraRNG_Install (temporary; removed by the apply step)",
		"before": None if b_len is None else {"path": rel(before), "bytes": b_len, "checksum": b_sum, "name": b_name},
		"runId": run,
		"pieces": n,
		"checksumAlgorithm": "x = (x * 131 + byte) % 1000000007 over the raw bytes, x starting at 0",
		"limits": {"maxBytes": max_bytes, "maxJsonBytes": max_json},
		"mode": "Studio Edit mode: execute_luau datamodel_type \"Edit\" (stop Play first), or the Command Bar",
		"resultFormat": "one line: OK|FAIL|STOP <file>: <what happened>",
		"order": order,
		"optional": ["00_status.luau"],
		"alternative": "90_install_from_file.luau",
		"rollback": "99_rollback.luau",
		"payloads": sorted(meta, key=lambda r: r["file"]),
	}
	return files, manifest


def main(argv=None):
	ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
	ap.add_argument("module", help="the module file, e.g. roblox/ReplicatedStorage/AuraFX/TheEnd.lua")
	ap.add_argument("--out", default=os.path.join(HERE, "payloads"))
	ap.add_argument("--target", help="Studio path of the ModuleScript (default ReplicatedStorage.AuraFX.<Name>)")
	ap.add_argument("--label", default="pass5", help="backup name suffix: <Name>_<YYYYMMDD>_before_<label>")
	ap.add_argument("--before", help="the version expected to be live now (default <Name>.pass4-live.lua next to the module; 'none')")
	ap.add_argument("--max-bytes", type=int, default=18000, help="per payload (default 18000: the Mac session's largest proven execute_luau was ~17.9 KB; up to 20000 is fine)")
	ap.add_argument("--max-json", type=int, default=25000)
	ap.add_argument("--chunk-bytes", type=int, default=0, help="force the piece size (tests)")
	ap.add_argument("--allow-cr", action="store_true")
	ap.add_argument("--check", action="store_true", help="exit 1 if --out does not hold exactly these payloads")
	ap.add_argument("--quiet", action="store_true")
	a = ap.parse_args(argv)

	src = a.module
	data = open(src, "rb").read()
	name = os.path.basename(src).split(".")[0]
	target = a.target or f"ReplicatedStorage.AuraFX.{name}"
	before = a.before
	if before is None:
		cand = os.path.join(os.path.dirname(os.path.abspath(src)), f"{name}.pass4-live.lua")
		before = cand if os.path.exists(cand) else None
	elif before.lower() == "none":
		before = None
	files, manifest = build(src, data, target, a.label, before, a.max_bytes, a.max_json, a.chunk_bytes, a.allow_cr)
	mtext = json.dumps(manifest, indent=1, ensure_ascii=False) + "\n"

	if a.check:
		bad = []
		for f, t in files.items():
			p = os.path.join(a.out, f)
			if not os.path.exists(p) or open(p, "rb").read() != t.encode("utf-8"):
				bad.append(f)
		mp = os.path.join(a.out, "manifest.json")
		if not os.path.exists(mp) or open(mp, "rb").read() != mtext.encode("utf-8"):
			bad.append("manifest.json")
		extra = [f for f in (os.listdir(a.out) if os.path.isdir(a.out) else [])
				 if re.fullmatch(r"\d\d_.*\.luau", f) and f not in files]
		if bad or extra:
			print(f"payloads in {rel(a.out)} are STALE for {rel(src)}: {', '.join(bad + extra)}. Run make_payloads.py again.")
			return 1
		print(f"payloads in {rel(a.out)} match {rel(src)} ({len(data)} bytes, checksum {manifest['source']['checksum']})")
		return 0

	os.makedirs(a.out, exist_ok=True)
	for f in os.listdir(a.out):
		if re.fullmatch(r"\d\d_.*\.luau", f) or f == "manifest.json":
			os.remove(os.path.join(a.out, f))
	for f, t in files.items():
		with open(os.path.join(a.out, f), "wb") as fh:
			fh.write(t.encode("utf-8"))
	with open(os.path.join(a.out, "manifest.json"), "wb") as fh:
		fh.write(mtext.encode("utf-8"))

	if not a.quiet:
		s = manifest["source"]
		print(f"{rel(src)}: {s['bytes']} bytes, checksum {s['checksum']} -> {target} ({manifest['pieces']} pieces)")
		if manifest["before"]:
			b = manifest["before"]
			print(f"expected live now: {b['name']} ({b['bytes']} bytes, checksum {b['checksum']})")
		for r in manifest["payloads"]:
			print(f"  {r['file']:<34} {r['bytes']:>6} B  (JSON {r['jsonBytes']:>6} B)  {r['kind']}")
		print(f"run in Studio Edit mode, in this order: {', '.join(manifest['order'])}")
		longest = max(max(len(ln) for ln in t.split("\n")) for t in files.values())
		if longest > 1900:
			print(f"note: a payload has a {longest}-character line: print payloads with `cat`, not a viewer that cuts long lines")
		tex = re.search(rb"local\s+TEX5\s*=\s*\{(.*?)\n\}", data, re.S)
		if tex:
			empty = len(re.findall(rb'=\s*""', tex.group(1)))
			if empty:
				print(f"note: TEX5 has {empty} empty ids (the aura uses its pass-4 fallback textures). After uploading the "
					  "te5 textures: roblox/install/patch_tex5.py, then this script again (see upload_textures.md).")
	return 0


if __name__ == "__main__":
	sys.exit(main())
