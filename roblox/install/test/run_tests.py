#!/usr/bin/env python3
"""Cloud tests for the Studio install kit (roblox/install/). No Roblox needed: the payloads run in the luau CLI against
test/mock_studio.luau, a tiny mock of the Studio APIs they use.

    python3 roblox/install/test/run_tests.py            # all tests (~10 s)
    python3 roblox/install/test/run_tests.py -k fuzz    # only tests whose name contains "fuzz"
    LUAU_BIN=/path/to/luau python3 roblox/install/test/run_tests.py

What is proven here: the pieces reproduce the module byte for byte (checked by dumping the installed source back out of
the mock, not only by checksum), for the live pass-4 module, for a module full of multi-byte UTF-8 and long-bracket
sequences cut at many piece sizes, for a ~150 KB module at the default sizes, and for CR/control bytes (escaped
encoding); every payload is <= 20 KB (<= 25 KB as a JSON string); the failure paths refuse safely (Play mode, missing
target, pieces out of order, a payload altered in transit, a changed module, compile errors, a script editor that stores
something else or fails, a StringValue that truncates, a stale holder, Archivable false, drafts-like clones); the
file-picker plan B; rollback; status is read-only; reruns are idempotent; patch_tex5.py fills TEX5 on a temp copy.
The studio_checks.md snippets compile, use only real Enum items, and (S1-S8) run without a Lua error inside the aura
harness's mock Roblox world next to the real TheEnd.lua (tools/harness); with LUAU_LSP set, luau-lsp type-checks every
payload and snippet against Roblox's API at plugin security (no type errors).

What is NOT proven: anything about the real Studio (that ScriptEditorService, StringValue and loadstring behave there as
in the mock; the mock follows the Mac session's earlier successful installs, which used the same APIs). Never report
an install as tested in Studio from this.
"""
import glob
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

sys.dont_write_bytecode = True  # (importing make_payloads must not leave __pycache__ in the repo)
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.dirname(HERE)
REPO = os.path.abspath(os.path.join(KIT, "..", ".."))
LUAU = os.environ.get("LUAU_BIN", "/home/user/luau-lang/luau/build/luau")
PASS4 = os.path.join(REPO, "roblox", "ReplicatedStorage", "AuraFX", "TheEnd.pass4-live.lua")
PASS5 = os.path.join(REPO, "roblox", "ReplicatedStorage", "AuraFX", "TheEnd.lua")
TARGET = "ReplicatedStorage.AuraFX.TheEnd"


def load(name, path):
	spec = importlib.util.spec_from_file_location(name, path)
	mod = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(mod)
	return mod


MP = load("make_payloads", os.path.join(KIT, "make_payloads.py"))
MOCK_SRC = open(os.path.join(HERE, "mock_studio.luau"), encoding="utf-8").read()
TMP = tempfile.mkdtemp(prefix="install_kit_test_")

# ---------------------------------------------------------------------------------------------------------- test modules


def evil_module() -> bytes:
	"""Valid Luau full of what can break chunking: multi-byte UTF-8 (2, 3 and 4 bytes), every ]=*] level, a long line,
	blank-line runs (pieces that start with a newline), backslashes, quotes, tabs, trailing spaces, no final newline."""
	L = []
	L.append("--[[ 『 THE END 』 — a test module for the install kit: é ñ ü ß 中文 😀 🕛 ]]")
	L.append("--[=====[ ]] ]=] ]==] ]===] ]====] and [[ [=[ [==[ inside a level-5 comment ]=====]")
	L.append("local M = {}")
	L.append('M.closers = { "]]", "]=]", "]==]", "]===]", "]====]", "]=====]", "]======]" }')
	L.append("M.long = [======[")
	L.append("]]  ]=]  ]==]  ]===]  ]====]  ]=====]  (all below level 6) 『』—")
	L.append("]======]")
	L.append('M.escapes = "back\\\\slash \\"quoted\\" \\n not a newline \\t \\226\\128\\148"')
	L.append("M.tabs = \"\t\ttwo tabs\" \t ")
	L.append("   ")
	L.append("")
	L.append("")
	L.append("")
	# a long line of multi-byte characters and bracket runs (longer than the small piece sizes: forces mid-line cuts)
	unit = "『x』—é😀]==]=]]=中"
	L.append('M.longline = "' + unit * 160 + '"')
	for i in range(40):
		L.append(f"M[{i}] = {{ name = \"ring {i} — 『{i}』\", t = [==[ ]] ]=] {'😀' * (i % 5)} ]==], n = {i * 131 % 97} }}")
		if i % 7 == 0:
			L.append("")
			L.append("")
	L.append("M.trail = \"ends with brackets ]=\"")
	L.append("M.trail2 = \"]==\"")
	L.append("return M -- 『 the end 』")
	return "\n".join(L).encode("utf-8")  # no final newline on purpose


def big_module() -> bytes:
	"""~150 KB of valid Luau (default piece sizes give ~10 pieces)."""
	L = ["-- big test module: 『 THE END 』 ~150 KB", "local T = {}"]
	i = 0
	while sum(len(x) + 1 for x in L) < 150000:
		L.append(f"T[{i}] = {{ id = {i}, label = \"part {i} — 『{i % 12}』\", cf = {{ {i * 0.5}, {i % 17}, -{i % 5} }}, s = [[ ]=] ]==] ]] }}")
		if i % 50 == 0:
			L.append("\t-- a section break with a tab and a trailing space ")
		i += 1
	L.append("return T")
	return ("\n".join(L) + "\n").encode("utf-8")


def cr_module() -> bytes:
	return b"-- CRLF lines and a form feed \x0c here\r\nlocal M = {} -- \xe3\x80\x8e x \xe3\x80\x8f\r\nM.a = \"]]\"\r\n\r\nreturn M\r\n"


def bad_module() -> bytes:
	return "-- does not compile 『』\nlocal M = {\nreturn M\n".encode("utf-8")


# ----------------------------------------------------------------------------------------------------------- the runner


def luau_q(s: str) -> str:
	return MP.luau_str(s)


HELPERS = r"""
local function unhex(h)
	return (string.gsub(h, "%x%x", function(x) return string.char(tonumber(x, 16)) end))
end
local function tohex(s)
	return (string.gsub(s, ".", function(c) return string.format("%02x", string.byte(c)) end))
end
SAVED = {}
function step(i, name, code)
	local f, err = loadstring(code, "=" .. name)
	local res
	if not f then
		res = "COMPILE " .. tostring(err)
	else
		local ok, r = pcall(f)
		res = ok and tostring(r) or ("ERROR " .. tostring(r))
	end
	print("@@" .. i .. "\tR\t" .. (string.gsub(res, "\n", "\\n")))
end
function dumpsrc(i, path)
	local s = MOCK.sourceOf(path)
	print("@@" .. i .. "\tS\t" .. (s and tohex(s) or "NIL"))
end
function check(i, fn)
	local ok, r = pcall(fn)
	print("@@" .. i .. "\tC\t" .. (ok and tostring(r) or ("ERROR " .. tostring(r))))
end
"""


