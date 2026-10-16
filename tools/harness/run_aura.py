#!/usr/bin/env python3
"""Headless Roblox test harness for AuraFX aura modules (no Studio needed).

Runs an aura module (e.g. roblox/ReplicatedStorage/AuraFX/TheEnd.pass4-live.lua) against a mock Roblox runtime written
in Luau (tools/harness/runtime/*.luau, run by the luau CLI), across deterministic scenarios. It catches the errors
Studio would throw, lints the build (asset ids, palette, flicker, leaks), measures cost and dumps snapshot frames for
the 3D preview renderer (tools/harness/SNAPSHOT.md).

  python3 tools/harness/run_aura.py roblox/ReplicatedStorage/AuraFX/TheEnd.pass4-live.lua
  python3 tools/harness/run_aura.py MODULE --scenarios day_idle,night_idle --out /tmp/run --snapshot "day_idle:t=1,3"
  python3 tools/harness/run_aura.py --list

Exit code: 0 clean, 1 module errors, 2 harness failure (crash, timeout, bad arguments).
"""
import argparse
import concurrent.futures as cf
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
RUNTIME = os.path.join(HERE, "runtime")
API_FILE = os.path.join(HERE, "api", "roblox_api.luau")
SECTIONS = ["prelude", "@api", "datatypes", "enum", "scheduler", "instance", "lints", "classes_parts", "classes_services",
            "world", "framework", "stats", "scenarios", "main"]
DEFAULT_LUAU = [os.environ.get("LUAU_BIN", ""), "/home/user/luau-lang/luau/build/luau", shutil.which("luau") or ""]

# every name here becomes a parameter of the function wrapping the module source, so these Roblox globals shadow the
# real Luau builtins (math, string, table ... stay native and fast)
GLOBALS = ["game", "workspace", "Workspace", "script", "plugin", "shared", "_G", "Instance", "Vector3", "Vector2", "CFrame",
           "Color3", "Vector3int16", "Vector2int16", "Region3", "Region3int16", "Ray", "ColorSequence", "ColorSequenceKeypoint",
           "NumberSequence", "NumberSequenceKeypoint", "NumberRange", "UDim", "UDim2", "Rect", "TweenInfo", "Enum", "Random",
           "BrickColor", "PhysicalProperties", "Faces", "Axes", "Font", "DateTime", "Content", "RaycastParams",
           "OverlapParams", "PathWaypoint", "task", "wait", "delay", "spawn", "Wait", "Delay", "Spawn", "tick", "time",
           "elapsedTime", "ElapsedTime", "os", "typeof", "type", "print", "warn", "require", "debug", "collectgarbage",
           "gcinfo", "settings", "UserSettings", "version", "Version", "stats", "Stats", "loadstring", "SharedTable",
           "ypcall"]

def _load_scenarios():
    """Scenario names (in order) and durations, read from runtime/scenarios.luau (the single source of truth)."""
    with open(os.path.join(RUNTIME, "scenarios.luau"), encoding="utf-8") as f:
        src = f.read()
    found = re.findall(r'def\("(\w+)",\s*"(?:[^"\\]|\\.)*",\s*\{\s*duration\s*=\s*([\d.]+)', src, re.S)
    return [n for n, _ in found], {n: float(d) for n, d in found}


SCENARIOS, DURATIONS = _load_scenarios()
DT = 1 / 60

# Camera presets. The presets are read from the preview renderer (tools/preview/web/views.js PRESETS, SUBJECT_PRESETS), so a harness
# run with --camera front34 gives the aura exactly the camera the renderer's "front34" view uses. These defaults are only
# used when the renderer is not next to the harness. "studio" is the camera of the Mac session's real pass-4 Studio
# captures (032409 day, 032418 night, 032533 reveal): Roblox's Custom camera with Camera Min/MaxZoomDistance = 40 and
# cam.CFrame = CFrame.lookAt(p + f * 38 + r * 8 + Vector3.new(0, 7, 0), p + Vector3.new(0, 6, 0)) set once.
ORBIT_DEFAULTS = {
    "front": (0, 8, 46, 5), "front34": (45, 12, 48, 5), "back": (180, 14, 36, 4.5), "side": (90, 6, 46, 5),
    "top": (25, 62, 56, 2), "far": (30, 7, 130, 6), "closeup": (18, 4, 15, 1.5),
}
SUBJECT_PRESETS = {"studio": (38, 8, 1, 40)}
VIEWS_JS = os.path.join(os.path.dirname(HERE), "preview", "web", "views.js")


def orbit_presets():
    presets = dict(ORBIT_DEFAULTS)
    try:
        with open(VIEWS_JS, encoding="utf-8") as f:
            src = f.read()
        block = re.search(r"PRESETS\s*=\s*\{(.*?)\n\};", src, re.S)
        num = r"(-?[\d.]+)"
        for m in re.finditer(r"(\w+):\s*\{\s*az:\s*%s,\s*el:\s*%s,\s*d:\s*%s,\s*ty:\s*%s\s*\}" % (num, num, num, num),
                             block.group(1) if block else ""):
            presets[m.group(1)] = tuple(float(x) for x in m.groups()[1:])
    except OSError:
        pass
    return presets


def subject_presets():
    presets = dict(SUBJECT_PRESETS)
    try:
        with open(VIEWS_JS, encoding="utf-8") as f:
            src = f.read()
        block = re.search(r"SUBJECT_PRESETS\s*=\s*\{(.*?)\};", src, re.S)
        num = r"(-?[\d.]+)"
        for m in re.finditer(r"(\w+):\s*\{\s*f:\s*%s,\s*r:\s*%s,\s*u:\s*%s,\s*zoom:\s*%s\s*\}" % (num, num, num, num),
                             block.group(1) if block else ""):
            presets[m.group(1)] = tuple(float(x) for x in m.groups()[1:])
    except OSError:
        pass
    return presets


