#!/usr/bin/env python3
# THE END (1 in 1,000,000,000) -- equipped aura, pass 5 "The Last Clock" -- texture group "particles".
#
# Spec: docs/the-end/pass5-spec.md, section 16.2 (group "particles") and section 9 (the emitters that use them). 7 textures:
#   te5_shards  (1024^2, Grid4x4 Loop)     P3 metal shards breaking off the bezel and flying into the void
#   te5_smoke   (1024^2, Grid4x4 OneShot)  P4a/P4b two-tone rim smoke, P7 ground mist
#   te5_mote    (128^2)                    P1 void swirl, P2 moon dust, P6a air dust, P8a galaxy motes, P11 foot drips
#   te5_glint   (256^2)                    P5a/P5b glints riding the metal, P6b air glints
#   te5_bokeh   (256^2)                    P6c big slow bokeh between the camera and the wearer
#   te5_streak  (256^2)                    P9 funnel, P10a/b palm intake, P12 speed trail (VelocityParallel; the TOP leads)
#   te5_ash     (256^2)                    P8b black ash flakes rising off the galaxy (one flake: rotation and spin vary it)
#
# Only python3 + numpy + PIL (runs the same on Milo's Mac and in the cloud). Deterministic: every random source is
# seeded, so a re-run gives byte-identical PNGs.
#
#   python3 make_te5_particles.py              # all textures + manifest + contact sheets (sheets/) + checks
#   python3 make_te5_particles.py --no-sheets  # textures + manifest + checks
#   python3 make_te5_particles.py --only te5_mote,te5_glint
#   python3 make_te5_particles.py --check      # only the numerical spec checks on the PNGs
#
# How the images are made (film-quality rules from the spec):
#   * Everything is rendered at 2x (SS) and box-filtered down in PREMULTIPLIED alpha, so anti-aliased edges are exact.
#   * Hard shapes (shard faces, flakes, the hexagon, capsules, discs) come from exact signed-distance fields, so every
#     edge has a true 1 px anti-aliased ramp and its ink outline follows it exactly.
#   * After downsampling, colour is un-premultiplied and BLED into the fully transparent pixels (nearest visible colour,
#     per flipbook cell), so Roblox's bilinear filtering and mip-maps never mix black into an edge: no fringes.
#   * Soft gradients (smoke, glow, bokeh, tails) get +-1 LSB triangular dither before 8-bit quantisation: no banding.
#   * Monochrome: every pixel is neutral grey (R = G = B). The particle Color supplies the faint cool tint.
#   * Flipbooks: cells are laid out row-major from the top-left (Roblox order), each cell keeps its padding, and
#     colour bleeding never crosses a cell border.
import argparse, json, math, os, sys, time
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.dirname(os.path.abspath(__file__))
SHEETS = os.path.join(OUT, "sheets")
REPO_DIR = "textures/te5/particles"
SS = 2                      # supersampling factor
F32 = np.float32

# contact-sheet backgrounds (task brief): night-ish dark and the bright tropical day sky
BG_DARK = (11, 12, 16)      # #0b0c10
BG_SKY = (126, 200, 240)    # #7ec8f0

# --------------------------------------------------------------------------------------------------------------------
# small maths helpers
# --------------------------------------------------------------------------------------------------------------------


def sstep(e0, e1, x):
    """smoothstep; works for e0 > e1 too (falling edge)."""
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def coverage(sd, aa):
    """Anti-aliased coverage of 'sd <= 0' with a linear ramp 'aa' wide (same units as sd)."""
    return np.clip(0.5 - sd / aa, 0.0, 1.0).astype(F32)


def line_cov(across, half_w, aa):
    """Coverage of a stroke |across| <= half_w that stays right for strokes thinner than a pixel
    (a 0.5 px line peaks at 0.5 coverage instead of vanishing or turning into a 1 px line)."""
    w = 2.0 * half_w
    return np.clip(np.minimum(w / aa, 0.5 + (half_w - across) / aa), 0.0, 1.0).astype(F32)


def gblur(a, sigma):
    """Separable Gaussian blur (numpy only), edge padding. sigma in pixels."""
    if sigma <= 0:
        return a.astype(F32)
    r = int(math.ceil(sigma * 3.5))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2).astype(F32)
    k /= k.sum()
    out = a.astype(F32)
    for ax in (0, 1):
        pad = [(0, 0)] * out.ndim
        pad[ax] = (r, r)
        p = np.pad(out, pad, mode="edge")
        acc = np.zeros_like(out)
        n = out.shape[ax]
        for i, w in enumerate(k):
            sl = [slice(None)] * out.ndim
            sl[ax] = slice(i, i + n)
            acc += w * p[tuple(sl)]
        out = acc
    return out


def band_noise(size, seed, fmin, fmax):
    """Periodic band-limited noise tile (spectral synthesis), mean 0, std 1. fmin/fmax in cycles per tile."""
    rng = np.random.default_rng(seed)
    fy = (np.fft.fftfreq(size) * size)[:, None]
    fx = (np.fft.rfftfreq(size) * size)[None, :]
    f = np.sqrt(fx * fx + fy * fy)
    amp = sstep(fmin * 0.6, fmin, f) * (1.0 - sstep(fmax, fmax * 1.6, f))
    spec = (rng.standard_normal(amp.shape) + 1j * rng.standard_normal(amp.shape)) * amp
    n = np.fft.irfft2(spec, s=(size, size))
    n = (n - n.mean()) / (n.std() + 1e-12)
    return n.astype(F32)


def sample_wrap(tex, y, x):
    """Bilinear sample of a periodic texture at float texel coords (y, x)."""
    H, W = tex.shape
    x0 = np.floor(x)
    y0 = np.floor(y)
    fx = (x - x0).astype(F32)
    fy = (y - y0).astype(F32)
    x0 = x0.astype(np.int64) % W
    y0 = y0.astype(np.int64) % H
    x1 = (x0 + 1) % W
    y1 = (y0 + 1) % H
    return (tex[y0, x0] * (1 - fx) * (1 - fy) + tex[y0, x1] * fx * (1 - fy)
            + tex[y1, x0] * (1 - fx) * fy + tex[y1, x1] * fx * fy).astype(F32)


class Noise:
    """Smooth periodic noise N(x, y), x/y in tile units (1 = one tile, ~f0 features per tile), mean 0, std 1."""

    def __init__(self, seed, f0=4.0, size=512):
        self.t = band_noise(size, seed, f0 * 0.7, f0 * 1.35)
        self.n = size

    def __call__(self, x, y):
        return sample_wrap(self.t, y * self.n, x * self.n)


class Octaves:
    """fbm from independent band-limited octaves (lacunarity 2). f = features per cell at the first octave.
    ridge 0 -> smooth signed fbm (~[-0.5, 0.5]); ridge 1 -> ridged filaments (thin bright lines along the zero
    crossings), so smoke can turn from billows into wisps by blending the two."""

    def __init__(self, seed, octaves=4):
        self.oct = [Noise(seed * 13 + i * 5 + 3, f0=8.0) for i in range(octaves)]
        self.off = np.random.default_rng(seed).random((octaves, 2)) * 8.0

    def __call__(self, x, y, f, n=4, gain=0.5, drift=(0.0, 0.0), ridge=0.0):
        acc, tot = 0.0, 0.0
        for i in range(n):
            s = f * 2 ** i / 8.0
            v = self.oct[i](x * s + self.off[i, 0] + drift[0] * (1 + 0.7 * i),
                            y * s + self.off[i, 1] + drift[1] * (1 + 0.7 * i))
            val = 0.5 * v * (1.0 - ridge) + ridge * (1.0 - np.minimum(np.abs(v), 1.8) / 0.9)
            amp = gain ** i
            acc = acc + amp * val
            tot += amp
        return acc / tot


# --------------------------------------------------------------------------------------------------------------------
# signed distances (all in 'cell units': a cell spans [-0.5, 0.5] in x and y, +y UP)
# --------------------------------------------------------------------------------------------------------------------


def cell_xy(n, ss=SS, ny=None):
    """Pixel-centre coordinates of an n (x ny) output-px cell at SS resolution, in cell units of the WIDTH:
    x right in [-0.5, 0.5], y up. Returns (X row vector, Y column vector) for broadcasting."""
    ny = n if ny is None else ny
    Mx, My = n * ss, ny * ss
    X = ((np.arange(Mx, dtype=F32) + 0.5) / Mx - 0.5)[None, :]
    Y = -(((np.arange(My, dtype=F32) + 0.5) / My - 0.5) * (ny / n))[:, None]
    return X, Y


def sd_poly(X, Y, V):
    """Exact signed distance to a simple polygon V (k x 2, any winding, convex or not). Negative inside."""
    V = np.asarray(V, np.float64)
    k = len(V)
    shape = np.broadcast(X, Y).shape
    d2 = np.full(shape, np.inf, F32)
    inside = np.zeros(shape, bool)
    for i in range(k):
        ax, ay = V[i]
        bx, by = V[(i + 1) % k]
        ex, ey = bx - ax, by - ay
        wx, wy = X - ax, Y - ay
        t = np.clip((wx * ex + wy * ey) / max(ex * ex + ey * ey, 1e-18), 0.0, 1.0)
        dx, dy = wx - ex * t, wy - ey * t
        d2 = np.minimum(d2, (dx * dx + dy * dy).astype(F32))
        if ay != by:
            cond = ((ay > Y) != (by > Y)) & (X < (bx - ax) * (Y - ay) / (by - ay) + ax)
            inside ^= cond
    d = np.sqrt(d2)
    return np.where(inside, -d, d).astype(F32)


def sd_segment(X, Y, a, b):
    ax, ay = a
    bx, by = b
    ex, ey = bx - ax, by - ay
    wx, wy = X - ax, Y - ay
    t = np.clip((wx * ex + wy * ey) / max(ex * ex + ey * ey, 1e-18), 0.0, 1.0)
    return np.hypot(wx - ex * t, wy - ey * t).astype(F32), t.astype(F32)


def convex_hull(P):
    """Monotone-chain convex hull of 2D points, CCW."""
    pts = sorted(set((float(x), float(y)) for x, y in P))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lo, hi = [], []
    for p in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0:
            lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(hi) >= 2 and cross(hi[-2], hi[-1], p) <= 0:
            hi.pop()
        hi.append(p)
    return lo[:-1] + hi[:-1]


