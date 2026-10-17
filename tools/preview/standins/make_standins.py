# Procedural stand-ins for the textures in THE END's TEX table that are not in this repo (the AuraCinema kit / VFX Studio
# textures and the pass-1/2 aura_work/tex + tex3 PNGs that live only on Milo's Mac). They are NOT the real images: they only
# have to look roughly right in the preview renderer (same role, shape, alpha and flipbook layout) so a render reads.
# Each file is named after its TEX key (tools/preview/texmap.json maps the real asset ids to these files).
# Run: python3 tools/preview/standins/make_standins.py   (python3 + numpy + PIL)
import math, os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = os.path.dirname(os.path.abspath(__file__))
FONT = next((p for p in ["/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf",
                         "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",
                         "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf"] if os.path.exists(p)), None)


def grid(n, m=None):
    m = m or n
    y, x = np.mgrid[0:m, 0:n].astype(np.float32)
    return (x - (n - 1) / 2) / ((n - 1) / 2), (y - (m - 1) / 2) / ((m - 1) / 2)


def sstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def noise(n, octaves=5, base=3, seed=0, falloff=0.55, m=None):
    m = m or n
    rng = np.random.RandomState(seed)
    acc = np.zeros((m, n), np.float32); amp = 1; tot = 0
    for o in range(octaves):
        s = base * 2 ** o
        g = (rng.rand(s, s) * 255).astype(np.uint8)
        acc += np.asarray(Image.fromarray(g).resize((n, m), Image.BICUBIC), np.float32) / 255 * amp
        tot += amp; amp *= falloff
    return acc / tot


def blur(a, r):
    return np.asarray(Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r)), np.float32) / 255


def save(v, a, name):
    """v = grey value (0..1) or (h, w, 3) colour, a = alpha (0..1)."""
    v = np.clip(v, 0, 1); a = np.clip(a, 0, 1)
    if v.ndim == 2:
        v = np.dstack([v, v, v])
    rgba = np.dstack([v * 255, a[..., None] * 255]).astype(np.uint8)
    Image.fromarray(rgba).save(os.path.join(OUT, name + ".png"))


def lightdark(light, dark, name):
    """white light over a dark ink halo, as in the te4 generator (one image that reads on bright and dark backgrounds)"""
    light = np.clip(light, 0, 1); dark = np.clip(dark, 0, 1)
    a = light + dark * (1 - light); v = light / np.maximum(a, 1e-4)
    save(v, a, name)


def white(a, name):
    save(np.ones_like(a), a, name)


def flipbook(frames, name):
    """16 (v, a) frames -> a 4x4 grid, row-major from the top-left (Roblox Grid4x4 order)"""
    h, w = frames[0][1].shape
    V = np.zeros((h * 4, w * 4), np.float32); A = np.zeros_like(V)
    for i, (v, a) in enumerate(frames):
        r, c = divmod(i, 4)
        V[r * h:(r + 1) * h, c * w:(c + 1) * w] = v
        A[r * h:(r + 1) * h, c * w:(c + 1) * w] = a
    save(V, A, name)


def star4(n, length=1.0, thick=0.035, core=0.18, diag=0.0, rot=0.0):
    x, y = grid(n)
    c, s = math.cos(rot), math.sin(rot)
    xr, yr = x * c - y * s, x * s + y * c
    ax, ay = np.abs(xr), np.abs(yr)
    ray = np.exp(-ay / thick) * np.clip(1 - ax / length, 0, 1) ** 2 + np.exp(-ax / thick) * np.clip(1 - ay / length, 0, 1) ** 2
    if diag:
        u, v = (xr + yr) / math.sqrt(2), (xr - yr) / math.sqrt(2)
        ray += diag * (np.exp(-np.abs(v) / (thick * 0.7)) * np.clip(1 - np.abs(u) / (length * 0.45), 0, 1) ** 2 +
                       np.exp(-np.abs(u) / (thick * 0.7)) * np.clip(1 - np.abs(v) / (length * 0.45), 0, 1) ** 2)
    r = np.sqrt(x * x + y * y)
    glow = np.exp(-(r / core) ** 2) + 0.35 * np.exp(-(r / (core * 2.5)) ** 2)
    return np.clip(ray + glow, 0, 1) * sstep(1.0, 0.92, r)


