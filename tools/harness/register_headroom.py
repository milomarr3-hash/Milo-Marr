#!/usr/bin/env python3
"""Register headroom check for an aura module: does End.build still compile with N more live locals?

Luau allows 200 live local registers per function. THE END's End.build holds ~170 top-level locals (helpers, group ids
that are not constants, state the frame closures capture); one more past the limit and the module stops compiling, so
pcall(require) fails in Studio and the aura shows nothing. This inserts N extra non-constant locals at the very top of
End.build (so they stay live through its deepest point), uses them once just before End.build's final `return fx`, and
compiles with the luau CLI (compile errors are reported before anything runs).

    python3 tools/harness/register_headroom.py MODULE.lua [--spare 16] [--luau PATH]
    python3 tools/harness/register_headroom.py MODULE.lua --measure     # how many spare registers there are

Exit code 0 = at least --spare registers left, 1 = fewer, 2 = could not check.
"""
import argparse, os, re, subprocess, sys, tempfile

LUAU = os.environ.get("LUAU_BIN", "/home/user/luau-lang/luau/build/luau")


def compiles(src, luau):
    with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False) as f:
        f.write(src)
        path = f.name
    try:
        r = subprocess.run([luau, path], capture_output=True, text=True, timeout=30)
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
    a = ap.parse_args()
    src = open(a.module, encoding="utf-8").read()
    ok, out = compiles(src, a.luau)
    if not ok:
        print("register_headroom: the module itself does not compile:\n" + out[:400])
        return 2
    if a.measure:
        n = 0
        while n < 200 and compiles(with_extra(src, n + 1), a.luau)[0]:
            n += 1
        print("%s: End.build has %d spare local registers (limit 200)" % (os.path.basename(a.module), n))
        return 0 if n >= a.spare else 1
    ok, out = compiles(with_extra(src, a.spare), a.luau)
    print("%s: End.build %s %d extra locals" % (os.path.basename(a.module), "compiles with" if ok else "does NOT compile with", a.spare))
    if not ok:
        print(out.strip().splitlines()[0])
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
