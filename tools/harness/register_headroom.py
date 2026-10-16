#!/usr/bin/env python3
"""Register headroom check for an aura module: does End.build still compile with N more live locals?

Luau allows 200 live local registers per function. THE END's End.build holds ~170 top-level locals (helpers, group ids
that are not constants, state the frame closures capture); one more past the limit and the module stops compiling, so
pcall(require) fails in Studio and the aura shows nothing. This inserts N extra non-constant locals at the very top of
End.build (so they stay live through its deepest point), uses them once just before End.build's final `return fx`, and
compiles with the luau CLI (compile errors are reported before anything runs).

    python3 tools/harness/register_headroom.py MODULE.lua [--spare 16] [--opt 0,1,2] [--luau PATH]
    python3 tools/harness/register_headroom.py MODULE.lua --measure     # how many spare registers there are

--opt: the Luau optimisation levels to compile at (default 0,1,2; the result is the worst of them). At -O1/-O2 locals that
only hold constants are folded away; at -O0 (a debugging compile) they take real registers, so it has the least headroom.

Exit code 0 = at least --spare registers left, 1 = fewer, 2 = could not check.
"""
import argparse, os, re, subprocess, sys, tempfile

LUAU = os.environ.get("LUAU_BIN", "/home/user/luau-lang/luau/build/luau")


def compiles(src, luau, opt=1):
    with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False) as f:
        f.write(src)
        path = f.name
    try:
        r = subprocess.run([luau, "-O%d" % opt, path], capture_output=True, text=True, timeout=30)
        out = r.stdout + r.stderr
        return "Out of local registers" not in out and "SyntaxError" not in out, out
    finally:
        os.unlink(path)


def with_extra(src, n):
    m = re.search(r"(?m)^function End\.build\(ctx\)\s*\n", src)
    hits = [x.start() for x in re.finditer(r"(?m)^\treturn fx\s*$", src)]
    if not m or not hits:
        raise SystemExit("register_headroom: no `function End.build(ctx)` ... `\\treturn fx` found")
    top, ret = m.end(), hits[-1]
    if n == 0:
        return src
    extra = "".join("\tlocal __headroom%d = {} -- (register_headroom)\n" % k for k in range(n))
    uses = "\tif __headroom0 == nil then print(%s) end\n" % ", ".join("__headroom%d" % k for k in range(n))
    return src[:top] + extra + src[top:ret] + uses + src[ret:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("module")
    ap.add_argument("--spare", type=int, default=16)
    ap.add_argument("--measure", action="store_true")
    ap.add_argument("--luau", default=LUAU)
    ap.add_argument("--opt", default="0,1,2", help="Luau optimisation levels to check, e.g. 0,1,2 (the worst one counts)")
    a = ap.parse_args()
    levels = [int(x) for x in a.opt.split(",") if x.strip() != ""]
    src = open(a.module, encoding="utf-8").read()
    name = os.path.basename(a.module)
    for lv in levels:
        ok, out = compiles(src, a.luau, lv)
        if not ok:
            print("register_headroom: the module itself does not compile at -O%d:\n%s" % (lv, out[:400]))
            return 2
    if a.measure:
        spare = {}
        for lv in levels:
            n = 0
            while n < 200 and compiles(with_extra(src, n + 1), a.luau, lv)[0]:
                n += 1
            spare[lv] = n
        worst = min(spare.values())
        print("%s: End.build has %d spare local registers (limit 200; %s)" % (
            name, worst, ", ".join("-O%d: %d" % (lv, spare[lv]) for lv in levels)))
        return 0 if worst >= a.spare else 1
    bad = []
    for lv in levels:
        ok, out = compiles(with_extra(src, a.spare), a.luau, lv)
        if not ok:
            bad.append((lv, out.strip().splitlines()[0] if out.strip() else ""))
    print("%s: End.build %s %d extra locals at %s" % (name, "compiles with" if not bad else "does NOT compile with", a.spare,
                                                      ", ".join("-O%d" % lv for lv in levels)))
    for lv, msg in bad:
        print("  -O%d: %s" % (lv, msg))
    return 0 if not bad else 1


if __name__ == "__main__":
    sys.exit(main())
