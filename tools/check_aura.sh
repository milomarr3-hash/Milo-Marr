#!/usr/bin/env bash
# One command from an aura module to a harness report and a standard set of preview renders (no Studio needed).
#
#   tools/check_aura.sh MODULE.lua OUTDIR [options]
#
#   1. the harness runs the module in all 35 scenarios           -> OUTDIR/harness/report.md (+ report.json, snapshots/)
#   2. the harness runs day_idle and night_idle once per view, with the camera of that view, and snapshots t = 8 s
#      (so anything the module places from the camera, like pass 5's viewer-anchored clock, is placed for that view)
#                                                                -> OUTDIR/views/snapshots/<scenario>@<view>/
#   3. the preview renderer draws each of those from its own camera -> OUTDIR/renders/*.png
#   4. contact sheets                                            -> OUTDIR/day_sheet.png, OUTDIR/night_sheet.png
#   (5. with --real-day / --real-night: Studio screenshot | preview, both from the "studio" camera -> OUTDIR/compare_*.png)
#
# Options:
#   --time T          snapshot time in seconds after the scenario starts (default 8: pass 4 has fully assembled by ~6.5 s)
#   --views LIST      default "studio,front34,back,side,far,closeup,subject:-1,0,0.35,12.5" (studio = the camera of the
#                     real pass-4 Studio captures; subject:-1,0,0.35,12.5 = Roblox's default 12.5-stud zoom behind the
#                     wearer, what players actually see; the others are tools/preview/web/views.js presets;
#                     orbit:AZ,EL,DIST[,TY] and subject:F,R,U,ZOOM also work, e.g. --views "front34,orbit:200,10,30")
#   --quick           skip step 1 (only the day/night view runs; their report is in OUTDIR/views/report.md)
#   --no-render       stop after the harness
#   --seed N          harness seed (default 12345; the orbiting moon/void phase depends on it)
#   --ss 2            supersample the renders (crisper hairlines, ~3x slower)
#   --size WxH|game   render size (default game = 1280 wide at Studio's 1920x913 viewport aspect)
#   --real-day FILE --real-night FILE   Studio screenshots taken with the studio camera (see tools/README.md) to compare
#   --first-person    also render the owner's first-person view by day, looking left and right of the wearer's facing
#                     (subject:0,-1,0.05,0.5 / subject:0,1,0.05,0.5, characters hidden as Roblox hides them) -> OUTDIR/fp/
#
# Exit code: the harness's (0 clean, 1 the module raised errors, 2 harness failure); 3 when rendering failed.
# Needs: python3, the luau CLI (LUAU_BIN or tools/harness default), node 18+ with `npm install` done in tools/preview,
# and Pillow for the sheets (python3 -m pip install pillow).
set -u

usage() { sed -n '2,31p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
[ $# -ge 2 ] || usage 2
case "$1" in -h|--help) usage 0;; esac
MODULE=$1; OUT=$2; shift 2
T=8; VIEWS="studio,front34,back,side,far,closeup,subject:-1,0,0.35,12.5"; FULL=1; RENDER=1; SEED=12345; SS=1; SIZE=game; REAL_DAY=""; REAL_NIGHT=""; FP=0
while [ $# -gt 0 ]; do
	case "$1" in
		--time) T=$2; shift;;
		--views) VIEWS=$2; shift;;
		--quick) FULL=0;;
		--no-render) RENDER=0;;
		--seed) SEED=$2; shift;;
		--ss) SS=$2; shift;;
		--size) SIZE=$2; shift;;
		--real-day) REAL_DAY=$2; shift;;
		--real-night) REAL_NIGHT=$2; shift;;
		--first-person) FP=1;;
		-h|--help) usage 0;;
		*) echo "unknown option $1 (see --help)" >&2; exit 2;;
	esac
	shift
done
HERE=$(cd "$(dirname "$0")" && pwd)
PY=${PYTHON:-python3}
[ -f "$MODULE" ] || { echo "no such module: $MODULE" >&2; exit 2; }
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)

# the view list: commas separate views, but orbit:/subject: specs keep their own commas
VIEW_LIST=$("$PY" -c 'import re,sys; print("\n".join(v.strip() for v in re.split(r",(?=\s*[A-Za-z])", sys.argv[1]) if v.strip()))' "$VIEWS")
SCEN=""
for base in day_idle night_idle; do
	while IFS= read -r v; do [ -n "$v" ] && SCEN="$SCEN,$base@$v"; done <<EOF
