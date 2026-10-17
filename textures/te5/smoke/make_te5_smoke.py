#!/usr/bin/env python3
# THE END (1 in 1,000,000,000) -- equipped aura, pass 5 "The Last Clock" -- texture group "smoke".
#
# Film-quality smoke for THE END's smoke emitters (roblox/ReplicatedStorage/AuraFX/TheEnd.lua: P4a void ink smoke,
# P4b moon silver smoke, P7 dais rim mist, P11 body wisps; all drawn with te5_smoke, key "smoke5", until now):
#   te5_billow    (1024^2, Grid4x4 OneShot)  one smoke puff over one particle life: born dense and compact, it billows
#                                            out in rolling cauliflower lobes, softens, shears into curling veils and
#                                            thins away (P4a / P4b)
#   te5_wisp      (1024^2, Grid4x4 OneShot)  thin curling smoke tendrils, like incense or cold breath: born as a faint
#                                            tuft, drawn up into curls, thinning away (P11; also the P16 ink strand)
#   te5_mistbank  (512^2, single image)      a soft, low, wide fog bank lit from above (P7)
#
# Only python3 + numpy + PIL. Deterministic: every random source is seeded (a re-run gives byte-identical PNGs on the
# same machine). About 2-3 minutes on 4 CPUs.
#
#   python3 make_te5_smoke.py               # all textures + manifest + contact sheets (sheets/) + checks
#   python3 make_te5_smoke.py --no-sheets   # textures + manifest + checks
#   python3 make_te5_smoke.py --only billow,wisp
#   python3 make_te5_smoke.py --check       # only the numeric self-tests on the PNGs
#   python3 make_te5_smoke.py --set billow.sigma=80 --out /tmp/try   # tuning: override parameters, write elsewhere
#
# How the smoke is made (real 3D volumes, lit and ray-marched; nothing is painted in 2D):
#   * Shape. A puff is modelled once, at birth, in its own "material" space: a sphere tree (a core, lobes on it,
#     sub-lobes on their outer sides, sub-sub-lobes on those) soft-unioned level by level (wide blends between the big
#     lobes, tight ones for the small billows) into a signed-distance volume. A wisp is seven thin twisted ribbons.
#   * Motion. A velocity field -- an expansion that slows down and swells more in some places than others, two scales of
#     divergence-free curl noise that strengthen with age, a slight rise -- is integrated backward from every frame's
#     time to birth (RK2, composed frame by frame on a 64^3 / 80^3 grid). Each frame looks its smoke up through that map,
#     so consecutive frames are the same smoke, moved on a little: no pops, no repeated frames.
#   * Density per frame: the shape's distance through a soft ramp (wide inside, so billows have soft cloudy edges),
#     fine billow detail and ramp noise in expansion-only coordinates (so the flow never shears it into brushed streaks),
#     and with age: wider ramps (diffusion), soft erosion, an exponential thinning, and density gathered into
#     curling veils (ridges of noise carried by the flow) as it dies.
#   * Light: an orthographic ray march (128 slices, front to back) with Beer-Lambert absorption. A key light from the
#     upper front left with a real shadow march toward it (its shadow front softened a little per slice, like a light of
#     some size), a multiple-scattering approximation (shadows lifted in octaves), a rim light from behind whose
#     transmittance makes thin edges glow (forward scattering), a soft sky term from above and a little ambient. Output:
#     luminance (baked lighting: Roblox draws particles unlit) and alpha = 1 - transmittance.
#   * Every frame is rendered at 2x (512 px per 256 px cell) and box-filtered down in PREMULTIPLIED alpha. One exposure
#     and one tone curve per texture (never per frame: the brightness must not jump between frames). Grey is bled into
#     the fully transparent pixels per cell (so mip-maps and bilinear filtering never pull a dark fringe in), alpha is
#     exactly 0 on every cell's border (>= 6 % padding), both channels get +-1 LSB triangular dither (no banding), and
#     every pixel is neutral grey (R = G = B): the emitter's Color tints it.
import argparse, json, math, os, sys, time
# one BLAS thread per process: frames render in parallel processes, nothing here needs threaded BLAS, and BLAS threads
# oversubscribing the CPUs made small matrix work ~40x slower in testing
for _v in ("OPENBLAS_NUM_THREADS", "OMP_NUM_THREADS", "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS", "NUMEXPR_NUM_THREADS"):
    os.environ.setdefault(_v, "1")
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_DIR = "textures/te5/smoke"
OLD_SMOKE = os.path.join(HERE, "..", "particles", "te5_smoke.png")
SS = 2                      # supersampling: render at 2x, box-filter down
CELL = 256                  # flipbook cell (Grid4x4 on a 1024^2 sheet)
F32 = np.float32
BG_DARK = (11, 12, 16)      # #0b0c10
BG_SKY = (126, 200, 240)    # #7ec8f0
OUT = HERE                  # (--out changes it)


# --------------------------------------------------------------------------------------------------------------------
# small helpers
# --------------------------------------------------------------------------------------------------------------------


def sstep(e0, e1, x):
    """smoothstep; works for e0 > e1 too (falling edge)."""
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def rot3(seed):
    """A random rotation matrix (deterministic): each noise lookup is turned differently, so no two line up."""
    rng = np.random.default_rng(seed)
    q = rng.standard_normal(4)
    q /= np.linalg.norm(q)
    a, b, c, d = q
    return np.array([[a * a + b * b - c * c - d * d, 2 * (b * c - a * d), 2 * (b * d + a * c)],
                     [2 * (b * c + a * d), a * a - b * b + c * c - d * d, 2 * (c * d - a * b)],
                     [2 * (b * d - a * c), 2 * (c * d + a * b), a * a - b * b - c * c + d * d]], F32)


def gblur(a, sigma):
    """Separable Gaussian blur (numpy only), zero padding. sigma in pixels."""
    if sigma <= 0:
        return a.astype(F32)
    r = int(math.ceil(sigma * 3.0))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2).astype(F32)
    k /= k.sum()
    out = a.astype(F32)
    for ax in (0, 1):
        pad = [(0, 0)] * out.ndim
        pad[ax] = (r, r)
        p = np.pad(out, pad)
        acc = np.zeros_like(out)
        n = out.shape[ax]
        for i, w in enumerate(k):
            sl = [slice(None)] * out.ndim
            sl[ax] = slice(i, i + n)
            acc += w * p[tuple(sl)]
        out = acc
    return out


# --------------------------------------------------------------------------------------------------------------------
# noise volumes (all periodic or clamped grids, looked up trilinearly; built once per process, deterministic)
# --------------------------------------------------------------------------------------------------------------------


def _tri(fl, m, n, u, v, w, wrap):
    """Trilinear lookup in a flattened (n+1 or n)^3 grid 'fl' (row length m) at voxel coords u, v, w (x, y, z)."""
    x0 = np.floor(u)
    y0 = np.floor(v)
    z0 = np.floor(w)
    fx = (u - x0).astype(F32)
    fy = (v - y0).astype(F32)
    fz = (w - z0).astype(F32)
    if wrap:
        i = ((z0.astype(np.int32) % n) * m + (y0.astype(np.int32) % n)) * m + (x0.astype(np.int32) % n)
    else:
        i = (z0.astype(np.int32) * m + y0.astype(np.int32)) * m + x0.astype(np.int32)
    c0 = fl[i]
    c0 += (fl[i + 1] - c0) * fx
    c1 = fl[i + m]
    c1 += (fl[i + m + 1] - c1) * fx
    c0 += (c1 - c0) * fy
    c2 = fl[i + m * m]
    c2 += (fl[i + m * m + 1] - c2) * fx
    c3 = fl[i + m * m + m]
    c3 += (fl[i + m * m + m + 1] - c3) * fx
    c2 += (c3 - c2) * fy
    c0 += (c2 - c0) * fz
    return c0


class Vol:
    """Periodic band-limited 3D noise (spectral synthesis), mean 0, std 1."""

    def __init__(self, seed, n=128, fmin=6.0, fmax=12.0):
        rng = np.random.default_rng(seed)
        f1 = np.fft.fftfreq(n) * n
        f2 = np.fft.rfftfreq(n) * n
        f = np.sqrt(f1[:, None, None] ** 2 + f1[None, :, None] ** 2 + f2[None, None, :] ** 2)
        amp = sstep(fmin * 0.6, fmin, f) * (1.0 - sstep(fmax, fmax * 1.5, f))
        spec = (rng.standard_normal(amp.shape) + 1j * rng.standard_normal(amp.shape)) * amp
        v = np.fft.irfftn(spec, s=(n, n, n), axes=(0, 1, 2))
        v = (v - v.mean()) / (v.std() + 1e-12)
        self._set(v, 0.5 * (fmin + fmax))

    def _set(self, v, fc):
        n = v.shape[0]
        self.n, self.m, self.fc = n, n + 1, float(fc)
        self.flat = np.pad(v.astype(F32), ((0, 1), (0, 1), (0, 1)), mode="wrap").ravel()

    def sample(self, X, Y, Z, freq, R, off):
        """Noise at points X, Y, Z (cell units) with 'freq' features (cycles) per cell unit, turned by R, shifted by
        'off' (in periods)."""
        k = freq / self.fc * self.n
        n = self.n
        u = (R[0, 0] * X + R[0, 1] * Y + R[0, 2] * Z) * k + off[0] * n
        v = (R[1, 0] * X + R[1, 1] * Y + R[1, 2] * Z) * k + off[1] * n
        w = (R[2, 0] * X + R[2, 1] * Y + R[2, 2] * Z) * k + off[2] * n
        return _tri(self.flat, self.m, n, u, v, w, True)


class WorleyVol(Vol):
    """Periodic cellular noise: round domes 1 - (F1/0.95)^2, one per feature point, V creases between them."""

    def __init__(self, seed, n=128, cells=8):
        rng = np.random.default_rng(seed)
        pts = rng.random((cells, cells, cells, 3)).astype(F32)
        g = (np.arange(n, dtype=F32) + 0.5) / (n / cells)
        Z, Y, X = np.meshgrid(g, g, g, indexing="ij")
        ci, cj, ck = (np.floor(a).astype(np.int32) for a in (X, Y, Z))
        best = np.full(X.shape, 9.0, F32)
        for dk in (-1, 0, 1):
            for dj in (-1, 0, 1):
                for di in (-1, 0, 1):
                    a, b, c = ci + di, cj + dj, ck + dk
                    p = pts[c % cells, b % cells, a % cells]
                    dx = a + p[..., 0] - X
                    dy = b + p[..., 1] - Y
                    dz = c + p[..., 2] - Z
                    np.minimum(best, dx * dx + dy * dy + dz * dz, out=best)
        self._set(1.0 - np.clip(np.sqrt(best) / 0.95, 0.0, 1.0) ** 2, cells)


