# Reconstructed 2026-10-14 (cloud) from the Mac session transcript: the original heredoc, then the orb-detail edit
# (3 replacements), then the two appended blocks (layered dials + galaxy; inked lines + galaxy2), in that order.
# The only change: a font fallback after REG so it runs off the Mac (Liberation Serif is metric-compatible with Times).
# THE END equipped aura, pass 4 textures (Milo: "ultra realistic, just like equinox", keep the clock):
# soft photographic orbs (billboards read as true spheres from every angle), uniform beam lines for 3D orbit rings,
# and a fine-line clock sigil (hair lines + a few strong strokes + gaps, glow and ink baked).
import math, os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
OUT = os.path.dirname(os.path.abspath(__file__))
REG = "/System/Library/Fonts/Supplemental/Times New Roman.ttf"
if not os.path.exists(REG):  # (not on the Mac: use a metric-compatible Times, as close as we can get)
    REG = next((p for p in ["/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf",
                            "/usr/share/fonts/truetype/msttcorefonts/Times_New_Roman.ttf",
                            "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"] if os.path.exists(p)), REG)

def grid(n):
    y, x = np.mgrid[0:n, 0:n].astype(np.float32); c = (n - 1) / 2
    return (x - c) / c, (y - c) / c
def sstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t)
def noise(n, octaves=6, base=3, seed=0, falloff=0.55):
    rng = np.random.RandomState(seed); acc = np.zeros((n, n), np.float32); amp = 1; tot = 0
    for o in range(octaves):
        s = base * 2 ** o
        g = (rng.rand(s, s) * 255).astype(np.uint8)
        acc += np.asarray(Image.fromarray(g).resize((n, n), Image.BICUBIC), np.float32) / 255 * amp
        tot += amp; amp *= falloff
    return acc / tot
def blur(a, r):
    return np.asarray(Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r)), np.float32) / 255
def warp(n, a, amt, seed):
    h = a.shape[0]; dx = (noise(h, 4, 3, seed) - 0.5) * amt; dy = (noise(h, 4, 3, seed + 1) - 0.5) * amt
    y, x = np.mgrid[0:h, 0:h]
    xi = np.clip((x + dx * h).astype(int), 0, h - 1); yi = np.clip((y + dy * h).astype(int), 0, h - 1)
    return a[yi, xi]
def rgba(v, a, size, name):
    v = np.clip(v, 0, 1) * 255; a = np.clip(a, 0, 1) * 255
    Image.fromarray(np.dstack([v, v, v, a]).astype(np.uint8), "RGBA").resize((size, size), Image.LANCZOS).save(os.path.join(OUT, name))
def lightdark(light, dark, size, name, w=None):
    light = np.clip(light, 0, 1); dark = np.clip(dark, 0, 1)
    a = light + dark * (1 - light); v = light / np.maximum(a, 1e-4)
    img = Image.fromarray(np.dstack([v * 255, v * 255, v * 255, a * 255]).astype(np.uint8), "RGBA")
    img.resize((size, w or size) if w else (size, size), Image.LANCZOS).save(os.path.join(OUT, name))

N = 1024
x, y = grid(N); r = np.sqrt(x * x + y * y)

# --- the moon: a bright cloudy pearl, fine grey veins, a bright limb, a thin halo ring and a soft glow round it
R = 0.6; d = r / R
z = np.sqrt(np.clip(1 - d * d, 0, 1))
cl = warp(N, noise(N, 6, 3, 7), 0.12, 21)
veins = sum(np.exp(-np.abs(warp(N, noise(N, 5, b, sd), 0.08, sd + 6) - 0.5) / 0.006) * k for b, sd, k in [(4, 3, 1), (7, 13, 0.7), (11, 23, 0.5)])
shade = 0.72 + 0.28 * z ** 0.6
v_in = shade * (0.8 + 0.32 * (cl - 0.5) * 2) - 0.16 * veins * sstep(1, 0.2, d) + 0.3 * sstep(0.8, 1.0, d)
inside = sstep(1.0, 0.985, d)
halo_ring = np.exp(-((d - 1.17) / 0.012) ** 2) * 0.75 + np.exp(-((d - 1.17) / 0.05) ** 2) * 0.2
glow = np.exp(-np.clip(d - 1, 0, None) * 4.5) * 0.55 * (1 - inside)
a = np.clip(inside + (halo_ring + glow) * (1 - inside), 0, 1) * sstep(1.62, 1.4, d)
v = np.where(inside > 0, np.clip(v_in, 0, 1) * inside + (1 - inside), 1)
rgba(v, a, 512, "te4_moon.png")