# ------------------------------------------------------------------------------------------------ soft round things
def make_soft():
    x, y = grid(256); r = np.sqrt(x * x + y * y)
    white(np.exp(-(r / 0.42) ** 2) * sstep(1.0, 0.75, r), "softGlow")      # tex3 soft glow: a wide soft radial
    white(np.clip(np.exp(-(r / 0.22) ** 2) + 0.45 * np.exp(-(r / 0.55) ** 2), 0, 1) * sstep(1.0, 0.8, r), "glow")  # kit glow dot
    # unknown ids: a neutral soft dot (grey, so it is obvious it is not a real texture)
    save(np.full_like(r, 0.8), np.exp(-(r / 0.5) ** 2) * sstep(1.0, 0.8, r), "unknown")
    # the void (tex3): a dense disc of black smoke (drawn tinted INK). Calibrated on the Studio captures (032409, 032418):
    # the 25-stud Void layer reads as solid black out to ~90% of its radius, with ragged smoky edges, and as the orbs'
    # dark halos (18-19 studs) it makes a big black smoke cloud, not a soft grey shadow
    x, y = grid(512); r = np.sqrt(x * x + y * y); th = np.arctan2(y, x)
    n = noise(512, 5, 4, 3); n2 = noise(512, 6, 6, 7)
    edge = 0.86 + 0.16 * (n - 0.5) + 0.03 * np.sin(th * 5 + 1.3)
    a = sstep(edge + 0.12, edge - 0.18, r)
    a = np.maximum(a, 0.7 * sstep(0.5, 0.78, n2) * sstep(1.0, 0.8, r) * sstep(0.45, 0.75, r))  # wisps past the edge
    save(0.02 + 0.1 * n2 * sstep(0.2, 0.9, r), np.clip(a, 0, 1) * sstep(1.0, 0.94, r), "void")
    # the rim (tex3): a ring of light
    ring = np.exp(-((r - 0.86) / 0.014) ** 2) + 0.2 * np.exp(-((r - 0.86) / 0.06) ** 2)
    white(np.clip(ring, 0, 1) * sstep(1.0, 0.97, r), "rim")


# ------------------------------------------------------------------------------------------------ star shapes
def make_stars():
    white(star4(256, 1.0, 0.03, 0.12, diag=0.5), "glint")
    white(star4(512, 1.0, 0.012, 0.08, diag=0.0) * 0.95 + 0.0, "flare_core")
    x, y = grid(512); r = np.sqrt(x * x + y * y)
    flare = star4(512, 1.0, 0.014, 0.09, diag=0.35) + 0.25 * np.exp(-np.abs(y) / 0.01) * np.clip(1 - np.abs(x), 0, 1)
    flare += 0.22 * np.exp(-((r - 0.42) / 0.012) ** 2)  # a faint halo ring
    white(np.clip(flare, 0, 1) * sstep(1.0, 0.95, r), "flare")
    os.remove(os.path.join(OUT, "flare_core.png"))
    # the spark (pass 1): a small point of light, a little elongated (the Studio captures show fine specks, not needles)
    x, y = grid(128)
    a = np.exp(-(x / 0.16) ** 2 - (y / 0.34) ** 2) + 0.35 * np.exp(-(x / 0.4) ** 2 - (y / 0.6) ** 2)
    white(np.clip(a * 1.1, 0, 1) * sstep(1.0, 0.85, np.sqrt(x * x + y * y)), "spark")
    # ash (pass 1): an irregular flake (white; tinted dark by the emitter)
    im = Image.new("L", (128, 128), 0); dr = ImageDraw.Draw(im); rng = np.random.RandomState(4)
    pts = []
    for k in range(9):
        ang = k / 9 * 2 * math.pi; rr = 40 + rng.rand() * 22
        pts.append((64 + rr * math.cos(ang), 64 + rr * 0.7 * math.sin(ang)))
    dr.polygon(pts, fill=255)
    a = blur(np.asarray(im, np.float32) / 255, 1.2)
    save(np.full_like(a, 0.85) - 0.25 * noise(128, 3, 4, 9), a, "ash")
    # the default Roblox particle texture (rbxasset://textures/particles/sparkles_main.dds): a sparkle star
    white(star4(128, 1.0, 0.05, 0.16, diag=0.6), "sparkles_main")