def parse_camera(spec):
    """'front34' | 'studio' | 'orbit:AZ,EL,DIST[,TY]' | 'subject:F,R,U,ZOOM' (+ optional '/fov=N') -> config dict or error."""
    if not spec:
        return None
    fov = None
    if "/fov=" in spec:
        spec, f = spec.split("/fov=", 1)
        fov = float(f)
    presets, subjects = orbit_presets(), subject_presets()
    if spec in presets:
        az, el, d, ty = presets[spec]
        cam = {"kind": "orbit", "az": az, "el": el, "d": d, "ty": ty}
    elif spec in subjects:
        f_, r_, u_, z_ = subjects[spec]
        cam = {"kind": "subject", "f": f_, "r": r_, "u": u_, "zoom": z_}
    elif spec.startswith("orbit:"):
        v = [float(x) for x in spec[6:].split(",") if x.strip()]
        if len(v) < 3:
            raise ValueError("orbit:AZ,EL,DIST[,TY] needs at least 3 numbers")
        cam = {"kind": "orbit", "az": v[0], "el": v[1], "d": v[2], "ty": v[3] if len(v) > 3 else 4}
    elif spec.startswith("subject:"):
        v = [float(x) for x in spec[8:].split(",") if x.strip()]
        if len(v) != 4:
            raise ValueError("subject:F,R,U,ZOOM needs 4 numbers")
        cam = {"kind": "subject", "f": v[0], "r": v[1], "u": v[2], "zoom": v[3]}
    else:
        raise ValueError("unknown camera %r (presets: %s, %s; or orbit:AZ,EL,DIST[,TY], subject:F,R,U,ZOOM)" % (
            spec, ", ".join(sorted(presets)), ", ".join(sorted(subjects))))
    if fov is not None:
        cam["fov"] = fov
    return cam


def split_scenario(name):
    """'day_idle@front34' -> ('day_idle', 'front34'); 'day_idle' -> ('day_idle', None)."""
    if "@" in name:
        base, view = name.split("@", 1)
        return base, view
    return name, None


def luau_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(float(v))
    if isinstance(v, str):
        return json.dumps(v)
    if isinstance(v, dict):
        return "{ " + ", ".join("%s = %s" % (k, luau_value(x)) for k, x in v.items()) + " }"
    raise TypeError(v)


def find_luau(explicit):
    for c in [explicit] + DEFAULT_LUAU:
        if c and os.path.isfile(c) and os.access(c, os.X_OK):
            return c
    sys.exit("luau CLI not found: pass --luau PATH or set LUAU_BIN")


def long_bracket(src):
    n = 1
    while ("]" + "=" * n + "]") in src:
        n += 1
    return n


def prepare_module(src):
    # `export type` is only legal at a module's top level; inside the wrapper function it becomes a local type
    src = re.sub(r"(?m)^(\s*)export(\s+type\s)", r"\1\2", src)
    if src.startswith("#!"):
        src = "--" + src
    return src


def build_source(module_src, module_label, scenario, config, mode="scenario"):
    """Returns (source, line_map) where line_map is a list of (first_line, last_line, label, offset)."""
    lines = []
    line_map = []
    # shadow only the Roblox globals the module mentions (parameters count against Luau's 200-locals limit)
    used = [g for g in GLOBALS if re.search(r"(?<![\w.:])" + re.escape(g) + r"\b", module_src)]
    header = "local __AURA_MODULE__ = function(%s)" % ", ".join(used + ["..."])
    lines.append(header)
    mod_lines = module_src.split("\n")
    line_map.append((2, 1 + len(mod_lines), module_label, 1))
    lines.extend(mod_lines)
    lines.append("end")
    for sec in SECTIONS:
        path = API_FILE if sec == "@api" else os.path.join(RUNTIME, sec + ".luau")
        with open(path, encoding="utf-8") as f:
            text = f.read().rstrip("\n").split("\n")
        start = len(lines) + 1
        label = "harness/api/roblox_api.luau" if sec == "@api" else "harness/runtime/%s.luau" % sec
        line_map.append((start, start + len(text) - 1, label, start - 1))
        lines.extend(text)
    line_map.append((len(lines) + 1, len(lines) + 40, "harness/entry", len(lines)))
    cfg = ["H.CONFIG = {"]
    cfg.append("\tseed = %d," % config["seed"])
    cfg.append("\tmono = %s," % ("true" if config["mono"] else "false"))
    cfg.append("\tmoduleName = %s," % json.dumps(config["moduleName"]))
    if config.get("forceQuality"):
        cfg.append("\tforceQuality = %s," % json.dumps(config["forceQuality"]))
    if config.get("camera"):
        cfg.append("\tcamera = %s," % luau_value(config["camera"]))
        cfg.append("\tcameraName = %s," % json.dumps(config["cameraName"]))
    if config.get("label"):
        cfg.append("\tlabel = %s," % json.dumps(config["label"]))
    frames = config.get("snapFrames", [])
    cfg.append("\tsnapFrames = { %s }," % ", ".join("[%d] = true" % f for f in frames))
    cfg.append("}")
    lines.extend(cfg)
    lines.append("H.MODULE_CHUNK = function()")
    lines.append("\tlocal G = H.makeGlobals()")
    lines.append("\treturn __AURA_MODULE__(%s)" % ", ".join("G[%s]" % json.dumps(g) for g in used))
    lines.append("end")
    if mode == "scenario":
        lines.append("H.runScenario(%s)" % json.dumps(split_scenario(scenario)[0]))
    else:
        lines.append("H.runScript(%s)" % json.dumps(scenario))
    return "\n".join(lines) + "\n", line_map


