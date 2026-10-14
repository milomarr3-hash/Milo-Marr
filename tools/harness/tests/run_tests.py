#!/usr/bin/env python3
"""Harness self-tests.

  1. Unit specs (spec_*.luau, script mode): mock datatypes and the Instance model behave like Roblox.
  2. Broken modules (modules/bad_*.lua): each deliberate defect is reported (error or warning, per its EXPECT header);
     good_minimal.lua must come out clean.
  3. The REAL pass-4 module across all scenarios: it runs without errors in Studio, so it must run clean here
     (any error is a harness bug). --update-baseline rewrites baseline/pass4-report.md (+ .json).

  python3 tools/harness/tests/run_tests.py            # everything
  python3 tools/harness/tests/run_tests.py -k bad_enum # only matching tests
  python3 tools/harness/tests/run_tests.py --update-baseline
"""
import argparse
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
HARNESS = os.path.dirname(HERE)
REPO = os.path.dirname(os.path.dirname(HARNESS))
RUN = os.path.join(HARNESS, "run_aura.py")
PASS4 = os.path.join(REPO, "roblox", "ReplicatedStorage", "AuraFX", "TheEnd.pass4-live.lua")
sys.path.insert(0, HARNESS)
import run_aura  # noqa: E402  (for the scenario list)


def headers(path):
    exp, scen, args, mode, only = [], "day_idle", [], "scenario", False
    with open(path, encoding="utf-8") as f:
        for line in f:
            if not line.startswith("--"):
                break
            body = line[2:].strip()
            if body.startswith("EXPECT error:"):
                exp.append(("error", None, body.split(":", 1)[1].strip()))
            elif body.startswith("EXPECT warning["):
                code = body[len("EXPECT warning["):body.index("]")]
                exp.append(("warning", code, body.split(":", 1)[1].strip()))
            elif body == "EXPECT timeout":
                exp.append(("timeout", None, None))
            elif body == "EXPECT clean":
                exp.append(("clean", None, None))
            elif body == "EXPECT only-listed":
                only = True
            elif body.startswith("SCENARIOS:"):
                scen = body.split(":", 1)[1].strip()
            elif body.startswith("ARGS:"):
                args = body.split(":", 1)[1].split()
            elif body.startswith("MODE:"):
                mode = body.split(":", 1)[1].strip()
    return exp, scen, args, mode, only


def run(path, out, scen, extra, mode):
    cmd = [sys.executable, RUN, path, "--out", out, "--quiet"]
    if "--snapshot" not in extra:
        cmd += ["--snapshot", "none"]
    cmd += ["--script"] if mode == "script" else ["--scenarios", scen]
    p = subprocess.run(cmd + extra, capture_output=True, text=True, timeout=900)
    rep_path = os.path.join(out, "report.json")
    if not os.path.exists(rep_path):
        return None, p
    with open(rep_path, encoding="utf-8") as f:
        return json.load(f), p