class Run:
	def __init__(self, title):
		self.title = title
		self.lines = [MOCK_SRC, HELPERS]
		self.checks = []
		self.results = {}

	def lua(self, code):
		self.lines.append(code)

	def world(self, live: bytes = None, backups_folder=False):
		self.lua('MOCK.makeFolder("ReplicatedStorage", "AuraFX")')
		if live is not None:
			self.lua(f'MOCK.makeModule("ReplicatedStorage.AuraFX", "TheEnd", unhex("{live.hex()}"))')
		if backups_folder:
			self.lua('MOCK.makeFolder("ServerStorage", "AuraRNG_Backups")')

	def run(self, fname, text, expect, desc=None):
		i = len(self.checks)
		self.lines.append(f'step({i}, {luau_q(fname)}, unhex("{text.encode("utf-8").hex()}"))')
		self.checks.append(("R", desc or fname, expect))

	def run_order(self, files, manifest):
		expect = {r["file"]: r["expect"] for r in manifest["payloads"]}
		for f in manifest["order"]:
			self.run(f, files[f], expect[f])

	def src_is(self, path, data: bytes, desc):
		i = len(self.checks)
		self.lines.append(f"dumpsrc({i}, {luau_q(path)})")
		self.checks.append(("S", desc, data))

	def expect(self, expr, desc):
		i = len(self.checks)
		self.lines.append(f"check({i}, function() return {expr} end)")
		self.checks.append(("C", desc, None))

	def go(self):
		script = "\n".join(self.lines) + "\n"
		path = os.path.join(TMP, re.sub(r"\W+", "_", self.title) + ".luau")
		with open(path, "w", encoding="utf-8") as f:
			f.write(script)
		p = subprocess.run([LUAU, path], capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=300)
		got = {}
		for line in p.stdout.splitlines():
			m = re.match(r"@@(\d+)\t([RSC])\t(.*)$", line)
			if m:
				got[int(m.group(1))] = m.group(3)
		fails = []
		if p.returncode != 0:
			fails.append(f"luau exited {p.returncode}: {p.stderr.strip()[-800:]}")
		for i, (kind, desc, want) in enumerate(self.checks):
			if i not in got:
				fails.append(f"#{i} {desc}: no output (script stopped?)")
				continue
			v = got[i]
			if kind == "R":
				if not re.search(want, v):
					fails.append(f"#{i} {desc}: got {v[:600]!r}, want /{want}/")
				self.results[i] = v
			elif kind == "S":
				data = None if v == "NIL" else bytes.fromhex(v)
				if data != want:
					if data is None:
						fails.append(f"#{i} {desc}: no such script")
					else:
						at = next((k for k in range(min(len(data), len(want))) if data[k] != want[k]), min(len(data), len(want)))
						fails.append(f"#{i} {desc}: source differs ({len(data)} bytes vs {len(want)}; first difference at byte {at})")
			elif kind == "C":
				if v != "true":
					fails.append(f"#{i} {desc}: {v}")
		return fails


TESTS = []


def test(fn):
	TESTS.append(fn)
	return fn


def payload_set(module: bytes, before: bytes = None, label="pass5", chunk_bytes=0, allow_cr=False, max_bytes=18000,
				name="TheEnd.lua"):
	d = tempfile.mkdtemp(dir=TMP)
	mp = os.path.join(d, name)
	with open(mp, "wb") as f:
		f.write(module)
	bp = None
	if before is not None:
		bp = os.path.join(d, "TheEnd.pass4-live.lua")
		with open(bp, "wb") as f:
			f.write(before)
	return MP.build(mp, module, TARGET, label, bp, max_bytes, 25000, chunk_bytes, allow_cr)


def sizes_ok(files):
	bad = []
	for f, t in files.items():
		raw = len(t.encode("utf-8"))
		js = len(json.dumps(t, ensure_ascii=True)) - 2
		if raw > 20000 or js > 25000:
			bad.append(f"{f}: {raw} B, JSON {js} B")
	return bad


def backups_with(n_expr, desc):
	return (f'(function() local b = MOCK.path("ServerStorage.AuraRNG_Backups"); local n = 0; if b then for _, c in ipairs(b:GetChildren()) do '
			f'if c:IsA("ModuleScript") then n += 1 end end end; return n {n_expr} end)()', desc)


PASS4_BYTES = open(PASS4, "rb").read()
EVIL = evil_module()
BIG = big_module()
TODAY = time.strftime("%Y%m%d")

# ------------------------------------------------------------------------------------------------------------- the tests


@test
def t_pass4_reference():
	fails = []
	if (len(PASS4_BYTES), MP.checksum(PASS4_BYTES)) != (35000, 489406639):
		fails.append(f"pass-4 live file is {len(PASS4_BYTES)} bytes, checksum {MP.checksum(PASS4_BYTES)}; expected 35000, 489406639")
	return fails


@test
def t_happy_install_rerun_rollback():
	files, man = payload_set(EVIL, PASS4_BYTES)
	fails = sizes_ok(files)
	r = Run("happy")
	r.world(PASS4_BYTES)
	r.run("00_status.luau", files["00_status.luau"], r"pass-4 live version.*backups: no ServerStorage\.AuraRNG_Backups yet.*holder: none")
	r.run_order(files, man)
	r.src_is(TARGET, EVIL, "installed source == evil module, byte for byte")
	r.src_is(f"ServerStorage.AuraRNG_Backups.TheEnd_{TODAY}_before_pass5", PASS4_BYTES, "backup == pass-4 live")
	r.expect(f'MOCK.path("ServerStorage.AuraRNG_Backups.TheEnd_{TODAY}_before_pass5"):GetAttribute("AuraRNG_Checksum") == 489406639', "backup attributes")
	r.expect('MOCK.path("ServerStorage.AuraRNG_Install") == nil', "holder removed after apply")
	r.run("00_status.luau", files["00_status.luau"], r"= the NEW version")
	# the whole sequence again: idempotent, no second backup
	r.lua("SAVED.w = MOCK.writes")
	r.run("01_backup.luau", files["01_backup.luau"], r"No backup needed")
	for f in man["order"][1:-1]:
		r.run(f, files[f], r"^OK .*piece \d+/\d+ stored")
	r.run(man["order"][-1], files[man["order"][-1]], r"already installed")
	r.expect(*backups_with("== 1", "still exactly one backup after a rerun"))
	r.src_is(TARGET, EVIL, "still the evil module after a rerun")
	# rollback to pass 4, the replaced version is kept
	r.run("99_rollback.luau", files["99_rollback.luau"], r"^OK 99_rollback\.luau: rolled back: .* holds TheEnd_\d{8}_before_pass5 .*pass-4 live.*saved as TheEnd_\d{8}_replaced_by_rollback")
	r.src_is(TARGET, PASS4_BYTES, "rolled back to pass 4, byte for byte")
	r.src_is(f"ServerStorage.AuraRNG_Backups.TheEnd_{TODAY}_replaced_by_rollback", EVIL, "the replaced version was saved")
	r.run("99_rollback.luau", files["99_rollback.luau"], r"already rolled back")
	r.expect(*backups_with("== 2", "two backups after the rollback"))
	# status never writes
	r.lua("SAVED.w2 = MOCK.writes")
	r.run("00_status.luau", files["00_status.luau"], r"^OK 00_status\.luau: mode Edit")
	r.expect("MOCK.writes == SAVED.w2", "00_status.luau changes nothing")
	# install again after the rollback: the pass-4 backup is reused, no new backup
	r.run_order(files, man)
	r.expect(*backups_with("== 2", "re-install after rollback reuses the existing pass-4 backup"))
	r.src_is(TARGET, EVIL, "re-installed")
	return fails + r.go()