class Mapper:
    def __init__(self, gen_path, line_map):
        self.gen = gen_path
        self.map = line_map
        self.rx = re.compile(re.escape(os.path.basename(gen_path)) + r":(\d+)")
        self.rx_full = re.compile(r"(?:\S*?)" + re.escape(os.path.basename(gen_path)) + r":(\d+)")

    def loc(self, n):
        for a, b, label, off in self.map:
            if a <= n <= b:
                return label, n - off
        return "harness/generated", n

    def text(self, s):
        if not s:
            return s

        def rep(m):
            label, ln = self.loc(int(m.group(1)))
            return "%s:%d" % (label, ln)
        return self.rx_full.sub(rep, s)

    def first_module_frame(self, s, module_label):
        for line in (s or "").split("\n"):
            m = self.rx_full.search(line)
            if m:
                label, ln = self.loc(int(m.group(1)))
                if label == module_label:
                    return "%s:%d" % (label, ln)
            elif line.startswith(module_label + ":"):
                return line.split(" ")[0].rstrip(":")
        return None


def run_one(luau, module_src, module_label, scenario, config, workdir, timeout, keep, mode="scenario"):
    src, line_map = build_source(module_src, module_label, scenario, config, mode)
    gen_path = os.path.join(workdir, "harness_%s.luau" % re.sub(r"\W", "_", scenario))
    with open(gen_path, "w", encoding="utf-8") as f:
        f.write(src)
    mapper = Mapper(gen_path, line_map)
    t0 = time.time()
    try:
        # -O1 like Studio: -O2 inlines small local functions, which shifts error(msg, level) positions
        p = subprocess.run([luau, "-O1", gen_path], capture_output=True, text=True, timeout=timeout, cwd=workdir)
        out, err, code = p.stdout, p.stderr, p.returncode
    except subprocess.TimeoutExpired as e:
        out = e.stdout.decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
        err, code = ("TIMEOUT after %ss: the module never gave control back (an infinite loop?) or the scenario is extremely slow "
                     "(raise --timeout)" % timeout), -1
    wall = time.time() - t0
    records, stray = [], []
    for line in out.split("\n"):
        if line.startswith("@@H "):
            try:
                records.append(json.loads(line[4:]))
            except json.JSONDecodeError as ex:
                stray.append("bad record: %s" % ex)
        elif line.strip():
            stray.append(line)
    if not keep:
        try:
            os.remove(gen_path)
        except OSError:
            pass
    return {"scenario": scenario, "records": records, "stray": stray, "stderr": mapper.text(err), "code": code,
            "wall": wall, "mapper": mapper}


def parse_snapshot_args(specs, scenarios):
    want = {s: set() for s in scenarios}
    if not specs:
        specs = ["all:t=1,3,6,10"]
    for spec in specs:
        if spec.lower() in ("none", "off"):
            return {s: set() for s in scenarios}
        if ":" not in spec:
            raise SystemExit("--snapshot expects scenario:frame,frame (or scenario:t=1,3 or all:t=...)")
        name, frames = spec.rsplit(":", 1)  # (a scenario name may hold a colon: day_idle@orbit:30,10,40:t=8)
        targets = scenarios if name == "all" else [name]
        use_t = frames.startswith("t=")
        if use_t:
            frames = frames[2:]
        for tgt in targets:
            if tgt not in want:
                continue
            for x in frames.split(","):
                x = x.strip()
                if not x:
                    continue
                if use_t:
                    t = float(x)
                    if t <= DURATIONS.get(split_scenario(tgt)[0], 12):
                        want[tgt].add(int(round(t / DT)))
                else:
                    want[tgt].add(int(x))
    return want


def fmt(x, nd=1):
    if x is None:
        return "-"
    if isinstance(x, float):
        return ("%." + str(nd) + "f") % x
    return str(x)


CAMERA_OVERRIDES = {}  # scenario label -> camera spec name (set in main; the follow-camera checks skip these)
FOLLOW_CAM = {"day_idle", "night_idle", "glide", "dusk", "low_quality", "r6_character", "film_meshes_present", "film_meshes_absent",
              "join_wearing", "respawn", "reequip", "air", "pair_behind", "pair_walkby", "jump", "seated", "small_avatar", "downhill",
              "equip_in_cutscene", "equip_in_cutscene_paused", "pair_side", "teleport", "nan_frame", "slope"}


