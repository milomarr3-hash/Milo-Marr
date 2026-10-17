#!/usr/bin/env python3
"""Record the te5 texture ids after uploading, and fill the module's TEX5 table from them.

    # 1) after uploading (Studio MCP upload_image or Asset Manager), record the ids in textures/te5/*/manifest.json
    python3 roblox/install/patch_tex5.py record --json upload_result.json          # upload_image's {url: id} result
    python3 roblox/install/patch_tex5.py record te5_mote.png=rbxassetid://123 glint5=456 ...   # or by hand
    # 2) fill TEX5 in roblox/ReplicatedStorage/AuraFX/TheEnd.lua from the manifests (only the TEX5 strings change)
    python3 roblox/install/patch_tex5.py patch
    # 3) then make the install payloads again: python3 roblox/install/make_payloads.py roblox/ReplicatedStorage/AuraFX/TheEnd.lua
    python3 roblox/install/patch_tex5.py status                                    # what is uploaded / filled in

A texture is named by its file (te5_mote.png), its name (te5_mote), its texKey (mote), or a URL/path ending in the file
name (http://127.0.0.1:8765/particles/te5_mote.png). Ids may be written rbxassetid://123, 123 or any text holding the
number. `record` refuses to change an id that is already recorded unless --force (so a re-upload is deliberate), and
writes textures/te5/uploaded.md (the id list, like textures/te4/uploaded.md). `patch` never clears a filled id for a
texture that has no recorded id; `patch --check` exits 1 if the module is not up to date with the manifests.
Options: --module FILE, --manifests DIR (default textures/te5), --uploaded-md FILE, --force. Standard library only.

Note: re-running a texture generator (textures/te5/*/make_te5_*.py) rewrites its manifest with uploadedId null. The ids
also live in textures/te5/uploaded.md and in the module's TEX5; `record` them again from there if that happens.
"""
import argparse
import glob
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


def rel(path):
	p = os.path.abspath(path)
	return os.path.relpath(p, REPO).replace(os.sep, "/") if p.startswith(REPO + os.sep) else os.path.basename(p)


# ---------------------------------------------------------------------------------------------------------- manifests

def load_manifests(root):
	"""-> list of (path, entries)."""
	out = []
	for p in sorted(glob.glob(os.path.join(root, "*", "manifest.json"))):
		with open(p, "rb") as f:
			entries = json.loads(f.read())
		if not isinstance(entries, list):
			raise SystemExit(f"patch_tex5: {rel(p)} is not a list of entries")
		out.append((p, entries))
	if not out:
		raise SystemExit(f"patch_tex5: no */manifest.json under {rel(root)}")
	return out


def png_size(path):
	"""(width, height) of a PNG from its header (standard library only), or None."""
	try:
		with open(path, "rb") as f:
			head = f.read(24)
	except OSError:
		return None
	if len(head) < 24 or head[:8] != b"\x89PNG\r\n\x1a\n":
		return None
	return int.from_bytes(head[16:20], "big"), int.from_bytes(head[20:24], "big")


def flipbook_problems(manifests):
	"""Roblox only animates particle flipbooks on 1024x1024 textures ("Particle texture must be 1024 by 1024 to use
	flipbooks"): any texture whose manifest layout is a Grid must be exactly that, or every particle shows the whole sheet."""
	out = []
	for p, entries in manifests:
		for e in entries:
			if str(e.get("layout") or "None").startswith("Grid"):
				png = os.path.join(os.path.dirname(p), e.get("file") or "")
				sz = png_size(png)
				if sz != (1024, 1024):
					out.append(f"{e.get('file')}: flipbook layout {e.get('layout')} needs a 1024x1024 PNG, this one is "
							   f"{'%dx%d' % sz if sz else 'unreadable'} (re-export it before uploading)")
	return out


def save_manifest(path, entries):
	data = (json.dumps(entries, indent=1, ensure_ascii=False) + "\n").encode("utf-8")
	with open(path, "rb") as f:
		if f.read() == data:
			return False
	with open(path, "wb") as f:
		f.write(data)
	return True


