# tools/ - checking an aura without Roblox Studio

Cloud sessions can't open Studio, so an aura module (like `roblox/ReplicatedStorage/AuraFX/TheEnd.lua`) is checked here in two
steps, then installed and play-tested on Milo's Mac:

1. **`harness/`** runs the module's real Luau code against a mock Roblox runtime (the luau CLI) in 28 scenarios: day, night,
   glide, air, far, low quality, respawn, six wearers ... It reports what Studio would throw (unknown members, bad types,
   read-only writes, leaks ...), lints THE END's rules (palette, no flicker, opacity, the clock blocking the view), measures
   cost, and writes snapshot frames (JSON: every part, GUI, beam, emitter, light and the posed character at a moment).
   See [harness/README.md](harness/README.md); the frame format is [harness/SNAPSHOT.md](harness/SNAPSHOT.md).
2. **`preview/`** draws those frames like Studio would (three.js in headless Chromium), in Milo's tropical plaza by day or
   by night. See [preview/README.md](preview/README.md), and **[preview/FIDELITY.md](preview/FIDELITY.md)** for what a render
   can and can't tell you.

Nothing here replaces Play mode in Studio. Never report a module as "tested in Studio" from these tools.

## The one command

```sh
tools/check_aura.sh roblox/ReplicatedStorage/AuraFX/TheEnd.lua /tmp/check      # ~1 minute on 4 CPUs
```

| output | what it is |
|---|---|
| `/tmp/check/harness/report.md` | the harness report over all 28 scenarios: **read the errors first, then the warnings** |
| `/tmp/check/day_sheet.png`, `night_sheet.png` | the standard views at t = 8 s (fully assembled): studio, front34, back, side, far, closeup and Roblox's default 12.5-stud zoom (`subject:-1,0,0.35,12.5`) |
| `/tmp/check/renders/*.png` | the same views one by one (1280x608, Studio's 1920x913 aspect) |
| `/tmp/check/views/` | the harness runs behind those renders (`report.md`, `snapshots/day_idle@front34/...`) |

Exit code: 0 = no module errors, 1 = the module raised errors (fix those first), 2 = harness failure, 3 = rendering failed.
Options: `--time T` (another moment, e.g. `--time 3` mid-assembly), `--views "studio,front34,orbit:200,10,30"`, `--quick`
(skip the 28-scenario run), `--no-render`, `--seed N`, `--ss 2` (crisper, slower), `--real-day shot.png --real-night shot.png`
(Studio screenshots taken with the studio camera -> `compare_day.png` / `compare_night.png`, Studio | preview).

**Why each view is its own harness run:** the harness gives the aura the camera of the view it will be drawn from. That
matters for anything a module places from the camera, like pass 5's clock that stands behind the wearer as seen by the
viewer: drawing a frame from another angle than the one it ran with would show the clock where it was placed for the first
camera. So `day_idle@front34` means "run day_idle with the front34 camera".

| view | camera (relative to the wearer; Roblox's FieldOfView 70) |
|---|---|
| `studio` | the camera of the real pass-4 Studio screenshots: Roblox's Custom camera, 40 studs from the HumanoidRootPart + 1.5 up, looking from front x 38 + right x 8 + up x 1 (nearly level, a little to the right) - what Milo frames his shots with |
| `front34` | 45° off the front, 12° up, 48 studs |
| `back` | behind and above, 36 studs, 14° up: the owner's usual game camera |
| `side` | from the wearer's right, 46 studs |
| `far` | 130 studs: past the framework's 110-stud detail range, so particles are off (as in Roblox) |
| `closeup` | 15 studs |
| also | `front`, `top`, `orbit:AZ,EL,DIST[,TY]`, `subject:F,R,U,ZOOM` (the presets live in `preview/web/views.js`; the harness reads them from there) |

## Setup

- `python3` (3.9+), the luau CLI (`LUAU_BIN`, default `/home/user/luau-lang/luau/build/luau`; on a Mac: a Luau release binary or
  a build of github.com/luau-lang/luau), and Pillow for the sheets (`python3 -m pip install pillow`).
- `node` 18+ and `cd tools/preview && npm install` (three 0.180.0, playwright 1.56.1). Playwright needs Chromium: in this cloud
  container it is preinstalled (`PLAYWRIGHT_BROWSERS_PATH`); elsewhere `npx playwright install chromium` once.

## Doing it step by step

```sh
# harness: all scenarios, or a few, with snapshots at chosen moments (t= seconds, or frame numbers at 60 fps)
python3 tools/harness/run_aura.py MODULE.lua --out /tmp/run
python3 tools/harness/run_aura.py MODULE.lua --scenarios day_idle@studio,night_idle@back --snapshot "all:t=3,8" --out /tmp/run

# preview: any snapshot folder, any views ("cam" = the camera the harness ran with)
node tools/preview/render.mjs --snapshot /tmp/run/snapshots --views cam --size game --out /tmp/renders
node tools/preview/render.mjs --snapshot /tmp/run/snapshots/day_idle@studio --views cam,front34,top --out /tmp/renders

# sheets and comparisons
python3 tools/preview/sheet.py grid /tmp/sheet.png /tmp/renders/*.png --cols 3
python3 tools/preview/sheet.py compare /tmp/cmp.png studio_shot.png /tmp/renders/day_idle@studio_f00480_cam.png
python3 tools/preview/calibration_probe.py studio_shot.png /tmp/renders/day_idle@studio_f00480_cam.png

# interactive: a self-contained page with an orbit camera, day/night and a timeline over the frames
node tools/preview/build-viewer.mjs --snapshot /tmp/run/snapshots --out /tmp/viewer.html
```

## Tests and baselines

```sh
python3 tools/harness/tests/run_tests.py     # harness self-tests: specs, 25 broken modules, pass 4 clean, camera overrides,
                                              # and THE END's register headroom (below)
python3 tools/harness/register_headroom.py roblox/ReplicatedStorage/AuraFX/TheEnd.lua --measure
                                              # how many spare local registers End.build has (Luau's limit is 200 per
                                              # function; one past it and the module does not compile: keep >= 16)
npm --prefix tools/preview test               # renderer smoke test: conventions and colours by pixel probes
tools/baseline/make_pass4.sh                  # rebuild tools/baseline/pass4/ and print the Studio-vs-preview probes
```

- `harness/baseline/pass4-report.md`: the harness report of the live pass-4 module (`--update-baseline` refreshes it).
- `baseline/pass4/`: the live pass-4 module next to the **real** Studio screenshots from the Mac session (`real_*.jpg`,
  `compare_*.jpg` = Studio | preview with the same camera and orb positions), and its standard day/night sheets. Compare a new
  pass against these, and re-run `make_pass4.sh` after changing the renderer to see that it still matches Studio.

## Layout

```
check_aura.sh          the one command (harness + standard renders + sheets)
harness/               run_aura.py, runtime/*.luau (mock Roblox), api/ (from Roblox's API dump), tests/, baseline/
preview/               render.mjs, web/*.js (renderer), standins/ (look-alike textures), fixtures/, sheet.py,
                       calibration_probe.py, viewer.html, FIDELITY.md
baseline/              make_pass4.sh, pass4/ (Studio screenshots and pass-4 renders)
```