def check_expectations(rep, exp, only):
    problems = []
    errs = [e["msg"] for e in rep["errors"]]
    warns = [(w["code"], w["msg"]) for w in rep["warnings"]]
    if any(k == "timeout" for k, _, _ in exp):
        if not any("TIMEOUT" in f["msg"] for f in rep["harnessFailures"]):
            problems.append("expected a timeout, got: %s" % (rep["harnessFailures"] or "none"))
        return problems
    if rep["harnessFailures"]:
        problems.append("harness failure: %s" % rep["harnessFailures"][0])
    matched_err = set()
    for kind, code, sub in exp:
        if kind == "clean":
            if errs:
                problems.append("expected clean, got errors: %s" % errs[:3])
            if warns:
                problems.append("expected clean, got warnings: %s" % warns[:3])
        elif kind == "error":
            hits = [i for i, m in enumerate(errs) if sub in m]
            if not hits:
                problems.append("missing error containing %r (errors: %s)" % (sub, errs[:4]))
            matched_err.update(hits)
        elif kind == "warning":
            if not any(c == code and sub in m for c, m in warns):
                problems.append("missing warning [%s] containing %r (warnings: %s)" % (code, sub, [w for w in warns if w[0] == code][:3] or warns[:4]))
    if only:
        extra = [m for i, m in enumerate(errs) if i not in matched_err]
        if extra:
            problems.append("unexpected errors: %s" % extra[:3])
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-k", help="only tests whose name contains this")
    ap.add_argument("--update-baseline", action="store_true", help="rewrite baseline/pass4-report.md from this run")
    ap.add_argument("--skip-pass4", action="store_true")
    a = ap.parse_args()
    tmp = tempfile.mkdtemp(prefix="harness_tests_")
    tests = sorted(glob.glob(os.path.join(HERE, "spec_*.luau"))) + sorted(glob.glob(os.path.join(HERE, "modules", "*.lua")))
    if a.k:
        tests = [t for t in tests if a.k in os.path.basename(t)]
    failed = 0
    for t in tests:
        name = os.path.splitext(os.path.basename(t))[0]
        exp, scen, extra, mode, only = headers(t)
        if not exp:
            print("SKIP %s (no EXPECT header)" % name)
            continue
        rep, proc = run(t, os.path.join(tmp, name), scen, extra, mode)
        if rep is None:
            failed += 1
            print("FAIL %s: no report (%s)" % (name, (proc.stderr or proc.stdout)[-500:]))
            continue
        problems = check_expectations(rep, exp, only)
        if problems:
            failed += 1
            print("FAIL %s" % name)
            for p in problems:
                print("     - %s" % p)
        else:
            print("ok   %s" % name)
    if not a.skip_pass4 and (not a.k or a.k in "pass4"):
        out = os.path.join(tmp, "pass4")
        rep, proc = run(PASS4, out, "all", ["--snapshot", "all:t=1,3,6,10"], "scenario")
        if rep is None:
            failed += 1
            print("FAIL pass4: no report (%s)" % (proc.stderr or proc.stdout)[-800:])
        else:
            n = len(rep["scenarios"])
            if rep["errors"] or rep["harnessFailures"] or n != len(run_aura.SCENARIOS):
                failed += 1
                print("FAIL pass4 (must run clean: it runs without errors in Studio): %d errors, %d harness failures, %d scenarios" % (
                    len(rep["errors"]), len(rep["harnessFailures"]), n))
                for e in rep["errors"][:5]:
                    print("     - %s at %s" % (e["msg"], e["location"]))
                for f in rep["harnessFailures"][:3]:
                    print("     - harness: %s %s" % (f["scenario"], f.get("stderr", "")[-300:]))
            else:
                print("ok   pass4 (%d scenarios clean, %d warning kinds, %d snapshots)" % (n, len(rep["warnings"]), rep.get("snapshots", 0)))
            chk = subprocess.run([sys.executable, os.path.join(HARNESS, "check_snapshot.py"), os.path.join(out, "snapshots")],
                                 capture_output=True, text=True)
            if chk.returncode != 0 or rep.get("snapshots", 0) == 0:
                failed += 1
                print("FAIL pass4 snapshots: %s" % (chk.stdout[-800:] or "no snapshots"))
            else:
                print("ok   pass4 snapshots match the contract (%s)" % chk.stdout.strip().split("\n")[-1])
            if a.update_baseline:
                base = os.path.join(HARNESS, "baseline")
                os.makedirs(base, exist_ok=True)
                shutil.copy(os.path.join(out, "report.md"), os.path.join(base, "pass4-report.md"))
                with open(os.path.join(out, "report.json"), encoding="utf-8") as f:
                    full = json.load(f)
                full["module"] = os.path.relpath(PASS4, REPO)
                with open(os.path.join(base, "pass4-report.json"), "w", encoding="utf-8") as f:
                    json.dump(full, f, indent=1)
                print("     baseline updated: tools/harness/baseline/pass4-report.md")
    # camera overrides (--camera / scenario@camera): the snapshot camera must be where the preview renderer's view of the same
    # name puts it (presets read from tools/preview/web/views.js), and "studio" must reproduce the Mac session's captures
    if not a.skip_pass4 and (not a.k or a.k in "camera"):
        out = os.path.join(tmp, "camera")
        rep, proc = run(PASS4, out, "day_idle@studio,day_idle@front34,night_idle@orbit:200,10,30,2", ["--snapshot", "all:t=4"], "scenario")
        problems = []
        if rep is None or rep["errors"] or rep["harnessFailures"]:
            problems.append("run failed: %s" % ((proc.stderr or proc.stdout)[-400:] if rep is None else rep["errors"][:2] or rep["harnessFailures"][:2]))
        else:
            import math
            presets = run_aura.orbit_presets()
            if presets.get("front34") != (45.0, 12.0, 48.0, 5.0):
                problems.append("front34 preset not read from views.js: %r" % (presets.get("front34"),))

            def snap(name):
                d = os.path.join(out, "snapshots", re.sub(r"[^\w@.=-]+", "_", name))
                fs = sorted(os.listdir(d)) if os.path.isdir(d) else []
                with open(os.path.join(d, fs[0]), encoding="utf-8") as f:
                    return json.load(f)

            def orbit_pos(sn, az, el, dist, ty):  # the renderer's views.js formula (wearer facing -Z here)
                w = sn["wearer"]
                bx, by, bz = w["cf"][0], w["cf"][1] + w["hover"] + ty, w["cf"][2]
                a, e = math.radians(az), math.radians(el)
                hx, hz = math.sin(a), -math.cos(a)  # front = -Z, right = +X
                return (bx + hx * math.cos(e) * dist, by + math.sin(e) * dist, bz + hz * math.cos(e) * dist)

            checks = [("day_idle@studio", (8.2378, 5.5297, -39.1295), "studio"),
                      ("day_idle@front34", None, "front34"), ("night_idle@orbit:200,10,30,2", None, "orbit:200,10,30,2")]
            for name, want, preset in checks:
                try:
                    sn = snap(name)
                except (OSError, IndexError) as ex:
                    problems.append("%s: no snapshot (%s)" % (name, ex))
                    continue
                got = sn["camera"]["cf"][:3]
                if want is None:
                    want = orbit_pos(sn, *(presets["front34"] if preset == "front34" else (200, 10, 30, 2)))
                if max(abs(g - w_) for g, w_ in zip(got, want)) > 0.02:
                    problems.append("%s: camera at %s, expected %s" % (name, [round(x, 3) for x in got], [round(x, 3) for x in want]))
                if sn["camera"].get("preset") != preset or sn["scenario"] != name:
                    problems.append("%s: camera.preset %r / scenario %r" % (name, sn["camera"].get("preset"), sn["scenario"]))
        if problems:
            failed += 1
            print("FAIL camera overrides")
            for p_ in problems:
                print("     - %s" % p_)
        else:
            print("ok   camera overrides (studio, front34 = the renderer's preset, orbit spec; snapshot camera.preset)")
    # static type-check (only when a luau-lsp binary is available): --strict --api-only must flag the API mistakes
    lsp = os.environ.get("LUAU_LSP") or shutil.which("luau-lsp")
    if lsp and (not a.k or a.k in "typecheck"):
        expect = {"bad_unknown_property": "not found in external type 'Part'", "bad_enum": "'Enum.PartType' but got 'Enum.Material'",
                  "bad_type_assign": "'Color3', but got 'Vector3'", "good_pass5_features": None}
        for name, sub in expect.items():
            path = os.path.join(HERE, "modules", name + ".lua")
            p = subprocess.run([os.path.join(HARNESS, "typecheck.sh"), "--strict", "--api-only", path], capture_output=True, text=True,
                               env=dict(os.environ, LUAU_LSP=lsp))
            out = p.stdout
            ok = (sub in out) if sub else ("   0 type error(s)" in out)
            if ok:
                print("ok   typecheck %s" % name)
            else:
                failed += 1
                print("FAIL typecheck %s: %s" % (name, (out + p.stderr)[-600:]))
    else:
        print("skip typecheck (set LUAU_LSP to a luau-lsp binary to include it)")
    shutil.rmtree(tmp, ignore_errors=True)
    print("%d failed" % failed if failed else "all tests passed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