class CurlVol:
    """A periodic divergence-free velocity field: the curl of a band-limited vector potential, RMS speed 1.
    Period = 1 cell unit; 'fmin..fmax' cycles per cell."""

    def __init__(self, seed, n=64, fmin=2.0, fmax=4.0):
        rng = np.random.default_rng(seed)
        f1 = np.fft.fftfreq(n) * n
        f2 = np.fft.rfftfreq(n) * n
        KZ, KY, KX = np.meshgrid(f1, f1, f2, indexing="ij")
        f = np.sqrt(KX ** 2 + KY ** 2 + KZ ** 2)
        amp = sstep(fmin * 0.6, fmin, f) * (1.0 - sstep(fmax, fmax * 1.5, f))
        Ax, Ay, Az = [(rng.standard_normal(amp.shape) + 1j * rng.standard_normal(amp.shape)) * amp for _ in range(3)]
        i2p = 2j * np.pi
        comps = [np.fft.irfftn(V, s=(n, n, n), axes=(0, 1, 2))
                 for V in (i2p * (KY * Az - KZ * Ay), i2p * (KZ * Ax - KX * Az), i2p * (KX * Ay - KY * Ax))]
        rms = math.sqrt(sum(float((c ** 2).mean()) for c in comps))
        self.n, self.m = n, n + 1
        self.flat = [np.pad((c / rms).astype(F32), ((0, 1), (0, 1), (0, 1)), mode="wrap").ravel() for c in comps]

    def at(self, X, Y, Z, off=(0.0, 0.0, 0.0)):
        n = self.n
        u, v, w = (X + off[0]) * n, (Y + off[1]) * n, (Z + off[2]) * n
        return [_tri(fl, self.m, n, u, v, w, True) for fl in self.flat]


class MatVol:
    """A static field on an N^3 grid over the cube [-B, B]^3 (cell units), looked up trilinearly (clamped)."""

    def __init__(self, vol, B):
        self.N, self.B = vol.shape[0], float(B)
        self.flat = np.ascontiguousarray(vol.astype(F32)).ravel()

    def at(self, X, Y, Z):
        N, B = self.N, self.B
        k = (N - 1) / (2.0 * B)
        hi = N - 1.0001
        return _tri(self.flat, N, N, np.clip((X + B) * k, 0.0, hi), np.clip((Y + B) * k, 0.0, hi),
                    np.clip((Z + B) * k, 0.0, hi), False)


def sphere_tree(seed, core=0.085, n1=11, d1=(0.75, 1.0), r1=(0.045, 0.07), n2=7, r2=(0.38, 0.52), n3=5,
                r3=(0.38, 0.5), spread=0.9):
    """A cauliflower: a core sphere, lobes on it, sub-lobes on the lobes' outer sides, sub-sub-lobes on those.
    Returns the levels as lists of (centre (3,), radius): [core + lobes, sub-lobes, sub-sub-lobes]."""
    rng = np.random.default_rng(seed)

    def unit():
        v = rng.standard_normal(3)
        return v / np.linalg.norm(v)
    lv1 = []
    for i in range(n1):
        y = 1.0 - 2.0 * (i + 0.5) / n1
        r = math.sqrt(max(0.0, 1.0 - y * y))
        th = i * 2.399963 + rng.uniform(-0.35, 0.35)
        d = np.array([r * math.cos(th), y, r * math.sin(th)]) + 0.25 * unit()
        d /= np.linalg.norm(d)
        lv1.append((d * core * rng.uniform(*d1), rng.uniform(*r1)))
    levels = [[(np.zeros(3), core)] + lv1]
    prev = lv1
    for (nn, rr) in ((n2, r2), (n3, r3)):
        nxt = []
        for c, rp in prev:
            outward = c / (np.linalg.norm(c) + 1e-9)
            for _ in range(nn):
                d = outward + spread * unit()
                d /= np.linalg.norm(d)
                nxt.append((c + d * rp * rng.uniform(0.75, 1.0), rp * rng.uniform(*rr)))
        levels.append(nxt)
        prev = nxt
    return levels


def sdf_spheres(levels, ks, N, B, far=0.06):
    """Signed distance of a sphere tree on an N^3 grid over [-B, B]^3: each level is soft-unioned (log-sum-exp) onto
    the levels before it with its own smoothing k (wide blends between the big lobes, so no seams; tight ones for the
    small billows, so they stay round). 'far' = beyond every sphere's reach. Spheres are evaluated in their own block."""
    h = 2.0 * B / (N - 1)
    g = (-B + np.arange(N) * h).astype(F32)
    sd = np.full((N, N, N), far, F32)
    for spheres, k in zip(levels, ks):
        k = F32(k)
        acc = np.exp(np.minimum(-sd / k, 80.0))
        reach = 8.0 * float(k) + 0.01
        for c, r in spheres:
            lo = np.clip(np.floor((c - r - reach + B) / h).astype(int), 0, N - 1)
            hi = np.clip(np.ceil((c + r + reach + B) / h).astype(int) + 1, 0, N)
            if np.any(hi <= lo):
                continue
            zz = g[lo[2]:hi[2], None, None] - F32(c[2])
            yy = g[None, lo[1]:hi[1], None] - F32(c[1])
            xx = g[None, None, lo[0]:hi[0]] - F32(c[0])
            d = np.sqrt(xx * xx + yy * yy + zz * zz) - F32(r)
            acc[lo[2]:hi[2], lo[1]:hi[1], lo[0]:hi[0]] += np.exp(np.minimum(-d / k, 80.0))
        with np.errstate(divide="ignore"):
            sd = np.minimum(-k * np.log(acc), far).astype(F32)
    return sd


# --------------------------------------------------------------------------------------------------------------------
# flow maps: where the smoke at x (frame k) was at birth. Backward advection (RK2) through a velocity field, composed
# frame by frame on a G^3 grid over the cell cube [-0.5, 0.5]^3 (cell-centred samples).
# --------------------------------------------------------------------------------------------------------------------


def grid_interp(Phi, G, X, Y, Z):
    """Trilinear lookup of a (C, G, G, G) [channel, z, y, x] grid at points X, Y, Z (cell units), clamped."""
    def idx(c):
        q = np.clip((c + 0.5) * G - 0.5, 0.0, G - 1.0001)
        i0 = np.floor(q).astype(np.int32)
        return i0, (q - i0).astype(F32)
    ix, fx = idx(X)
    iy, fy = idx(Y)
    iz, fz = idx(Z)
    out = []
    for g in Phi:
        def at(dz, dy, dx):
            return g[iz + dz, iy + dy, ix + dx]
        c00 = at(0, 0, 0) + (at(0, 0, 1) - at(0, 0, 0)) * fx
        c01 = at(0, 1, 0) + (at(0, 1, 1) - at(0, 1, 0)) * fx
        c10 = at(1, 0, 0) + (at(1, 0, 1) - at(1, 0, 0)) * fx
        c11 = at(1, 1, 0) + (at(1, 1, 1) - at(1, 1, 0)) * fx
        c0 = c00 + (c01 - c00) * fy
        c1 = c10 + (c11 - c10) * fy
        out.append((c0 + (c1 - c0) * fz).astype(F32))
    return out


def flow_maps(times, vel, G=64, substeps=2):
    """times: increasing frame times. vel(X, Y, Z, t) -> (u, v, w). Returns one (3, G, G, G) map per time: the birth
    (material) position of the smoke found at each grid point at that time."""
    g = ((np.arange(G) + 0.5) / G - 0.5).astype(F32)
    Z, Y, X = np.meshgrid(g, g, g, indexing="ij")
    maps, prev, tprev = [], None, 0.0
    for t in times:
        px, py, pz = X.copy(), Y.copy(), Z.copy()
        h = (t - tprev) / substeps
        tc = t
        for _ in range(substeps):
            u1 = vel(px, py, pz, tc)
            mx, my, mz = px - 0.5 * h * u1[0], py - 0.5 * h * u1[1], pz - 0.5 * h * u1[2]
            u2 = vel(mx, my, mz, tc - 0.5 * h)
            px, py, pz = px - h * u2[0], py - h * u2[1], pz - h * u2[2]
            tc -= h
        cur = np.stack([px, py, pz] if prev is None else grid_interp(prev, G, px, py, pz)).astype(F32)
        maps.append(cur)
        prev, tprev = cur, t
    return maps


def interp_index(S, G, flip):
    """Linear interpolation from a cell-centred G grid over [-0.5, 0.5] to S output pixels: (i0, f) per pixel
    (flip: output index 0 = coordinate +0.5, so image rows run top to bottom). Gather-and-lerp, no BLAS: threaded BLAS
    on small matrices is pathologically slow when several processes share the CPUs."""
    c = (np.arange(S) + 0.5) / S - 0.5
    if flip:
        c = -c
    q = np.clip((c + 0.5) * G - 0.5, 0.0, G - 1.0001)
    i0 = np.floor(q).astype(np.int64)
    return i0, (q - i0).astype(F32)


def upsample2(M, iy, fy, ix, fx):
    """(G, G) grid slice -> (len(iy), len(ix)) image, separable bilinear."""
    a = M[iy] * (1 - fy)[:, None] + M[iy + 1] * fy[:, None]
    return a[:, ix] * (1 - fx)[None, :] + a[:, ix + 1] * fx[None, :]


# --------------------------------------------------------------------------------------------------------------------
# the volume renderer: orthographic, camera on +z looking down -z; slices from the front (z = +zh) to the back
# --------------------------------------------------------------------------------------------------------------------


def shift_zero(a, dy, dx):
    """out[r, c] = a[r + dy, c + dx] (bilinear, zero outside)."""
    H, W = a.shape
    iy, ix = int(math.floor(dy)), int(math.floor(dx))
    fy, fx = F32(dy - iy), F32(dx - ix)
    pad = max(abs(iy), abs(ix)) + 2
    p = np.zeros((H + 2 * pad, W + 2 * pad), F32)
    p[pad:pad + H, pad:pad + W] = a

    def win(oy, ox):
        return p[pad + oy:pad + oy + H, pad + ox:pad + ox + W]
    top = win(iy, ix) * (1 - fx) + win(iy, ix + 1) * fx
    bot = win(iy + 1, ix) * (1 - fx) + win(iy + 1, ix + 1) * fx
    return top * (1 - fy) + bot * fy


def soften(a, w):
    """One step of a tiny separable blur [w, 1-2w, w] (zero outside): spreads a shadow front a little per slice, as a
    light of some size and multiple scattering do (without it, fine density detail casts hairline shadow streaks)."""
    if w <= 0:
        return a
    w = F32(w)
    b = a * (1 - 2 * w)
    b[1:] += w * a[:-1]
    b[:-1] += w * a[1:]
    c = b * (1 - 2 * w)
    c[:, 1:] += w * b[:, :-1]
    c[:, :-1] += w * b[:, 1:]
    return c