# --- the void: a black sphere with fine white fractures, a hairline rim and a dark haze round it
R = 0.52; d = r / R
inside = sstep(1.0, 0.985, d)
fr = warp(N, noise(N, 5, 3, 31), 0.15, 41)
cracks = (np.exp(-np.abs(fr - 0.5) / 0.004) + 0.7 * np.exp(-np.abs(warp(N, noise(N, 5, 6, 71), 0.12, 81) - 0.5) / 0.003)) * sstep(0.95, 0.35, d) * (0.5 + 0.5 * noise(N, 3, 2, 51))
cracks = np.clip(cracks + blur(cracks, 3) * 1.2, 0, 1)
v_in = 0.03 + 0.04 * noise(N, 5, 4, 61) + cracks * 0.95 + 0.25 * np.exp(-((d - 0.97) / 0.03) ** 2)
rim = np.exp(-((d - 1.0) / 0.01) ** 2) * 0.9 + np.exp(-((d - 1.0) / 0.04) ** 2) * 0.25
haze = np.exp(-np.clip(d - 1, 0, None) * 2.5) * 0.75 * (1 - inside)
light = np.where(inside > 0, np.clip(v_in, 0, 1), rim)
lightdark(light * sstep(1.9, 1.6, d), np.maximum(inside, haze) * sstep(1.9, 1.6, d), 512, "te4_void.png")

# --- beam lines: uniform along the length (U), a crisp core with a soft glow across (V)
yy = np.arange(32, dtype=np.float32) - 15.5
prof = np.clip(np.exp(-(yy / 2.2) ** 2) + 0.35 * np.exp(-(yy / 8) ** 2), 0, 1)
a = np.tile(prof[:, None], (1, 256)); rgba(np.ones_like(a), a, 0, "x.png") if False else None
Image.fromarray(np.dstack([np.full_like(a, 255), np.full_like(a, 255), np.full_like(a, 255), a * 255]).astype(np.uint8), "RGBA").save(os.path.join(OUT, "te4_line.png"))
# engraved ring: a centre line with ticks across it (1 long + 3 short per tile)
H, W = 64, 256
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32); cy = (H - 1) / 2
a = np.exp(-((yy - cy) / 1.6) ** 2) + 0.25 * np.exp(-((yy - cy) / 6) ** 2)
for i in range(4):
    cx = i * 64 + 32; half = 26 if i == 0 else 12
    a += np.exp(-((xx - cx) / 1.4) ** 2) * sstep(half + 1, half - 2, np.abs(yy - cy))
a = np.clip(a, 0, 1)
Image.fromarray(np.dstack([np.full_like(a, 255), np.full_like(a, 255), np.full_like(a, 255), a * 255]).astype(np.uint8), "RGBA").save(os.path.join(OUT, "te4_tick.png"))

# --- the clock sigil, fine-line: hair rings, a few strong strokes broken by gaps, minute/hour ticks, thin roman numerals,
# a twelve-point star woven inside, bead rings, partial arcs, slender hands frozen at twelve
S = 2048; C = S / 2
im = Image.new("L", (S, S), 0); dr = ImageDraw.Draw(im)
def P(rr, ang): t = math.radians(ang); return (C + rr * math.sin(t), C - rr * math.cos(t))
def circ(rr, w): dr.ellipse([C - rr, C - rr, C + rr, C + rr], outline=255, width=w)
def arc(rr, a0, a1, w): dr.arc([C - rr, C - rr, C + rr, C + rr], a0 - 90, a1 - 90, fill=255, width=w)
circ(1000, 2); circ(985, 2)
for h in range(12): arc(955, h * 30 + 5, h * 30 + 25, 10)               # the strong ring, broken at each hour
for m in range(60):
    if m % 5: dr.line([P(905, m * 6), P(935, m * 6)], fill=255, width=3)
for h in range(12):
    dr.line([P(880, h * 30), P(940, h * 30)], fill=255, width=9)
    dr.ellipse([P(968, h * 30)[0] - 7, P(968, h * 30)[1] - 7, P(968, h * 30)[0] + 7, P(968, h * 30)[1] + 7], fill=255)
font = ImageFont.truetype(REG, 104)
for h, s in enumerate(["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"]):
    t = Image.new("L", (360, 160), 0); ImageDraw.Draw(t).text((180, 80), s, font=font, fill=255, anchor="mm")
    t = t.rotate(-h * 30, resample=Image.BICUBIC, expand=True)
    px, py = P(790, h * 30); im.paste(255, (int(px - t.width / 2), int(py - t.height / 2)), t)