def norm_id(v):
	m = re.search(r"(\d{5,})", str(v))
	if not m:
		raise ValueError(f"no asset id in {v!r}")
	return "rbxassetid://" + m.group(1)


def find_entry(manifests, key):
	k = key.strip().strip("\"'")
	base = re.split(r"[/\\]", k.split("?")[0])[-1]
	stem = base[:-4] if base.lower().endswith(".png") else base
	hits = []
	for p, entries in manifests:
		for e in entries:
			if base == e.get("file") or stem == e.get("name") or stem == e.get("texKey") or k == e.get("texKey"):
				hits.append((p, e))
	if len(hits) != 1:
		return None
	return hits[0]


def parse_upload_text(text):
	"""Pairs from upload_image's result ({url: id} JSON), any JSON object/list of pairs, or loose text."""
	try:
		d = json.loads(text)
	except ValueError:
		d = None
	pairs = []
	if isinstance(d, dict):
		pairs = list(d.items())
	elif isinstance(d, list):
		for it in d:
			if isinstance(it, dict):
				k = it.get("file") or it.get("name") or it.get("url") or it.get("path")
				v = it.get("id") or it.get("assetId") or it.get("uploadedId")
				if k and v:
					pairs.append((k, v))
	if not pairs:
		for m in re.finditer(r"([\w./:\\-]*te5_\w+\.png)[^\d\n]{0,40}?(\d{5,})", text):
			pairs.append((m.group(1), m.group(2)))
	return pairs


def write_uploaded_md(manifests, path):
	lines = [
		"# THE END pass 5 textures (te5): uploaded ids",
		"",
		"Written by `roblox/install/patch_tex5.py` from `textures/te5/*/manifest.json` (edit those with `patch_tex5.py record`,",
		"not this file). The PNGs are made by `textures/te5/*/make_te5_*.py` and uploaded from Milo's Mac (Studio MCP",
		"`upload_image`, or Studio's Asset Manager bulk import); `patch_tex5.py patch` copies the ids into the `TEX5` table of",
		"`roblox/ReplicatedStorage/AuraFX/TheEnd.lua`. Until a texture has an id, the aura uses its pass-4 fallback.",
		"",
		"| file | TEX5 key | asset | what it is |",
		"|---|---|---|---|",
	]
	for p, entries in manifests:
		group = os.path.basename(os.path.dirname(p))
		for e in entries:
			lines.append(f"| {group}/{e.get('file')} | {e.get('texKey')} | {e.get('uploadedId') or '(not uploaded)'} | "
						 f"{(e.get('purpose') or '').replace('|', '/')} |")
	data = ("\n".join(lines) + "\n").encode("utf-8")
	old = open(path, "rb").read() if os.path.exists(path) else None
	if old != data:
		with open(path, "wb") as f:
			f.write(data)
		return True
	return False


# --------------------------------------------------------------------------------------- the TEX5 table in the module

def lua_tokens(src: str, start: int, end: int):
	"""Tokens of src[start:end] -> (kind, text, pos), kinds: name, string, op. Comments and whitespace are skipped."""
	i = start
	while i < end:
		c = src[i]
		if c in " \t\r\n":
			i += 1
		elif src.startswith("--", i):
			m = re.match(r"--\[(=*)\[", src[i:])
			if m:
				close = "]" + m.group(1) + "]"
				j = src.find(close, i + len(m.group(0)))
				i = (j + len(close)) if j != -1 else end
			else:
				j = src.find("\n", i)
				i = j if j != -1 else end
		elif c in "\"'":
			j = i + 1
			while j < end and src[j] != c:
				if src[j] == "\\":
					j += 1
				elif src[j] == "\n":
					break
				j += 1
			yield ("string", src[i:j + 1], i)
			i = j + 1
		elif c == "[" and re.match(r"\[=*\[", src[i:]):
			m = re.match(r"\[(=*)\[", src[i:])
			close = "]" + m.group(1) + "]"
			j = src.find(close, i + len(m.group(0)))
			j = (j + len(close)) if j != -1 else end
			yield ("string", src[i:j], i)
			i = j
		elif c.isalpha() or c == "_":
			m = re.match(r"[A-Za-z_]\w*", src[i:])
			yield ("name", m.group(0), i)
			i += len(m.group(0))
		elif c.isdigit():
			m = re.match(r"[0-9][\w.]*", src[i:])
			yield ("op", m.group(0), i)
			i += len(m.group(0))
		else:
			yield ("op", c, i)
			i += 1