class Light:
    """key: direction TO the key light (x right, y up, z toward the camera). rim: direction to the rim light (z < 0:
    behind the smoke). ms: multiple-scattering octaves (weight, extinction factor) for the key light. soft: shadow-front
    blur per slice."""

    def __init__(self, key=(-0.5, 0.7, 0.5), rim=(0.45, 0.35, -0.82), k_int=1.0, rim_int=0.8, sky_int=0.25, amb=0.03,
                 sigma_rim=1.0, sigma_sky=0.35, ms=((1.0, 1.0), (0.35, 0.4), (0.15, 0.16)), soft=0.12, sigma_key=1.0):
        self.key = np.asarray(key, float) / np.linalg.norm(key)
        self.rim = np.asarray(rim, float) / np.linalg.norm(rim)
        self.k_int, self.rim_int, self.sky_int, self.amb = k_int, rim_int, sky_int, amb
        self.sigma_rim, self.sigma_sky, self.ms, self.soft = sigma_rim, sigma_sky, ms, soft
        self.sigma_key = sigma_key      # (< 1: lighter self-shadowing, for thin smoke)


def render_volume(density_slice, h, w, NZ, zh, sigma, light, px):
    """Ray-march an (NZ, h, w) window. density_slice(z) -> (h, w) density at depth z (cell units; slices from +zh down
    to -zh); px = pixel size in cell units; sigma = extinction per cell unit at density 1. Returns the premultiplied
    luminance P and the alpha A (h, w)."""
    dz = 2.0 * zh / NZ
    D = np.empty((NZ, h, w), F32)
    for i in range(NZ):
        D[i] = density_slice(zh - (i + 0.5) * dz)
    pz = dz / px                                          # slice spacing in pixels
    # rim light from behind: its shadow march runs back to front
    L2 = light.rim
    ds2 = F32(dz / abs(L2[2]))
    dy2, dx2 = -L2[1] / abs(L2[2]) * pz, L2[0] / abs(L2[2]) * pz
    Trim = np.empty((NZ, h, w), np.float16)
    tau = np.zeros((h, w), F32)
    sr = F32(sigma * light.sigma_rim)
    for i in range(NZ - 1, -1, -1):
        tau = soften(shift_zero(tau, dy2, dx2), light.soft) + D[i] * (0.5 * ds2)
        Trim[i] = np.exp(-sr * tau)
        tau += D[i] * (0.5 * ds2)
    # key light (in front) and the view: front to back
    L = light.key
    ds = F32(dz / L[2])
    dy, dx = -L[1] / L[2] * pz, L[0] / L[2] * pz
    tau = np.zeros((h, w), F32)
    T = np.ones((h, w), F32)
    P = np.zeros((h, w), F32)
    sk, ss, sdz = F32(sigma * light.sigma_key), F32(sigma * light.sigma_sky * px), F32(sigma * dz)
    for i in range(NZ):
        d = D[i]
        if not d.any() and not tau.any():
            continue
        tau = soften(shift_zero(tau, dy, dx), light.soft) + d * (0.5 * ds)
        tk = sk * tau
        key = sum(F32(wt) * np.exp(-F32(e) * tk) for wt, e in light.ms)
        tau += d * (0.5 * ds)
        up = np.cumsum(d, axis=0) - 0.5 * d              # the sky, from straight above, through this slice
        Lin = light.k_int * key + light.rim_int * Trim[i].astype(F32) + light.sky_int * np.exp(-ss * up) + light.amb
        a = 1.0 - np.exp(-sdz * d)
        P += T * a * Lin
        T *= 1.0 - a
    return P, 1.0 - T


def render_advected(S, G, ZH, NZ, sigma, light, grid, reach_test, density, crop_margin=2.0):
    """One frame of a smoke whose material positions are in 'grid' (C, G, G, G): channels 0-2 = the material position,
    3.. = extra fields precomputed on the grid. reach_test(ch) -> bool mask of grid points / pixels that may hold smoke;
    density(ch_masked, XW, YW, z) -> density at those points. Renders only the bounding box of the smoke (per frame) and
    evaluates density only where reach_test passes. Returns P, A for the whole S x S cell."""
    act = reach_test([grid[c] for c in range(grid.shape[0])])
    P = np.zeros((S, S), F32)
    A = np.zeros((S, S), F32)
    if not act.any():
        return P, A
    gi = np.argwhere(act)
    lo = (gi.min(axis=0) + 0.5) / G - 0.5 - crop_margin / G     # (z, y, x)
    hi = (gi.max(axis=0) + 0.5) / G - 0.5 + crop_margin / G
    r0 = int(max(0, math.floor((0.5 - hi[1]) * S)))
    r1 = int(min(S, math.ceil((0.5 - lo[1]) * S)))
    c0 = int(max(0, math.floor((lo[2] + 0.5) * S)))
    c1 = int(min(S, math.ceil((hi[2] + 0.5) * S)))
    zh = min(ZH, max(abs(lo[0]), abs(hi[0])))
    nz = max(16, int(round(NZ * zh / ZH)))
    h, w = r1 - r0, c1 - c0
    c = ((np.arange(S) + 0.5) / S - 0.5).astype(F32)
    XW = np.ascontiguousarray(np.broadcast_to(c[None, c0:c1], (h, w)))
    YW = np.ascontiguousarray(np.broadcast_to(-c[r0:r1, None], (h, w)))
    iy, fy = interp_index(S, G, True)
    ix, fx = interp_index(S, G, False)
    iy, fy, ix, fx = iy[r0:r1], fy[r0:r1], ix[c0:c1], fx[c0:c1]
    C = grid.shape[0]

    def dslice(z):
        q = min(max((z + 0.5) * G - 0.5, 0.0), G - 1.0001)
        i0 = int(q)
        f = F32(q - i0)
        ch = [upsample2(grid[k, i0] * (1 - f) + grid[k, i0 + 1] * f, iy, fy, ix, fx) for k in range(C)]
        out = np.zeros((h, w), F32)
        m = reach_test(ch)
        if m.any():
            out[m] = density([a[m] for a in ch], XW[m], YW[m], z)
        return out
    Pc, Ac = render_volume(dslice, h, w, nz, zh, sigma, light, 1.0 / S)
    P[r0:r1, c0:c1] = Pc
    A[r0:r1, c0:c1] = Ac
    return P, A


# --------------------------------------------------------------------------------------------------------------------
# te5_billow: the puff
# --------------------------------------------------------------------------------------------------------------------

BILLOW = dict(
    # the shape at birth (material space): sphere tree + per-level smoothing
    seed=7, core=0.11, n1=11, d1=(0.75, 1.0), r1=(0.045, 0.07), n2=7, r2=(0.38, 0.52), n3=5, r3=(0.38, 0.5),
    spread=0.9, ks=(0.014, 0.006, 0.003), matN=192, matB=0.26,
    # motion: expansion E0 (1 - EA t) swelling +-beta in places; curl scales 1 and 2 at a + b t + c t^3; rise
    E0=0.9, EA=0.55, beta=0.2, curl1=(0.02, 0.05, 0.15), curl2=(0.012, 0.03, 0.06), rise=0.02, G=64, substeps=2,
    # density: fine billows (Worley A3 at F3/cell), ramp noise (QN at FQ), Perlin bumps (AP at FP), mixed FMIX of the way
    # from expansion-only to material coordinates; ramps w_out / w_in widening with age
    A3=0.004, F3=60.0, AP=0.002, FP=24.0, QN=0.4, FQ=30.0, FMIX=0.5,
    wo=(0.004, 0.045, 0.2), wi=(0.05, 0.07, 0.35),
    # dying: thinning exp(-DK sstep(DT0, 1, t)^DP), erosion, density gathered into veils (ridges at F4, power RP)
    DK=3.3, DT0=0.32, DP=1.1, ero=(1.0, 0.4, 0.25), EN=0.2, ED=0.45, EDD=0.12, FE=12.0,
    veil=(1.0, 0.4), F4=7.0, RP=1.6, RLO=0.2, RHI=1.25,
    # light and render
    sigma=90.0, S=CELL * SS, NZ=128, ZH=0.45, win=(0.44, 0.38),
    key=(-0.5, 0.7, 0.5), rim=(0.45, 0.35, -0.82), k_int=1.0, rim_int=0.8, sky_int=0.25, amb=0.03,
    ms=((1.0, 1.0), (0.35, 0.4), (0.15, 0.16)), soft=0.12,
    # output tone: luminance / (p95 of the dense smoke in frames 2-9) through 1 - exp(-gamma x), normalised
    gamma=1.6, ref_frames=(2, 9),
)

_CACHE = {}


def billow_noise(P):
    key = ("billow", json.dumps(P, sort_keys=True, default=str))
    if key not in _CACHE:
        lv = sphere_tree(P["seed"], P["core"], P["n1"], P["d1"], P["r1"], P["n2"], P["r2"], P["n3"], P["r3"], P["spread"])
        _CACHE[key] = dict(
            puff=MatVol(sdf_spheres(lv, P["ks"], P["matN"], P["matB"]), P["matB"]),
            w2=WorleyVol(32, 128, 8), n1=Vol(11), n2=Vol(12), n3=Vol(13), n4=Vol(14), nl=Vol(15, 64, 2.0, 4.0),
            c1=CurlVol(21, 64, 2.0, 3.5), c2=CurlVol(22, 64, 5.0, 8.0), R=[rot3(100 + i) for i in range(10)])
    return _CACHE[key]


def frame_times(n=16):
    """OneShot frame k shows during life fraction [k/16, (k+1)/16): it is rendered at the middle of that span."""
    return [(k + 0.5) / n for k in range(n)]


def billow_scale(P, t):
    """Mean expansion at time t: s = exp(integral of E0 (1 - EA t))."""
    return math.exp(P["E0"] * (t - P["EA"] * t * t / 2.0))


def billow_velocity(P):
    N = billow_noise(P)

    def vel(X, Y, Z, t):
        e = P["E0"] * (1.0 - P["EA"] * t)
        if P["beta"]:
            e = e * (1.0 + P["beta"] * N["nl"].sample(X, Y, Z, 3.0, N["R"][7], (0.31, 0.47, 0.11)))
        a = N["c1"].at(X, Y, Z, (0.13, 0.71, 0.37))
        b = N["c2"].at(X, Y, Z, (0.52, 0.29, 0.83))
        k1 = P["curl1"][0] + P["curl1"][1] * t + P["curl1"][2] * t ** 3
        k2 = P["curl2"][0] + P["curl2"][1] * t + P["curl2"][2] * t ** 3
        return (e * X + k1 * a[0] + k2 * b[0], e * Y + k1 * a[1] + k2 * b[1] + P["rise"], e * Z + k1 * a[2] + k2 * b[2])
    return vel