circ(700, 2)
for k in range(120):
    px, py = P(680, k * 3); rr = 5 if k % 10 == 0 else 2.5; dr.ellipse([px - rr, py - rr, px + rr, py + rr], fill=255)
circ(600, 5)
pts = [P(600, h * 30) for h in range(12)]
for h in range(12): dr.line([pts[h], pts[(h + 5) % 12]], fill=255, width=2)  # the {12/5} star woven inside
circ(420, 2)
for k in range(72): dr.line([P(400, k * 5), P(412, k * 5)], fill=255, width=2)
for a0, a1 in [(15, 165), (195, 345)]: arc(320, a0, a1, 4)
for a0, a1 in [(-60, 60), (120, 240)]: arc(280, a0, a1, 2)
circ(70, 6); dr.ellipse([C - 18, C - 18, C + 18, C + 18], fill=255)
# slender hands at twelve: a long minute lance and a shorter hour hand with an open lozenge, a small counterweight
dr.polygon([P(860, 0), (C - 9, C - 80), (C + 9, C - 80)], fill=255)
dr.polygon([P(560, 0), P(470, -3.2), P(380, 0), P(470, 3.2)], outline=255, width=5)
dr.polygon([P(380, 0), (C - 14, C - 80), (C + 14, C - 80)], fill=255)
dr.ellipse([P(150, 180)[0] - 30, P(150, 180)[1] - 30, P(150, 180)[0] + 30, P(150, 180)[1] + 30], outline=255, width=6)
dr.line([(C, C + 80), P(150, 180)], fill=255, width=7)
lines = np.asarray(im, np.float32) / 255
light = np.clip(lines + blur(lines, 10) * 0.9 + blur(lines, 40) * 0.45, 0, 1)
dark = np.clip(blur(np.asarray(im.filter(ImageFilter.MaxFilter(15)), np.float32) / 255, 10) * 0.85, 0, 1)
lightdark(light, dark, 1024, "te4_sigil.png")
print("ok")

# --- the same clock split into layers stacked in depth (outer face / woven star / inner dial / hands), so it has parallax
def canvas():
    im = Image.new("L", (S, S), 0); return im, ImageDraw.Draw(im)
def finish(im, name, glow=1.0):
    lines = np.asarray(im, np.float32) / 255
    light = np.clip(lines + (blur(lines, 10) * 0.9 + blur(lines, 40) * 0.45) * glow, 0, 1)
    dark = np.clip(blur(np.asarray(im.filter(ImageFilter.MaxFilter(15)), np.float32) / 255, 10) * 0.85, 0, 1)
    lightdark(light, dark, 1024, name)
def mk(drawfn, name, glow=1.0):
    global im, dr
    im, dr = canvas(); drawfn(); finish(im, name, glow)
def outer():
    circ(1000, 2); circ(985, 2)
    for h in range(12): arc(955, h * 30 + 5, h * 30 + 25, 10)
    for m in range(60):
        if m % 5: dr.line([P(905, m * 6), P(935, m * 6)], fill=255, width=3)
    for h in range(12):
        dr.line([P(880, h * 30), P(940, h * 30)], fill=255, width=9)
        q = P(968, h * 30); dr.ellipse([q[0] - 7, q[1] - 7, q[0] + 7, q[1] + 7], fill=255)
    for h, s in enumerate(["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"]):
        t = Image.new("L", (360, 160), 0); ImageDraw.Draw(t).text((180, 80), s, font=font, fill=255, anchor="mm")
        t = t.rotate(-h * 30, resample=Image.BICUBIC, expand=True)
        px, py = P(790, h * 30); im.paste(255, (int(px - t.width / 2), int(py - t.height / 2)), t)
    circ(700, 2)
def middle():
    for k in range(120):
        px, py = P(680, k * 3); rr = 5 if k % 10 == 0 else 2.5; dr.ellipse([px - rr, py - rr, px + rr, py + rr], fill=255)
    circ(600, 5)
    pts = [P(600, h * 30) for h in range(12)]
    for h in range(12): dr.line([pts[h], pts[(h + 5) % 12]], fill=255, width=2)
    for h in range(0, 12, 3):  # four small diamonds on the cardinal points
        a = h * 30; dr.polygon([P(640, a), P(612, a - 2.2), P(584, a), P(612, a + 2.2)], fill=255)
def inner():
    circ(420, 2)
    for k in range(72): dr.line([P(400, k * 5), P(412, k * 5)], fill=255, width=2)
    for a0, a1 in [(15, 165), (195, 345)]: arc(320, a0, a1, 4)
    for a0, a1 in [(-60, 60), (120, 240)]: arc(280, a0, a1, 2)
    circ(70, 6)