@test
def t_big_module_default_sizes():
	files, man = payload_set(BIG, PASS4_BYTES)
	fails = sizes_ok(files)
	if man["pieces"] < 8:
		fails.append(f"expected ~10 pieces for {len(BIG)} bytes, got {man['pieces']}")
	biggest = max(r["bytes"] for r in man["payloads"])
	if biggest < 17000:
		fails.append(f"payloads use the 20 KB budget poorly (largest {biggest} B)")
	r = Run("big")
	r.world(PASS4_BYTES, backups_folder=True)
	# things already in the backups folder must be left alone
	r.lua('MOCK.makeFolder("ServerStorage.AuraRNG_Backups", "Old")')
	r.lua('MOCK.makeModule("ServerStorage.AuraRNG_Backups", "TheEnd_20261013_before_auravfx4", "return {} -- pass 3")')
	r.run_order(files, man)
	r.src_is(TARGET, BIG, "big module installed byte for byte")
	r.src_is("ServerStorage.AuraRNG_Backups.TheEnd_20261013_before_auravfx4", b"return {} -- pass 3", "older backup untouched")
	r.expect('MOCK.tree("ServerStorage.AuraRNG_Backups") == "Old:Folder,TheEnd_20261013_before_auravfx4:ModuleScript,TheEnd_' + TODAY + '_before_pass5:ModuleScript"', "backups folder: old things kept, one new backup")
	return fails + r.go()


@test
def t_fuzz_piece_sizes():
	fails = []
	levels, starts_nl, midline, enc = set(), 0, 0, set()
	for cb in (128, 160, 191, 251, 333, 509, 1000, 4093):
		files, man = payload_set(EVIL, PASS4_BYTES, chunk_bytes=cb)
		fails += sizes_ok(files)
		pieces = MP.split_chunks(EVIL, cb)
		if b"".join(pieces) != EVIL:
			fails.append(f"cb {cb}: split pieces do not join back")
		for p in pieces:
			p.decode("utf-8")  # raises if a character was cut
			levels.add(MP.long_bracket_level(p))
			starts_nl += p.startswith(b"\n")
			midline += not p.endswith(b"\n")
		for row in man["payloads"]:
			if row["kind"] == "chunk":
				enc.add(row["chunk"]["encoding"])
		r = Run(f"fuzz_{cb}")
		r.world(PASS4_BYTES)
		r.run_order(files, man)
		r.src_is(TARGET, EVIL, f"piece size {cb}: installed byte for byte ({man['pieces']} pieces)")
		fails += r.go()
	if max(levels) < 3:
		fails.append(f"fuzz never needed a long-bracket level >= 3 (levels {sorted(levels)}): the test module is not hard enough")
	if midline < 10:
		fails.append("too few mid-line cuts (UTF-8 boundary cutting not exercised)")
	return fails


@test
def t_piece_starting_with_newline():
	"""Luau drops the first newline after an opening long bracket: a piece that itself starts with one or two newlines
	(and one that is only newlines) must still come out exact."""
	fails = []
	cb = 200
	mod = b"-- " + "『x』".encode("utf-8") * 20 + b"x" * (cb - 3 - 7 * 20) + b"\n\n\nlocal M = {}\n" + b"\n" * 150 + b"return M\n"
	pieces = MP.split_chunks(mod, cb)
	if not (len(pieces) >= 2 and pieces[1].startswith(b"\n\n")):
		return [f"test module did not produce a piece starting with newlines: {[p[:8] for p in pieces]}"]
	files, man = payload_set(mod, PASS4_BYTES, chunk_bytes=cb)
	r = Run("newline_pieces")
	r.world(PASS4_BYTES)
	r.run_order(files, man)
	r.src_is(TARGET, mod, "pieces starting with newlines installed byte for byte")
	fails += r.go()
	return fails


@test
def t_split_never_cuts_characters():
	fails = []
	data = ("😀『』é" * 400).encode("utf-8")  # no newlines at all
	for cb in range(16, 64):
		ps = MP.split_chunks(data, cb)
		if b"".join(ps) != data:
			fails.append(f"cb {cb}: pieces do not join")
		for p in ps:
			try:
				p.decode("utf-8")
			except UnicodeDecodeError:
				fails.append(f"cb {cb}: a piece cuts a character")
				break
			if len(p) > cb:
				fails.append(f"cb {cb}: piece of {len(p)} bytes")
				break
	# long-bracket level: the closer must first appear exactly at the end
	for s in (b"", b"]", b"]=", b"]==", b"x]]", b"]=]", b"a]==]b]=]", b"]]=]==]===]"):
		lvl = MP.long_bracket_level(s)
		close = b"]" + b"=" * lvl + b"]"
		if (s + close).find(close) != len(s):
			fails.append(f"level {lvl} unsafe for {s!r}")
	return fails


@test
def t_encode_tiny_pieces():
	"""Every piece of the test modules cut at 16..99 bytes, encoded as the payloads do and decoded by Luau's own parser
	(loadstring), comes back byte for byte."""
	fails = []
	lines = [HELPERS, "local function dec(lit) return loadstring('return ' .. lit)() end", "local got = {}"]
	want = []
	for data in (EVIL, cr_module()):
		for cb in range(16, 100, 3):
			for p in MP.split_chunks(data, cb):
				lit, enc = MP.encode_chunk(p)
				lines.append(f'table.insert(got, tohex(dec(unhex("{lit.encode("utf-8").hex()}"))))')
				want.append(p)
	lines.append('for i, h in ipairs(got) do print("@@" .. i .. "\\t" .. h) end')
	path = os.path.join(TMP, "encode_tiny.luau")
	open(path, "w", encoding="utf-8").write("\n".join(lines))
	p = subprocess.run([LUAU, path], capture_output=True, text=True, timeout=300)
	got = {}
	for line in p.stdout.splitlines():
		m = re.match(r"@@(\d+)\t([0-9a-f]*)$", line)
		if m:
			got[int(m.group(1))] = bytes.fromhex(m.group(2))
	if p.returncode != 0:
		fails.append(f"luau: {p.stderr[-500:]}")
	bad = [i for i, w in enumerate(want, 1) if got.get(i) != w]
	if bad:
		fails.append(f"{len(bad)} of {len(want)} pieces did not decode back exactly (first: #{bad[0]} {want[bad[0] - 1]!r})")
	print(f"      ({len(want)} pieces decoded)")
	return fails


@test
def t_play_mode_and_missing_target():
	files, man = payload_set(EVIL, PASS4_BYTES)
	r = Run("guards")
	r.world(None)
	r.lua("SAVED.w = MOCK.writes")
	r.run("01_backup.luau", files["01_backup.luau"], r"^FAIL 01_backup\.luau: ReplicatedStorage\.AuraFX\.TheEnd was not found\. Nothing changed")
	r.run("99_rollback.luau", files["99_rollback.luau"], r"^FAIL 99_rollback\.luau: .*was not found")
	r.run("90_install_from_file.luau", files["90_install_from_file.luau"], r"^FAIL .*was not found")
	r.run(man["order"][-1], files[man["order"][-1]], r"^FAIL .*was not found")
	r.expect("MOCK.writes == SAVED.w", "nothing created when the target is missing")
	r.lua(f'MOCK.makeModule("ReplicatedStorage.AuraFX", "TheEnd", unhex("{PASS4_BYTES.hex()}"))')
	r.lua("MOCK.running = true")
	r.lua("SAVED.w = MOCK.writes")
	for f in ["01_backup.luau", man["order"][1], man["order"][-1], "90_install_from_file.luau", "99_rollback.luau"]:
		r.run(f, files[f], r"^STOP .*Play mode", f"{f} in Play mode")
	r.expect("MOCK.writes == SAVED.w", "nothing changed in Play mode")
	r.run("00_status.luau", files["00_status.luau"], r"mode PLAY")
	r.lua("MOCK.running = false")
	r.src_is(TARGET, PASS4_BYTES, "module untouched")
	# a non-ModuleScript in the way
	r.lua('MOCK.path("ReplicatedStorage.AuraFX.TheEnd").Name = "TheEndOld"')
	r.lua('do local s = Instance.new("Script"); s.Name = "TheEnd"; s.Parent = MOCK.path("ReplicatedStorage.AuraFX") end')
	r.run("01_backup.luau", files["01_backup.luau"], r"is a Script, not a ModuleScript")
	return r.go()