def derive_warnings(s, name):
    """Warnings computed from a scenario's stats (budgets, per-frame writes, leaks, flicker, view blocking)."""
    out = []
    sf = s.get("steadyFrames") or 0
    if sf >= 60:
        for x in s.get("writesUpdate", []):
            share = x["steadyFramesWritten"] / sf
            if x["cat"] == "gui" and share >= 0.5:
                out.append(("gui-writes-per-frame", "%s is written in %d%% of steady frames (%.1f writes/frame): per-frame GUI property "
                            "writes stall Roblox; write GUIs only when a value changes" % (x["key"], round(share * 100), x["steadyAvg"])))
            # (appearance writes on parts: flagged when they happen most frames; a burst on an event, such as the 3 steps of
            # a ghost fade written once each, is not per-frame work however many parts it touches)
            elif x["cat"] == "part" and x["key"].endswith(("Transparency", "LocalTransparencyModifier", "Color", "Size")) and x["steadyAvg"] >= 5 \
                    and share >= 0.2:
                out.append(("part-writes-per-frame", "%s: %.1f writes per steady frame (move parts with BulkMoveTo; avoid per-frame "
                            "appearance writes on many parts)" % (x["key"], x["steadyAvg"])))
            elif x["steadyAvg"] > 40:
                out.append(("many-writes-per-frame", "%s: %.1f writes per steady frame" % (x["key"], x["steadyAvg"])))
        ni = (s.get("series") or {}).get("newInstances") or {}
        if ni.get("steadyAvg", 0) > 0:
            out.append(("instances-per-frame", "%.2f new instances created per steady frame inside update/callbacks (create everything in "
                        "build; reuse)" % ni["steadyAvg"]))
    c = pick_census(s)
    if c:
        low = s.get("quality") == "low"
        budget = 1500 if low else 4000
        if c.get("alive", 0) > budget * max(1, s.get("wearers", 1)):
            out.append(("particle-budget", "~%d particles alive (budget %d per wearer on %s quality)" % (c["alive"], budget, s.get("quality"))))
        if c.get("highlights", 0) > 31:
            out.append(("highlight-cap", "%d Highlights: Roblox draws at most 31 per client" % c["highlights"]))
        for e in c.get("topEmitters", []):
            if e["alive"] > 800:
                out.append(("emitter-heavy", "%s keeps ~%d particles alive (Rate %.1f x Lifetime %.1f)" % (e["path"], e["alive"], e["rate"], e["life"])))
        if c.get("shadowLights", 0) > 0:
            out.append(("light-shadows", "%d light(s) cast shadows" % c["shadowLights"]))
    for lk in s.get("leaks", []):
        if lk["leftoverInstances"]:
            out.append(("leak-instances", "after destroy, %d instance(s) the module created are still in the game: %s" % (
                len(lk["leftoverInstances"]), ", ".join("%s (%s)" % (x["path"], x["class"]) for x in lk["leftoverInstances"][:5]))))
        if lk["liveConnections"]:
            out.append(("leak-connections", "after destroy, %d connection(s) made by the aura are still connected: %s" % (
                len(lk["liveConnections"]), ", ".join("%s on %s" % (x["signal"], x["owner"]) for x in lk["liveConnections"][:5]))))
        if lk["renderStepBindings"]:
            out.append(("leak-renderstep", "after destroy, BindToRenderStep still bound: " + ", ".join(lk["renderStepBindings"])))
        if lk["playingTweens"]:
            out.append(("leak-tweens", "after destroy, tweens still playing on: " + ", ".join(lk["playingTweens"][:5])))
    for f in s.get("flicker", []):
        out.append(("flicker", "%s.%s changes direction %d times within one second (reads as flicker/strobe)" % (f["path"], f["prop"], f["perSecond"])))
    occ = s.get("occlusion") or {}
    if name in FOLLOW_CAM and name not in CAMERA_OVERRIDES and occ.get("samples", 0) >= 20 and occ.get("blocked", 0) / occ["samples"] > 0.4:
        by = sorted((occ.get("by") or {}).items(), key=lambda kv: -kv[1])
        out.append(("view-blocked", "from the default camera behind the wearer, solid aura parts cover the wearer's head (%s)" % (
            ", ".join(sorted(k for k, _ in by[:5]))), "%d%%" % round(100 * occ["blocked"] / occ["samples"])))
    cuts = s.get("billboardCuts") or {}
    if cuts.get("samples", 0) >= 3:
        per_sprite = {}
        for k, n in (cuts.get("hits") or {}).items():
            sprite, plane = k.split("|", 1)
            if n / cuts["samples"] >= 0.3:
                per_sprite.setdefault(sprite, []).append((plane, n))
        for sprite, planes in sorted(per_sprite.items()):
            planes.sort(key=lambda x: -x[1])
            out.append(("billboard-cut", "%s (solid, camera-facing) crosses SurfaceGui planes, which cut it in Roblox" % sprite,
                        "%s %d%%" % ("/".join(sorted(p for p, _ in planes)), round(100 * planes[0][1] / cuts["samples"]))))
    for u in s.get("unimplemented", []):
        out.append(("harness-gap", "%s is not implemented by the mock (returned nil)" % u["api"]))
    return out