# ------------------------------------------------------------------------------------------------ flipbooks (4x4)
def make_flipbooks():
    n = 256
    x, y = grid(n); r = np.sqrt(x * x + y * y)
    # sparkles (kit, OneShot): a four-point sparkle that blooms then fades over the 16 frames, with two small companions
    frames = []
    for i in range(16):
        u = i / 15; s = math.sin(min(u * 1.25, 1) * math.pi) ** 0.8
        a = star4(n, 0.25 + 0.75 * s, 0.03, 0.06 + 0.1 * s, diag=0.45 * s, rot=u * 0.4) * (0.25 + 0.75 * s)
        for ox, oy, ph in [(0.45, -0.35, 0.3), (-0.4, 0.4, 0.6)]:
            ss = max(0.0, math.sin(min(max(u - ph * 0.5, 0) * 1.6, 1) * math.pi))
            a += np.exp(-((x - ox) ** 2 + (y - oy) ** 2) / (0.004 + 0.01 * ss)) * ss
        frames.append((np.ones_like(a), np.clip(a, 0, 1)))
    flipbook(frames, "sparkles")
    # puff (kit, OneShot): a dense, fluffy smoke puff (noise-warped volume, self-shaded from the top-left) that swells and
    # thins out over the 16 frames, filling most of its cell like a VFX-pack smoke flipbook
    frames = []
    warp1, warp2 = noise(n, 4, 3, 31), noise(n, 4, 3, 32)
    for i in range(16):
        u = i / 15
        R = 0.56 + 0.34 * u
        n1 = noise(n, 6, 4, 100 + i // 3) * 0.6 + noise(n, 6, 5, 140) * 0.4
        rw = r + (warp1 - 0.5) * (0.55 + 0.3 * u) + (n1 - 0.5) * 0.35
        dens = sstep(R + 0.18, R - 0.34, rw)
        detail = 0.66 + 0.34 * noise(n, 5, 8, 160 + i)
        # (fuller than a soft puff: the Studio captures show the kit smoke as dark curling billows)
        a = np.clip(dens * detail * (1.0 - 0.5 * u) * 1.4 - 0.12 * u * (1 - n1), 0, 1)
        a *= sstep(1.0, 0.8, r)
        # self-shading: denser toward the light (top-left) -> darker on the far side
        sh = np.roll(np.roll(dens, 10, axis=0), 10, axis=1)
        v = np.clip(0.62 + 0.38 * (dens - sh) * 3 + 0.18 * (n1 - 0.5), 0.35, 1)
        frames.append((v, a))
    flipbook(frames, "puff")
    # mist (kit, Loop): a broad soft veil with drifting wisps that loops
    frames = []
    base1, base2 = noise(n, 5, 3, 400), noise(n, 5, 3, 401)
    for i in range(16):
        ph = i / 16 * 2 * math.pi
        m = base1 * (0.5 + 0.5 * math.cos(ph)) + base2 * (0.5 - 0.5 * math.cos(ph))
        sh = np.roll(m, int(i * 3), axis=1)
        a = np.clip(0.35 + (sh - 0.45) * 1.6, 0, 1) * sstep(1.0, 0.25, r) * 0.65
        frames.append((np.full_like(a, 0.93), a))
    flipbook(frames, "mist")


# ------------------------------------------------------------------------------------------------ beam strips
def make_strips():
    # streak (tex3): a lens streak / travelling dash: bright in the middle of the tile, fading to both ends (U = length)
    W, H = 256, 64
    x, y = grid(W, H)
    a = np.exp(-(y / 0.12) ** 2) * np.clip(1 - np.abs(x), 0, 1) ** 1.5 + 0.35 * np.exp(-(y / 0.45) ** 2) * np.clip(1 - np.abs(x), 0, 1) ** 3
    white(np.clip(a, 0, 1), "streak")
    # pillar (kit): a soft column of light with streaks along it
    W, H = 256, 128
    x, y = grid(W, H)
    streaks = noise(W, 4, 3, 77, m=H)
    streaks = np.asarray(Image.fromarray((streaks * 255).astype(np.uint8)).resize((W // 16, H), Image.BICUBIC).resize((W, H), Image.BICUBIC), np.float32) / 255
    a = np.exp(-(y / 0.35) ** 2) * (0.55 + 0.6 * streaks) + 0.5 * np.exp(-(y / 0.08) ** 2)
    white(np.clip(a, 0, 1), "pillar")


# ------------------------------------------------------------------------------------------------ rings and discs
def make_rings():
    S = 1024; C = S / 2
    x, y = grid(S); r = np.sqrt(x * x + y * y); th = np.arctan2(y, x)

    def P(rr, ang):
        t = math.radians(ang); return (C + rr * math.sin(t), C - rr * math.cos(t))

    # gring (tex3): an engraved clock ring for the ground (58 studs) and the tilted rings. Matched to what the Studio captures
    # show on the ground: a bold outer double band, ticks, big serif hour numerals with four-point stars between them, and
    # small triangles pointing at the centre further in
    im = Image.new("L", (S, S), 0); dr = ImageDraw.Draw(im)
    for rr, w in [(507, 8), (493, 3), (330, 3)]:
        dr.ellipse([C - rr, C - rr, C + rr, C + rr], outline=255, width=w)
    for m in range(60):
        L = 30 if m % 5 == 0 else 14
        dr.line([P(486, m * 6), P(486 - L, m * 6)], fill=255, width=6 if m % 5 == 0 else 3)
    for h in range(12):  # four-point stars between the numerals
        a0 = h * 30 + 15; cx, cy = P(405, a0); R1, R2 = 30, 7
        pts = []
        for k in range(8):
            t = math.radians(a0 + k * 45); rr = R1 if k % 2 == 0 else R2
            pts.append((cx + rr * math.sin(t), cy - rr * math.cos(t)))
        dr.polygon(pts, fill=255)
        tx, ty = P(352, h * 30)  # a triangle pointing at the centre
        dr.polygon([P(338, h * 30), P(372, h * 30 - 3.2), P(372, h * 30 + 3.2)], fill=255)
    if FONT:
        font = ImageFont.truetype(FONT, 78)
        for h, s_ in enumerate(["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"]):
            t = Image.new("L", (240, 120), 0); ImageDraw.Draw(t).text((120, 60), s_, font=font, fill=255, anchor="mm")
            t = t.rotate(-h * 30, resample=Image.BICUBIC, expand=True)
            px, py = P(418, h * 30); im.paste(255, (int(px - t.width / 2), int(py - t.height / 2)), t)
    lines = np.asarray(im, np.float32) / 255
    lightdark(np.clip(lines + blur(lines, 4) * 0.5, 0, 1), np.clip(blur(lines, 6) * 0.6, 0, 1), "gring")

    # ornate (kit): an ornate magic ring — double rings, a band of diamonds and scrolls, an inner star
    im = Image.new("L", (S, S), 0); dr = ImageDraw.Draw(im)
    for rr, w in [(500, 6), (470, 3), (330, 3), (300, 6), (150, 3)]:
        dr.ellipse([C - rr, C - rr, C + rr, C + rr], outline=255, width=w)
    for k in range(24):
        a0 = k * 15
        dr.polygon([P(462, a0), P(400, a0 - 3.5), P(338, a0), P(400, a0 + 3.5)], outline=255, width=3)
        dr.arc([P(400, a0 + 7.5)[0] - 22, P(400, a0 + 7.5)[1] - 22, P(400, a0 + 7.5)[0] + 22, P(400, a0 + 7.5)[1] + 22], 0, 360, fill=255, width=2)
    pts = [P(290, k * 45) for k in range(8)]
    for k in range(8):
        dr.line([pts[k], pts[(k + 3) % 8]], fill=255, width=3)
    lines = np.asarray(im, np.float32) / 255
    white(np.clip(lines + blur(lines, 6) * 0.8, 0, 1), "ornate")

    # swirlRing (kit): a ring of swirling strokes (spun fast by the emitter)
    # (faint: in the Studio captures the spinning ring round the void barely shows, by day or by night)
    a = np.zeros((S, S), np.float32)
    rng = np.random.RandomState(12)
    for k in range(14):
        r0 = 0.6 + rng.rand() * 0.3; ph = rng.rand() * 2 * math.pi; ln = 0.5 + rng.rand() * 1.2
        d = ((th - ph) % (2 * math.pi))
        a += np.exp(-((r - r0 + 0.08 * d / ln) / 0.008) ** 2) * sstep(ln, 0, d) * sstep(0, 0.15, d)
    white(np.clip(a * 0.3 + blur(np.clip(a, 0, 1), 6) * 0.1, 0, 0.25) * sstep(1.0, 0.95, r), "swirlRing")

    # swirl (kit): spiral arms of light for the ground
    ph = th - 3.2 * np.log(r + 1e-3)
    arms = ((1 + np.cos(3 * ph)) / 2) ** 6
    n1 = noise(S, 5, 4, 31)
    a = arms * sstep(1.0, 0.55, r) * sstep(0.05, 0.25, r) * (0.55 + 0.6 * n1)
    white(np.clip(a * 1.3, 0, 1), "swirl")

    # shards (tex3): thin slivers of light radiating out from an empty centre
    im = Image.new("L", (S, S), 0); dr = ImageDraw.Draw(im); rng = np.random.RandomState(8)
    # (sparse and faint: in the Studio captures only a handful of long thin rays show round the clock, mostly at night)
    for k in range(30):
        ang = k * 360 / 30 + rng.rand() * 6
        r0 = 340 + rng.rand() * 70; r1 = r0 + 60 + rng.rand() * 100 * (1.6 if k % 5 == 0 else 1)
        w = 0.5 + rng.rand() * 0.8 + (0.6 if k % 5 == 0 else 0)
        dr.polygon([P(r0, ang), P((r0 + r1) / 2, ang - w * 0.25), P(min(r1, 505), ang), P((r0 + r1) / 2, ang + w * 0.25)], fill=int(80 + rng.rand() * 110))
    lines = np.asarray(im, np.float32) / 255
    white(np.clip(lines * 0.75 + blur(lines, 5) * 0.25, 0, 1), "shards")

    # galaxy (tex3): a bolder, simpler spiral than te4 — two bright arms over a dark disc
    gr = r + 1e-4
    ph = th - (1 / math.tan(math.radians(18))) * np.log(gr)
    arm = ((1 + np.cos(2 * ph)) / 2) ** 4
    n1 = noise(S, 6, 4, 55)
    light = np.clip(np.exp(-gr / 0.4) * (0.2 + arm * 1.1) * (0.5 + 0.8 * n1) * sstep(1, 0.7, gr) + np.exp(-(gr / 0.08) ** 2), 0, 1)
    dark = np.clip(0.6 * sstep(1.0, 0.6, gr), 0, 1)
    lightdark(light, dark, "galaxy")


# ------------------------------------------------------------------------------------------------ the pass-2 clock (tex3)
def make_clock():
    S = 1024; C = S / 2

    def P(rr, ang):
        t = math.radians(ang); return (C + rr * math.sin(t), C - rr * math.cos(t))

    # sigil: a radiant clock — a crown of light spikes, bold rings and numerals, hands at twelve
    im = Image.new("L", (S, S), 0); dr = ImageDraw.Draw(im)
    for k in range(48):
        L = 500 if k % 4 == 0 else 470
        dr.polygon([P(430, k * 7.5 - 1.6), P(L, k * 7.5), P(430, k * 7.5 + 1.6)], fill=255)
    for rr, w in [(425, 10), (400, 4), (300, 4), (120, 6)]:
        dr.ellipse([C - rr, C - rr, C + rr, C + rr], outline=255, width=w)
    for m in range(60):
        dr.line([P(398, m * 6), P(380 if m % 5 else 360, m * 6)], fill=255, width=6 if m % 5 == 0 else 3)
    if FONT:
        font = ImageFont.truetype(FONT, 58)
        for h, s in enumerate(["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"]):
            t = Image.new("L", (200, 100), 0); ImageDraw.Draw(t).text((100, 50), s, font=font, fill=255, anchor="mm")
            t = t.rotate(-h * 30, resample=Image.BICUBIC, expand=True)
            px, py = P(330, h * 30); im.paste(255, (int(px - t.width / 2), int(py - t.height / 2)), t)
    dr.polygon([P(370, 0), (C - 10, C), (C + 10, C)], fill=255)
    dr.polygon([P(250, 0), (C - 16, C), (C + 16, C)], fill=255)
    dr.ellipse([C - 26, C - 26, C + 26, C + 26], fill=255)
    lines = np.asarray(im, np.float32) / 255
    lightdark(np.clip(lines + blur(lines, 6) * 0.9 + blur(lines, 24) * 0.4, 0, 1), np.clip(blur(lines, 8) * 0.8, 0, 1), "sigil")
    # hands (tex3): bold hands frozen at twelve
    im = Image.new("L", (S, S), 0); dr = ImageDraw.Draw(im)
    dr.polygon([P(420, 0), P(200, -4), (C - 9, C), (C + 9, C), P(200, 4)], fill=255)
    dr.polygon([P(290, 0), P(170, -7), (C - 16, C), (C + 16, C), P(170, 7)], fill=255)
    dr.ellipse([C - 30, C - 30, C + 30, C + 30], fill=255)
    lines = np.asarray(im, np.float32) / 255
    lightdark(np.clip(lines + blur(lines, 6) * 0.9, 0, 1), np.clip(blur(lines, 8) * 0.8, 0, 1), "hands")


if __name__ == "__main__":
    make_soft(); make_stars(); make_flipbooks(); make_strips(); make_rings(); make_clock()
    print("standins ok:", sorted(f for f in os.listdir(OUT) if f.endswith(".png")))
