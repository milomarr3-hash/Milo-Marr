#!/usr/bin/env python3
"""Generate the compact Roblox API table the harness's mock runtime loads (api/roblox_api.luau).

Sources (both are optional, at least one is needed):
  --defs   luau-lsp's Roblox definitions (globalTypes.None.d.luau = what a normal game script can touch). The "full"
           file (--defs-full, globalTypes.d.luau = RobloxScriptSecurity) adds the members that exist but a game
           script may not use, so the mock can say "lacking capability" instead of "not a valid member".
  --dump   Roblox's Full-API-Dump.json (MaximumADHD/Roblox-Client-Tracker). Adds what the .d.luau files do not carry:
           enum item values, ReadOnly tags, write-restricted members (e.g. MeshPart.MeshId), int vs float, default values.

The output is vendored in the repo so the harness runs offline; re-run this script to refresh it:

  python3 tools/harness/gen_api.py \
      --defs  ~/luau-lsp/scripts/globalTypes.None.d.luau \
      --defs-full ~/luau-lsp/scripts/globalTypes.d.luau \
      --dump  Full-API-Dump.json --dump-version 0.742.0.7421053

Encoding (parsed lazily per class by runtime/api.luau): API.classes[Name] = "Super|flags\\n" + one line per member:
  kind|name|type|flags|default     kind: p property, f function, e event
  type codes: number int string boolean Content ContentObj any E:<Enum> I:<Class> <DataType>
  flags: r read-only, R write-restricted (security), x not accessible to game scripts, d deprecated, h hidden, y yields
"""
import argparse
import json
import re
import sys

DATATYPES = {
    "Vector3", "Vector2", "CFrame", "Color3", "UDim", "UDim2", "NumberRange", "NumberSequence", "ColorSequence",
    "Rect", "BrickColor", "Font", "PhysicalProperties", "Faces", "Axes", "Ray", "Region3", "Region3int16",
    "Vector3int16", "Vector2int16", "DateTime", "TweenInfo", "Content", "SecurityCapabilities", "Path2DControlPoint",
}


