#!/usr/bin/env python3
# THE END (1 in 1,000,000,000) -- equipped aura -- texture group "particles" (pass 6: film-quality particles).
#
# 10 textures (keys stay valid for the module's TEX5 slots; 3 are new):
#   te5_glint     (256^2)                    glint5    a photographic star: hot core, soft halo, four tapering
#                                                      diffraction spikes with faint interference, four thin diagonals
#   te5_twinkle   (1024^2, Grid4x4 OneShot)  twinkle   NEW: that star blooming from a point, turning, drawing back
#   te5_mote      (128^2)                    mote      a soft point of light (core + glow + halo, no ring)
#   te5_stardust  (1024^2, Grid4x4 Loop)     stardust  NEW: a pinch of glitter (30 grains swelling and fading in turn)
#   te5_streak    (256^2)                    streak5   a comet of matter for VelocityParallel (the TOP leads)
#   te5_spark     (256^2)                    spark5    NEW: a hot spark with a hairline motion-blur tail (TOP leads)
#   te5_shards    (1024^2, Grid4x4 Loop)     shards5   a ray-traced shard of polished steel, one tumble in 16 frames
#   te5_ash       (1024^2, Grid4x4 Loop)     ash5      a glowing ember flake tumbling, foreshortened (was one flake)
#   te5_bokeh     (256^2)                    bokeh     an out-of-focus light disc (nine-blade iris)
#   te5_smoke     (1024^2, Grid4x4 OneShot)  smoke5    unchanged (being replaced elsewhere): its code and PNG are
#                                                      byte-identical to pass 5
#
# Only python3 + numpy + PIL (runs the same on Milo's Mac and in the cloud). Deterministic: every random source is
# seeded, so a re-run gives byte-identical PNGs.
#
#   python3 make_te5_particles.py                     # all textures + manifest + contact sheets (sheets/) + checks
#   python3 make_te5_particles.py --no-sheets         # textures + manifest + checks
#   python3 make_te5_particles.py --only te5_mote,te5_glint
#   python3 make_te5_particles.py --before OLD_DIR    # also sheets/before_after.png against the PNGs in OLD_DIR
#   python3 make_te5_particles.py --check             # only the numerical self-tests on the PNGs
#
# How the images are made:
#   * Everything is rendered at 2x (SS; the shards ray-cast at 4x) and box-filtered down in PREMULTIPLIED alpha.
#   * Light (stars, motes, streaks, sparks, glitter) is built as physical layers: a flat-topped hot core, a gaussian
#     glow, a ~1/r^p scattered halo, diffraction spikes whose width and alpha taper to nothing; they combine as light
#     does (alpha = 1 - prod(1 - a)), and hairlines thinner than a pixel keep their energy instead of stair-stepping.
#   * The shards and the ember are rendered in 3D: the shard is a convex polyhedron ray-cast against a reflected photo
#     studio with Fresnel; the ember is a torn slab projected through its tumble (true foreshortening, edge-on rim).
#   * After downsampling, colour is un-premultiplied and BLED into the fully transparent pixels (nearest visible colour,
#     per flipbook cell), so Roblox's bilinear filtering and mip-maps never mix black into an edge: no fringes.
#   * Soft gradients get +-1 LSB triangular dither before 8-bit quantisation: no banding.
#   * Monochrome: every pixel is neutral grey (R = G = B). The particle Color supplies the faint cool tint.
#   * Flipbooks are exactly 1024x1024 (Roblox refuses any other size); cells are laid out row-major from the top-left
#     (Roblox order); alpha is exactly 0 within 4 % of every cell edge; colour bleeding never crosses a cell border.
#   * The contact sheets composite like tools/preview: sRGB textures in linear light, out = src*a + dst*(1 - a*(1 -
#     LightEmission)), the place's Bloom (threshold 2) and the preview's filmic curve. NOT Studio: a sheet is evidence.
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


def coverage(sd, aa):
    """Anti-aliased coverage of 'sd <= 0' with a linear ramp 'aa' wide (same units as sd)."""
    return np.clip(0.5 - sd / aa, 0.0, 1.0).astype(F32)


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
# --------------------------------------------------------------------------------------------------------------------
# light: photographic stars (glint, twinkle, stardust, the heads of streaks and sparks)
# --------------------------------------------------------------------------------------------------------------------


def thin_line(across, hw, hw_min):
    """Gaussian profile across a stroke of half-width hw. A stroke thinner than hw_min is drawn hw_min wide with its
    energy kept (alpha x hw / hw_min), so a hairline fades out instead of breaking into stair-steps."""
    hw = np.asarray(hw, F32)
    k = np.minimum(hw / hw_min, 1.0)
    hwe = np.maximum(hw, hw_min)
    return (k * np.exp(-0.5 * (across / hwe) ** 2)).astype(F32)


def union(layers):
    """Alpha of light layers seen together: 1 - prod(1 - a) (they add up and saturate softly, never past 1)."""
    keep = np.float32(1.0)
    for a in layers:
        keep = keep * (1.0 - np.clip(a, 0.0, 1.0))
    return np.clip(1.0 - keep, 0.0, 1.0).astype(F32)


def spikes4(base_ang, L, w0, w1, a0, l0, p, q, rip=0.0, lam=0.03, fringe=0.0, jitter=(1, 1, 1, 1), tw=1.2, cc=0.55):
    """Four arms at base_ang + k*90 deg (degrees). L = arm length, w0/w1 = full width at the core / tip in output px,
    a0 = peak alpha, l0/p = the photographic falloff near the core, q = taper to the tip, cc = share of the core peak,
    rip/lam = faint interference beads, fringe = faint parallel side lobes, jitter = per-arm length factors."""
    return [dict(ang=base_ang + 90 * k, len=L * jitter[k], w0=w0, w1=w1, a0=a0, l0=l0, p=p, q=q, rip=rip, lam=lam,
                 fringe=fringe, tw=tw, cc=cc) for k in range(4)]


def star_alpha(X, Y, px, core_r=0.016, glow_a=0.80, glow_s=0.030, halo_a=0.30, halo_r0=0.022, halo_p=1.6,
               spikes=(), ring=(), win=(0.36, 0.47)):
    """Alpha of a photographic star (white light) in cell units (+y up; px = one output px): a hot flat-topped core,
    the lens's gaussian glow, a long scattered halo (~1/r^halo_p, windowed to 0 between win[0] and win[1]),
    diffraction spikes (spikes4) that taper to nothing at their tips, and faint rings (radius, width, alpha)."""
    r = np.hypot(X, Y)
    w = sstep(win[1], win[0], r)
    layers = [1.0 / (1.0 + (r / core_r) ** 6),
              glow_a * np.exp(-0.5 * (r / glow_s) ** 2),
              halo_a / (1.0 + (r / halo_r0) ** 2) ** (halo_p / 2.0) * w]
    hw_min = 0.55 * px
    for s in spikes:
        if s["len"] <= 1e-6 or s["a0"] <= 0:
            continue
        th = math.radians(s["ang"])
        c, sn = math.cos(th), math.sin(th)
        along = X * c + Y * sn
        across = -X * sn + Y * c
        L = s["len"]
        u = np.clip(along / L, 0.0, 1.0)
        on = (along > 0) & (along < L)
        hw = 0.5 * px * (s["w1"] + (s["w0"] - s["w1"]) * (1.0 - u) ** s["tw"])
        cc = s["cc"]
        fall = cc / (1.0 + (np.maximum(along, 0) / s["l0"]) ** s["p"]) + (1.0 - cc)   # a core peak on a slow taper
        taper = (1.0 - u) ** s["q"]
        # faint interference beads along the arm, their spacing growing outward (a chirp, never a regular zipper)
        rip = 1.0 + s["rip"] * np.cos(2 * math.pi * along / (s["lam"] * (1.0 + 1.6 * u))) * sstep(0.03, 0.08, along) * (1 - u)
        prof = thin_line(across, hw, hw_min)
        if s["fringe"]:
            prof = prof + s["fringe"] * (thin_line(across - 2.6 * hw, 0.6 * hw, hw_min) + thin_line(across + 2.6 * hw, 0.6 * hw, hw_min))
        layers.append(np.where(on, s["a0"] * fall * taper * rip * prof, 0.0))
    for (rr, ww, aa) in ring:
        layers.append(aa * np.exp(-0.5 * ((r - rr) / ww) ** 2) * w)
    return union(layers) * sstep(0.462, 0.44, r)


