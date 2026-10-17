#!/usr/bin/env python3
"""Colour/brightness probes that compare a preview render with a real Studio screenshot of the same framing.

  python3 tools/preview/calibration_probe.py REAL.jpg PREVIEW.png [REAL2 PREVIEW2 ...] [--clock X0,Y0,X1,Y1] [--json]

Both images are scaled to 1920x913 (Studio's viewport). Measured, per pair:
  grass / sand   median colour of the pixels classified as grass or sand in the lower-right box (1300..1920, 600..913),
                 where the captures have open ground and no HUD
  sky            10th and 90th percentile of the top-right box (clear sky and cloud)
  clock          brightness percentiles (max channel) inside the dial (default box 860,230 - 1040,310: between the hands'
                 pivot and the XII mark with the "studio" camera); the real pass-4 clock is black there between fine lines
Used by tools/baseline/make_pass4.sh; the numbers it printed for the current renderer are in tools/preview/FIDELITY.md.
"""
import argparse
import json
import sys

import numpy as np
from PIL import Image

W, H = 1920, 913


def load(path):
    return np.asarray(Image.open(path).convert("RGB").resize((W, H), Image.LANCZOS)).astype(float)


def ground(a, box=(1300, 600, 1920, 913)):
    x0, y0, x1, y1 = box
    p = a[y0:y1, x0:x1].reshape(-1, 3)
    r, g, b = p[:, 0], p[:, 1], p[:, 2]
    mx, mn = p.max(1), p.min(1)
    sat = (mx - mn) / np.maximum(mx, 1)
    out = {}
    for name, m in (("grass", (g > r * 1.08) & (g > b * 1.3) & (sat > 0.3)),
                    ("sand", (r >= g) & (g >= b) & (sat < 0.45) & (sat > 0.08) & (mx > 120))):
        out[name] = [int(v) for v in np.median(p[m], 0)] if m.sum() > 50 else None
    return out


def sky(a, box=(1300, 0, 1920, 120)):
    x0, y0, x1, y1 = box
    p = a[y0:y1, x0:x1].reshape(-1, 3)
    return [int(v) for v in np.percentile(p, 10, 0)], [int(v) for v in np.percentile(p, 90, 0)]


def clock(a, box):
    x0, y0, x1, y1 = box
    p = a[y0:y1, x0:x1].reshape(-1, 3).max(1)
    return [int(v) for v in np.percentile(p, [10, 25, 50, 75, 90])]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("images", nargs="+", help="REAL PREVIEW pairs")
    ap.add_argument("--clock", default="860,230,1040,310")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    if len(a.images) % 2:
        sys.exit("give REAL PREVIEW pairs")
    box = tuple(int(v) for v in a.clock.split(","))
    rows = []
    for i in range(0, len(a.images), 2):
        pair = {}
        for kind, path in (("real", a.images[i]), ("preview", a.images[i + 1])):
            im = load(path)
            g = ground(im)
            s10, s90 = sky(im)
            pair[kind] = {"file": path, "grass": g["grass"], "sand": g["sand"], "sky10": s10, "sky90": s90, "clock": clock(im, box)}
        rows.append(pair)
    if a.json:
        print(json.dumps(rows, indent=1))
        return
    for pair in rows:
        print("%s  vs  %s" % (pair["real"]["file"].split("/")[-1], pair["preview"]["file"].split("/")[-1]))
        for k, label in (("grass", "grass"), ("sand", "sand"), ("sky10", "sky p10"), ("sky90", "sky p90"), ("clock", "clock p10/25/50/75/90")):
            print("  %-22s real %-22s preview %s" % (label, pair["real"][k], pair["preview"][k]))


if __name__ == "__main__":
    main()