def tex5_entries(src: str):
	"""-> list of (key, value_text, start, end) for each `key = "string"` directly inside `local TEX5 = { ... }`."""
	m = re.search(r"(?m)^local\s+TEX5\s*=\s*\{", src)
	if not m:
		raise SystemExit("patch_tex5: the module has no `local TEX5 = {` table")
	toks = list(lua_tokens(src, m.end(), len(src)))
	depth, out, k = 1, [], 0
	while k < len(toks) and depth > 0:
		kind, text, pos = toks[k]
		if kind == "op" and text in "{(":
			depth += 1
		elif kind == "op" and text in "})":
			depth -= 1
		elif (depth == 1 and kind == "name" and k + 2 < len(toks) and toks[k + 1][1] == "="
			  and toks[k + 2][0] == "string" and toks[k + 2][1][:1] in "\"'"):
			s = toks[k + 2]
			out.append((text, s[1], s[2], s[2] + len(s[1])))
			k += 3
			continue
		k += 1
	if depth != 0:
		raise SystemExit("patch_tex5: could not find the end of the TEX5 table")
	return out


def string_value(lit: str) -> str:
	return lit[1:-1]


def plan_patch(src: str, manifests):
	"""-> (new_src, report lines, changed count, filled count, total keys)."""
	entries = tex5_entries(src)
	keys = {}
	for key, lit, a, b in entries:
		if key in keys:
			raise SystemExit(f"patch_tex5: TEX5.{key} appears twice")
		keys[key] = (lit, a, b)
	want = {}
	for p, es in manifests:
		for e in es:
			if e.get("uploadedId"):
				want[e["texKey"]] = norm_id(e["uploadedId"])
	report, edits = [], []
	for tk in sorted(set(e["texKey"] for _, es in manifests for e in es) - set(keys)):
		report.append(f"warning: the module has no TEX5.{tk} (a manifest texture it does not use)")
	changed = 0
	for key, (lit, a, b) in keys.items():
		cur = string_value(lit)
		if key in want and cur != want[key]:
			edits.append((a, b, '"' + want[key] + '"'))
			changed += 1
			report.append(f"TEX5.{key}: {cur or '(empty)'} -> {want[key]}")
	new = src
	for a, b, text in sorted(edits, reverse=True):
		new = new[:a] + text + new[b:]
	filled = sum(1 for k, (lit, a, b) in keys.items() if (want.get(k) or string_value(lit)))
	return new, report, changed, filled, len(keys)


# ------------------------------------------------------------------------------------------------------------- main

