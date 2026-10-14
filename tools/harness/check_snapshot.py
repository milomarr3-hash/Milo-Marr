#!/usr/bin/env python3
"""Validate harness snapshot frames against the shared snapshot contract (tools/harness/SNAPSHOT.md).

  python3 tools/harness/check_snapshot.py OUT/snapshots            # every frame under a directory
  python3 tools/harness/check_snapshot.py frame_00060.json ...

Checks required keys and value types for every list entry, the CF / vector shapes, enum-like fields, and that ids
referenced by beams, trails, emitters, GUIs and attachments exist. Exit 1 if any frame is invalid.
"""
import json
import os
import sys

NUM = (int, float)


def is_num(v):
    return isinstance(v, NUM) and not isinstance(v, bool)


def vec(n):
    return lambda v: isinstance(v, list) and len(v) == n and all(is_num(x) for x in v)


def nullable(check):
    return lambda v: v is None or check(v)


def seq(width):
    return lambda v: isinstance(v, list) and len(v) >= 2 and all(isinstance(k, list) and len(k) == width and all(is_num(x) for x in k) for k in v)


CF, V3, V2, RGB, U2 = vec(12), vec(3), vec(2), vec(3), vec(4)
STR = lambda v: isinstance(v, str)
BOOL = lambda v: isinstance(v, bool)
INT = lambda v: isinstance(v, int) and not isinstance(v, bool)
SHAPES = {"Block", "Ball", "Cylinder", "Wedge", "CornerWedge", "Mesh"}

SCHEMA = {
    "parts": {"id": INT, "path": STR, "class": STR, "shape": lambda v: v in SHAPES, "size": V3, "cf": CF, "color": RGB,
              "material": STR, "transparency": is_num, "localTransparencyModifier": is_num, "reflectance": is_num,
              "meshId": nullable(STR), "textureId": nullable(STR), "parentPath": nullable(STR)},
    "attachments": {"id": INT, "path": STR, "hostId": nullable(INT), "worldCf": CF},
    "beams": {"path": STR, "a0": nullable(INT), "a1": nullable(INT), "curve0": is_num, "curve1": is_num, "width0": is_num,
              "width1": is_num, "segments": is_num, "faceCamera": BOOL, "texture": STR, "textureMode": STR, "textureLength": is_num,
              "textureSpeed": is_num, "color": seq(4), "transparency": seq(3), "lightEmission": is_num, "lightInfluence": is_num,
              "brightness": is_num, "zOffset": is_num, "enabled": BOOL},
    "guis": {"kind": lambda v: v in ("SurfaceGui", "BillboardGui"), "path": STR, "hostId": nullable(INT), "face": nullable(STR),
             "canvas": nullable(V2), "sizeStuds": nullable(V2), "studsOffset": nullable(V3), "studsOffsetWorldSpace": nullable(V3),
             "brightness": is_num, "lightInfluence": is_num, "alwaysOnTop": BOOL, "enabled": BOOL, "maxDistance": nullable(is_num),
             "images": lambda v: isinstance(v, list)},
    "emitters": {"path": STR, "hostId": nullable(INT), "hostAttachmentId": nullable(INT), "enabled": BOOL, "texture": STR,
                 "rate": is_num, "lifetime": V2, "speed": V2, "spreadAngle": V2, "emissionDirection": STR, "shape": STR,
                 "shapeStyle": STR, "shapeInOut": STR, "shapePartial": is_num, "size": seq(3), "transparency": seq(3),
                 "color": seq(4), "lightEmission": is_num, "lightInfluence": is_num, "brightness": is_num, "acceleration": V3,
                 "drag": is_num, "lockedToPart": BOOL, "rotation": V2, "rotSpeed": V2, "zOffset": is_num, "orientation": STR,
                 "flipbookLayout": STR, "flipbookMode": STR, "squash": nullable(seq(3)), "timeScale": is_num},
    "trails": {"path": STR, "a0": nullable(INT), "a1": nullable(INT), "enabled": BOOL, "texture": STR, "lifetime": is_num,
               "color": seq(4), "transparency": seq(3), "widthScale": seq(3)},
    "lights": {"class": STR, "hostId": nullable(INT), "color": RGB, "brightness": is_num, "range": is_num, "enabled": BOOL},
    "highlights": {"path": STR, "adorneePath": nullable(STR), "fillColor": RGB, "fillTransparency": is_num, "outlineColor": RGB,
                   "outlineTransparency": is_num, "depthMode": STR, "enabled": BOOL},
    "effects": {"class": STR, "props": lambda v: isinstance(v, dict)},
}
IMAGE = {"image": STR, "color": RGB, "transparency": is_num, "rotation": is_num, "size": U2, "position": U2}