def summarize(results, module_path, module_label, args, api_version):
    errors = {}
    warnings = {}
    scen = {}
    harness_failures = []
    for r in results:
        name = r["scenario"]
        mapper = r["mapper"]
        summary = None
        live_errors = []
        prints = []
        for rec in r["records"]:
            k = rec.get("kind")
            if k == "summary":
                summary = rec
            elif k == "error":
                live_errors.append(rec)
            elif k == "print":
                prints.append(rec)
            elif k == "fatal":
                harness_failures.append({"scenario": name, "msg": rec.get("msg")})
        if r["code"] != 0 or summary is None:
            msg = "TIMEOUT (infinite loop?)" if r["code"] == -1 else "luau exited with %s" % r["code"]
            harness_failures.append({"scenario": name, "msg": msg, "stderr": r["stderr"][-4000:], "stray": r["stray"][-20:]})
        errs = (summary or {}).get("errors") or live_errors
        for e in errs:
            msg = mapper.text(e["msg"])
            tb = mapper.text(e.get("tb", ""))
            loc = mapper.first_module_frame(e.get("tb", "") + "\n" + e["msg"], module_label)
            key = (re.sub(r"^\S+:\d+: ", "", msg), loc)
            ent = errors.setdefault(key, {"msg": msg, "location": loc, "trace": tb, "scenarios": [], "count": 0,
                                          "where": e.get("where"), "first": None})
            ent["count"] += e.get("count", 1)
            ent["scenarios"].append({"scenario": name, "frame": e.get("frame"), "t": round(e.get("t", 0), 3),
                                     "count": e.get("count", 1), "where": e.get("where")})
        for w in (summary or {}).get("warnings", []):
            msg = mapper.text(w["msg"])
            loc = mapper.first_module_frame(w.get("tb", ""), module_label)
            key = (w["code"], msg)
            ent = warnings.setdefault(key, {"code": w["code"], "msg": msg, "location": loc, "scenarios": [], "count": 0})
            ent["count"] += w["count"]
            ent["scenarios"].append(name)
        if summary:
            for dw in derive_warnings(summary, name):
                code, msg = dw[0], dw[1]
                ent = warnings.setdefault((code, msg), {"code": code, "msg": msg, "location": None, "scenarios": [], "count": 0})
                ent["count"] += 1
                ent["scenarios"].append(name + (" " + dw[2] if len(dw) > 2 else ""))
            if name in CAMERA_OVERRIDES:
                summary["camera"] = CAMERA_OVERRIDES[name]
                summary["desc"] = "%s [camera overridden: %s]" % (summary.get("desc", ""), CAMERA_OVERRIDES[name])
            summary["printsSample"] = [p["text"] for p in prints[:10]]
            summary["wallSeconds"] = round(r["wall"], 2)
            summary["stray"] = r["stray"][:20]
            scen[name] = summary
    return {
        "module": module_path, "moduleLabel": module_label, "apiVersion": api_version,
        "generated": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        "scenarios": [s for s in args.scenarios_list if s in scen], "errors": list(errors.values()),
        "warnings": sorted(warnings.values(), key=lambda w: (w["code"], w["msg"])), "perScenario": scen,
        "harnessFailures": harness_failures, "seed": args.seed, "mono": args.mono,
    }


def pick_census(s):
    """The census to show: steady state (~10 s), else the last one where the aura was in the world."""
    cs = s.get("census") or {}
    for k in ("steady", "final", "afterBuild"):
        c = cs.get(k)
        if c and c.get("total"):
            return c
    return cs.get("steady") or {}


