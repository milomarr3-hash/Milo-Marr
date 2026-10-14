#!/usr/bin/env python3
"""Contact sheets and real-vs-preview comparisons for preview renders (python3 + Pillow).

  python3 tools/preview/sheet.py grid OUT.png IMG [IMG ...] [--cols 3] [--width 640] [--title TEXT]
      every image scaled to --width, laid out --cols per row, each labelled with its file name (or LABEL=PATH)
  python3 tools/preview/sheet.py compare OUT.png REAL.jpg PREVIEW.png [--width 960] [--labels "Studio,preview"]
      the real Studio screenshot and the preview side by side at the same size (the preview is scaled to the real
      image's aspect); use it after a Studio capture with the "studio" camera (see tools/README.md)

Output format follows the extension (.png, or .jpg at quality 85).
"""
import argparse
import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover
    sys.exit("sheet.py needs Pillow: python3 -m pip install pillow")

FONT_PATHS = ["/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/Library/Fonts/Arial Bold.ttf"]


def font(size):
    for p in FONT_PATHS:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def label(im, text, size=None):
    d = ImageDraw.Draw(im)
    f = font(size or max(12, im.width // 48))
    x0, y0, x1, y1 = d.textbbox((0, 0), text, font=f)
    pad = max(4, (y1 - y0) // 3)
    d.rectangle([0, 0, x1 - x0 + pad * 2, y1 - y0 + pad * 2], fill=(0, 0, 0))
    d.text((pad - x0, pad - y0), text, font=f, fill=(255, 255, 255))


def split_label(arg):
    if "=" in arg and not os.path.exists(arg):
        lab, path = arg.split("=", 1)
        return lab, path
    return os.path.splitext(os.path.basename(arg))[0], arg


def save(im, out):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    if out.lower().endswith((".jpg", ".jpeg")):
        im.convert("RGB").save(out, quality=85, optimize=True, progressive=True)
    else:
        im.save(out, optimize=True)


def grid(args):
    items = [split_label(a) for a in args.images]
    ims = []
    for lab, path in items:
        im = Image.open(path).convert("RGB")
        im = im.resize((args.width, round(im.height * args.width / im.width)), Image.LANCZOS)
        label(im, lab)
        ims.append(im)
    if not ims:
        sys.exit("no images")
    cols = max(1, min(args.cols, len(ims)))
    rows = (len(ims) + cols - 1) // cols
    h = max(i.height for i in ims)
    top = 0
    if args.title:
        top = max(28, args.width // 18)
    sheet = Image.new("RGB", (args.width * cols, h * rows + top), (17, 17, 17))
    if args.title:
        d = ImageDraw.Draw(sheet)
        d.text((10, top // 6), args.title, font=font(top * 2 // 3), fill=(235, 235, 235))
    for k, im in enumerate(ims):
        sheet.paste(im, ((k % cols) * args.width, top + (k // cols) * h))
    save(sheet, args.out)


def compare(args):
    labels = (args.labels or "Studio,preview").split(",")
    real = Image.open(args.real).convert("RGB")
    prev = Image.open(args.preview).convert("RGB")
    w = args.width
    h = round(real.height * w / real.width)
    real = real.resize((w, h), Image.LANCZOS)
    prev = prev.resize((w, h), Image.LANCZOS)  # (same aspect as the real frame: the preview should be rendered with --size game)
    label(real, labels[0])
    label(prev, labels[1] if len(labels) > 1 else "preview")
    sheet = Image.new("RGB", (w * 2 + 4, h), (17, 17, 17))
    sheet.paste(real, (0, 0))
    sheet.paste(prev, (w + 4, 0))
    save(sheet, args.out)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("grid")
    g.add_argument("out")
    g.add_argument("images", nargs="+")
    g.add_argument("--cols", type=int, default=3)
    g.add_argument("--width", type=int, default=640)
    g.add_argument("--title")
    c = sub.add_parser("compare")
    c.add_argument("out")
    c.add_argument("real")
    c.add_argument("preview")
    c.add_argument("--width", type=int, default=960)
    c.add_argument("--labels")
    a = ap.parse_args()
    (grid if a.cmd == "grid" else compare)(a)


if __name__ == "__main__":
    main()