def poly_area(V):
    V = np.asarray(V, np.float64)
    return 0.5 * float(np.sum(V[:, 0] * np.roll(V[:, 1], -1) - np.roll(V[:, 0], -1) * V[:, 1]))


# --------------------------------------------------------------------------------------------------------------------
# premultiplied image pipeline:  (P, A) at SS  ->  box down  ->  un-premultiply  ->  grey lock  ->  bleed  ->  8 bit
# --------------------------------------------------------------------------------------------------------------------


def box_down(P, A, f):
    H, W = A.shape
    P = P.reshape(H // f, f, W // f, f).mean(axis=(1, 3))
    A = A.reshape(H // f, f, W // f, f).mean(axis=(1, 3))
    return P.astype(F32), A.astype(F32)


def _pullpush(C, w):
    """Fill pixels with w == 0 from a coarse-to-fine average of the weighted ones."""
    H, W = w.shape
    has = w > 0
    if has.all() or H <= 1 or W <= 1:
        tot = w.sum()
        fb = (C * w).sum() / tot if tot > 0 else 0.0
        return np.where(has, C, fb).astype(F32)
    Hp, Wp = H + (H % 2), W + (W % 2)
    Cp = np.zeros((Hp, Wp), F32)
    Cp[:H, :W] = C * w
    wp = np.zeros((Hp, Wp), F32)
    wp[:H, :W] = w
    C2s = Cp.reshape(Hp // 2, 2, Wp // 2, 2).sum(axis=(1, 3))
    w2 = wp.reshape(Hp // 2, 2, Wp // 2, 2).sum(axis=(1, 3))
    C2 = _pullpush(np.where(w2 > 0, C2s / np.maximum(w2, 1e-12), 0.0).astype(F32), w2)
    Cup = np.repeat(np.repeat(C2, 2, axis=0), 2, axis=1)[:H, :W]
    return np.where(has, C, Cup).astype(F32)


def bleed(C, visible, rings=24):
    """Grey under invisible pixels := grey of the NEAREST visible pixels (ring-by-ring dilation, then pull-push),
    so filtering never mixes black or white into an edge: the ring round an ink outline carries ink."""
    filled = visible.copy()
    out = np.where(visible, C, 0.0).astype(F32)
    nbrs = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
    for _ in range(rings):
        acc = np.zeros_like(out)
        cnt = np.zeros(filled.shape, F32)
        fpad = np.pad(filled, 1)
        opad = np.pad(out, 1)
        H, W = out.shape
        for dy, dx in nbrs:
            f = fpad[1 + dy:1 + dy + H, 1 + dx:1 + dx + W]
            acc += opad[1 + dy:1 + dy + H, 1 + dx:1 + dx + W] * f
            cnt += f
        new = (~filled) & (cnt > 0)
        if not new.any():
            break
        out[new] = acc[new] / cnt[new]
        filled |= new
    if not filled.all():
        out = _pullpush(out, filled.astype(F32))
    return out


def quantise(x, rng, dither):
    v = x * 255.0
    if dither:
        d = rng.random(x.shape, dtype=F32) - rng.random(x.shape, dtype=F32)   # TPDF, +-1 LSB
        inner = (v > 1.0) & (v < 254.0)      # never dither the first / last LSB: exact 0 and 255 stay exact
        v = np.where(inner, v + d, v)
    return np.clip(np.rint(v), 0, 255).astype(np.uint8)


def finish(name, P, A, grid=(1, 1), dither=False, seed=7):
    """P (premultiplied grey) and A at SS -> box down, un-premultiply, bleed per flipbook cell, quantise, save RGBA."""
    P, A = box_down(P, A, SS)
    A = np.clip(A, 0.0, 1.0)
    C = np.clip(np.where(A > 1e-6, P / np.maximum(A, 1e-6), 0.0), 0.0, 1.0)
    rng = np.random.default_rng(seed)
    a8 = quantise(A, rng, dither)
    H, W = A.shape
    gy, gx = grid
    ch, cw = H // gy, W // gx
    Cb = np.zeros_like(C)
    for j in range(gy):
        for i in range(gx):
            sl = (slice(j * ch, (j + 1) * ch), slice(i * cw, (i + 1) * cw))
            Cb[sl] = bleed(C[sl], a8[sl] > 0)
    g8 = quantise(np.clip(Cb, 0, 1), rng, dither)
    img = np.dstack([g8, g8, g8, a8])
    Image.fromarray(img, "RGBA").save(os.path.join(OUT, name + ".png"), optimize=True)
    return img


def assemble(cells, gy, gx):
    """Row-major list of (P, A) cells -> one (P, A) sheet (Roblox flipbook order: left to right, top to bottom)."""
    rowsP, rowsA = [], []
    for j in range(gy):
        rowsP.append(np.concatenate([cells[j * gx + i][0] for i in range(gx)], axis=1))
        rowsA.append(np.concatenate([cells[j * gx + i][1] for i in range(gx)], axis=1))
    return np.concatenate(rowsP, axis=0), np.concatenate(rowsA, axis=0)


# ====================================================================================================================
# te5_mote  (128^2): white core disc, ink rim (reads on a bright sky), a soft white glow
# ====================================================================================================================


def make_mote():
    n = 128
    X, Y = cell_xy(n)
    r = np.hypot(X, Y)
    aa = 1.0 / n                                         # 1 output px ramp
    core = coverage(r - 0.22, aa)                         # r < 0.22: white, alpha 1
    rim = coverage(r - 0.30, aa)                          # r < 0.30: core or ink rim
    s = np.clip((r - 0.30) / (0.465 - 0.30), 0.0, 1.0)    # glow r 0.30 -> 0.465 (alpha 0 at 4.4 % inside the frame)
    glow_a = 0.25 * (1.0 - s) ** 2 * (1.0 - s * 0.35)
    w_core = core
    w_rim = rim - core
    w_glow = 1.0 - rim
    ink = 18.0 / 255.0
    A = w_core * 1.0 + w_rim * 0.85 + w_glow * glow_a
    P = w_core * 1.0 + w_rim * 0.85 * ink + w_glow * glow_a * 1.0
    return finish("te5_mote", P.astype(F32), A.astype(F32), dither=True, seed=11)


# ====================================================================================================================
# te5_glint  (256^2): a 4-point star glint with fine 45 degree spikes, a white core and a thin ink halo
# ====================================================================================================================


def make_glint():
    n = 256
    X, Y = cell_xy(n)
    px = 1.0 / n                                          # one output px in cell units
    aa = px
    r = np.hypot(X, Y)

    def spike(along, across, half_len, w0_px, w1_px, a0, taper=1.5, fade=1.8):
        u = np.clip(along / half_len, 0.0, 1.0)
        half_w = 0.5 * px * (w1_px + (w0_px - w1_px) * (1.0 - u) ** taper)
        a = a0 * (1.0 - u) ** fade * (along < half_len)
        return line_cov(across, half_w, aa) * a

    ax_, ay_ = np.abs(X), np.abs(Y)
    # main spikes: horizontal + vertical, thickness 6 px -> 0.5 px, alpha 1 -> 0 at the tips (tips 4 % inside the frame)
    L1 = 0.465
    h = spike(ax_, ay_, L1, 6.0, 0.5, 1.0)
    v = spike(ay_, ax_, L1, 6.0, 0.5, 1.0)
    # 45 degree spikes: half length 0.45 along the diagonal, alpha 0.5, thickness 3.5 px -> 0.5 px
    d1 = np.abs((X + Y) / math.sqrt(2.0))
    d2 = np.abs((X - Y) / math.sqrt(2.0))
    dg1 = spike(d2, d1, 0.45, 3.5, 0.5, 0.5, fade=2.2)
    dg2 = spike(d1, d2, 0.45, 3.5, 0.5, 0.5, fade=2.2)
    # core disc r 0.05 at alpha 1, with a short soft bloom that stays inside the ink halo
    core = coverage(r - 0.05, aa)
    bloom = 0.55 * (1.0 - np.clip((r - 0.05) / 0.017, 0.0, 1.0)) ** 2 * (r > 0.05)
    white = 1.0 - (1.0 - h) * (1.0 - v) * (1.0 - dg1) * (1.0 - dg2) * (1.0 - core) * (1.0 - bloom)
    # thin ink halo r 0.07 - 0.09 (RGB 15, alpha 0.6) under the white
    halo = (coverage(r - 0.09, aa) - coverage(r - 0.07, aa)) * 0.6
    ink = 15.0 / 255.0
    A = white + halo * (1.0 - white)
    P = white * 1.0 + halo * (1.0 - white) * ink
    return finish("te5_glint", P.astype(F32), A.astype(F32), dither=True, seed=12)


# ====================================================================================================================
# te5_bokeh  (256^2): a hexagonal aperture disc with a brighter rim band and faint onion rings
# ====================================================================================================================


def sd_hexagon(X, Y, apothem):
    """iq's exact hexagon distance, flat sides at |y| = apothem (pointy left/right)."""
    kx, ky, kz = -0.866025404, 0.5, 0.577350269
    px, py = np.abs(X), np.abs(Y)
    dot = np.minimum(kx * px + ky * py, 0.0)
    px = px - 2.0 * dot * kx
    py = py - 2.0 * dot * ky
    px = px - np.clip(px, -kz * apothem, kz * apothem)
    py = py - apothem
    return (np.hypot(px, py) * np.sign(py)).astype(F32)


def make_bokeh():
    n = 256
    X, Y = cell_xy(n)
    px = 1.0 / n
    Rc = 0.46                               # circumradius of the hexagon
    ap = Rc * math.cos(math.radians(30))    # apothem 0.398
    rc = 0.15 * Rc                          # corner rounding radius (15 %)
    # rotate the aperture a little off-axis (it reads less like a UI hexagon); particles spin it anyway
    th = math.radians(8.0)
    Xr = X * math.cos(th) - Y * math.sin(th)
    Yr = X * math.sin(th) + Y * math.cos(th)
    sd = sd_hexagon(Xr, Yr, ap - rc) - rc   # rounded hexagon, flat sides kept at the apothem
    edge = coverage(sd, 2.0 * px)           # 2 px AA on the outer edge
    depth = np.clip(-sd / ap, 0.0, 1.0)     # 0 at the edge, 1 at the centre
    q = 1.0 - depth
    band = 0.08 * Rc                        # rim band = outer 8 %
    rimw = sstep(band + 3.0 * px, band - 1.0 * px, -sd)      # soft inner side, like a real aperture rim
    a_in = 0.55
    a = lerp(a_in, 0.85, rimw)
    # faint onion rings (+-0.03 alpha): the irregular concentric ripples of an aspheric lens element. A band-limited
    # 1D noise of the radius (random spacing and strength), stronger toward the rim, never a regular target pattern
    r = np.hypot(X, Y)
    rng = np.random.default_rng(31)
    nf = 4096
    spec = np.zeros(nf // 2 + 1, complex)
    fr = np.arange(nf // 2 + 1)                     # cycles per unit radius x (nf / 1.0)
    band = sstep(6, 10, fr) * (1.0 - sstep(26, 38, fr))
    spec[:] = (rng.standard_normal(fr.size) + 1j * rng.standard_normal(fr.size)) * band
    prof = np.fft.irfft(spec, n=nf)
    prof = prof / np.abs(prof).max()
    ring = np.interp(np.clip(r, 0, 0.999) * nf, np.arange(nf), prof)
    a = a + 0.03 * ring * (0.45 + 0.55 * q) * (1.0 - rimw)
    A = a * edge
    L = 0.90 + 0.10 * q ** 1.6
    L = np.where(rimw > 0, lerp(L, 1.0, rimw), L)
    P = L * A
    return finish("te5_bokeh", P.astype(F32), A.astype(F32), dither=True, seed=13)


# ====================================================================================================================
# te5_streak  (256 x 256): a thin vertical capsule of matter (1:10), white core + ink edges, bright leading (top) end,
# fading tail. Square: Roblox draws particles square, so a 64x256 image was stretched into a fat pill (review round 1, F18).
# ====================================================================================================================


def make_streak():
    W, H = 256, 256
    # work in output pixels: x from the centre line, y down from the top edge
    Ms, Ns = W * SS, H * SS
    xs = ((np.arange(Ms, dtype=F32) + 0.5) / SS - W / 2.0)[None, :]
    ys = ((np.arange(Ns, dtype=F32) + 0.5) / SS)[:, None]
    R = 11.0                                 # 22 px wide (1:10 of its length)
    y0, y1 = 0.04 * H, 0.96 * H              # capsule extent including the round caps
    a = (0.0, y0 + R)
    b = (0.0, y1 - R)
    dist, t = sd_segment(xs, ys, a, b)
    sd = dist - R                            # px
    body = coverage(sd, 1.0)                  # outer edge with 1 px AA
    corew = sstep(7.5, 6.0, dist)             # white core |x| < ~6.75 px (13-14 px), 1.5 px blend into the ink
    # along the streak: f = 0 at the leading tip, 1 at the tail tip
    f = np.clip((ys - y0) / (y1 - y0), 0.0, 1.0)
    fade = 1.0 - sstep(0.60, 1.0, f) ** 0.85            # the tail fades over the lower 40 %
    head = 1.0 - 0.18 * sstep(0.05, 0.60, f)              # the leading end is brightest (1.0 -> 0.82)
    core_L = head
    ink_L = 15.0 / 255.0
    # alpha: core 1, ink 0.9 (with the same fade); colour: grey along the core, ink at the edges
    a_core = corew * 1.0
    a_ink = (1.0 - corew) * 0.9
    A = body * (a_core + a_ink) * fade
    P = body * (a_core * core_L + a_ink * ink_L) * fade
    return finish("te5_streak", P.astype(F32), A.astype(F32), dither=True, seed=14)


# ====================================================================================================================
# te5_shards  (1024^2, Grid4x4, Loop): a tumbling metal sliver, 16 frames x 22.5 deg about normalize(0.35, 1, 0.2)
# ====================================================================================================================

SHARD_Q = [(-0.30, -0.42), (0.22, -0.35), (0.34, 0.40), (-0.12, 0.46)]   # spec quad (x0.8 of the cell before padding)
SHARD_T = 0.06                                                            # thickness, in the same units as Q x 0.8
SHARD_AXIS = (0.35, 1.0, 0.2)
SHARD_LIGHT = (-0.45, 0.75, 0.55)        # key light: upper left, toward the viewer
SHARD_PAD = 0.20                         # >= 20 % padding on every side of every cell


def rot_axis(axis, ang):
    a = np.asarray(axis, np.float64)
    a = a / np.linalg.norm(a)
    x, y, z = a
    c, s = math.cos(ang), math.sin(ang)
    C = 1 - c
    return np.array([[c + x * x * C, x * y * C - z * s, x * z * C + y * s],
                     [y * x * C + z * s, c + y * y * C, y * z * C - x * s],
                     [z * x * C - y * s, z * y * C + x * s, c + z * z * C]])


def shard_geometry(scale):
    """Prism vertices (8 x 3) centred on the quad's centroid, faces as index lists with outward normals (local)."""
    Q = np.asarray(SHARD_Q, np.float64)
    if poly_area(Q) < 0:
        Q = Q[::-1]
    # area centroid
    x, y = Q[:, 0], Q[:, 1]
    cr = x * np.roll(y, -1) - np.roll(x, -1) * y
    A = cr.sum() / 2
    cx = ((x + np.roll(x, -1)) * cr).sum() / (6 * A)
    cy = ((y + np.roll(y, -1)) * cr).sum() / (6 * A)
    Q = (Q - [cx, cy]) * scale
    h = 0.5 * SHARD_T / 0.8 * scale
    k = len(Q)
    V = np.zeros((2 * k, 3))
    V[:k, :2] = Q
    V[:k, 2] = h
    V[k:, :2] = Q
    V[k:, 2] = -h
    faces = [("front", list(range(k)), np.array([0, 0, 1.0])),
             ("back", [k + i for i in range(k)][::-1], np.array([0, 0, -1.0]))]
    for i in range(k):
        j = (i + 1) % k
        e = Q[j] - Q[i]
        nrm = np.array([e[1], -e[0], 0.0])
        nrm /= np.linalg.norm(nrm)
        faces.append((f"side{i}", [i, j, k + j, k + i], nrm))
    return V, faces, Q


def shard_scale():
    """Largest scale keeping every frame's silhouette + 2 px outline + 1 px AA inside the 20 % padding box."""
    cell = 256
    margin = 3.5 / cell
    lim = 0.5 - SHARD_PAD - margin
    V, _, _ = shard_geometry(1.0)
    ext = 0.0
    for k in range(16):
        Rm = rot_axis(SHARD_AXIS, math.radians(22.5 * k))
        p = V @ Rm.T
        ext = max(ext, np.abs(p[:, :2]).max())
    return lim / ext


def render_shard_frame(k, scale, cell=256, brushed=None):
    X, Y = cell_xy(cell)
    px = 1.0 / cell
    aa = px
    V, faces, Q = shard_geometry(scale)
    Rm = rot_axis(SHARD_AXIS, math.radians(22.5 * k))
    Vr = V @ Rm.T
    Ld = np.asarray(SHARD_LIGHT, np.float64)
    Ld /= np.linalg.norm(Ld)
    zf = np.array([0, 0, 1.0])
    hull = convex_hull(Vr[:, :2])
    sd_sil = sd_poly(X, Y, hull)
    body_cov = coverage(sd_sil, aa)
    acc_L = np.zeros(sd_sil.shape, F32)
    acc_w = np.zeros(sd_sil.shape, F32)
    big = None
    for name, idx, nrm in faces:
        nr = Rm @ nrm
        if nr[2] <= 1e-4:
            continue                      # back-face culling (convex prism: visible faces never overlap)
        poly = Vr[idx][:, :2]
        cov = coverage(sd_poly(X, Y, poly), aa)
        lam = float(nr @ Ld)
        if name == "front":
            Lf = 0.86 + 0.07 * (lam - float(zf @ Ld))
        elif name == "back":
            Lf = 0.25 + 0.06 * (lam - float(zf @ Ld))
        else:
            Lf = 0.55 + 0.10 * lam
        if name in ("front", "back"):
            big = (name, idx, nr)
            # brushed-metal grain + a gentle gradient toward the lit edge, in face-local coordinates (so the grain
            # turns with the shard instead of swimming): solve screen = c + a*e1 + b*e2 for (a, b)
            e1 = Rm @ np.array([1.0, 0, 0])
            e2 = Rm @ np.array([0, 1.0, 0])
            c0 = Rm @ np.array([0, 0, V[idx[0], 2]])
            M = np.array([[e1[0], e2[0]], [e1[1], e2[1]]])
            det = np.linalg.det(M)
            if abs(det) > 1e-3:
                Mi = np.linalg.inv(M)
                dx, dy = X - c0[0], Y - c0[1]
                la = Mi[0, 0] * dx + Mi[0, 1] * dy
                lb = Mi[1, 0] * dx + Mi[1, 1] * dy
                g = (-0.55 * la + 0.83 * lb) / (0.5 * scale)          # -1 .. 1 across the face toward the light
                tex = brushed(la / scale, lb / scale) if brushed is not None else 0.0
                amp = 1.0 if name == "front" else 0.6
                # a soft reflection band of the sky sweeping across the metal as it turns (loops with the frames)
                ck = 1.5 * math.cos(2 * math.pi * k / 16.0 + 0.6)
                sheen = np.exp(-((g - ck) / 0.32) ** 2)
                Lmap = Lf + amp * (0.035 * np.clip(g, -1.2, 1.2) + 0.022 * tex + 0.06 * sheen)
            else:
                Lmap = Lf
            acc_L += cov * Lmap
        else:
            acc_L += cov * Lf
        acc_w += cov
    L = np.where(acc_w > 1e-6, acc_L / np.maximum(acc_w, 1e-6), 0.55)
    # 1 px specular line on the lit edge: along the creases of the visible big face whose bevel faces the light;
    # weights change smoothly with the rotation, so the loop never pops
    spec = np.zeros_like(L)
    if big is not None:
        name, idx, nF = big
        vis = sstep(0.04, 0.22, float(nF[2]))
        kq = len(Q)
        for _, sidx, snrm in faces[2:]:
            ns = Rm @ snrm
            bis = nF + ns
            bis /= np.linalg.norm(bis)
            w = sstep(0.30, 0.80, float(bis @ Ld)) * vis
            if w <= 0.002:
                continue
            # this side's edge on the big face
            ia, ib = (sidx[0], sidx[1]) if name == "front" else (sidx[3], sidx[2])
            pa, pb = Vr[ia, :2], Vr[ib, :2]
            # inset the line half a pixel into the big face (toward its centroid)
            cen = Vr[idx][:, :2].mean(axis=0)
            mid = 0.5 * (pa + pb)
            dirn = cen - mid
            dirn /= max(np.linalg.norm(dirn), 1e-9)
            off = dirn * 0.9 * px
            dist, t = sd_segment(X, Y, pa + off, pb + off)
            taper = np.maximum(np.sin(np.pi * np.clip(t, 0, 1)), 0.0) ** 0.6
            spec = np.maximum(spec, line_cov(dist, 0.55 * px, 0.5 * aa) * w * taper)
    L = L + (1.0 - L) * spec
    # 2 px ink outline round the silhouette
    sil_out = coverage(sd_sil - 2.0 * px, aa)
    ink = 10.0 / 255.0
    A = sil_out
    P = body_cov * L + (sil_out - body_cov) * ink
    return P.astype(F32), A.astype(F32)


def make_shards():
    scale = shard_scale()
    grain = Noise(4242, f0=6.0)

    def brushed(a, b):
        # fine streaks along the sliver's length (strongly anisotropic), plus a few longer scratches
        return 0.7 * grain(a * 0.35 + 3.1, b * 0.02 + 0.4) * 1.0 + 0.3 * grain(a * 1.4 + 7.7, b * 0.05 + 2.2)

    cells = [render_shard_frame(k, scale, brushed=brushed) for k in range(16)]
    P, A = assemble(cells, 4, 4)
    make_shards.scale = scale
    return finish("te5_shards", P, A, grid=(4, 4), dither=False, seed=15)


# ====================================================================================================================
# te5_smoke  (1024^2, Grid4x4, OneShot): a curling smoke tendril, dense and crisp -> thin and wispy over 16 frames
# ====================================================================================================================

SMOKE_PEAK = [0.62, 0.76, 0.85, 0.85, 0.85, 0.81, 0.76, 0.70, 0.64, 0.58, 0.53, 0.48, 0.44, 0.40, 0.37, 0.34]


SMOKE_SEED = 777


def render_smoke_frame(k, no, cell=256):
    """One frame of the smoke: a 2D slice of a puff that expands, curls and thins. Everything is a smooth function of
    t = k / 15, so neighbouring frames differ only a little (the OneShot plays ~4 fps over the particle's life)."""
    X, Y = cell_xy(cell)
    t = k / 15.0
    e = 1.0 - (1.0 - t) ** 1.6                       # fast early growth that settles
    R = 0.22 + 0.20 * e                              # blob radius 0.22 -> 0.42 of the cell
    r = np.hypot(X, Y)
    # spiral (curl) warp, growing: the inside turns further than the outside, so lobes wind into curling tendrils
    W = 0.15 + 1.35 * t ** 1.15                      # radians at the centre
    phi = W * np.exp(-(r / (0.9 * R)) ** 2)
    c, s = np.cos(-phi), np.sin(-phi)
    xs = X * c - Y * s
    ys = X * s + Y * c
    S = 1.0 + (R / 0.22 - 1.0) * 0.85                # the features spread with the puff (a bit slower than it)
    qx, qy = xs / S, ys / S
    # domain warp (grows): the turbulence that tears the puff into wisps
    A = 0.02 + 0.07 * e
    wx = no(qx + 5.2, qy + 1.3, 3.0, n=3)
    wy = no(qx - 3.7, qy + 8.1, 3.0, n=3)
    qx2, qy2 = qx + A * wx, qy + A * wy
    # the puff: a rounded mass with 2-octave lobes, plus 4-octave fbm detail that turns into ridged wisps late
    lob = no(qx2 + 11.7, qy2 - 2.4, 2.0, n=2)
    rq = np.hypot(qx2, qy2) / 0.22
    shape = 1.0 - rq ** 2.2 + 0.25 * lob
    wisp = sstep(0.4, 1.0, t)
    det = no(qx2, qy2, 4.5, n=4, gain=0.55, drift=(0.0, -0.05 * t), ridge=0.6 * wisp)
    dens = shape + 1.3 * det - 0.05 - 0.55 * t ** 1.2
    gate = 1.0 - sstep(0.85 * R, 1.25 * R, np.hypot(xs, ys))     # no floating islands far from the puff
    dens = np.maximum(dens, 0.0) * gate
    win = 1.0 - sstep(0.34, 0.46, r)                  # alpha reaches 0 at 0.46 of the cell (no square edges)
    dens = dens * win
    # opacity: Beer-Lambert (soft, never a hard threshold), normalised to the frame's planned peak
    kap = 3.2 * (1.0 - t) + 2.2 * t
    a = 1.0 - np.exp(-kap * dens)
    occ = a[a > 0.02]
    ref = float(np.percentile(occ, 99.5)) if occ.size else 1.0
    a = np.clip(a / max(ref, 0.2), 0.0, 1.0) * SMOKE_PEAK[k]
    # internal shading 0.75 - 1.0: self-shadow by marching toward the light (upper left) + a bump on the lumps
    Ld = (-0.55, 0.835)
    step = 2.0 * SS                                   # 2 output px per march step, 12 steps
    acc = np.zeros_like(dens)
    for j in range(1, 13):
        dy = int(round(-Ld[1] * step * j))
        dx = int(round(Ld[0] * step * j))
        acc += np.roll(np.roll(dens, -dy, axis=0), -dx, axis=1)
    T = np.exp(-0.5 * acc * (2.0 / 256.0) * 10.0)
    D = gblur(dens, 3.0 * SS)
    gy, gx = np.gradient(D)
    lam = (-gx * Ld[0] + gy * Ld[1]) * 6.0 * SS
    shade = np.clip(0.75 + 0.25 * np.clip(0.55 * T + 0.45 + lam, 0.0, 1.0), 0.75, 1.0)
    return (shade * a).astype(F32), a.astype(F32)


def make_smoke():
    no = Octaves(SMOKE_SEED)
    cells = [render_smoke_frame(k, no) for k in range(16)]
    P, A = assemble(cells, 4, 4)
    return finish("te5_smoke", P, A, grid=(4, 4), dither=True, seed=16)


# ====================================================================================================================
# te5_ash  (256^2): one charred flake, a jagged 9-gon, silver highlight on the upper-left edges. (Review round 2: it was a
# 1024^2 2x2 flipbook of 4 flakes, 5 MB of texture memory for a flake that never covers more than ~20 px; the emitter's
# random rotation and tumble already make every particle look different, and a single image needs no flipbook mode)
# ====================================================================================================================

ASH_FLAKES = [  # (seed, main vertices, target extent of the cell)
    (71, 7, 0.70),
    (72, 9, 0.74),
    (73, 8, 0.64),
    (74, 8, 0.72),
]
ASH_PAD = 0.12


def flake_polygon(seed, nv, extent):
    """A star-shaped (so always simple) jagged polygon: nv main corners, each edge broken into torn sub-steps."""
    rng = np.random.default_rng(seed)
    base = np.sort((np.arange(nv) + rng.uniform(-0.32, 0.32, nv)) / nv * 2 * np.pi + rng.uniform(0, 2 * np.pi))
    rad = rng.uniform(0.62, 1.0, nv)
    elong = rng.uniform(0.70, 0.88)            # flakes are a bit longer than wide
    rot = rng.uniform(0, np.pi)
    main = np.stack([np.cos(base) * rad, np.sin(base) * rad * elong], axis=1)
    cr, sr = math.cos(rot), math.sin(rot)
    main = main @ np.array([[cr, sr], [-sr, cr]])
    pts = []
    for i in range(nv):
        a = main[i]
        b = main[(i + 1) % nv]
        m = int(rng.integers(3, 6))
        for j in range(m):
            tt = j / m
            p = a + (b - a) * tt
            if j > 0:
                # torn edge: radial jitter (keeps the polygon star-shaped), with an occasional deeper bite
                jit = rng.normal(0, 0.035)
                if rng.random() < 0.12:
                    jit -= rng.uniform(0.06, 0.12)
                p = p * (1.0 + jit)
            pts.append(p)
    P = np.asarray(pts)
    ext = (P.max(axis=0) - P.min(axis=0)).max()
    P = P * (extent / ext)
    P = P - 0.5 * (P.max(axis=0) + P.min(axis=0))
    return P


def render_flake(seed, nv, extent, cell=512):
    X, Y = cell_xy(cell)
    px = 1.0 / cell
    aa = px
    V = flake_polygon(seed, nv, extent)
    sd = sd_poly(X, Y, V)
    cov = coverage(sd, aa)
    # outward normal from the distance gradient
    gy, gx = np.gradient(sd)
    gx, gy = gx, -gy                              # rows run down; +y is up
    gn = np.hypot(gx, gy) + 1e-9
    nx, ny = gx / gn, gy / gn
    ul = (-nx + ny) / math.sqrt(2.0)              # facing the upper left
    hl = sstep(0.15, 0.75, ul)
    band = coverage(sd, aa) - coverage(sd + 1.0 * px, aa)        # the outermost 1 px inside the edge
    # body: RGB 14 - 22: two facets (a soft fold), fibre texture along the grain, darker toward the char edge
    rng = np.random.default_rng(seed + 500)
    fang = rng.uniform(0, np.pi)
    ux, uy = math.cos(fang), math.sin(fang)
    fib = Noise(seed + 900, f0=5.0)
    a_ = (X * ux + Y * uy)
    b_ = (-X * uy + Y * ux)
    fibre = 0.65 * fib(a_ * 0.25, b_ * 3.2) + 0.35 * fib(a_ * 0.6 + 4.0, b_ * 7.0)
    fold_ang = fang + rng.uniform(0.6, 1.2)
    fold = np.tanh(((X * math.cos(fold_ang) + Y * math.sin(fold_ang)) - rng.uniform(-0.06, 0.06)) / (2.5 * px))
    inner = np.clip(-sd / (0.06), 0.0, 1.0)
    body = 18.0 + 2.0 * fold + 1.6 * fibre + 1.0 * inner
    body = np.clip(body, 14.0, 22.0) / 255.0
    edge_L = lerp(body, 190.0 / 255.0, hl)
    L = lerp(body, edge_L, np.clip(band / np.maximum(cov, 1e-6), 0.0, 1.0))
    A = cov
    P = L * A
    return P.astype(F32), A.astype(F32)


ASH_FLAKE = ASH_FLAKES[1]  # the 9-cornered one


def make_ash():
    seed, nv, ext = ASH_FLAKE
    P, A = render_flake(seed, nv, ext, cell=256)
    return finish("te5_ash", P, A, grid=(1, 1), dither=False, seed=17)


# ====================================================================================================================
# registry, manifest
# ====================================================================================================================

JOBS = {
    "te5_shards": make_shards,
    "te5_smoke": make_smoke,
    "te5_mote": make_mote,
    "te5_glint": make_glint,
    "te5_bokeh": make_bokeh,
    "te5_streak": make_streak,
    "te5_ash": make_ash,
}

MANIFEST = [
    # name, texKey, fallbackTexKey, size, layout, mode, purpose, notes
    ("te5_shards", "shards5", "ash", "1024x1024", "Grid4x4", "Loop",
     "P3 metal shards breaking off the bezel and flying into the void",
     "Flipbook 4x4 Loop (16 frames x 22.5 deg about normalize(0.35,1,0.2); frame 16 = frame 0). Front face L 0.86, back "
     "0.25, sides 0.55 (flat values, with faint brushed grain and a soft sky-reflection band that sweeps the face "
     "and loops with the frames), 1 px specular line on the lit crease, 2 px ink (10) outline. "
     "The spec's 'x0.8 of the cell' and '>= 20 % padding' conflict (x0.8 puts the corners 8 % from the edge); padding "
     "wins, so the sliver is scaled to the largest size that keeps 20 % on every side in every frame (face-on it is "
     "~48 % of the cell tall, at most ~54 % in any frame): at the spec's Size 0.5-0.75 the visible shard is "
     "~0.25-0.4 studs; raise Size ~1.3x if it reads too small. Use FlipbookFramerate 10-14, FlipbookStartRandom "
     "true."),
    ("te5_smoke", "smoke5", "puff", "1024x1024", "Grid4x4", "OneShot",
     "P4a/P4b two-tone rim smoke and P7 ground mist",
     "Flipbook 4x4 OneShot. Per-frame peak alpha 0.62 0.76 0.85 0.85 0.85 0.81 0.76 0.70 0.64 0.58 0.53 0.48 0.44 0.40 "
     "0.37 0.34. RGB 0.75-1.0 internal shading lit from the upper left. Radial window reaches alpha 0 at 0.46 of the "
     "cell. Frames change gently (OneShot over a 3.5-4.5 s lifetime is ~4 fps), so the flipbook never pops."),
    ("te5_mote", "mote", "glow", "128x128", "None", None,
     "Dust motes: P1 void swirl, P2 moon dust, P6a air dust, P8a galaxy motes, P11 foot drips",
     "White core r < 0.22 (alpha 1), ink rim r 0.22-0.30 (RGB 18, alpha 0.85), white glow r 0.30 -> 0.465 "
     "(alpha 0.25 -> 0)."),
    ("te5_glint", "glint5", "glint", "256x256", "None", None,
     "P5a/P5b glints riding the metal and P6b mid-size air glints",
     "4-point glint: H/V spikes 6 -> 0.5 px, alpha 1 -> 0, tips at 0.465 of the cell; 45 deg spikes half length 0.45 at "
     "alpha 0.5; core r 0.05; ink halo r 0.07-0.09 (RGB 15, alpha 0.6)."),
    ("te5_bokeh", "bokeh", "glow", "256x256", "None", None,
     "P6c big slow bokeh between camera and wearer (L7)",
     "Rounded hexagon (circumradius 0.46, corners 15 %), interior alpha 0.55 (L 0.9 -> 1.0 outward), rim band (outer "
     "8 %) alpha 0.85, 2 px AA, onion rings +-0.03 alpha. White."),
    ("te5_streak", "streak5", "spark", "256x256", "None", None,
     "Matter streaks with VelocityParallel: P9 funnel and P10a/b palm intake",
     "Square 256 px (Roblox draws particles square). Vertical capsule y 0.04-0.96, 22 px wide (1:10): white core ~13 px "
     "(alpha 1), ~4 px ink edges (RGB 15, alpha 0.9); the module draws it 2.2x the spark fallback's size. The "
     "TOP end leads (brightest); the tail fades over the lower 40 %. If streaks fly tail-first in Studio, flip the "
     "image vertically before upload (VelocityParallel orientation check)."),
    ("te5_ash", "ash5", "ash", "256x256", "None", None,
     "P8b black ash flakes rising off the galaxy",
     "One charred flake, 256x256 (no flipbook: the emitter's random Rotation and RotSpeed -90..90 make every particle a "
     "different shape). 9 main corners with torn edges, extent 0.74, >= 12 % padding. Body RGB 14-22 alpha 1 with "
     "fibre grain and a soft fold; 1 px silver (190) highlight on the upper-left edges."),
]


def write_manifest():
    entries = []
    for name, key, fb, size, layout, mode, purpose, notes in MANIFEST:
        e = {"name": name, "file": name + ".png", "repoPath": f"{REPO_DIR}/{name}.png", "texKey": key,
             "fallbackTexKey": fb, "size": size, "layout": layout}
        if mode:
            e["flipbookMode"] = mode
        e.update({"purpose": purpose, "notes": notes, "uploadedId": None})
        entries.append(e)
    with open(os.path.join(OUT, "manifest.json"), "w") as f:
        json.dump(entries, f, indent=1, ensure_ascii=False)
        f.write("\n")
    return entries


# ====================================================================================================================
# contact sheets: overview, flipbook frames, pixel zooms and IN-GAME previews (particles at their real on-screen size,
# with the spec's particle Color / LightEmission / Brightness / Transparency, by day over the sky and by night)
# ====================================================================================================================

SHEET_ORDER = ["te5_shards", "te5_smoke", "te5_mote", "te5_glint", "te5_bokeh", "te5_streak", "te5_ash"]
GRIDS = {"te5_shards": 4, "te5_smoke": 4}


def _font(sz):
    for fp in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf",
               "/Library/Fonts/Arial.ttf"):
        if os.path.exists(fp):
            return ImageFont.truetype(fp, sz)
    return ImageFont.load_default()


def label(im, text, xy, sz=14, fill=(235, 235, 240)):
    d = ImageDraw.Draw(im)
    f = _font(sz)
    x, y = xy
    d.text((x + 1, y + 1), text, font=f, fill=(0, 0, 0))
    d.text((x, y), text, font=f, fill=fill)


def load(name):
    return np.asarray(Image.open(os.path.join(OUT, name + ".png")).convert("RGBA"), F32) / 255.0


def cell_of(img, g, k):
    h, w = img.shape[:2]
    ch, cw = h // g, w // g
    r, c = divmod(k, g)
    return img[r * ch:(r + 1) * ch, c * cw:(c + 1) * cw]


def resize_premult(img, w, h):
    """Resize like the GPU would show it: premultiplied; BOX when minifying (a mip level), bicubic when magnifying."""
    a = img[..., 3]
    p = img[..., :3] * a[..., None]
    shrink = w < img.shape[1] or h < img.shape[0]
    mode = Image.BOX if shrink else Image.BICUBIC

    def rs(ch):
        return np.asarray(Image.fromarray(ch.astype(F32), "F").resize((max(1, w), max(1, h)), mode), F32)

    P = np.dstack([rs(p[..., i]) for i in range(3)])
    A = np.clip(rs(a), 0, 1)
    C = np.where(A[..., None] > 1e-5, P / np.maximum(A, 1e-5)[..., None], 0.0)
    return np.dstack([np.clip(C, 0, 1), A]).astype(F32)


def rotate_rgba(img, deg):
    a = img[..., 3]
    p = img[..., :3] * a[..., None]

    def rt(ch):
        return np.asarray(Image.fromarray(ch.astype(F32), "F").rotate(deg, resample=Image.BICUBIC), F32)

    P = np.dstack([rt(p[..., i]) for i in range(3)])
    A = np.clip(rt(a), 0, 1)
    C = np.where(A[..., None] > 1e-5, P / np.maximum(A, 1e-5)[..., None], 0.0)
    return np.dstack([np.clip(C, 0, 1), A]).astype(F32)


class Comp:
    """A float RGB canvas with Roblox-style particle blending: out = c*a + dst*(1 - a*(1 - LightEmission))."""

    def __init__(self, w, h, bg):
        self.rgb = np.ones((h, w, 3), F32) * (np.asarray(bg, F32) / 255.0)

    def put(self, tex, cx, cy, size, color=(255, 255, 255), transp=0.0, le=0.0, br=1.0, rot=0.0, aspect=1.0):
        """Draw 'tex' (straight RGBA) as a particle of 'size' px centred at (cx, cy). aspect = height / width."""
        w = max(1, int(round(size)))
        h = max(1, int(round(size * aspect)))
        t = resize_premult(tex, w, h)
        if rot:
            pad = int(math.ceil(max(w, h) * 0.5))
            t = np.pad(t, ((pad, pad), (pad, pad), (0, 0)))
            t = rotate_rgba(t, rot)
        th, tw = t.shape[:2]
        x0 = int(round(cx - tw / 2))
        y0 = int(round(cy - th / 2))
        H, W = self.rgb.shape[:2]
        xa, ya = max(0, x0), max(0, y0)
        xb, yb = min(W, x0 + tw), min(H, y0 + th)
        if xb <= xa or yb <= ya:
            return
        sub = t[ya - y0:yb - y0, xa - x0:xb - x0]
        col = np.asarray(color, F32) / 255.0 * br
        a = sub[..., 3:4] * (1.0 - transp)
        src = sub[..., :3] * col
        dst = self.rgb[ya:yb, xa:xb]
        self.rgb[ya:yb, xa:xb] = src * a + dst * (1.0 - a * (1.0 - le))

    def put_plain(self, tex, x, y):
        """Plain 'over' of a straight RGBA image with its top-left at (x, y)."""
        h, w = tex.shape[:2]
        a = tex[..., 3:4]
        self.rgb[y:y + h, x:x + w] = tex[..., :3] * a + self.rgb[y:y + h, x:x + w] * (1.0 - a)

    def image(self):
        return Image.fromarray((np.clip(self.rgb, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")


def sky_bg(w, h, seed):
    """Day backdrop: the cyan sky with one soft white cloud bank (the hardest place for white particles to read)."""
    rgb = np.ones((h, w, 3), F32) * (np.asarray(BG_SKY, F32) / 255.0)
    nz = band_noise(256, seed, 2.0, 6.0)
    yy, xx = np.mgrid[0:h, 0:w].astype(F32)
    n = sample_wrap(nz, yy / h * 256 * 0.5, xx / w * 256)
    cloud = np.clip(0.5 + 0.35 * n - 1.4 * ((xx / w - 0.78) ** 2 + (yy / h - 0.25) ** 2) * 3.0, 0, 1)
    cloud = sstep(0.25, 0.75, cloud)[..., None]
    return rgb * (1 - 0.85 * cloud) + np.asarray([0.93, 0.95, 0.97], F32) * 0.85 * cloud


def sheet_overview():
    tile, pad, cols = 400, 14, 4
    rows = math.ceil(len(SHEET_ORDER) / cols)
    paths = []
    for bgname, bg in (("dark", BG_DARK), ("sky", BG_SKY)):
        W = cols * (tile + pad) + pad
        H = rows * (tile + pad + 22) + pad
        cp = Comp(W, H, (30, 31, 36))
        labels = []
        for i, nm in enumerate(SHEET_ORDER):
            cx = pad + (i % cols) * (tile + pad)
            cy = pad + (i // cols) * (tile + pad + 22) + 22
            cp.rgb[cy:cy + tile, cx:cx + tile] = np.asarray(bg, F32) / 255.0
            img = load(nm)
            h, w = img.shape[:2]
            sc = tile / max(w, h)
            tw, th = int(round(w * sc)), int(round(h * sc))
            im2 = resize_premult(img, tw, th)
            ox, oy = cx + (tile - tw) // 2, cy + (tile - th) // 2
            cp.put_plain(im2, ox, oy)
            g = GRIDS.get(nm)
            if g:
                for j in range(1, g):
                    cp.rgb[oy:oy + th, ox + j * tw // g] = cp.rgb[oy:oy + th, ox + j * tw // g] * 0.6 + 0.2
                    cp.rgb[oy + j * th // g, ox:ox + tw] = cp.rgb[oy + j * th // g, ox:ox + tw] * 0.6 + 0.2
            lay = {"te5_shards": "Grid4x4 Loop", "te5_smoke": "Grid4x4 OneShot"}.get(nm, "")
            labels.append((f"{nm}  {w}x{h}  {lay}", (cx, cy - 20)))
        out = cp.image()
        for t, xy in labels:
            label(out, t, xy)
        p_ = os.path.join(SHEETS, f"overview_{bgname}.png")
        out.save(p_)
        paths.append(p_)
    return paths


def sheet_frames():
    """Every flipbook frame: shards 1:1 (central 160 px of each cell), smoke 1:2; the ash flake at 4 rotations."""
    paths = []
    sh, sm, ah = load("te5_shards"), load("te5_smoke"), load("te5_ash")
    for bgname, bg in (("dark", BG_DARK), ("sky", BG_SKY)):
        W = 8 * 168 + 8
        H = 30 + 2 * 176 + 30 + 2 * 136 + 30 + 268 + 10
        cp = Comp(W, H, (30, 31, 36))
        texts = [("te5_shards: 16 frames (22.5 deg each), 1:1, central 160 px of each 256 px cell", (8, 8))]
        y = 30
        for k in range(16):
            x = 8 + (k % 8) * 168
            yy = y + (k // 8) * 176
            cp.rgb[yy:yy + 160, x:x + 160] = np.asarray(bg, F32) / 255.0
            cp.put_plain(cell_of(sh, 4, k)[48:208, 48:208], x, yy)
            texts.append((str(k), (x + 3, yy + 2)))
        y += 2 * 176
        texts.append(("te5_smoke: 16 frames OneShot, 1:2 (each 256 px cell shown at 128 px)", (8, y + 6)))
        y += 30
        for k in range(16):
            x = 8 + (k % 8) * 168
            yy = y + (k // 8) * 136
            cp.rgb[yy:yy + 128, x:x + 128] = np.asarray(bg, F32) / 255.0
            cp.put_plain(resize_premult(cell_of(sm, 4, k), 128, 128), x, yy)
            texts.append((f"{k}  a{SMOKE_PEAK[k]:.2f}", (x + 3, yy + 2)))
        y += 2 * 136
        texts.append(("te5_ash: one flake (256 px), shown at 4 of the particle's random rotations", (8, y + 6)))
        y += 30
        for k in range(4):
            x = 8 + k * 268
            cp.rgb[y:y + 256, x:x + 256] = np.asarray(bg, F32) / 255.0
            cp.put_plain(np.rot90(ah, k), x, y)
        out = cp.image()
        for t, xy in texts:
            label(out, t, xy, 13)
        p_ = os.path.join(SHEETS, f"frames_{bgname}.png")
        out.save(p_)
        paths.append(p_)
    return paths


def sheet_zoom():
    """The pixels themselves (nearest-neighbour zoom): edges, AA, ink outlines, no fringes."""
    crops = [("te5_mote", (0, 0, 128, 128), 4), ("te5_glint", (88, 88, 168, 168), 4),
             ("te5_streak", (96, 0, 160, 64), 4), ("te5_streak", (96, 140, 160, 256), 3),
             ("te5_shards", (256 + 60, 256 + 50, 256 + 160, 256 + 150), 4), ("te5_shards", (512 + 70, 768 + 60, 512 + 170, 768 + 160), 4),
             ("te5_ash", (512 + 80, 0 + 80, 512 + 400, 0 + 360), 1), ("te5_bokeh", (0, 60, 110, 170), 4),
             ("te5_smoke", (256, 0, 512, 256), 2)]
    paths = []
    for bgname, bg in (("dark", BG_DARK), ("sky", BG_SKY)):
        tiles = []
        for nm, (x0, y0, x1, y1), z in crops:
            img = load(nm)[y0:y1, x0:x1]
            img = np.repeat(np.repeat(img, z, 0), z, 1)
            cp = Comp(img.shape[1], img.shape[0], bg)
            cp.put_plain(img, 0, 0)
            t = cp.image()
            label(t, f"{nm} {x0},{y0} x{z}", (5, 3), 12)
            tiles.append(t)
        W = 1500
        x = y = 0
        rowh = 0
        placed = []
        for t in tiles:
            if x + t.width > W:
                x = 0
                y += rowh + 8
                rowh = 0
            placed.append((t, x, y))
            x += t.width + 8
            rowh = max(rowh, t.height)
        out = Image.new("RGB", (W, y + rowh), (30, 31, 36))
        for t, px_, py_ in placed:
            out.paste(t, (px_, py_))
        p_ = os.path.join(SHEETS, f"zoom_{bgname}.png")
        out.save(p_)
        paths.append(p_)
    return paths


# The spec's emitters (section 9): (Color, Transparency at peak, LightEmission day/night, Brightness day/night)
WHITE, SILVER_P, INK, SMOKE, MIST, ASH = (248, 249, 255), (214, 218, 226), (5, 5, 8), (14, 14, 19), (205, 209, 220), (16, 16, 20)


def _sys(night, le, br):
    return (le[1] if night else le[0]), (br[1] if night else br[0])


def ingame_panel(kind, night, w, h, seed):
    """One panel of simulated particles at their real on-screen size. px/stud 32 ~ a camera 20 studs away (FOV 70,
    913 px tall: ~650/distance px per stud). 'night' uses the spec's night LightEmission / Brightness."""
    rng = np.random.default_rng(seed)
    if night:
        cp = Comp(w, h, BG_DARK)
    else:
        cp = Comp(w, h, BG_SKY)
        cp.rgb[:] = sky_bg(w, h, seed)
    pps = 32.0
    texts = []
    if kind == "motes":
        mote = load("te5_mote")
        le, br = _sys(night, (0.2, 0.8), (1.4, 2.2))
        for _ in range(110):                                     # P6a air dust .06-.16 studs
            cp.put(mote, rng.uniform(0, w), rng.uniform(0, h), rng.uniform(0.06, 0.16) * pps, (226, 230, 240),
                   0.12, le, br)
        le, br = _sys(night, (0.2, 0.7), (1.4, 2.2))
        for _ in range(26):                                      # P2 moon dust .1-.24
            cp.put(mote, rng.uniform(0, w), rng.uniform(0, h), rng.uniform(0.1, 0.24) * pps, (238, 240, 246),
                   0.1, le, br)
        le, br = _sys(night, (0.3, 0.9), (1.6, 2.4))
        for _ in range(14):                                      # P1 swirl / P8a galaxy motes up to .32
            cp.put(mote, rng.uniform(0, w), rng.uniform(0, h), rng.uniform(0.2, 0.32) * pps, WHITE, 0.05, le, br)
        texts.append("P1/P2/P6a/P8a motes  .06-.32 studs  (2-10 px)")
    elif kind == "glints":
        gl = load("te5_glint")
        le, br = _sys(night, (0.5, 1.0), (1.6, 2.4))
        for _ in range(9):
            cp.put(gl, rng.uniform(20, w - 20), rng.uniform(20, h - 20), rng.uniform(0.5, 0.9) * pps, WHITE, 0.1,
                   le, br, rot=rng.uniform(0, 90))
        le, br = _sys(night, (0.4, 1.0), (1.6, 2.4))
        for _ in range(10):
            cp.put(gl, rng.uniform(10, w - 10), rng.uniform(10, h - 10), rng.uniform(0.25, 0.45) * pps, WHITE, 0.1,
                   le, br, rot=rng.uniform(0, 90))
        texts.append("P5a/P6b glints  .25-.9 studs (8-29 px)")
    elif kind == "shards":
        sh = load("te5_shards")
        le, br = _sys(night, (0.0, 0.3), (1.0, 1.6))
        for i in range(14):                                       # a stream across the dial toward the void
            u = i / 13.0
            x = 30 + u * (w - 60)
            y = h * 0.62 - math.sin(u * 2.4) * h * 0.35 + rng.normal(0, 8)
            sz = (0.5 + 0.25 * min(1.0, u / 0.85)) * pps * (1.5 if i % 4 == 0 else 1.0)
            cp.put(cell_of(sh, 4, int(rng.integers(0, 16))), x, y, sz, SILVER_P, 0.0, le, br, rot=rng.uniform(0, 360))
        texts.append("P3 shards  .5-.75 studs (16-24 px; every 4th at 1.5x)")
    elif kind in ("smoke_dark", "smoke_silver"):
        sm = load("te5_smoke")
        if kind == "smoke_dark":
            col, tr, le, br = SMOKE, 0.30, 0.0, 1.0
            texts.append("P4a dark rim smoke  3-7.5 studs, Transp .30-.45, LE 0")
        else:
            col, tr = (196, 200, 210), 0.45
            le, br = _sys(night, (0.1, 0.4), (1.0, 1.0))
            texts.append("P4b silver rim smoke  3-7 studs, Transp .45-.6")
        for i in range(12):                                       # a drifting plume: older (bigger, thinner) at the top
            life = i / 11.0
            k = min(15, int(life * 16))
            sz = (3.0 + 4.5 * life) * pps * 0.55
            ttr = tr + (0.15 * max(0.0, (life - 0.2) / 0.5) if life < 0.7 else 0.15 + 0.85 * (life - 0.7) / 0.3 * 0.5)
            x = w * 0.30 + life * w * 0.45 + rng.normal(0, 10)
            y = h * 0.80 - life * h * 0.55 + rng.normal(0, 8)
            cp.put(cell_of(sm, 4, k), x, y, sz, col, min(0.95, ttr), le, br, rot=rng.uniform(0, 360))
    elif kind == "bokeh":
        bk = load("te5_bokeh")
        le, br = _sys(night, (0.3, 0.8), (1.2, 1.8))
        # Rate 0.5 (day) / 1.2 (night) x Lifetime 5-7 s: about 3 (day) to 7 (night) alive, spread over a host box
        # wider than the screen; ~3 / ~4 land in a frame this size. 5-8 studs from the camera: ~70 px per stud.
        n_alive = 4 if night else 3
        xs_ = np.linspace(0.15, 0.85, n_alive) * w + rng.normal(0, 25, n_alive)
        for i in range(n_alive):
            cp.put(bk, xs_[i], rng.uniform(70, h - 70), rng.uniform(1.2, 2.4) * 70, (232, 236, 246),
                   0.6, le, br, rot=rng.uniform(0, 360))
        texts.append("P6c bokeh  1.2-2.4 studs close to the camera, Transp .6")
    elif kind == "streaks":
        st = load("te5_streak")
        le, br = _sys(night, (0.3, 0.9), (1.6, 2.4))
        cx, cy = w * 0.32, h * 0.5
        for i in range(26):                                       # P9 funnel: streaks spiralling inward
            ang = i / 26 * 2 * math.pi
            rr = 30 + (i % 5) * 9
            x, y = cx + rr * math.cos(ang), cy + rr * math.sin(ang) * 0.55
            vel = ang + math.pi / 2 + 0.5                         # tangent + inward
            sz = rng.uniform(0.18, 0.3) * pps * 1.6
            cp.put(st, x, y, sz, WHITE, 0.05, le, br, rot=-math.degrees(vel) + 90)
        cx2 = w * 0.75
        for i in range(18):                                       # P10b ink motes converging into the void palm
            ang = rng.uniform(0, 2 * math.pi)
            rr = rng.uniform(14, 48)
            x, y = cx2 + rr * math.cos(ang), cy + rr * math.sin(ang)
            sz = rng.uniform(0.12, 0.22) * pps * 1.6
            cp.put(st, x, y, sz, INK, 0.05, 0.0, 1.0, rot=-math.degrees(ang + math.pi) + 90)
        texts.append("P9 funnel (white) / P10b palm intake (ink)  streaks .1-.3 studs")
    elif kind == "ash":
        ah = load("te5_ash")
        for _ in range(26):
            cp.put(ah, rng.uniform(10, w - 10), rng.uniform(10, h - 10),
                   rng.uniform(0.28, 0.42) * pps * 1.2, ASH, 0.05, 0.0, 1.0, rot=rng.uniform(0, 360))
        texts.append("P8b ash  .28-.42 studs (9-14 px)")
    return cp.image(), texts


def sheet_ingame():
    kinds = ["motes", "glints", "shards", "ash", "streaks", "bokeh", "smoke_dark", "smoke_silver"]
    pw, ph = 420, 260
    paths = []
    for night in (False, True):
        cols = 4
        rows = 2
        out = Image.new("RGB", (cols * (pw + 8) + 8, rows * (ph + 8) + 8 + 24), (30, 31, 36))
        label(out, ("NIGHT (dark, night LightEmission/Brightness)" if night else
                    "DAY (sky + cloud, day LightEmission/Brightness)") + "  - particles at their in-game size, "
              "spec Color/Transparency", (8, 5), 14)
        for i, kd in enumerate(kinds):
            im, texts = ingame_panel(kd, night, pw, ph, 100 + i)
            x = 8 + (i % cols) * (pw + 8)
            y = 32 + (i // cols) * (ph + 8)
            out.paste(im, (x, y))
            for t in texts:
                label(out, t, (x + 6, y + 4), 12)
        p_ = os.path.join(SHEETS, f"ingame_{'night' if night else 'day'}.png")
        out.save(p_)
        paths.append(p_)
    return paths


def sheet_sizes():
    """Each texture at the pixel sizes it covers on screen (mip-filtered), day sky vs night, raw white/ink."""
    sets = [("te5_mote", [3, 4, 6, 8, 12, 16], WHITE, 0.25), ("te5_glint", [8, 12, 16, 24, 32], WHITE, 0.5),
            ("te5_shards", [12, 16, 20, 24, 32], SILVER_P, 0.0), ("te5_ash", [8, 10, 12, 14, 18], ASH, 0.0),
            ("te5_streak", [6, 8, 10, 14, 20], WHITE, 0.3)]
    rowh = 44
    W = 760
    paths = []
    out = Image.new("RGB", (W, len(sets) * rowh * 2 + 10), (30, 31, 36))
    for night in (False, True):
        for i, (nm, sizes, col, le_day) in enumerate(sets):
            y = (i * 2 + (1 if night else 0)) * rowh + 5
            cp = Comp(W - 150, rowh - 4, BG_DARK if night else BG_SKY)
            img = load(nm)
            x = 20
            for sz in sizes:
                for k in range(3 if nm in ("te5_shards", "te5_ash") else 1):
                    tex = cell_of(img, GRIDS[nm], k * 5 % (GRIDS[nm] ** 2)) if nm in GRIDS else img
                    le = (0.9 if night else le_day) if col != ASH else 0.0
                    br = (2.2 if night else 1.5) if col == WHITE else (1.6 if night and nm == "te5_shards" else 1.0)
                    cp.put(tex, x, (rowh - 4) / 2, sz, col, 0.05, le, br, rot=0)
                    x += sz + 10
                x += 14
            out.paste(cp.image(), (150, y))
            label(out, f"{nm} {'night' if night else 'day'}", (6, y + 12), 12)
    p_ = os.path.join(SHEETS, "sizes.png")
    out.save(p_)
    paths.append(p_)
    return paths


def make_sheets():
    os.makedirs(SHEETS, exist_ok=True)
    paths = []
    for fn in (sheet_overview, sheet_frames, sheet_zoom, sheet_ingame, sheet_sizes):
        t0 = time.time()
        paths += fn()
        print(f"sheet {fn.__name__}: {time.time() - t0:.1f}s")
    return paths


# ====================================================================================================================
# numerical spec checks on the written PNGs
# ====================================================================================================================


def _radial(img, ch, r0, r1, n, cell=None):
    """Mean of channel ch over the annulus r0..r1 (cell units, r 0.5 = cell edge)."""
    h, w = img.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    rr = np.hypot(xx + 0.5 - w / 2, yy + 0.5 - h / 2) / w
    m = (rr >= r0) & (rr < r1)
    return float(img[..., ch][m].mean())


def check():
    fails = []

    def ok(cond, msg):
        print(("  ok   " if cond else "  FAIL ") + msg)
        if not cond:
            fails.append(msg)

    sizes = {"te5_shards": (1024, 1024), "te5_smoke": (1024, 1024), "te5_mote": (128, 128), "te5_glint": (256, 256),
             "te5_bokeh": (256, 256), "te5_streak": (256, 256), "te5_ash": (256, 256)}
    imgs = {}
    for nm, (w, h) in sizes.items():
        im = Image.open(os.path.join(OUT, nm + ".png"))
        a = np.asarray(im.convert("RGBA")).astype(np.int32)
        imgs[nm] = a
        ok(im.mode == "RGBA" and im.size == (w, h), f"{nm}: RGBA {w}x{h}")
        R, G, B, A = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
        ok(bool((R == G).all() and (G == B).all()), f"{nm}: monochrome (R = G = B)")
        g = GRIDS.get(nm, 1)
        ch, cw = h // g, w // g
        edge4 = 0
        for j in range(g):
            for i in range(g):
                c = A[j * ch:(j + 1) * ch, i * cw:(i + 1) * cw]
                m4 = max(1, int(round(0.04 * cw)))
                ring = np.ones_like(c, bool)
                ring[m4:-m4, m4:-m4] = False
                edge4 = max(edge4, int(c[ring].max()))
        ok(edge4 == 0, f"{nm}: alpha 0 within 4 % of every {'cell' if g > 1 else 'frame'} edge (no square edges)")
        # no fringes: every fully transparent pixel touching visible ones carries a grey inside the range of those
        # neighbours (8-neighbourhood), so filtering never pulls black or white into an edge
        vis = A > 0
        Rp = np.pad(R, 1)
        Vp = np.pad(vis, 1)
        lo = np.full(R.shape, 999)
        hi = np.full(R.shape, -1)
        anyv = np.zeros(R.shape, bool)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                v2 = Vp[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
                r2 = Rp[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
                lo = np.where(v2, np.minimum(lo, r2), lo)
                hi = np.where(v2, np.maximum(hi, r2), hi)
                anyv |= v2
        edge = (~vis) & anyv
        if edge.any():
            out_by = np.maximum(lo - R, R - hi)[edge]
            ok(int(out_by.max()) <= 3, f"{nm}: transparent edge pixels carry their neighbours' grey (no fringe; "
                                       f"max {int(max(out_by.max(), 0))} levels outside)")
    # --- shards
    a = imgs["te5_shards"]
    pad_ok, body_ok, areas = True, True, []
    for k in range(16):
        c = cell_of(a, 4, k)
        A = c[..., 3]
        lim = int(round(0.20 * 256))
        ring = np.ones_like(A, bool)
        ring[lim:-lim, lim:-lim] = False
        pad_ok &= int(A[ring].max()) == 0
        areas.append(int((A > 127).sum()))
        body_ok &= int((A == 255).sum()) > 0.8 * int((A > 0).sum()) - 400
    ok(pad_ok, "te5_shards: >= 20 % padding in all 16 cells")
    ok(body_ok, "te5_shards: opaque body (alpha 1 inside, AA only on the rim)")
    jumps = [abs(areas[(k + 1) % 16] - areas[k]) / max(areas) for k in range(16)]
    ok(max(jumps) < 0.35, f"te5_shards: loop is continuous (max silhouette-area step {max(jumps):.2f} incl. 15 -> 0)")
    c0 = cell_of(a, 4, 0)
    front = c0[..., 0][(c0[..., 3] == 255) & (c0[..., 0] > 150)]
    ok(abs(float(np.median(front)) / 255 - 0.86) < 0.04, f"te5_shards: front face L {np.median(front) / 255:.2f} "
                                                          "(spec 0.86)")
    c8 = cell_of(a, 4, 8)
    back = c8[..., 0][(c8[..., 3] == 255) & (c8[..., 0] < 110) & (c8[..., 0] > 30)]
    ok(abs(float(np.median(back)) / 255 - 0.25) < 0.04, f"te5_shards: back face L {np.median(back) / 255:.2f} "
                                                         "(spec 0.25)")
    # --- smoke
    a = imgs["te5_smoke"]
    peaks, prev, steps = [], None, []
    win_ok, rgb_ok = True, True
    yy, xx = np.mgrid[0:256, 0:256]
    rr = np.hypot(xx + 0.5 - 128, yy + 0.5 - 128) / 256
    for k in range(16):
        c = cell_of(a, 4, k).astype(F32)
        A = c[..., 3] / 255
        peaks.append(float(np.percentile(A[A > 0.02], 99.5)))
        win_ok &= float(A[rr >= 0.46].max()) == 0.0
        L = c[..., 0][A > 0.08] / 255
        rgb_ok &= bool(L.min() >= 0.74 and L.max() <= 1.0)
        Al = A.reshape(32, 8, 32, 8).mean(axis=(1, 3))      # 8 px blocks: the large-scale change the eye sees as a pop
        if prev is not None:
            steps.append(float(np.abs(Al - prev).mean()))
        prev = Al
    ok(all(abs(peaks[k] - 0.85) < 0.03 for k in (2, 3, 4)), "te5_smoke: alpha peaks at 0.85 in frames 2-4 -> " +
       " ".join(f"{p:.2f}" for p in peaks[:6]))
    ok(peaks[15] <= 0.355, f"te5_smoke: frame 15 peak alpha {peaks[15]:.2f} (<= 0.35)")
    ok(win_ok, "te5_smoke: alpha 0 beyond 0.46 of the cell in every frame")
    ok(rgb_ok, "te5_smoke: RGB 0.75-1.0 wherever the smoke is visible")
    ok(max(steps) < 0.035, f"te5_smoke: frames change gently (max large-scale mean |dA| per frame {max(steps):.3f})")
    # --- mote
    a = imgs["te5_mote"].astype(F32) / 255
    vals = [(_radial(a, 3, 0.0, 0.2, 128), 1.0, 0.01, "core alpha"), (_radial(a, 0, 0.0, 0.2, 128), 1.0, 0.01, "core RGB"),
            (_radial(a, 3, 0.235, 0.285, 128), 0.85, 0.02, "rim alpha"), (_radial(a, 0, 0.235, 0.285, 128), 18 / 255, 0.02,
                                                                            "rim RGB"),
            (_radial(a, 3, 0.305, 0.315, 128), 0.235, 0.03, "glow alpha at r .31"), (_radial(a, 3, 0.47, 0.5, 128), 0.0, 0.002,
                                                                                    "alpha 0 at r >= .47")]
    for v, want, tol, what in vals:
        ok(abs(v - want) <= tol, f"te5_mote: {what} {v:.3f} (spec {want:.3f})")
    # --- glint
    a = imgs["te5_glint"].astype(F32) / 255
    ok(a[128, 128, 3] > 0.99 and _radial(a, 3, 0.0, 0.045, 256) > 0.99, "te5_glint: core disc alpha 1")
    yy, xx = np.mgrid[0:256, 0:256]
    rr = np.hypot(xx + 0.5 - 128, yy + 0.5 - 128) / 256
    th = np.degrees(np.arctan2(yy + 0.5 - 128, xx + 0.5 - 128)) % 45
    halo = (rr > 0.074) & (rr < 0.086) & (th > 12) & (th < 33)
    ok(abs(float(a[..., 3][halo].mean()) - 0.6) < 0.05 and float(a[..., 0][halo].mean()) < 0.08,
       f"te5_glint: ink halo r .07-.09 alpha {a[..., 3][halo].mean():.2f} RGB {a[..., 0][halo].mean() * 255:.0f}")
    row = a[127:129, :, 3].mean(axis=0)
    ok(row[128 + 30] > 0.4 and row[128 + 100] < 0.15 and row[128 + 100] > 0.0 and row[250] == 0,
       f"te5_glint: H spike alpha {row[158]:.2f} @ .12, {row[228]:.3f} @ .39, 0 at the tip")
    dg = np.array([a[128 + i, 128 + i, 3] for i in range(20, 60)])
    ok(dg.max() <= 0.52, f"te5_glint: 45 deg spikes alpha <= 0.5 (max {dg.max():.2f})")
    # --- bokeh
    a = imgs["te5_bokeh"].astype(F32) / 255
    inter = _radial(a, 3, 0.05, 0.3, 256)
    ok(abs(inter - 0.55) < 0.02, f"te5_bokeh: interior alpha {inter:.3f} (spec 0.55)")
    Lc = _radial(a, 0, 0.0, 0.05, 256)
    ok(abs(Lc - 0.90) < 0.02, f"te5_bokeh: centre L {Lc:.2f} (spec 0.9, brightening to 1.0 at the rim)")
    rim = float(a[..., 3][a[..., 3] > 0.80].mean()) if (a[..., 3] > 0.80).any() else 0
    ok(abs(rim - 0.85) < 0.02, f"te5_bokeh: rim band alpha {rim:.3f} (spec 0.85)")
    ok(_radial(a, 3, 0.462, 0.5, 256) < 0.002, "te5_bokeh: alpha 0 outside the aperture")
    # --- streak
    a = imgs["te5_streak"].astype(F32) / 255
    rowy = int(0.3 * 256)
    rA = a[rowy, :, 3]
    ok(12 <= int((rA > 0.97).sum()) <= 15, f"te5_streak: white core {int((rA > 0.97).sum())} px wide (13)")
    vis = (a[rowy, :, 3] > 0.5)
    ok(20 <= int(vis.sum()) <= 24, f"te5_streak: total width {int(vis.sum())} px (22: 1:10 of its length)")
    inkpx = (a[rowy, :, 3] > 0.8) & (a[rowy, :, 0] < 0.1)
    ok(int(inkpx.sum()) >= 2, f"te5_streak: ink edges present ({int(inkpx.sum())} px RGB<=25, alpha>=.8)")
    ok(a[:int(0.04 * 256) - 1, :, 3].max() == 0 and a[int(0.96 * 256) + 1:, :, 3].max() == 0,
       "te5_streak: capsule within y 0.04-0.96")
    top_L = a[int(0.12 * 256), 128, 0]
    mid_L = a[int(0.55 * 256), 128, 0]
    ok(top_L > mid_L, f"te5_streak: the leading (top) end is brightest (L {top_L:.2f} vs {mid_L:.2f})")
    colA = a[:, 127:129, 3].mean(axis=1)
    ok(colA[int(0.55 * 256)] > 0.97 and colA[int(0.80 * 256)] < 0.6 and colA[int(0.92 * 256)] < 0.1,
       f"te5_streak: tail fades over the lower 40 % ({colA[int(0.55 * 256)]:.2f} / {colA[int(0.8 * 256)]:.2f} / "
       f"{colA[int(0.92 * 256)]:.2f})")
    # --- ash
    a = imgs["te5_ash"]
    pad_ok, ext_ok, body_ok, hl_ok = True, True, True, True
    exts = []
    for c in (a,):
        A = c[..., 3]
        cs = A.shape[0]
        lim = int(round(0.12 * cs))
        ring = np.ones_like(A, bool)
        ring[lim:-lim, lim:-lim] = False
        pad_ok &= int(A[ring].max()) == 0
        ys_, xs_ = np.nonzero(A > 127)
        ext = max(xs_.max() - xs_.min() + 1, ys_.max() - ys_.min() + 1) / cs
        exts.append(ext)
        ext_ok &= 0.6 <= ext <= 0.8
        solid = A == 255
        inner = solid & np.roll(solid, 2, 0) & np.roll(solid, -2, 0) & np.roll(solid, 2, 1) & np.roll(solid, -2, 1)
        body_ok &= bool(c[..., 0][inner].min() >= 14 and c[..., 0][inner].max() <= 22)
        hl_ok &= int((c[..., 0] >= 150).sum()) > 20 * cs // 128
    ok(pad_ok, "te5_ash: >= 12 % padding")
    ok(ext_ok, "te5_ash: flakes span 0.6-0.8 of the cell -> " + " ".join(f"{e:.2f}" for e in exts))
    ok(body_ok, "te5_ash: body RGB 14-22 at alpha 1")
    ok(hl_ok, "te5_ash: silver (190) edge highlight present")
    return fails


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--no-sheets", action="store_true")
    ap.add_argument("--check", action="store_true", help="only run the numerical spec checks on the PNGs")
    args = ap.parse_args()
    if args.check:
        sys.exit(1 if check() else 0)
    names = [s.strip() for s in args.only.split(",") if s.strip()] or list(JOBS)
    for nm in names:
        t0 = time.time()
        JOBS[nm]()
        print(f"{nm}: {time.time() - t0:.1f}s")
    write_manifest()
    if not args.no_sheets:
        make_sheets()
    if not args.only:
        print("checks:")
        if check():
            sys.exit(1)


if __name__ == "__main__":
    main()