def check(snap):
    errs = []

    def need(obj, key, chk, where):
        if key not in obj:
            errs.append("%s: missing '%s'" % (where, key))
        elif not chk(obj[key]):
            errs.append("%s: bad '%s' = %s" % (where, key, json.dumps(obj[key])[:80]))

    need(snap, "version", lambda v: v == 1, "frame")
    for k, chk in (("scenario", STR), ("frame", INT), ("t", is_num), ("clockTime", is_num), ("quality", lambda v: v in ("high", "low"))):
        need(snap, k, chk, "frame")
    cam = snap.get("camera") or {}
    need(cam, "cf", CF, "camera")
    need(cam, "fov", is_num, "camera")
    if "wearer" in snap:
        w = snap["wearer"]
        for k, chk in (("cf", CF), ("hover", is_num), ("glide", is_num), ("legLen", is_num), ("ground", nullable(V3))):
            need(w, k, chk, "wearer")
    for lst, schema in SCHEMA.items():
        if not isinstance(snap.get(lst), list):
            errs.append("frame: '%s' must be a list" % lst)
            continue
        for i, e in enumerate(snap[lst]):
            for k, chk in schema.items():
                need(e, k, chk, "%s[%d]" % (lst, i))
            if lst == "guis":
                for j, im in enumerate(e.get("images", [])):
                    for k, chk in IMAGE.items():
                        need(im, k, chk, "guis[%d].images[%d]" % (i, j))
    part_ids = {p.get("id") for p in snap.get("parts", [])}
    att_ids = {a.get("id") for a in snap.get("attachments", [])}
    for lst in ("beams", "trails"):
        for i, b in enumerate(snap.get(lst, [])):
            for k in ("a0", "a1"):
                if b.get(k) is not None and b[k] not in att_ids:
                    errs.append("%s[%d].%s = %s is not in attachments" % (lst, i, k, b[k]))
    for i, e in enumerate(snap.get("emitters", [])):
        if e.get("hostAttachmentId") is not None and e["hostAttachmentId"] not in att_ids:
            errs.append("emitters[%d].hostAttachmentId not in attachments" % i)
        if e.get("hostId") is not None and e["hostId"] not in part_ids and "hostCf" not in e:
            errs.append("emitters[%d].hostId not in parts and no hostCf" % i)
        if (e.get("hostId") is None) == (e.get("hostAttachmentId") is None):
            errs.append("emitters[%d]: exactly one of hostId / hostAttachmentId must be set" % i)
    for i, g in enumerate(snap.get("guis", [])):
        if g.get("hostId") is not None and g["hostId"] not in part_ids and not g.get("hostCf"):
            errs.append("guis[%d].hostId not in parts and no hostCf" % i)
    return errs


def main():
    paths = sys.argv[1:]
    if not paths:
        print(__doc__)
        return 2
    files = []
    for p in paths:
        if os.path.isdir(p):
            for root, _, names in os.walk(p):
                files += [os.path.join(root, n) for n in sorted(names) if n.endswith(".json")]
        else:
            files.append(p)
    bad = 0
    for f in files:
        with open(f, encoding="utf-8") as fh:
            errs = check(json.load(fh))
        if errs:
            bad += 1
            print("INVALID %s" % f)
            for e in errs[:12]:
                print("   - " + e)
    print("%d frame(s) checked, %d invalid" % (len(files), bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