def billow_frame(P, k, Phi):
    N = billow_noise(P)
    R = N["R"]
    t = frame_times()[k]
    s = billow_scale(P, t)
    G = P["G"]
    grid = np.concatenate([Phi, N["puff"].at(Phi[0], Phi[1], Phi[2])[None]], axis=0)
    w_out = P["wo"][0] + P["wo"][1] * float(sstep(P["wo"][2], 1.0, t))
    w_in = P["wi"][0] + P["wi"][1] * float(sstep(P["wi"][2], 1.0, t))
    dens = math.exp(-P["DK"] * float(sstep(P["DT0"], 1.0, t)) ** P["DP"])
    eth = -0.3 + P["ero"][0] * float(sstep(P["ero"][1], 1.0, t))
    veil = P["veil"][0] * float(sstep(P["veil"][1], 1.0, t))
    reach = (P["A3"] + P["AP"] + 0.01) * s + w_out + 0.02

    def reach_test(ch):
        return ch[3] * s - reach < 0

    def density(ch, XW, YW, z):
        X, Y, Z = ch[0], ch[1], ch[2]
        sd = N["puff"].at(X, Y, Z)
        # fine detail in expansion-only coordinates, mixed FMIX of the way toward the flowed material ones
        Xf, Yf, Zf = XW / s, YW / s, np.full(XW.shape, z / s, F32)
        mx = P["FMIX"]
        Xf, Yf, Zf = Xf + mx * (X - Xf), Yf + mx * (Y - Yf), Zf + mx * (Z - Zf)
        w3 = N["w2"].sample(Xf, Yf, Zf, P["F3"], R[2], (0.7, 0.8, 0.9))
        n3 = N["n3"].sample(Xf, Yf, Zf, P["FP"], R[5], (0.6, 0.1, 0.7))
        Dw = (sd - P["A3"] * (w3 - 0.5) - P["AP"] * n3) * s
        rho = sstep(w_out, -w_in, Dw)
        nq = N["n1"].sample(Xf, Yf, Zf, P["FQ"], R[8], (0.21, 0.66, 0.93)) \
            + 0.5 * N["n1"].sample(Xf, Yf, Zf, 2.1 * P["FQ"], R[9], (0.71, 0.16, 0.43))
        rho = rho * np.clip(1.0 + P["QN"] * 0.8 * nq * (1.0 - rho) * 2.0, 0.0, 2.0)
        n2 = N["n2"].sample(X, Y, Z, P["FE"], R[4], (0.3, 0.3, 0.6))
        Er = 0.5 + P["EN"] * n2 + P["ED"] * sstep(0.0, -P["EDD"], Dw)
        rho = rho * sstep(eth - P["ero"][2], eth + P["ero"][2], Er) * dens
        if veil > 0:
            n4 = N["n4"].sample(X, Y, Z, P["F4"], R[6], (0.15, 0.55, 0.35))
            rid = (1.0 - np.minimum(np.abs(n4), 1.0)) ** P["RP"]
            rho = rho * (1.0 - veil + veil * (P["RLO"] + P["RHI"] * rid))
        r3 = np.sqrt(XW * XW + YW * YW + z * z)
        return (rho * sstep(P["win"][0], P["win"][1], r3)).astype(F32)

    light = Light(P["key"], P["rim"], P["k_int"], P["rim_int"], P["sky_int"], P["amb"], ms=P["ms"], soft=P["soft"])
    return render_advected(P["S"], G, P["ZH"], P["NZ"], P["sigma"], light, grid, reach_test, density)


# --------------------------------------------------------------------------------------------------------------------
# rendering driver: flow maps in this process, frames in parallel worker processes (fork on Linux, spawn on a Mac:
# workers rebuild the same seeded noises, so the result does not depend on how the frames are spread)
# --------------------------------------------------------------------------------------------------------------------

KINDS = {}      # name -> (default params, velocity(P) -> vel(X, Y, Z, t), frame(P, k, Phi) -> (P, A))


def _work(args):
    kind, P, k, Phi = args
    t0 = time.time()
    Pk, Ak = KINDS[kind][2](P, k, Phi)
    return k, Pk, Ak, time.time() - t0


def render_flipbook(kind, P, frames=None, procs=4, log=print):
    frames = list(range(16)) if frames is None else frames
    t0 = time.time()
    vel = KINDS[kind][1](P)
    maps = flow_maps(frame_times()[:max(frames) + 1], vel, G=P["G"], substeps=P["substeps"])
    log(f"  {kind}: flow maps {time.time() - t0:.1f}s")
    jobs = [(kind, P, k, maps[k]) for k in frames]
    if procs > 1:
        import multiprocessing as mp
        ctx = mp.get_context("fork" if "fork" in mp.get_all_start_methods() and sys.platform != "darwin" else "spawn")
        with ctx.Pool(min(procs, len(jobs))) as pool:
            res = pool.map(_work, jobs, chunksize=1)
    else:
        res = [_work(j) for j in jobs]
    res.sort(key=lambda r: r[0])
    log(f"  {kind}: {len(res)} frames {time.time() - t0:.1f}s (slowest frame {max(r[3] for r in res):.1f}s)")
    return [r[1] for r in res], [r[2] for r in res]


KINDS["billow"] = (BILLOW, billow_velocity, billow_frame)


# --------------------------------------------------------------------------------------------------------------------
# te5_wisp: thin curling tendrils (incense, cold breath)
# --------------------------------------------------------------------------------------------------------------------

WISP = dict(
    # seven thin ribbons at birth (material space): a short tuft low in the cell (y0..y1, each ribbon starting and
    # ending at its own height, the ends frayed by noise), half-width growing from the bottom (hw[0]) to the top
    # (hw[1]), gaussian thickness, a twist about the vertical (rad per cell unit), a gentle wave (amplitude, rad per
    # cell unit, growth with height) and streaks along the flow
    seed=41, ribbons=7, y0=-0.31, y1=0.0, hw=(0.02, 0.11), thick=0.007, twist=6.0, spread_x=0.05,
    wave=(0.03, 14.0, 1.0), streak=0.32, streakF=(6.0, 40.0), ends=(0.1, 0.25), fray=0.07,
    # motion: curl (3-5 cycles per cell) at a + b t, a finer curl, a rise plus buoyant strain (smoke above ybase
    # rises faster the higher it is, so the tuft is drawn up into tall tendrils) and a slight spread
    curl=(0.06, 0.72), curlF=(3.0, 5.0), curl2=(0.01, 0.08), rise=0.04, strain=0.62, ybase=-0.32, E0=0.22, G=80,
    substeps=3,
    # life: born at born[0] of full density, full by t = born[1]; thinning exp(-DK sstep(DT0, 1, t)^DP); the ribbons
    # thicken (diffuse) with age
    DK=1.4, DT0=0.5, DP=1.4, diff=(0.0, 0.010, 0.3), born=(0.22, 0.4),
    # light and render (thin smoke: lighter self-shadowing, more ambient and multiple scattering, a strong rim)
    sigma=60.0, S=CELL * SS, NZ=256, ZH=0.45, win=(0.44, 0.38),
    key=(-0.5, 0.7, 0.5), rim=(0.45, 0.35, -0.82), k_int=1.0, rim_int=1.1, sky_int=0.3, amb=0.14,
    ms=((1.0, 1.0), (0.5, 0.4), (0.25, 0.16)), soft=0.1, kext=0.55,
    gamma=1.6, ref_frames=(3, 10),
)


def wisp_noise(P):
    key = ("wisp", json.dumps(P, sort_keys=True, default=str))
    if key not in _CACHE:
        rng = np.random.default_rng(P["seed"])
        rib = []
        for _ in range(P["ribbons"]):
            rib.append(dict(th=rng.uniform(0, math.pi), ox=rng.uniform(-1, 1) * P["spread_x"],
                            oz=rng.uniform(-1, 1) * P["spread_x"], ph=rng.uniform(0, 2 * math.pi),
                            ph2=rng.uniform(0, 2 * math.pi), dens=rng.uniform(0.75, 1.0),
                            tw=P["twist"] * rng.uniform(0.6, 1.3) * rng.choice([-1, 1]), wf=rng.uniform(0.8, 1.25),
                            lo=rng.uniform(0.0, P["ends"][0]), hi=1.0 - rng.uniform(0.0, P["ends"][1])))
        _CACHE[key] = dict(rib=rib, c1=CurlVol(51, 64, *P["curlF"]), c2=CurlVol(52, 64, 7.0, 11.0), n1=Vol(53),
                           R=[rot3(200 + i) for i in range(8)])
    return _CACHE[key]


def wisp_velocity(P):
    N = wisp_noise(P)

    def vel(X, Y, Z, t):
        a = N["c1"].at(X, Y, Z, (0.3, 0.6, 0.1))
        b = N["c2"].at(X, Y, Z, (0.7, 0.2, 0.5))
        k1 = P["curl"][0] + P["curl"][1] * t
        k2 = P["curl2"][0] + P["curl2"][1] * t
        e = P["E0"] * (1.0 - 0.5 * t)
        # buoyancy: higher smoke rises faster, so a short tuft is drawn up into tall tendrils
        up = P["rise"] + P["strain"] * np.maximum(Y - P["ybase"], 0.0)
        return (e * X + k1 * a[0] + k2 * b[0], 0.3 * e * Y + k1 * a[1] + k2 * b[1] + up,
                e * Z + k1 * a[2] + k2 * b[2])
    return vel


def ribbons(P, N, X, Y, Z, extra):
    """Density of the ribbons at material positions X, Y, Z ('extra' = added gaussian thickness: diffusion)."""
    rho = np.zeros(X.shape, F32)
    yy = (Y - P["y0"]) / (P["y1"] - P["y0"])                  # 0 at the bottom, 1 at the top
    # each ribbon starts and ends at its own height, and the ends are frayed by noise (no flat cut)
    fray = P["fray"] * N["n1"].sample(X, Y, Z, 5.0, N["R"][1], (0.55, 0.15, 0.85))
    yc = np.clip(yy, 0.0, 1.0)
    hw = P["hw"][0] + (P["hw"][1] - P["hw"][0]) * yc
    th2 = P["thick"] ** 2 + extra ** 2
    amp = P["thick"] / math.sqrt(th2)
    wav = P["wave"][0] * yc ** P["wave"][2]
    for r in N["rib"]:
        th = r["th"] + r["tw"] * Y
        nx, nz = np.cos(th), np.sin(th)
        dx = X - r["ox"] - wav * np.sin(P["wave"][1] * r["wf"] * Y + r["ph"])
        dz = Z - r["oz"] - wav * np.cos(P["wave"][1] * r["wf"] * 0.8 * Y + r["ph2"])
        dn = dx * nx + dz * nz                                # off the ribbon's plane
        dt = -dx * nz + dz * nx                               # across it, in its plane
        ye = yy + fray
        env = sstep(r["lo"] - 0.02, r["lo"] + 0.12, ye) * sstep(r["hi"] + 0.05, r["hi"] - 0.3, ye)
        rho += r["dens"] * amp * np.exp(-dn * dn / th2) * sstep(hw, hw * 0.45, np.abs(dt)) * env
    sx = P["streakF"][1] / P["streakF"][0]                    # streaks: noise stretched along the flow
    n = N["n1"].sample(X * sx, Y, Z * sx, P["streakF"][0], N["R"][0], (0.2, 0.4, 0.6))
    return (rho * np.clip(1.0 + P["streak"] * n, 0.15, 2.0)).astype(F32)


