#!/usr/bin/env python3
# THE END (1 in 1,000,000,000) -- equipped aura, pass 5 "The Last Clock" -- texture group "surfaces".
#
# Spec: docs/the-end/pass5-spec.md, section 16.2 (group "surfaces"). 11 textures:
#   te5_dial_inlay  te5_subdial  te5_accretion  te5_galaxy_floor  te5_galaxy_arms  te5_galaxy_core
#   te5_engraving   te5_halo     te5_stream
#   te5_moon        te5_star_window  (added in review round 1: docs/the-end/pass5-build-notes.md)
#   (te5_ribbon was dropped in review round 3: the void's ink ribbon became the lensed band, two beams that use
#   te5_stream. Its generator is in the git history.)
#
# Only python3 + numpy + PIL (runs the same on Milo's Mac and in the cloud). Deterministic: every random source is
# seeded, so a re-run gives byte-identical PNGs (on the same machine). te5_lunar_data.py (next to this file) holds the
# Moon's near side as data. A full run takes about 4 minutes on 4 CPUs.
#
#   python3 make_te5_surfaces.py              # all textures + contact sheets (sheets/) + checks
#   python3 make_te5_surfaces.py --no-sheets  # textures only
#   python3 make_te5_surfaces.py --only te5_halo,te5_stream
#   python3 make_te5_surfaces.py --check      # only the numerical checks on the PNGs
#   python3 make_te5_surfaces.py --before DIR # also sheets/before_after_*.png against older PNGs in DIR
#
# How the images are made (film-quality rules from the spec):
#   * Everything is rendered at 2x (SS) and box-filtered down, in PREMULTIPLIED alpha, so anti-aliased edges are exact.
#   * Line art (dial, sub-dial, engraving) is drawn from exact signed-distance fields (circles, boxes, convex
#     polygons, the spiral), so every stroke has a true 1 px anti-aliased edge and its ink outline follows it exactly.
#   * The photographic ones are simulated, not painted: the moon is a lit globe (albedo + height field on the sphere,
#     lunar-Lambert reflectance, cast shadows); the accretion disc is turbulence sheared by a Kepler orbit; the galaxies
#     are density-wave spirals in orthogonal log-spiral coordinates (star clouds, knots, braided dust lanes, resolved
#     stars); the star window is ~22,000 stars of real magnitudes convolved with a point-spread function. All noise is
#     band-limited, so stretched or sheared features never alias into dashes.
#   * After downsampling the colour is un-premultiplied and BLED into the fully transparent pixels (pull-push fill), so
#     Roblox's bilinear filtering and mip-maps never mix black into an edge: no dark or light fringes.
#   * Smooth gradients (halo, discs) are dithered by +-1 LSB before 8-bit quantisation: no banding.
#   * Monochrome lock: every pixel has R == G and R <= B <= R + 20 (a faint cool tint at most; the rebuilt seven are
#     pure grey, R == G == B).
import argparse, json, math, os, sys, time
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import te5_lunar_data as LUNAR      # the Moon's near side as data (te5_moon)

OUT = os.path.dirname(os.path.abspath(__file__))
SHEETS = os.path.join(OUT, "sheets")
SS = 2                     # supersampling factor
F32 = np.float32
BIG = F32(1e6)

# --------------------------------------------------------------------------------------------------------------------
# small maths helpers
# --------------------------------------------------------------------------------------------------------------------

def sstep(e0, e1, x):
    """smoothstep; works for e0 > e1 too (falling edge)."""
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def wrap_pi(a):
    return (a + np.pi) % (2.0 * np.pi) - np.pi


def screen(*layers):
    """Photographic 'screen' blend of light layers in [0, 1]."""
    out = np.zeros_like(layers[0])
    for l in layers:
        out = 1.0 - (1.0 - out) * (1.0 - np.clip(l, 0.0, 1.0))
    return out


def pchip(xs, ys, x):
    """Monotone cubic (Fritsch-Carlson) interpolation through (xs, ys): smooth, no overshoot, flat at extrema."""
    xs = np.asarray(xs, np.float64); ys = np.asarray(ys, np.float64)
    h = np.diff(xs); dlt = np.diff(ys) / h
    m = np.zeros_like(ys)
    for i in range(1, len(xs) - 1):
        if dlt[i - 1] * dlt[i] > 0:
            w1 = 2 * h[i] + h[i - 1]; w2 = h[i] + 2 * h[i - 1]
            m[i] = (w1 + w2) / (w1 / dlt[i - 1] + w2 / dlt[i])
    # end slopes 0 (the curve starts and ends flat: no kink where alpha meets 0)
    xc = np.clip(x, xs[0], xs[-1])
    k = np.clip(np.searchsorted(xs, xc) - 1, 0, len(xs) - 2)
    t = (xc - xs[k]) / h[k]
    h00 = (2 * t ** 3 - 3 * t ** 2 + 1); h10 = (t ** 3 - 2 * t ** 2 + t)
    h01 = (-2 * t ** 3 + 3 * t ** 2); h11 = (t ** 3 - t ** 2)
    return (h00 * ys[k] + h10 * h[k] * m[k] + h01 * ys[k + 1] + h11 * h[k] * m[k + 1]).astype(F32)


def gblur(a, sigma):
    """Separable Gaussian blur (numpy only), zero padding. sigma in pixels."""
    if sigma <= 0:
        return a
    r = int(math.ceil(sigma * 3.5))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2).astype(F32); k /= k.sum()
    out = a.astype(F32)
    for ax in (0, 1):
        pad = [(0, 0)] * out.ndim; pad[ax] = (r, r)
        p = np.pad(out, pad)
        acc = np.zeros_like(out)
        n = out.shape[ax]
        for i, w in enumerate(k):
            sl = [slice(None)] * out.ndim; sl[ax] = slice(i, i + n)
            acc += w * p[tuple(sl)]
        out = acc
    return out


def noise_periodic(shape, seed, beta=1.0, fmin=1.0, fmax=None, aniso=(1.0, 1.0)):
    """Fractal noise by spectral synthesis: periodic on both axes, mean 0, std 1.
    beta = amplitude fall-off (amp ~ f^-beta); aniso = (fy_scale, fx_scale) stretches the features."""
    H, W = shape
    rng = np.random.default_rng(seed)
    fy = (np.fft.fftfreq(H) * H)[:, None] * aniso[0]
    fx = (np.fft.rfftfreq(W) * W)[None, :] * aniso[1]
    f = np.sqrt(fx * fx + fy * fy)
    amp = np.where(f >= fmin, np.power(np.maximum(f, 1e-6), -beta), 0.0)
    if fmax is not None:
        amp *= np.exp(-(f / fmax) ** 2)
    spec = (rng.standard_normal(amp.shape) + 1j * rng.standard_normal(amp.shape)) * amp
    n = np.fft.irfft2(spec, s=shape)
    n = (n - n.mean()) / (n.std() + 1e-12)
    return n.astype(F32)


def unit01(n, spread=2.2):
    """Map a mean-0/std-1 noise to [0, 1] smoothly (mean 0.5)."""
    return (0.5 + 0.5 * np.tanh(n / spread * 1.5)).astype(F32)


def sample_wrap(tex, y, x):
    """Bilinear sample of a periodic texture at float texel coords (y, x)."""
    H, W = tex.shape
    x0 = np.floor(x); y0 = np.floor(y)
    fx = (x - x0).astype(F32); fy = (y - y0).astype(F32)
    x0 = x0.astype(np.int64) % W; y0 = y0.astype(np.int64) % H
    x1 = (x0 + 1) % W; y1 = (y0 + 1) % H
    return (tex[y0, x0] * (1 - fx) * (1 - fy) + tex[y0, x1] * fx * (1 - fy)
            + tex[y1, x0] * (1 - fx) * fy + tex[y1, x1] * fx * fy).astype(F32)


# --------------------------------------------------------------------------------------------------------------------
# premultiplied image pipeline:  (P, A) at SS resolution  ->  box down  ->  un-premultiply  ->  bleed  ->  8-bit PNG
# --------------------------------------------------------------------------------------------------------------------

def over(top, bottom):
    """Porter-Duff 'over' on premultiplied (P, A) pairs."""
    Pt, At = top; Pb, Ab = bottom
    return Pt + Pb * (1.0 - At)[..., None], At + Ab * (1.0 - At)


def solid(rgb, a):
    """Premultiplied pair for a constant colour with an alpha map."""
    rgb = np.asarray(rgb, F32).reshape(1, 1, 3) / 255.0 if np.ndim(rgb) == 1 else rgb
    return (rgb * a[..., None]).astype(F32), a.astype(F32)