def main(argv=None):
	ap = argparse.ArgumentParser(description="Record te5 texture ids and fill the module's TEX5 table.")
	ap.add_argument("command", choices=["record", "patch", "status"])
	ap.add_argument("pairs", nargs="*", help="record: NAME=ID pairs (file, name or texKey = rbxassetid://ID or digits)")
	ap.add_argument("--json", help="record: a file holding upload_image's result ({url: rbxassetid}) or similar text")
	ap.add_argument("--force", action="store_true", help="record: allow changing an id that is already recorded")
	ap.add_argument("--module", default=os.path.join(REPO, "roblox", "ReplicatedStorage", "AuraFX", "TheEnd.lua"))
	ap.add_argument("--manifests", default=os.path.join(REPO, "textures", "te5"))
	ap.add_argument("--uploaded-md", help="default: <manifests>/uploaded.md")
	ap.add_argument("--check", action="store_true", help="patch: change nothing, exit 1 if the module needs patching")
	a = ap.parse_args(argv)
	md = a.uploaded_md or os.path.join(a.manifests, "uploaded.md")
	manifests = load_manifests(a.manifests)
	if a.command in ("record", "patch"):
		bad = flipbook_problems(manifests)
		if bad:
			print("patch_tex5: refusing to " + a.command + ":")
			for b in bad:
				print("  " + b)
			return 2

	if a.command == "record":
		pairs = []
		if a.json:
			with open(a.json, encoding="utf-8") as f:
				pairs += parse_upload_text(f.read())
		for p in a.pairs:
			if "=" not in p:
				raise SystemExit(f"patch_tex5: {p!r} is not NAME=ID")
			k, v = p.split("=", 1)
			pairs.append((k, v))
		if not pairs:
			raise SystemExit("patch_tex5: nothing to record (give --json FILE and/or NAME=ID pairs)")
		problems, todo = [], []
		for k, v in pairs:
			hit = find_entry(manifests, k)
			if not hit:
				problems.append(f"{k}: no single te5 texture matches this name")
				continue
			try:
				nid = norm_id(v)
			except ValueError as e:
				problems.append(f"{k}: {e}")
				continue
			p, e = hit
			old = e.get("uploadedId")
			if old and norm_id(old) != nid and not a.force:
				problems.append(f"{e['file']}: already recorded as {old}; refusing to change it to {nid} without --force")
				continue
			todo.append((p, e, nid))
		if problems:
			print("patch_tex5: nothing written:")
			for s in problems:
				print("  " + s)
			return 2
		for p, e, nid in todo:
			if e.get("uploadedId") != nid:
				print(f"  {e['file']:<22} {e['texKey']:<12} {nid}")
			e["uploadedId"] = nid
		for p, entries in manifests:
			if save_manifest(p, entries):
				print(f"wrote {rel(p)}")
		if write_uploaded_md(manifests, md):
			print(f"wrote {rel(md)}")
		missing = [e["file"] for _, es in manifests for e in es if not e.get("uploadedId")]
		print(f"recorded {len(todo)} ids; {len(missing)} textures still without an id" + (f": {', '.join(missing)}" if missing else ""))
		print("next: python3 roblox/install/patch_tex5.py patch")
		return 0

	src_bytes = open(a.module, "rb").read()
	src = src_bytes.decode("utf-8")
	new, report, changed, filled, total = plan_patch(src, manifests)

	if a.command == "status":
		vals = {k: string_value(lit) for k, lit, _, _ in tex5_entries(src)}
		print(f"{rel(a.module)}: TEX5 has {total} keys, {sum(1 for v in vals.values() if v)} filled")
		for p, es in manifests:
			for e in es:
				print(f"  {os.path.basename(os.path.dirname(p))}/{e['file']:<22} {e['texKey']:<12} "
					  f"manifest {e.get('uploadedId') or '-':<30} module {vals.get(e['texKey'], '(no key)') or '-'}")
		print("module up to date with the manifests" if changed == 0 else f"{changed} TEX5 values differ: run patch")
		return 0

	for line in report:
		print("  " + line)
	if a.check:
		print(f"{rel(a.module)}: {'up to date' if changed == 0 else f'{changed} TEX5 values need patching'}")
		return 1 if changed else 0
	if changed:
		data = new.encode("utf-8")
		with open(a.module, "wb") as f:
			f.write(data)
	else:
		data = src_bytes
	print(f"{rel(a.module)}: TEX5 {filled}/{total} filled, {changed} changed; now {len(data)} bytes, checksum {checksum(data)}")
	if changed:
		print("next: python3 roblox/install/make_payloads.py " + rel(a.module) + " --label pass5tex   (then install again)")
	return 0


if __name__ == "__main__":
	sys.exit(main())