@test
def t_order_and_tampering():
	files, man = payload_set(EVIL, PASS4_BYTES, chunk_bytes=1500)
	o = man["order"]
	n = man["pieces"]
	assert n >= 3
	r = Run("order")
	r.world(PASS4_BYTES)
	r.run(o[2], files[o[2]], r"^FAIL .*no install holder", "piece 2 before 01")
	r.run(o[0], files[o[0]], r"^OK 01_backup")
	r.run(o[2], files[o[2]], r"^FAIL .*piece 1 is missing or damaged: run 02_chunk_01", "piece 2 before piece 1")
	r.run(o[-1], files[o[-1]], r"^FAIL .*piece 1 is missing", "apply with no pieces")
	# altered in transit: tabs turned into spaces, last newline lost, CRLF, one character changed
	t1 = files[o[1]]
	data_start = t1.index("local DATA = ") + 20
	variants = {
		"tabs->spaces": t1[:data_start] + t1[data_start:].replace("\t", "    ", 1),
		"one char": t1[:data_start + 40] + ("X" if t1[data_start + 40] != "X" else "Y") + t1[data_start + 41:],
		"lost blank line": t1[:data_start] + t1[data_start:].replace("\n\n", "\n", 1),
	}
	for k, t in variants.items():
		r.run(o[1], t, r"^FAIL .*arrived changed .*Nothing stored", f"piece 1 altered: {k}")
	r.expect('#MOCK.path("ServerStorage.AuraRNG_Install"):GetChildren() == 0', "no piece stored from altered payloads")
	# CRLF line ends picked up in transit are harmless: Luau reads CR LF inside a long string as LF
	r.run(o[1], t1.replace("\n", "\r\n"), r"^OK .*piece 1/\d+ stored \(", "piece 1 sent with CRLF line ends")
	r.run(o[1], files[o[1]], r"^OK .*piece 1/\d+ stored again")
	r.run(o[3], files[o[3]], r"^FAIL .*piece 2 is missing", "piece 3 skipping 2")
	for f in o[2:-1]:
		r.run(f, files[f], r"^OK ")
	r.run(o[-1], files[o[-1]], r"^OK .*installed")
	r.src_is(TARGET, EVIL, "installed after the detours")
	return r.go()


@test
def t_module_changed_after_backup():
	files, man = payload_set(EVIL, PASS4_BYTES)
	o = man["order"]
	r = Run("changed")
	r.world(PASS4_BYTES)
	for f in o[:-1]:
		r.run(f, files[f], r"^OK ")
	r.lua('MOCK.path("ReplicatedStorage.AuraFX.TheEnd").Source = "return {} -- edited by hand"')
	r.run(o[-1], files[o[-1]], r"^FAIL .*changed after 01_backup\.luau ran.*Nothing changed")
	r.src_is(TARGET, b"return {} -- edited by hand", "hand edit kept")
	r.run(o[0], files[o[0]], r"UNKNOWN version.*Backed up to ServerStorage\.AuraRNG_Backups\.TheEnd_\d{8}_before_pass5_2 .*4/4 pieces stored|UNKNOWN version.*_before_pass5_2")
	r.run(o[-1], files[o[-1]], r"^OK .*installed.*saved as ServerStorage\.AuraRNG_Backups\.TheEnd_\d{8}_before_pass5_2")
	r.src_is(TARGET, EVIL, "installed")
	r.src_is(f"ServerStorage.AuraRNG_Backups.TheEnd_{TODAY}_before_pass5_2", b"return {} -- edited by hand", "the hand edit was backed up")
	# rollback default = the pass-4 live backup, not the newest
	r.run("99_rollback.luau", files["99_rollback.luau"], r"rolled back: .*TheEnd_\d{8}_before_pass5 \(35000 bytes")
	r.src_is(TARGET, PASS4_BYTES, "rollback went to pass 4")
	# BACKUP_NAME picks a specific one
	rb = files["99_rollback.luau"].replace("local BACKUP_NAME = nil", f'local BACKUP_NAME = "TheEnd_{TODAY}_before_pass5_2"')
	r.run("99_rollback.luau", rb, r"rolled back: .*TheEnd_\d{8}_before_pass5_2", "rollback with BACKUP_NAME")
	r.src_is(TARGET, b"return {} -- edited by hand", "BACKUP_NAME honoured")
	rb2 = files["99_rollback.luau"].replace("local BACKUP_NAME = nil", 'local BACKUP_NAME = "Nope"')
	r.run("99_rollback.luau", rb2, r"^FAIL .*no ModuleScript named Nope")
	return r.go()


@test
def t_compile_error():
	bad = bad_module()
	files, man = payload_set(bad, PASS4_BYTES)
	r = Run("compile")
	r.world(PASS4_BYTES)
	for f in man["order"][:-1]:
		r.run(f, files[f], r"^OK ")
	r.run(man["order"][-1], files[man["order"][-1]], r"^FAIL .*does not compile: TheEnd:\d+: .*Nothing changed.*holder is kept")
	r.lua("SAVED.ls = loadstring")
	r.run(man["order"][-1], files[man["order"][-1]].replace("local FILE =", "local loadstring = nil\nlocal FILE ="), r"^FAIL .*loadstring is not available here.*Nothing changed", "apply without loadstring")
	r.src_is(TARGET, PASS4_BYTES, "module unchanged")
	r.expect('MOCK.path("ServerStorage.AuraRNG_Install") ~= nil', "holder kept")
	return r.go()


@test
def t_editor_misbehaves():
	files, man = payload_set(EVIL, PASS4_BYTES)
	o = man["order"]
	r = Run("editor")
	r.world(PASS4_BYTES)
	for f in o[:-1]:
		r.run(f, files[f], r"^OK ")
	# 1) the editor stores the new text without its last byte; the old text goes back fine
	r.lua(f"MOCK.updateFilter = function(s) if #s == {len(EVIL)} then return string.sub(s, 1, -2) end return s end")
	r.run(o[-1], files[o[-1]], r"^FAIL .*read back different \(read back %d bytes.*first difference at byte %d\)\. The previous version is in place \(checked\)" % (len(EVIL) - 1, len(EVIL)))
	r.src_is(TARGET, PASS4_BYTES, "old text put back")
	# 2) the editor drops the last newline of everything: the old text cannot be put back exactly -> warning
	r.lua('MOCK.updateFilter = function(s) return s .. " " end')
	r.run(o[-1], files[o[-1]], r"^FAIL .*WARNING: the previous version could not be put back: run 99_rollback")
	r.lua("MOCK.updateFilter = nil")
	# 3) UpdateSourceAsync errors
	r.lua(f'MOCK.path("ReplicatedStorage.AuraFX.TheEnd").Source = unhex("{PASS4_BYTES.hex()}")')
	r.lua("MOCK.updateFails = true")
	r.run(o[-1], files[o[-1]], r"^FAIL .*UpdateSourceAsync failed: .*The previous version is in place \(checked\)")
	r.src_is(TARGET, PASS4_BYTES, "unchanged after an UpdateSourceAsync error")
	r.lua("MOCK.updateFails = false")
	r.run(o[-1], files[o[-1]], r"^OK .*installed")
	r.src_is(TARGET, EVIL, "installed once the editor behaves")
	return r.go()


@test
def t_stringvalue_truncates():
	files, man = payload_set(EVIL, PASS4_BYTES)
	o = man["order"]
	r = Run("stringvalue")
	r.world(PASS4_BYTES)
	r.run(o[0], files[o[0]], r"^OK ")
	r.lua("MOCK.valueFilter = function(s) return string.sub(s, 1, 1000) end")
	r.run(o[1], files[o[1]], r"^FAIL .*the StringValue changed piece 1 \(1000 bytes stored")
	r.lua("MOCK.valueFilter = nil")
	r.run(man["order"][-1], files[man["order"][-1]], r"^FAIL .*piece 1 is missing or damaged")
	r.src_is(TARGET, PASS4_BYTES, "nothing installed")
	return r.go()