def parse_defs(path):
    """Parse a luau-lsp definitions file into (classes, enums, metadata)."""
    classes, enums, meta = {}, {}, {}
    cur, kind, pending_dep = None, None, False
    with open(path, encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")
            if line.startswith("--#METADATA#"):
                meta = json.loads(line[len("--#METADATA#"):])
                continue
            m = re.match(r"^declare extern type (\w+)(?: extends (\w+))? with\s*$", line)
            if m:
                name, sup = m.group(1), m.group(2)
                if name.endswith("_INTERNAL") and sup == "Enum":
                    cur, kind = {"items": []}, "enum"
                    enums[name[len("Enum"):-len("_INTERNAL")]] = cur
                elif sup == "EnumItem" or name in ("Enum", "EnumItem"):
                    cur, kind = None, None
                else:
                    cur, kind = {"super": sup, "members": {}}, "class"
                    classes[name] = cur
                pending_dep = False
                continue
            if line == "end":
                cur, kind = None, None
                continue
            if cur is None:
                continue
            s = line.strip()
            if s.startswith("@"):
                if "deprecated" in s:
                    pending_dep = True
                continue
            if kind == "enum":
                m = re.match(r"^(\w+): Enum\w+$", s)
                if m:
                    cur["items"].append(m.group(1))
                continue
            m = re.match(r"^function (\w+)\(", s)
            if m:
                nm = m.group(1)
                if not nm.startswith("__"):
                    cur["members"].setdefault(nm, {"kind": "f", "type": "", "dep": pending_dep})
                pending_dep = False
                continue
            m = re.match(r"^(\w+): (.+)$", s)
            if m:
                nm, ty = m.group(1), m.group(2)
                k = "e" if ty.startswith("RBXScriptSignal") else "p"
                cur["members"][nm] = {"kind": k, "type": ty, "dep": pending_dep}
                pending_dep = False
    return classes, enums, meta


def is_instance_class(classes, name):
    seen = 0
    while name and seen < 64:
        if name in ("Instance", "Object"):
            return True
        c = classes.get(name)
        name = c and c["super"]
        seen += 1
    return False


def type_code(ty, classes, enums):
    t = ty.strip()
    if t.endswith("?"):
        t = t[:-1]
    if t in ("number",):
        return "number"
    if t in ("string", "boolean"):
        return t
    if t in ("ContentId", "ProtectedString", "BinaryString"):
        return "Content" if t == "ContentId" else "string"
    if t == "Content":
        return "ContentObj"
    if t.startswith("Enum") and t[4:] in enums:
        return "E:" + t[4:]
    if t in DATATYPES:
        return t
    if t in classes and is_instance_class(classes, t):
        return "I:" + t
    return "any"


def dump_type_code(vt):
    cat, name = vt.get("Category"), vt.get("Name")
    if cat == "Primitive":
        return {"bool": "boolean", "float": "number", "double": "number", "int": "int", "int64": "int",
                "string": "string"}.get(name, "any")
    if cat == "Enum":
        return "E:" + name
    if cat == "Class":
        return "I:" + name
    if cat == "DataType":
        if name == "ContentId":
            return "Content"
        if name == "Content":
            return "ContentObj"
        if name in ("ProtectedString", "BinaryString"):
            return "string"
        return name if name in DATATYPES else "any"
    return "any"


def esc(s):
    out = []
    for ch in s:
        o = ord(ch)
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ch == "\n":
            out.append("\\n")
        elif o < 32 or o > 126:
            out.append("\\%d" % o if o < 256 else "?")
        else:
            out.append(ch)
    return "".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--defs", required=True, help="globalTypes.None.d.luau (game-script security level)")
    ap.add_argument("--defs-full", help="globalTypes.d.luau (all security levels)")
    ap.add_argument("--dump", help="Full-API-Dump.json")
    ap.add_argument("--dump-version", default="?")
    ap.add_argument("--defs-version", default="?")
    ap.add_argument("--out", default="tools/harness/api/roblox_api.luau")
    a = ap.parse_args()

    classes, enums, meta = parse_defs(a.defs)
    full_classes = parse_defs(a.defs_full)[0] if a.defs_full else {}
    creatable = set(meta.get("CREATABLE_INSTANCES", []))
    services = set(meta.get("SERVICES", []))

    enum_values = {}
    dump_classes = {}
    if a.dump:
        with open(a.dump, encoding="utf-8") as f:
            d = json.load(f)
        for e in d["Enums"]:
            enum_values[e["Name"]] = [(it["Name"], it["Value"]) for it in e["Items"]]
        for c in d["Classes"]:
            dump_classes[c["Name"]] = c

    out_classes = {}
    names = sorted(n for n in classes if is_instance_class(classes, n))
    for name in names:
        c = classes[name]
        dc = dump_classes.get(name)
        dmem = {m["Name"]: m for m in dc["Members"]} if dc else {}
        flags = ""
        if name in creatable:
            flags += "c"
        if name in services:
            flags += "s"
        lines = ["%s|%s" % (c["super"] or "", flags)]
        members = dict(c["members"])
        # members that exist (full defs) but a game script may not use
        fc = full_classes.get(name)
        if fc:
            for nm, mm in fc["members"].items():
                if nm not in members:
                    members[nm] = dict(mm, hidden_sec=True)
        for nm in sorted(members):
            mm = members[nm]
            kind = mm["kind"]
            fl = ""
            if mm.get("dep"):
                fl += "d"
            if mm.get("hidden_sec"):
                fl += "x"
            ty = type_code(mm["type"], classes, enums) if kind == "p" else ""
            default = ""
            dm = dmem.get(nm)
            if dm:
                tags = [t for t in (dm.get("Tags") or []) if isinstance(t, str)]
                if "Deprecated" in tags and "d" not in fl:
                    fl += "d"
                if "Hidden" in tags:
                    fl += "h"
                if dm["MemberType"] == "Property":
                    sec = dm.get("Security") or {}
                    if sec.get("Read", "None") == "None" and "NotScriptable" not in tags:
                        fl = fl.replace("x", "")  # readable by game scripts (writes are checked below)
                    elif "x" not in fl:
                        fl += "x"
                    if "ReadOnly" in tags:
                        fl += "r"
                    elif sec.get("Write", "None") != "None":
                        fl += "R"
                    ty = dump_type_code(dm["ValueType"]) if ty in ("any", "number", "") or ty.startswith("I:") else ty
                    dv = dm.get("Default")
                    if isinstance(dv, str) and not dv.startswith("__api_dump"):
                        default = dv
                elif dm["MemberType"] in ("Function", "Event"):
                    if "Yields" in tags:
                        fl += "y"
                    sec = dm.get("Security", "None")
                    if isinstance(sec, str) and sec == "None" and "NotScriptable" not in tags:
                        fl = fl.replace("x", "")
                    elif isinstance(sec, str) and sec != "None" and "x" not in fl:
                        fl += "x"
            lines.append("%s|%s|%s|%s|%s" % (kind, nm, ty, fl, default.replace("|", "/").replace("\n", " ")))
        out_classes[name] = "\n".join(lines)

    out_enums = {}
    for en, e in sorted(enums.items()):
        vals = dict(enum_values.get(en, []))
        items = []
        for i, it in enumerate(e["items"]):
            items.append("%s=%s" % (it, vals.get(it, i)))
        out_enums[en] = ",".join(items)

    with open(a.out, "w", encoding="utf-8") as f:
        f.write("-- GENERATED by tools/harness/gen_api.py - do not edit by hand.\n")
        f.write("-- Sources: luau-lsp definitions (%s), Roblox Full-API-Dump %s\n" % (a.defs_version, a.dump_version))
        f.write("H.API = {\n\tversion = \"%s\",\n\tclasses = {\n" % esc(a.dump_version))
        for name in sorted(out_classes):
            f.write("\t\t%s = \"%s\",\n" % (name, esc(out_classes[name])))
        f.write("\t},\n\tenums = {\n")
        for en in sorted(out_enums):
            f.write("\t\t%s = \"%s\",\n" % (en, esc(out_enums[en])))
        f.write("\t},\n}\n")
    print("wrote %s: %d classes, %d enums (%d creatable, %d services)" % (
        a.out, len(out_classes), len(out_enums), len(creatable), len(services)))


if __name__ == "__main__":
    sys.exit(main())
