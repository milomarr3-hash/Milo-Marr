#!/usr/bin/env bash
# Rebuilds tools/baseline/pass4/: the live pass-4 module (roblox/ReplicatedStorage/AuraFX/TheEnd.pass4-live.lua) through the
# harness and the preview renderer, next to the REAL Studio screenshots of pass 4 from the Mac session (2026-10-14):
#
#   real_day_032409.jpg     ClockTime 14, ~8.5 s after equipping      (the Mac's te4d_day capture)
#   real_night_032418.jpg   ClockTime 0.3, fully assembled             (te4d_night)
#   real_reveal_032533.jpg  ClockTime 0.3, ~6 s into the equip reveal, the wearer's screen grade still on (te4e_reveal)
#
# All three were taken with the same camera: Roblox's Custom camera, Camera Min/MaxZoomDistance = 40, cam.CFrame =
# CFrame.lookAt(p + f * 38 + r * 8 + Vector3.new(0, 7, 0), p + Vector3.new(0, 6, 0)) -> the "studio" camera of the harness
# and the renderer. The moon and the void orbit with a random phase (math.random in build), so each comparison uses a harness
# seed that puts them where they were in that capture (found by searching seeds 1-160 and projecting the orbs).
#
#   tools/baseline/make_pass4.sh [WORKDIR]      (about 2 minutes; prints the calibration probes at the end)
#
# Writes compare_*.jpg (Studio | preview), day_sheet.jpg / night_sheet.jpg (the standard check_aura.sh views at t = 8 s),
# day_front34.jpg and night_back.jpg. Nothing here was rendered by Roblox except the real_*.jpg files.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
TOOLS=$(dirname "$HERE")
REPO=$(dirname "$TOOLS")
PY=${PYTHON:-python3}
M="$REPO/roblox/ReplicatedStorage/AuraFX/TheEnd.pass4-live.lua"
B="$HERE/pass4"
WORK=${1:-$(mktemp -d)}
mkdir -p "$WORK" "$B"

echo "== the three captures (studio camera, matched orb phases)"
"$PY" "$TOOLS/harness/run_aura.py" "$M" --scenarios day_idle@studio --seed 58 --snapshot "day_idle@studio:t=8.6" --out "$WORK/day" --quiet
"$PY" "$TOOLS/harness/run_aura.py" "$M" --scenarios night_idle@studio --seed 61 --snapshot "night_idle@studio:t=8" --out "$WORK/night" --quiet
"$PY" "$TOOLS/harness/run_aura.py" "$M" --scenarios night_idle@studio --seed 96 --snapshot "night_idle@studio:t=6.05" --out "$WORK/reveal" --quiet
node "$TOOLS/preview/render.mjs" --snapshot "$WORK/day/snapshots" --snapshot "$WORK/night/snapshots" --snapshot "$WORK/reveal/snapshots" \
	--views cam --size game --sheet off --out "$WORK/match"
R="$WORK/match"
"$PY" "$TOOLS/preview/sheet.py" compare "$B/compare_day.jpg" "$B/real_day_032409.jpg" "$R/day_idle@studio_f00516_cam.png" \
	--labels "Studio 032409 (day),preview day_idle@studio t=8.6 seed 58"
"$PY" "$TOOLS/preview/sheet.py" compare "$B/compare_night.jpg" "$B/real_night_032418.jpg" "$R/night_idle@studio_f00480_cam.png" \
	--labels "Studio 032418 (night),preview night_idle@studio t=8 seed 61"
"$PY" "$TOOLS/preview/sheet.py" compare "$B/compare_reveal.jpg" "$B/real_reveal_032533.jpg" "$R/night_idle@studio_f00363_cam.png" \
	--labels "Studio 032533 (reveal; grade on),preview night_idle@studio t=6.05 seed 96"

echo "== the standard set (tools/check_aura.sh --quick)"
"$TOOLS/check_aura.sh" "$M" "$WORK/std" --quick >/dev/null
S="$WORK/std/renders"
for base in day night; do
	set --
	for v in studio front34 back side far closeup; do set -- "$@" "$base $v=$S/${base}_idle@${v}_f00480_cam.png"; done
	"$PY" "$TOOLS/preview/sheet.py" grid "$B/${base}_sheet.jpg" "$@" --cols 3 --width 640 \
		--title "pass 4 (live)  ${base}_idle  t=8s  -  harness + preview renders, not Studio"
done
"$PY" -c 'import sys; from PIL import Image; Image.open(sys.argv[1]).convert("RGB").save(sys.argv[2], quality=85, optimize=True, progressive=True)' \
	"$S/day_idle@front34_f00480_cam.png" "$B/day_front34.jpg"
"$PY" -c 'import sys; from PIL import Image; Image.open(sys.argv[1]).convert("RGB").save(sys.argv[2], quality=85, optimize=True, progressive=True)' \
	"$S/night_idle@back_f00480_cam.png" "$B/night_back.jpg"

echo "== calibration probes (Studio vs preview)"
"$PY" "$TOOLS/preview/calibration_probe.py" \
	"$B/real_day_032409.jpg" "$R/day_idle@studio_f00516_cam.png" \
	"$B/real_night_032418.jpg" "$R/night_idle@studio_f00480_cam.png" \
	"$B/real_reveal_032533.jpg" "$R/night_idle@studio_f00363_cam.png"
echo "baseline written to $B ($(ls "$B" | wc -l | tr -d ' ') files, $(du -sh "$B" | cut -f1))"