def hands():
    dr.polygon([P(860, 0), (C - 9, C - 80), (C + 9, C - 80)], fill=255)
    dr.polygon([P(560, 0), P(470, -3.2), P(380, 0), P(470, 3.2)], outline=255, width=5)
    dr.polygon([P(380, 0), (C - 14, C - 80), (C + 14, C - 80)], fill=255)
    q = P(150, 180); dr.ellipse([q[0] - 30, q[1] - 30, q[0] + 30, q[1] + 30], outline=255, width=6)
    dr.line([(C, C + 80), q], fill=255, width=7)
    dr.ellipse([C - 22, C - 22, C + 22, C + 22], fill=255)
mk(outer, "te4_dial_outer.png"); mk(middle, "te4_dial_mid.png"); mk(inner, "te4_dial_inner.png"); mk(hands, "te4_hands.png", 1.2)

# --- the galaxy: a photographic spiral (two arms + faint spurs), dust lanes, star knots, a bright core, over a dark disc
G = 1024; gx, gy = grid(G); gr = np.sqrt(gx * gx + gy * gy) + 1e-4; th = np.arctan2(gy, gx)
ph = th - (1 / math.tan(math.radians(16))) * np.log(gr)
n1 = warp(G, noise(G, 6, 4, 101), 0.06, 111)
arm = ((1 + np.cos(2 * ph)) / 2) ** 3
spur = ((1 + np.cos(4 * ph + 1.3)) / 2) ** 6 * 0.35
disk = np.exp(-gr / 0.34) * sstep(1.0, 0.7, gr)
lightv = disk * (0.16 + (arm + spur) * 1.0) * (0.5 + 0.9 * n1)
core = np.exp(-(gr / 0.07) ** 2) + np.exp(-(gr / 0.18) ** 2) * 0.35
dust = ((1 + np.cos(2 * ph + 0.55)) / 2) ** 8 * sstep(0.95, 0.15, gr) * sstep(0.04, 0.12, gr) * (0.4 + 0.8 * noise(G, 5, 6, 121))
rng = np.random.RandomState(5); st = np.zeros((G, G), np.float32)
for _ in range(2200):
    rr = rng.rand() ** 0.8 * 0.95; aa = rng.rand() * 2 * math.pi
    st[int((rr * math.sin(aa) + 1) / 2 * (G - 1)), int((rr * math.cos(aa) + 1) / 2 * (G - 1))] = rng.rand() ** 2
stars = np.clip(blur(st, 1.0) * 6, 0, 1) * (0.35 + arm) * sstep(1.0, 0.8, gr)
light = np.clip(lightv * (1 - dust * 0.85) + core + stars, 0, 1)
dark = np.clip(dust * 0.85 * sstep(1, 0.5, gr) + 0.55 * sstep(1.0, 0.6, gr), 0, 1)
lightdark(light, dark, 1024, "te4_galaxy.png")
print("layers ok")

# --- v2 (day readability): beam lines with a dark ink edge (drawn with LightEmission 0: the white core glows, the ink
# edge keeps them readable on a bright sky), and a wider, brighter galaxy that fills the whole disc
def inkline(H, W, core_w, ink_w, ticks, name):
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32); cy = (H - 1) / 2
    core = np.exp(-((yy - cy) / core_w) ** 2)
    for cx, half in ticks:
        core = np.maximum(core, np.exp(-((xx - cx) / 1.4) ** 2) * sstep(half + 1, half - 2, np.abs(yy - cy)))
    ink = blur(np.clip(core * 3, 0, 1), ink_w) * 0.9
    light = np.clip(core + blur(core, 2) * 0.4, 0, 1)
    lightdark(light, ink, W, name, H)
inkline(32, 256, 2.0, 2.5, [], "te4_inkline.png")
inkline(64, 256, 1.6, 2.5, [(i * 64 + 32, 26 if i == 0 else 12) for i in range(4)], "te4_inktick.png")
disk = np.exp(-gr / 0.55) * sstep(1.0, 0.78, gr)
lightv = disk * (0.22 + (arm + spur) * 1.1) * (0.5 + 0.9 * n1)
light = np.clip(lightv * (1 - dust * 0.8) * 1.35 + core + stars * 1.3, 0, 1)
dark = np.clip(dust * 0.8 * sstep(1, 0.5, gr) + 0.6 * sstep(1.0, 0.7, gr), 0, 1)
lightdark(light, dark, 1024, "te4_galaxy2.png")
print("v2 ok")