@test
def t_stale_holder_from_another_set():
	fa, ma = payload_set(EVIL, PASS4_BYTES)
	fb, mb = payload_set(BIG, PASS4_BYTES)
	r = Run("stale")
	r.world(PASS4_BYTES)
	r.run(ma["order"][0], fa[ma["order"][0]], r"^OK ")
	r.run(ma["order"][1], fa[ma["order"][1]], r"^OK ")
	r.run(mb["order"][1], fb[mb["order"][1]], r"^FAIL .*no install holder for this payload set")
	r.run("00_status.luau", fb["00_status.luau"], r"from ANOTHER payload set")
	r.run(mb["order"][0], fb[mb["order"][0]], r"Already backed up as .*cleared 1 old pieces")
	for f in mb["order"][1:]:
		r.run(f, fb[f], r"^OK ")
	r.src_is(TARGET, BIG, "set B installed")
	r.expect(*backups_with("== 1", "one backup shared by both sets"))
	return r.go()


@test
def t_backup_edge_cases():
	files, man = payload_set(EVIL, PASS4_BYTES)
	fails = []
	for title, setup in (("drafts-like clone", "MOCK.cloneDropsSource = true"),
						 ("archivable false", 'MOCK.path("ReplicatedStorage.AuraFX.TheEnd").Archivable = false')):
		r = Run("backup_" + title)
		r.world(PASS4_BYTES)
		r.lua(setup)
		r.run("01_backup.luau", files["01_backup.luau"], r"Backed up to .*\(text checked\)", title)
		r.src_is(f"ServerStorage.AuraRNG_Backups.TheEnd_{TODAY}_before_pass5", PASS4_BYTES, f"{title}: backup holds pass 4")
		fails += r.go()
	r = Run("holder_in_the_way")
	r.world(PASS4_BYTES)
	r.lua('do local v = Instance.new("StringValue"); v.Name = "AuraRNG_Install"; v.Parent = game:GetService("ServerStorage") end')
	r.run("01_backup.luau", files["01_backup.luau"], r"^FAIL .*AuraRNG_Install exists but is a StringValue")
	fails += r.go()
	return fails


@test
def t_file_picker_plan_b():
	files, man = payload_set(EVIL, PASS4_BYTES)
	t = files["90_install_from_file.luau"]
	r = Run("picker")
	r.world(PASS4_BYTES)
	r.lua("MOCK.pickFile = nil")
	r.run("90", t, r"^STOP .*no file was picked\. Nothing installed \(backup TheEnd_\d{8}_before_pass5 kept\)")
	r.lua(f'MOCK.pickFile = {{ name = "TheEnd.pass4-live.lua", data = unhex("{PASS4_BYTES.hex()}") }}')
	r.run("90", t, r"^FAIL .*the picked file TheEnd\.pass4-live\.lua is 35000 bytes.*Nothing installed")
	r.src_is(TARGET, PASS4_BYTES, "wrong file: unchanged")
	r.lua(f'MOCK.pickFile = {{ name = "TheEnd.lua", data = unhex("{EVIL.hex()}") }}')
	r.run("90", t, r"^OK .*installed from TheEnd\.lua: .*saved as ServerStorage\.AuraRNG_Backups\.TheEnd_\d{8}_before_pass5")
	r.src_is(TARGET, EVIL, "installed from the picked file")
	r.run("90", t, r"^OK .*already installed")
	r.expect(*backups_with("== 1", "one backup"))
	return r.go()


@test
def t_cr_and_control_bytes():
	fails = []
	cr = cr_module()
	try:
		payload_set(cr, PASS4_BYTES)
		fails.append("a CRLF module was accepted without --allow-cr")
	except SystemExit as e:
		if "CR" not in str(e):
			fails.append(f"unexpected refusal text: {e}")
	for cb in (0, 20, 33):
		files, man = payload_set(cr, PASS4_BYTES, allow_cr=True, chunk_bytes=cb)
		encs = {r["chunk"]["encoding"] for r in man["payloads"] if r["kind"] == "chunk"}
		if "escaped strings" not in encs:
			fails.append(f"cb {cb}: CR pieces were not escaped ({encs})")
		r = Run(f"cr_{cb}")
		r.world(PASS4_BYTES)
		r.run_order(files, man)
		r.src_is(TARGET, cr, f"cb {cb}: CRLF + form feed module installed byte for byte")
		fails += r.go()
	for data, word in ((b"\xef\xbb\xbfreturn 1\n", "BOM"), (b"return 1\x00\n", "NUL"), (b"return '\xff'\n", "UTF-8"), (b"", "empty")):
		try:
			payload_set(data, PASS4_BYTES)
			fails.append(f"accepted a module with {word}")
		except SystemExit as e:
			if word not in str(e):
				fails.append(f"{word}: refusal says {e}")
	return fails


@test
def t_no_before_file():
	files, man = payload_set(EVIL, None)
	r = Run("nobefore")
	r.world(PASS4_BYTES)
	r.run("01_backup.luau", files["01_backup.luau"], r"UNKNOWN version.*Backed up to")
	for f in man["order"][1:]:
		r.run(f, files[f], r"^OK ")
	r.run("99_rollback.luau", files["99_rollback.luau"], r"rolled back: .*TheEnd_\d{8}_before_pass5 \(35000 bytes")
	r.src_is(TARGET, PASS4_BYTES, "newest kit backup restored when no before-file is known")
	return r.go()


@test
def t_rollback_without_backups():
	files, man = payload_set(EVIL, PASS4_BYTES)
	r = Run("nobackups")
	r.world(PASS4_BYTES)
	r.run("99_rollback.luau", files["99_rollback.luau"], r"^FAIL .*no ServerStorage\.AuraRNG_Backups.*Nothing changed")
	r.lua('MOCK.makeFolder("ServerStorage", "AuraRNG_Backups")')
	r.run("99_rollback.luau", files["99_rollback.luau"], r"^FAIL .*no backup of ReplicatedStorage\.AuraFX\.TheEnd found")
	return r.go()


@test
def t_cli_check_and_determinism():
	fails = []
	d = tempfile.mkdtemp(dir=TMP)
	mod = os.path.join(d, "TheEnd.lua")
	shutil.copy(PASS4, os.path.join(d, "TheEnd.pass4-live.lua"))
	with open(mod, "wb") as f:
		f.write(EVIL)
	out = os.path.join(d, "payloads")
	cli = [sys.executable, os.path.join(KIT, "make_payloads.py")]
	p = subprocess.run(cli + [mod, "--out", out], capture_output=True, text=True)
	if p.returncode != 0:
		return [f"CLI failed: {p.stderr}"]
	first = {f: open(os.path.join(out, f), "rb").read() for f in os.listdir(out)}
	man = json.load(open(os.path.join(out, "manifest.json")))
	if man["before"] is None or man["before"]["checksum"] != 489406639:
		fails.append("the CLI did not pick up TheEnd.pass4-live.lua next to the module as --before")
	if any(os.path.isabs(str(v)) for v in (man["source"]["path"], (man["before"] or {}).get("path", ""))):
		fails.append("absolute paths in the manifest")
	with open(os.path.join(out, "05_stale.luau"), "w") as f:
		f.write("-- left over")
	subprocess.run(cli + [mod, "--out", out, "--quiet"], check=True)
	second = {f: open(os.path.join(out, f), "rb").read() for f in os.listdir(out)}
	if first != second:
		fails.append("two runs gave different payloads (or a stale NN_*.luau survived)")
	if subprocess.run(cli + [mod, "--out", out, "--check"], capture_output=True).returncode != 0:
		fails.append("--check failed right after generating")
	with open(mod, "ab") as f:
		f.write(b"\n-- changed")
	if subprocess.run(cli + [mod, "--out", out, "--check"], capture_output=True).returncode != 1:
		fails.append("--check did not notice a changed module")
	return fails