def md_report(rep):
    L = []
    w = L.append
    errs, warns, scen = rep["errors"], rep["warnings"], rep["perScenario"]
    w("# Aura harness report: `%s`" % rep["moduleLabel"])
    w("")
    w("Headless run against the mock Roblox runtime (tools/harness). **Not a Studio test**: no rendering, physics or real "
      "engine. Roblox API %s; seed %s; %d scenarios; generated %s." % (rep["apiVersion"], rep["seed"], len(scen), rep["generated"]))
    w("")
    verdict = "CLEAN: no errors" if not errs and not rep["harnessFailures"] else \
        "%d error(s), %d harness failure(s)" % (len(errs), len(rep["harnessFailures"]))
    w("**Verdict: %s.** %d warning kind(s)." % (verdict, len(warns)))
    w("")
    # overview table
    w("## Scenarios")
    w("")
    w("| scenario | frames | update us p50 / p95 | instances | BaseParts | emitters on | rate sum | alive est. | beams | GUIs | lights | highlights | parts moved/frame | new inst./frame | GUI writes/frame (steady) | view blocked |")
    w("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for name in rep["scenarios"]:
        s = scen[name]
        c = pick_census(s)
        ut = s.get("updateTiming") or s.get("updateTimingRemote") or {}
        ser = s.get("series") or {}
        gui_steady = sum(x["steadyAvg"] for x in s.get("writesUpdate", []) if x["cat"] == "gui")
        occ = s.get("occlusion") or {}
        occ_txt = "-" if not occ.get("samples") else "%d%%" % round(100 * occ["blocked"] / occ["samples"])
        w("| %s | %d | %s / %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |" % (
            name, s.get("frames", 0), fmt(ut.get("p50Us"), 0), fmt(ut.get("p95Us"), 0), c.get("total", "-"), c.get("baseParts", "-"),
            c.get("emittersEnabled", "-"), fmt(c.get("rateSum"), 0), fmt(c.get("alive"), 0), c.get("beams", "-"), c.get("guis", "-"),
            c.get("lights", "-"), c.get("highlights", "-"), fmt((ser.get("bulkMoved") or {}).get("steadyAvg"), 1),
            fmt((ser.get("newInstances") or {}).get("steadyAvg"), 2), fmt(gui_steady, 2), occ_txt))
    w("")
    w("Columns: census at ~10 s (steady state; if the aura is hidden then, the last census where it was shown); `alive est.` = sum over enabled emitters of Rate x mean Lifetime; `update us` is "
      "the real Lua time of one `fx.update` in the mock (indicative only, the mock's property access is slower than Roblox's); "
      "`view blocked` = share of samples where an opaque aura part (or an opaque SurfaceGui plane) sits between the camera and "
      "the wearer's head.")
    w("")
    # errors
    w("## Errors (%d)" % len(errs))
    w("")
    if not errs:
        w("None.")
    for i, e in enumerate(errs, 1):
        w("### %d. %s" % (i, e["msg"].split("\n")[0]))
        w("")
        w("- at: `%s` (phase: %s); %d occurrence(s)" % (e["location"] or "?", e.get("where"), e["count"]))
        w("- scenarios: " + ", ".join("%s (frame %s, t=%ss, x%s)" % (s["scenario"], s["frame"], s["t"], s["count"]) for s in e["scenarios"][:12]))
        if e.get("trace"):
            tr = [x for x in e["trace"].strip().split("\n") if not x.startswith("harness/")] or e["trace"].strip().split("\n")
            w("")
            w("```")
            w("\n".join(tr)[:2500])
            w("```")
        w("")
    if rep["harnessFailures"]:
        w("## Harness failures")
        w("")
        for f in rep["harnessFailures"]:
            w("- **%s**: %s" % (f["scenario"], f["msg"]))
            if f.get("stderr"):
                w("")
                w("```")
                w(f["stderr"].strip()[-2000:])
                w("```")
        w("")
    # warnings
    w("## Warnings (%d kinds)" % len(warns))
    w("")
    if not warns:
        w("None.")
    for x in warns:
        sc = sorted(set(x["scenarios"]))
        detailed = any(" " in v for v in sc)
        if not detailed and len(sc) == len(scen):
            where = "all scenarios"
        elif not detailed and len(sc) >= 0.75 * len(scen) and len(scen) > 4:
            where = "all scenarios except " + ", ".join(n for n in rep["scenarios"] if n not in sc)
        else:
            where = "; ".join(sc)
        w("- **[%s]** %s%s (x%d; %s)" % (x["code"], x["msg"], (" at `%s`" % x["location"]) if x.get("location") else "", x["count"], where))
    w("")
    # cost
    w("## Cost and per-frame work")
    w("")
    ref = scen.get("day_idle") or (scen[rep["scenarios"][0]] if rep["scenarios"] else None)
    if ref:
        w("Reference scenario `%s` (%d frames, %d steady):" % (ref["scenario"], ref["frames"], ref["steadyFrames"]))
        w("")
        c = pick_census(ref)
        if c:
            w("- Instances in the aura: %d (BaseParts %d, MeshParts %d, attachments %d); emitters %d (%d enabled), rate sum %.1f/s, "
              "~%.0f particles alive, particle area ~%.0f stud^2; beams %d (%d segments); GUIs %d (%d images, %.1f Mpx of SurfaceGui "
              "canvas); lights %d (%d with shadows); highlights %d; trails %d." % (
                  c["total"], c["baseParts"], c["meshParts"], c["attachments"], c["emitters"], c["emittersEnabled"], c["rateSum"],
                  c["alive"], c["particleArea"], c["beams"], c["beamSegments"], c["guis"], c["images"], c["canvasPixels"] / 1e6,
                  c["lights"], c["shadowLights"], c["highlights"], c["trails"]))
            bc = c.get("byClass") or {}
            w("- By class: " + ", ".join("%s %d" % (k, v) for k, v in sorted(bc.items(), key=lambda kv: -kv[1])))
            if c.get("topEmitters"):
                w("- Busiest emitters: " + "; ".join("%s (%.0f alive)" % (t["path"].split(".")[-2] + "." + t["path"].split(".")[-1], t["alive"]) for t in c["topEmitters"]))
        ut = ref.get("updateTiming") or {}
        if ut:
            w("- fx.update: %d calls, mean %.0f us, p50 %.0f, p95 %.0f, max %.0f (mock time); build %.1f ms." % (
                ut["calls"], ut["meanUs"], ut["p50Us"], ut["p95Us"], ut["maxUs"], ref.get("buildMs", 0)))
        ser = ref.get("series") or {}
        if ser.get("bulkMoved"):
            w("- BulkMoveTo: %.1f parts/frame in %.1f call(s)/frame (steady)." % (ser["bulkMoved"]["steadyAvg"], ser.get("bulkCalls", {}).get("steadyAvg", 0)))
        w("")
        w("Property writes per frame made inside `fx.update` (avg over all frames / steady state after the assembly; max):")
        w("")
        w("| class.property | kind | avg/frame | steady avg | max | frames written |")
        w("|---|---|---|---|---|---|")
        for x in ref.get("writesUpdate", [])[:25]:
            w("| %s | %s | %.2f | %.2f | %d | %d |" % (x["key"], x["cat"], x["avgPerFrame"], x["steadyAvg"], x["max"], x["framesWritten"]))
        if ref.get("writesTween"):
            w("")
            w("Tween-driven writes: " + ", ".join("%s %.2f/frame (max %d)" % (x["key"], x["avgPerFrame"], x["max"]) for x in ref["writesTween"][:8]))
        if ref.get("writesCallback"):
            w("")
            w("Writes from callbacks (task.*, events, setVisible/setDetail/destroy): " + ", ".join("%s x%d" % (x["key"], x["total"]) for x in ref["writesCallback"][:10]))
        if ref.get("writesRedundant"):
            w("")
            w("Redundant writes (same value written again) inside update: " + ", ".join("%s %.2f/frame" % (x["key"], x["avgPerFrame"]) for x in ref["writesRedundant"][:8]))
        w("")
    # leaks
    w("## Cleanup (after the final destroy + 1.5 s)")
    w("")
    any_leak = False
    for name in rep["scenarios"]:
        s = scen[name]
        for lk in s.get("leaks", []):
            parts = []
            if lk["leftoverInstances"]:
                parts.append("%d instance(s) left: %s" % (len(lk["leftoverInstances"]), ", ".join("%s (%s)" % (x["path"], x["class"]) for x in lk["leftoverInstances"][:6])))
            if lk["liveConnections"]:
                parts.append("%d live connection(s): %s" % (len(lk["liveConnections"]), ", ".join("%s on %s" % (x["signal"], x["owner"]) for x in lk["liveConnections"][:6])))
            if lk["pendingThreads"]:
                parts.append("%d delayed callback(s) still scheduled (due in %s s)" % (len(lk["pendingThreads"]), ", ".join(str(x["dueIn"]) for x in lk["pendingThreads"][:6])))
            if lk["playingTweens"]:
                parts.append("tweens still playing on " + ", ".join(lk["playingTweens"][:6]))
            if lk["renderStepBindings"]:
                parts.append("render-step bindings: " + ", ".join(lk["renderStepBindings"]))
            if parts:
                any_leak = True
                w("- **%s** (build %d): %s" % (name, lk["gen"], "; ".join(parts)))
    if not any_leak:
        w("Nothing left behind in any scenario: 0 instances outside the container, 0 live connections, 0 pending callbacks.")
    mlc = {}
    for name in rep["scenarios"]:
        for c in scen[name].get("moduleLevelConnections", []):
            mlc.setdefault("%s on %s" % (c["signal"], c["owner"]), set()).add(name)
    if mlc:
        w("")
        w("Module-level connections (made once when the module is required; they live for the session, expected): " +
          ", ".join(sorted(mlc)))
    w("")
    # flicker / occlusion
    w("## Flicker and view checks")
    w("")
    fl = []
    for name in rep["scenarios"]:
        for f in scen[name].get("flicker", []):
            fl.append("%s.%s (%s): %d reversals within 1 s (%s)" % (f["path"], f["prop"], f["class"], f["perSecond"], name))
    w("- Flicker (3+ back-and-forth changes of brightness / transparency / Enabled within one second): " + ("none" if not fl else ""))
    for x in fl[:20]:
        w("  - " + x)
    occ_rows = []
    for name in rep["scenarios"]:
        occ = scen[name].get("occlusion") or {}
        if occ.get("blocked"):
            by = sorted((occ.get("by") or {}).items(), key=lambda kv: -kv[1])
            occ_rows.append("| %s | %d%% (%d of %d) | %s |" % (name, round(100 * occ["blocked"] / occ["samples"]), occ["blocked"],
                                                           occ["samples"], ", ".join("%s %d" % kv for kv in by[:6])))
    if occ_rows:
        w("- The camera's view of the wearer's head (sampled 10x a second from the local player's camera):")
        w("")
        w("| scenario | blocked | by (samples) |")
        w("|---|---|---|")
        for r in occ_rows:
            w(r)
    else:
        w("- The aura never blocked the camera's view of the wearer's head.")
    w("")
    # harness gaps
    un = {}
    for name in rep["scenarios"]:
        for u in scen[name].get("unimplemented", []):
            un[u["api"]] = un.get(u["api"], 0) + u["calls"]
    w("## Harness gaps hit")
    w("")
    if un:
        w("The module called APIs the mock does not implement (they returned nil; results after this point may be harness artefacts): " +
          ", ".join("%s x%d" % kv for kv in sorted(un.items())))
    else:
        w("None: every API the module used is implemented by the mock.")
    w("")
    assets = {}
    for name in rep["scenarios"]:
        for a in scen[name].get("assets", []):
            assets.setdefault(a["id"], set()).update(a["props"])
    w("## Asset ids used (%d)" % len(assets))
    w("")
    for k in sorted(assets):
        w("- `%s` (%s)" % (k, ", ".join(sorted(assets[k]))))
    w("")
    w("## Scenario notes")
    w("")
    for name in rep["scenarios"]:
        s = scen[name]
        w("- **%s**: %s" % (name, s.get("desc", "")))
    w("")
    return "\n".join(L)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("module", nargs="?", help="aura module source (.lua/.luau)")
    ap.add_argument("--scenarios", default="all", help="all, or a comma list (see --list)")
    ap.add_argument("--out", help="output directory (default tools/harness/out/<module>)")
    ap.add_argument("--snapshot", action="append", help='"scenario:frame,frame", "scenario:t=1,3" or "all:t=..."; "none" to skip. Default all:t=1,3,6,10')
    ap.add_argument("--seed", type=int, default=12345)
    ap.add_argument("--jobs", type=int, default=os.cpu_count() or 4)
    ap.add_argument("--timeout", type=int, default=300, help="seconds per scenario (an infinite loop in the module ends as a timeout)")
    ap.add_argument("--mono", dest="mono", action="store_true", default=None,
                    help="THE END rules: black/white/silver palette and the opacity rule (default: on when the file name contains TheEnd)")
    ap.add_argument("--no-mono", dest="mono", action="store_false")
    ap.add_argument("--module-name", help="name of the ModuleScript (default: from the file name, e.g. TheEnd)")
    ap.add_argument("--quality", choices=["high", "low"], help="force ctx.quality in every scenario")
    ap.add_argument("--camera", help="override every scenario's camera: a preview view preset (front, front34, back, side, top, "
                    "far, closeup), studio (the real pass-4 Studio captures), orbit:AZ,EL,DIST[,TY] or subject:F,R,U,ZOOM; "
                    "append /fov=N for another FieldOfView. A scenario named NAME@CAMERA (e.g. day_idle@front34) overrides "
                    "only that run, so one scenario can run under several cameras at once")
    ap.add_argument("--luau", help="path to the luau CLI")
    ap.add_argument("--keep", action="store_true", help="keep the generated .luau files in OUT/gen for debugging")
    ap.add_argument("--list", action="store_true", help="list scenarios and exit")
    ap.add_argument("--script", action="store_true", help="run the file as a plain script in a default world (unit specs)")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()
    if args.list:
        for s in SCENARIOS:
            print(s)
        return 0
    if not args.module:
        ap.error("module path required")
    luau = find_luau(args.luau)
    module_path = os.path.abspath(args.module)
    with open(module_path, encoding="utf-8") as f:
        module_src = prepare_module(f.read())
    base = os.path.basename(module_path)
    stem = base.split(".")[0]
    module_label = base
    if args.mono is None:
        args.mono = "theend" in stem.lower()
    # (split on commas that start a new name, so "day_idle@orbit:30,10,40" keeps its numbers)
    args.scenarios_list = SCENARIOS if args.scenarios == "all" else [
        s.strip() for s in re.split(r",(?=\s*[A-Za-z])", args.scenarios) if s.strip()]
    if args.script:
        args.scenarios_list = ["script"]
        args.snapshot = ["none"]
    bad = [s for s in args.scenarios_list if split_scenario(s)[0] not in SCENARIOS and not args.script]
    if bad:
        print("unknown scenario(s): %s (see --list)" % ", ".join(bad), file=sys.stderr)
        return 2
    cameras = {}
    for s_ in args.scenarios_list:
        view = split_scenario(s_)[1] or args.camera
        try:
            cameras[s_] = (parse_camera(view), view)
        except ValueError as e:
            print("bad camera for %s: %s" % (s_, e), file=sys.stderr)
            return 2
        if cameras[s_][0]:
            CAMERA_OVERRIDES[s_] = view
    out = os.path.abspath(args.out or os.path.join(HERE, "out", re.sub(r"\W", "_", base.rsplit(".", 1)[0])))
    os.makedirs(out, exist_ok=True)
    snaps = parse_snapshot_args(args.snapshot, args.scenarios_list)
    api_version = "?"
    with open(API_FILE, encoding="utf-8") as f:
        for line in f:
            m = re.search(r'version = "([^"]*)"', line)
            if m:
                api_version = m.group(1)
                break
    workdir = os.path.join(out, "gen") if args.keep else tempfile.mkdtemp(prefix="aura_harness_")
    os.makedirs(workdir, exist_ok=True)
    t0 = time.time()
    results = []
    with cf.ThreadPoolExecutor(max_workers=max(1, args.jobs)) as ex:
        futs = {}
        for s in args.scenarios_list:
            config = {"seed": args.seed, "mono": args.mono, "moduleName": args.module_name or stem,
                      "snapFrames": sorted(snaps.get(s, [])), "forceQuality": args.quality,
                      "camera": cameras.get(s, (None, None))[0], "cameraName": cameras.get(s, (None, None))[1], "label": s}
            futs[ex.submit(run_one, luau, module_src, module_label, s, config, workdir, args.timeout, args.keep,
                           "script" if args.script else "scenario")] = s
        for fut in cf.as_completed(futs):
            r = fut.result()
            results.append(r)
            if not args.quiet:
                nerr = sum(1 for x in r["records"] if x.get("kind") == "error")
                print("  %-22s %5.1fs  %s" % (r["scenario"], r["wall"], "ok" if r["code"] == 0 and nerr == 0 else
                                                ("%d error(s)" % nerr if r["code"] == 0 else "FAILED (exit %s)" % r["code"])), flush=True)
    results.sort(key=lambda r: args.scenarios_list.index(r["scenario"]))
    # snapshots (lists sorted by stable content keys: a module that creates instances inside pairs() over a table keyed
    # by EnumItems/Instances gets an arbitrary creation order, in Roblox too, so creation order is not reproducible)
    def stable(snap):
        def key(e, *fields):
            return tuple(json.dumps(e.get(f), sort_keys=True) for f in fields)
        order = {"parts": ("path", "class", "size", "cf"), "attachments": ("path", "worldCf"), "guis": ("path", "kind", "face", "images"),
                 "emitters": ("path", "texture", "rate", "hostCf"), "beams": ("path", "texture", "width0", "curve0"),
                 "trails": ("path", "texture"), "lights": ("path", "class"), "highlights": ("path",), "effects": ("path", "class")}
        for lst, fields in order.items():
            if isinstance(snap.get(lst), list):
                snap[lst].sort(key=lambda e: key(e, *fields))
        return snap
    snap_dir = os.path.join(out, "snapshots")
    nsnap = 0
    for r in results:
        for rec in r["records"]:
            if rec.get("kind") == "snapshot":
                snap = rec["snap"]
                d = os.path.join(snap_dir, re.sub(r"[^\w@.=-]+", "_", r["scenario"]))  # (orbit:30,10,40 -> orbit_30_10_40)
                os.makedirs(d, exist_ok=True)
                with open(os.path.join(d, "frame_%05d.json" % snap["frame"]), "w", encoding="utf-8") as f:
                    json.dump(stable(snap), f, separators=(",", ":"))
                nsnap += 1
    rep = summarize(results, module_path, module_label, args, api_version)
    rep["snapshots"] = nsnap
    rep["wallSeconds"] = round(time.time() - t0, 1)
    with open(os.path.join(out, "report.json"), "w", encoding="utf-8") as f:
        json.dump(rep, f, indent=1)
    md = md_report(rep)
    with open(os.path.join(out, "report.md"), "w", encoding="utf-8") as f:
        f.write(md)
    if not args.keep:
        shutil.rmtree(workdir, ignore_errors=True)
    nerr, nfail = len(rep["errors"]), len(rep["harnessFailures"])
    if not args.quiet:
        print("%s: %d error(s), %d warning kind(s), %d harness failure(s), %d snapshot(s) in %.1fs -> %s" % (
            module_label, nerr, len(rep["warnings"]), nfail, nsnap, rep["wallSeconds"], out))
    if nfail:
        return 2
    return 1 if nerr else 0


if __name__ == "__main__":
    sys.exit(main())