def wisp_frame(P, k, Phi):
    N = wisp_noise(P)
    t = frame_times()[k]
    # born faint (a wisp gathers body as it rises and curls: a dense newborn tuft reads as a white dot on the body),
    # then thinning away
    dens = math.exp(-P["DK"] * float(sstep(P["DT0"], 1.0, t)) ** P["DP"])
    dens *= P["born"][0] + (1.0 - P["born"][0]) * float(sstep(0.0, P["born"][1], t))
    extra = P["diff"][0] + P["diff"][1] * float(sstep(P["diff"][2], 1.0, t))
    grid = np.concatenate([Phi, ribbons(P, N, Phi[0], Phi[1], Phi[2], max(extra, 0.012))[None]], axis=0)

    def reach_test(ch):
        return ch[3] > 0.003

    def density(ch, XW, YW, z):
        rho = ribbons(P, N, ch[0], ch[1], ch[2], extra) * dens
        r3 = np.sqrt(XW * XW + YW * YW + z * z)
        return (rho * sstep(P["win"][0], P["win"][1], r3)).astype(F32)

    light = Light(P["key"], P["rim"], P["k_int"], P["rim_int"], P["sky_int"], P["amb"], ms=P["ms"], soft=P["soft"],
                  sigma_key=P["kext"])
    return render_advected(P["S"], P["G"], P["ZH"], P["NZ"], P["sigma"], light, grid, reach_test, density,
                           crop_margin=4.0)


KINDS["wisp"] = (WISP, wisp_velocity, wisp_frame)


# --------------------------------------------------------------------------------------------------------------------
# te5_mistbank: one soft, wide fog bank (a single image: a slow 6-8 s mist particle shows no flipbook steps)
# --------------------------------------------------------------------------------------------------------------------

MIST = dict(
    seed=61, lobes=13, span=0.30, lobe_r=(0.10, 0.17), flat=0.7, zspread=0.12, ks=(0.03, 0.012), matN=160,
    A=0.025, F=10.0, QN=0.3, FQ=9.0, layer=(0.22, 0.45, 1.8), wo=0.03, wi=0.09, height=0.2,
    sigma=11.0, S=512 * SS, NZ=128, ZH=0.45, win=(0.435, 0.38),
    key=(-0.35, 0.85, 0.4), rim=(0.4, 0.35, -0.85), k_int=1.0, rim_int=0.7, sky_int=0.45, amb=0.12,
    ms=((1.0, 1.0), (0.5, 0.4), (0.25, 0.16)), soft=0.2, kext=0.7, gamma=1.6,
)


def mist_density_fn(P):
    """A static fog bank: a row of flattened soft lobes along x (densest on the middle line, where the floor cuts the
    particle), billowy on top, thinning upward, with soft cloudy density inside."""
    rng = np.random.default_rng(P["seed"])
    lobes = []
    for i in range(P["lobes"]):
        x = (-1.0 + 2.0 * (i + rng.uniform(0.2, 0.8)) / P["lobes"]) * P["span"]
        r = rng.uniform(*P["lobe_r"]) * (1.0 - 0.45 * (abs(x) / P["span"]) ** 2)
        lobes.append((np.array([x, rng.uniform(-0.01, 0.03), rng.uniform(-1, 1) * P["zspread"]]), r))
    small = []
    for c, r in lobes:
        for _ in range(4):
            d = rng.standard_normal(3)
            d[1] = abs(d[1]) * 1.5
            d /= np.linalg.norm(d)
            small.append((c + d * r * rng.uniform(0.6, 0.9), r * rng.uniform(0.35, 0.55)))
    B = 0.5
    # flattened: build the sdf in a space stretched by 1/flat along y, then look it up at (x, y / flat, z)
    sd = MatVol(sdf_spheres([lobes, small], P["ks"], P["matN"], B, far=0.25), B)
    nz, w2, R = Vol(63), WorleyVol(64, 128, 8), [rot3(300 + i) for i in range(4)]

    def density(X, Y, Z):
        Yf = Y / P["flat"]
        d = sd.at(X, Yf, Z) * P["flat"]
        w = w2.sample(X, Y, Z, P["F"], R[0], (0.1, 0.3, 0.5))
        d = d - P["A"] * (w - 0.5)
        rho = sstep(P["wo"], -P["wi"], d)
        q = (nz.sample(X, Y, Z, P["FQ"], R[1], (0.4, 0.2, 0.7))
             + 0.5 * nz.sample(X, Y, Z, 2.2 * P["FQ"], R[2], (0.1, 0.8, 0.3)))
        # ground mist lies in layers: noise stretched along x (and z), squeezed in y
        lay = nz.sample(X * P["layer"][1], Y * P["layer"][2], Z * P["layer"][1], P["FQ"], R[3], (0.6, 0.5, 0.2))
        rho = rho * np.clip(0.75 + P["QN"] * 0.5 * q + P["layer"][0] * lay, 0.1, 1.6)
        rho = rho * np.exp(-np.maximum(Y, 0.0) / P["height"])           # thins upward
        r3 = np.sqrt(X * X + Y * Y + Z * Z)
        return (rho * sstep(P["win"][0], P["win"][1], r3)).astype(F32)
    return density


def render_mist(P):
    dens = mist_density_fn(P)
    S = P["S"]
    # where the fog is (from a coarse 64^3 look), so only that box is ray-marched
    g = ((np.arange(64) + 0.5) / 64 - 0.5).astype(F32)
    Zc, Yc, Xc = np.meshgrid(g, g, g, indexing="ij")
    occ = np.argwhere(dens(Xc, Yc, Zc) > 1e-4)
    lo = (occ.min(axis=0) + 0.5) / 64 - 0.5 - 2.0 / 64           # (z, y, x)
    hi = (occ.max(axis=0) + 0.5) / 64 - 0.5 + 2.0 / 64
    r0, r1 = max(0, int(math.floor((0.5 - hi[1]) * S))), min(S, int(math.ceil((0.5 - lo[1]) * S)))
    c0, c1 = max(0, int(math.floor((lo[2] + 0.5) * S))), min(S, int(math.ceil((hi[2] + 0.5) * S)))
    zh = min(P["ZH"], max(abs(lo[0]), abs(hi[0])))
    nz = max(16, int(round(P["NZ"] * zh / P["ZH"])))
    c = ((np.arange(S) + 0.5) / S - 0.5).astype(F32)
    XW = np.ascontiguousarray(np.broadcast_to(c[None, c0:c1], (r1 - r0, c1 - c0)))
    YW = np.ascontiguousarray(np.broadcast_to(-c[r0:r1, None], (r1 - r0, c1 - c0)))

    def dslice(z):
        return dens(XW, YW, np.full(XW.shape, z, F32))
    light = Light(P["key"], P["rim"], P["k_int"], P["rim_int"], P["sky_int"], P["amb"], ms=P["ms"], soft=P["soft"],
                  sigma_key=P["kext"])
    Pc, Ac = render_volume(dslice, r1 - r0, c1 - c0, nz, zh, P["sigma"], light, 1.0 / S)
    Pm, Am = np.zeros((S, S), F32), np.zeros((S, S), F32)
    Pm[r0:r1, c0:c1], Am[r0:r1, c0:c1] = Pc, Ac
    return Pm, Am


# --------------------------------------------------------------------------------------------------------------------
# finishing: tone, 2x -> 1x in premultiplied alpha, bleed, dither, save
# --------------------------------------------------------------------------------------------------------------------


def tone(Ps, As, gamma, ref_frames):
    """One exposure and one tone curve for the whole flipbook: luminance / ref (ref = p95 of the dense smoke over the
    reference frames) through (1 - exp(-gamma x)) / (1 - exp(-gamma)). Returns premultiplied toned luminance."""
    vals = []
    for k in range(ref_frames[0], ref_frames[1] + 1):
        if k < len(Ps):
            m = As[k] > 0.6
            if m.any():
                vals.append((Ps[k][m] / As[k][m]))
    ref = float(np.percentile(np.concatenate(vals), 95)) if vals else 1.0
    out = []
    for P, A in zip(Ps, As):
        L = np.where(A > 1e-6, P / np.maximum(A, 1e-6), 0.0)
        g = (1.0 - np.exp(-gamma * L / ref)) / (1.0 - math.exp(-gamma))
        out.append((np.clip(g, 0.0, 1.0) * A).astype(F32))
    return out, ref