def filament_noise(seed, n=4096, f0=2, f1=12):
    """Smooth 1D noise over [0, 1] (n samples, f0..f1 cycles), values in [-1, 1]."""
    rng = np.random.default_rng(seed)
    f = np.arange(n // 2 + 1)
    band = sstep(f0, f0 * 2, f) * (1.0 - sstep(f1, f1 * 1.6, f))
    spec = (rng.standard_normal(f.size) + 1j * rng.standard_normal(f.size)) * band
    prof = np.fft.irfft(spec, n=n)
    return (prof / np.abs(prof).max()).astype(F32)


# ====================================================================================================================
# te5_mote  (128^2): a soft photographic point of light: hot core, gaussian glow, a short scattered halo. No ring.
# ====================================================================================================================


def make_mote():
    n = 128
    X, Y = cell_xy(n)
    r = np.hypot(X, Y)
    core = 1.0 / (1.0 + (r / 0.060) ** 5)                    # solid hot centre to r ~0.05, half at 0.06
    glow = 0.62 * np.exp(-0.5 * (r / 0.080) ** 2)
    halo = 0.26 / (1.0 + (r / 0.050) ** 2) ** 1.15 * sstep(0.44, 0.20, r)
    A = union([core, glow, halo]) * sstep(0.465, 0.43, r)
    return finish("te5_mote", A.copy(), A, dither=True, seed=11)


# ====================================================================================================================
# te5_glint  (256^2): a photographic star: tiny hot core, soft halo, four tapering diffraction spikes with faint chirped
# interference beads and side fringes, four thin secondary spikes at 45 deg, the faintest ring
# ====================================================================================================================

GLINT_MAIN = dict(L=0.455, w0=5.0, w1=0.6, a0=1.0, l0=0.030, p=1.4, q=1.5, rip=0.07, lam=0.022, fringe=0.06, cc=0.55)
GLINT_SEC = dict(L=0.27, w0=2.6, w1=0.5, a0=0.60, l0=0.016, p=1.3, q=1.8, cc=0.6)
GLINT_BODY = dict(core_r=0.020, glow_a=0.55, glow_s=0.034, halo_a=0.30, halo_r0=0.016, halo_p=2.3, ring_r=0.105,
                  ring_w=0.007, ring_a=0.025, win=(0.16, 0.40))


def glint_alpha(X, Y, px, e=1.0, rot=0.0, breathe=0.0, sec=1.0, fringe=1.0):
    """The glint star with an 'energy' e (0..1: spike length, core size, glow and halo all grow with it), turned by
    rot degrees; breathe lengthens the H arms and shortens the V arms (counterphase); sec scales the 45 deg spikes."""
    m, s2, b = GLINT_MAIN, GLINT_SEC, GLINT_BODY
    jit = (1.0 + breathe, 0.97 - breathe, 1.0 + breathe, 0.95 - breathe)
    main = spikes4(rot, m["L"] * e ** 0.85, m["w0"] * (0.55 + 0.45 * e), m["w1"], m["a0"] * (0.45 + 0.55 * e),
                   m["l0"], m["p"], m["q"], rip=m["rip"], lam=m["lam"], fringe=m["fringe"] * fringe * e, jitter=jit,
                   cc=m["cc"])
    diag = spikes4(rot + 45.0, s2["L"] * max(sec, 0.02), s2["w0"], s2["w1"], s2["a0"] * sec, s2["l0"], s2["p"], s2["q"],
                   jitter=(1.0, 0.9, 0.95, 0.85), cc=s2["cc"])
    return star_alpha(X, Y, px, core_r=b["core_r"] * (0.45 + 0.55 * e), glow_a=b["glow_a"] * e,
                      glow_s=b["glow_s"] * (0.6 + 0.4 * e), halo_a=b["halo_a"] * e, halo_r0=b["halo_r0"],
                      halo_p=b["halo_p"], spikes=main + diag, ring=[(b["ring_r"], b["ring_w"], b["ring_a"] * e)],
                      win=b["win"])


def make_glint():
    n = 256
    X, Y = cell_xy(n)
    A = glint_alpha(X, Y, 1.0 / n)
    return finish("te5_glint", A.copy(), A, dither=True, seed=12)


# ====================================================================================================================
# te5_twinkle  (1024^2, Grid4x4, OneShot over the particle's life): the glint star blooming from a point, its spikes
# growing and turning ~14 deg while it holds (H and V arms breathing in counterphase, the thin diagonals coming in
# late), then drawing back to a point. The twinkle is in the texture; the emitter keeps Size and Transparency steady.
# ====================================================================================================================



def _twinkle_e(k):
    """Energy of frame k: an ease-out bloom over the first 40 % of the life, a true hold, the mirror-image fall
    (0.15 -> 1 -> 0.15). Steps shrink toward the hold (0.25, 0.21, 0.17, 0.12, 0.08, 0.02), so even over the star
    halo's 6-8 s life (~0.45 s a frame) nothing pops; the first steps play while the emitters fade the particle in."""
    t = (k + 0.5) / 16.0
    x = min(1.0, min(t, 1.0 - t) / 0.4)
    return round(math.sin(0.5 * math.pi * x) ** 0.9, 4)


TWINKLE_E = [_twinkle_e(k) for k in range(16)]


def twinkle_cell(k, n=256):
    X, Y = cell_xy(n)
    t = (k + 0.5) / 16.0
    e = TWINKLE_E[k]
    sec = float(sstep(0.18, 0.45, t) * sstep(1.0, 0.72, t))
    A = glint_alpha(X, Y, 1.0 / n, e=e, rot=-7.0 + 14.0 * t, breathe=0.06 * math.sin(2 * math.pi * t), sec=sec)
    A = A * (0.55 + 0.45 * min(1.0, e / 0.6))                 # a newborn or dying point is dimmer
    return A.astype(F32), A.astype(F32)


def make_twinkle():
    cells = [twinkle_cell(k) for k in range(16)]
    P, A = assemble(cells, 4, 4)
    return finish("te5_twinkle", P, A, grid=(4, 4), dither=True, seed=21)


# ====================================================================================================================
# te5_bokeh  (256^2): an out-of-focus light: a soft-edged disc from a nine-blade iris (round, with the faintest
# polygon), brighter toward a thin rim (spherical aberration), faint aspheric onion rings, a few soft specks of lens
# dust, a whisper of scattered light outside the edge
# ====================================================================================================================


def sd_ngon(X, Y, R, n, rot):
    """Signed distance to a regular n-gon of circumradius R (exact on the flat sides)."""
    a = np.arctan2(Y, X) - rot
    seg = 2 * math.pi / n
    a = (a + seg / 2) % seg - seg / 2
    return (np.hypot(X, Y) * np.cos(a) - R * math.cos(math.pi / n)).astype(F32)


def make_bokeh():
    n = 256
    X, Y = cell_xy(n)
    px = 1.0 / n
    r = np.hypot(X, Y)
    R = 0.405
    sd = 0.82 * (r - R) + 0.18 * sd_ngon(X, Y, R * 1.012, 9, math.radians(11))
    edge = sstep(1.6 * px, -2.2 * px, sd)
    q = np.clip(r / R, 0, 1.2)
    a = 0.40 + 0.12 * q ** 3 + 0.30 * np.exp(-0.5 * ((sd + 0.016) / 0.0095) ** 2)
    rng = np.random.default_rng(31)
    nf = 4096
    f = np.arange(nf // 2 + 1)
    band = sstep(10, 16, f) * (1.0 - sstep(40, 60, f))
    spec = (rng.standard_normal(f.size) + 1j * rng.standard_normal(f.size)) * band
    prof = np.fft.irfft(spec, n=nf)
    prof /= np.abs(prof).max()
    a = a + 0.025 * np.interp(np.clip(r, 0, 0.999) * nf, np.arange(nf), prof) * sstep(0.1, 0.6, q)
    dust = np.zeros_like(r)
    for _ in range(6):
        cx, cy = rng.uniform(-0.28, 0.28, 2)
        rr = rng.uniform(0.007, 0.016)
        dust = np.maximum(dust, rng.uniform(0.03, 0.06) * np.exp(-0.5 * (np.hypot(X - cx, Y - cy) / rr) ** 2))
    A = np.clip(a - dust, 0, 1) * edge
    scatter = 0.05 * np.exp(-np.maximum(sd, 0) / 0.02) * (sd > 0) * sstep(0.46, 0.43, r)
    A = 1.0 - (1.0 - A) * (1.0 - scatter)
    P = (0.94 + 0.06 * q) * A
    return finish("te5_bokeh", P.astype(F32), A.astype(F32), dither=True, seed=13)


# ====================================================================================================================
# te5_streak  (256^2, VelocityParallel: the TOP leads): a comet of matter: a hot head with a tiny glint and a soft bow,
# a tapering luminous tail with a soft sheath and fine filaments that peel off and wander, brightening and fading
# ====================================================================================================================


def make_streak():
    n = 256
    X, Y = cell_xy(n)
    px = 1.0 / n
    yh, ye = 0.395, -0.44                                   # head centre (top = forward), tail end
    s = np.clip((yh - Y) / (yh - ye), 0.0, 1.0)            # 0 at the head, 1 at the tail's end
    below = sstep(yh + 0.004, yh - 0.026, Y)               # the tail fades in under the head (no edge at its centre)
    hw0 = 0.024                                            # tail half-width at the head (6 px)
    hw = hw0 * (1.0 - s) ** 0.85 + 0.6 * px
    a_core = (1.0 - s) ** 1.2 * (0.55 + 0.45 / (1.0 + (s / 0.10) ** 1.4))
    layers = [below * a_core * thin_line(X, 0.42 * hw, 0.5 * px),
              below * 0.32 * (1.0 - s) ** 1.9 * np.exp(-0.5 * (X / (1.8 * hw)) ** 2)]
    rng = np.random.default_rng(1414)
    for i in range(6):
        d = (-1) ** i * rng.uniform(0.25, 1.0)
        fq, ph = rng.uniform(0.8, 1.8), rng.uniform(0, 2 * math.pi)
        off = hw0 * (d * 1.25 * s ** 1.15 + 0.18 * np.sin(2 * math.pi * fq * s + ph) * s)
        b = np.interp(s * 4095, np.arange(4096), filament_noise(500 + i))
        amp = 0.42 * (1.0 - s) * np.clip(0.55 + 0.6 * b, 0.0, 1.0) * sstep(0.02, 0.12, s)
        layers.append(below * amp * thin_line(X - off, 0.32 * px + 0.25 * hw * (1 - s), 0.5 * px))
    rh = np.hypot(X, Y - yh)
    layers.append(1.0 / (1.0 + (rh / 0.021) ** 5))
    layers.append(0.60 * np.exp(-0.5 * (rh / 0.030) ** 2))
    gl = spikes4(0.0, 0.050, 1.8, 0.5, 0.55, 0.010, 1.2, 1.7, jitter=(1.0, 0.8, 1.0, 1.3))
    layers.append(star_alpha(X, Y - yh, px, core_r=0.012, glow_a=0.0, halo_a=0.10, halo_r0=0.012, halo_p=2.4,
                             spikes=gl, win=(0.03, 0.08)))
    A = union(layers) * sstep(0.458, 0.43, np.abs(X)) * sstep(0.458, 0.43, Y) * sstep(-0.458, -0.43, Y)
    return finish("te5_streak", A.copy(), A, dither=True, seed=14)


# ====================================================================================================================
# te5_spark  (256^2, VelocityParallel: the TOP leads): a hot fleck of metal with a long thin motion-blur tail (a
# grinding spark): smaller and hotter than the streak's head, a hairline tail with a faint sheath
# ====================================================================================================================


def make_spark():
    n = 256
    X, Y = cell_xy(n)
    px = 1.0 / n
    X = X - 0.5 * px                                       # the hairline sits on one pixel column, not between two
    yh, ye = 0.34, -0.44
    s = np.clip((yh - Y) / (yh - ye), 0.0, 1.0)
    below = sstep(yh + 0.003, yh - 0.020, Y)
    hw = 0.0048 * (1.0 - s) ** 0.7 + 0.42 * px              # 2.5 px at the head -> sub-pixel at the tail
    a_line = (1.0 - s) ** 1.6 * (0.5 + 0.5 / (1.0 + (s / 0.06) ** 1.5))
    rh = np.hypot(X, Y - yh)
    gl = spikes4(0.0, 0.055, 1.8, 0.5, 0.55, 0.008, 1.2, 1.7, jitter=(1.0, 0.7, 1.0, 1.0))
    A = union([below * a_line * thin_line(X, hw, 0.5 * px),
               below * 0.20 * (1.0 - s) ** 2.6 * np.exp(-0.5 * (X / (3.0 * hw + 2 * px)) ** 2),
               1.0 / (1.0 + (rh / 0.013) ** 5),
               0.50 * np.exp(-0.5 * (rh / 0.026) ** 2),
               0.16 / (1.0 + (rh / 0.018) ** 2) ** 1.2 * sstep(0.14, 0.05, rh),
               star_alpha(X, Y - yh, px, core_r=0.008, glow_a=0.0, halo_a=0.0, spikes=gl, win=(0.03, 0.08))])
    A = A * sstep(0.458, 0.43, np.abs(X)) * sstep(0.458, 0.43, Y) * sstep(-0.458, -0.43, Y)
    return finish("te5_spark", A.copy(), A, dither=True, seed=22)


# ====================================================================================================================
# te5_shards  (1024^2, Grid4x4, Loop): a REAL render of a tumbling shard of polished steel, 16 frames of one turn.
# The shard is a convex polyhedron (a broken blade: an irregular outline, a wedge thick on one side with a shallow
# ridge on each face, every real edge chamfered), ray-cast per sample (orthographic, 4x supersampled). Shading: Fresnel
# (Schlick, F0 0.6) between a photo studio reflected in each surface (grey room, dark floor band under a bright
# horizon line, overhead softbox, a rectangular key softbox up-left, a fill card, tall strip lights behind for rim
# light) and a little satin diffuse, plus the key light's specular glint. The faces bulge very slightly (as a piece
# broken off a curved bezel would), so reflections glide across them as the shard turns instead of popping; brushed
# grain on the faces, rough fracture walls. A film shoulder rolls highlights off.
# ====================================================================================================================

SHARD_OUTLINE = [(-0.215, -0.430), (0.095, -0.470), (0.255, -0.080), (0.175, 0.360), (-0.030, 0.500),
                 (-0.205, 0.190), (-0.265, -0.120)]
SHARD_FACES = [((0.13, 0.02, 1.0), 0.034, "front"), ((-0.17, -0.03, 1.0), 0.030, "front"),
               ((0.09, -0.04, -1.0), 0.026, "back"), ((-0.12, 0.03, -1.0), 0.024, "back")]
SHARD_CHAMFER, SHARD_CHAMFER_SIDE = 0.010, 0.008
SHARD_AXIS = (0.50, 0.72, 0.45)         # the tumble axis (screen space: x right, y up, z toward the camera)
SHARD_PAD = 0.20                        # >= 20 % padding on every side of every cell
SHARD_SS = 4                            # samples per output px (each way)
SHARD_KEY = (-0.50, 0.70, 0.52)


def nrm(v):
    v = np.asarray(v, np.float64)
    return v / np.linalg.norm(v)


def rot_axis(axis, ang):
    a = nrm(axis)
    x, y, z = a
    c, s = math.cos(ang), math.sin(ang)
    C = 1 - c
    return np.array([[c + x * x * C, x * y * C - z * s, x * z * C + y * s],
                     [y * x * C + z * s, c + y * y * C, y * z * C - x * s],
                     [z * x * C - y * s, z * y * C + x * s, c + z * z * C]])


def poly_vertices(planes):
    """Vertices of the convex polyhedron {x : n.x <= d for every (n, d)} (all triple intersections inside it)."""
    N = np.array([p[0] for p in planes])
    D = np.array([p[1] for p in planes])
    out = []
    for i in range(len(planes)):
        for j in range(i + 1, len(planes)):
            for k in range(j + 1, len(planes)):
                M = N[[i, j, k]]
                if abs(np.linalg.det(M)) < 1e-9:
                    continue
                x = np.linalg.solve(M, D[[i, j, k]])
                if np.all(N @ x <= D + 1e-6) and not any(np.linalg.norm(x - u) < 1e-6 for u in out):
                    out.append(x)
    return np.array(out)


def shard_planes():
    """(normal, offset, kind) half-spaces of the shard: side walls along the outline (each tilted a little: a broken
    edge is never square to the faces), the faceted faces, then a chamfer on every real edge (faces meeting at more
    than 35 deg; the shallow ridge stays sharp)."""
    ol = np.asarray(SHARD_OUTLINE, np.float64)
    if poly_area(ol) < 0:
        ol = ol[::-1]
    rng = np.random.default_rng(77)
    planes = []
    for i in range(len(ol)):
        a, b = ol[i], ol[(i + 1) % len(ol)]
        e = b - a
        n2 = np.array([e[1], -e[0]]) / np.linalg.norm(e)
        n = nrm([n2[0], n2[1], rng.uniform(-0.25, 0.25)])
        planes.append((n, float(n @ np.array([a[0], a[1], 0.0])), "side"))
    for nv, d, kind in SHARD_FACES:
        planes.append((nrm(nv), d, kind))
    V = poly_vertices([(p[0], p[1]) for p in planes])
    base = list(planes)
    for i in range(len(base)):
        for j in range(i + 1, len(base)):
            pi, pj = base[i], base[j]
            on = [v for v in V if abs(pi[0] @ v - pi[1]) < 1e-6 and abs(pj[0] @ v - pj[1]) < 1e-6]
            if len(on) < 2 or float(pi[0] @ pj[0]) > math.cos(math.radians(35)):
                continue
            nc = nrm(pi[0] + pj[0])
            c = SHARD_CHAMFER_SIDE if (pi[2] == "side" and pj[2] == "side") else SHARD_CHAMFER
            planes.append((nc, max(float(nc @ v) for v in V) - c, "chamfer"))
    return planes


SHARD_R0 = rot_axis([1, 0, 0], math.radians(-18)) @ rot_axis([0, 0, 1], math.radians(-24))


def shard_rot(k):
    return rot_axis(SHARD_AXIS, 2 * math.pi * k / 16.0) @ SHARD_R0


def studio_env(R):
    """The studio reflected in the steel, by reflection direction R (view space: +y up, +z toward the camera).
    Radiance (the film shoulder in render_shard rolls it off)."""
    rx, ry, rz = R[..., 0], R[..., 1], R[..., 2]
    L = 0.42 + 0.12 * np.clip(ry, 0, 1)                                   # the grey room
    L = L - 0.34 * sstep(-0.02, -0.12, ry) * sstep(-0.80, -0.40, ry)     # a dark floor band below the horizon
    L = L + 0.50 * np.exp(-((ry - 0.02) / 0.03) ** 2)                    # the horizon's bright line
    az = np.degrees(np.arctan2(rx, rz))
    el = np.degrees(np.arcsin(np.clip(ry, -1, 1)))

    def rect(az0, el0, w, h, k, soft=4.0):
        da = np.abs((az - az0 + 180.0) % 360.0 - 180.0)
        return k * sstep(w + soft, w, da) * sstep(h + soft, h, np.abs(el - el0))

    def strip(az0, k, half_w=7.0, y0=-0.55, y1=0.80):
        da = np.abs((az - az0 + 180.0) % 360.0 - 180.0)
        return k * sstep(half_w + 4.0, half_w, da) * sstep(y0 - 0.1, y0, ry) * sstep(y1 + 0.1, y1, ry)

    L = L + 0.95 * sstep(52.0, 64.0, el)                                 # overhead softbox
    L = L + rect(-40.0, 30.0, 13.0, 8.0, 1.65)                           # key softbox (rectangular, like a real one)
    L = L + rect(44.0, -22.0, 11.0, 7.0, 0.50)                           # fill card
    L = L + rect(180.0, -20.0, 26.0, 9.0, 0.95)                          # a lit floor sweep behind (grazing faces)
    L = L + strip(112.0, 1.25) + strip(-118.0, 1.05)                     # rim strips behind, right and left
    L = L + strip(48.0, 0.45, half_w=5.0) + strip(-40.0, 0.40, half_w=4.0)
    return L


def render_shard(planes, Rm, scale, n=256, ss=SHARD_SS):
    """One frame: (P, A) at 2x of an n-px cell (box-filtered from ss x ss samples per output px)."""
    M = n * ss
    xs = ((np.arange(M) + 0.5) / M - 0.5)
    X = np.broadcast_to(xs[None, :], (M, M))
    Y = np.broadcast_to(-xs[:, None], (M, M))
    N = np.array([Rm @ p[0] for p in planes])
    D = np.array([p[1] * scale for p in planes])
    ztop = np.full((M, M), np.inf)
    zbot = np.full((M, M), -np.inf)
    arg = np.full((M, M), -1, np.int32)
    for i, (nv, d) in enumerate(zip(N, D)):
        zc = (d - (nv[0] * X + nv[1] * Y)) / (nv[2] if abs(nv[2]) > 1e-9 else 1e-9)
        if nv[2] > 0:
            m = zc < ztop
            ztop = np.where(m, zc, ztop)
            arg = np.where(m, i, arg)
        else:
            zbot = np.maximum(zbot, zc)
    hit = (ztop >= zbot) & (arg >= 0)
    ai = np.clip(arg, 0, None)
    nh = N[ai]
    Pl = (np.stack([X, Y, np.where(hit, ztop, 0.0)], axis=-1) / scale) @ Rm      # hit point, shard-local
    nl = nh @ Rm
    kind = np.array([{"front": 0, "back": 0, "side": 1, "chamfer": 2}[p[2]] for p in planes])[ai]
    kap = np.where(kind == 0, 1.15, np.where(kind == 1, 0.6, 0.3))[..., None]
    nlp = nl + kap * (Pl - np.sum(Pl * nl, axis=-1, keepdims=True) * nl)         # the faces bulge a little
    gx = Pl[..., 0] + 0.02 * np.sin(Pl[..., 1] * 31.0)
    g = (np.sin(gx * 1130.0) + 0.7 * np.sin(gx * 1717.0 + 1.3) + 0.5 * np.sin(gx * 2903.0 + 4.1)) / 2.2
    nlp[..., 0] += 0.014 * g * (kind == 0)                                        # brushed grain along the blade
    rough = (np.sin(Pl[..., 1] * 210.0 + 5.0 * np.sin(Pl[..., 0] * 90.0)) + np.sin(Pl[..., 2] * 380.0 + Pl[..., 1] * 150.0)) * 0.5
    nlp = nlp + (kind == 1)[..., None] * 0.10 * np.stack([rough, -rough, 0.6 * rough], axis=-1)   # rough fracture
    nlp /= np.linalg.norm(nlp, axis=-1, keepdims=True)
    nv = nlp @ Rm.T
    nv = np.where(nv[..., 2:3] < 0.02, nh, nv)
    vz = np.clip(nv[..., 2], 0.0, 1.0)
    R = np.stack([2 * vz * nv[..., 0], 2 * vz * nv[..., 1], 2 * vz * nv[..., 2] - 1.0], axis=-1)
    F = 0.60 + 0.40 * (1 - vz) ** 5
    key = nrm(SHARD_KEY)
    spec = np.clip(nv @ nrm(key + np.array([0, 0, 1.0])), 0, 1) ** 260
    Lr = F * studio_env(R) + (1 - F) * (0.05 + 0.08 * np.clip(nv @ key, 0, 1)) + 1.2 * spec
    L = 1.0 - np.exp(-1.55 * Lr)                                                  # film shoulder
    A = hit.astype(np.float64)
    f = ss // SS
    H2 = M // f
    P = (L * A).reshape(H2, f, H2, f).mean(axis=(1, 3))
    A = A.reshape(H2, f, H2, f).mean(axis=(1, 3))
    return P.astype(F32), A.astype(F32)


def shard_scale(planes, n=256):
    """Largest scale that keeps every frame's silhouette (+2 px) inside the 20 % padding box."""
    V = poly_vertices([(p[0], p[1]) for p in planes])
    ext = max(np.abs((V @ shard_rot(k).T)[:, :2]).max() for k in range(16))
    return (0.5 - SHARD_PAD - 2.0 / n) / ext


def make_shards():
    planes = shard_planes()
    sc = shard_scale(planes)
    cells = [render_shard(planes, shard_rot(k), sc) for k in range(16)]
    P, A = assemble(cells, 4, 4)
    make_shards.scale = sc
    return finish("te5_shards", P, A, grid=(4, 4), dither=False, seed=15)


# ====================================================================================================================
# te5_smoke  (1024^2, Grid4x4, OneShot): a dense ink-tight billow filling ~80 % of its cell, wisps only at the edge,
# dissolving from the edge inward only in frames 12-15 (review round 3)
# ====================================================================================================================

SMOKE_SEED = 777


def render_smoke_frame(k, no, cell=256):
    """One frame of the smoke: a dense, ink-tight billow (review round 3: the old curl covered ~30 % of its cell and was
    mostly translucent, so in game the 'ink' smoke read half see-through and teal on the sky). The billow fills ~80 %
    of the cell: a cauliflower of round lobes round a solid body (alpha >= 0.9 over its inner half), soft creases
    between the lobes, torn wisps only at its edge. It turns slowly, and dissolves only in frames 12-15, from the edge
    inward into ragged wisps. Everything is a smooth function of t = k / 15, so neighbouring frames differ only a little
    (the OneShot plays ~4 fps over the particle's life)."""
    X, Y = cell_xy(cell)
    t = k / 15.0
    e = sstep(0.0, 0.7, t)                           # grows over frames 0-10, then holds
    R = 0.37 + 0.035 * e                             # body radius 0.37 -> 0.405 of the cell (lobes reach ~0.44)
    r = np.hypot(X, Y)
    # a slow curl: the inside turns a little further than the outside
    W = 0.10 + 0.55 * t
    phi = W * np.exp(-(r / (0.9 * R)) ** 2)
    c, s = np.cos(-phi), np.sin(-phi)
    xs = X * c - Y * s
    ys = X * s + Y * c
    # gentle turbulence
    A = 0.015 + 0.03 * t
    wx = no(xs + 5.2, ys + 1.3, 3.0, n=3)
    wy = no(xs - 3.7, ys + 8.1, 3.0, n=3)
    qx, qy = xs + A * wx, ys + A * wy
    th = np.arctan2(qy, qx)
    # the cauliflower outline: 7 and 11 round lobes (their phases drift a little) plus low noise
    lobes = 0.075 * np.abs(np.sin(3.5 * th + 0.8 + 0.4 * t)) + 0.045 * np.abs(np.sin(5.5 * th + 2.1 - 0.3 * t)) - 0.06
    lob = no(qx * 0.9 + 11.7, qy * 0.9 - 2.4, 2.4, n=2)
    rb = R * (1.0 + lobes + 0.22 * lob)
    rq = np.hypot(qx, qy)
    rn = rq / np.maximum(rb, 0.05)
    # torn wisps at the edge only (ridged noise, masked to the rim band)
    wisp = no(qx, qy, 6.0, n=4, gain=0.55, drift=(0.0, -0.04 * t), ridge=0.6)
    rim = sstep(0.6, 0.9, rn)
    edge = sstep(1.12, 0.70, rn + 0.26 * wisp * rim)
    # soft creases between the lobes and big soft lumps inside (alpha 0.88-0.97)
    bill = no(qx + 2.2, qy - 7.4, 3.6, n=3)
    a = edge * (0.93 + 0.08 * bill)
    # dissolve (frames 12-15 only): it thins from the edge inward and noise tears it into ragged wisps
    d = min(max((t - 11.0 / 15.0) / (4.0 / 15.0), 0.0), 1.0)    # 0.25 a frame over frames 12-15
    if d > 0:
        ero = no(qx - 4.1, qy + 6.6, 4.0, n=3, ridge=0.2) + 0.45 + 0.7 * (1.0 - rn)   # the centre survives longest
        thr = d * 0.95
        a = a * sstep(thr - 0.2, thr + 0.2, ero) * (1.0 - 0.2 * d)
    win = 1.0 - sstep(0.38, 0.46, r)                  # alpha reaches 0 at 0.46 of the cell (no square edges)
    a = np.clip(a * win, 0.0, 0.97)
    dens = a
    # internal shading 0.75 - 1.0: self-shadow by marching toward the light (upper left) + a bump on the lumps
    Ld = (-0.55, 0.835)
    step = 2.0 * SS                                   # 2 output px per march step, 12 steps
    acc = np.zeros_like(dens)
    for j in range(1, 13):
        dy = int(round(-Ld[1] * step * j))
        dx = int(round(Ld[0] * step * j))
        acc += np.roll(np.roll(dens, -dy, axis=0), -dx, axis=1)
    T = np.exp(-0.5 * acc * (2.0 / 256.0) * 10.0)
    hgt = gblur(dens, 2.0 * SS) + 0.35 * gblur(np.clip(bill + 0.5, 0, 1) * edge, 4.0 * SS)   # the lumps' relief
    gy, gx = np.gradient(hgt)
    lam = (-gx * Ld[0] + gy * Ld[1]) * 9.0 * SS
    shade = np.clip(0.75 + 0.25 * np.clip(0.5 * T + 0.42 + lam, 0.0, 1.0), 0.75, 1.0)
    return (shade * a).astype(F32), a.astype(F32)


def make_smoke():
    no = Octaves(SMOKE_SEED)
    cells = [render_smoke_frame(k, no) for k in range(16)]
    P, A = assemble(cells, 4, 4)
    return finish("te5_smoke", P, A, grid=(4, 4), dither=True, seed=16)


# ====================================================================================================================
# te5_ash  (1024^2, Grid4x4, Loop): a glowing EMBER FLAKE tumbling through one turn in 16 frames, drawn in true
# perspective of its turn (foreshortened; edge-on it shows its thin burning rim). A torn flake of char, black with a
# faint fibrous grain and a dull sheen where it faces the light; its edge burns white-hot (a thin hot line, then a burn
# zone soaking inward, hotter along some stretches than others); wavy fissures run in from the burning edge. Monochrome:
# with a white particle Color and Brightness ~2.5 the edge glows past the Bloom threshold, the char stays black.
# ====================================================================================================================

EMBER_SEED, EMBER_CORNERS = 72, 9       # the flake outline (flake_polygon: a torn, star-shaped polygon)
EMBER_AXIS = (0.78, 0.50, 0.38)
EMBER_PAD = 0.14
EMBER_THICK = 0.035                     # thickness, in flake units (the flake spans 1.0)


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


def voronoi_cracks(U, V, pts):
    """F2 - F1 (the distance to the nearest Voronoi boundary of pts): small along the cracks."""
    d1 = np.full(U.shape, np.inf, F32)
    d2 = np.full(U.shape, np.inf, F32)
    for (x0, y0) in pts:
        d = np.hypot(U - x0, V - y0)
        m = d < d1
        d2 = np.where(m, d1, np.minimum(d2, d))
        d1 = np.where(m, d, d1)
    return (d2 - d1).astype(F32)


EMBER_R0 = rot_axis([0, 0, 1], math.radians(20)) @ rot_axis([1, 0, 0], math.radians(-25))


def ember_rot(k):
    return rot_axis(EMBER_AXIS, 2 * math.pi * k / 16.0) @ EMBER_R0


def ember_scale(outline, n=256):
    ext = 0.0
    for k in range(16):
        Rm = ember_rot(k)
        p = outline[:, :1] * Rm[None, :2, 0] + outline[:, 1:2] * Rm[None, :2, 1]
        ext = max(ext, float(np.abs(p).max()))
    return (0.5 - EMBER_PAD - 2.0 / n) / (ext + EMBER_THICK)


def render_ember(k, outline, scale, n=256):
    X, Y = cell_xy(n)
    px = 1.0 / n
    Rm = ember_rot(k)
    e1, e2, nn = Rm[:, 0], Rm[:, 1], Rm[:, 2]
    proj = (outline * scale)[:, :1] * e1[None, :2] + (outline * scale)[:, 1:2] * e2[None, :2]
    t = EMBER_THICK * scale
    # the slab's silhouette: the projected outline swept along the projected thickness
    sd = np.min(np.stack([sd_poly(X - w * nn[0], Y - w * nn[1], proj) for w in (-t / 2, 0.0, t / 2)]), axis=0)
    cov = coverage(sd, px)
    # flake coordinates (U, V) of the visible face (regularised when the flake is edge-on)
    wv = (t / 2) * (1.0 if nn[2] >= 0 else -1.0)
    bx, by = X - wv * nn[0], Y - wv * nn[1]
    M = np.array([[e1[0], e2[0]], [e1[1], e2[1]]])
    Mi = np.linalg.inv(M.T @ M + 2e-3 * np.eye(2)) @ M.T
    U = ((Mi[0, 0] * bx + Mi[0, 1] * by) / scale).astype(F32)
    V = ((Mi[1, 0] * bx + Mi[1, 1] * by) / scale).astype(F32)
    face = abs(float(nn[2]))                                    # 1 face-on, 0 edge-on
    di = np.maximum(-sd_poly(U, V, outline), 0.0)               # depth inside the flake (flake units)
    rng = np.random.default_rng(9090)
    nz = Noise(3131, f0=5.0)
    nz2 = Noise(3137, f0=9.0)
    # it burns from one side: a hot crescent there (a deeper burn zone soaking inward), cooling round the flake to a
    # nearly cold edge opposite, with hotter and cooler stretches along the way
    side = sstep(-0.32, 0.30, U * 0.80 + V * 0.60)
    m = np.clip(0.68 + 0.42 * nz(U * 0.45 + 3.3, V * 0.45 + 1.1), 0.35, 1.0) * (0.22 + 0.78 * side)
    rim = (0.55 * np.exp(-di / 0.010) + 0.60 * np.exp(-di / (0.030 + 0.050 * side))) * m
    pts = rng.uniform(-0.42, 0.42, (13, 2))
    wu = U + 0.050 * nz(U * 1.5 + 8.1, V * 1.5 - 2.2)                             # wavy cracks, not a cell network
    wvv = V + 0.050 * nz(U * 1.5 - 5.3, V * 1.5 + 6.6)
    cr = voronoi_cracks(wu, wvv, pts)
    fis = np.exp(-(cr / 0.0135) ** 2) * np.clip(1.0 - di / 0.10, 0, 1) ** 1.3 * m  # fissures in from the edge
    fglow = np.exp(-(cr / 0.026) ** 2) * np.clip(1.0 - di / 0.12, 0, 1) * m
    smoulder = 0.34 * np.exp(-di / (0.05 + 0.09 * side)) * m + 0.22 * fglow       # heat soaking in from the burn
    glow = np.clip(np.maximum(np.maximum(rim, 0.9 * fis), smoulder), 0, 1) ** 0.8
    # the char: near-black, a faint fibrous grain, a dull sheen where the (gently cupped) flake faces the light
    body = 0.032 + 0.012 * (0.5 + 0.5 * nz2(U * 0.9 + 7.0, V * 1.6))
    nloc = np.stack([-0.5 * U, -0.3 * V, np.ones_like(U)], axis=-1)
    nloc /= np.linalg.norm(nloc, axis=-1, keepdims=True)
    nvw = (nloc @ Rm.T) * (1.0 if nn[2] >= 0 else -1.0)
    K = nrm([-0.5, 0.7, 0.5])
    sheen = 0.05 * np.clip(nvw @ nrm(K + np.array([0, 0, 1.0])), 0, 1) ** 10 + 0.025 * np.clip(nvw @ K, 0, 1)
    L = 1.0 - (1.0 - (body + sheen * face)) * (1.0 - glow)
    side = sstep(0.35, 0.05, face)                              # edge-on, what shows is the burning rim itself
    L = L * (1 - side) + side * np.maximum(L, 0.75 * m)
    return (np.clip(L, 0, 1) * cov).astype(F32), cov.astype(F32)


def make_ash():
    outline = flake_polygon(EMBER_SEED, EMBER_CORNERS, 1.0)
    sc = ember_scale(outline)
    cells = [render_ember(k, outline, sc) for k in range(16)]
    P, A = assemble(cells, 4, 4)
    return finish("te5_ash", P, A, grid=(4, 4), dither=False, seed=17)


# ====================================================================================================================
# te5_stardust  (1024^2, Grid4x4, Loop): a pinch of silver glitter: ~30 grains of three sizes (three of them tiny
# four-point stars) in a loose cluster. Over the 16 frames every grain swells and fades once (a smooth cosine, never
# off) and drifts round a tiny circle, each at its own phase, so the loop is seamless and a cluster glitters without a
# single blink. FlipbookStartRandom gives every particle its own phase.
# ====================================================================================================================

STARDUST_SEED = 4040


def stardust_points():
    rng = np.random.default_rng(STARDUST_SEED)
    pts = []
    for i in range(30):
        hero = i < 3
        while True:
            x0, y0 = rng.normal(0, 0.17, 2)
            if math.hypot(x0, y0) < (0.26 if hero else 0.355):
                break
        if hero:
            rc = rng.uniform(0.010, 0.013)
        elif rng.random() < 0.7:
            rc = rng.uniform(0.0055, 0.0085)
        else:
            rc = rng.uniform(0.0085, 0.011)
        b0 = 1.0 if hero else rng.uniform(0.55, 1.0)
        pts.append((x0, y0, rc, b0, rng.uniform(0, 1), rng.uniform(0.002, 0.007), hero, rng.uniform(0, 45)))
    return pts


def stardust_cell(k, pts, n=256):
    X, Y = cell_xy(n)
    px = 1.0 / n
    t = k / 16.0
    layers = []
    for (x0, y0, rc, b0, ph, orb, hero, sang) in pts:
        tw = 0.5 + 0.5 * math.cos(2 * math.pi * (t + ph))
        b = b0 * (0.35 + 0.65 * tw)
        cx = x0 + orb * math.cos(2 * math.pi * (t + ph))
        cy = y0 + orb * math.sin(2 * math.pi * (t + ph))
        Xs, Ys = X - cx, Y - cy
        if hero:
            sp = spikes4(sang, 0.085 * (0.5 + 0.5 * tw), 2.2, 0.5, 0.75 * b, 0.010, 1.2, 1.6, jitter=(1, 0.85, 1, 0.9))
            layers.append(b * star_alpha(Xs, Ys, px, core_r=rc * (0.75 + 0.25 * tw), glow_a=0.45 * b, glow_s=2.4 * rc,
                                         halo_a=0.0, spikes=sp, win=(0.05, 0.12)))
        else:
            rr = np.hypot(Xs, Ys)
            layers.append(b / (1.0 + (rr / (rc * (0.8 + 0.2 * tw))) ** 6))
            layers.append(0.22 * b * np.exp(-0.5 * (rr / (2.2 * rc)) ** 2))
    A = union(layers) * sstep(0.445, 0.41, np.hypot(X, Y))
    return A.astype(F32), A.astype(F32)


def make_stardust():
    pts = stardust_points()
    cells = [stardust_cell(k, pts) for k in range(16)]
    P, A = assemble(cells, 4, 4)
    return finish("te5_stardust", P, A, grid=(4, 4), dither=True, seed=23)


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
    "te5_twinkle": make_twinkle,
    "te5_spark": make_spark,
    "te5_stardust": make_stardust,
}

MANIFEST = [
    # name, texKey, fallbackTexKey, size, layout, mode, purpose, notes
    ("te5_shards", "shards5", "ash", "1024x1024", "Grid4x4", "Loop",
     "P3 metal shards breaking off the bezel and flying into the void",
     "Pass 6 (film quality): a real render, 16 frames of one smooth tumble (22.5 deg a frame about a tilted axis; frame "
     "16 = frame 0). The shard is a convex polyhedron ray-cast per sample at 4x4 supersampling: a broken blade of "
     "polished steel (irregular 7-sided outline, a wedge with a shallow ridge on each face, every real edge chamfered, "
     "rough fracture walls, brushed grain on the faces). Shading: Fresnel between a photo studio reflected in the metal "
     "(grey room, dark floor band under a bright horizon line, overhead softbox, rectangular key softbox up-left, fill "
     "card, rim strip lights behind, a lit floor sweep) and a little satin diffuse, plus the key light's glint; the "
     "faces bulge very slightly, so the reflections glide across them as it turns (no whole-face pop: per-frame mean "
     "L 0.31-0.63, max frame-to-frame brightness step 0.33). Every frame keeps >= 20 % padding (the shard spans "
     "0.24-0.57 of its cell); with the turn's edge-on frames "
     "it covers less area than pass 5's flat quad, so draw it ~1.6x the fallback's size (pass 5 used 1.3x). "
     "FlipbookFramerate 10-14 (one turn in ~1.3 s), FlipbookStartRandom true. Opaque (alpha 1 inside, AA rim)."),
    ("te5_smoke", "smoke5", "puff", "1024x1024", "Grid4x4", "OneShot",
     "P4a/P4b two-tone orb smoke, P7 rim mist and P11 the body's silver wisps",
     "Flipbook 4x4 OneShot. Review round 3: a dense billow filling ~80 % of its cell (body radius 0.37 -> 0.405, round "
     "lobes reaching ~0.44), alpha ~0.93 over its inner half, per-cell mean alpha >= 0.30 in frames 0-11, torn wisps only "
     "at the edge; it dissolves from the edge inward into ragged wisps in frames 12-15 only (mean alpha 0.36 -> 0.08). "
     "RGB 0.75-1.0 internal shading lit from the upper left (the lobes' relief). Radial window reaches alpha 0 at 0.46 of "
     "the cell. Frames 0-11 change gently (OneShot over a 3.5-4.5 s lifetime is ~4 fps); the dissolve frames play while "
     "the emitter's own Transparency fades the particle out. Drawn at the same size as the pass-4 puff (no 1.3x)."),
    ("te5_mote", "mote", "glow", "128x128", "None", None,
     "Dust motes: P1 void swirl and P2 moon dust (review round 3: the air dust, floor motes and foot drips became glints)",
     "Pass 6: a soft photographic point of light, no ring: a hot core (alpha 1 to r ~0.05, half at 0.06), a gaussian glow "
     "(sigma 0.08, alpha 0.62) and a short scattered halo (~1/r^2.3) fading to 0 by r 0.44. RGB white everywhere. Its "
     "bright core is smaller than pass 5's opaque disc (r 0.22), so it reads as light rather than a pearl; draw it ~1.25x "
     "the pass-5 size if the swirl looks thinner."),
    ("te5_glint", "glint5", "glint", "256x256", "None", None,
     "Four-point glints: P13 time dust round the bezel, P6a/P6b air sparkles, P8 floor twinkles, P11 the body's sparks",
     "Pass 6: a photographic star (white light, no ink): hot core (r ~0.02), gaussian glow (sigma 0.034) and a scattered "
     "halo (~1/r^2.3, gone by r 0.40); four diffraction spikes tips at 0.44-0.455, 5 px wide at the core tapering to "
     "0.6 px, alpha falling from a core peak along a slow taper to 0 at the tip, with faint chirped interference beads "
     "(+-7 %) and faint side fringes; four thin secondary spikes at 45 deg (length 0.23-0.27, alpha 0.6); the faintest "
     "Airy ring (r 0.105, alpha 0.025). Reads on the day sky through Brightness 2.4 (white over cyan), glows at night."),
    ("te5_bokeh", "bokeh", "glow", "256x256", "None", None,
     "P6c big slow bokeh between camera and wearer (L7)",
     "Pass 6: an out-of-focus light, not a glass panel: a soft-edged disc (r 0.405, ~4 px edge) from a nine-blade iris "
     "(round, with the faintest polygon), interior alpha ~0.42 brightening toward a thin bright rim (~0.75, spherical "
     "aberration), faint aspheric onion rings, six soft specks of lens dust, a whisper of scatter outside the edge. "
     "RGB 0.94-1.0. Subtle by design (Transparency 0.6-0.72): drop it by day if it reads as a smudge in Studio."),
    ("te5_streak", "streak5", "spark", "256x256", "None", None,
     "Matter streaks with VelocityParallel: P9 funnel, P10a/b palm intake and P12 speed trail",
     "Pass 6: a comet of matter for VelocityParallel, the TOP leads (unchanged convention): a hot head 0.105 from the "
     "top (core r 0.021, glow, a tiny four-point glint), a tapering luminous tail to 0.94 (12 px wide at the head -> "
     "sub-pixel, alpha falling with distance; it fades in under the head) with a soft sheath and six fine filaments that peel off, wander and "
     "brighten and fade along it. No ink edge (it reads as light by day through Brightness 2.4; with the INK Color, P10b "
     "is a soft dark comet). If streaks fly tail-first in Studio, set STREAK_FLIP (or flip the PNG vertically)."),
    ("te5_ash", "ash5", "ash", "1024x1024", "Grid4x4", "Loop",
     "P8b ember flakes rising off the galaxy (was: black ash)",
     "Pass 6: LAYOUT CHANGED to a flipbook (Grid4x4, Loop): a glowing ember flake tumbling through one turn in 16 frames, "
     "drawn foreshortened as it turns (edge-on it shows its thin burning rim). Charred black body (RGB ~8-11) with a faint "
     "fibrous grain and a dull sheen; it burns from one side: there the torn edge is white-hot (a thin hot line, then a "
     "burn zone soaking inward), cooling round the flake to a nearly cold edge opposite; wavy fissures glow in from the "
     "edge. So at night it reads as a burning fragment, not a ring. >= 14 % padding (the flake spans 0.48-0.65 of its "
     "cell). Needs TEX5_LAYOUT ash5 = { Grid4x4, Loop } and a WHITE particle Color (the old ASH Color would turn the "
     "glow black), LightEmission 0, Brightness 1.6 by day (black char, a bright edge) and 3.2 at night (the edge "
     "passes the Bloom threshold, the smoulder shows). FlipbookFramerate 8-12, FlipbookStartRandom true; draw ~1.4x "
     "the old size."),
    ("te5_twinkle", "twinkle", "sparkles", "1024x1024", "Grid4x4", "OneShot",
     "NEW (pass 5.1's twinkle slot): a star that blooms, holds and shrinks out over its life: P15 star halo, P16 the "
     "duality helix's silver strand, P17 the dial's twinkles (and a drop-in for the glint5 systems)",
     "Flipbook 4x4 OneShot over the particle's life: the glint5 star (same core, halo, tapering diffraction spikes) "
     "blooming from a small point (an ease-out over frames 0-5), holding (6-9) while its spikes turn (~14 deg over the "
     "life), the H and V arms breathe in counterphase and the thin diagonals come in, then drawing back to a point "
     "(10-15, the mirror image). Energy per frame 0.15 -> 1 -> 0.15, the steps shrinking toward the hold (0.25, 0.21, "
     "0.17, 0.12, 0.08, 0.02), so even over the halo's 6-8 s life (~0.45 s a frame) it never pops; the first steps "
     "play while the emitter fades the particle in. Keep Size and Transparency steady "
     "(the twinkle is in the texture, not a transparency pulse); 1.6-3.4 s lifetimes look smoothest (5-10 frames a "
     "second). The fallback (kit sparkles, also 4x4) plays the same way."),
    ("te5_spark", "spark5", "spark", "256x256", "None", None,
     "NEW: hot metal sparks with a motion-blur tail (VelocityParallel, the TOP leads): where the shards break off the "
     "bezel, and the body's rising sparks",
     "A hot fleck (core r 0.013, glow, a tiny glint) 0.16 from the top with a long hairline tail to 0.94 (2.5 px at "
     "the head -> sub-pixel, on one pixel column, alpha falling as (1-s)^1.6) and a faint sheath. Thinner and hotter "
     "than the streak. Square 256 px (Roblox draws particles square)."),
    ("te5_stardust", "stardust", "sparkles", "1024x1024", "Grid4x4", "Loop",
     "NEW: a pinch of silver glitter (a third, finest scale of dust: in the air round the wearer, or trailing the moon)",
     "Flipbook 4x4 Loop: 30 sharp grains of three sizes (three are tiny four-point stars) in a loose cluster (r < 0.36). "
     "Every grain swells and fades once per loop on a smooth cosine (never off: 35-100 %) and drifts round a tiny "
     "circle, each at its own phase: a glitter with no blinks. FlipbookFramerate 6-10, FlipbookStartRandom true. "
     "Fallback: the kit 'sparkles' sheet (also 4x4)."),
]


def write_manifest():
    entries = []
    for name, key, fb, size, layout, mode, purpose, notes in MANIFEST:
        e = {"name": name, "file": name + ".png", "repoPath": f"{REPO_DIR}/{name}.png", "texKey": key,
             "fallbackTexKey": fb, "size": size, "layout": layout, "mode": mode}
        if mode:
            e["flipbookMode"] = mode
        e.update({"purpose": purpose, "notes": notes, "uploadedId": None})
        entries.append(e)
    with open(os.path.join(OUT, "manifest.json"), "w") as f:
        json.dump(entries, f, indent=1, ensure_ascii=False)
        f.write("\n")
    return entries


# ====================================================================================================================
# contact sheets: overview, flipbook frames, pixel zooms, GIFs, and IN-GAME previews (particles at their real on-screen
# size, composited the way tools/preview draws them: sRGB textures decoded to linear light, Roblox's particle blend
# out = src*a + dst*(1 - a*(1 - LightEmission)), the place's Bloom (threshold 2, Size 24) and the filmic tone curve)
# ====================================================================================================================

SHEET_ORDER = ["te5_glint", "te5_twinkle", "te5_mote", "te5_stardust", "te5_streak", "te5_spark", "te5_shards",
               "te5_ash", "te5_bokeh", "te5_smoke"]
GRIDS = {"te5_shards": 4, "te5_smoke": 4, "te5_twinkle": 4, "te5_ash": 4, "te5_stardust": 4}
LAYOUT_LABEL = {"te5_shards": "Grid4x4 Loop", "te5_smoke": "Grid4x4 OneShot", "te5_twinkle": "Grid4x4 OneShot",
                "te5_ash": "Grid4x4 Loop", "te5_stardust": "Grid4x4 Loop"}
GIF_FPS = {"te5_shards": 12, "te5_twinkle": 8, "te5_ash": 10, "te5_stardust": 8, "te5_smoke": 4}


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


def load(name, folder=None):
    return np.asarray(Image.open(os.path.join(folder or OUT, name + ".png")).convert("RGBA"), F32) / 255.0


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
    """A float RGB canvas (display values) for plain 'over' layouts of straight-alpha images."""

    def __init__(self, w, h, bg):
        self.rgb = np.ones((h, w, 3), F32) * (np.asarray(bg, F32) / 255.0)

    def put_plain(self, tex, x, y):
        h, w = tex.shape[:2]
        a = tex[..., 3:4]
        self.rgb[y:y + h, x:x + w] = tex[..., :3] * a + self.rgb[y:y + h, x:x + w] * (1.0 - a)

    def image(self):
        return Image.fromarray((np.clip(self.rgb, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")


def srgb_to_lin(c):
    c = np.asarray(c, F32)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4).astype(F32)


def lin_to_srgb(c):
    c = np.clip(np.asarray(c, F32), 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055).astype(F32)


def filmic(x):
    """The preview renderer's tone curve (the Narkowicz ACES fit, calibrated against Studio captures)."""
    x = np.maximum(x, 0)
    return np.clip((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0, 1)


def inv_filmic(y):
    y = np.clip(y, 0, 0.995)
    a = 2.51 - 2.43 * y
    b = 0.03 - 0.59 * y
    return ((-b + np.sqrt(b * b + 4 * a * 0.14 * y)) / (2 * a)).astype(F32)


def fft_blur(img, sigma):
    """Gaussian blur of an HxWxC image by FFT (zero padding 3 sigma): fast for the wide bloom kernels."""
    pad = int(math.ceil(3 * sigma))
    H, W = img.shape[:2]
    Hp, Wp = H + 2 * pad, W + 2 * pad
    fy = np.fft.fftfreq(Hp)[:, None]
    fx = np.fft.rfftfreq(Wp)[None, :]
    k = np.exp(-2 * (math.pi * sigma) ** 2 * (fx * fx + fy * fy))
    out = np.empty_like(img)
    for c in range(img.shape[2]):
        p = np.zeros((Hp, Wp), F32)
        p[pad:pad + H, pad:pad + W] = img[..., c]
        out[..., c] = np.fft.irfft2(np.fft.rfft2(p) * k, s=(Hp, Wp))[pad:pad + H, pad:pad + W]
    return out


class HDRComp:
    """Scene-linear canvas. bg: HxWx3 DISPLAY colours in [0, 1], pushed through the inverse tone curve (as the preview
    does with Studio's displayed sky). put() blends like Roblox: out = src*a + dst*(1 - a*(1 - LightEmission)), with
    src = texture (sRGB-decoded) * Color * Brightness."""

    def __init__(self, bg):
        self.lin = inv_filmic(srgb_to_lin(bg))

    def put(self, tex, cx, cy, size, color=(255, 255, 255), transp=0.0, le=0.0, br=1.0, rot=0.0, aspect=1.0):
        w = max(1, int(round(size)))
        h = max(1, int(round(size * aspect)))
        t = resize_premult(tex, w, h)
        if rot:
            pad = int(math.ceil(max(w, h) * 0.5))
            t = rotate_rgba(np.pad(t, ((pad, pad), (pad, pad), (0, 0))), rot)
        th, tw = t.shape[:2]
        x0 = int(round(cx - tw / 2))
        y0 = int(round(cy - th / 2))
        H, W = self.lin.shape[:2]
        xa, ya = max(0, x0), max(0, y0)
        xb, yb = min(W, x0 + tw), min(H, y0 + th)
        if xb <= xa or yb <= ya:
            return
        sub = t[ya - y0:yb - y0, xa - x0:xb - x0]
        a = sub[..., 3:4] * (1.0 - transp)
        src = srgb_to_lin(sub[..., :3]) * (srgb_to_lin(np.asarray(color, F32) / 255.0) * br)
        dst = self.lin[ya:yb, xa:xb]
        self.lin[ya:yb, xa:xb] = src * a + dst * (1.0 - a * (1.0 - le))

    def disc(self, cx, cy, r, rgb):
        H, W = self.lin.shape[:2]
        yy, xx = np.mgrid[0:H, 0:W]
        cov = np.clip(r + 0.5 - np.hypot(xx + 0.5 - cx, yy + 0.5 - cy), 0, 1)[..., None]
        self.lin = self.lin * (1 - cov) + inv_filmic(srgb_to_lin(np.asarray(rgb, F32) / 255.0)) * cov

    def image(self, bloom=True):
        lin = self.lin
        if bloom:
            m = lin.max(axis=2)
            ex = lin * (np.maximum(m - 2.0, 0) / np.maximum(m, 1e-4))[..., None]
            if (ex > 0).any():
                lin = lin + sum(w * fft_blur(ex, s) for s, w in ((2.5, 0.203), (8.0, 0.556), (22.0, 0.231), (58.0, 0.01)))
        return Image.fromarray((lin_to_srgb(filmic(lin)) * 255 + 0.5).astype(np.uint8), "RGB")


def sky_bg(w, h, seed, cloud=True):
    """Day backdrop: the cyan sky (#7ec8f0) with one soft white cloud bank (the hardest place for white particles)."""
    rgb = np.ones((h, w, 3), F32) * (np.asarray(BG_SKY, F32) / 255.0)
    if not cloud:
        return rgb
    nz = band_noise(256, seed, 2.0, 6.0)
    yy, xx = np.mgrid[0:h, 0:w].astype(F32)
    n = sample_wrap(nz, yy / h * 256 * 0.5, xx / w * 256)
    c = np.clip(0.5 + 0.35 * n - 1.4 * ((xx / w - 0.78) ** 2 + (yy / h - 0.25) ** 2) * 3.0, 0, 1)
    c = sstep(0.25, 0.75, c)[..., None]
    return rgb * (1 - 0.85 * c) + np.asarray([0.93, 0.95, 0.97], F32) * 0.85 * c


def dark_bg(w, h):
    return np.ones((h, w, 3), F32) * (np.asarray(BG_DARK, F32) / 255.0)


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
            ox, oy = cx + (tile - tw) // 2, cy + (tile - th) // 2
            cp.put_plain(resize_premult(img, tw, th), ox, oy)
            g = GRIDS.get(nm)
            if g:
                for j in range(1, g):
                    cp.rgb[oy:oy + th, ox + j * tw // g] = cp.rgb[oy:oy + th, ox + j * tw // g] * 0.6 + 0.2
                    cp.rgb[oy + j * th // g, ox:ox + tw] = cp.rgb[oy + j * th // g, ox:ox + tw] * 0.6 + 0.2
            labels.append((f"{nm}  {w}x{h}  {LAYOUT_LABEL.get(nm, '')}", (cx, cy - 20)))
        out = cp.image()
        for t, xy in labels:
            label(out, t, xy)
        p_ = os.path.join(SHEETS, f"overview_{bgname}.png")
        out.save(p_)
        paths.append(p_)
    return paths


def sheet_frames():
    """Every flipbook frame: shards and ember 1:1 (central 176 px of each 256 px cell), twinkle, stardust and smoke 1:2."""
    paths = []
    books = [("te5_shards", "te5_shards: 16 frames of one tumble (22.5 deg each), Loop, 1:1 (central 176 px of each cell)", 1.0, 40),
             ("te5_ash", "te5_ash (ember flake): 16 frames of one tumble, Loop, 1:1 (central 176 px of each cell)", 1.0, 40),
             ("te5_twinkle", "te5_twinkle: 16 frames, OneShot over the particle's life, 1:2", 0.5, 0),
             ("te5_stardust", "te5_stardust: 16 frames, Loop (every grain swells and fades once), 1:2", 0.5, 0),
             ("te5_smoke", "te5_smoke: 16 frames OneShot, 1:2 (unchanged)", 0.5, 0)]
    for bgname, bg in (("dark", BG_DARK), ("sky", BG_SKY)):
        blocks, texts = [], []
        y = 8
        W = 8 * 184 + 8
        for nm, title, sc, crop in books:
            img = load(nm)
            cs = int((256 - 2 * crop) * sc)
            texts.append((title, (8, y)))
            y += 22
            for k in range(16):
                c = cell_of(img, 4, k)
                if crop:
                    c = c[crop:256 - crop, crop:256 - crop]
                if sc != 1.0:
                    c = resize_premult(c, cs, cs)
                x = 8 + (k % 8) * (cs + 8)
                yy = y + (k // 8) * (cs + 8)
                blocks.append((c, x, yy, cs))
                texts.append((str(k), (x + 3, yy + 2)))
            y += 2 * (cs + 8) + 6
        cp = Comp(W, y, (30, 31, 36))
        for c, x, yy, cs in blocks:
            cp.rgb[yy:yy + cs, x:x + cs] = np.asarray(bg, F32) / 255.0
            cp.put_plain(c, x, yy)
        out = cp.image()
        for t, xy in texts:
            label(out, t, xy, 13)
        p_ = os.path.join(SHEETS, f"frames_{bgname}.png")
        out.save(p_)
        paths.append(p_)
    return paths


def sheet_zoom():
    """The pixels themselves (nearest-neighbour zoom): cores, spikes, edges, AA, no fringes."""
    crops = [("te5_glint", (96, 96, 176, 160), 4), ("te5_mote", (32, 32, 96, 96), 4), ("te5_streak", (96, 0, 160, 72), 4),
             ("te5_streak", (100, 150, 156, 250), 3), ("te5_spark", (104, 20, 152, 84), 4),
             ("te5_shards", (60, 50, 200, 210), 2), ("te5_ash", (40, 40, 216, 216), 2),
             ("te5_twinkle", (256 * 2 + 72, 72, 256 * 2 + 184, 184), 3), ("te5_stardust", (60, 60, 196, 196), 3),
             ("te5_bokeh", (0, 60, 110, 170), 3), ("te5_smoke", (256, 0, 512, 256), 2)]
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
        x = y = rowh = 0
        placed = []
        for t in tiles:
            if x + t.width > W:
                x, y, rowh = 0, y + rowh + 8, 0
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


def sheet_gifs():
    """An animated GIF of every flipbook at its suggested frame rate: dark and sky at 192 px, then at an in-game 64 px."""
    paths = []
    for nm, fps in GIF_FPS.items():
        img = load(nm)
        frames = []
        for k in range(16):
            c = cell_of(img, 4, k)
            cp = Comp(4 * 200 + 8, 200, (30, 31, 36))
            for i, (bg, sz) in enumerate(((BG_DARK, 192), (BG_SKY, 192), (BG_DARK, 64), (BG_SKY, 64))):
                x = 4 + i * 200
                cp.rgb[4:196, x:x + 192] = np.asarray(bg, F32) / 255.0
                t = resize_premult(c, sz, sz)
                cp.put_plain(t, x + (192 - sz) // 2, 4 + (192 - sz) // 2)
            frames.append(cp.image().convert("P", palette=Image.ADAPTIVE, colors=255))
        p_ = os.path.join(SHEETS, f"gif_{nm}.gif")
        frames[0].save(p_, save_all=True, append_images=frames[1:], duration=int(round(1000 / fps)), loop=0,
                       optimize=False, disposal=1)
        paths.append(p_)
    return paths


# THE END's particle colours (the module's constants)
WHITE, SILVER_P, INK, SMOKE, MIST, ASH = (248, 249, 255), (214, 218, 226), (5, 5, 8), (14, 14, 19), (205, 209, 220), (16, 16, 20)
WHITE_LE, WHITE_BR = (0.3, 0.9), (2.4, 3.0)
ASH_LE, ASH_BR = (0.0, 0.0), (1.6, 3.2)        # the ember: black char by day, a smouldering flake by night


def _sys(night, le, br):
    return (le[1] if night else le[0]), (br[1] if night else br[0])


def _life_size(f, peak, rise=0.3):
    """The glint systems' Size curve [0, 0] [rise, peak] [1 - rise, peak] [1, 0] at life fraction f."""
    if f < rise:
        return peak * f / rise
    if f > 1 - rise:
        return peak * (1 - f) / rise
    return peak


def ingame_panel(kind, night, w, h, seed, pps=26.0, folder=None):
    """One panel of simulated particles at their real on-screen size (pps px per stud ~ a camera 25 studs away at FOV
    70 on a 913 px tall view), with the module's Color / LightEmission / Brightness / Transparency by day or night."""
    rng = np.random.default_rng(seed)
    c = HDRComp(dark_bg(w, h) if night else sky_bg(w, h, seed))
    L = lambda nm: load(nm, folder)
    texts = []
    if kind == "glints":
        gl = L("te5_glint")
        le, br = _sys(night, (0.5, 1.0), WHITE_BR)
        for _ in range(16):                                        # P13 time dust 1.7 studs, P6a air 1.1, P6b 0.7
            peak = rng.choice([1.7, 1.1, 1.1, 0.7])
            sz = _life_size(rng.uniform(0.05, 0.95), peak) * pps
            c.put(gl, rng.uniform(15, w - 15), rng.uniform(15, h - 15), sz, WHITE, 0.1, le, br, rot=rng.uniform(0, 90))
        texts.append("glint5: time dust 1.7 / air 1.1 / 0.7 studs (size grows, holds, shrinks)")
    elif kind == "twinkle":
        tw = L("te5_twinkle")
        le, br = _sys(night, (0.5, 1.0), WHITE_BR)
        for _ in range(18):
            k = int(rng.integers(0, 16))
            c.put(cell_of(tw, 4, k), rng.uniform(15, w - 15), rng.uniform(15, h - 15), rng.choice([1.7, 1.3, 1.1]) * pps,
                  WHITE, 0.05, le, br, rot=rng.uniform(0, 90))
        texts.append("NEW twinkle: 1.0-1.7 studs, steady size, random life phase")
    elif kind == "motes":
        mo = L("te5_mote")
        cx, cy = w * 0.36, h * 0.52
        c.disc(cx, cy, 2.6 * pps, (0, 0, 0))                       # the void's black core
        le, br = _sys(night, WHITE_LE, WHITE_BR)
        for i in range(30):                                        # P1: matter spiralling in, 1.5 -> 0.35 studs
            f = rng.uniform(0, 1)
            ang = rng.uniform(0, 2 * math.pi)
            rr = (6.3 - 5.0 * f) * pps * 0.62
            sz = (1.5 - 1.15 * f) * pps
            g = 1 - 0.32 * f
            col = (int(248 * g + 170 * (1 - g)), int(249 * g + 174 * (1 - g)), int(255 * g + 184 * (1 - g)))
            c.put(mo, cx + rr * math.cos(ang), cy + rr * math.sin(ang) * 0.45, sz, col, 0.05, le, br)
        le, br = _sys(night, (0.2, 0.7), (1.4, 2.2))
        for _ in range(14):                                        # P2 moon dust, 0.18-0.6 studs
            c.put(mo, rng.uniform(w * 0.70, w - 10), rng.uniform(10, h - 10), rng.uniform(0.18, 0.6) * pps,
                  (238, 240, 246), 0.1, le, br)
        texts.append("mote: P1 void swirl 1.5->0.35 studs, P2 moon dust 0.2-0.6")
    elif kind == "streaks":
        st = L("te5_streak")
        le, br = _sys(night, WHITE_LE, WHITE_BR)
        cx, cy = w * 0.30, h * 0.5
        for i in range(22):                                        # P9 funnel: 0.92 -> 0.22 studs (x2.2), spiralling in
            ang = i / 22 * 2 * math.pi
            rr = 34 + (i % 5) * 10
            sz = rng.uniform(0.3, 0.92) * pps
            c.put(st, cx + rr * math.cos(ang), cy + rr * math.sin(ang) * 0.5, sz, WHITE, 0.05, le, br,
                  rot=-math.degrees(ang + math.pi / 2 + 0.5) + 90)
        cx2 = w * 0.76
        for i in range(16):                                        # P10b ink intake converging on the palm
            ang = rng.uniform(0, 2 * math.pi)
            rr = rng.uniform(12, 46)
            c.put(st, cx2 + rr * math.cos(ang), cy + rr * math.sin(ang), rng.uniform(0.25, 0.6) * pps, INK, 0.05, 0.0, 1.0,
                  rot=-math.degrees(ang + math.pi) + 90)
        texts.append("streak5: P9 funnel (white) / P10b palm intake (ink), VelocityParallel")
    elif kind == "sparks":
        sp = L("te5_spark")
        le, br = _sys(night, (0.5, 1.0), WHITE_BR)
        ox, oy = w * 0.25, h * 0.35
        for i in range(26):                                        # a spray where a shard breaks off, falling
            ang = rng.uniform(-0.9, 0.5)
            spd = rng.uniform(0.3, 1.0)
            x = ox + math.cos(ang) * spd * w * 0.6
            y = oy + math.sin(ang) * spd * h * 0.5 + spd * spd * h * 0.25
            vx, vy = math.cos(ang), math.sin(ang) + 0.9 * spd
            c.put(sp, x, y, rng.uniform(0.4, 0.8) * pps, WHITE, 0.05, le, br, rot=-math.degrees(math.atan2(vy, vx)) - 90)
        texts.append("NEW spark5: a spray of hot sparks 0.4-0.8 studs, VelocityParallel")
    elif kind == "shards":
        sh = L("te5_shards")
        le, br = _sys(night, (0.0, 0.3), (1.0, 1.6))
        for i in range(14):
            u = i / 13.0
            x = 30 + u * (w - 60)
            y = h * 0.62 - math.sin(u * 2.4) * h * 0.35 + rng.normal(0, 8)
            sz = (0.6 + 0.3 * min(1.0, u / 0.85)) * 1.6 * pps * (1.3 if i % 4 == 0 else 1.0)
            c.put(cell_of(sh, 4, int(rng.integers(0, 16))), x, y, sz, SILVER_P, 0.0, le, br, rot=rng.uniform(0, 360))
        texts.append("shards5: a stream, 0.6-0.9 studs x1.6 (tumbling flipbook)")
    elif kind == "ash":
        ah = L("te5_ash")
        le, br = _sys(night, ASH_LE, ASH_BR)
        for _ in range(24):
            c.put(cell_of(ah, 4, int(rng.integers(0, 16))), rng.uniform(10, w - 10), rng.uniform(10, h - 10),
                  rng.uniform(0.4, 0.6) * 1.4 * pps, WHITE, 0.05, le, br, rot=rng.uniform(0, 360))
        texts.append("ash5 ember flakes: 0.56-0.84 studs, WHITE, LE 0, Br 1.6 day / 3.2 night")
    elif kind == "stardust":
        sd_ = L("te5_stardust")
        le, br = _sys(night, (0.4, 1.0), WHITE_BR)
        for _ in range(9):
            c.put(cell_of(sd_, 4, int(rng.integers(0, 16))), rng.uniform(30, w - 30), rng.uniform(30, h - 30),
                  rng.uniform(1.8, 2.8) * pps, WHITE, 0.15, le, br, rot=rng.uniform(0, 360))
        texts.append("NEW stardust: glitter clusters 1.8-2.8 studs")
    elif kind == "bokeh":
        bk = L("te5_bokeh")
        le, br = _sys(night, (0.3, 0.8), (1.2, 1.8))
        n_alive = 4 if night else 3
        xs_ = np.linspace(0.15, 0.85, n_alive) * w + rng.normal(0, 25, n_alive)
        for i in range(n_alive):                                    # 5-8 studs from the camera: ~70 px per stud
            c.put(bk, xs_[i], rng.uniform(70, h - 70), rng.uniform(1.2, 2.4) * 70, (232, 236, 246), 0.72, le, br,
                  rot=rng.uniform(0, 360))
        texts.append("bokeh: 1.2-2.4 studs close to the camera, Transparency 0.72")
    elif kind in ("smoke_dark", "smoke_silver"):
        sm = L("te5_smoke")
        if kind == "smoke_dark":
            col, tr, le, br = SMOKE, 0.30, 0.0, 1.0
            texts.append("smoke5 (unchanged): P4a dark smoke, LE 0")
        else:
            col, tr = (176, 176, 178), 0.45
            le, br = _sys(night, (0.1, 0.4), (1.0, 1.0))
            texts.append("smoke5 (unchanged): P4b silver smoke")
        for i in range(12):
            life = i / 11.0
            k = min(15, int(life * 16))
            sz = (3.0 + 4.5 * life) * 32 * 0.55
            ttr = tr + (0.15 * max(0.0, (life - 0.2) / 0.5) if life < 0.7 else 0.15 + 0.85 * (life - 0.7) / 0.3 * 0.5)
            c.put(cell_of(sm, 4, k), w * 0.30 + life * w * 0.45 + rng.normal(0, 10), h * 0.80 - life * h * 0.55 + rng.normal(0, 8),
                  sz, col, min(0.95, ttr), le, br, rot=rng.uniform(0, 360))
    return c.image(), texts


INGAME_KINDS = ["glints", "twinkle", "motes", "stardust", "streaks", "sparks", "shards", "ash", "bokeh", "smoke_dark",
                "smoke_silver"]


def sheet_ingame():
    pw, ph, cols = 420, 260, 4
    rows = math.ceil(len(INGAME_KINDS) / cols)
    paths = []
    for night in (False, True):
        out = Image.new("RGB", (cols * (pw + 8) + 8, rows * (ph + 8) + 8 + 24), (30, 31, 36))
        label(out, ("NIGHT (dark sky, night LightEmission/Brightness)" if night else
                    "DAY (cyan sky + cloud, day LightEmission/Brightness)") + "  - particles at their in-game size, "
              "linear light + Bloom (threshold 2) + the preview's filmic curve", (8, 5), 14)
        for i, kd in enumerate(INGAME_KINDS):
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
    """Each texture at the pixel sizes it covers on screen (mip-filtered), day over the sky vs night, through the
    linear-light compositor with the module's colours."""
    sets = [("te5_glint", [10, 16, 24, 36, 56, 80], WHITE, (0.5, 1.0), WHITE_BR),
            ("te5_twinkle", [16, 24, 36, 56, 80], WHITE, (0.5, 1.0), WHITE_BR),
            ("te5_mote", [4, 6, 10, 16, 24, 40], WHITE, WHITE_LE, WHITE_BR),
            ("te5_stardust", [32, 48, 64, 96], WHITE, (0.4, 1.0), WHITE_BR),
            ("te5_streak", [10, 16, 24, 36, 56], WHITE, WHITE_LE, WHITE_BR),
            ("te5_spark", [10, 16, 24, 36, 56], WHITE, (0.5, 1.0), WHITE_BR),
            ("te5_shards", [16, 24, 32, 44, 60], SILVER_P, (0.0, 0.3), (1.0, 1.6)),
            ("te5_ash", [12, 16, 22, 30, 44], WHITE, ASH_LE, ASH_BR)]
    rowh, W = 96, 1180
    out = Image.new("RGB", (W, len(sets) * rowh * 2 + 10), (30, 31, 36))
    for night in (False, True):
        for i, (nm, sizes, col, le, br) in enumerate(sets):
            y = (i * 2 + (1 if night else 0)) * rowh + 5
            c = HDRComp(dark_bg(W - 150, rowh - 4) if night else sky_bg(W - 150, rowh - 4, 1, cloud=False))
            img = load(nm)
            x = 20
            for sz in sizes:
                for k in range(3):
                    tex = cell_of(img, 4, (k * 5 + 2) % 16) if nm in GRIDS else img
                    c.put(tex, x + sz / 2, (rowh - 4) / 2, sz, col, 0.05, le[night], br[night], rot=[0, 35, 70][k])
                    x += sz + 10
                x += 14
            out.paste(c.image(), (150, y))
            label(out, f"{nm} {'night' if night else 'day'}", (6, y + 36), 12)
    p_ = os.path.join(SHEETS, "sizes.png")
    out.save(p_)
    return [p_]


BEFORE_AFTER = [("te5_glint", None, WHITE, (0.5, 1.0), WHITE_BR, 44), ("te5_mote", None, WHITE, WHITE_LE, WHITE_BR, 30),
                ("te5_streak", None, WHITE, WHITE_LE, WHITE_BR, 56), ("te5_shards", 4, SILVER_P, (0.0, 0.3), (1.0, 1.6), 48),
                ("te5_ash", 4, WHITE, ASH_LE, ASH_BR, 34), ("te5_bokeh", None, (232, 236, 246), (0.3, 0.8), (1.2, 1.8), 120)]


def sheet_before_after(before):
    """Old (left) vs new (right) for every texture that existed before: the raw texture on dark and sky, then in game
    by day and night at a typical on-screen size. The old ash is drawn the way pass 5 drew it (ASH colour, no glow)."""
    if not before or not os.path.isdir(before):
        return []
    rowh = 150
    W = 2 * (2 * 132 + 2 * 250) + 30
    out = Image.new("RGB", (W, len(BEFORE_AFTER) * (rowh + 6) + 30), (30, 31, 36))
    label(out, "BEFORE (pass 5)  |  AFTER (pass 6):  texture on dark, on sky;  in game by day, by night", (8, 6), 14)
    for i, (nm, g, col, le, br, size) in enumerate(BEFORE_AFTER):
        y = 30 + i * (rowh + 6)
        for j, folder in enumerate((before, OUT)):
            if not os.path.exists(os.path.join(folder, nm + ".png")):
                continue
            img = load(nm, folder)
            gg = g if img.shape[0] == 1024 and g else None
            x0 = 10 + j * (2 * 132 + 2 * 250 + 10)
            for t, bg in enumerate((BG_DARK, BG_SKY)):
                cp = Comp(128, 128, bg)
                tex = cell_of(img, gg, 2) if gg else img
                cp.put_plain(resize_premult(tex, 128, 128), 0, 0)
                out.paste(cp.image(), (x0 + t * 132, y + 10))
            for t, night in enumerate((False, True)):
                rng = np.random.default_rng(7 + i)
                c = HDRComp(dark_bg(246, rowh - 10) if night else sky_bg(246, rowh - 10, 3, cloud=False))
                ccol, lle, bbr = col, le[night], br[night]
                if nm == "te5_ash" and folder == before:
                    ccol, lle, bbr = ASH, 0.0, 1.0
                n_ = 1 if nm == "te5_bokeh" else 5
                for k in range(n_):
                    tex = cell_of(img, gg, int(rng.integers(0, 16))) if gg else img
                    sz = size * (1.0 if n_ == 1 else rng.uniform(0.7, 1.15))
                    c.put(tex, 30 + (k + 0.5) * (186 / n_), (rowh - 10) / 2 + rng.normal(0, 12), sz, ccol,
                          0.72 if nm == "te5_bokeh" else 0.05, lle, bbr, rot=rng.uniform(0, 360) if nm != "te5_streak" else 30)
                out.paste(c.image(), (x0 + 2 * 132 + t * 250, y + 5))
            label(out, ("before " if folder == before else "after ") + nm, (x0 + 2, y + 140 - 2), 11)
    p_ = os.path.join(SHEETS, "before_after.png")
    out.save(p_)
    return [p_]


def make_sheets(before=None):
    os.makedirs(SHEETS, exist_ok=True)
    paths = []
    for fn in (sheet_overview, sheet_frames, sheet_zoom, sheet_gifs, sheet_ingame, sheet_sizes):
        t0 = time.time()
        paths += fn()
        print(f"sheet {fn.__name__}: {time.time() - t0:.1f}s")
    paths += sheet_before_after(before)
    return paths


# ====================================================================================================================
# numerical self-tests on the written PNGs (--check)
# ====================================================================================================================

SIZES = {"te5_shards": (1024, 1024), "te5_smoke": (1024, 1024), "te5_mote": (128, 128), "te5_glint": (256, 256),
         "te5_bokeh": (256, 256), "te5_streak": (256, 256), "te5_ash": (1024, 1024), "te5_twinkle": (1024, 1024),
         "te5_spark": (256, 256), "te5_stardust": (1024, 1024)}


def _radial(img, ch, r0, r1, n, cell=None):
    """Mean of channel ch over the annulus r0..r1 (cell units, r 0.5 = cell edge)."""
    h, w = img.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    rr = np.hypot(xx + 0.5 - w / 2, yy + 0.5 - h / 2) / w
    m = (rr >= r0) & (rr < r1)
    return float(img[..., ch][m].mean())


def _rr(n):
    yy, xx = np.mgrid[0:n, 0:n]
    return np.hypot(xx + 0.5 - n / 2, yy + 0.5 - n / 2) / n, xx, yy


def _near_edge(A, dist=4):
    """Visible pixels within 'dist' px of a pixel with alpha < 0.5 (the silhouette's rim band)."""
    lo = A < 0.5
    acc = lo.copy()
    for _ in range(dist):
        p = np.pad(acc, 1)
        acc = acc | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    return acc & ~lo


def _peaks(a, thr):
    """Count of strict local maxima above thr in a 2D array (3x3 neighbourhood)."""
    p = np.pad(a, 1, constant_values=-1)
    c = p[1:-1, 1:-1]
    m = c > thr
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dy or dx:
                m &= c >= p[1 + dy:p.shape[0] - 1 + dy, 1 + dx:p.shape[1] - 1 + dx]
    return int(m.sum())


def check():
    fails = []

    def ok(cond, msg):
        print(("  ok   " if cond else "  FAIL ") + msg)
        if not cond:
            fails.append(msg)

    imgs = {}
    for nm, (w, h) in SIZES.items():
        im = Image.open(os.path.join(OUT, nm + ".png"))
        a = np.asarray(im.convert("RGBA")).astype(np.int32)
        imgs[nm] = a
        ok(im.mode == "RGBA" and im.size == (w, h), f"{nm}: RGBA {w}x{h}")
        if nm in GRIDS:
            ok(im.size == (1024, 1024), f"{nm}: a flipbook is exactly 1024x1024 (Roblox refuses any other size)")
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
    F = {k: v.astype(F32) / 255.0 for k, v in imgs.items()}
    rr256, xx256, yy256 = _rr(256)

    # --- glint: a photographic star
    a = F["te5_glint"]
    A = a[..., 3]
    ok(A[128, 128] > 0.99 and _radial(a, 3, 0.0, 0.012, 256) > 0.99, "te5_glint: hot core alpha 1")
    ok(bool((a[..., 0][A > 0.004] > 0.97).all()), "te5_glint: pure light (RGB white wherever visible: no ink)")
    h_arm = [float(A[127:129, 128 + int(f * 256)].mean()) for f in (0.05, 0.15, 0.30, 0.42)]
    ok(all(h_arm[i] > h_arm[i + 1] for i in range(3)) and h_arm[3] > 0.0 and A[127:129, 128 + 120:].max() == 0,
       "te5_glint: main spike fades along its length (" + " ".join(f"{v:.2f}" for v in h_arm) + ") and ends before the edge")
    def fwhm(col):
        return int((col > 0.5 * col.max()).sum())
    wid = [fwhm(A[100:156, 128 + int(f * 256)]) for f in (0.06, 0.30)]
    ok(wid[0] > wid[1] >= 1, f"te5_glint: spikes taper (half-max width {wid[0]} px near the core, {wid[1]} px at 0.30)")
    o10 = int(round(0.10 * 256 / math.sqrt(2)))
    d10 = float(A[128 - o10, 128 + o10 - 1:128 + o10 + 1].max())
    m10 = float(A[127:129, 128 + int(0.10 * 256)].mean())
    ok(0.05 < d10 < m10, f"te5_glint: thinner, fainter 45 deg spikes ({d10:.2f} vs the main spikes' {m10:.2f} at r .1)")
    th = np.degrees(np.arctan2(yy256 + 0.5 - 128, xx256 + 0.5 - 128)) % 45
    between = (th > 17) & (th < 28)
    prof = [float(A[between & (rr256 >= r0) & (rr256 < r0 + 0.01)].mean()) for r0 in (0.03, 0.06, 0.12, 0.25)]
    ok(prof[0] > prof[1] > prof[2] >= prof[3] and prof[0] > 0.2 and prof[3] < 0.01,
       "te5_glint: soft halo between the spikes falls off (" + " ".join(f"{v:.3f}" for v in prof) + ")")
    ripple = np.diff(A[127:129, 128 + 20:128 + 100].mean(axis=0))
    ok(int((np.sign(ripple[:-1]) != np.sign(ripple[1:])).sum()) >= 2,
       "te5_glint: faint interference beads along the main spikes")

    # --- twinkle: blooms from a point, holds while turning, draws back
    a = F["te5_twinkle"]
    en = [float(cell_of(a, 4, k)[..., 3].sum()) for k in range(16)]
    pk = max(en)
    ok(en[0] < 0.25 * pk and en[15] < 0.25 * pk, f"te5_twinkle: starts and ends as a point (energy {en[0] / pk:.2f} / "
                                                   f"{en[15] / pk:.2f} of the peak)")
    ok(all(en[k] < en[k + 1] for k in range(5)) and all(en[k] > en[k + 1] for k in range(11, 15)),
       "te5_twinkle: energy rises over frames 0-5 and falls over 11-15")
    ok(max(en[5:11]) / min(en[5:11]) < 1.15, f"te5_twinkle: holds over frames 5-10 (+-{(max(en[5:11]) / min(en[5:11]) - 1) * 100:.0f} %)")
    steps = [abs(en[k + 1] - en[k]) / pk for k in range(15)]
    ok(max(steps) < 0.40, f"te5_twinkle: no jump between frames (max energy step {max(steps):.2f} of the peak)")

    def arm_len(c):
        row = c[127:129, 128:, 3].mean(axis=0)
        nz_ = np.nonzero(row > 0.1)[0]
        return int(nz_.max()) if nz_.size else 0
    lens = [arm_len(cell_of(a, 4, k)) for k in range(16)]
    ok(lens[0] < lens[2] < lens[4] <= lens[7] + 2 and lens[15] < lens[11],
       "te5_twinkle: spikes grow out and draw back (" + " ".join(str(v) for v in lens) + " px)")

    def arm_angle(c):
        A_ = c[..., 3]
        ring = (rr256 > 0.20) & (rr256 < 0.30)
        ang = np.arctan2(-(yy256 + 0.5 - 128), xx256 + 0.5 - 128)
        wgt = A_ * ring
        return math.degrees(math.atan2((wgt * np.sin(4 * ang)).sum(), (wgt * np.cos(4 * ang)).sum()) / 4)
    turn = arm_angle(cell_of(a, 4, 11)) - arm_angle(cell_of(a, 4, 4))
    ok(4.0 < turn < 12.0, f"te5_twinkle: the spikes turn while it holds ({turn:.1f} deg from frame 4 to 11)")

    # --- mote: core + halo, no dark ring
    a = F["te5_mote"]
    ok(_radial(a, 3, 0.0, 0.03, 128) > 0.99, f"te5_mote: hot core alpha {_radial(a, 3, 0.0, 0.03, 128):.3f}")
    ok(bool((a[..., 0][a[..., 3] > 0.004] > 0.97).all()), "te5_mote: no dark ring (RGB white wherever visible)")
    prof = [_radial(a, 3, r0, r0 + 0.02, 128) for r0 in np.arange(0.0, 0.46, 0.02)]
    ok(all(prof[i] >= prof[i + 1] - 0.004 for i in range(len(prof) - 1)), "te5_mote: alpha falls off monotonically")
    ok(_radial(a, 3, 0.47, 0.5, 128) == 0.0 and 0.05 < _radial(a, 3, 0.10, 0.12, 128) < 0.5,
       f"te5_mote: soft halo ({_radial(a, 3, 0.10, 0.12, 128):.2f} at r .11), 0 beyond r .47")

    # --- bokeh: an out-of-focus disc
    a = F["te5_bokeh"]
    A = a[..., 3]
    inter = _radial(a, 3, 0.02, 0.25, 256)
    rim = max(_radial(a, 3, r0, r0 + 0.01, 256) for r0 in np.arange(0.33, 0.41, 0.01))
    ok(0.36 <= inter <= 0.52, f"te5_bokeh: interior alpha {inter:.2f}")
    ok(rim > inter + 0.15, f"te5_bokeh: brighter rim (alpha {rim:.2f} vs {inter:.2f} inside)")
    ok(_radial(a, 3, 0.47, 0.5, 256) == 0.0, "te5_bokeh: alpha 0 outside the aperture")
    rowA = A[128, 128:]
    i90 = int(np.nonzero(rowA > 0.9 * rowA[95:105].max())[0].max())
    i10 = int(np.nonzero(rowA > 0.1 * rowA[95:105].max())[0].max())
    ok(i10 - i90 >= 2, f"te5_bokeh: a soft (out-of-focus) edge ({i10 - i90} px from 90 % to 10 %)")
    ok(bool((a[..., 0][A > 0.004] > 0.9).all()), "te5_bokeh: white light (RGB >= 0.9)")

    # --- streak: a comet, head at the TOP
    a = F["te5_streak"]
    A = a[..., 3]
    rows = A.sum(axis=1)
    ok(int(np.argmax(rows)) < int(0.2 * 256), f"te5_streak: the head leads at the top (row {int(np.argmax(rows))})")
    cen = A[:, 126:130].max(axis=1)
    ok(cen[int(0.10 * 256)] > 0.99 and cen[int(0.3 * 256)] > cen[int(0.6 * 256)] > cen[int(0.85 * 256)] > 0
       and cen[int(0.97 * 256):].max() == 0, f"te5_streak: the tail fades from the head ({cen[int(0.3 * 256)]:.2f} / "
       f"{cen[int(0.6 * 256)]:.2f} / {cen[int(0.85 * 256)]:.2f}) and ends by y 0.97")
    w30, w75 = int((A[int(0.3 * 256)] > 0.1).sum()), int((A[int(0.75 * 256)] > 0.1).sum())
    ok(w30 > w75, f"te5_streak: the tail tapers ({w30} px at y .3, {w75} px at y .75)")
    rowf = A[int(0.62 * 256), 100:156]
    ok(_peaks(rowf[None, :], 0.03) >= 2, f"te5_streak: fine filaments in the tail ({_peaks(rowf[None, :], 0.03)} peaks "
                                          "across y .62)")
    gl = int((A[int(0.10 * 256)] > 0.1).sum())
    ok(gl > 1.3 * w30, f"te5_streak: a glint on the head ({gl} px wide vs the tail's {w30})")
    ok(A[:int(0.03 * 256)].max() == 0 and A[int(0.97 * 256):].max() == 0, "te5_streak: within y 0.03-0.97")

    # --- spark: a hot fleck with a hairline tail
    a = F["te5_spark"]
    A = a[..., 3]
    ok(int(np.argmax(A.sum(axis=1))) < int(0.25 * 256), "te5_spark: the hot head leads at the top")
    row = A[int(0.5 * 256)]
    fw = int((row > 0.5 * row.max()).sum())
    srow = F["te5_streak"][int(0.5 * 256), :, 3]
    ok(fw <= 3 and row.max() > 0.1, f"te5_spark: a hairline tail (half-max width {fw} px at mid-length)")
    ok(fw < int((srow > 0.5 * srow.max()).sum()) and row.sum() < 0.6 * srow.sum(), "te5_spark: thinner than the streak")

    # --- shards: a real render
    a = imgs["te5_shards"]
    pad_ok, body_ok, areas, meanL, energy, hiL, loL, glint_fr = True, True, [], [], [], [], [], 0
    for k in range(16):
        c = cell_of(a, 4, k)
        A = c[..., 3]
        lim = int(round(0.20 * 256))
        ring = np.ones_like(A, bool)
        ring[lim:-lim, lim:-lim] = False
        pad_ok &= int(A[ring].max()) == 0
        areas.append(int((A > 127).sum()))
        body_ok &= int((A == 255).sum()) > 0.7 * int((A > 0).sum()) - 300
        Lb = c[..., 0][A == 255] / 255.0
        meanL.append(float(Lb.mean()))
        energy.append(float((c[..., 0] * A).sum()) / 255.0 / 255.0)
        hiL.append(float(np.percentile(Lb, 97)))
        loL.append(float(np.percentile(Lb, 5)))
        glint_fr += int((Lb > 0.85).sum() >= 3)
        sheen_fr = sheen_fr + int(np.percentile(Lb, 99) >= 0.70) if k else int(np.percentile(Lb, 99) >= 0.70)
    ok(pad_ok, "te5_shards: >= 20 % padding in all 16 cells")
    ok(body_ok, "te5_shards: opaque body (alpha 1 inside, AA only on the rim)")
    jumps = [abs(areas[(k + 1) % 16] - areas[k]) / max(areas) for k in range(16)]
    ok(max(jumps) < 0.35, f"te5_shards: one smooth tumble (max silhouette-area step {max(jumps):.2f}, incl. 15 -> 0)")
    ok(max(areas) / max(min(areas), 1) > 3, f"te5_shards: it really turns (area {min(areas)} -> {max(areas)} px)")
    esteps = [abs(energy[(k + 1) % 16] - energy[k]) / max(energy) for k in range(16)]
    ok(max(esteps) < 0.40, f"te5_shards: no flash frame (max brightness-energy step {max(esteps):.2f}, incl. 15 -> 0)")
    ok(min(loL) < 0.30 and max(hiL) > 0.85, f"te5_shards: polished metal has darks and highlights (p5 {min(loL):.2f}, "
                                            f"p97 {max(hiL):.2f})")
    ok(sheen_fr >= 14 and glint_fr >= 5, f"te5_shards: a bright sheen in {sheen_fr} of 16 frames, a hot glint in "
                                          f"{glint_fr} (it sweeps the faces as they turn to the key)")

    # --- ash: the ember flake
    a = imgs["te5_ash"]
    pad_ok, areas, dark_ok, rim_ok, glow_fr = True, [], True, True, 0
    for k in range(16):
        c = cell_of(a, 4, k).astype(F32) / 255.0
        A = c[..., 3]
        lim = int(round(0.12 * 256))
        ring = np.ones_like(A, bool)
        ring[lim:-lim, lim:-lim] = False
        pad_ok &= float(A[ring].max()) == 0.0
        areas.append(int((A > 0.5).sum()))
        L = c[..., 0]
        rimband = _near_edge(A, 4)
        deep = (A > 0.99) & ~_near_edge(A, 12)
        if deep.sum() > 2000:
            dark_ok &= float(np.median(L[deep])) < 0.15
        hot = (L > 0.85) & (A > 0.5)
        if hot.sum() > 0:
            glow_fr += 1
            rim_ok &= float((hot & rimband).sum()) / float(hot.sum()) > 0.6
    ok(pad_ok, "te5_ash: >= 12 % padding in all 16 cells")
    ok(dark_ok, "te5_ash: charred body (median L < 0.15 away from the burning edge, face-on frames)")
    ok(glow_fr >= 14 and rim_ok, f"te5_ash: white-hot glow in {glow_fr} of 16 frames, mostly along the burning edge")
    ok(max(areas) / max(min(areas), 1) > 3, f"te5_ash: foreshortened as it turns (area {min(areas)} -> {max(areas)} px)")
    jumps = [abs(areas[(k + 1) % 16] - areas[k]) / max(areas) for k in range(16)]
    ok(max(jumps) < 0.35, f"te5_ash: one smooth tumble (max area step {max(jumps):.2f}, incl. 15 -> 0)")

    # --- stardust: a glittering cluster that never blinks
    a = F["te5_stardust"]
    npk = [_peaks(cell_of(a, 4, k)[..., 3], 0.25) for k in range(16)]
    en = [float(cell_of(a, 4, k)[..., 3].sum()) for k in range(16)]
    st = [abs(en[(k + 1) % 16] - en[k]) / max(en) for k in range(16)]
    ok(min(npk) >= 18, f"te5_stardust: {min(npk)}-{max(npk)} grains per frame")
    ok(max(st) < 0.15, f"te5_stardust: gentle loop (max energy step {max(st):.2f}, incl. 15 -> 0)")
    ok(max(_radial(cell_of(a, 4, k), 3, 0.45, 0.5, 256) for k in range(16)) == 0.0, "te5_stardust: alpha 0 beyond r .45")

    # --- smoke (unchanged)
    a = imgs["te5_smoke"]
    means, inner, prev, steps = [], [], None, []
    win_ok, rgb_ok = True, True
    yy, xx = np.mgrid[0:256, 0:256]
    rr = np.hypot(xx + 0.5 - 128, yy + 0.5 - 128) / 256
    for k in range(16):
        c = cell_of(a, 4, k).astype(F32)
        A = c[..., 3] / 255
        means.append(float(A.mean()))
        inner.append(float(A[rr < 0.21].mean()))
        win_ok &= float(A[rr >= 0.46].max()) == 0.0
        L = c[..., 0][A > 0.08] / 255
        rgb_ok &= bool(L.min() >= 0.74 and L.max() <= 1.0)
        Al = A.reshape(32, 8, 32, 8).mean(axis=(1, 3))
        if prev is not None:
            steps.append(float(np.abs(Al - prev).mean()))
        prev = Al
    ok(all(m >= 0.30 for m in means[:12]), "te5_smoke: per-cell mean alpha >= 0.30 in frames 0-11 -> " +
       " ".join(f"{m:.2f}" for m in means[:12]))
    ok(all(v >= 0.85 for v in inner[:12]), "te5_smoke: alpha >= 0.85 over the inner half of the billow (r < 0.21) in "
       "frames 0-11 -> " + " ".join(f"{v:.2f}" for v in inner[:12]))
    ok(means[15] <= 0.5 * means[11], f"te5_smoke: it dissolves in frames 12-15 (mean alpha {means[11]:.2f} -> {means[15]:.2f})")
    ok(win_ok, "te5_smoke: alpha 0 beyond 0.46 of the cell in every frame")
    ok(rgb_ok, "te5_smoke: RGB 0.75-1.0 wherever the smoke is visible")
    ok(max(steps[:11]) < 0.035 and max(steps[11:]) < 0.10, f"te5_smoke: frames change gently (max large-scale mean |dA| "
       f"per frame {max(steps[:11]):.3f} in frames 0-11, {max(steps[11:]):.3f} in the dissolve)")
    # --- the manifest matches the PNGs
    man = json.load(open(os.path.join(OUT, "manifest.json")))
    by = {e["name"]: e for e in man}
    ok(set(by) == set(SIZES), "manifest: one entry per PNG")
    for nm, (w, h) in SIZES.items():
        e = by.get(nm, {})
        ok(e.get("size") == f"{w}x{h}" and (e.get("layout") == "Grid4x4") == (nm in GRIDS)
           and e.get("uploadedId", "x") is None and e.get("fallbackTexKey") and e.get("texKey"),
           f"manifest: {nm} size/layout/fallback/texKey recorded, uploadedId null")
    return fails


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--no-sheets", action="store_true")
    ap.add_argument("--before", default="", help="folder holding the previous PNGs: adds sheets/before_after.png")
    ap.add_argument("--check", action="store_true", help="only run the numerical self-tests on the PNGs")
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
        make_sheets(args.before or None)
    if not args.only:
        print("checks:")
        if check():
            sys.exit(1)


if __name__ == "__main__":
    main()
