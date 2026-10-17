# Textures for the preview fixtures: labelled faces (with an arrow pointing to the image's top) and an arrow strip
# (arrows pointing along +U, i.e. from a beam's Attachment0 toward Attachment1). They make orientation conventions visible.
# Run: python3 tools/preview/fixtures/make_fixture_tex.py
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tex")
os.makedirs(OUT, exist_ok=True)
FONT = next((p for p in ["/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"] if os.path.exists(p)), None)
font = ImageFont.truetype(FONT, 64) if FONT else ImageFont.load_default()
small = ImageFont.truetype(FONT, 34) if FONT else ImageFont.load_default()

FACES = {"front": ("FRONT", "-Z", (40, 90, 200)), "back": ("BACK", "+Z", (200, 60, 50)), "top": ("TOP", "+Y", (40, 160, 70)),
         "bottom": ("BOTTOM", "-Y", (120, 120, 40)), "left": ("LEFT", "-X", (150, 60, 170)), "right": ("RIGHT", "+X", (230, 140, 30))}
for k, (label, axis, col) in FACES.items():
    im = Image.new("RGBA", (256, 256), col + (255,))
    d = ImageDraw.Draw(im)
    d.rectangle([4, 4, 251, 251], outline=(255, 255, 255, 255), width=6)
    d.polygon([(128, 14), (98, 60), (158, 60)], fill=(255, 255, 255, 255))  # arrow to the image's top
    d.rectangle([120, 58, 136, 92], fill=(255, 255, 255, 255))
    d.text((128, 140), label, font=font if len(label) < 6 else small, fill=(255, 255, 255, 255), anchor="mm")
    d.text((128, 200), axis, font=small, fill=(255, 255, 255, 255), anchor="mm")
    d.text((22, 230), "L", font=small, fill=(255, 255, 255, 200), anchor="mm")  # left edge marker
    im.save(os.path.join(OUT, "face_%s.png" % k))

# arrow strip: 256 x 64, arrows pointing right (+U), white on a dark band
im = Image.new("RGBA", (256, 64), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
d.rectangle([0, 18, 255, 46], fill=(20, 20, 24, 255))
for x in (20, 148):
    d.polygon([(x, 22), (x + 70, 32), (x, 42)], fill=(255, 255, 255, 255))
d.rectangle([0, 18, 6, 46], fill=(255, 60, 60, 255))  # U = 0 marked red
im.save(os.path.join(OUT, "arrow_strip.png"))
print("fixture textures ok")