def box_down(P, A, f):
    H, W = A.shape
    return (P.reshape(H // f, f, W // f, f).mean(axis=(1, 3)).astype(F32),
            A.reshape(H // f, f, W // f, f).mean(axis=(1, 3)).astype(F32))


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
    """Grey under invisible pixels := grey of the NEAREST visible pixels (ring-by-ring dilation, then pull-push), so
    filtering and mip-maps never mix black or white into an edge."""
    filled = visible.copy()
    out = np.where(visible, C, 0.0).astype(F32)
    nbrs = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
    H, W = out.shape
    for _ in range(rings):
        acc = np.zeros_like(out)
        cnt = np.zeros(filled.shape, F32)
        fpad = np.pad(filled, 1)
        opad = np.pad(out, 1)
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


def quantise(x, rng):
    """8-bit with +-1 LSB triangular dither (no banding); exact 0 and 255 stay exact."""
    v = x * 255.0
    d = rng.random(x.shape, dtype=F32) - rng.random(x.shape, dtype=F32)
    v = np.where((v > 1.0) & (v < 254.0), v + d, v)
    return np.clip(np.rint(v), 0, 255).astype(np.uint8)


def finish(name, cellsP, cellsA, grid, seed, pad_frac=0.0625):
    """2x premultiplied cells -> one RGBA PNG: box down, un-premultiply, alpha 0 on every cell's border band
    (pad_frac of the cell), bleed grey per cell, dither, save. Returns the uint8 image."""
    gy, gx = grid
    rows = []
    rng = np.random.default_rng(seed)
    for j in range(gy):
        row = []
        for i in range(gx):
            P, A = box_down(cellsP[j * gx + i], cellsA[j * gx + i], SS)
            n = A.shape[0]
            b = int(math.ceil(pad_frac * n))
            A = np.clip(A, 0.0, 1.0)
            A[:b] = 0
            A[-b:] = 0
            A[:, :b] = 0
            A[:, -b:] = 0
            C = np.clip(np.where(A > 1e-6, P / np.maximum(A, 1e-6), 0.0), 0.0, 1.0)
            a8 = quantise(A, rng)
            g8 = quantise(np.clip(bleed(C, a8 > 0), 0.0, 1.0), rng)
            row.append(np.dstack([g8, g8, g8, a8]))
        rows.append(np.concatenate(row, axis=1))
    img = np.concatenate(rows, axis=0)
    Image.fromarray(img, "RGBA").save(os.path.join(OUT, name + ".png"), optimize=True)
    return img


# --------------------------------------------------------------------------------------------------------------------
# the textures, the manifest
# --------------------------------------------------------------------------------------------------------------------

TEXTURES = [
    dict(name="te5_billow", kind="billow", texKey="billow", size="1024x1024", layout="Grid4x4", mode="OneShot",
         purpose="P4a the void's dense ink smoke and P4b the moon's grey-silver smoke (one puff per particle life)"),
    dict(name="te5_wisp", kind="wisp", texKey="wisp", size="1024x1024", layout="Grid4x4", mode="OneShot",
         purpose="P11 silver wisps rising off the wearer's shoulders and back"),
    dict(name="te5_mistbank", kind="mist", texKey="mistbank", size="512x512", layout="None", mode=None,
         purpose="P7 the low mist bank round the dais rim"),
]


def build(names, over, procs, log=print):
    for spec in TEXTURES:
        nm = spec["name"]
        if nm not in names:
            continue
        t0 = time.time()
        if spec["kind"] == "mist":
            P = dict(MIST, **over.get("mist", {}))
            Pm, Am = render_mist(P)
            (Pt,), ref = tone([Pm], [Am], P["gamma"], (0, 0))
            finish(nm, [Pt], [Am], (1, 1), seed=73)
        else:
            base = BILLOW if spec["kind"] == "billow" else WISP
            P = dict(base, **over.get(spec["kind"], {}))
            Ps, As = render_flipbook(spec["kind"], P, procs=procs, log=log)
            Pt, ref = tone(Ps, As, P["gamma"], P["ref_frames"])
            finish(nm, Pt, As, (4, 4), seed=71 if spec["kind"] == "billow" else 72)
        log(f"{nm}.png  {os.path.getsize(os.path.join(OUT, nm + '.png')) / 1024:.0f} KB  (exposure ref {ref:.3f}, "
            f"{time.time() - t0:.1f}s)")


def _sha(path):
    import hashlib
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


NOTES = {
    "te5_billow": (
        "Flipbook 4x4 OneShot: frame k shows the puff at life fraction (k + 0.5) / 16. A volumetric puff ray-marched in 3D "
        "(Beer-Lambert, key light upper front left with a shadow march, multiple-scattering lift, rim light from behind, "
        "sky from above): born dense and compact (visible radius ~0.19 of the cell), billows out in rolling cauliflower "
        "lobes (radius ~0.38 by frame 11), softens, and from frame ~10 thins into curling veils (its own mean alpha falls "
        "~75 % from the peak at frame 9 to frame 15). Opaque core (alpha 1) in frames 0-10. Baked light comes from the upper left: "
        "keep the particle's Rotation within about +-20 deg (not 0-360) or the light turns with it. The puff grows inside "
        "its cell, so the emitter's Size curve should grow less than for te5_smoke (see the recommended settings)."),
    "te5_wisp": (
        "Flipbook 4x4 OneShot (life ~1.6-2.2 s = 7-10 fps): seven thin twisted ribbons of smoke advected through curl "
        "noise and buoyancy -- born as a small tuft low in the cell (~0.15 of it), drawn up into tall incense-like curling "
        "tendrils (bright where a fold is edge-on, a veil where it is face-on), then spreading and thinning (its own mean "
        "alpha falls ~60 % from frame 9 to 15). OneShot, not Loop: the wisp's life (tuft -> curls -> fade) is the "
        "particle's, every particle starts small at the body, and a loop would have to fold back on itself (a visible "
        "cycle at 8-10 fps). It rises toward the TOP of the cell: keep Rotation within about +-15 deg (P11). For a "
        "strand of many small particles (P16) any rotation is fine."),
    "te5_mistbank": (
        "One image (FlipbookLayout None): a soft low fog bank ~0.8 of the image wide and ~0.3 tall, densest along its "
        "middle line (where the floor cuts a particle born on it), billowy and thinning upward, lit from above, in soft "
        "horizontal layers. A single image because the mist lives 6-8 s: a flipbook at 2-3 fps would step visibly. Keep "
        "Rotation within about +-5 deg so the bank stays level."),
}


def write_manifest():
    path = os.path.join(OUT, "manifest.json")
    old = {}
    if os.path.exists(path):
        try:
            for e in json.load(open(path)):
                old[e.get("name")] = e
        except Exception:
            old = {}
    out = []
    for spec in TEXTURES:
        nm = spec["name"]
        f = os.path.join(OUT, nm + ".png")
        if not os.path.exists(f):
            continue
        sha = _sha(f)
        prev = old.get(nm, {})
        uid = prev.get("uploadedId") if prev.get("sha256") == sha else None   # (an id is kept only for the same bytes)
        if prev.get("uploadedId") and uid is None:
            print(f"  note: {nm}.png changed, so its old uploadedId {prev['uploadedId']} was dropped: upload it again")
        notes = NOTES[nm]
        e = dict(name=nm, file=nm + ".png", repoPath=f"{REPO_DIR}/{nm}.png", texKey=spec["texKey"],
                 fallbackTexKey="puff", size=spec["size"], layout=spec["layout"], mode=spec["mode"],
                 purpose=spec["purpose"], uploadedId=uid, notes=notes, sha256=sha)
        out.append(e)
    with open(path, "w") as fh:
        json.dump(out, fh, indent=1)
        fh.write("\n")
    return path


# --------------------------------------------------------------------------------------------------------------------
# contact sheets (sheets/): over the night-ish dark and the bright day sky, frames, in-game sizes, tints, GIFs,
# before/after against the old te5_smoke
# --------------------------------------------------------------------------------------------------------------------

INK, SILVER, WHITE = (14, 14, 19), (176, 176, 178), (248, 249, 255)


def _font(sz):
    for fp in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf",
               "/Library/Fonts/Arial.ttf"):
        if os.path.exists(fp):
            return ImageFont.truetype(fp, sz)
    return ImageFont.load_default()


def label(im, text, xy, sz=14, fill=(235, 235, 240)):
    d = ImageDraw.Draw(im)
    f = _font(sz)
    d.text((xy[0] + 1, xy[1] + 1), text, font=f, fill=(0, 0, 0))
    d.text(xy, text, font=f, fill=fill)


def load_png(path):
    return np.asarray(Image.open(path).convert("RGBA"), F32) / 255.0


def cell_of(img, g, k):
    c = img.shape[0] // g
    r, q = divmod(k, g)
    return img[r * c:(r + 1) * c, q * c:(q + 1) * c]


def resize_premult(img, w, h):
    """Resize as the GPU shows it: premultiplied; BOX when minifying (a mip level), bicubic when magnifying."""
    a = img[..., 3]
    p = img[..., :3] * a[..., None]
    mode = Image.BOX if (w < img.shape[1] or h < img.shape[0]) else Image.BICUBIC

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

    def put(self, tex, cx, cy, size, color=(255, 255, 255), transp=0.0, le=0.0, br=1.0, rot=0.0):
        w = max(1, int(round(size)))
        t = resize_premult(tex, w, w)
        if rot:
            pad = int(math.ceil(w * 0.25))
            t = rotate_rgba(np.pad(t, ((pad, pad), (pad, pad), (0, 0))), rot)
        th, tw = t.shape[:2]
        x0, y0 = int(round(cx - tw / 2)), int(round(cy - th / 2))
        H, W = self.rgb.shape[:2]
        xa, ya, xb, yb = max(0, x0), max(0, y0), min(W, x0 + tw), min(H, y0 + th)
        if xb <= xa or yb <= ya:
            return
        sub = t[ya - y0:yb - y0, xa - x0:xb - x0]
        a = sub[..., 3:4] * (1.0 - transp)
        src = sub[..., :3] * (np.asarray(color, F32) / 255.0 * br)
        dst = self.rgb[ya:yb, xa:xb]
        self.rgb[ya:yb, xa:xb] = src * a + dst * (1.0 - a * (1.0 - le))

    def put_plain(self, tex, x, y):
        h, w = tex.shape[:2]
        a = tex[..., 3:4]
        self.rgb[y:y + h, x:x + w] = tex[..., :3] * a + self.rgb[y:y + h, x:x + w] * (1.0 - a)

    def image(self):
        return Image.fromarray((np.clip(self.rgb, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")


def sky_bg(w, h, seed):
    """Day backdrop: the cyan sky with one soft white cloud bank (the hardest place for white smoke to read)."""
    rng = np.random.default_rng(seed)
    rgb = np.ones((h, w, 3), F32) * (np.asarray(BG_SKY, F32) / 255.0)
    yy, xx = np.mgrid[0:h, 0:w].astype(F32)
    n = gblur(rng.standard_normal((h // 8 + 1, w // 8 + 1)).astype(F32), 2.0)
    n = np.asarray(Image.fromarray(n, "F").resize((w, h), Image.BICUBIC), F32)
    cloud = np.clip(0.5 + 1.2 * n - 1.4 * ((xx / w - 0.8) ** 2 + (yy / h - 0.22) ** 2) * 3.0, 0, 1)
    cloud = sstep(0.25, 0.75, cloud)[..., None]
    return rgb * (1 - 0.85 * cloud) + np.asarray([0.93, 0.95, 0.97], F32) * 0.85 * cloud


def seq_at(kps, t):
    """A NumberSequence [(t, v), ...] at t."""
    for (t0, v0), (t1, v1) in zip(kps, kps[1:]):
        if t <= t1:
            return v0 + (v1 - v0) * (t - t0) / max(t1 - t0, 1e-9)
    return kps[-1][1]


# Emitter settings for the in-game sheets: the module's current ones (with te5_smoke) and the recommended ones (with
# the new textures). Units: studs, seconds; dir = emission direction on screen (radians: 0 = right, pi/2 = up) +- spread.
EMIT_OLD = {
    "void": dict(rate=10, life=(3.5, 4.5), size=[(0, 5), (1, 14)], tr=[(0, 1), (0.18, 0.08), (0.7, 0.32), (1, 1)],
                 speed=(1.4, 2.4), drag=0.35, acc=0.4, color=INK, le=(0, 0), br=(1, 1), rot=(0, 360), rots=(-25, 25),
                 grid=4, src_r=2.6),
    "moon": dict(rate=5, life=(3.5, 4.5), size=[(0, 3.5), (1, 9)], tr=[(0, 1), (0.2, 0.32), (0.7, 0.55), (1, 1)],
                 speed=(0.9, 1.5), drag=0.35, acc=0.3, color=SILVER, le=(0.1, 0.4), br=(1, 1), rot=(0, 360),
                 rots=(-20, 20), grid=4, src_r=3.0),
    "wisps": dict(rate=7, life=(1.6, 2.2), size=[(0, 1.2), (1, 3.4)], tr=[(0, 1), (0.2, 0.32), (0.6, 0.55), (1, 1)],
                  speed=(1.5, 2.5), drag=0.0, acc=1.0, color=(200, 202, 208), le=(0.2, 0.6), br=(1.2, 2.0),
                  rot=(0, 360), rots=(-40, 40), grid=4, src_r=0.0),
    "mist": dict(rate=2.5, life=(6, 8), size=[(0, 8), (1, 14)], tr=[(0, 1), (0.3, 0.8), (0.7, 0.82), (1, 1)],
                 speed=(0.1, 0.25), drag=0.0, acc=0.0, color=(205, 209, 220), le=(0, 0), br=(1, 1), rot=(0, 360),
                 rots=(-6, 6), grid=4, src_r=0.0),
}
EMIT_NEW = {
    "void": dict(EMIT_OLD["void"], size=[(0, 7), (0.5, 11.5), (1, 14)], tr=[(0, 1), (0.07, 0.0), (0.8, 0.06), (1, 1)],
                 color=(24, 24, 30), rot=(-20, 20), rots=(-6, 6), br=(1.0, 2.2)),
    "moon": dict(EMIT_OLD["moon"], size=[(0, 5), (0.5, 8), (1, 10)], tr=[(0, 1), (0.08, 0.12), (0.8, 0.25), (1, 1)],
                 rot=(-20, 20), rots=(-5, 5), le=(0.0, 0.3), br=(1.0, 1.4)),
    "wisps": dict(EMIT_OLD["wisps"], size=[(0, 2.2), (1, 4.6)], tr=[(0, 1), (0.2, 0.1), (0.75, 0.2), (1, 1)],
                  rot=(-15, 15), rots=(-10, 10), le=(0.2, 0.4), br=(1.2, 1.4)),
    "mist": dict(EMIT_OLD["mist"], size=[(0, 9), (1, 15)], tr=[(0, 1), (0.3, 0.55), (0.7, 0.6), (1, 1)],
                 rot=(-4, 4), rots=(-2, 2), grid=1),
}


def sim_emitter(cp, tex, e, ox, oy, pps, night, seed, T=30.0, dir_fn=None, spawn_fn=None):
    """Draw every particle of an emitter alive at time T (births on a jittered lattice at 'rate'), oldest first."""
    rng = np.random.default_rng(seed)
    g = e["grid"]
    n = g * g
    le = e["le"][1 if night else 0]
    br = e["br"][1 if night else 0]
    parts = []
    k0 = int((T - e["life"][1]) * e["rate"]) - 1
    for k in range(k0, int(T * e["rate"]) + 1):
        r = np.random.default_rng(seed * 100003 + k)
        tau = (k + r.random()) / e["rate"]
        L = r.uniform(*e["life"])
        age = T - tau
        if age < 0 or age >= L:
            continue
        f = age / L
        ang = dir_fn(r) if dir_fn else r.uniform(0, 2 * math.pi)
        sp = r.uniform(*e["speed"])
        kd = e["drag"] * math.log(2.0)
        disp = sp * (1 - math.exp(-kd * age)) / kd if kd > 0 else sp * age
        sx, sy = spawn_fn(r) if spawn_fn else (math.cos(ang) * e["src_r"], math.sin(ang) * e["src_r"])
        x = ox + (sx + math.cos(ang) * disp) * pps
        y = oy - (sy + math.sin(ang) * disp + 0.5 * e["acc"] * age * age) * pps
        size = seq_at(e["size"], f) * pps
        tr = seq_at(e["tr"], f)
        rot = r.uniform(*e["rot"]) + r.uniform(*e["rots"]) * age
        frame = min(n - 1, int(f * n)) if n > 1 else 0
        parts.append((tau, x, y, size, tr, rot, frame))
    for tau, x, y, size, tr, rot, frame in sorted(parts):
        t = cell_of(tex, g, frame) if g > 1 else tex
        cp.put(t, x, y, size, e["color"], tr, le, br, rot=-rot)


def ingame_panel(which, tex, e, night, w, h, seed):
    if night:
        cp = Comp(w, h, BG_DARK)
    else:
        cp = Comp(w, h, BG_SKY)
        cp.rgb[:] = sky_bg(w, h, seed)
    if which == "void":                # the void's ink smoke boiling off a black orb (16 px per stud: the studio camera)
        pps = 16.0
        sim_emitter(cp, tex, e, w * 0.42, h * 0.62, pps, night, seed)
        yy, xx = np.mgrid[0:h, 0:w]
        orb = (np.hypot(xx - w * 0.42, yy - h * 0.62) < 2.6 * pps)
        cp.rgb[orb] = 0.0
    elif which == "moon":
        pps = 16.0
        sim_emitter(cp, tex, e, w * 0.5, h * 0.6, pps, night, seed)
        yy, xx = np.mgrid[0:h, 0:w]
        d = np.hypot(xx - w * 0.5, yy - h * 0.6) / (3.0 * pps)
        disc = d < 1.0
        cp.rgb[disc] = (0.86 - 0.18 * d[disc] ** 2)[..., None] * np.array([1.0, 1.0, 1.02], F32)
    elif which == "wisps":             # rising off a torso (40 px per stud: a close camera)
        pps = 40.0
        x0, y0 = w * 0.5, h * 0.78
        body = np.zeros((h, w), bool)
        yy, xx = np.mgrid[0:h, 0:w]
        body |= (np.abs(xx - x0) < 1.0 * pps) & (yy > y0 - 1.0 * pps)          # torso
        body |= (np.abs(xx - x0) < 0.5 * pps) & (np.abs(yy - (y0 - 1.6 * pps)) < 0.5 * pps)   # head
        cp.rgb[body] = np.array([0.16, 0.16, 0.19], F32)
        sim_emitter(cp, tex, e, x0, y0 - 0.6 * pps, pps, night, seed,
                    dir_fn=lambda r: math.pi / 2 + math.radians(r.uniform(-20, 20)),
                    spawn_fn=lambda r: (r.uniform(-1.0, 1.0), r.uniform(-0.5, 1.0)))
    else:                              # the mist bank on the dais rim (16 px per stud), the floor hides the lower half
        pps = 16.0
        x0, y0 = w * 0.5, h * 0.66
        sim_emitter(cp, tex, e, x0, y0, pps, night, seed, dir_fn=lambda r: math.pi / 2,
                    spawn_fn=lambda r: (r.uniform(-12, 12), 0.0))
        cp.rgb[int(y0):] = np.array([0.30, 0.31, 0.34] if night else [0.80, 0.74, 0.58], F32)
        cp.rgb[int(y0):int(y0) + 3] = np.array([0.75, 0.75, 0.78], F32)
    return cp.image()


def make_sheets(names):
    os.makedirs(SHEETS, exist_ok=True)
    tex = {nm: load_png(os.path.join(OUT, nm + ".png")) for nm in names if os.path.exists(os.path.join(OUT, nm + ".png"))}
    old = load_png(OLD_SMOKE) if os.path.exists(OLD_SMOKE) else None
    out = []
    # 1. overview: each texture whole, over the dark and the sky
    for bgname, bg in (("dark", BG_DARK), ("sky", BG_SKY)):
        tile, pad = 640, 16
        im = Image.new("RGB", (pad + len(tex) * (tile + pad), tile + 2 * pad + 22), (24, 25, 30))
        for i, (nm, t) in enumerate(tex.items()):
            cp = Comp(tile, tile, bg)
            if bgname == "sky":
                cp.rgb[:] = sky_bg(tile, tile, 5 + i)
            cp.put_plain(resize_premult(t, tile, tile), 0, 0)
            im.paste(cp.image(), (pad + i * (tile + pad), pad + 22))
            label(im, f"{nm}.png  {t.shape[1]}x{t.shape[0]}", (pad + i * (tile + pad), 4))
        p = os.path.join(SHEETS, f"overview_{bgname}.png")
        im.save(p, optimize=True)
        out.append(p)
    # 2. frames strip: every flipbook frame (each 256 px cell at 128 px) with its mean alpha, white, dark and sky
    books = [nm for nm in tex if tex[nm].shape[0] == 1024]
    cw = 128
    im = Image.new("RGB", (16 * cw + 17 * 4, len(books) * 2 * (cw + 22) + 8), (24, 25, 30))
    y = 4
    for nm in books:
        for bgname, bg in (("dark", BG_DARK), ("sky", BG_SKY)):
            label(im, f"{nm}  over {bgname}  (frame: mean alpha)", (6, y), 13)
            for k in range(16):
                c = cell_of(tex[nm], 4, k)
                cp = Comp(cw, cw, bg)
                cp.put_plain(resize_premult(c, cw, cw), 0, 0)
                x = 4 + k * (cw + 4)
                im.paste(cp.image(), (x, y + 18))
                label(im, f"{k}: {c[..., 3].mean():.2f}", (x + 3, y + 20), 11)
            y += cw + 22
    p = os.path.join(SHEETS, "frames.png")
    im.save(p, optimize=True)
    out.append(p)
    # 3. tints: ink, silver, white, over the dark and the sky, a few frames of each flipbook + the mist bank
    picks = [(nm, k) for nm in books for k in ((1, 5, 9, 13) if nm == "te5_billow" else (2, 6, 10, 14))]
    if "te5_mistbank" in tex:
        picks.append(("te5_mistbank", None))
    tw = 160
    tints = (("ink (14,14,19)", INK), ("silver (176,176,178)", SILVER), ("white", WHITE))
    im = Image.new("RGB", (180 + len(picks) * (tw + 4), 6 * (tw + 4) + 30), (24, 25, 30))
    for j, (tn, col) in enumerate(tints):
        for b, (bgname, bg) in enumerate((("dark", BG_DARK), ("sky", BG_SKY))):
            row = j * 2 + b
            y = 26 + row * (tw + 4)
            label(im, f"{tn}", (6, y + 50), 13)
            label(im, f"over {bgname}", (6, y + 70), 13)
            for i, (nm, k) in enumerate(picks):
                c = cell_of(tex[nm], 4, k) if k is not None else tex[nm]
                cp = Comp(tw, tw, bg)
                cp.put(c, tw / 2, tw / 2, tw, col)
                im.paste(cp.image(), (180 + i * (tw + 4), y))
    for i, (nm, k) in enumerate(picks):
        label(im, f"{nm.replace('te5_', '')} {'' if k is None else 'f%d' % k}", (184 + i * (tw + 4), 6), 12)
    p = os.path.join(SHEETS, "tints.png")
    im.save(p, optimize=True)
    out.append(p)
    # 4. in game: particles at their real on-screen size, recommended settings, day and night
    kinds = [("void", "te5_billow", "P4a void ink smoke (Color 24,24,30)"), ("moon", "te5_billow", "P4b moon silver smoke"),
             ("wisps", "te5_wisp", "P11 body wisps (40 px/stud)"), ("mist", "te5_mistbank", "P7 rim mist bank")]
    kinds = [k for k in kinds if k[1] in tex]
    pw, ph = 480, 360
    for night in (False, True):
        im = Image.new("RGB", (len(kinds) * (pw + 6) + 6, ph + 40), (24, 25, 30))
        label(im, ("NIGHT" if night else "DAY") + "  - the new textures at their in-game size with the recommended emitter "
              "settings (16 px per stud = the studio camera at 40 studs)", (6, 4), 14)
        for i, (which, nm, title) in enumerate(kinds):
            pan = ingame_panel(which, tex[nm], EMIT_NEW[which], night, pw, ph, 11 + i)
            im.paste(pan, (6 + i * (pw + 6), 32))
            label(im, title, (12 + i * (pw + 6), 36), 13)
        p = os.path.join(SHEETS, f"ingame_{'night' if night else 'day'}.png")
        im.save(p, optimize=True)
        out.append(p)
    # 5. before / after: the old te5_smoke and the new te5_billow, frame by frame and in game (same emitters)
    if old is not None and "te5_billow" in tex:
        cw = 112
        im = Image.new("RGB", (16 * (cw + 4) + 8, 4 * (cw + 4) + 2 * (ph + 30) + 60), (24, 25, 30))
        y = 4
        for nm, t in (("before: te5_smoke (smoke5)", old), ("after: te5_billow", tex["te5_billow"])):
            for bgname, bg in (("dark", BG_DARK), ("sky", BG_SKY)):
                label(im, f"{nm}  over {bgname}", (6, y), 13)
                for k in range(16):
                    cp = Comp(cw, cw, bg)
                    cp.put_plain(resize_premult(cell_of(t, 4, k), cw, cw), 0, 0)
                    im.paste(cp.image(), (4 + k * (cw + 4), y + 16))
                y += cw + 20
        for night in (False, True):
            for i, (which, t, e, title) in enumerate((
                    ("void", old, EMIT_OLD["void"], "before: te5_smoke, the module's P4a settings"),
                    ("void", tex["te5_billow"], EMIT_NEW["void"], "after: te5_billow, recommended P4a settings"),
                    ("moon", old, EMIT_OLD["moon"], "before: te5_smoke, P4b"),
                    ("moon", tex["te5_billow"], EMIT_NEW["moon"], "after: te5_billow, P4b"))):
                pan = ingame_panel(which, t, e, night, 440, ph, 3 + i)
                x = 6 + i * 446
                im.paste(pan, (x, y + 18))
                label(im, ("night  " if night else "day  ") + title, (x + 6, y + 22), 12)
            y += ph + 24
        im = im.crop((0, 0, im.width if im.width >= 4 * 446 + 6 else 4 * 446 + 6, y + 4))
        p = os.path.join(SHEETS, "before_after.png")
        im.save(p, optimize=True)
        out.append(p)
    # 6. GIFs: each flipbook at its in-game rate, white on dark | silver on dark | ink on the sky | white on the sky
    for nm, ms in (("te5_billow", 250), ("te5_wisp", 120)):
        if nm not in tex:
            continue
        frames = []
        tw = 200
        for k in range(16):
            row = Image.new("RGB", (4 * tw, tw + 18), (24, 25, 30))
            for i, (bg, col) in enumerate(((BG_DARK, WHITE), (BG_DARK, SILVER), (BG_SKY, INK), (BG_SKY, WHITE))):
                cp = Comp(tw, tw, bg)
                cp.put(cell_of(tex[nm], 4, k), tw / 2, tw / 2, tw, col)
                row.paste(cp.image(), (i * tw, 18))
            label(row, f"{nm}  frame {k:2d}  ({ms} ms/frame = its in-game OneShot rate)", (4, 1), 12)
            frames.append(row.quantize(colors=255, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG))
        p = os.path.join(SHEETS, nm + ".gif")
        frames[0].save(p, save_all=True, append_images=frames[1:], duration=ms, loop=0, optimize=False)
        out.append(p)
    return out


# --------------------------------------------------------------------------------------------------------------------
# numeric self-tests on the PNGs (--check)
# --------------------------------------------------------------------------------------------------------------------


def frame_change(img):
    """Per step k -> k+1: mean |dA| over the cell and the 99th percentile of |dA| (after a 5x5 box blur)."""
    A = [cell_of(img, 4, k)[..., 3] for k in range(16)]

    def box(a, r=2):
        p = np.pad(a, r, mode="edge")
        c = np.cumsum(np.cumsum(p, 0), 1)
        c = np.pad(c, ((1, 0), (1, 0)))
        n = 2 * r + 1
        return (c[n:, n:] - c[:-n, n:] - c[n:, :-n] + c[:-n, :-n]) / (n * n)
    mean = [float(np.abs(A[k + 1] - A[k]).mean()) for k in range(15)]
    p99 = [float(np.percentile(np.abs(box(A[k + 1]) - box(A[k])), 99)) for k in range(15)]
    return mean, p99, [float(a.mean()) for a in A]


def check(names=None):
    names = names or [t["name"] for t in TEXTURES]
    ok_all = True

    def ok(cond, msg):
        nonlocal ok_all
        ok_all &= bool(cond)
        print(("  ok    " if cond else "  FAIL  ") + msg)
    print("checks:")
    for spec in TEXTURES:
        nm = spec["name"]
        if nm not in names:
            continue
        f = os.path.join(OUT, nm + ".png")
        if not os.path.exists(f):
            ok(False, f"{nm}.png exists")
            continue
        im = Image.open(f)
        w, h = (int(x) for x in spec["size"].split("x"))
        ok(im.mode == "RGBA" and im.size == (w, h), f"{nm}: RGBA {im.size[0]}x{im.size[1]} (want {w}x{h})")
        a = np.asarray(im.convert("RGBA"))
        ok(bool((a[..., 0] == a[..., 1]).all() and (a[..., 1] == a[..., 2]).all()), f"{nm}: monochrome (R = G = B everywhere)")
        g = 4 if spec["layout"] == "Grid4x4" else 1
        c = a.shape[0] // g
        b = int(math.ceil(0.0625 * c))
        border = np.ones((c, c), bool)
        border[b:-b, b:-b] = False
        bmax = max(int(cell_of(a, g, k)[..., 3][border].max()) for k in range(g * g))
        ok(bmax == 0, f"{nm}: alpha exactly 0 on every cell's outer {b} px (6.25 %) (max {bmax})")
        # no clipping by that border: the ring just inside it stays faint
        ring = np.zeros((c, c), bool)
        ring[b:b + 4, b:-b] = ring[-b - 4:-b, b:-b] = ring[b:-b, b:b + 4] = ring[b:-b, -b - 4:-b] = True
        rmax = max(int(cell_of(a, g, k)[..., 3][ring].max()) for k in range(g * g))
        ok(rmax <= 8, f"{nm}: nothing is cut by the padding (alpha <= 8/255 just inside it: max {rmax})")
        # bleed: transparent pixels next to visible ones carry the visible grey (no black fringe for the mip-maps)
        worst = 0.0
        for k in range(g * g):
            cc = cell_of(a, g, k).astype(F32)
            vis = cc[..., 3] > 64
            tr = cc[..., 3] == 0
            near = tr & (np.roll(vis, 1, 0) | np.roll(vis, -1, 0) | np.roll(vis, 1, 1) | np.roll(vis, -1, 1))
            if near.any() and vis.any():
                gv = float(np.median(cc[..., 0][vis]))
                worst = max(worst, float(np.percentile(np.abs(cc[..., 0][near] - gv), 50)))
        ok(worst < 90, f"{nm}: grey bled under alpha 0 (median |grey - visible grey| next to the smoke: {worst:.0f}/255)")
        ok(len(np.unique(a[..., 3])) >= 200, f"{nm}: smooth alpha ({len(np.unique(a[..., 3]))} levels, dithered)")
        if g == 4:
            mean, p99, am = frame_change(a.astype(F32) / 255.0)
            ok(max(mean) <= 0.045, f"{nm}: gentle frame-to-frame change: mean |dA| per step <= 0.045 (max "
               f"{max(mean):.3f} at {int(np.argmax(mean))}->{int(np.argmax(mean)) + 1})")
            ok(min(mean) >= 0.002, f"{nm}: no repeated frames (min mean |dA| {min(mean):.4f})")
            pk = int(np.argmax(am))
            ok(am[15] <= 0.45 * am[pk], f"{nm}: it dissipates by itself (mean alpha peak {am[pk]:.3f} at frame {pk} -> "
               f"{am[15]:.3f} at frame 15)")
            drops = [am[k] - am[k + 1] for k in range(pk, 15)]
            ok(max(drops) <= 0.05 and all(d >= -0.004 for d in drops), f"{nm}: it fades smoothly after the peak "
               f"(largest drop {max(drops):.3f} a frame)")
            if spec["kind"] == "billow":
                cores = []
                for k in range(11):
                    cc = cell_of(a, 4, k)[..., 3].astype(F32) / 255
                    cores.append(float(np.percentile(cc, 99.5)))
                ok(min(cores) >= 0.97, f"{nm}: a dense opaque core in frames 0-10 (p99.5 alpha >= 0.97: min {min(cores):.2f})")
                lum = []
                for k in range(2, 10):
                    cc = cell_of(a, 4, k).astype(F32) / 255
                    m = cc[..., 3] > 0.9
                    lum.append(np.percentile(cc[..., 0][m], 95) - np.percentile(cc[..., 0][m], 5))
                ok(min(lum) >= 0.45, f"{nm}: real light and shadow in the opaque smoke (p5-p95 grey spread >= 0.45 in "
                   f"frames 2-9: min {min(lum):.2f})")
        else:
            ok(float(a[..., 3].max()) / 255 >= 0.6, f"{nm}: a visible core (max alpha {a[..., 3].max() / 255:.2f})")
    return ok_all


# --------------------------------------------------------------------------------------------------------------------


def main():
    global OUT, SHEETS
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--only", help="comma list of texture names (te5_billow,te5_wisp,te5_mistbank) or kinds")
    ap.add_argument("--no-sheets", action="store_true")
    ap.add_argument("--check", action="store_true", help="only the numeric self-tests on the PNGs")
    ap.add_argument("--out", help="write everything here instead of next to this script (tuning)")
    ap.add_argument("--set", action="append", default=[], help="override a parameter: kind.key=JSON (billow.sigma=80)")
    ap.add_argument("--procs", type=int, default=min(4, os.cpu_count() or 1))
    a = ap.parse_args()
    if a.out:
        OUT = os.path.abspath(a.out)
        os.makedirs(OUT, exist_ok=True)
    SHEETS = os.path.join(OUT, "sheets")
    all_names = [t["name"] for t in TEXTURES]
    names = all_names
    if a.only:
        want = [s.strip() for s in a.only.split(",") if s.strip()]
        names = [t["name"] for t in TEXTURES if t["name"] in want or t["kind"] in want or t["texKey"] in want]
    if a.check:
        sys.exit(0 if check(names) else 1)
    over = {}
    for s in a.set:
        k, v = s.split("=", 1)
        kind, key = k.split(".", 1)
        over.setdefault(kind, {})[key] = json.loads(v)
    t0 = time.time()
    build(names, over, a.procs)
    print("manifest:", write_manifest())
    if not a.no_sheets:
        for p in make_sheets(all_names):
            print("sheet:", os.path.relpath(p, OUT))
    good = check(names)
    print(f"done in {time.time() - t0:.0f}s")
    sys.exit(0 if good else 1)


SHEETS = os.path.join(OUT, "sheets")

if __name__ == "__main__":
    main()
