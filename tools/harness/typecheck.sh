#!/usr/bin/env bash
# Static type-check of aura modules against the Roblox API, with luau-lsp's command line ("luau-lsp analyze").
# It complements run_aura.py: the harness only sees code paths the scenarios execute; the type checker reads them all
# (a misspelt property in a branch that never ran, Enum.Materal, a Vector3 where a Color3 belongs).
#
#   tools/harness/typecheck.sh [--strict] [--api-only] MODULE.lua [MODULE.lua ...]
#
#   (default)   the module's own mode (nonstrict unless it starts with --!strict): what Studio's Script Analysis shows.
#   --strict    check it as if it started with --!strict. Catches far more API mistakes, but code written in the
#               dynamic style (helpers like new(class, props) that set properties through o[k] = v) also produces
#               many "type" complaints that are not bugs.
#   --api-only  only print diagnostics about the Roblox API (unknown members of Roblox classes, wrong enum types,
#               wrong datatypes for typed values); pair it with --strict to triage.
#
# Needs:
#   LUAU_LSP  the luau-lsp binary (build: see README "Static type-checking"). Default: luau-lsp on PATH.
#   DEFS      Roblox definitions (luau-lsp's scripts/globalTypes.d.luau). Default: next to the binary's source tree if
#             found, else downloaded once to ~/.cache/aura-harness/globalTypes.d.luau.
# The module is typed as ReplicatedStorage.AuraFX.<Name> through a small generated Rojo sourcemap, so `script`,
# `script.Parent` and the services resolve like in Studio.
set -euo pipefail

STRICT=0
APIONLY=0
FILES=()
for a in "$@"; do
	case "$a" in
		--strict) STRICT=1 ;;
		--api-only) APIONLY=1 ;;
		-h|--help) sed -n '2,20p' "$0"; exit 0 ;;
		*) FILES+=("$a") ;;
	esac
done
if [ ${#FILES[@]} -lt 1 ]; then
	echo "usage: $0 [--strict] [--api-only] MODULE.lua [MODULE.lua ...]" >&2
	exit 2
fi
LSP="${LUAU_LSP:-$(command -v luau-lsp || true)}"
if [ -z "$LSP" ] || [ ! -x "$LSP" ]; then
	echo "luau-lsp not found: set LUAU_LSP=/path/to/luau-lsp (see tools/harness/README.md)" >&2
	exit 2
fi
DEFS="${DEFS:-}"
if [ -z "$DEFS" ]; then
	for c in "$(dirname "$LSP")/../src/scripts/globalTypes.d.luau" "$(dirname "$LSP")/../scripts/globalTypes.d.luau" \
		"$HOME/.cache/aura-harness/globalTypes.d.luau"; do
		if [ -f "$c" ]; then DEFS="$c"; break; fi
	done
fi
if [ -z "$DEFS" ]; then
	mkdir -p "$HOME/.cache/aura-harness"
	DEFS="$HOME/.cache/aura-harness/globalTypes.d.luau"
	echo "downloading Roblox definitions to $DEFS" >&2
	curl -sSfLo "$DEFS" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
fi
DEFS="$(cd "$(dirname "$DEFS")" && pwd)/$(basename "$DEFS")"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
status=0
for MOD in "${FILES[@]}"; do
	base="$(basename -- "$MOD")"
	name="${base%%.*}"
	dir="$WORK/$name"
	mkdir -p "$dir"
	if [ $STRICT = 1 ]; then
		# (the directive takes a line of its own; reported line numbers are shifted back below)
		{ printf -- '--!strict\n'; cat "$MOD"; } >"$dir/$name.luau"
	else
		cp "$MOD" "$dir/$name.luau"
	fi
	# DataModel tree: ReplicatedStorage.AuraFX (ModuleScript) > <Name> (ModuleScript = this file)
	cat >"$dir/sourcemap.json" <<EOF
{"name":"Game","className":"DataModel","children":[
 {"name":"ReplicatedStorage","className":"ReplicatedStorage","children":[
  {"name":"AuraFX","className":"ModuleScript","children":[
   {"name":"$name","className":"ModuleScript","filePaths":["$name.luau"]}]}]},
 {"name":"Workspace","className":"Workspace"},
 {"name":"Players","className":"Players"},
 {"name":"Lighting","className":"Lighting"}]}
EOF
	echo "== $base$([ $STRICT = 1 ] && echo ' (checked as --!strict)' || true)"
	out="$(cd "$dir" && "$LSP" analyze --platform=roblox --definitions="@roblox=$DEFS" --sourcemap=sourcemap.json --formatter=plain \
		"$name.luau" 2>&1)" || status=1
	printf '%s\n' "$out" | STRICT=$STRICT APIONLY=$APIONLY DIR="$dir/" NAME="$name.luau" BASE="$base" python3 -c '
import os, re, sys
strict, api_only = os.environ["STRICT"] == "1", os.environ["APIONLY"] == "1"
name, base, d = os.environ["NAME"], os.environ["BASE"], os.environ["DIR"]
diags = []
for line in sys.stdin.read().split("\n"):
    if line.startswith("[INFO]") or "client does not allow" in line or not line.strip():
        continue
    line = line.replace(d, "")
    line = re.sub(re.escape(name) + r"( \[[^]]*\])?", base, line)
    if re.match(r"^\S+:\d+:\d+", line) or not diags:
        diags.append(line)
    else:
        diags[-1] += " " + line.strip()  # (continuation of a multi-line diagnostic)
if strict:
    diags = [re.sub(r"^([^:]+):(\d+):", lambda m: "%s:%d:" % (m.group(1), int(m.group(2)) - 1), x) for x in diags]
if api_only:
    keep = []
    for x in diags:
        if "TypeError" not in x:
            continue
        if re.search(r"not found in (external type|class) .(?!Instance.)[A-Z]", x) or re.search(r"Enum\.\w+.* but got .*Enum\.\w+", x) \
                or re.search(r"Expected this to be .(Vector3|Vector2|CFrame|Color3|UDim2|UDim|NumberSequence|ColorSequence|NumberRange|Rect|TweenInfo)., but got", x):
            keep.append(x)
    diags = keep
for x in diags:
    print(x)
nt = sum(1 for x in diags if "TypeError" in x)
print("   %d type error(s), %d other diagnostic(s)" % (nt, len(diags) - nt))
'
done
exit $status