@test
def t_real_modules():
	"""The live pass-4 module (installing it over itself = 'already installed'), and TheEnd.lua when it exists."""
	fails = []
	files, man = payload_set(PASS4_BYTES, PASS4_BYTES)
	fails += sizes_ok(files)
	r = Run("pass4_self")
	r.world(PASS4_BYTES)
	r.run("01_backup.luau", files["01_backup.luau"], r"35000 bytes, checksum 489406639: the NEW version\. No backup needed")
	for f in man["order"][1:-1]:
		r.run(f, files[f], r"^OK ")
	r.run(man["order"][-1], files[man["order"][-1]], r"already installed")
	fails += r.go()
	# pass 4 installed over a different live text, byte for byte
	r = Run("pass4_over_other")
	r.world(b"return {} -- some other version\n")
	r.run_order(files, man)
	r.src_is(TARGET, PASS4_BYTES, "pass-4 module installed byte for byte (3 pieces)")
	fails += r.go()
	if os.path.exists(PASS5):
		data = open(PASS5, "rb").read()
		files, man = payload_set(data, PASS4_BYTES)
		fails += sizes_ok(files)
		r = Run("pass5")
		r.world(PASS4_BYTES)
		r.run_order(files, man)
		r.src_is(TARGET, data, f"TheEnd.lua ({len(data)} bytes, {man['pieces']} pieces) installed byte for byte")
		r.run("99_rollback.luau", files["99_rollback.luau"], r"^OK .*rolled back")
		r.src_is(TARGET, PASS4_BYTES, "rolled back to pass 4")
		fails += r.go()
		print(f"      (TheEnd.lua: {len(data)} bytes, checksum {MP.checksum(data)}, {man['pieces']} pieces)")
	else:
		print("      (TheEnd.lua does not exist yet: only pass 4 tested)")
	return fails