def box_down(P, A, f):
    H, W = A.shape
    P = P.reshape(H // f, f, W // f, f, 3).mean(axis=(1, 3))
    A = A.reshape(H // f, f, W // f, f).mean(axis=(1, 3))
    return P.astype(F32), A.astype(F32)


def _pullpush(P, w):
    H, W = w.shape
    has = w > 0
    if has.all() or H <= 1 or W <= 1:
        tot = w.sum()
        fallback = (P.reshape(-1, 3).sum(0) / tot) if tot > 0 else np.zeros(3, F32)
        return np.where(has[..., None], P / np.maximum(w, 1e-12)[..., None], fallback).astype(F32)
    Hp, Wp = H + (H % 2), W + (W % 2)
    Pp = np.zeros((Hp, Wp, 3), F32); Pp[:H, :W] = P
    wp = np.zeros((Hp, Wp), F32); wp[:H, :W] = w
    P2 = Pp.reshape(Hp // 2, 2, Wp // 2, 2, 3).sum(axis=(1, 3))
    w2 = wp.reshape(Hp // 2, 2, Wp // 2, 2).sum(axis=(1, 3))
    C2 = _pullpush(P2, w2)
    Cup = np.repeat(np.repeat(C2, 2, axis=0), 2, axis=1)[:H, :W]
    return np.where(has[..., None], P / np.maximum(w, 1e-12)[..., None], Cup).astype(F32)


def bleed(C, visible, rings=24):
    """Colour under invisible pixels := colour of the NEAREST visible pixels, so bilinear filtering and mip-maps never
    mix black (or the white core) into an edge: the ring of transparent pixels round an ink outline carries ink.
    Ring-by-ring dilation (mean of the already-filled 8-neighbours) for `rings` px, then pull-push for the rest."""
    filled = visible.copy()
    out = np.where(visible[..., None], C, 0.0).astype(F32)
    nbrs = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
    for _ in range(rings):
        acc = np.zeros_like(out); cnt = np.zeros(filled.shape, F32)
        for dy, dx in nbrs:
            f = np.roll(filled, (dy, dx), axis=(0, 1))
            acc += np.roll(out, (dy, dx), axis=(0, 1)) * f[..., None]
            cnt += f
        new = (~filled) & (cnt > 0)
        if not new.any():
            break
        out[new] = acc[new] / cnt[new][:, None]
        filled |= new
    if not filled.all():
        w = filled.astype(F32)
        out = np.where(filled[..., None], out, _pullpush(out * w[..., None], w))
    return out


def quantise(x, rng, dither):
    v = x * 255.0
    if dither:
        d = (rng.random(x.shape, dtype=F32) - rng.random(x.shape, dtype=F32))   # TPDF, +-1 LSB
        inner = (v > 1.0) & (v < 254.0)        # never dither the first / last LSB: exact 0 and 255 stay exact
        v = np.where(inner, v + d, v)
    return np.clip(np.rint(v), 0, 255).astype(np.uint8)


def finish(name, P, A, dither=False, extra=None, seed=7):
    """Downsample (P, A) from SS, un-premultiply, enforce monochrome, bleed, quantise and save. Returns the RGBA array."""
    P, A = box_down(P, A, SS)
    if extra is not None:          # post-downsample hook working on straight colour (e.g. single-pixel stars)
        C = np.where(A[..., None] > 1e-6, P / np.maximum(A, 1e-6)[..., None], 0.0)
        C, A = extra(C, A)
        P = C * A[..., None]
    A = np.clip(A, 0.0, 1.0)
    C = np.where(A[..., None] > 1e-6, P / np.maximum(A, 1e-6)[..., None], 0.0)
    C = np.clip(C, 0.0, 1.0)
    # monochrome lock: R = G = grey, B in [grey, grey + 20/255]
    g = np.clip(C[..., 0], 0.0, 1.0)
    b = np.clip(C[..., 2], g, np.minimum(1.0, g + 20.0 / 255.0))
    C = np.dstack([g, g, b])
    rng = np.random.default_rng(seed)
    a8 = quantise(A, rng, dither)
    C = bleed(C, a8 > 0)
    rgb8 = quantise(np.clip(C, 0, 1), rng, dither)
    rgb8[..., 1] = rgb8[..., 0]                      # keep R == G exactly after dithering
    rgb8[..., 2] = np.maximum(rgb8[..., 2], rgb8[..., 0])
    img = np.dstack([rgb8, a8])
    Image.fromarray(img, "RGBA").save(os.path.join(OUT, name + ".png"), optimize=True)
    return img


# --------------------------------------------------------------------------------------------------------------------
# signed-distance line-art canvas.  Coordinates: 'r units' with the image centre at 0, +x right, +y UP, r = 1 at the
# image edge.  Distances are kept in SS pixels.  A Layer holds the union (min) of the shapes added to it.
# Clock angles phi are measured clockwise from 12 o'clock: point at radius r = (r sin phi, r cos phi).
# --------------------------------------------------------------------------------------------------------------------

class Canvas:
    def __init__(self, n):
        self.n = n                       # output size (px)
        self.M = n * SS                  # working size
        self.k = self.M / 2.0            # SS px per r unit
        c = (np.arange(self.M, dtype=F32) + 0.5) - self.M / 2.0
        self.xs = c                      # SS px, x right
        self.ys = -c                     # SS px, y up (row 0 is the top)
        self._r = None

    @property
    def r_px(self):
        if self._r is None:
            self._r = np.hypot(self.xs[None, :], self.ys[:, None]).astype(F32)
        return self._r

    def px(self, w_out):
        """output pixels -> SS pixels"""
        return w_out * SS

    def region(self, x0, x1, y0, y1, pad):
        """Index slices + local coordinate grids for a bbox given in SS px (math coords)."""
        M = self.M
        c0 = int(max(0, math.floor(x0 - pad + M / 2.0)))
        c1 = int(min(M, math.ceil(x1 + pad + M / 2.0)))
        r0 = int(max(0, math.floor(M / 2.0 - (y1 + pad))))
        r1 = int(min(M, math.ceil(M / 2.0 - (y0 - pad))))
        if c1 <= c0 or r1 <= r0:
            return None
        X = self.xs[c0:c1][None, :]
        Y = self.ys[r0:r1][:, None]
        return (slice(r0, r1), slice(c0, c1)), X, Y


class Layer:
    def __init__(self, cv, pad_out=6.0):
        self.cv = cv
        self.d = np.full((cv.M, cv.M), BIG, F32)
        self.pad = pad_out * SS          # how far from a shape distances are still needed (ink + AA)

    # --- full-canvas shapes
    def ring(self, R, w_out):
        cv = self.cv
        d = np.abs(cv.r_px - R * cv.k) - cv.px(w_out) / 2.0
        np.minimum(self.d, d, out=self.d)

    # --- local shapes
    def poly(self, verts_r):
        """Convex polygon given in r units (any winding). Exact signed distance."""
        cv = self.cv
        V = np.asarray(verts_r, np.float64) * cv.k
        area = 0.5 * np.sum(V[:, 0] * np.roll(V[:, 1], -1) - np.roll(V[:, 0], -1) * V[:, 1])
        if area < 0:
            V = V[::-1]
        reg = cv.region(V[:, 0].min(), V[:, 0].max(), V[:, 1].min(), V[:, 1].max(), self.pad)
        if reg is None:
            return
        sl, X, Y = reg
        dist = np.full(np.broadcast(X, Y).shape, np.inf, F32)
        inside = np.ones_like(dist, dtype=bool)
        n = len(V)
        for i in range(n):
            ax, ay = V[i]; bx, by = V[(i + 1) % n]
            ex, ey = bx - ax, by - ay
            wx, wy = X - ax, Y - ay
            t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0.0, 1.0)
            dx, dy = wx - ex * t, wy - ey * t
            dist = np.minimum(dist, np.sqrt(dx * dx + dy * dy))
            inside &= (ex * wy - ey * wx) >= 0
        sd = np.where(inside, -dist, dist).astype(F32)
        np.minimum(self.d[sl], sd, out=self.d[sl])

    def box(self, c, axis, half_len, half_w):
        """Rectangle centred at c (r units), long axis 'axis' (unit vector), half sizes in r units."""
        ux, uy = axis; nx, ny = -uy, ux
        cx, cy = c
        self.poly([(cx + ux * half_len + nx * half_w, cy + uy * half_len + ny * half_w),
                   (cx - ux * half_len + nx * half_w, cy - uy * half_len + ny * half_w),
                   (cx - ux * half_len - nx * half_w, cy - uy * half_len - ny * half_w),
                   (cx + ux * half_len - nx * half_w, cy + uy * half_len - ny * half_w)])

    def radial_tick(self, phi, r0, r1, w_out):
        s, c = math.sin(phi), math.cos(phi)
        rm = 0.5 * (r0 + r1)
        self.box((rm * s, rm * c), (s, c), 0.5 * (r1 - r0), 0.5 * w_out / (self.cv.n / 2.0))

    def disc(self, c, R):
        cv = self.cv
        cx, cy = c[0] * cv.k, c[1] * cv.k; Rp = R * cv.k
        reg = cv.region(cx - Rp, cx + Rp, cy - Rp, cy + Rp, self.pad)
        if reg is None:
            return
        sl, X, Y = reg
        sd = (np.sqrt((X - cx) ** 2 + (Y - cy) ** 2) - Rp).astype(F32)
        np.minimum(self.d[sl], sd, out=self.d[sl])

    def field(self, sd):
        """Union with an arbitrary full-canvas signed distance (SS px)."""
        np.minimum(self.d, sd.astype(F32), out=self.d)

    def capsule(self, p0, p1, w_out):
        """Segment p0 -> p1 (r units) with round caps, stroke width w_out output px."""
        cv = self.cv
        ax, ay = p0[0] * cv.k, p0[1] * cv.k; bx, by = p1[0] * cv.k, p1[1] * cv.k
        hw = cv.px(w_out) / 2.0
        reg = cv.region(min(ax, bx) - hw, max(ax, bx) + hw, min(ay, by) - hw, max(ay, by) + hw, self.pad)
        if reg is None:
            return
        sl, X, Y = reg
        ex, ey = bx - ax, by - ay
        wx, wy = X - ax, Y - ay
        t = np.clip((wx * ex + wy * ey) / max(ex * ex + ey * ey, 1e-12), 0.0, 1.0)
        sd = (np.hypot(wx - ex * t, wy - ey * t) - hw).astype(F32)
        np.minimum(self.d[sl], sd, out=self.d[sl])

    def polyline(self, pts, w_out):
        for a, b in zip(pts[:-1], pts[1:]):
            self.capsule(a, b, w_out)


def coverage(d, aa=1.0):
    """Anti-aliased coverage of 'd <= 0' with a ramp of 'aa' SS pixels."""
    return np.clip(0.5 - d / aa, 0.0, 1.0).astype(F32)


def inked(layer, fill=250, fill_a=1.0, ink_out=2.0, ink=(10, 10, 14), ink_a=0.9):
    """A white stroke layer with an ink outline 'ink_out' output px wide around it -> premultiplied (P, A)."""
    d = layer.d
    cf = coverage(d) * fill_a
    ci = coverage(d - ink_out * SS) * ink_a if ink_out > 0 else np.zeros_like(d)
    fill_rgb = np.asarray([fill, fill, fill], F32) / 255.0
    ink_rgb = np.asarray(ink, F32) / 255.0
    A = cf + ci * (1.0 - cf)
    P = fill_rgb * cf[..., None] + ink_rgb * (ci * (1.0 - cf))[..., None]
    return P.astype(F32), A.astype(F32)


# --------------------------------------------------------------------------------------------------------------------
# Roman numerals from thick-thin serif strokes (no font file).  Glyph units: cap height 1, v in [-0.5, 0.5].
# --------------------------------------------------------------------------------------------------------------------

def _clip_halfplane(poly, a, b, keep_pt):
    """Clip a convex polygon by the line a->b, keeping the side that contains keep_pt (Sutherland-Hodgman)."""
    ax, ay = a; bx, by = b
    def side(p):
        return (bx - ax) * (p[1] - ay) - (by - ay) * (p[0] - ax)
    s_keep = side(keep_pt)
    out = []
    n = len(poly)
    for i in range(n):
        p, q = poly[i], poly[(i + 1) % n]
        sp, sq = side(p) * s_keep, side(q) * s_keep
        if sp >= 0:
            out.append(p)
        if (sp >= 0) != (sq >= 0):
            t = sp / (sp - sq)
            out.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
    return out


def _rect(x0, x1, y0, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def _slant_w(w, dx):
    """horizontal width of a stroke of perpendicular width w that drifts dx over the cap height."""
    return w * math.sqrt(1.0 + dx * dx)


def glyph(ch, T, t):
    """Convex polygons for one letter (I, V, X) and its [left, right] extent. T = thick, t = thin (glyph units)."""
    ts = t * 1.15                      # serif slab thickness
    ov = 0.025                         # pieces OVERLAP by this much: abutting SDF pieces would leave a seam
    polys = []
    if ch == "I":
        e = 0.105                      # serif reach past the stem
        polys.append(_rect(-T / 2, T / 2, -0.5, 0.5))
        polys.append(_rect(-T / 2 - e, T / 2 + e, 0.5 - ts, 0.5))
        polys.append(_rect(-T / 2 - e, T / 2 + e, -0.5, -0.5 + ts))
        bx, by = e * 0.62, 0.085       # brackets: the fillet between slab and stem
        for sx in (-1, 1):
            polys.append([(sx * (T / 2 - ov), 0.5 - ts + ov), (sx * (T / 2 + bx), 0.5 - ts + ov),
                          (sx * (T / 2 - ov), 0.5 - ts - by)])
            polys.append([(sx * (T / 2 - ov), -0.5 + ts - ov), (sx * (T / 2 - ov), -0.5 + ts + by),
                          (sx * (T / 2 + bx), -0.5 + ts - ov)])
        return polys, (-T / 2 - e, T / 2 + e)
    if ch == "V":
        a, f, e = 0.355, 0.045, 0.075
        sl = a - f / 2                 # how far each outer edge drifts over the cap height
        wT = _slant_w(T, sl); wt = _slant_w(t, sl)
        left = [(-a, 0.5), (-a + wT, 0.5), (-f / 2 + wT, -0.5), (-f / 2, -0.5)]
        right = [(a - wt, 0.5), (a, 0.5), (f / 2, -0.5), (f / 2 - wt, -0.5)]
        left = _clip_halfplane(left, (a, 0.5), (f / 2, -0.5), (0.0, 0.3))      # trim at the right arm's outer edge
        right = _clip_halfplane(right, (-a, 0.5), (-f / 2, -0.5), (0.0, 0.3))
        polys += [left, right]
        polys.append(_rect(-a - e, -a + wT + e * 0.7, 0.5 - ts, 0.5))
        polys.append(_rect(a - wt - e * 0.7, a + e, 0.5 - ts, 0.5))
        bx, by = e * 0.55, 0.08        # brackets follow the slanted outer edges (no notch)
        yb = 0.5 - ts - by
        xe = -a + (0.5 - yb) * sl       # left outer edge at height yb
        polys.append([(-a + 0.04, 0.5 - ts + ov), (-a - bx, 0.5 - ts + ov), (xe + 0.03, yb)])
        polys.append([(a - 0.04, 0.5 - ts + ov), (-xe - 0.03, yb), (a + bx, 0.5 - ts + ov)])
        return polys, (-a - e, a + e)
    if ch == "X":
        a, e = 0.335, 0.07
        wT = wt = 0.0
        for _ in range(3):             # the slant depends on the widths; iterate to a fixed point
            wT = _slant_w(T, 2 * a - wT); wt = _slant_w(t, 2 * a - wt)
        thick = [(-a, 0.5), (-a + wT, 0.5), (a, -0.5), (a - wT, -0.5)]
        thin = [(a - wt, 0.5), (a, 0.5), (-a + wt, -0.5), (-a, -0.5)]
        polys += [thick, thin]
        polys.append(_rect(-a - e, -a + wT + e * 0.7, 0.5 - ts, 0.5))        # top-left (thick)
        polys.append(_rect(a - wt - e * 0.7, a + e, 0.5 - ts, 0.5))          # top-right (thin)
        polys.append(_rect(-a - e, -a + wt + e * 0.7, -0.5, -0.5 + ts))      # bottom-left (thin)
        polys.append(_rect(a - wT - e * 0.7, a + e, -0.5, -0.5 + ts))        # bottom-right (thick)
        return polys, (-a - e, a + e)
    raise ValueError(ch)


def numeral_polys(text, T, t, gap=0.075):
    """Polygons for a numeral string centred on (0, 0), glyph units."""
    parts, x = [], 0.0
    for i, ch in enumerate(text):
        polys, (l, r) = glyph(ch, T, t)
        off = x - l
        parts.append([[(px + off, py) for px, py in p] for p in polys])
        x = off + r + gap
    width = x - gap
    return [[(px - width / 2, py) for px, py in p] for g in parts for p in g], width


NUMERALS = ["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"]   # IIII: the clockmaker's four


def radial_numerals(layer, r_mid, height, thick_r, thin_r):
    """12 numerals whose tops point outward (XII upright at the top)."""
    T, t = thick_r / height, thin_r / height
    for h, text in enumerate(NUMERALS):
        phi = math.radians(h * 30.0)
        up = (math.sin(phi), math.cos(phi))            # outward
        rt = (math.cos(phi), -math.sin(phi))           # glyph +u (clockwise tangent)
        cx, cy = r_mid * up[0], r_mid * up[1]
        polys, _ = numeral_polys(text, T, t)
        for p in polys:
            layer.poly([(cx + height * (u * rt[0] + v * up[0]), cy + height * (u * rt[1] + v * up[1])) for u, v in p])


def star4(layer, c, phi, L, waist=0.24, short=1.0):
    """A 4-point star: two crossed rhombi, one point radial."""
    s, co = math.sin(phi), math.cos(phi)
    rad = (s, co); tan = (co, -s)
    cx, cy = c
    for (ax, ay), (bx, by), ln in ((rad, tan, L), (tan, rad, L * short)):
        w = L * waist
        layer.poly([(cx + ax * ln, cy + ay * ln), (cx + bx * w, cy + by * w),
                    (cx - ax * ln, cy - ay * ln), (cx - bx * w, cy - by * w)])


# --------------------------------------------------------------------------------------------------------------------
# 1. te5_dial_inlay  (1024^2, inlay plane 24.4 studs, r 1 = 12.2 studs)
# --------------------------------------------------------------------------------------------------------------------

def make_dial_inlay():
    n = 1024; cv = Canvas(n); px = 1.0 / (n / 2.0)          # one output pixel in r units
    L = Layer(cv, pad_out=4.0)
    L.ring(0.985, 3.0)                                      # (a) outer track
    L.ring(0.955, 2.0)                                      # (b) inner track
    for m in range(60):                                     # (c) minute ticks / hour batons
        phi = math.radians(m * 6.0)
        if m % 5 == 0:
            L.radial_tick(phi, 0.94, 0.985, 5.0)
        else:
            L.radial_tick(phi, 0.955, 0.985, 2.0)
    radial_numerals(L, 0.865, 0.13, 0.016, 0.007)           # (d) numerals r 0.80-0.93
    L.ring(0.775, 2.0)                                      # (e) inner edge
    for h in range(12):                                     # (f) half-hour stars
        phi = math.radians(h * 30.0 + 15.0)
        star4(L, (0.865 * math.sin(phi), 0.865 * math.cos(phi)), phi, 0.025)
    P, A = inked(L, fill=250, ink_out=2.0, ink=(10, 10, 14), ink_a=0.9)
    return finish("te5_dial_inlay", P, A)


# --------------------------------------------------------------------------------------------------------------------
# 2. te5_subdial  (512^2, the 6.5-stud sub-dial face)
# --------------------------------------------------------------------------------------------------------------------

def make_subdial():
    n = 512; cv = Canvas(n)
    # guilloche rosette: 24 circles of radius 0.30 whose centres sit on a circle of radius 0.30 (they all pass through
    # the centre), 1.5 px white at alpha 0.85, clipped to r < 0.78 (and kept off the hub inside the centre ring)
    ros = Layer(cv, pad_out=2.0)
    r = cv.r_px / cv.k
    for i in range(24):
        a = 2 * math.pi * i / 24
        cx, cy = 0.30 * math.cos(a), 0.30 * math.sin(a)
        dc = np.hypot(cv.xs[None, :] / cv.k - cx, cv.ys[:, None] / cv.k - cy)
        ros.field((np.abs(dc - 0.30) * cv.k - SS * 1.5 / 2).astype(F32))
    clip = sstep(0.78, 0.765, r) * sstep(0.135, 0.165, r)
    cr = coverage(ros.d) * 0.85 * clip
    rosette = solid([250, 250, 250], cr)
    # rings and ticks with ink
    L = Layer(cv, pad_out=3.0)
    L.ring(0.96, 3.0)
    for m in range(60):
        phi = math.radians(m * 6.0)
        if m % 5 == 0:
            L.radial_tick(phi, 0.84, 0.94, 3.0)
        else:
            L.radial_tick(phi, 0.88, 0.94, 1.5)
    L.ring(0.12, 3.0)
    marks = inked(L, fill=250, ink_out=1.5, ink=(10, 10, 14), ink_a=0.9)
    P, A = over(marks, rosette)
    return finish("te5_subdial", P, A)


# --------------------------------------------------------------------------------------------------------------------
# 7. te5_engraving  (1024^2, the stage: a ground ring 56 studs across, r 1 = 28 studs; review round 3: it was 40 studs and
#    barely cleared the dais rim, a faint thin ring of tiny numerals. Now it runs from just outside the rim (r 0.57 =
#    15.95 studs) to r 0.99: fine guilloche ticks, Roman numerals 3 studs tall, an INKED minute track (a solid dark band
#    with white ticks, lume batons at the five-minute marks) that reads on bright sand by day. Opaque: every stroke is
#    white with an ink outline at alpha >= 0.9, the band is solid ink; nothing is semi-transparent)
# --------------------------------------------------------------------------------------------------------------------

def make_engraving():
    n = 1024; cv = Canvas(n)
    r = cv.r_px / cv.k
    # the inked minute track: a solid dark band (alpha 1, anti-aliased edges)
    band = sstep(0.922, 0.926, r) * sstep(0.978, 0.974, r)
    track = solid([16, 16, 20], band.astype(F32))
    L = Layer(cv, pad_out=4.0)
    # inner frame just outside the dais rim, and a fine guilloche tick band
    for R, w in ((0.585, 3.0), (0.605, 1.6), (0.632, 1.6), (0.688, 1.6)):
        L.ring(R, w)
    for k in range(120):
        phi = math.radians(k * 3.0)
        L.radial_tick(phi, 0.638, 0.682, 2.6 if k % 10 == 0 else 1.2)
    # the numerals (3 studs tall) and half-hour four-point stars
    H = 0.107
    radial_numerals(L, 0.80, H, 0.016 * H / 0.13 * 1.05, 0.007 * H / 0.13 * 1.2)
    for h in range(12):
        phi = math.radians(h * 30.0 + 15.0)
        star4(L, (0.80 * math.sin(phi), 0.80 * math.cos(phi)), phi, 0.026)
    L.ring(0.725, 2.0)
    L.ring(0.875, 2.0)
    # the minute track's white frame and its ticks (inside the dark band), lume batons every five minutes
    L.ring(0.918, 2.4)
    L.ring(0.982, 3.0)
    for m in range(60):
        phi = math.radians(m * 6.0)
        if m % 5 == 0:
            L.radial_tick(phi, 0.929, 0.971, 6.0)
        else:
            L.radial_tick(phi, 0.938, 0.962, 2.0)
    marks = inked(L, fill=240, ink_out=2.0, ink=(20, 20, 22), ink_a=0.95)
    P, A = over(marks, track)
    return finish("te5_engraving", P, A)


# --------------------------------------------------------------------------------------------------------------------
# 9. (te5_hairspring was dropped in review round 2: the 3.8-stud spiral under the feet was invisible at every framing, and
# its GUI went to the moon's face. Its generator is in the git history.)
# --------------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------------
# procedural discs: shared polar grid (r units, +y up, theta CCW from +x) at SS resolution, noise and point helpers
# --------------------------------------------------------------------------------------------------------------------

def polar(n):
    M = n * SS
    c = ((np.arange(M, dtype=F32) + 0.5) - M / 2.0) / (M / 2.0)
    x = c[None, :]; y = -c[:, None]
    r = np.hypot(x, y).astype(F32)
    th = np.arctan2(y, x).astype(F32)
    return x, y, r, th


def spiral_noise(r, th, k, seed, size=(512, 2048), along=0.5, beta=1.15, fmin=2.0, ylr=None):
    """Noise whose features are stretched ALONG the log spiral theta - k*ln r = const (filaments that follow the arms /
    streaks). Periodic in the spiral phase, so there is no seam.  size[1] texels span one turn of spiral phase (across
    the filaments); ylr texels span one unit of ln r (along them; default size[0]*along/2)."""
    tex = noise_periodic(size, seed, beta=beta, fmin=fmin)
    lr = np.log(np.maximum(r, 1e-3))
    psi = (th - k * lr) / (2 * math.pi)                 # spiral phase (turns), constant along a spiral
    if ylr is None:
        ylr = size[0] * along / 2.0
    return sample_wrap(tex, lr * ylr, psi * size[1])


def cart_noise(n, seed, beta=1.3, fmin=2.0):
    return noise_periodic((n * SS, n * SS), seed, beta=beta, fmin=fmin)


def band_noise(shape, seed, fmin, fmax, beta=1.0, aniso=(1.0, 1.0)):
    """Periodic fractal noise limited to the band fmin..fmax (cycles per tile): features never finer than the band, so a
    stretched or sheared copy never aliases into dashed lines. Mean 0, std 1."""
    return noise_periodic(shape, seed, beta=beta, fmin=fmin, fmax=fmax, aniso=aniso)


def deposit(shape, xs, ys, vals):
    """Point fluxes at float pixel positions, shared bilinearly between the four nearest pixels (no aliasing)."""
    H, W = shape
    out = np.zeros(shape, F32)
    x0 = np.floor(xs - 0.5).astype(np.int64); y0 = np.floor(ys - 0.5).astype(np.int64)
    fx = (xs - 0.5 - x0).astype(F32); fy = (ys - 0.5 - y0).astype(F32)
    vals = np.asarray(vals, F32)
    for dy, dx, w in ((0, 0, (1 - fx) * (1 - fy)), (0, 1, fx * (1 - fy)), (1, 0, (1 - fx) * fy), (1, 1, fx * fy)):
        yy = y0 + dy; xx = x0 + dx
        ok = (yy >= 0) & (yy < H) & (xx >= 0) & (xx < W)
        np.add.at(out, (yy[ok], xx[ok]), (vals * w)[ok])
    return out


def soft_dots(shape, xs, ys, sig, vals):
    """Round Gaussian dots (sigma sig px, peak val) at float pixel positions, screen-combined."""
    out = np.zeros(shape, F32)
    H, W = shape
    for x, y, s, v in zip(xs, ys, sig, vals):
        R = int(math.ceil(s * 3.2)) + 1
        x0, x1 = max(0, int(x) - R), min(W, int(x) + R + 2)
        y0, y1 = max(0, int(y) - R), min(H, int(y) + R + 2)
        if x1 <= x0 or y1 <= y0:
            continue
        X = np.arange(x0, x1, dtype=F32)[None, :] + 0.5 - x
        Y = np.arange(y0, y1, dtype=F32)[:, None] + 0.5 - y
        p = np.clip(v * np.exp(-0.5 * (X * X + Y * Y) / (s * s)), 0.0, 1.0)
        out[y0:y1, x0:x1] = 1.0 - (1.0 - out[y0:y1, x0:x1]) * (1.0 - p)
    return out


def r_to_px(n, x, y):
    """r units (+y up) -> SS pixel coordinates of an n-px image"""
    m = n * SS
    return x * m / 2.0 + m / 2.0, m / 2.0 - y * m / 2.0


def disc_grid(n):
    """polar() broadcast to full SS-resolution arrays: x, y, r, theta"""
    x, y, r, th = polar(n)
    shp = (n * SS, n * SS)
    return (np.broadcast_to(x, shp).astype(F32), np.broadcast_to(y, shp).astype(F32),
            np.broadcast_to(r, shp).astype(F32), np.broadcast_to(th, shp).astype(F32))


# --------------------------------------------------------------------------------------------------------------------
# 3. te5_accretion  (1024^2, 13-stud plane, r 1 = 6.5 studs)
#    Interstellar's disc, seen from above: turbulent plasma sheared by the orbit. Every feature is a blob of isotropic
#    turbulence carried round at the Kepler rate (angular speed ~ r^-1.5), so it is drawn out into a long trailing streak
#    that winds CLOCKWISE outward (image +y up): turn the plane COUNTER-clockwise (as seen on its Top face) and they
#    trail. Brightness climbs to a white-hot inner edge; thin cool lanes and darker gaps break up the outer disc. Nothing
#    depends on the angle, so the spinning plane never shows a fixed bright lobe.
#    Alpha (the convention the module is built on): an opaque BLACK skirt r 0.60-0.68, under the 8-stud core's silhouette
#    (r 0.615), so the day sky never shows between the core and the hot edge; the spec's soft inner edge (0.68-0.72) is
#    drawn as white fading into that black; opaque to r 0.86, smoothstep to 0 at r 1.0.
# --------------------------------------------------------------------------------------------------------------------

def kepler_sample(tex, r, th, w0, r_in=0.72, extent=1.12):
    """Sample a periodic source field at the place the gas now at (r, theta) started from: theta - w0 (r / r_in)^-1.5."""
    phi = th - w0 * (np.maximum(r, 0.3) / r_in) ** -1.5
    sx = r * np.cos(phi); sy = r * np.sin(phi)
    Ht, Wt = tex.shape
    return sample_wrap(tex, (0.5 - sy / extent * 0.5) * Ht, (sx / extent * 0.5 + 0.5) * Wt)


def flatten_azimuth(L, r, th, r0, r1, nr=48, nt=96, sigma_deg=40.0, lim=(0.7, 1.4)):
    """Divide out the broad brightness lobes round each ring (angular scales above ~sigma_deg), keeping the finer
    structure: the disc spins, so a big bright or dark lobe would sweep round it like a slow searchlight."""
    rb = np.clip(((r - r0) / (r1 - r0) * nr).astype(np.int64), 0, nr - 1)
    tb = (((th + math.pi) / (2 * math.pi)) * nt).astype(np.int64) % nt
    idx = (rb * nt + tb).ravel()
    sel = ((r >= r0) & (r < r1)).ravel()
    tot = np.bincount(idx[sel], weights=L.ravel()[sel].astype(np.float64), minlength=nr * nt).reshape(nr, nt)
    cnt = np.bincount(idx[sel], minlength=nr * nt).reshape(nr, nt)
    cell = tot / np.maximum(cnt, 1)
    k = np.exp(-0.5 * (np.minimum(np.arange(nt), nt - np.arange(nt)) * 360.0 / nt / sigma_deg) ** 2); k /= k.sum()
    lobes = np.fft.irfft(np.fft.rfft(cell, axis=1) * np.fft.rfft(k)[None, :], n=nt, axis=1)
    corr = np.clip(cell.mean(axis=1, keepdims=True) / np.maximum(lobes, 1e-4), lim[0], lim[1]).astype(F32)
    # bilinear lookup (periodic in angle, clamped in radius); outside r0..r1 the correction fades to 1
    fr = np.clip((r - r0) / (r1 - r0) * nr - 0.5, 0, nr - 1.001)
    ft = ((th + math.pi) / (2 * math.pi)) * nt - 0.5
    c = sample_wrap(corr, fr, ft)
    w = sstep(r0, r0 + 0.02, r) * sstep(r1, r1 - 0.02, r)
    return L * (1.0 + (c - 1.0) * w)


def make_accretion():
    n = 1024
    x, y, r, th = disc_grid(n)
    # source turbulence (band-limited: the sheared filaments stay at least ~1.5 px across, so nothing aliases)
    turb1 = kepler_sample(band_noise((1024, 1024), 3101, 3.0, 48.0, 1.1), r, th, 7.0)      # the main eddies
    turb2 = kepler_sample(band_noise((512, 512), 3102, 5.0, 14.0, 1.6), r, th, 3.2)        # slow broad brightness
    filn = kepler_sample(band_noise((1024, 1024), 3103, 5.0, 26.0, 0.8), r, th, 8.0)       # bright filaments
    lanen = kepler_sample(band_noise((1024, 1024), 3104, 4.0, 24.0, 1.0), r, th, 7.0)      # cool lanes
    lmask = kepler_sample(band_noise((512, 512), 3105, 4.0, 12.0, 1.5), r, th, 4.9)        # where the lanes are
    gaps = kepler_sample(band_noise((512, 512), 3107, 5.0, 12.0, 1.4), r, th, 2.4)         # broad darker gaps
    # hot knots: sparse bright blobs in the source, sheared into short bright arcs
    rng = np.random.default_rng(3106)
    kx, ky, ks, kv = [], [], [], []
    for _ in range(520):
        rr = rng.uniform(0.70, 1.0); aa = rng.uniform(0, 2 * math.pi)
        kx.append((rr * math.cos(aa) / 1.12 * 0.5 + 0.5) * 1024); ky.append((0.5 - rr * math.sin(aa) / 1.12 * 0.5) * 1024)
        ks.append(rng.uniform(2.5, 8.0)); kv.append(rng.uniform(0.3, 1.0) ** 0.7)
    knots = kepler_sample(soft_dots((1024, 1024), kx, ky, ks, kv), r, th, 5.0)
    # emission: white-hot at the inner edge, falling off outward, broken by the turbulence
    prof = np.clip((0.765 / np.maximum(r, 1e-3)) ** 3.0, 0.0, 1.0)
    turb = 0.56 + 0.24 * np.tanh(0.9 * turb1) + 0.26 * np.tanh(1.2 * turb2)
    fil = np.exp(-(filn / 0.32) ** 2)
    L = prof * turb + 0.26 * fil * prof ** 0.6 + 0.55 * knots * prof ** 0.5
    L = L * (1.0 - 0.38 * sstep(0.2, 1.3, gaps))
    lane = np.exp(-(lanen / 0.28) ** 2) * sstep(-0.3, 0.6, lmask) * sstep(0.775, 0.84, r) * sstep(0.99, 0.94, r)
    L = L * (1.0 - 0.85 * np.clip(lane * 1.4, 0, 1))
    L = flatten_azimuth(L, r, th, 0.70, 1.0, sigma_deg=20.0)
    # the white-hot inner edge: 1 inside r 0.742, eased into the turbulent disc by r 0.768
    L = L + (1.0 - L) * sstep(0.768, 0.742, r)
    # the convention: white fading into the black skirt over r 0.676-0.712; skirt from 0.60; soft outer edge
    L = 0.012 + (L - 0.012) * sstep(0.676, 0.712, r)
    A = sstep(0.598, 0.624, r) * (1.0 - sstep(0.86, 1.0, r))
    L = np.clip(L, 0.0, 1.0)
    rgb = np.dstack([L, L, L])
    return finish("te5_accretion", (rgb * A[..., None]).astype(F32), A.astype(F32), dither=True)


# --------------------------------------------------------------------------------------------------------------------
# galaxy helpers (te5_galaxy_floor / _arms / _core).  Arms wind COUNTER-clockwise outward with image +y up:
# theta_arm(r) = theta0 + k*ln(r/r0), k = 1/tan(pitch).  Spin the plane CLOCKWISE (image +y up) for trailing arms.
# The concave (inner) side of such an arm is the +delta side (larger theta at the same radius): its dust lane lives there.
# --------------------------------------------------------------------------------------------------------------------

_SPN = {}


def spiral_field(r, th, pitch, seed, lam, n_out, elong=1.0, beta=1.0, r_ref=0.5, W=1024):
    """Noise in ORTHOGONAL log-spiral coordinates: psi = theta - k ln r is constant along an arm, eta = theta + ln r / k
    across it. Features are lam = (min, max) output px wide across the arm at r_ref and elong x longer along it, and grow
    with the radius like the galaxy does. Band-limited and periodic in both: no seam, no aliasing, no repeats."""
    p = math.radians(pitch); k = 1.0 / math.tan(p)
    H = max(16, int(round(W * k / elong / 8.0)) * 8)          # texels per turn of eta (along the arms)
    tex_px = 2 * math.pi * r_ref * math.sin(p) / W * (n_out / 2.0)
    fmin = W * tex_px / lam[1]; fmax = W * tex_px / lam[0]
    key = (H, W, seed, beta, round(fmin, 4), round(fmax, 4))
    tex = _SPN.get(key)
    if tex is None:
        tex = noise_periodic((H, W), seed, beta=beta, fmin=fmin, fmax=fmax, aniso=(W / H, 1.0))
        _SPN[key] = tex
    lr = np.log(np.maximum(r, 1e-3))
    return sample_wrap(tex, (th + lr / k) / (2 * math.pi) * H, (th - k * lr) / (2 * math.pi) * W)


def across_arm(r, th, theta0, k, r0, sinp, wperp):
    """Signed distance across the arm theta0 in arm widths (+ = its concave / inner side), nearest winding."""
    d = wrap_pi(th - (theta0 + k * np.log(np.maximum(r, 1e-3) / r0)))
    return (r * d * sinp / wperp).astype(F32)


def breakup(noise01, lo, gain):
    """0 where the noise is low, 1 where it is high: breaks a lane into pieces"""
    return np.clip(gain * noise01 - lo, 0.0, 1.0)


def dust_lanes(xa, r, th, seed, pitch, n_out, centre=0.58, scale=1.0):
    """The dust on an arm's inner edge (absorption 0..1): a long main lane that meanders, two broken side threads and a
    faint patchy veil, all drawn along the spiral."""
    f = lambda sd, lam, e, b=1.1: spiral_field(r, th, pitch, sd, lam, n_out, elong=e, beta=b)
    meander = 0.14 * f(seed, (25, 100), 6.0, 1.5)
    lane = np.zeros_like(xa)
    # (offset in arm widths, width, strength, how often it breaks)
    for i, (o, w, s, lo, gn) in enumerate(((0.0, 0.11, 1.0, 0.0, 2.6), (0.25, 0.07, 0.8, 0.35, 1.9),
                                           (-0.18, 0.06, 0.6, 0.45, 1.9))):
        oi = o + 0.08 * f(seed + 10 + i, (10, 40), 6.0, 1.2)
        brk = breakup(unit01(f(seed + 20 + i, (6, 30), 6.0, 1.1), 1.1), lo, gn)
        wi = w * scale * (0.75 + 0.5 * unit01(f(seed + 30 + i, (8, 40), 6.0, 1.0), 1.2))
        lane = np.maximum(lane, s * brk * np.exp(-((xa - centre - meander - oi) / wi) ** 2))
    veil = 0.34 * unit01(f(seed + 40, (8, 50), 3.0, 1.1), 1.2) * np.exp(-((xa - centre - 0.1) / (0.45 * scale)) ** 2)
    return np.clip(np.maximum(lane, veil), 0.0, 1.0)


def star_grain(rng, n, dens, count, rmax, vmin=0.10, vspread=0.55, blur=0.7):
    """A fine field of resolved stars whose density follows dens (0..1): the granular texture of a real galaxy."""
    Hs = dens.shape[0]
    px_ = rng.uniform(-rmax, rmax, count * 3); py_ = rng.uniform(-rmax, rmax, count * 3)
    ok = np.hypot(px_, py_) < rmax
    sx, sy = r_to_px(n, px_[ok], py_[ok])
    ix = np.clip(sx.astype(np.int64), 0, Hs - 1); iy = np.clip(sy.astype(np.int64), 0, Hs - 1)
    keep = rng.random(len(ix)) < dens[iy, ix]
    ix, iy = ix[keep][:count], iy[keep][:count]
    g = np.zeros(dens.shape, F32)
    np.add.at(g, (iy, ix), (vmin + vspread * rng.random(len(ix)) ** 4.0).astype(F32))
    return gblur(g, blur)


def knot_points(rng, count, theta0s, k, r0, rr, ang_w, cluster=(1, 6), bias=-0.15, spread=0.45):
    """Star-forming knots along the arms, in small clusters, mostly just outside the dust lane: (x, y, r)."""
    out = []
    while len(out) < count:
        j = rng.integers(len(theta0s))
        r = rr[0] + (rr[1] - rr[0]) * rng.random() ** 0.8
        off = rng.normal(bias, spread) * ang_w(r)
        for _ in range(int(rng.integers(cluster[0], cluster[1] + 1))):
            rc = r + rng.normal(0, 0.006)
            t = theta0s[j] + k * math.log(max(rc, 1e-3) / r0) + off + rng.normal(0, 0.12) * ang_w(r)
            out.append((rc * math.cos(t), rc * math.sin(t), rc))
    return out


def field_stars(n, seed, rmax, count, bright):
    """single-pixel stars (and a few with a small halo) added after the 2x downsample, inside rmax"""
    def add(C, A1):
        rs = np.random.default_rng(seed)
        m = n
        for _ in range(count):
            rr_ = rmax * math.sqrt(rs.random()); tt = rs.random() * 2 * math.pi
            i = int((m / 2) - rr_ * math.sin(tt) * (m / 2)); jx = int((m / 2) + rr_ * math.cos(tt) * (m / 2))
            v = 0.35 + 0.65 * rs.random() ** 2.2
            if C[i, jx, 0] < v:
                C[i, jx] = (v, v, v)
        for _ in range(bright):
            rr_ = (rmax - 0.02) * math.sqrt(rs.random()); tt = rs.random() * 2 * math.pi
            ci = (m / 2) - rr_ * math.sin(tt) * (m / 2); cj = (m / 2) + rr_ * math.cos(tt) * (m / 2)
            for di in range(-3, 4):
                for dj in range(-3, 4):
                    i, jx = int(ci) + di, int(cj) + dj
                    dd = math.hypot(di + 0.5 - (ci - int(ci)), dj + 0.5 - (cj - int(cj)))
                    v = math.exp(-dd * dd / 0.8) + 0.16 * math.exp(-dd / 1.5)
                    C[i, jx] = 1.0 - (1.0 - C[i, jx]) * (1.0 - min(1.0, v))
        return C, A1
    return add


# --------------------------------------------------------------------------------------------------------------------
# 4. te5_galaxy_floor  (1024^2, dais pool 29.6 studs): a barred grand-design spiral seen face-on, opaque to r 0.86.
#    Density-wave arms (pitch 16) with a sharp inner edge where the gas is shocked and a gentle outer decline; their
#    stars come in clouds and in clusters of bright knots just downstream of the dust; dark lanes on each arm's inner
#    edge (one long braided lane, broken side threads and a veil) that run on along the bar as an S; a smooth bulge, a
#    strong bar and an exponential disc of resolved stars; field stars over all. Mean L ~0.21: a dark pool, white arms.
# --------------------------------------------------------------------------------------------------------------------

def make_galaxy_floor():
    n = 1024
    seed = 401
    X, Y, r, th = disc_grid(n)
    rng = np.random.default_rng(seed)
    pitch = 16.0; k = 1.0 / math.tan(math.radians(pitch)); r0 = 0.18; sinp = math.sin(math.radians(pitch))
    T0 = [0.0, math.pi]
    wperp = 0.030 + 0.052 * np.clip((r - r0) / 0.65, 0, 1)        # arm width across the arm (r units)
    grow = sstep(0.15, 0.24, r)
    fade = np.exp(-np.maximum(r - 0.22, 0) / 0.42)
    # star clouds along the arms (fine and middle scale) and the slow brightness change along each arm
    cl_f = unit01(spiral_field(r, th, pitch, seed + 1, (5, 20), n, elong=1.6, beta=0.9), 1.2)
    cl_m = unit01(spiral_field(r, th, pitch, seed + 2, (22, 80), n, elong=2.0, beta=1.1), 1.3)
    slow = unit01(spiral_field(r, th, pitch, seed + 3, (30, 130), n, elong=4.0, beta=1.4), 1.3)
    mottle = unit01(cart_noise(n, seed + 4, beta=1.1, fmin=6.0), 1.6)
    # faint spurs leaving the arms' outer side at a steeper pitch
    ks = 1.0 / math.tan(math.radians(40.0))
    spur_n = spiral_noise(r, th, ks, seed + 7, size=(64, 512), beta=1.5, fmin=2.0, ylr=6.0)
    spurs = (0.5 + 0.5 * np.cos(15.0 * (th - ks * np.log(np.maximum(r, 1e-3))) + 1.6 * spur_n)) ** 8
    spurs = spurs * breakup(unit01(spiral_noise(r, th, ks, seed + 13, size=(64, 256), beta=1.4, fmin=2.0, ylr=5.0), 1.0), 0.5, 1.6)
    armp = np.zeros_like(r); skirt = np.zeros_like(r); dust = np.zeros_like(r); spur_l = np.zeros_like(r)
    for j, t0 in enumerate(T0):
        xa = across_arm(r, th, t0, k, r0, sinp, wperp)
        armp = np.maximum(armp, np.where(xa > 0, np.exp(-(xa / 0.75) ** 2), np.exp(-(xa / 1.35) ** 2)))
        skirt = np.maximum(skirt, np.exp(-(xa / 3.2) ** 2))
        dust = np.maximum(dust, dust_lanes(xa, r, th, seed + 100 + 50 * j, pitch, n) * sstep(0.17, 0.23, r) * sstep(0.92, 0.80, r))
        spur_l = np.maximum(spur_l, spurs * np.exp(-((xa + 1.2) / 1.6) ** 2))
    clouds = (0.55 + 0.30 * cl_m + 0.30 * cl_f) * (0.75 + 0.35 * slow)
    arml = grow * fade * (armp * clouds + 0.28 * skirt * (0.85 + 0.25 * cl_m) + 0.10 * spur_l * sstep(0.3, 0.45, r))
    # bulge, bar (along theta = 0, to r ~0.18) and the exponential disc
    bulge = 1.0 / (1.0 + (r / 0.05) ** 2) ** 0.8
    ax_ = np.abs(X)
    bar = 0.70 * np.exp(-(ax_ / 0.185) ** 3.2) * np.exp(-(Y / (0.034 + 0.012 * (ax_ / 0.18) ** 2)) ** 2)
    disc = 0.11 * np.exp(-r / 0.30) * (0.75 + 0.5 * mottle)
    # the bar's dust lanes: thin, curved, broken, on the side each arm leaves from (an S into the arm lanes)
    ycen = 0.024 * np.sign(X) * sstep(0.03, 0.15, ax_) ** 1.4
    bfr = breakup(unit01(cart_noise(n, seed + 15, beta=1.3, fmin=8.0), 1.2), 0.2, 1.5)
    dust = np.maximum(dust, np.exp(-((Y - ycen) / 0.0055) ** 2) * sstep(0.05, 0.10, ax_) * sstep(0.215, 0.165, ax_) * 0.62 * bfr)
    # resolved stars and the bright knots
    dens = np.clip(0.95 * arml + 0.35 * disc / 0.11 * np.exp(-r / 0.5) + 0.5 * bar + 0.3 * bulge, 0, 1)
    grain = star_grain(rng, n, dens, 180000, 0.86)
    wf = lambda rr_: (0.030 + 0.052 * min(max((rr_ - r0) / 0.65, 0), 1)) / (rr_ * sinp)
    pts = knot_points(rng, 1300, T0, k, r0, (0.20, 0.86), wf, cluster=(1, 7))
    xs, ys = r_to_px(n, np.array([p[0] for p in pts]), np.array([p[1] for p in pts]))
    rads = np.array([p[2] for p in pts])
    vals = (0.30 + 0.70 * rng.random(len(pts)) ** 2.0) * np.exp(-np.maximum(rads - 0.35, 0) / 0.8)
    knots = soft_dots(r.shape, xs, ys, (0.6 + 1.5 * rng.random(len(pts)) ** 3) * SS, vals)
    base = (9.0 + 4.0 * np.clip(cart_noise(n, seed + 9, beta=0.7, fmin=8.0), -1.5, 1.5) / 1.5) / 255.0
    light = screen(bulge, bar, disc + arml * 0.86, grain * 1.1, knots * (1.0 - 0.7 * dust))
    L = screen(base, light)
    L = L * (1.0 - 0.78 * dust) + 0.012 * dust
    A = 1.0 - sstep(0.86, 1.0, r)
    rgb = np.dstack([L, L, L]).astype(F32)
    img = finish("te5_galaxy_floor", (rgb * A[..., None]).astype(F32), A.astype(F32), dither=True,
                 extra=field_stars(n, seed + 10, 0.86, 1500, 22))
    g = img[..., 0] / 255.0
    yy, xx = np.mgrid[0:n, 0:n]; rr = np.hypot(xx + 0.5 - n / 2, yy + 0.5 - n / 2) / (n / 2)
    print(f"  galaxy floor mean L (r < 0.86) = {g[rr < 0.86].mean():.3f}  (spec ~0.22)")
    return img


# --------------------------------------------------------------------------------------------------------------------
# 5. te5_galaxy_arms  (1024^2, floating arm layer 21 studs): the same kind of spiral turned 90 deg, pitch 13, arms only.
#    Each arm is a luminous stream of star clouds (opaque in its core, soft wings), dusted with resolved stars and bright
#    knots, with the dust lane on its concave (= leading for a counter-clockwise spin) edge. Transparent between the arms.
# --------------------------------------------------------------------------------------------------------------------

def make_galaxy_arms():
    n = 1024
    seed = 501
    X, Y, r, th = disc_grid(n)
    rng = np.random.default_rng(seed)
    pitch = 13.0; k = 1.0 / math.tan(math.radians(pitch)); r0 = 0.18; sinp = math.sin(math.radians(pitch))
    T0 = [math.pi / 2, 3 * math.pi / 2]
    wperp = 0.022 + 0.040 * np.clip((r - 0.2) / 0.65, 0, 1)
    span = sstep(0.13, 0.24, r) * (1.0 - sstep(0.85, 1.0, r))   # arms grow out of the centre; the outer 15 % fades
    cl_f = unit01(spiral_field(r, th, pitch, seed + 1, (5, 20), n, elong=1.6, beta=0.9), 1.2)
    cl_m = unit01(spiral_field(r, th, pitch, seed + 2, (22, 80), n, elong=2.0, beta=1.1), 1.3)
    slow = unit01(spiral_field(r, th, pitch, seed + 3, (30, 130), n, elong=4.0, beta=1.4), 1.3)
    breathe = spiral_field(r, th, pitch, seed + 4, (25, 100), n, elong=4.0, beta=1.3)
    core = np.zeros_like(r); wing = np.zeros_like(r); dust = np.zeros_like(r)
    for j, t0 in enumerate(T0):
        xa = across_arm(r, th, t0, k, r0, sinp, wperp * (1.0 + 0.25 * np.tanh(breathe)))
        core = np.maximum(core, np.where(xa > 0, np.exp(-(xa / 0.7) ** 2), np.exp(-(xa / 1.1) ** 2)))
        wing = np.maximum(wing, np.exp(-(xa / 2.4) ** 2))
        dust = np.maximum(dust, dust_lanes(xa, r, th, seed + 100 + 50 * j, pitch, n, centre=0.52, scale=1.1)
                          * sstep(0.1, 0.5, np.exp(-(xa / 1.6) ** 2)))
    clouds = (0.50 + 0.32 * cl_m + 0.30 * cl_f) * (0.78 + 0.30 * slow)
    a_core = np.clip(core * 1.15, 0, 1) ** 1.3 * np.clip(clouds, 0, 1.15)
    a_wing = wing * 0.20 * (0.75 + 0.25 * cl_m)
    a_arm = np.clip(np.maximum(a_core * 0.94, a_wing), 0, 1) * span
    grain = np.clip(star_grain(np.random.default_rng(seed + 9), n, np.clip(a_arm * 1.3, 0, 1), 90000, 0.95,
                               vmin=0.35, vspread=0.65, blur=0.6) * 1.4, 0, 1) * span
    wf = lambda rr_: (0.022 + 0.040 * min(max((rr_ - 0.2) / 0.65, 0), 1)) / (rr_ * sinp)
    pts = knot_points(rng, 700, T0, k, r0, (0.24, 0.88), wf, cluster=(1, 6), bias=-0.25, spread=0.4)
    xs, ys = r_to_px(n, np.array([p[0] for p in pts]), np.array([p[1] for p in pts]))
    knots = soft_dots(r.shape, xs, ys, (0.55 + 1.2 * rng.random(len(pts)) ** 3) * SS,
                      0.55 + 0.45 * rng.random(len(pts)) ** 1.5) * (1.0 - sstep(0.85, 0.97, r))
    Lw = 0.84 + 0.16 * cl_m
    white = solid(np.dstack([Lw, Lw, Lw]).astype(F32), a_arm.astype(F32))
    pts_l = solid(np.ones((1, 1, 3), F32), np.clip(np.maximum(knots * (1 - 0.8 * dust), grain), 0, 1).astype(F32))
    dust = np.clip(dust * span * sstep(0.2, 0.3, r), 0, 1)
    ink = solid([9, 9, 10], (dust * 0.86).astype(F32))
    P, A = over(ink, over(pts_l, white))
    return finish("te5_galaxy_arms", P, A, dither=True)


# --------------------------------------------------------------------------------------------------------------------
# 6. te5_galaxy_core  (512^2, inner layer 12 studs): the bulge (alpha 1 to r 0.08, soft to 0.25) with a faint nuclear
#    dust spiral, and 4 tightly wound (10 deg) arms of star clouds from r 0.1, each with its own length (0.68-0.80) and
#    strength (a vortex, not rings), broken dust lanes on their inner edges and small bright knots. Alpha 0 beyond 0.85.
# --------------------------------------------------------------------------------------------------------------------

def make_galaxy_core():
    n = 512
    seed = 601
    X, Y, r, th = disc_grid(n)
    rng = np.random.default_rng(seed)
    pitch = 15.0; k = 1.0 / math.tan(math.radians(pitch)); sinp = math.sin(math.radians(pitch))
    psi = th - k * np.log(np.maximum(r, 1e-3))
    wob = 0.05 * spiral_noise(r, th, k, seed + 1, size=(256, 1024), along=0.9, beta=1.4, fmin=2.0)
    q = 4.0 * (psi + wob * 0.2) / (2 * math.pi)
    jarm = np.mod(np.floor(q + 0.5), 4).astype(np.int64)
    d = wrap_pi(4.0 * (psi + wob * 0.2)) / 4.0                    # angular offset to the nearest of the 4 arms
    # arm width set PERPENDICULAR to the arm (r units): ~4 px near the core -> ~11 px at r 0.8 (an angular width would
    # make these tightly wound arms hairlines near the centre)
    wp = 0.016 + 0.026 * np.clip((r - 0.1) / 0.7, 0.0, 1.0)
    breathe = spiral_field(r, th, pitch, seed + 4, (10, 40), n, elong=4.0, beta=1.3, r_ref=0.4, W=256)
    xa = r * d * sinp / (wp * (1.0 + 0.3 * np.tanh(breathe)))
    cl_f = unit01(spiral_field(r, th, pitch, seed + 2, (2.5, 8), n, elong=2.5, beta=0.9, r_ref=0.4, W=256), 1.2)
    cl_m = unit01(spiral_field(r, th, pitch, seed + 3, (8, 30), n, elong=4.0, beta=1.1, r_ref=0.4, W=256), 1.3)
    r_end = np.asarray([0.80, 0.72, 0.78, 0.68], F32)[jarm]
    gain = np.asarray([1.0, 0.82, 0.92, 0.74], F32)[jarm]
    span = sstep(0.07, 0.14, r) * sstep(r_end + 0.05, r_end - 0.10, r) * sstep(0.85, 0.80, r)
    prof = np.where(xa > 0, np.exp(-(xa / 0.75) ** 2), np.exp(-(xa / 1.15) ** 2))
    a_arm = np.clip((prof * gain * (0.62 + 0.36 * cl_m + 0.14 * cl_f) - 0.06) / 0.94, 0.0, 0.9) * span
    lfr = breakup(unit01(spiral_field(r, th, pitch, seed + 6, (2, 10), n, elong=5.0, beta=1.0, r_ref=0.4, W=256), 1.1), 0.3, 1.7)
    lane = np.exp(-((xa - 0.55) / 0.22) ** 2) * span * sstep(0.12, 0.22, r) * lfr
    dfl = spiral_field(r, th, 13.0, seed + 7, (3, 14), n, elong=6.0, beta=1.2, r_ref=0.15, W=256)
    nuc_dust = np.exp(-(dfl / 0.35) ** 2) * sstep(0.06, 0.11, r) * sstep(0.30, 0.18, r) * 0.42
    core_a = np.where(r < 0.08, 1.0, np.exp(-((r - 0.08) / 0.075) ** 2) * (1.0 - sstep(0.18, 0.25, r)))
    Lb = 1.0 - 0.10 * sstep(0.03, 0.2, r)
    pts = []
    while len(pts) < 260:
        j = rng.integers(4); rr_ = 0.14 + 0.62 * rng.random() ** 0.9
        t = j * math.pi / 2 + k * math.log(rr_) + rng.normal(-0.1, 0.25) * (0.016 + 0.026 * min(max((rr_ - 0.1) / 0.7, 0), 1)) / (rr_ * sinp)
        pts.append((rr_ * math.cos(t), rr_ * math.sin(t)))
    xs, ys = r_to_px(n, np.array([p[0] for p in pts]), np.array([p[1] for p in pts]))
    knots = soft_dots(r.shape, xs, ys, (0.45 + 0.9 * rng.random(len(pts)) ** 3) * SS, 0.5 + 0.5 * rng.random(len(pts)))
    knots = knots * sstep(0.85, 0.75, r)
    Lw = 0.86 + 0.14 * cl_m
    arm = solid(np.dstack([Lw, Lw, Lw]).astype(F32), a_arm.astype(F32))
    kn = solid(np.ones((1, 1, 3), F32), np.clip(knots * (1 - 0.8 * lane), 0, 1).astype(F32))
    core = solid(np.dstack([Lb, Lb, Lb]).astype(F32), core_a.astype(F32))
    ink = solid([9, 9, 10], np.clip(lane * 0.9, 0, 1).astype(F32))
    nd = solid([30, 30, 32], np.clip(nuc_dust * core_a, 0, 1).astype(F32))
    P, A = over(nd, over(core, over(ink, over(kn, arm))))
    cut = 1.0 - sstep(0.84, 0.85, r)
    return finish("te5_galaxy_core", (P * cut[..., None]).astype(F32), (A * cut).astype(F32), dither=True)


# --------------------------------------------------------------------------------------------------------------------
# 8. te5_halo  (512^2): rim-only halo, alpha 0 (r < 0.66) -> 0.95 (0.74) -> 0.35 (0.82) -> 0.10 (0.90) -> 0 (1.0)
# --------------------------------------------------------------------------------------------------------------------

def make_halo():
    n = 512
    x, y, r, th = polar(n)
    xs = [0.66, 0.74, 0.82, 0.90, 1.00]
    ys = [0.00, 0.95, 0.35, 0.10, 0.00]
    a = pchip(xs, ys, r)
    a = np.where(r < 0.66, 0.0, np.where(r > 1.0, 0.0, a)).astype(F32)
    P = np.dstack([a, a, a]).astype(F32)
    return finish("te5_halo", P, a, dither=True)


# --------------------------------------------------------------------------------------------------------------------
# 12. te5_moon  (1024^2): a photographic full moon for the moon's camera-facing face disc (review round 1, AD4; rebuilt
#     after review round 3). Rendered, not painted: the near side as a globe (north up, the Earth-facing hemisphere,
#     orthographic), its albedo and a height field built on the sphere, then lit.
#     * Maria where the real ones are (te5_lunar_data.py), their shores flooded round the old terrain's relief (lava fills
#       the low ground), round basins kept round, darker and lighter lava units, ghost craters under the lava.
#     * ~26,000 craters with a power-law size spread (N(>D) ~ D^-1.85) plus ~250 named ones: bowl, raised rim, terraces,
#       central peaks, an ejecta skirt; old ones softened. Mountain chains on the basin rims.
#     * Young craters bright, with ray systems: Tycho's (a dark collar, a bright nimbus, rays across half the disc),
#       Copernicus, Kepler, Aristarchus, Proclus (its gap), Messier's twin rays, ~500 small rayed craters.
#     * Light ~22 deg off the view axis from the upper left: lunar-Lambert reflectance (mostly Lommel-Seeliger, so the
#       disc stays evenly lit to the limb with no dark side), relief from the height field's normals and cast shadows,
#       so craters near the limb show depth while the whole face stays lit.
#     Hard alpha edge at r 0.985 (1.6 % ramp): no ring, no glow.
# --------------------------------------------------------------------------------------------------------------------

_GX = np.array([1, -1, 1, -1, 1, -1, 1, -1, 0, 0, 0, 0, 1, 0, -1, 0], F32)
_GY = np.array([1, 1, -1, -1, 0, 0, 0, 0, 1, -1, 1, -1, 1, -1, 1, -1], F32)
_GZ = np.array([0, 0, 0, 0, 1, 1, -1, -1, 1, 1, -1, -1, 0, 1, 0, -1], F32)


def perlin3(x, y, z, perm):
    """Improved Perlin gradient noise at float32 points (any shape); about -1..1."""
    fx = np.floor(x); fy = np.floor(y); fz = np.floor(z)
    xi = fx.astype(np.int32) & 255; yi = fy.astype(np.int32) & 255; zi = fz.astype(np.int32) & 255
    xf = (x - fx).astype(F32); yf = (y - fy).astype(F32); zf = (z - fz).astype(F32)
    u = xf * xf * xf * (xf * (xf * 6 - 15) + 10)
    v = yf * yf * yf * (yf * (yf * 6 - 15) + 10)
    w = zf * zf * zf * (zf * (zf * 6 - 15) + 10)
    A = perm[xi] + yi; B = perm[xi + 1] + yi
    AA = perm[A] + zi; AB = perm[A + 1] + zi; BA = perm[B] + zi; BB = perm[B + 1] + zi

    def g(h, X, Y, Z):
        h = h & 15
        return _GX[h] * X + _GY[h] * Y + _GZ[h] * Z
    xm = xf - 1; ym = yf - 1; zm = zf - 1
    x1 = g(perm[AA], xf, yf, zf); x1 += u * (g(perm[BA], xm, yf, zf) - x1)
    x2 = g(perm[AB], xf, ym, zf); x2 += u * (g(perm[BB], xm, ym, zf) - x2)
    y1 = x1 + v * (x2 - x1)
    x3 = g(perm[AA + 1], xf, yf, zm); x3 += u * (g(perm[BA + 1], xm, yf, zm) - x3)
    x4 = g(perm[AB + 1], xf, ym, zm); x4 += u * (g(perm[BB + 1], xm, ym, zm) - x4)
    y2 = x3 + v * (x4 - x3)
    return (y1 + w * (y2 - y1)).astype(F32)


def fbm3(X, Y, Z, freq, octaves, seed, gain=0.5, lac=2.03, ridged=False):
    """Fractal sum of perlin3 octaves at points on the unit sphere: features keep their true shape on the globe (no
    stretching at the limb). Mean 0, std 1."""
    rng = np.random.default_rng(seed)
    p = rng.permutation(256).astype(np.int32)
    perm = np.concatenate([p, p])
    out = np.zeros(X.shape, F32)
    amp, f = 1.0, freq
    for _ in range(octaves):
        off = rng.uniform(-100, 100, 3).astype(F32)
        nz = perlin3(X * f + off[0], Y * f + off[1], Z * f + off[2], perm)
        if ridged:
            nz = (1.0 - np.abs(nz) * 1.6) ** 2
        out += amp * nz
        amp *= gain; f *= lac
    out -= out.mean()
    return (out / (out.std() + 1e-9)).astype(F32)


RKM = 1737.4                      # the Moon's radius, km


def sph(lon, lat):
    """unit vector of a selenographic point: +x east (right), +y north (up), +z toward the viewer"""
    lo, la = math.radians(lon), math.radians(lat)
    return np.array([math.cos(la) * math.sin(lo), math.sin(la), math.cos(la) * math.cos(lo)])


def dest(lon, lat, bearing, dist):
    """the point dist degrees from (lon, lat) along bearing (degrees from north toward east)"""
    la1, lo1, b, d = map(math.radians, (lat, lon, bearing, dist))
    la2 = math.asin(math.sin(la1) * math.cos(d) + math.cos(la1) * math.sin(d) * math.cos(b))
    lo2 = lo1 + math.atan2(math.sin(b) * math.sin(d) * math.cos(la1), math.cos(d) - math.sin(la1) * math.sin(la2))
    return math.degrees(lo2), math.degrees(la2)


class Globe:
    """The visible hemisphere at SS resolution: per pixel the sphere point (U, V, W), its latitude / longitude."""
    def __init__(self, n_out=1024, R=0.985):
        N = n_out * SS
        self.N, self.R = N, R
        self.Rpx = R * N / 2.0
        c = (np.arange(N, dtype=np.float64) + 0.5 - N / 2.0) / self.Rpx
        U = np.broadcast_to(c[None, :], (N, N)); V = np.broadcast_to(-c[:, None], (N, N))
        r2 = U * U + V * V
        self.inside = r2 < 1.0
        self.U = np.ascontiguousarray(U, F32); self.V = np.ascontiguousarray(V, F32)
        self.W = np.sqrt(np.clip(1.0 - r2, 0.0, 1.0)).astype(F32)
        self.r = np.sqrt(r2).astype(F32)                  # (in disc radii)
        self.lat = np.degrees(np.arcsin(np.clip(V, -1, 1))).astype(F32)
        self.lon = np.degrees(np.arctan2(U, self.W)).astype(F32)
        self.ii = np.nonzero(self.inside)

    def fbm(self, freq, octaves, seed, lac=2.03, **kw):
        """3D fbm over the hemisphere; smooth ones are evaluated on a coarser grid and upsampled (same noise, faster)"""
        div = int(min(8, max(1, 250.0 / (freq * lac ** (octaves - 1)))))
        while self.N % div:
            div -= 1
        if div == 1:
            out = np.zeros((self.N, self.N), F32)
            i = self.ii
            out[i] = fbm3(self.U[i], self.V[i], self.W[i], freq, octaves, seed, lac=lac, **kw)
            return out
        n = self.N // div
        c = (np.arange(n, dtype=np.float64) + 0.5 - n / 2.0) * div / self.Rpx
        U = np.broadcast_to(c[None, :], (n, n)); V = np.broadcast_to(-c[:, None], (n, n))
        rr = np.sqrt(U * U + V * V); k = np.where(rr > 0.9995, 0.9995 / np.maximum(rr, 1e-9), 1.0)
        U = (U * k).astype(F32); V = (V * k).astype(F32); W = np.sqrt(np.clip(1 - U * U - V * V, 0, 1)).astype(F32)
        small = fbm3(U, V, W, freq, octaves, seed, lac=lac, **kw)
        return np.asarray(Image.fromarray(small, "F").resize((self.N, self.N), Image.BILINEAR), F32)

    def window(self, C, rad):
        """index window covering the cap of angular radius rad round the unit vector C (None if out of sight)"""
        if C[2] < -math.sin(rad):
            return None
        cx = C[0] * self.Rpx + self.N / 2.0; cy = self.N / 2.0 - C[1] * self.Rpx
        e = math.sin(min(rad, math.pi / 2)) * self.Rpx + 3
        c0, c1 = max(0, int(cx - e)), min(self.N, int(cx + e) + 2)
        r0, r1 = max(0, int(cy - e)), min(self.N, int(cy + e) + 2)
        if c1 <= c0 or r1 <= r0:
            return None
        return slice(r0, r1), slice(c0, c1)

    def angdist(self, sl, C):
        dx = self.U[sl] - C[0]; dy = self.V[sl] - C[1]; dz = self.W[sl] - C[2]
        return (2.0 * np.arcsin(np.clip(np.sqrt(dx * dx + dy * dy + dz * dz) / 2.0, 0, 1))).astype(F32)

    def bearing(self, sl, C):
        """bearing (rad, from north toward east) of each pixel as seen from C"""
        en = np.array([0.0, 1.0, 0.0]) - C * C[1]; en /= max(np.linalg.norm(en), 1e-9)
        ee = np.cross(en, C)
        px, py, pz = self.U[sl], self.V[sl], self.W[sl]
        return np.arctan2(px * ee[0] + py * ee[1] + pz * ee[2], px * en[0] + py * en[1] + pz * en[2]).astype(F32)


def _equirect(img, lon0, lat1, ppd):
    """bilinear lookup of an equirectangular map img[lat, lon] (lat descending) at (lon, lat) degrees"""
    H, W = img.shape

    def f(lon, lat):
        x = np.clip((lon - lon0) * ppd - 0.5, 0, W - 1.001); y = np.clip((lat1 - lat) * ppd - 0.5, 0, H - 1.001)
        x0 = np.floor(x).astype(np.int32); y0 = np.floor(y).astype(np.int32)
        fx = (x - x0).astype(F32); fy = (y - y0).astype(F32)
        return (img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x0 + 1] * fx * (1 - fy)
                + img[y0 + 1, x0] * (1 - fx) * fy + img[y0 + 1, x0 + 1] * fx * fy).astype(F32)
    return f


def _outline(shape, args):
    if shape == "circle":
        lon, lat, rd = args
        return [dest(lon, lat, b, rd) for b in np.linspace(0, 360, 96, endpoint=False)]
    if shape == "ellipse":
        lon, lat, a_, b_ = args
        out = []
        for t in np.linspace(0, 2 * math.pi, 96, endpoint=False):
            e, nn = a_ * math.cos(t), b_ * math.sin(t)
            out.append(dest(lon, lat, math.degrees(math.atan2(e, nn)), math.hypot(e, nn)))
        return out
    pts = []
    for (a, b), (c, d) in zip(shape, shape[1:] + shape[:1]):          # (a polygon: densified edges)
        for t in np.linspace(0, 1, 6, endpoint=False):
            pts.append((a + (c - a) * t, b + (d - b) * t))
    return pts


def maria_maps(ppd=6):
    """The seas as maps over (lon, lat): coverage (summed, so seas that touch join up), their lava level, and how round
    each basin is (circles and ellipses keep their shape; the irregular seas' shores may wander)."""
    lon0, lon1, lat0, lat1 = -110.0, 110.0, -90.0, 90.0
    Wm, Hm = int((lon1 - lon0) * ppd), int((lat1 - lat0) * ppd)
    cov = np.zeros((Hm, Wm), F32); num = np.zeros((Hm, Wm), F32); den = np.zeros((Hm, Wm), F32)
    rnd = np.zeros((Hm, Wm), F32)
    for m in LUNAR.MARIA:
        name, level, soft = m[0], m[1], m[2]
        shape, args = (m[3], m[4]) if isinstance(m[3], str) else (m[3], None)
        im = Image.new("L", (Wm * 2, Hm * 2), 0)
        ImageDraw.Draw(im).polygon([((lo - lon0) * ppd * 2, (lat1 - la) * ppd * 2) for lo, la in _outline(shape, args)], fill=255)
        lay = np.asarray(im.resize((Wm, Hm), Image.BOX), F32) / 255.0
        ys, xs = np.nonzero(lay > 0)
        pad = int(soft * ppd * 7) + 2
        y0, y1 = max(0, ys.min() - pad), min(Hm, ys.max() + pad + 1); x0, x1 = max(0, xs.min() - pad), min(Wm, xs.max() + pad + 1)
        sub = gblur(lay[y0:y1, x0:x1], soft * ppd * 1.6)
        cov[y0:y1, x0:x1] += sub
        num[y0:y1, x0:x1] += sub * level; den[y0:y1, x0:x1] += sub
        roundness = 1.0 if isinstance(m[3], str) else (0.7 if name == "Imbrium" else 0.0)
        wide = gblur(lay[y0:y1, x0:x1], soft * ppd + 3.0 * ppd)
        rnd[y0:y1, x0:x1] = np.maximum(rnd[y0:y1, x0:x1], wide * roundness)
    lvl = (num + 0.5 * 0.05) / (den + 0.05)
    return (_equirect(np.clip(cov, 0.0, 1.0), lon0, lat1, ppd), _equirect(lvl, lon0, lat1, ppd),
            _equirect(np.clip(rnd * 1.6, 0.0, 1.0), lon0, lat1, ppd))


def _blur_mirror(h, sig):
    r = int(math.ceil(sig * 3.5))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sig) ** 2); k /= k.sum()
    return np.convolve(np.concatenate([h[1:r + 1][::-1], h, np.full(r, h[-1])]), k, mode="valid")


def crater_profile(D, kind, fresh, rng):
    """A crater's height (km) against q = distance / radius: bowl or flat floor, terraced inner wall, raised rim, central
    peaks, an ejecta skirt falling off as q^-3; older craters are smoothed. kind: s simple, c complex (central peak),
    f flat (flooded) floor, w walled plain."""
    q = np.linspace(0.0, 3.2, 641)
    if kind == "s" or D < 16:
        d = 0.20 * D * (0.55 + 0.45 * fresh)
        hr = 0.042 * D * (0.5 + 0.5 * fresh)
        h = np.where(q < 1.0, -d + (d + hr) * q ** 2.0, hr * np.maximum(q, 1e-3) ** -3.0)
    else:
        d = 1.044 * D ** 0.301 * (0.6 + 0.4 * fresh) * {"f": 0.8, "w": 0.75}.get(kind, 1.0)
        hr = 0.236 * D ** 0.399 * (0.55 + 0.45 * fresh)
        f = {"c": 0.36, "f": 0.62, "w": 0.55}.get(kind, 0.4) + 0.12 * min(1.0, max(0.0, (D - 30.0) / 150.0))
        wall = np.clip((q - f) / (1.0 - f), 0.0, 1.0) ** 1.7
        if D > 40 and fresh > 0.25:                                      # terraces: slump steps down the inner wall
            nt = 3 if D < 100 else 4
            wall = wall + 0.10 * fresh * np.sin(2 * math.pi * nt * wall) / math.pi
        h = np.where(q < 1.0, -d + (d + hr) * wall, hr * np.maximum(q, 1e-3) ** -2.6)
        if kind == "c" and D < 200:
            ph = 0.42 * d * (0.5 + 0.5 * fresh)
            h = h + ph * np.exp(-(q / (0.10 + 0.04 * rng.random())) ** 2)
            if D > 60:
                for _ in range(2):                                       # a cluster of peaks, not one cone
                    o = rng.uniform(0.04, 0.10)
                    h = h + 0.5 * ph * np.exp(-((q - o) / 0.06) ** 2)
    h = np.where(q > 3.0, 0.0, h) * sstep(3.0, 2.2, q)
    sig = (0.02 + 0.12 * (1.0 - fresh) ** 1.5) / (q[1] - q[0])
    if sig > 0.5:
        h = _blur_mirror(h, sig)
    return q, h.astype(F32)


def _add_craters(g, craters, H, bright, rng):
    """cut each crater into the height field (big ones first, so younger small ones cut into them) and record its albedo:
    fresh craters are bright (walls and an ejecta nimbus), old ones barely show"""
    for C, D, kind, fresh in craters:
        rho = (D / 2.0) / RKM
        sl = g.window(C, rho * 3.1)
        if sl is None:
            continue
        q = g.angdist(sl, C) / rho
        ins = g.inside[sl] & (q < 3.1)
        if not ins.any():
            continue
        qt, ht = crater_profile(D, kind, fresh, rng)
        if D > 25:                                                       # big rims are not perfect circles
            phi = g.bearing(sl, C)
            wob = np.zeros_like(q)
            for k in (2, 3, 5, 7):
                wob += rng.normal(0, 0.035 / k ** 0.5) * np.cos(k * phi + rng.uniform(0, 6.28))
            q = q * (1.0 + wob)
        H[sl] += np.where(ins, np.interp(q, qt, ht).astype(F32), 0.0)
        fr = fresh ** 1.6
        ej = np.where(q > 0.9, np.exp(-(q - 0.9) / (0.55 + 0.5 * fr)), 0.0)
        b = 0.03 * np.exp(-((q - 1.0) / 0.18) ** 2) + fr * (0.42 * sstep(1.05, 0.55, q) * (0.45 + 0.55 * sstep(0.0, 0.6, q)) + 0.30 * ej)
        bright[sl] = np.maximum(bright[sl], np.where(ins, b, 0.0))


def _ray_system(g, rays, collar, C, D, st, reach, nr, nimb, dcol, gap_az, gap_w, rr, NB=2048, NA=256, wscale=1.0, lobe=None):
    """A young crater's ray system (drawn into rays by max) through a polar lookup grid (bearing x distance): rays of
    many lengths that meander a little and break into clumps (chains of secondary craters), a bright nimbus round the
    crater with fine radial striations, and for Tycho a dark collar just outside the rim."""
    rho = (D / 2.0) / RKM
    amax = math.radians(reach) * 1.15 + rho * 4
    sl = g.window(C, amax)
    if sl is None:
        return
    a = g.angdist(sl, C)
    phi = g.bearing(sl, C)
    bgrid = np.linspace(0, 2 * math.pi, NB, endpoint=False)[None, :]
    agrid = np.linspace(0, amax, NA)[:, None]
    R = np.zeros((NA, NB), F32)
    reach_r = math.radians(reach)
    for _ in range(nr):
        az = rr.uniform(0, 2 * math.pi)
        if lobe is not None:                    # an oblique impact: the rays bunch round one axis, both ways along it
            az = lobe + rr.normal(0, 0.55) + (math.pi if rr.random() < 0.5 else 0.0)
        if gap_az is not None and abs((math.degrees(az) - gap_az + 180) % 360 - 180) < gap_w / 2:
            continue
        ln = reach_r * (0.22 + 0.78 * rr.random() ** 1.3)
        wid = (math.radians(rr.uniform(0.25, 0.9)) * (D / 80.0) ** 0.35 + rho * 0.35) * wscale
        for _ in range(rr.integers(1, 4)):
            az2 = az + rr.normal(0, 0.02)
            w2 = wid * rr.uniform(0.5, 1.0)
            dphi = (bgrid - az2 + math.pi) % (2 * math.pi) - math.pi
            mea = w2 * 0.8 * (np.sin(agrid / ln * rr.uniform(3, 7) + rr.uniform(0, 6.3))
                              + 0.5 * np.sin(agrid / ln * rr.uniform(9, 15) + rr.uniform(0, 6.3)))
            across = np.abs(dphi * np.sin(np.maximum(agrid, 1e-5)) - mea * sstep(0.0, ln * 0.3, agrid))
            wa = w2 * (0.5 + 0.9 * np.minimum(agrid / ln, 1.5))
            along = np.exp(-np.maximum(agrid - rho * 1.3, 0) / (ln * 0.55)) * sstep(rho * 0.9, rho * 1.8, agrid) \
                * sstep(ln * 1.15, ln * 0.6, agrid)
            R = np.maximum(R, (np.exp(-(across / wa) ** 2) * along * rr.uniform(0.5, 1.0)).astype(F32))
    R = R * np.clip(0.75 + 0.55 * noise_periodic((NA, NB), int(rr.integers(1 << 30)), beta=1.1, fmin=3.0), 0.0, 1.7)
    stri = noise_periodic((NA, NB), int(rr.integers(1 << 30)), beta=0.8, fmin=6.0, aniso=(1.0, 0.12))
    nim = nimb * np.exp(-np.maximum(agrid - rho, 0) / (rho * (1.4 + 1.6 * (D > 60)))) \
        * (0.62 + 0.38 * sstep(rho * 0.5, rho * 1.0, agrid)) * (0.7 + 0.3 * np.tanh(stri))
    R = np.maximum(R, nim.astype(F32))
    val = sample_wrap(R, np.clip(a / amax * (NA - 1), 0, NA - 1.001), (phi % (2 * math.pi)) / (2 * math.pi) * NB) * (a < amax)
    rays[sl] = np.maximum(rays[sl], st * val * g.inside[sl])
    if dcol > 0:
        collar[sl] = np.maximum(collar[sl], dcol * np.exp(-((a - rho * 1.3) / (rho * 0.4)) ** 2) * g.inside[sl])


def _splat(img, ys, xs, vals, sig):
    """add Gaussian specks (sigma sig px) at float pixel positions into img"""
    N = img.shape[0]
    rad = int(math.ceil(sig * 3))
    for dy in range(-rad, rad + 1):
        for dx in range(-rad, rad + 1):
            yy = np.floor(ys).astype(np.int64) + dy; xx = np.floor(xs).astype(np.int64) + dx
            ok = (yy >= 0) & (yy < N) & (xx >= 0) & (xx < N)
            wgt = np.exp(-0.5 * ((yy + 0.5 - ys) ** 2 + (xx + 0.5 - xs) ** 2) / (sig * sig)) * vals
            np.add.at(img, (yy[ok], xx[ok]), wgt[ok].astype(F32))


def make_moon():
    n = 1024
    light_deg, light_az, cap_deg = 22.0, 140.0, 80.0       # light 22 deg off the view axis, from the upper left
    g = Globe(n)
    N = g.N
    inside = g.inside
    rng = np.random.default_rng(1207)
    # the seas' outlines, gently warped (round basins keep their circles)
    cov_f, lvl_f, rnd_f = maria_maps()
    rnd = rnd_f(g.lon, g.lat)
    wamp = 1.0 - 0.7 * rnd
    w1 = g.fbm(3.0, 4, 11); w2 = g.fbm(3.0, 4, 12); w3 = g.fbm(10.0, 3, 16); w4 = g.fbm(10.0, 3, 17)
    coslat = np.maximum(np.cos(np.radians(g.lat)), 0.25)
    lonw = g.lon + wamp * (0.9 * w1 + 0.55 * w3) / coslat; latw = g.lat + wamp * (0.9 * w2 + 0.55 * w4)
    cov = cov_f(lonw, latw); lvl = lvl_f(lonw, latw)
    # two crater populations: the old terrain (before the lava) and the young craters (after it)
    old, young = [], []
    for name, lon, lat, D, kind, fresh in LUNAR.CRATERS:
        (young if fresh >= 0.5 else old).append((sph(lon, lat), D, kind, fresh))
    count = 0
    while count < 26000:
        z = rng.uniform(-1, 1); ph = rng.uniform(-math.pi, math.pi)
        s = math.sqrt(1 - z * z)
        C = np.array([s * math.sin(ph), z, s * math.cos(ph)])
        if C[2] < 0.03:
            continue
        D = 4.0 * (1.0 - rng.random()) ** (-1.0 / 1.85)               # N(>D) ~ D^-1.85, 4 km and up
        if D > 75:
            continue
        kind = "s" if D < 18 else ("c" if rng.random() < 0.6 else "w")
        if rng.random() < 0.075:
            young.append((C, D, kind, 0.35 + 0.65 * rng.random() ** 1.4))
        else:
            old.append((C, D, kind, 0.35 * rng.random() ** 1.5))
        count += 1
    old.sort(key=lambda c: -c[1]); young.sort(key=lambda c: -c[1])
    H = np.zeros((N, N), F32)                                           # heights, km
    bright = np.zeros((N, N), F32)
    _add_craters(g, old, H, bright, rng)
    # mountain chains on the basin rims (old terrain too)
    ridge_n = g.fbm(13.0, 3, 31, ridged=True)
    for name, pts, hkm, hw in LUNAR.RANGES:
        dense = []
        for (a1, b1), (a2, b2) in zip(pts[:-1], pts[1:]):
            for t in np.linspace(0, 1, 12, endpoint=False):
                dense.append((a1 + (a2 - a1) * t, b1 + (b2 - b1) * t))
        dense.append(pts[-1])
        lon_c = np.mean([p[0] for p in pts]); lat_c = np.mean([p[1] for p in pts])
        ext = max(max(abs(p[0] - lon_c) * math.cos(math.radians(lat_c)), abs(p[1] - lat_c)) for p in pts) + 4 * hw
        sl = g.window(sph(lon_c, lat_c), math.radians(ext))
        if sl is None:
            continue
        dmin = np.full(H[sl].shape, 1e9, F32)
        for lo, la in dense:
            dmin = np.minimum(dmin, np.degrees(g.angdist(sl, sph(lo, la))))
        prof = np.exp(-(dmin / hw) ** 2)
        H[sl] += hkm * prof * (0.45 + 0.75 * np.clip(ridge_n[sl], 0, None) ** 1.2) * inside[sl]
        bright[sl] = np.maximum(bright[sl], 0.12 * prof * inside[sl])
    # the lava flood: inside the basins the low ground fills first, so the shores follow the old relief; some shores
    # sharp, some gradual, a patchy mixing zone; the flooded craters survive as faint ghost rings
    sh1 = g.fbm(8.0, 4, 13); sh2 = g.fbm(24.0, 3, 14); sh3 = g.fbm(60.0, 3, 15); ew = g.fbm(4.0, 3, 19)
    raw = (cov - 0.5) * 1.25 + 0.5 - 0.15 * gblur(H, 1.5) * sstep(0.04, 0.3, cov) + 0.05 * sh1 * wamp + 0.035 * sh2
    raw = raw + np.clip(1.0 - np.abs(raw - 0.5) * 2.0, 0.0, 1.0) * (0.10 * sh2 + 0.07 * sh3)
    wdt = 0.06 + 0.28 * sstep(-0.4, 1.0, ew) * (1.0 - 0.5 * rnd)
    mare = sstep(0.5 - wdt, 0.5 + wdt, raw)
    H = H * (1.0 - 0.75 * mare)
    _add_craters(g, young, H, bright, rng)
    mare_core = sstep(0.55, 0.97, gblur(mare, 28.0))
    mare_t = 0.82 * mare + 0.18 * gblur(mare, 6.0)
    # albedo: mottled highlands; maria with darker and lighter lava units
    big = g.fbm(1.4, 4, 21); mid = g.fbm(4.5, 4, 22); fine = g.fbm(16.0, 4, 23, gain=0.6)
    high = 0.75 + 0.048 * np.tanh(1.3 * big) + 0.022 * np.tanh(1.2 * mid) + 0.012 * fine
    mu1 = g.fbm(3.0, 4, 25); mu2 = g.fbm(9.0, 4, 26); mu3 = g.fbm(40.0, 3, 27, gain=0.6)
    mlv = lvl - 0.088 + 0.018 * big + 0.032 * np.tanh(2.6 * mu1) + 0.016 * mu2 + 0.012 * fine + 0.010 * mu3
    for lon, lat, rd, dlt in LUNAR.PATCHES:
        C = sph(lon, lat)
        sl = g.window(C, math.radians(rd * 2.5))
        if sl is not None:
            mlv[sl] += dlt * np.exp(-(np.degrees(g.angdist(sl, C)) / rd) ** 2)
    C = sph(17.5, 28.0); sl = g.window(C, math.radians(14))
    mlv[sl] -= 0.055 * np.exp(-((np.degrees(g.angdist(sl, C)) - 10.0) / 1.7) ** 2)      # Serenitatis' dark border
    mlv = mlv + 0.03 * (1.0 - mare_core)                                 # sea edges a little lighter (mixed ejecta)
    alb = high * (1 - mare_t) + mlv * mare_t
    # ray systems: the big young craters, then ~500 small ones (a third of them lopsided)
    rays = np.zeros((N, N), F32)
    collar = np.zeros((N, N), F32)
    for (name, lon, lat, D, st, reach, nr, nimb, dcol, gap_az, gap_w) in LUNAR.RAYED:
        rr = np.random.default_rng(sum(ord(c) * 131 ** i for i, c in enumerate(name)) % (2 ** 31))
        _ray_system(g, rays, collar, sph(lon, lat), D, st, reach, nr, nimb, dcol, gap_az, gap_w, rr)
    for _ in range(520):
        z = rng.uniform(0.05, 1.0); ph = rng.uniform(-math.pi, math.pi)
        s0 = math.sqrt(1 - z * z)
        C = np.array([s0 * math.cos(ph), s0 * math.sin(ph), z])
        D = 3.0 + 13.0 * rng.random() ** 2
        reach = (0.8 + 3.2 * rng.random() ** 1.5) * (D / 8.0) ** 0.5
        st = rng.uniform(0.14, 0.42)
        lobe = rng.uniform(0, 2 * math.pi) if rng.random() < 0.6 else None
        _ray_system(g, rays, collar, C, D, st, reach, int(rng.integers(3, 8)), 0.9, 0.0, None, 0, rng, NB=512, NA=64,
                    wscale=1.8, lobe=lobe)
    for lon, lat, brg, ln_deg, w_deg, st in LUNAR.STREAKS:              # Messier A's twin rays, Tycho's longest rays
        C = sph(lon, lat)
        amax = math.radians(ln_deg * 1.1)
        sl = g.window(C, amax)
        a = g.angdist(sl, C)
        dphi = (g.bearing(sl, C) - math.radians(brg) + math.pi) % (2 * math.pi) - math.pi
        ln = math.radians(ln_deg)
        sd = int(abs(lon * 1000 + brg * 7)) % 99991
        alongn = noise_periodic((1, 1024), sd, beta=1.5, fmin=3.0)[0]
        jit = noise_periodic((1, 1024), sd + 1, beta=2.0, fmin=1.0)[0]
        idx = np.clip(a / amax * 1023, 0, 1023).astype(np.int32)
        wv = math.radians(w_deg * 0.5) * (0.6 + 0.6 * np.clip(0.5 + 0.4 * alongn[(idx + 300) % 1024], 0, 1))
        across = np.abs(dphi * np.sin(np.maximum(a, 1e-5)) - math.radians(w_deg) * 0.9 * jit[idx])
        v = np.exp(-(across / wv) ** 2) * sstep(ln, ln * 0.4, a) * sstep(0.0, ln * 0.08, a) \
            * np.clip(0.85 + 0.4 * alongn[idx], 0.15, 1.6) * (np.abs(dphi) < math.pi / 2)
        rays[sl] = np.maximum(rays[sl], st * v * inside[sl])
    rays = rays * np.clip(0.9 + 0.25 * g.fbm(22.0, 4, 41), 0.3, 1.4)
    C = sph(-59.0, 7.5); sl = g.window(C, math.radians(3.0))           # Reiner Gamma, the bright swirl
    a = np.degrees(g.angdist(sl, C)); phi = g.bearing(sl, C)
    ex = a * np.sin(phi); ny = a * np.cos(phi)
    loop = np.exp(-((np.hypot(ex / 1.0, ny / 0.55) - 0.75) / 0.18) ** 2) \
        + 0.6 * np.exp(-((ny + 0.2) / 0.25) ** 2) * sstep(0.0, -1.6, ex) * sstep(-2.6, -1.0, ex)
    bright[sl] = np.maximum(bright[sl], 0.30 * loop * inside[sl])
    # unresolved craterlets: a fine speckle of bright and dark specks
    nsp = 160000
    th_ = np.arccos(rng.uniform(0.0, 1.0, nsp)); pp = rng.uniform(-math.pi, math.pi, nsp)
    xs = N / 2 + np.sin(th_) * np.cos(pp) * g.Rpx; ys = N / 2 - np.sin(th_) * np.sin(pp) * g.Rpx
    val = rng.pareto(2.2, nsp).clip(0, 6) * 0.05
    spk = np.zeros((N, N), F32); spd = np.zeros((N, N), F32)
    _splat(spk, ys, xs, val.astype(F32), 0.8)
    dark = rng.random(nsp) < 0.35
    _splat(spd, ys[dark], xs[dark], (val[dark] * 0.6).astype(F32), 1.1)
    spk *= (1 - 0.2 * mare); spd *= (1 - 0.3 * mare)
    alb = alb * (1.0 - 0.32 * collar) * (1.0 - np.clip(spd, 0, 0.3))
    alb = alb + (1.0 - alb) * np.clip(bright + spk, 0, 1)
    alb = alb + (0.975 - alb) * np.clip(rays * 1.15, 0, 1)
    # relief: the height field (plus fine roughness and wrinkle ridges on the seas) bends the normals
    rough = g.fbm(34.0, 4, 51, gain=0.55) * (0.22 * (1 - mare) + 0.06 * mare)
    rough = rough + 0.30 * np.clip(g.fbm(12.0, 3, 52, ridged=True) - 0.45, 0, None) * mare
    Hs = H / RKM
    gy, gx = np.gradient((H + rough) / RKM)
    hu = gx * g.Rpx; hv = -gy * g.Rpx
    sm = np.sqrt(hu * hu + hv * hv) * np.maximum(g.W, 0.05)
    lim = np.where(sm > 0.85, 0.85 / np.maximum(sm, 1e-9), 1.0)     # (no slope steeper than ~40 deg: no pinholes)
    hu = hu * lim; hv = hv * lim
    u, v = g.U, g.V
    w = np.maximum(g.W, 1e-3)
    fade = sstep(0.02, 0.10, g.W)
    nx = u - ((w * w + v * v) * hu - u * v * hv) * fade
    ny = v - (-u * v * hu + (w * w + u * u) * hv) * fade
    nz = g.W + w * (u * hu + v * hv) * fade
    nl = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-9
    nx /= nl; ny /= nl; nz /= nl
    al = math.radians(light_deg); az_ = math.radians(light_az)
    Ld = np.array([math.sin(al) * math.cos(az_), math.sin(al) * math.sin(az_), math.cos(al)])
    mu0 = u * Ld[0] + v * Ld[1] + g.W * Ld[2]
    # the light never falls below 10 deg above any local horizon (cos 80): no dark side, the whole disc stays lit
    mu_min = math.cos(math.radians(cap_deg))
    mu_eff = np.clip(0.5 * (mu0 + mu_min + np.sqrt((mu0 - mu_min) ** 2 + 0.01)), mu_min, 1.0)
    Tx = Ld[0] - mu0 * u; Ty = Ld[1] - mu0 * v; Tz = Ld[2] - mu0 * g.W
    Tn = np.sqrt(Tx * Tx + Ty * Ty + Tz * Tz) + 1e-9
    Tx /= Tn; Ty /= Tn; Tz /= Tn
    s_ = np.sqrt(np.clip(1 - mu_eff ** 2, 0, 1))
    m0l = nx * (mu_eff * u + s_ * Tx) + ny * (mu_eff * v + s_ * Ty) + nz * (mu_eff * g.W + s_ * Tz)
    lam = 0.15                                                          # lunar-Lambert: Lommel-Seeliger + a little Lambert
    f_loc = np.maximum(m0l, 0) / (np.maximum(m0l, 0) + np.maximum(nz, 0.02)) + lam * np.maximum(m0l, 0)
    f_sm = mu_eff / (mu_eff + np.maximum(g.W, 0.02)) + lam * mu_eff
    rel = np.clip(f_loc / f_sm, 0.0, 2.5)
    # cast shadows: march toward the light over the height field
    tan_e = mu_eff / np.maximum(s_, 1e-3)
    iy, ix = np.nonzero(inside & (mu_eff < 0.75))
    h0 = Hs[iy, ix]; te = tan_e[iy, ix]; dx = Tx[iy, ix]; dy = -Ty[iy, ix]
    maxexc = np.full(len(iy), -1.0, F32)
    ds = 1.0 / g.Rpx
    for k in range(1, 72):
        s = k * ds
        xx = np.clip(ix + k * dx, 0, N - 1.001); yy = np.clip(iy + k * dy, 0, N - 1.001)
        x0 = xx.astype(np.int32); y0 = yy.astype(np.int32); fx = xx - x0; fy = yy - y0
        hk = (Hs[y0, x0] * (1 - fx) * (1 - fy) + Hs[y0, x0 + 1] * fx * (1 - fy) + Hs[y0 + 1, x0] * (1 - fx) * fy
              + Hs[y0 + 1, x0 + 1] * fx * fy)
        np.maximum(maxexc, (hk - (h0 + s * te + 0.5 * s * s)) / s, out=maxexc)
    vis = np.ones((N, N), F32)
    vis[iy, ix] = np.clip(0.5 - maxexc / 0.0094, 0.0, 1.0)
    # the disc: nearly flat (full moon), a touch of the real fall-off away from the light, a little limb darkening
    macro = 0.55 + 0.45 * np.minimum(np.clip(f_sm / (Ld[2] / (Ld[2] + 1.0) + lam * Ld[2]), 0.0, 1.6), 1.15)
    macro = macro * (1.0 - 0.10 * (1.0 - g.W) ** 2.5)
    L = np.clip(alb * macro * (rel * vis + (1 - vis) * 0.10), 0.0, 1.0).astype(F32)
    C3 = bleed(np.dstack([L, L, L]), inside, rings=10)
    A = np.clip((0.985 + 0.008 - g.r * g.R) / 0.016, 0.0, 1.0).astype(F32)
    img = finish("te5_moon", (C3 * A[..., None]).astype(F32), A, dither=True)
    gr = img[..., 0].astype(np.float64); a8 = img[..., 3]
    print(f"  moon: grey p5/p50/p95 inside = {np.percentile(gr[a8 == 255], 5):.0f} / {np.percentile(gr[a8 == 255], 50):.0f} / "
          f"{np.percentile(gr[a8 == 255], 95):.0f}  ({len(old) + len(young)} craters)")
    return img


# --------------------------------------------------------------------------------------------------------------------
# 13. te5_star_window  (1024^2): deep space for the clock's movement plate (behind the skeleton dial), opaque near-black
#     (alpha 1 to r 0.985). A faint, gently curved Milky-Way band at 32 deg: star clouds brighter toward one end, the
#     Great Rift down its middle, branching dark filaments and a few dark globules, two faint emission clouds. ~22,000
#     stars with a real magnitude spread (N(<m) ~ 10^(0.4 m) over 8 magnitudes), denser in the band and dimmed behind the
#     dust, each drawn with a point-spread halo; the 8 brightest with short diffraction spikes; ~260,000 unresolved
#     stars as the band's grain; 34 small distant galaxies. Still dark overall (mean L ~0.07).
# --------------------------------------------------------------------------------------------------------------------

def _psf(shape, sig_core, halos):
    """a star's point-spread function (sharp core + faint wide halos), centred at [0, 0] for an FFT convolution"""
    H, W = shape
    y = np.fft.fftfreq(H) * H; x = np.fft.fftfreq(W) * W
    d2 = (y[:, None] ** 2 + x[None, :] ** 2).astype(F32)
    k = np.exp(-0.5 * d2 / sig_core ** 2) / (2 * math.pi * sig_core ** 2)
    for frac, s in halos:
        k = k * (1 - frac) + frac * np.exp(-0.5 * d2 / s ** 2) / (2 * math.pi * s ** 2)
    return k.astype(F32)


def make_star_window():
    n = 1024
    seed = 1301
    NS = n * SS
    X, Y, r, th = disc_grid(n)
    shp = r.shape
    rng = np.random.default_rng(seed)
    # the band: gently curved and warped, star clouds brighter toward the galactic centre's side
    ang = math.radians(32.0)
    along = X * math.cos(ang) + Y * math.sin(ang)
    acr = -X * math.sin(ang) + Y * math.cos(ang) - 0.06 * along ** 2 + 0.05 * cart_noise(n, seed + 1, beta=1.8, fmin=1.5)
    core = np.exp(-0.5 * (acr / 0.13) ** 2)
    halo = np.exp(-0.5 * (acr / 0.32) ** 2)
    clouds = unit01(cart_noise(n, seed + 2, beta=1.3, fmin=3.0), 1.2)
    clouds2 = unit01(cart_noise(n, seed + 3, beta=1.0, fmin=10.0), 1.2)
    band = (0.65 * core + 0.35 * halo) * (0.55 + 0.5 * clouds) * (0.8 + 0.25 * clouds2) * (0.75 + 0.45 * np.exp(-((along - 0.28) / 0.35) ** 2))
    # dust: the Great Rift, branching filaments, patches and a few dark globules
    rift_c = 0.015 + 0.03 * cart_noise(n, seed + 4, beta=2.0, fmin=1.5)
    rift = np.exp(-0.5 * ((acr - rift_c) / (0.022 + 0.018 * unit01(cart_noise(n, seed + 5, beta=1.6, fmin=3.0), 1.0))) ** 2)
    rift = rift * sstep(-0.75, -0.2, along) * (0.6 + 0.5 * unit01(cart_noise(n, seed + 6, beta=1.2, fmin=6.0), 1.2))
    fil = np.exp(-(cart_noise(n, seed + 7, beta=1.25, fmin=5.0) / 0.18) ** 2) * (0.4 + 0.6 * core) \
        * unit01(cart_noise(n, seed + 8, beta=1.4, fmin=4.0), 1.0)
    patches = np.clip((cart_noise(n, seed + 9, beta=1.5, fmin=4.0) - 0.9) * 1.2, 0, 1) * halo
    dust = np.clip(np.maximum(np.maximum(rift, 0.75 * fil), patches), 0, 1)
    for _ in range(5):
        a_ = rng.uniform(-0.6, 0.6); c_ = rng.normal(0, 0.12)
        gx = a_ * math.cos(ang) - c_ * math.sin(ang); gy = a_ * math.sin(ang) + c_ * math.cos(ang)
        s_ = rng.uniform(0.008, 0.02)
        dust = np.maximum(dust, np.exp(-((X - gx) ** 2 + (Y - gy) ** 2) / (2 * s_ * s_)))
    trans = 1.0 - 0.88 * dust
    neb = np.zeros(shp, F32)
    wisp = unit01(cart_noise(n, seed + 10, beta=1.1, fmin=6.0), 1.0)
    for (a_, c_, s_) in ((-0.35, 0.05, 0.10), (0.42, -0.07, 0.08)):
        gx = a_ * math.cos(ang) - c_ * math.sin(ang); gy = a_ * math.sin(ang) + c_ * math.cos(ang)
        neb += np.exp(-((X - gx) ** 2 + (Y - gy) ** 2) / (2 * s_ * s_)) * wisp ** 2
    sky = 0.016 + 0.006 * unit01(cart_noise(n, seed + 11, beta=0.9, fmin=6.0), 1.0)
    diffuse = sky + trans * (0.20 * band * (0.7 + 0.6 * clouds) + 0.06 * neb)

    def scatter(count, dens_fn):
        px_ = rng.uniform(-1, 1, count * 4); py_ = rng.uniform(-1, 1, count * 4)
        ok = np.hypot(px_, py_) < 0.99
        px_, py_ = px_[ok], py_[ok]
        ix = np.clip(((px_ * 0.5 + 0.5) * NS).astype(np.int64), 0, NS - 1); iy = np.clip(((0.5 - py_ * 0.5) * NS).astype(np.int64), 0, NS - 1)
        d_ = dens_fn(iy, ix)
        keep = rng.random(len(d_)) < d_ / d_.max()
        return (px_[keep][:count] * 0.5 + 0.5) * NS, (0.5 - py_[keep][:count] * 0.5) * NS
    # the stars: magnitudes 0..8 below the brightest (N(<m) ~ 10^(0.4 m)), flux in SS-pixel units
    xs, ys = scatter(22000, lambda iy, ix: (0.10 + 1.9 * band[iy, ix]) * trans[iy, ix])
    mag = np.log10(1 + rng.random(len(xs)) * (10 ** (0.4 * 8.0) - 1)) / 0.4
    flux = (10 ** (-0.4 * mag) * 700.0).astype(F32)
    acc = deposit(shp, xs, ys, flux)
    gx_, gy_ = scatter(260000, lambda iy, ix: (0.03 + 1.6 * band[iy, ix]) * trans[iy, ix])    # unresolved: the grain
    acc += deposit(shp, gx_, gy_, (0.12 + 0.30 * rng.random(len(gx_)) ** 2).astype(F32))
    light = np.fft.irfft2(np.fft.rfft2(acc) * np.fft.rfft2(_psf(shp, 1.0, [(0.06, 4.0), (0.02, 14.0), (0.012, 34.0)])),
                          s=shp).astype(F32)
    starL = 1.0 - np.exp(-light * 0.9)
    # the bright stars' glow (the optics scatter a bright star's light into a soft disc: it still reads small)
    bright = np.nonzero(flux > 40.0)[0]
    fr_ = np.sqrt(flux[bright] / flux.max())
    starL = screen(starL, soft_dots(shp, xs[bright], ys[bright], 3.0 + 7.0 * fr_, 0.10 + 0.40 * fr_))
    # short diffraction spikes on the 8 brightest
    order = np.argsort(-flux)[:8]
    spikes = np.zeros(shp, F32)
    for i in order:
        cx, cy, f = xs[i], ys[i], flux[i]
        Ls = 10.0 + 18.0 * math.sqrt(f / flux[order[0]])
        R = int(Ls * 3)
        x0, x1 = max(0, int(cx) - R), min(NS, int(cx) + R + 1); y0, y1 = max(0, int(cy) - R), min(NS, int(cy) + R + 1)
        DX = np.arange(x0, x1, dtype=F32)[None, :] + 0.5 - cx; DY = np.arange(y0, y1, dtype=F32)[:, None] + 0.5 - cy
        sp = np.exp(-np.abs(DX) / Ls) * np.exp(-0.5 * (DY / 0.8) ** 2) + np.exp(-np.abs(DY) / Ls) * np.exp(-0.5 * (DX / 0.8) ** 2)
        spikes[y0:y1, x0:x1] = np.maximum(spikes[y0:y1, x0:x1], sp * 0.7 * min(1.0, f / flux[order[0]] * 2.5))
    # small distant galaxies: elliptical smudges, some with two faint arms
    gal = np.zeros(shp, F32)
    for _ in range(34):
        while True:
            gx, gy = rng.uniform(-0.95, 0.95, 2)
            if math.hypot(gx, gy) < 0.95:
                break
        cx = (gx * 0.5 + 0.5) * NS; cy = (0.5 - gy * 0.5) * NS
        a_ = rng.uniform(2.0, 7.0); q_ = rng.uniform(0.25, 1.0); pa = rng.uniform(0, math.pi)
        R = int(a_ * 4)
        x0, x1 = max(0, int(cx) - R), min(NS, int(cx) + R + 1); y0, y1 = max(0, int(cy) - R), min(NS, int(cy) + R + 1)
        DX = np.arange(x0, x1, dtype=F32)[None, :] + 0.5 - cx; DY = np.arange(y0, y1, dtype=F32)[:, None] + 0.5 - cy
        uu = DX * math.cos(pa) + DY * math.sin(pa); vv = -DX * math.sin(pa) + DY * math.cos(pa)
        rr = np.sqrt(uu * uu + (vv / q_) ** 2) / a_
        prof = np.exp(-3.0 * rr ** 0.6) * rng.uniform(0.25, 0.6)
        if rng.random() < 0.3:
            prof = prof * (0.75 + 0.35 * np.cos(2 * np.arctan2(vv / q_, uu) - 2.2 * np.log(np.maximum(rr, 1e-3))))
        gal[y0:y1, x0:x1] = np.maximum(gal[y0:y1, x0:x1], prof * trans[y0:y1, x0:x1])
    L = screen(diffuse, starL, spikes, gal * 0.7)
    A = np.clip((0.985 + 0.008 - r) / 0.016, 0.0, 1.0)
    rgb = np.dstack([L, L, L]).astype(F32)
    img = finish("te5_star_window", (rgb * A[..., None]).astype(F32), A.astype(F32), dither=True)
    print(f"  star window: mean L inside = {img[..., 0][img[..., 3] == 255].mean() / 255:.3f}")
    return img


# --------------------------------------------------------------------------------------------------------------------
# 10. te5_stream  (512x128, beam band tiled in U; was 256x64, same 4:1 aspect, so the module's TextureLength and Wrap
#     map it the same way): the palm streams (B1 silver, B3 ink via Beam Color) and the void's lensed band.
#     Image x runs ALONG the beam (seamless every 512 px), y across it (v in [-0.5, 0.5]). Opaque body (alpha 1 for
#     |v| < 0.40, 1.5 px edge) with ink edges (|v| 0.33-0.40): a braid of luminous strands twisting round each other (the
#     near half of each turn brighter, so the braid has depth), two thinner strands winding twice as fast, fine flowing
#     striations, a soft glow round the strands and a darker body between them. Tinted ink it is a solid ink stream with a
#     faint woven structure.
# --------------------------------------------------------------------------------------------------------------------

def make_stream():
    W, H = 512, 128
    Ws, Hs = W * SS, H * SS
    u = ((np.arange(Ws, dtype=F32) + 0.5) / Ws)[None, :]
    v = ((np.arange(Hs, dtype=F32) + 0.5) / Hs - 0.5)[:, None]
    av = np.abs(v)
    rng = np.random.default_rng(1001)
    TAU = 2 * math.pi
    stri = noise_periodic((Hs, Ws), 1003, beta=0.8, fmin=6.0, fmax=60.0, aniso=(1.0, 8.0))     # flowing striations
    light = np.zeros((Hs, Ws), F32); glow = np.zeros((Hs, Ws), F32)
    # (amplitude across, turns per tile, phase, width px, brightness): integer turns only, so the tile is seamless
    strands = [(0.15, 1, i / 3.0, 5.0, 1.0) for i in range(3)] + [(0.21, 2, 0.1 + 0.5 * i, 2.0, 0.85) for i in range(2)]
    for a, k, ph0, w, b in strands:
        ph = TAU * (k * u + ph0)
        cv = a * np.sin(ph) + 0.008 * np.sin(TAU * 3 * u + rng.uniform(0, TAU))
        z = np.cos(ph)                                                   # +1: the near side of the turn
        slope = a * np.cos(ph) * TAU * k * (H / W)
        d_px = np.abs(v - cv) * H / np.sqrt(1.0 + slope * slope)        # distance across the strand, px
        wpx = w * (1.0 + 0.25 * z)
        bz = b * (0.50 + 0.50 * (0.5 + 0.5 * z)) * (0.86 + 0.14 * np.tanh(1.5 * stri))
        light = 1.0 - (1.0 - light) * (1.0 - np.exp(-0.5 * (d_px / wpx) ** 2) * bz)
        glow = 1.0 - (1.0 - glow) * (1.0 - np.exp(-0.5 * (d_px / (wpx * 1.7)) ** 2) * bz * 0.35)
    lines = np.zeros((Hs, Ws), F32)
    for _ in range(10):                                                  # fine threads along the flow, bright in runs
        cv = rng.uniform(-0.26, 0.26) + rng.uniform(0.004, 0.015) * np.sin(TAU * int(rng.integers(1, 3)) * u + rng.uniform(0, TAU))
        seg = np.clip(0.45 + 0.7 * noise_periodic((1, Ws), int(rng.integers(1 << 30)), beta=1.3, fmin=2.0, fmax=14.0), 0, 1)
        lines = 1.0 - (1.0 - lines) * (1.0 - np.exp(-0.5 * (np.abs(v - cv) * H / 0.6) ** 2) * seg * rng.uniform(0.35, 0.7))
    body = 0.24 + 0.08 * np.exp(-0.5 * (av / 0.12) ** 2)
    L = screen(body, glow * 0.5, light, lines * 0.5) * (1.0 - 0.35 * sstep(0.22, 0.33, av))   # (rounded: darker edges)
    edge = sstep(0.300, 0.335, av)
    L = L * (1 - edge) + (12.0 / 255.0) * edge
    A = np.broadcast_to(np.clip((0.40 - av) / (1.5 / H) + 0.5, 0.0, 1.0), (Hs, Ws)).astype(F32)
    L = np.clip(L, 0, 1)
    rgb = np.dstack([L, L, L]).astype(F32)
    return finish("te5_stream", (rgb * A[..., None]).astype(F32), A, dither=True)


# --------------------------------------------------------------------------------------------------------------------
# contact sheets + in-game-size mock-ups (sheets/).  These are review aids, not uploads.  They composite the PNGs the
# way a SurfaceGui with LightInfluence 0 draws them: colour x Brightness (clipped), over the background, plus a rough
# bloom for the part above 1 at night (place Bloom: threshold ~2 in Studio's units; here simply "above white").
# --------------------------------------------------------------------------------------------------------------------

BG_DARK = (11, 12, 16)        # #0b0c10
BG_SKY = (126, 200, 240)      # #7ec8f0
SAND = (222, 205, 160)        # the plaza's sand path (from the Studio captures)
GRASS = (104, 178, 74)
NIGHT_GROUND = (46, 56, 52)


def _font(sz):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf",
              "/Library/Fonts/Arial.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def load(name):
    return np.asarray(Image.open(os.path.join(OUT, name + ".png")).convert("RGBA"), F32) / 255.0


def resize_premult(img, w, h):
    """Minify like a mip-mapped texture would (premultiplied, Lanczos)."""
    a = img[..., 3]
    p = img[..., :3] * a[..., None]
    def rs(ch):
        return np.asarray(Image.fromarray(ch.astype(F32), "F").resize((w, h), Image.LANCZOS), F32)
    P = np.dstack([rs(p[..., i]) for i in range(3)]); A = np.clip(rs(a), 0, 1)
    C = np.where(A[..., None] > 1e-5, P / np.maximum(A, 1e-5)[..., None], 0.0)
    return np.dstack([np.clip(C, 0, 1), A]).astype(F32)


def rotate_rgba(img, deg):
    """Rotate a square RGBA float image about its centre (premultiplied, bicubic)."""
    a = img[..., 3]; p = img[..., :3] * a[..., None]
    def rt(ch):
        return np.asarray(Image.fromarray(ch.astype(F32), "F").rotate(deg, resample=Image.BICUBIC), F32)
    P = np.dstack([rt(p[..., i]) for i in range(3)]); A = np.clip(rt(a), 0, 1)
    C = np.where(A[..., None] > 1e-5, P / np.maximum(A, 1e-5)[..., None], 0.0)
    return np.dstack([np.clip(C, 0, 1), A]).astype(F32)


def _persp_coeffs(src, dst):
    """PIL PERSPECTIVE coefficients mapping OUTPUT (dst) points to INPUT (src) points."""
    m = []; b = []
    for (x, y), (u, v) in zip(dst, src):
        m.append([x, y, 1, 0, 0, 0, -u * x, -u * y]); b.append(u)
        m.append([0, 0, 0, x, y, 1, -v * x, -v * y]); b.append(v)
    return np.linalg.solve(np.asarray(m, np.float64), np.asarray(b, np.float64)).tolist()


def warp_rgba(img, out_wh, dst_quad):
    """Map the image's corners (TL, TR, BR, BL) onto dst_quad in an out_wh canvas (premultiplied, bicubic)."""
    h, w = img.shape[:2]
    co = _persp_coeffs([(0, 0), (w, 0), (w, h), (0, h)], dst_quad)
    a = img[..., 3]; p = img[..., :3] * a[..., None]
    def tf(ch):
        return np.asarray(Image.fromarray(ch.astype(F32), "F").transform(out_wh, Image.PERSPECTIVE, co,
                                                                       resample=Image.BICUBIC), F32)
    P = np.dstack([tf(p[..., i]) for i in range(3)]); A = np.clip(tf(a), 0, 1)
    C = np.where(A[..., None] > 1e-5, P / np.maximum(A, 1e-5)[..., None], 0.0)
    return np.dstack([np.clip(C, 0, 1), A]).astype(F32)


class Comp:
    """A float RGB canvas with an HDR side-buffer for bloom."""
    def __init__(self, w, h, bg):
        self.rgb = np.ones((h, w, 3), F32) * (np.asarray(bg, F32) / 255.0)
        self.hdr = np.zeros((h, w), F32)

    def put(self, img, x0, y0, bright=1.0, color=(255, 255, 255), alpha_mul=1.0):
        h, w = img.shape[:2]
        H, W = self.rgb.shape[:2]
        xa, ya = max(0, x0), max(0, y0); xb, yb = min(W, x0 + w), min(H, y0 + h)
        if xb <= xa or yb <= ya:
            return
        sub = img[ya - y0:yb - y0, xa - x0:xb - x0]
        c = sub[..., :3] * (np.asarray(color, F32) / 255.0) * bright
        a = sub[..., 3:4] * alpha_mul
        self.rgb[ya:yb, xa:xb] = self.rgb[ya:yb, xa:xb] * (1 - a) + np.minimum(c, 1.0) * a
        self.hdr[ya:yb, xa:xb] = self.hdr[ya:yb, xa:xb] * (1 - a[..., 0]) + np.max(np.maximum(c - 1.0, 0), axis=2) * a[..., 0]

    def disc(self, cx, cy, r_in, r_out, rgb, alpha=1.0):
        H, W = self.rgb.shape[:2]
        yy, xx = np.mgrid[0:H, 0:W].astype(F32)
        d = np.hypot(xx + 0.5 - cx, yy + 0.5 - cy)
        a = (np.clip(r_out - d + 0.5, 0, 1) * np.clip(d - r_in + 0.5, 0, 1) * alpha)[..., None]
        self.rgb = self.rgb * (1 - a) + (np.asarray(rgb, F32) / 255.0) * a
        self.hdr *= (1 - a[..., 0])

    def image(self, bloom=0.0):
        out = self.rgb.copy()
        if bloom > 0:
            b = gblur(self.hdr, 6.0) * 0.8 + gblur(self.hdr, 18.0) * 0.6
            out = out + bloom * b[..., None]
        return Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")


def label(im, text, xy, sz=15, fill=(235, 235, 240)):
    d = ImageDraw.Draw(im)
    f = _font(sz)
    x, y = xy
    d.text((x + 1, y + 1), text, font=f, fill=(0, 0, 0))
    d.text((x, y), text, font=f, fill=fill)


SHEET_ORDER = ["te5_dial_inlay", "te5_subdial", "te5_accretion", "te5_galaxy_floor", "te5_galaxy_arms", "te5_galaxy_core",
               "te5_engraving", "te5_halo", "te5_stream", "te5_moon", "te5_star_window"]


def sheet_overview():
    """All 12 textures over the dark and the sky background (tiles 400 px; beams tiled 2x along U)."""
    tile, pad, cols = 400, 14, 4
    rows = math.ceil(len(SHEET_ORDER) / cols)
    paths = []
    for bgname, bg in (("dark", BG_DARK), ("sky", BG_SKY)):
        W = cols * (tile + pad) + pad; H = rows * (tile + pad + 22) + pad
        cp = Comp(W, H, (30, 31, 36))
        im_labels = []
        for i, nm in enumerate(SHEET_ORDER):
            cx = pad + (i % cols) * (tile + pad); cy = pad + (i // cols) * (tile + pad + 22) + 22
            cp.disc(0, 0, 0, 0, (0, 0, 0), 0)    # no-op keeps the API uniform
            cp.rgb[cy:cy + tile, cx:cx + tile] = np.asarray(bg, F32) / 255.0
            img = load(nm)
            h, w = img.shape[:2]
            if w != h:     # beams: two periods along U, scaled to the tile width
                img = np.concatenate([img, img], axis=1)
                sc = tile / img.shape[1]
                img = resize_premult(img, tile, max(1, int(round(img.shape[0] * sc * 2))))
                cp.put(img, cx, cy + tile // 2 - img.shape[0] // 2)
            else:
                img = resize_premult(img, tile, tile)
                cp.put(img, cx, cy)
            im_labels.append((nm + f"  {w}x{h}", (cx, cy - 20)))
        out = cp.image()
        for t, xy in im_labels:
            label(out, t, xy)
        p = os.path.join(SHEETS, f"overview_{bgname}.png"); out.save(p); paths.append(p)
    return paths


def sheet_zoom():
    """1:1 / 2:1 detail crops (the pixels themselves) over both backgrounds."""
    crops = [("te5_dial_inlay", (400, 0, 624, 150), 2), ("te5_dial_inlay", (700, 760, 900, 930), 2),
             ("te5_subdial", (128, 0, 384, 200), 2), ("te5_engraving", (420, 0, 604, 120), 3),
             ("te5_accretion", (600, 40, 1000, 300), 1),
             ("te5_galaxy_floor", (430, 300, 830, 560), 1), ("te5_galaxy_arms", (520, 120, 860, 400), 1),
             ("te5_galaxy_core", (160, 160, 352, 352), 2), ("te5_halo", (256, 0, 512, 256), 1),
             ("te5_stream", (0, 0, 512, 128), 2),
             ("te5_moon", (250, 600, 650, 900), 1), ("te5_moon", (230, 250, 630, 510), 1),
             ("te5_star_window", (420, 420, 620, 620), 2)]
    paths = []
    for bgname, bg in (("dark", BG_DARK), ("sky", BG_SKY)):
        tiles = []
        for nm, (x0, y0, x1, y1), z in crops:
            img = load(nm)[y0:y1, x0:x1]
            img = np.repeat(np.repeat(img, z, 0), z, 1)
            cp = Comp(img.shape[1], img.shape[0], bg)
            cp.put(img, 0, 0)
            t = cp.image(); label(t, f"{nm} {x0},{y0} x{z}", (6, 4), 13)
            tiles.append(t)
        W = 1600; x = y = 0; rowh = 0; placed = []
        for t in tiles:
            if x + t.width > W:
                x = 0; y += rowh + 8; rowh = 0
            placed.append((t, x, y)); x += t.width + 8; rowh = max(rowh, t.height)
        out = Image.new("RGB", (W, y + rowh), (30, 31, 36))
        for t, px_, py_ in placed:
            out.paste(t, (px_, py_))
        p = os.path.join(SHEETS, f"zoom_{bgname}.png"); out.save(p); paths.append(p)
    return paths


def insitu_clock():
    """The dial at its in-game size (bezel 28 studs ~ 430 px, as in the pass-4 Studio capture): silver bezel, dark
    chapter ring + te5_dial_inlay, the skeleton centre showing the movement plate's te5_star_window (Brightness 1.1 / 2.0),
    the dark sub-dial + te5_subdial. Day (Brightness 1.6/1.4)
    over the sky and night (2.6/2.2, bloom) over the night sky."""
    S = 15.4                                   # px per stud
    W, H = 520, 520
    cx = cy = W / 2
    out = []
    for mode in ("day", "night"):
        cp = Comp(W, H, BG_SKY if mode == "day" else (20, 22, 30))
        cp.disc(cx, cy, 12.2 * S, 14.0 * S, (176, 180, 190) if mode == "day" else (120, 124, 134))   # bezel
        # the movement plate (24.6 studs, black) with te5_star_window on it, seen through the skeleton dial
        cp.disc(cx, cy, 0, 12.3 * S, (12, 12, 16))
        sw = resize_premult(load("te5_star_window"), int(24.6 * S), int(24.6 * S))
        cp.put(sw, int(cx - sw.shape[1] / 2), int(cy - sw.shape[0] / 2), bright=1.1 if mode == "day" else 2.0)
        cp.disc(cx, cy, 12.0 * S, 12.2 * S, (60, 62, 68))
        cp.disc(cx, cy, 9.4 * S, 12.2 * S, (44, 46, 52))                                              # chapter ring
        inl = resize_premult(load("te5_dial_inlay"), int(24.4 * S), int(24.4 * S))
        cp.put(inl, int(cx - inl.shape[1] / 2), int(cy - inl.shape[0] / 2), bright=1.6 if mode == "day" else 2.6)
        cp.disc(cx, cy, 0, 3.25 * S, (30, 31, 36))                                                    # sub-dial
        sd = resize_premult(load("te5_subdial"), int(6.5 * S), int(6.5 * S))
        cp.put(sd, int(cx - sd.shape[1] / 2), int(cy - sd.shape[0] / 2), bright=1.4 if mode == "day" else 2.2)
        cp.disc(cx, cy, 0, 0.65 * S, (44, 46, 52)); cp.disc(cx, cy, 0, 0.42 * S, (214, 218, 226))     # hub
        im = cp.image(bloom=0.0 if mode == "day" else 1.0)
        label(im, f"clock {mode}: 28-stud bezel at ~430 px", (8, 6), 14)
        out.append(im)
    big = Image.new("RGB", (W * 2 + 10, H), (30, 31, 36))
    big.paste(out[0], (0, 0)); big.paste(out[1], (W + 10, 0))
    p = os.path.join(SHEETS, "insitu_clock.png"); big.save(p)
    return [p]


def _ground_quad(cx, cy, R, elev_deg, W, H, persp=0.18):
    """Screen quad for a ground square of half-size R px seen from a camera at elev_deg (simple perspective)."""
    s = math.sin(math.radians(elev_deg))
    far = 1.0 - persp; near = 1.0 + persp
    return [(cx - R * far, cy - R * s * far), (cx + R * far, cy - R * s * far),
            (cx + R * near, cy + R * s * near), (cx - R * near, cy + R * s * near)]


def insitu_dais(t=3.0):
    """The dais stack at in-game scale: engraving (56) on the plaza, dark base (29.6) + te5_galaxy_floor, the floating
    arms (21, +0.42) and core (12, +0.66) at their relative spins after t seconds, silver rim (31.1). Top-down and from a
    32-degree camera, by day and by night."""
    S = 10.0                                   # px per stud (the 56-stud stage fits the 600 px tile)
    out = []
    eng = load("te5_engraving"); flo = load("te5_galaxy_floor"); arm = load("te5_galaxy_arms")
    cor = load("te5_galaxy_core")
    for mode in ("day", "night"):
        for view in ("top", "persp"):
            W, H = 600, 600 if view == "top" else 380
            ground = SAND if mode == "day" else NIGHT_GROUND
            cp = Comp(W, H, ground)
            cx, cy = W / 2, H / 2 if view == "top" else H * 0.52
            elev = 90 if view == "top" else 32
            day = mode == "day"
            for img, dia, rate, br, lift in [(eng, 56.0, 2.5, 1.0 if day else 2.0, 0.0),
                                             (None, 29.6, 0, 0, 0.06),
                                             (flo, 29.6, -6.0, 1.3 if day else 2.4, 0.15),
                                             (None, 31.1, 0, 0, 0.9),
                                             (arm, 21.0, 9.0, 1.4 if day else 2.4, 0.42),
                                             (cor, 12.0, -16.0, 1.5 if day else 2.6, 0.66)]:
                R = dia / 2 * S
                if img is None and dia == 29.6:          # D1 base disc
                    src = np.zeros((256, 256, 4), F32); yy, xx = np.mgrid[0:256, 0:256]
                    rr = np.hypot(xx + 0.5 - 128, yy + 0.5 - 128) / 128
                    src[..., :3] = np.asarray([12, 12, 16], F32) / 255; src[..., 3] = np.clip((1 - rr) * 128, 0, 1)
                    br = 1.0
                elif img is None:                         # D6 silver rim, 14.75 -> 15.55 (top face only)
                    src = np.zeros((512, 512, 4), F32); yy, xx = np.mgrid[0:512, 0:512]
                    rr = np.hypot(xx + 0.5 - 256, yy + 0.5 - 256) / 256 * 15.55
                    src[..., :3] = (np.asarray([176, 180, 190], F32) if day else np.asarray([110, 114, 124], F32)) / 255
                    src[..., 3] = np.clip((15.55 - rr) * 16, 0, 1) * np.clip((rr - 14.75) * 16, 0, 1)
                    R = 15.55 * S; br = 1.0
                else:
                    src = rotate_rgba(img, rate * t)
                size = int(2 * R)
                src = resize_premult(src, size, size) if view == "top" else src
                yoff = -lift * S * math.cos(math.radians(elev)) if view != "top" else 0
                if view == "top":
                    cp.put(src, int(cx - R), int(cy - R), bright=br)
                else:
                    q = _ground_quad(cx, cy + yoff, R, elev, W, H)
                    wimg = warp_rgba(resize_premult(src, min(1024, size * 2), min(1024, size * 2)), (W, H), q)
                    cp.put(wimg, 0, 0, bright=br)
            im = cp.image(bloom=0.0 if day else 1.0)
            label(im, f"dais {mode} {view} (t={t:.0f}s)", (8, 6), 14, fill=(20, 20, 24) if day else (235, 235, 240))
            out.append(im)
    W = out[0].width + out[1].width + 10
    big = Image.new("RGB", (W, out[0].height * 2 + 10), (30, 31, 36))
    big.paste(out[0], (0, 0)); big.paste(out[1], (out[0].width + 10, 0))
    big.paste(out[2], (0, out[0].height + 10)); big.paste(out[3], (out[0].width + 10, out[0].height + 10))
    p = os.path.join(SHEETS, "insitu_dais.png"); big.save(p)
    return [p]


def insitu_void():
    """The void core (Neon black, 8 studs) with the te5_accretion disc (13 studs) at the spec's 15-degree tilt seen from
    a camera ~8 degrees above (so ~23 degrees off edge-on), plus a top-down view; far half behind, near half in front."""
    S = 26.0
    acc = load("te5_accretion")
    out = []
    for mode in ("day", "night"):
        day = mode == "day"
        for view, elev in (("tilted", 23.0), ("top", 90.0)):
            W, H = 420, 420 if view == "top" else 300
            cp = Comp(W, H, BG_SKY if day else (20, 22, 30))
            cx, cy = W / 2, H / 2
            R = 6.5 * S
            br = 1.5 if day else 2.4
            q = _ground_quad(cx, cy, R, elev, W, H, persp=0.04 if view != "top" else 0.0)
            disc = warp_rgba(resize_premult(acc, 1024, 1024), (W, H), q)
            if view == "top":
                cp.put(disc, 0, 0, bright=br)
                cp.disc(cx, cy, 0, 4.0 * S, (0, 0, 0))
            else:
                far = disc.copy(); far[int(cy):, :, 3] = 0
                near = disc.copy(); near[:int(cy), :, 3] = 0
                cp.put(far, 0, 0, bright=br)
                cp.disc(cx, cy, 0, 4.0 * S, (0, 0, 0))
                cp.put(near, 0, 0, bright=br)
            cp.disc(cx, cy, 4.0 * S + 1, 4.0 * S + 0.22 * S + 1, (236, 240, 248))      # photon ring (geometry)
            im = cp.image(bloom=0.0 if day else 1.0)
            label(im, f"void {mode} {view}", (8, 6), 14, fill=(20, 20, 24) if day else (235, 235, 240))
            out.append(im)
    W = out[0].width + out[1].width + 10
    big = Image.new("RGB", (W, max(o.height for o in out[:2]) * 2 + 10), (30, 31, 36))
    big.paste(out[0], (0, 0)); big.paste(out[1], (out[0].width + 10, 0))
    big.paste(out[2], (0, 430)); big.paste(out[3], (out[0].width + 10, 430))
    p = os.path.join(SHEETS, "insitu_void.png"); big.save(p)
    return [p]


def insitu_halo_beams():
    """Moon halo (13 studs around the 9-stud moon; ImageTransparency 0.65 day / 0.45 night), the night corona (40 studs
    around the 28-stud bezel, 0.6), and the beams at in-game width: B1 stream (WHITE), B3 stream (Color 18,18,24),
    and the void's lensed band (te5_stream, WHITE), each with its Wrap repeat count."""
    S = 18.0
    halo = load("te5_halo")
    tiles = []
    for mode in ("day", "night"):
        day = mode == "day"
        W, H = 300, 300
        cp = Comp(W, H, BG_SKY if day else (20, 22, 30))
        hi = resize_premult(halo, int(13 * S), int(13 * S))
        cp.put(hi, int(W / 2 - hi.shape[1] / 2), int(H / 2 - hi.shape[0] / 2), bright=1.0 if day else 1.6,
               color=(236, 240, 248), alpha_mul=0.35 if day else 0.55)
        # the moon: a softly shaded white ball
        yy, xx = np.mgrid[0:H, 0:W].astype(F32)
        d = np.hypot(xx + 0.5 - W / 2, yy + 0.5 - H / 2) / (4.5 * S)
        z = np.sqrt(np.clip(1 - d * d, 0, 1))
        shade = (0.70 + 0.30 * z) * (234 / 255)
        a = np.clip((1 - d) * 4.5 * S, 0, 1)[..., None]
        cp.rgb = cp.rgb * (1 - a) + shade[..., None] * a
        im = cp.image(bloom=0.0 if day else 1.0); label(im, f"moon halo {mode}", (8, 6), 14,
                                                         fill=(20, 20, 24) if day else (235, 235, 240))
        tiles.append(im)
    # night corona
    S2 = 7.0; W, H = 300, 300
    cp = Comp(W, H, (20, 22, 30))
    ci = resize_premult(halo, int(40 * S2), int(40 * S2))
    cp.put(ci, int(W / 2 - ci.shape[1] / 2), int(H / 2 - ci.shape[0] / 2), bright=1.8, color=(236, 240, 248), alpha_mul=0.4)
    cp.disc(W / 2, H / 2, 12.2 * S2, 14.0 * S2, (120, 124, 134)); cp.disc(W / 2, H / 2, 9.4 * S2, 12.2 * S2, (44, 46, 52))
    im = cp.image(bloom=1.0); label(im, "night corona (40) round the bezel", (8, 6), 14); tiles.append(im)
    # beams
    for mode in ("day", "night"):
        day = mode == "day"
        W, H = 900, 300
        cp = Comp(W, H, BG_SKY if day else (20, 22, 30))
        specs = [("te5_stream", "B1 stream WHITE, Wrap 5", (248, 249, 255), 1.6 if day else 2.4, 1.4, 0.30, 5, 40),
                 ("te5_stream", "B3 stream Color 18,18,24", (18, 18, 24), 1.0, 1.6, 0.35, 5, 110),
                 ("te5_stream", "lensed band WHITE, Wrap 6", (248, 249, 255), 2.0 if day else 3.0, 1.5, 1.5, 6, 180)]
        labels_ = []
        for nm, lab, col, br, w0, w1, wrap, y in specs:
            tex = load(nm)
            L = 760; x0 = 70
            reps = np.concatenate([tex] * wrap, axis=1)
            strip = resize_premult(reps, L, int(max(w0, w1) * S * 1.0))
            # taper: Width0 at the orb end -> Width1 at the palm end
            hh = strip.shape[0]
            out_s = np.zeros((hh, L, 4), F32)
            for i in range(L):
                wi = (w0 + (w1 - w0) * i / (L - 1)) / max(w0, w1)
                col_h = max(1, int(round(hh * wi)))
                c = Image.fromarray((strip[:, i:i + 1, 3] * 255).astype(np.uint8))
                for ch in range(4):
                    v = np.asarray(Image.fromarray(strip[:, i, ch].reshape(-1, 1).astype(F32), "F").resize((1, col_h), Image.BILINEAR), F32)[:, 0]
                    o = (hh - col_h) // 2
                    out_s[o:o + col_h, i, ch] = v
            cp.put(out_s, x0, y - hh // 2, bright=br, color=col)
            labels_.append((lab, (x0, y - hh // 2 - 18)))
        im = cp.image(bloom=0.0 if day else 1.0)
        for t, xy in labels_:
            label(im, t, xy, 13, fill=(20, 20, 24) if day else (235, 235, 240))
        tiles.append(im)
    row1 = Image.new("RGB", (910, 300), (30, 31, 36))
    row1.paste(tiles[0], (0, 0)); row1.paste(tiles[1], (305, 0)); row1.paste(tiles[2], (610, 0))
    big = Image.new("RGB", (910, 920), (30, 31, 36))
    big.paste(row1, (0, 0)); big.paste(tiles[3], (0, 310)); big.paste(tiles[4], (0, 620))
    p = os.path.join(SHEETS, "insitu_halo_beams.png"); big.save(p)
    return [p]


# --------------------------------------------------------------------------------------------------------------------
# before / after: the seven textures rebuilt after review round 3 against the PNGs they replaced (--before DIR: a copy of
# this folder from before, e.g. git show / a backup). Each row: before | after over the dark background, then the sky.
# --------------------------------------------------------------------------------------------------------------------

REBUILT = ["te5_moon", "te5_accretion", "te5_galaxy_floor", "te5_galaxy_arms", "te5_galaxy_core", "te5_star_window",
           "te5_stream"]


def _load_from(d, name):
    return np.asarray(Image.open(os.path.join(d, name + ".png")).convert("RGBA"), F32) / 255.0


def sheet_before_after(before):
    global OUT, SHEETS
    tile, pad, lab = 300, 12, 24
    names = [nm for nm in REBUILT if os.path.exists(os.path.join(before, nm + ".png"))]
    W = 4 * (tile + pad) + pad
    rows_h = []
    for nm in names:
        rows_h.append(tile if nm != "te5_stream" else 2 * (90 + pad) - pad)
    H = sum(h + lab + pad for h in rows_h) + pad + 26
    cp = Comp(W, H, (30, 31, 36))
    labels = [("BEFORE (dark)", (pad + 4, 6)), ("AFTER (dark)", (pad + tile + pad + 4, 6)),
              ("BEFORE (sky)", (pad + 2 * (tile + pad) + 4, 6)), ("AFTER (sky)", (pad + 3 * (tile + pad) + 4, 6))]
    y = 26 + pad
    for nm, rh in zip(names, rows_h):
        old, new = _load_from(before, nm), load(nm)
        labels.append((f"{nm}   {old.shape[1]}x{old.shape[0]} -> {new.shape[1]}x{new.shape[0]}", (pad + 4, y + 2)))
        y += lab
        if nm == "te5_stream":
            # two periods of each along the strip; the module tiles it along the beam (Wrap)
            wide = 2 * tile + pad
            for i, (img, bg) in enumerate(((old, BG_DARK), (new, BG_DARK), (old, BG_SKY), (new, BG_SKY))):
                strip = resize_premult(np.concatenate([img, img], axis=1), wide, 90)
                x = pad + (i % 2) * (wide + pad); yy = y + (i // 2) * (90 + pad)
                cp.rgb[yy:yy + 90, x:x + wide] = np.asarray(bg, F32) / 255.0
                cp.put(strip, x, yy)
        else:
            for i, (img, bg) in enumerate(((old, BG_DARK), (new, BG_DARK), (old, BG_SKY), (new, BG_SKY))):
                x = pad + i * (tile + pad)
                cp.rgb[y:y + tile, x:x + tile] = np.asarray(bg, F32) / 255.0
                cp.put(resize_premult(img, tile, tile), x, y)
        y += rh + pad
    out = cp.image()
    for t, xy in labels:
        label(out, t, xy, 14)
    paths = []
    p = os.path.join(SHEETS, "before_after.png"); out.save(p); paths.append(p)
    # the in-situ mock-ups, before | after: the old PNGs go through the SAME mock-up code (a temporary folder holding this
    # folder's PNGs with the old ones copied over them), so only the textures differ
    import shutil, tempfile
    keep = (OUT, SHEETS)
    tmp = tempfile.mkdtemp(prefix="te5_before_")
    try:
        for f in os.listdir(keep[0]):
            if f.endswith(".png"):
                shutil.copy(os.path.join(keep[0], f), tmp)
        for f in os.listdir(before):
            if f.endswith(".png"):
                shutil.copy(os.path.join(before, f), tmp)
        OUT, SHEETS = tmp, os.path.join(tmp, "sheets")
        os.makedirs(SHEETS)
        old_sheets = {fn.__name__: fn()[0] for fn in (insitu_void, insitu_dais, insitu_halo_beams, insitu_clock)}
        OUT, SHEETS = keep
        for nm, po in old_sheets.items():
            pn = os.path.join(SHEETS, nm + ".png")
            if not os.path.exists(pn):
                continue
            a, b = Image.open(po).convert("RGB"), Image.open(pn).convert("RGB")
            big = Image.new("RGB", (a.width + b.width + 12, max(a.height, b.height) + 28), (30, 31, 36))
            big.paste(a, (0, 28)); big.paste(b, (a.width + 12, 28))
            label(big, "BEFORE", (6, 6), 16); label(big, "AFTER", (a.width + 18, 6), 16)
            p = os.path.join(SHEETS, f"before_after_{nm}.png"); big.save(p); paths.append(p)
    finally:
        OUT, SHEETS = keep
        shutil.rmtree(tmp, ignore_errors=True)
    return paths


# --------------------------------------------------------------------------------------------------------------------
# manifest.json (read by tools/preview: 'file' is relative to this folder; uploadedId is filled on the Mac after upload)
# --------------------------------------------------------------------------------------------------------------------

MANIFEST = [
    ("te5_dial_inlay", "dialInlay", "dialOuter", "1024x1024",
     "Inlaid Roman numerals, minute track and inner ring on the solid dark chapter ring (C3 inlay plane, 24.4 "
     "studs)",
     "C3 SurfaceGui Face=Back, image +y toward XII. r 1 = 12.2 studs. White 250 strokes, 2 px ink (10,10,14, "
     "0.9). Radial numerals (tops outward, XII upright), IIII at 4 as on clock dials. Half-hour 4-point stars, "
     "tip radius 0.025."),
    ("te5_subdial", "subdial", "dialInner", "512x512",
     "Engraved guilloche face of the 6.5-stud sub-dial at the clock centre (C6)",
     "C6 Face=Left. 24-circle rosette (alpha 0.85, no ink) kept off r < 0.15, which the hub stack covers "
     "anyway."),
    ("te5_accretion", "accretion", "galaxy4", "1024x1024",
     "Opaque accretion disc round the void (V2, 13-stud plane, Top GUI): Interstellar-style sheared plasma",
     "Rebuilt after review round 3: turbulence carried round at the Kepler rate (angular speed ~ r^-1.5), so "
     "every eddy is drawn out into a long trailing streak; bright filaments, hot knots, thin cool lanes and "
     "darker gaps; brightness climbs to a white-hot inner edge (L 1 inside r 0.742). Even round the disc "
     "(broad lobes divided out: the plane spins, so nothing sweeps round like a searchlight). Streaks wind "
     "CLOCKWISE outward (image +y up), as before: turn the image COUNTER-clockwise (as seen on the Top face) "
     "for trailing streaks (ACC_DIR 1). Alpha unchanged: opaque BLACK inner skirt r 0.60-0.68 (under the "
     "8-stud core's silhouette at r 0.615), white fading into it over 0.676-0.712, opaque to r 0.86, "
     "smoothstep to 0 at r 1.0. Pure grey (R=G=B). Brightness day 1.6 / night 2.4."),
    ("te5_galaxy_floor", "galaxyFloor", "galaxy4", "1024x1024",
     "Dark galaxy pool on the dais base (D2, 29.6 studs): a barred grand-design spiral, the day-readable dark "
     "stage",
     "Rebuilt after review round 3: density-wave arms (pitch 16, sharp inner edge, gentle outer decline) made "
     "of star clouds and clusters of bright knots, braided broken dust lanes on each arm's inner edge running "
     "on along the bar as an S, faint spurs, a smooth bulge, a strong bar, an exponential disc of resolved "
     "stars (~180,000 grains) and field stars. Arms wind COUNTER-clockwise outward (image +y up), as before: a "
     "CLOCKWISE spin of the image makes them trail (spec rate -6 deg/s). Opaque to r 0.86, smoothstep to 0 at "
     "1.0. Mean L 0.22. Pure grey. Brightness 1.3 / 2.4."),
    ("te5_galaxy_arms", "galaxyArms", "galaxy4", "1024x1024",
     "Floating arm layer above the pool for parallax (D3, 21 studs)",
     "Rebuilt after review round 3: the same winding as the floor, turned 90 deg, pitch 13: two luminous "
     "streams of star clouds (alpha up to 1 along their cores, soft 0.2 wings), resolved stars and knots "
     "riding them, braided dust lanes (RGB 9, alpha up to 0.86) on the concave (= leading for a "
     "counter-clockwise spin) edge; alpha 0 at r < 0.13 and between the arms (mean alpha 0.18), the outer 15 % "
     "fades. The spec spins D3 at +9 deg/s against D2's -6: counter-rotating layers (strong parallax); its "
     "arms then lead rather than trail. Brightness 1.4 / 2.4."),
    ("te5_galaxy_core", "galaxyCore", "ornate", "512x512",
     "Bright core layer under the feet (D4, 12 studs): the bulge and an inner vortex",
     "Rebuilt after review round 3: the bulge (alpha 1 to r 0.08, soft to 0.25) with a faint nuclear dust "
     "spiral; 4 arms of star clouds from r 0.1, each with its own length (0.68-0.80) and strength, broken dust "
     "lanes on their inner edges, small bright knots; alpha 0 beyond r 0.85. Same winding as the floor "
     "(COUNTER-clockwise outward). Pitch now 15 deg (was 10: from Roblox's low default camera the 10-deg arms "
     "read as concentric rings; 15 reads as a vortex). Brightness 1.5 / 2.6."),
    ("te5_engraving", "engraving", "gring", "1024x1024",
     "The stage: an engraved clock ring on the ground round the dais (D5, 56 studs; review round 3, was 40)",
     "r 1 = 28 studs. From just outside the dais rim (r 0.585) to r 0.99: a fine guilloche tick band (r "
     "0.64-0.68), Roman numerals 3 studs tall at r 0.80 with half-hour four-point stars, and an INKED minute "
     "track (a solid ink band r 0.925-0.975, alpha 1) with white ticks and lume batons every five minutes. "
     "White 240 strokes with a 2 px ink (20) outline at alpha 0.95: nothing semi-transparent. Day Brightness "
     "1.0 (the ink carries the day), night 2.0."),
    ("te5_halo", "halo", "rim", "512x512",
     "Rim-only halo: moon halo billboard (15 studs), night bezel corona (C10, 44 studs) and the void's horizon "
     "glow particles (11.2 studs); its ring peaks at r 0.73, and the module scales the three by RIM_R while "
     "the pass-2 'rim' texture stands in",
     "White; alpha 0 below r 0.66, 0.95 at 0.74, 0.35 at 0.82, 0.10 at 0.90, 0 at 1.0 (monotone cubic, "
     "dithered). Tint with ImageColor3 (236,240,248)."),
    ("te5_stream", "stream", "line", "512x128",
     "Palm stream beams B1 (silver) and B3 (ink, via Beam Color), and the void's lensed band (B5/B6)",
     "Rebuilt after review round 3 at 512x128 (was 256x64; the same 4:1 aspect, so TextureLength / Wrap map it "
     "the same way). Image x runs ALONG the beam (seamless every 512 px, TextureMode Wrap), y across. Opaque "
     "body (alpha 1 for |v| < 0.40, 1.5 px edge, alpha 0 on the top and bottom rows) with ink edges (|v| "
     "0.33-0.40, RGB 12): a braid of three luminous strands twisting round each other (the near half of each "
     "turn brighter), two thinner ones winding twice as fast, fine flowing striations, a darker body between "
     "them (L ~0.25-0.3). Color WHITE = a silver braided stream with ink edges (Brightness 1.6 / 2.4; lens 2.0 "
     "/ 3.0); Color (18,18,24) = a solid ink stream with a faint woven structure."),
    ("te5_moon", "moon", "moon", "1024x1024",
     "Photographic full-moon face for the moon's camera-facing face disc (review round 1, AD4; rebuilt after "
     "round 3)",
     "Rendered as a lit globe, north up, the Earth-facing side: maria where the real ones are "
     "(te5_lunar_data.py; shores flooded round the old relief, ghost craters, darker and lighter lava units) "
     "at grey ~75-135, highlands ~165-195; ~26,000 craters with a power-law size spread plus 247 named ones "
     "(bowls, terraces, central peaks, ejecta); ray systems (Tycho with its dark collar and long rays, "
     "Copernicus, Kepler, Aristarchus, Proclus, Messier A, ~500 small); light 22 deg off the view axis from "
     "the upper left with lunar-Lambert reflectance and cast shadows: relief near the limb, the whole disc lit "
     "(no dark side). Hard alpha edge at r 0.985 (1.6 % ramp), no ring, no glow. Drawn whole (no ImageRect "
     "crop), ImageColor3 white. Brightness 1.25 by day; at night 2.6 clips the highland craters in the "
     "preview, 2.0 keeps them (a module choice)."),
    ("te5_star_window", "starWindow", "galaxy4", "1024x1024",
     "Deep-space window on the clock's solid movement plate behind the skeleton dial (review round 1, AD1)",
     "Rebuilt after review round 3: opaque near-black field (alpha 1 to r 0.985, mean L 0.07); a faint, gently "
     "curved Milky-Way band at 32 deg with star clouds, the Great Rift, branching dark filaments, globules and "
     "two faint emission clouds; ~22,000 stars with a real magnitude spread (N(<m) ~ 10^(0.4 m) over 8 "
     "magnitudes) drawn through a point-spread function (sharp core, faint halo), denser in the band and "
     "dimmed behind the dust, the 8 brightest with short diffraction spikes; ~260,000 unresolved stars as the "
     "band's grain; 34 small distant galaxies. Turns with the centre wheel (+6 deg/s). Brightness 1.1 / 2.0. "
     "Until uploaded it falls back to the pass-4 galaxy (galaxy4), drawn dimmer."),
]


def write_manifest():
    entries = []
    for name, key, fb, size, purpose, notes in MANIFEST:
        entries.append({"name": name, "file": name + ".png", "repoPath": "textures/te5/surfaces/" + name + ".png",
                        "texKey": key, "fallbackTexKey": fb, "size": size, "layout": "None", "mode": "None", "purpose": purpose,
                        "notes": notes, "uploadedId": None})
    with open(os.path.join(OUT, "manifest.json"), "w") as f:
        json.dump(entries, f, indent=1, ensure_ascii=False)
        f.write("\n")
    return entries


def _radial_mean(img, ch, rs, n):
    yy, xx = np.mgrid[0:n, 0:n]
    rr = np.hypot(xx + 0.5 - n / 2, yy + 0.5 - n / 2) / (n / 2)
    return [float(img[..., ch][np.abs(rr - r) < 0.004].mean()) / 255.0 for r in rs]


def _ring(ch, r, n_ang=2048):
    """a channel sampled round the circle of radius r (r units), bilinear"""
    n = ch.shape[0]
    t = np.arange(n_ang) * 2 * math.pi / n_ang
    x = (r * np.cos(t) * 0.5 + 0.5) * n - 0.5; y = (0.5 - r * np.sin(t) * 0.5) * n - 0.5
    x0 = np.floor(x).astype(int); y0 = np.floor(y).astype(int); fx = x - x0; fy = y - y0
    return (ch[y0, x0] * (1 - fx) * (1 - fy) + ch[y0, x0 + 1] * fx * (1 - fy) + ch[y0 + 1, x0] * (1 - fx) * fy
            + ch[y0 + 1, x0 + 1] * fx * fy)


def _winding(ch, r1, r2, fold=1):
    """the angle (rad, + = counter-clockwise) that best lines the ring at r2 up with the ring at r1 (a few rings averaged
    each side), folded into one period of an n-fold pattern"""
    a = sum(_ring(ch, r1 + d) for d in np.linspace(-0.005, 0.005, 5)); b = sum(_ring(ch, r2 + d) for d in np.linspace(-0.005, 0.005, 5))
    a = a - a.mean(); b = b - b.mean()
    c = np.fft.irfft(np.conj(np.fft.rfft(a)) * np.fft.rfft(b), n=len(a))
    lag = int(np.argmax(c)) * 2 * math.pi / len(a)
    period = 2 * math.pi / fold
    return (lag + period / 2) % period - period / 2


def check():
    """Numerical spec checks on the written PNGs. Returns a list of failures (empty = all good)."""
    fails = []
    def ok(cond, msg):
        print(("  ok   " if cond else "  FAIL ") + msg)
        if not cond:
            fails.append(msg)
    sizes = {"te5_dial_inlay": (1024, 1024), "te5_subdial": (512, 512), "te5_accretion": (1024, 1024),
             "te5_galaxy_floor": (1024, 1024), "te5_galaxy_arms": (1024, 1024), "te5_galaxy_core": (512, 512),
             "te5_engraving": (1024, 1024), "te5_halo": (512, 512),
             "te5_stream": (512, 128), "te5_moon": (1024, 1024), "te5_star_window": (1024, 1024)}
    for nm, (w, h) in sizes.items():
        im = Image.open(os.path.join(OUT, nm + ".png"))
        a = np.asarray(im.convert("RGBA")).astype(np.int32)
        ok(im.mode == "RGBA" and im.size == (w, h), f"{nm}: RGBA {w}x{h}")
        R, G, B, A = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
        ok(bool((R == G).all() and (B >= R).all() and (B - R <= 20).all()), f"{nm}: monochrome (R=G, 0<=B-R<=20)")
        if w == h:
            border = np.concatenate([A[0], A[-1], A[:, 0], A[:, -1]])
            ok(int(border.max()) == 0, f"{nm}: alpha 0 on the whole border (no square edges)")
        else:
            ok(int(A[0].max()) == 0 and int(A[-1].max()) == 0, f"{nm}: alpha 0 on the top/bottom rows")
            f = a.astype(F32)
            seam = np.abs(f[:, 0] - f[:, -1]).mean()
            step = np.abs(np.diff(f, axis=1)).mean()
            ok(seam <= 2.5 * step + 0.5, f"{nm}: seamless in U (wrap diff {seam:.2f} vs column step {step:.2f})")
        # no fringes: every fully transparent pixel next to a visible one carries a colour close to that neighbour's
        vis = A > 0
        edge = (~vis) & (np.roll(vis, 1, 0) | np.roll(vis, -1, 0) | np.roll(vis, 1, 1) | np.roll(vis, -1, 1))
        if edge.any():
            nb = np.zeros_like(R, dtype=F32); cnt = np.zeros_like(R, dtype=F32)
            for ax_, sh in ((0, 1), (0, -1), (1, 1), (1, -1)):
                v2 = np.roll(vis, sh, ax_); r2 = np.roll(R, sh, ax_)
                nb += np.where(v2, r2, 0); cnt += v2
            diff = np.abs(R[edge] - nb[edge] / np.maximum(cnt[edge], 1))
            ok(float(np.percentile(diff, 99)) <= 40, f"{nm}: transparent edge pixels carry the stroke colour "
                                                       f"(p99 |diff| {np.percentile(diff, 99):.0f}/255)")
    halo = np.asarray(Image.open(os.path.join(OUT, "te5_halo.png")).convert("RGBA"))
    hv = _radial_mean(halo, 3, [0.60, 0.74, 0.82, 0.90, 0.99], 512)
    ok(hv[0] < 0.005 and abs(hv[1] - 0.95) < 0.03 and abs(hv[2] - 0.35) < 0.03 and abs(hv[3] - 0.10) < 0.02
       and hv[4] < 0.01, "te5_halo: alpha 0 / .95 / .35 / .10 / 0 at r .60/.74/.82/.90/.99 -> " +
       " ".join(f"{v:.3f}" for v in hv))
    acc = np.asarray(Image.open(os.path.join(OUT, "te5_accretion.png")).convert("RGBA"))
    av = _radial_mean(acc, 3, [0.58, 0.64, 0.75, 0.85, 0.995], 1024)
    lv = _radial_mean(acc, 0, [0.73], 1024)
    ok(av[0] < 0.01 and av[1] > 0.99 and av[2] > 0.99 and av[3] > 0.99 and av[4] < 0.02,
       "te5_accretion: alpha 0 inside the core / 1 skirt+body / 0 at the rim -> " + " ".join(f"{v:.2f}" for v in av))
    ok(lv[0] > 0.97, f"te5_accretion: white-hot inner edge at r 0.73 (L {lv[0]:.2f})")
    flo = np.asarray(Image.open(os.path.join(OUT, "te5_galaxy_floor.png")).convert("RGBA"))
    yy, xx = np.mgrid[0:1024, 0:1024]; rr = np.hypot(xx + 0.5 - 512, yy + 0.5 - 512) / 512
    mL = float(flo[..., 0][rr < 0.86].mean()) / 255
    ok(0.19 <= mL <= 0.25, f"te5_galaxy_floor: mean L inside r 0.86 = {mL:.3f} (spec ~0.22)")
    ok(float(flo[..., 3][rr < 0.85].min()) == 255, "te5_galaxy_floor: opaque to r 0.85")
    # winding: the shift that lines a ring up with a slightly bigger one. Galaxy arms wind COUNTER-clockwise outward
    # (+), the accretion streaks CLOCKWISE (-), image +y up; folded by the pattern's symmetry (2 arms, 4 arms)
    for nm, ch, fold, rings_, sign in (("te5_galaxy_floor", 0, 2, ((0.40, 0.45), (0.50, 0.55), (0.60, 0.65)), 1),
                                       ("te5_galaxy_arms", 3, 2, ((0.40, 0.45), (0.50, 0.55), (0.60, 0.65)), 1),
                                       ("te5_galaxy_core", 3, 4, ((0.30, 0.34), (0.40, 0.44), (0.50, 0.54)), 1),
                                       ("te5_accretion", 0, 1, ((0.78, 0.80), (0.80, 0.84), (0.85, 0.89)), -1)):
        img = np.asarray(Image.open(os.path.join(OUT, nm + ".png")).convert("RGBA")).astype(np.float64) / 255.0
        lags = [_winding(img[..., ch], a, b, fold) for a, b in rings_]
        ok(all(sign * l > 0.05 for l in lags), f"{nm}: winds {'counter-' if sign > 0 else ''}clockwise outward "
                                                 f"(ring shifts {' '.join(f'{l:+.2f}' for l in lags)} rad)")
    # the accretion plane spins: no broad bright lobe round the disc (16 sectors of r 0.76-0.95)
    tt = np.arctan2(511.5 - yy, xx - 511.5)
    m = (rr > 0.76) & (rr < 0.95)
    sec = np.asarray([acc[..., 0][m & (np.floor((tt + math.pi) / (math.pi / 8)) == i)].mean() for i in range(16)])
    ok(float((sec.max() - sec.min()) / sec.mean()) < 0.25, f"te5_accretion: even round the disc (sector means "
                                                           f"{sec.min() / 255:.2f}-{sec.max() / 255:.2f})")
    # the moon: a hard disc, lit to the limb (no dark side), seas darker than the highlands, Tycho bright
    moon = np.asarray(Image.open(os.path.join(OUT, "te5_moon.png")).convert("RGBA")).astype(np.float64)
    ok(moon[..., 3][rr < 0.975].min() == 255 and moon[..., 3][rr > 0.995].max() == 0,
       "te5_moon: opaque disc to r 0.975, alpha 0 beyond 0.995")
    g = moon[..., 0]
    p1 = float(np.percentile(g[rr < 0.97], 1))
    ok(p1 >= 50, f"te5_moon: lit to the limb, no dark side (p1 grey {p1:.0f})")

    def at(lon, lat, rad):
        x = 0.985 * math.cos(math.radians(lat)) * math.sin(math.radians(lon)); y = 0.985 * math.sin(math.radians(lat))
        return float(g[np.hypot(xx + 0.5 - (x * 0.5 + 0.5) * 1024, yy + 0.5 - (0.5 - y * 0.5) * 1024) < rad * 512].mean())
    seas = [at(-16, 36, 0.02), at(30, 8, 0.02), at(59, 17, 0.03)]
    high = [at(5, -30, 0.04), at(20, -45, 0.04), at(-60, -45, 0.03)]
    ok(max(seas) + 40 < min(high), "te5_moon: Imbrium / Tranquillitatis / Crisium darker than the highlands (" +
       " ".join(f"{v:.0f}" for v in seas) + " vs " + " ".join(f"{v:.0f}" for v in high) + ")")
    ty = at(-11.4, -43.3, 0.03)
    ok(ty > float(np.mean(high)) + 10, f"te5_moon: Tycho's bright nimbus ({ty:.0f})")
    # the star window: dark overall, opaque, a real spread of star brightness
    sw = np.asarray(Image.open(os.path.join(OUT, "te5_star_window.png")).convert("RGBA")).astype(np.float64) / 255.0
    L = sw[..., 0]
    mL = float(L[rr < 0.97].mean())
    ok(0.03 <= mL <= 0.10 and sw[..., 3][rr < 0.975].min() == 1.0, f"te5_star_window: opaque and dark (mean L {mL:.3f})")
    peak = (L >= np.roll(L, 1, 0)) & (L >= np.roll(L, -1, 0)) & (L >= np.roll(L, 1, 1)) & (L >= np.roll(L, -1, 1)) & (rr < 0.97)
    nb = [int((peak & (L > t)).sum()) for t in (0.3, 0.5, 0.95)]
    ok(nb[0] > 2 * nb[1] > 4 * nb[2] > 0, f"te5_star_window: faint stars outnumber bright ones ({nb[0]} > 0.3, "
                                          f"{nb[1]} > 0.5, {nb[2]} > 0.95)")
    # the stream: an opaque body, ink edges, a bright braid
    st = np.asarray(Image.open(os.path.join(OUT, "te5_stream.png")).convert("RGBA")).astype(np.float64) / 255.0
    v = np.abs((np.arange(st.shape[0]) + 0.5) / st.shape[0] - 0.5)
    ok(st[v < 0.385, :, 3].min() == 1.0, "te5_stream: opaque body (alpha 1 for |v| < 0.385)")
    ink = float(st[(v > 0.34) & (v < 0.39), :, 0].mean()); core = float(st[v < 0.2, :, 0].mean())
    ok(ink < 0.1 and core > 0.45, f"te5_stream: ink edges ({ink:.2f}) and a bright braid ({core:.2f})")
    # the galaxy layers' alpha conventions
    ar = np.asarray(Image.open(os.path.join(OUT, "te5_galaxy_arms.png")).convert("RGBA")).astype(np.float64) / 255.0
    ma = float(ar[..., 3][rr < 0.86].mean())
    ok(ar[..., 3][rr < 0.1].max() == 0 and 0.10 <= ma <= 0.30 and ar[..., 3].max() > 0.95,
       f"te5_galaxy_arms: clear centre, opaque arm cores, open between the arms (mean alpha {ma:.2f})")
    co = np.asarray(Image.open(os.path.join(OUT, "te5_galaxy_core.png")).convert("RGBA")).astype(np.float64) / 255.0
    yc, xc = np.mgrid[0:512, 0:512]; rc = np.hypot(xc + 0.5 - 256, yc + 0.5 - 256) / 256
    ok(co[..., 3][rc < 0.06].min() == 1.0 and co[..., 3][rc > 0.86].max() == 0,
       "te5_galaxy_core: opaque bulge (r < 0.06), alpha 0 beyond r 0.86")
    return fails


def make_sheets(before=None):
    os.makedirs(SHEETS, exist_ok=True)
    paths = []
    for fn in (sheet_overview, sheet_zoom, insitu_clock, insitu_dais, insitu_void, insitu_halo_beams):
        t0 = time.time()
        paths += fn()
        print(f"sheet {fn.__name__}: {time.time() - t0:.1f}s")
    if before:
        paths += sheet_before_after(before)
        print("sheet sheet_before_after")
    return paths


# --------------------------------------------------------------------------------------------------------------------
# registry + main
# --------------------------------------------------------------------------------------------------------------------

JOBS = {}


def job(name, fn):
    JOBS[name] = fn


job("te5_dial_inlay", make_dial_inlay)
job("te5_subdial", make_subdial)
job("te5_accretion", make_accretion)
job("te5_galaxy_floor", make_galaxy_floor)
job("te5_galaxy_arms", make_galaxy_arms)
job("te5_galaxy_core", make_galaxy_core)
job("te5_engraving", make_engraving)
job("te5_halo", make_halo)
job("te5_stream", make_stream)
job("te5_moon", make_moon)
job("te5_star_window", make_star_window)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--no-sheets", action="store_true")
    ap.add_argument("--check", action="store_true", help="only run the numerical spec checks on the PNGs")
    ap.add_argument("--before", default="", help="a folder of older PNGs (and sheets/): also make sheets/before_after*.png")
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