$VIEW_LIST
EOF
done
SCEN=${SCEN#,}

CODE=0
if [ "$FULL" = 1 ]; then
	echo "== 1/4 harness: all scenarios"
	"$PY" "$HERE/harness/run_aura.py" "$MODULE" --out "$OUT/harness" --seed "$SEED"
	CODE=$?
	[ "$CODE" -ge 2 ] && echo "   (harness failure: see $OUT/harness/report.md)" >&2
fi
echo "== 2/4 harness: day/night x views at t=${T}s"
"$PY" "$HERE/harness/run_aura.py" "$MODULE" --scenarios "$SCEN" --snapshot "all:t=$T" --out "$OUT/views" --seed "$SEED" --quiet
VCODE=$?
[ "$FULL" = 1 ] || CODE=$VCODE
[ "$VCODE" -ge 2 ] && { echo "the view runs failed (see $OUT/views/report.md)" >&2; exit 2; }

if [ "$RENDER" = 1 ]; then
	if [ ! -d "$HERE/preview/node_modules/three" ]; then
		echo "tools/preview needs its packages: (cd tools/preview && npm install)" >&2; exit 3
	fi
	echo "== 3/4 preview renders"
	rm -rf "$OUT/renders"
	node "$HERE/preview/render.mjs" --snapshot "$OUT/views/snapshots" --views cam --size "$SIZE" --ss "$SS" --sheet off --out "$OUT/renders" \
		|| { echo "rendering failed" >&2; exit 3; }
	echo "== 4/4 contact sheets"
	for base in day_idle night_idle; do
		set --
		while IFS= read -r v; do
			[ -n "$v" ] || continue
			safe=$(printf '%s' "$base@$v" | sed 's/[^A-Za-z0-9_@.=-]\{1,\}/_/g')
			f=$(ls "$OUT/renders/${safe}_f"*_cam.png 2>/dev/null | head -1)
			[ -n "$f" ] && set -- "$@" "${base%_idle} $v=$f"
		done <<EOF
$VIEW_LIST
EOF
		[ $# -gt 0 ] && "$PY" "$HERE/preview/sheet.py" grid "$OUT/${base%_idle}_sheet.png" "$@" --cols 3 --width 640 \
			--title "$(basename "$MODULE")  ${base}  t=${T}s  (harness + preview, not Studio)"
	done
	if [ "$FP" = 1 ]; then
		echo "== first person (day, looking left / right)"
		"$PY" "$HERE/harness/run_aura.py" "$MODULE" --scenarios "day_idle@subject:0,-1,0.05,0.5,day_idle@subject:0,1,0.05,0.5" \
			--snapshot "all:t=$T" --out "$OUT/fp/views" --seed "$SEED" --quiet
		node "$HERE/preview/render.mjs" --snapshot "$OUT/fp/views/snapshots" --views cam --size "$SIZE" --ss "$SS" --sheet off \
			--hide characters --out "$OUT/fp" || { echo "rendering failed" >&2; exit 3; }
	fi
	stu() { ls "$OUT/renders/${1}@studio_f"*_cam.png 2>/dev/null | head -1; }
	if [ -n "$REAL_DAY" ] && [ -n "$(stu day_idle)" ]; then
		"$PY" "$HERE/preview/sheet.py" compare "$OUT/compare_day.png" "$REAL_DAY" "$(stu day_idle)" --labels "Studio (day),preview day_idle@studio"
	fi
	if [ -n "$REAL_NIGHT" ] && [ -n "$(stu night_idle)" ]; then
		"$PY" "$HERE/preview/sheet.py" compare "$OUT/compare_night.png" "$REAL_NIGHT" "$(stu night_idle)" --labels "Studio (night),preview night_idle@studio"
	fi
fi

echo
echo "done in $(( $(date +%s) - t0 ))s -> $OUT"
[ "$FULL" = 1 ] && echo "  harness report: $OUT/harness/report.md"
echo "  view runs:      $OUT/views/report.md"
if [ "$RENDER" = 1 ]; then
	echo "  renders:        $OUT/renders/ ($(ls "$OUT/renders" | wc -l | tr -d ' ') png)"
	echo "  sheets:         $OUT/day_sheet.png $OUT/night_sheet.png"
	for f in "$OUT"/compare_*.png; do [ -f "$f" ] && echo "  compare:        $f"; done
fi
case $CODE in
	0) echo "  result: no module errors (read the warnings in the report)";;
	1) echo "  result: THE MODULE RAISED ERRORS (see the report)";;
	*) echo "  result: harness failure (see the report)";;
esac
exit "$CODE"