@test
def t_patch_tex5():
	"""patch_tex5.py on temp copies: record ids (upload_image JSON + NAME=ID), patch TEX5, idempotent, nothing else
	changes, conflicts refused, uploaded.md written, then the patched module installs."""
	script = os.path.join(KIT, "patch_tex5.py")
	if not os.path.exists(script):
		return ["patch_tex5.py missing"]
	fails = []
	d = tempfile.mkdtemp(dir=TMP)
	te5 = os.path.join(d, "te5")
	for g in ("particles", "surfaces"):
		os.makedirs(os.path.join(te5, g))
		shutil.copy(os.path.join(REPO, "textures", "te5", g, "manifest.json"), os.path.join(te5, g, "manifest.json"))
		# (the PNGs too: patch_tex5 checks flipbook textures are 1024x1024 before recording)
		for png in glob.glob(os.path.join(REPO, "textures", "te5", g, "*.png")):
			shutil.copy(png, os.path.join(te5, g, os.path.basename(png)))
	entries = []
	for g in ("particles", "surfaces"):
		for e in json.load(open(os.path.join(te5, g, "manifest.json"))):
			entries.append(e)
	if os.path.exists(PASS5) and b"TEX5" in open(PASS5, "rb").read():
		module = open(PASS5, "rb").read()
	else:
		module = TEX5_FIXTURE.encode("utf-8")
	mod = os.path.join(d, "TheEnd.lua")
	with open(mod, "wb") as f:
		f.write(module)
	run = lambda *a: subprocess.run([sys.executable, script, *a], capture_output=True, text=True)
	common = ["--manifests", te5, "--module", mod, "--uploaded-md", os.path.join(te5, "uploaded.md")]
	# record half from an upload_image result (URL keys), the rest as NAME=ID in different spellings
	ids = {e["name"]: str(100000000000000 + i) for i, e in enumerate(entries)}
	half = entries[: len(entries) // 2]
	up = {f"http://127.0.0.1:8765/{('particles' if e['repoPath'].split('/')[-2] == 'particles' else 'surfaces')}/{e['file']}":
		  f"rbxassetid://{ids[e['name']]}" for e in half}
	upf = os.path.join(d, "upload.json")
	json.dump(up, open(upf, "w"))
	p = run("record", "--json", upf, *common)
	if p.returncode != 0:
		fails.append(f"record --json failed: {p.stdout} {p.stderr}")
	rest = entries[len(entries) // 2:]
	pairs = []
	for k, e in enumerate(rest):
		key = (e["file"], e["name"], e["texKey"])[k % 3]
		val = ids[e["name"]] if k % 2 else f"rbxassetid://{ids[e['name']]}"
		pairs.append(f"{key}={val}")
	p = run("record", *pairs, *common)
	if p.returncode != 0:
		fails.append(f"record NAME=ID failed: {p.stdout} {p.stderr}")
	for g in ("particles", "surfaces"):
		for e in json.load(open(os.path.join(te5, g, "manifest.json"))):
			if e.get("uploadedId") != f"rbxassetid://{ids[e['name']]}":
				fails.append(f"{e['name']}: uploadedId {e.get('uploadedId')!r}")
	# a conflicting id is refused without --force; the same id again is fine
	e0 = entries[0]
	p = run("record", f"{e0['name']}=999999999999", *common)
	if p.returncode == 0:
		fails.append("a conflicting id was accepted without --force")
	p = run("record", f"{e0['name']}={ids[e0['name']]}", *common)
	if p.returncode != 0:
		fails.append(f"recording the same id again failed: {p.stdout}")
	if not os.path.exists(os.path.join(te5, "uploaded.md")) or ids[e0["name"]] not in open(os.path.join(te5, "uploaded.md")).read():
		fails.append("uploaded.md not written")
	# patch
	p = run("patch", *common)
	if p.returncode != 0:
		fails.append(f"patch failed: {p.stdout} {p.stderr}")
	patched = open(mod, "rb").read()
	for e in entries:
		if f'{e["texKey"]} = "rbxassetid://{ids[e["name"]]}"'.encode() not in patched:
			fails.append(f"TEX5.{e['texKey']} not filled")
	# only the TEX5 values changed
	strip = lambda b: re.sub(rb'(\w+ = )"(rbxassetid://\d+)?"', rb'\1""', b)
	if strip(patched) != strip(module):
		fails.append("patch changed more than the TEX5 values")
	p = run("patch", *common)
	if "0 changed" not in p.stdout:
		fails.append(f"second patch was not a no-op: {p.stdout}")
	if run("patch", "--check", *common).returncode != 0:
		fails.append("patch --check fails after patching")
	# the patched module installs byte for byte
	files, man = payload_set(patched, PASS4_BYTES)
	r = Run("tex5_install")
	r.world(PASS4_BYTES)
	r.run_order(files, man)
	r.src_is(TARGET, patched, "patched module installed")
	fails += r.go()
	return fails


@test
def t_doc_snippets():
	"""Every ```lua snippet in the kit's docs compiles (luau), and every Enum.X.Y they use exists in Roblox's API data."""
	fails, snippets = [], []
	for doc in ("studio_checks.md", "README.md", "upload_textures.md"):
		text = open(os.path.join(KIT, doc), encoding="utf-8").read()
		for k, m in enumerate(re.finditer(r"```lua\n(.*?)```", text, re.S)):
			snippets.append((f"{doc}#{k + 1}", m.group(1)))
	if len(snippets) < 8:
		fails.append(f"expected the 8 studio_checks.md snippets, found {len(snippets)}")
	lines = [HELPERS]
	for i, (name, code) in enumerate(snippets):
		lines.append(f'do local f, e = loadstring(unhex("{code.encode("utf-8").hex()}"), {luau_q(name)}); '
					 f'print("@@{i}\\t" .. (f and "ok" or tostring(e))) end')
	path = os.path.join(TMP, "snippets.luau")
	open(path, "w", encoding="utf-8").write("\n".join(lines))
	p = subprocess.run([LUAU, path], capture_output=True, text=True, timeout=120)
	got = dict(re.findall(r"@@(\d+)\t(.*)", p.stdout))
	for i, (name, _) in enumerate(snippets):
		if got.get(str(i)) != "ok":
			fails.append(f"{name} does not compile: {got.get(str(i))}")
	api = open(os.path.join(REPO, "tools", "harness", "api", "roblox_api.luau"), encoding="utf-8").read()
	enums = {}
	for m in re.finditer(r'^\t\t(\w+) = "([^"]*)",?$', api[api.index("\tenums = {"):], re.M):
		enums[m.group(1)] = {kv.split("=")[0] for kv in m.group(2).split(",") if kv}
	texts = [c for _, c in snippets] + list(payload_set(EVIL, PASS4_BYTES)[0].values())
	used = set()
	for t in texts:
		used |= set(re.findall(r"Enum\.(\w+)\.(\w+)", t))
	for e, item in sorted(used):
		if e not in enums or item not in enums[e]:
			fails.append(f"Enum.{e}.{item} is not in the Roblox API data")
	print(f"      ({len(snippets)} snippets compiled, {len(used)} enum items checked)")
	return fails


@test
def t_typecheck():
	"""(only with LUAU_LSP set) luau-lsp's static check of every payload and docs snippet against Roblox's API at plugin
	security (what execute_luau and the Command Bar run with): no type errors."""
	lsp = os.environ.get("LUAU_LSP")
	if not lsp:
		print("      (skipped: set LUAU_LSP=/path/to/luau-lsp to type-check the payloads and snippets)")
		return []
	defs = os.environ.get("DEFS")
	if not defs:
		for c in ("../src/scripts", "../scripts", "scripts"):
			cand = os.path.join(os.path.dirname(lsp), c, "globalTypes.PluginSecurity.d.luau")
			if os.path.exists(cand):
				defs = cand
				break
	if not defs:
		return ["no globalTypes.PluginSecurity.d.luau found next to luau-lsp (set DEFS)"]
	d = tempfile.mkdtemp(dir=TMP)
	files = {}
	pf, _ = payload_set(EVIL, PASS4_BYTES)
	for f, t in pf.items():
		files[f] = t
	text = open(os.path.join(KIT, "studio_checks.md"), encoding="utf-8").read()
	for k, m in enumerate(re.finditer(r"```lua\n(.*?)```", text, re.S), 1):
		files[f"S{k}.luau"] = m.group(1)
	for f, t in files.items():
		open(os.path.join(d, f), "w", encoding="utf-8").write(t)
	json.dump({"name": "Game", "className": "DataModel", "children": [
		{"name": "ReplicatedStorage", "className": "ReplicatedStorage", "children": [{"name": "AuraFX", "className": "ModuleScript",
			"children": [{"name": "TheEnd", "className": "ModuleScript"}]}]},
		{"name": "ServerStorage", "className": "ServerStorage"}, {"name": "Workspace", "className": "Workspace"},
		{"name": "Players", "className": "Players"}, {"name": "Lighting", "className": "Lighting"}]},
		open(os.path.join(d, "sourcemap.json"), "w"))
	fails = []
	for f in sorted(files):
		p = subprocess.run([lsp, "analyze", "--platform=roblox", f"--definitions=@roblox={os.path.abspath(defs)}",
							"--sourcemap=sourcemap.json", "--formatter=plain", f], cwd=d, capture_output=True, text=True)
		errs = [ln for ln in (p.stdout + p.stderr).splitlines() if "TypeError" in ln]
		fails += [f"{f}: {e}" for e in errs]
	print(f"      ({len(files)} files type-checked)")
	return fails


@test
def t_snippets_in_harness():
	"""studio_checks.md's Client snippets S5 (bench), S2 (inspect), S7 (Highlight) and S6 (stop) run for real inside the
	aura harness's mock Roblox world (tools/harness), next to the real TheEnd.lua worn by Player1: no errors, the bench
	builds low/high on a clone and an R6 body, the inspect checks come out right, and nothing is left behind."""
	if not os.path.exists(PASS5):
		print("      (skipped: TheEnd.lua does not exist yet)")
		return []
	md = open(os.path.join(KIT, "studio_checks.md"), encoding="utf-8").read()
	sn = {}
	for code in re.findall(r"```lua\n(.*?)```", md, re.S):
		for key, marker in (("S2", "What THE END is doing right now"), ("S5", "THE END on stand-in wearers"),
							("S6", "Remove the bench stand-ins"), ("S7", "silver-tone Highlight off or on")):
			if marker in code:
				sn[key] = code
	if len(sn) != 4:
		return [f"could not find S2/S5/S6/S7 in studio_checks.md (found {sorted(sn)})"]
	src = open(PASS5, encoding="utf-8").read()
	body = src[:src.rstrip().rfind("return End")]

	def fn(name, code, subs):
		for a, b in subs:
			if a not in code:
				raise AssertionError(f"{name}: {a!r} not in the snippet")
			code = code.replace(a, b)
		return f"local function {name}()\n{code}\nend\n"
	driver = """
task.spawn(function()
	task.wait(3)
	print("BENCH> " .. tostring(BENCH()))
	task.wait(6)
	print("INSPECT> " .. tostring(INSPECT()))
	print("INSPECTME> " .. tostring(INSPECTME()))
	print("HIGHLIGHT> " .. tostring(HIGHLIGHT()))
	task.wait(0.5)
	print("STOP> " .. tostring(STOPB()))
	task.wait(1)
	local left = 0
	for _, o in ipairs(workspace:GetDescendants()) do
		if string.match(o.Name, "^TheEndBench") or o.Name == "TheEnd_TheEndBench1" then left += 1 end
	end
	print("LEFT> " .. left)
end)
"""
	fails = []
	for quality, rig, is_local, parts in (("low", "clone", "false", 149), ("high", "r6", "true", 360)):
		d = os.path.join(tempfile.mkdtemp(dir=TMP), "h")
		os.makedirs(d)
		text = (body + "\n-- test: studio_checks.md snippets driven inside the harness\n"
				+ fn("BENCH", sn["S5"], [("local SECONDS = 60", "local SECONDS = 14"), ('local QUALITY = "low"', f'local QUALITY = "{quality}"'),
										 ('local RIG = "clone"', f'local RIG = "{rig}"'), ("local IS_LOCAL = false", f"local IS_LOCAL = {is_local}")])
				+ fn("INSPECT", sn["S2"], [("local WHO = nil", 'local WHO = "TheEndBench1"'), ("local SAMPLE = 2", "local SAMPLE = 0.5")])
				+ fn("INSPECTME", sn["S2"], [("local SAMPLE = 2", "local SAMPLE = 0.5")])
				+ fn("HIGHLIGHT", sn["S7"], []) + fn("STOPB", sn["S6"], []) + driver + "\nreturn End\n")
		mod = os.path.join(d, "TheEnd.lua")
		open(mod, "w", encoding="utf-8").write(text)
		out = os.path.join(d, "out")
		p = subprocess.run([sys.executable, os.path.join(REPO, "tools", "harness", "run_aura.py"), mod, "--scenarios",
							"day_idle,night_idle", "--snapshot", "none", "--out", out], capture_output=True, text=True, timeout=600)
		tag = f"{quality}/{rig}/isLocal {is_local}"
		if p.returncode != 0:
			fails.append(f"{tag}: harness exit {p.returncode}: {p.stdout.strip().splitlines()[-1:]}")
		rep = open(os.path.join(out, "report.json"), encoding="utf-8").read()
		prints = {}
		for k, v in re.findall(r'"(BENCH|INSPECT|INSPECTME|HIGHLIGHT|STOP|LEFT)> ((?:[^"\\]|\\.)*)"', rep):
			prints.setdefault(k, []).append(json.loads('"' + v + '"'))
		want = {
			"BENCH": rf"^bench: 1 stand-in\(s\) \({rig}, quality {quality}, isLocal {is_local}\)",
			"INSPECT": rf"^TheEnd_TheEndBench1: {parts} parts.*clock on the far side: true, moon left: true, void right: true \| grade: "
					   + ("on" if is_local == "true" else "none"),
			"INSPECTME": r"^TheEnd_Player1: 360 parts.*clock on the far side: true, moon left: true, void right: true",
			"HIGHLIGHT": r"^TheEndTone OFF on 2 aura\(s\)",
			"STOP": r"^removed 1 stand-in\(s\)$",
			"LEFT": r"^0$",
		}
		for k, rx in want.items():
			got = prints.get(k, [])
			if len(got) != 2 or not all(re.search(rx, g) for g in got):
				fails.append(f"{tag}: {k} printed {got!r}, want 2x /{rx}/")
		md_rep = open(os.path.join(out, "report.md"), encoding="utf-8").read()
		if "Nothing left behind in any scenario" not in md_rep:
			fails.append(f"{tag}: the harness found leftovers after destroy")
	# the other snippets: S1 (every VIEW, no equip: the mock has no AuraRemotes), S3 (every MODE), S4, S8. The harness
	# drives its own camera, so only "runs without a Lua error and says the right thing" is checked here.
	codes = re.findall(r"```lua\n(.*?)```", md, re.S)
	s1 = next(c for c in codes if "Set the time, (optionally) equip THE END" in c)
	s3 = next(c for c in codes if "Move so the aura has to follow" in c)
	s4 = next(c for c in codes if "Swing the camera round the wearer" in c)
	s8 = next(c for c in codes if "Set / clear THE END's CONFIG overrides" in c)
	parts, calls = [], []
	for v in ("studio", "owner", "owner25", "side", "high", "far", "first", "clock", "void", "reset"):
		parts.append(fn(f"SHOT_{v}", s1, [('local VIEW = "studio"', f'local VIEW = "{v}"'), ("local WAIT = 1.5", "local WAIT = 0.2")]))
		calls.append((f"SHOT_{v}", r"^(view |no (clock|void) part found)"))
	for mode in ("walk", "fast", "jump", "sit", "air", "stop"):
		parts.append(fn(f"MOVE_{mode}", s3, [('local MODE = "walk"', f'local MODE = "{mode}"')]))
		calls.append((f"MOVE_{mode}", r"^(walk|fast|jump|sitting|held|stopped)"))
	parts.append(fn("ORBIT", s4, [("local SECONDS = 6", "local SECONDS = 2")]))
	calls.append(("ORBIT", r"^orbiting at 120"))
	parts.append(fn("FLAGS", s8, [("local SET = {", "local SET = { DEBUG = true, USE_FILM_MESHES = true,")]))
	calls.append(("FLAGS", r"^TheEnd overrides: DEBUG=true, USE_FILM_MESHES=true$"))
	parts.append(fn("FLAGS2", s8, [("local CLEAR = {}", 'local CLEAR = { "DEBUG" }')]))
	calls.append(("FLAGS2", r"^TheEnd overrides: USE_FILM_MESHES=true$"))
	parts.append(fn("FLAGSCLR", s8, [("local CLEAR_ALL = false", "local CLEAR_ALL = true")]))
	calls.append(("FLAGSCLR", r"^TheEnd overrides: none"))
	rep = ""
	for group in ([c for c in calls if c[0].startswith("SHOT_")], [c for c in calls if not c[0].startswith("SHOT_")]):
		drv = "task.spawn(function()\n\ttask.wait(1)\n" + "".join(
			f'\tdo local ok, r = pcall({c}); print("{c}> " .. (ok and "" or "ERROR ") .. tostring(r)) end\n' for c, _ in group) + "end)\n"
		d = os.path.join(tempfile.mkdtemp(dir=TMP), "h")
		os.makedirs(d)
		mod = os.path.join(d, "TheEnd.lua")
		open(mod, "w", encoding="utf-8").write(body + "".join(parts) + drv + "\nreturn End\n")
		out = os.path.join(d, "out")
		p = subprocess.run([sys.executable, os.path.join(REPO, "tools", "harness", "run_aura.py"), mod, "--scenarios", "day_idle",
							"--snapshot", "none", "--out", out], capture_output=True, text=True, timeout=600)
		if p.returncode != 0:
			fails.append(f"{group[0][0]}..: harness exit {p.returncode} (errors: see {out}/report.md)")
		rep += open(os.path.join(out, "report.json"), encoding="utf-8").read()
	for c, rx in calls:
		m = re.search(r'"' + c + r'> ((?:[^"\\]|\\.)*)"', rep)
		got = json.loads('"' + m.group(1) + '"') if m else None
		if got is None or got.startswith("ERROR") or not re.search(rx, got):
			fails.append(f"{c}: printed {got!r}, want /{rx}/")
	return fails


# a stand-in module with the spec's TEX5 block (used when TheEnd.lua does not exist yet)
TEX5_FIXTURE = """-- stand-in module with the pass-5 spec's TEX5 block (spec section 16.1)
local TEX = { glow = "rbxassetid://88172507927269" }
local TEX5 = { -- te5 uploads (textures/te5/); "" until uploaded from the Mac
	dialInlay = "", subdial = "", accretion = "", galaxyFloor = "", galaxyArms = "", galaxyCore = "", engraving = "",
	halo = "", hairspring = "", stream = "", ribbon = "",
	shards5 = "", smoke5 = "", mote = "", glint5 = "", bokeh = "", streak5 = "", ash5 = "",
}
local TEX5_LAYOUT = { shards5 = { "Grid4x4", "Loop" }, smoke5 = { "Grid4x4", "OneShot" }, ash5 = { "Grid2x2", "Random" } }
local note = "mote = \\"\\" in a string is not TEX5" -- mote = "" in a comment is not TEX5 either
return { TEX = TEX, TEX5 = TEX5, TEX5_LAYOUT = TEX5_LAYOUT, note = note }
"""


def main():
	only = None
	if len(sys.argv) > 2 and sys.argv[1] == "-k":
		only = sys.argv[2]
	if not os.path.exists(LUAU):
		print(f"luau CLI not found at {LUAU} (set LUAU_BIN)")
		return 2
	total, bad = 0, 0
	t0 = time.time()
	for fn in TESTS:
		if only and only not in fn.__name__:
			continue
		total += 1
		try:
			fails = fn()
		except (Exception, SystemExit) as e:  # a crash in the test itself
			import traceback
			fails = ["test crashed: " + traceback.format_exc()]
		if fails:
			bad += 1
			print(f"FAIL {fn.__name__}")
			for f in fails[:25]:
				print("      " + f)
		else:
			print(f"ok   {fn.__name__}")
	print(f"{total - bad}/{total} passed in {time.time() - t0:.1f} s")
	if not bad:
		shutil.rmtree(TMP, ignore_errors=True)
	else:
		print(f"(scripts kept in {TMP})")
	return 1 if bad else 0


if __name__ == "__main__":
	sys.exit(main())
