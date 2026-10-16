#!/usr/bin/env python3
# THE END (1 in 1,000,000,000) -- equipped aura, pass 5 "The Last Clock" -- texture group "surfaces".
#
# Spec: docs/the-end/pass5-spec.md, section 16.2 (group "surfaces"). 13 textures:
#   te5_dial_inlay  te5_subdial  te5_accretion  te5_galaxy_floor  te5_galaxy_arms  te5_galaxy_core
#   te5_engraving   te5_halo     te5_hairspring te5_stream        te5_ribbon
#   te5_moon        te5_star_window  (added in review round 1: docs/the-end/pass5-build-notes.md)
#
# Only python3 + numpy + PIL (runs the same on Milo's Mac and in the cloud). Deterministic: every random source is
# seeded, so a re-run gives byte-identical PNGs.
#
#   python3 make_te5_surfaces.py              # all textures + contact sheets (sheets/)
#   python3 make_te5_surfaces.py --no-sheets  # textures only
#   python3 make_te5_surfaces.py --only te5_halo,te5_stream
#
# How the images are made (film-quality rules from the spec):
#   * Everything is rendered at 2x (SS) and box-filtered down, in PREMULTIPLIED alpha, so anti-aliased edges are exact.
#   * Line art (dial, sub-dial, engraving, hairspring) is drawn from exact signed-distance fields (circles, boxes, convex
#     polygons, the spiral), so every stroke has a true 1 px anti-aliased edge and its ink outline follows it exactly.
#   * After downsampling the colour is un-premultiplied and BLED into the fully transparent pixels (pull-push fill), so
#     Roblox's bilinear filtering and mip-maps never mix black into an edge: no dark or light fringes.
#   * Smooth gradients (halo, discs) are dithered by +-1 LSB before 8-bit quantisation: no banding.
#   * Monochrome lock: every pixel has R == G and R <= B <= R + 20 (a faint cool tint at most).
import argparse, json, math, os, sys, time
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

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
# 7. te5_engraving  (1024^2, ground ring 40 studs, r 1 = 20 studs)
# --------------------------------------------------------------------------------------------------------------------

def make_engraving():
    n = 1024; cv = Canvas(n)
    L = Layer(cv, pad_out=4.0)
    for R, w in ((0.78, 3.0), (0.80, 2.0), (0.965, 2.0), (0.985, 4.0)):
        L.ring(R, w)
    for k in range(120):
        phi = math.radians(k * 3.0)
        if k % 10 == 0:
            L.radial_tick(phi, 0.92, 0.965, 4.0)
        else:
            L.radial_tick(phi, 0.94, 0.965, 1.5)
    H = 0.08                                               # same glyph builder, height 0.08, same thick:thin ratio
    radial_numerals(L, 0.87, H, 0.016 * H / 0.13 * 1.12, 0.007 * H / 0.13 * 1.25)
    for h in range(12):                                    # half-hour diamonds
        phi = math.radians(h * 30.0 + 15.0)
        s, c = math.sin(phi), math.cos(phi)
        cx, cy = 0.87 * s, 0.87 * c
        lr, lt = 0.019, 0.0105
        L.poly([(cx + s * lr, cy + c * lr), (cx + c * lt, cy - s * lt), (cx - s * lr, cy - c * lr), (cx - c * lt, cy + s * lt)])
    P, A = inked(L, fill=240, ink_out=2.0, ink=(20, 20, 22), ink_a=0.92)
    return finish("te5_engraving", P, A)


# --------------------------------------------------------------------------------------------------------------------
# 9. te5_hairspring  (512^2, Archimedean spiral r = 0.12 + 0.8*theta/(2*pi*9) over 9 turns)
# --------------------------------------------------------------------------------------------------------------------

def make_hairspring():
    n = 512; cv = Canvas(n)
    turns, r0, span = 9, 0.12, 0.8
    b = span / (2 * math.pi * turns)
    rho = cv.r_px / cv.k
    phi = np.mod(np.arctan2(cv.ys[:, None], cv.xs[None, :]), 2 * math.pi)
    tmax = 2 * math.pi * turns
    best = np.full(rho.shape, np.inf, F32)
    for k in range(turns + 1):
        tk = phi + 2 * math.pi * k
        rk = r0 + b * tk
        dk = np.where(tk <= tmax, np.abs(rho - rk), np.inf)
        best = np.minimum(best, dk)
    cosa = 1.0 / np.sqrt(1.0 + (b / np.maximum(rho, 0.05)) ** 2)     # spiral pitch correction -> true distance
    sd = best * cosa * cv.k - SS * 3.0 / 2
    L = Layer(cv, pad_out=3.0)
    # round caps at both spiral ends
    for tt in (0.0, tmax):
        rr = r0 + b * tt
        L.disc((rr * math.cos(tt), rr * math.sin(tt)), 1.5 / (n / 2.0))
    L.field(sd)
    L.ring(0.10, 4.0)                                                 # collet
    L.disc(((r0 + b * tmax) * math.cos(tmax), (r0 + b * tmax) * math.sin(tmax)), 0.025)   # terminal stud
    # the inner end is pinned into the collet: the coil eases in from the collet's rim over 0.7 rad before the spiral
    # starts (a smooth curve, no tab)
    pts = []
    for i in range(15):
        a = -0.7 + 0.7 * i / 14.0
        rr = 0.1075 + (r0 - 0.1075) * float(sstep(-0.7, 0.0, a))
        pts.append((rr * math.cos(a), rr * math.sin(a)))
    L.polyline(pts, 3.0)
    P, A = inked(L, fill=250, ink_out=1.5, ink=(10, 10, 14), ink_a=0.9)
    return finish("te5_hairspring", P, A)


# --------------------------------------------------------------------------------------------------------------------
# procedural discs: shared polar grid (r units, +y up, theta CCW from +x) at SS resolution
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


def gauss_dots(shape, pts, k_px, val_cover=True):
    """Soft round dots at SS resolution. pts: (x_r, y_r, radius_out_px, value). Returns a coverage-style max map."""
    M = shape[0]
    out = np.zeros(shape, F32)
    for (x, y, rad, val) in pts:
        cx = x * k_px + M / 2.0; cy = M / 2.0 - y * k_px
        s = rad * SS
        R = int(math.ceil(s * 3 + 2))
        c0, c1 = max(0, int(cx) - R), min(M, int(cx) + R + 1)
        r0, r1 = max(0, int(cy) - R), min(M, int(cy) + R + 1)
        if c1 <= c0 or r1 <= r0:
            continue
        X = np.arange(c0, c1, dtype=F32)[None, :] + 0.5 - cx
        Y = np.arange(r0, r1, dtype=F32)[:, None] + 0.5 - cy
        d = np.sqrt(X * X + Y * Y)
        prof = val * (np.clip(s - d + 0.5, 0, 1) * 0.65 + 0.35 * np.exp(-0.5 * (d / (s * 1.4)) ** 2))
        np.maximum(out[r0:r1, c0:c1], prof, out=out[r0:r1, c0:c1])
    return out


# --------------------------------------------------------------------------------------------------------------------
# 3. te5_accretion  (1024^2, 13-stud plane, r 1 = 6.5 studs)
#    Streaks/lanes wind CLOCKWISE outward in the image (+y up): theta + c*ln r = const.  Spin the plane so the image
#    turns COUNTER-clockwise (as seen with image +y up) and the streaks trail.
# --------------------------------------------------------------------------------------------------------------------

def make_accretion():
    n = 1024
    x, y, r, th = polar(n)
    lr = np.log(np.maximum(r, 1e-3))
    # fbm (mean 0, std 1): fine laminar filaments stretched far along the streaks, plus a little slow turbulence
    fil = spiral_noise(r, th, -2.2, 302, size=(64, 2048), beta=1.3, fmin=2.0, ylr=9.0)
    fil2 = spiral_noise(r, th, -2.2, 305, size=(64, 4096), beta=1.6, fmin=4.0, ylr=22.0)
    slow = cart_noise(n, 301, beta=1.8, fmin=2.0)
    # crisp ridged filaments (thin bright threads riding the flow)
    hf = spiral_noise(r, th, -2.2, 306, size=(64, 4096), beta=0.9, fmin=24.0, ylr=6.0)
    ridge = (1.0 - np.clip(np.abs(hf) / 2.2, 0.0, 1.0)) ** 7
    fbm_n = 0.85 * fil + 0.35 * fil2 + 0.35 * slow
    fbm_n = (fbm_n - fbm_n.mean()) / fbm_n.std()
    fbm = 0.62 * unit01(fbm_n) + 0.38 * ridge / max(ridge.mean() * 2.0, 1e-3) * 0.5    # [0, 1], mean ~0.5
    fbm = np.clip(fbm, 0.0, 1.0)
    # streak-phase warp: the spec's 0.25 rad per unit of fbm, on a large-scale noise so the 9 streaks never read as a
    # regular iris; plus the fine fbm
    wslow = spiral_noise(r, th, -2.2, 307, size=(32, 256), beta=1.8, fmin=1.0, ylr=4.0)
    warp = 0.25 * fbm_n + 0.9 * wslow
    s = (0.5 + 0.5 * np.cos(9.0 * (th + 2.2 * lr) + warp)) ** 3
    L = np.clip((0.72 / np.maximum(r, 1e-3)) ** 3.2, 0.0, 1.0)
    L = L * (0.65 + 0.35 * s) * (0.85 + 0.3 * fbm)
    # white-hot inner edge: forced to 1.0 inside r 0.74, eased into the streaked disc by r 0.765 (no ring step)
    L = L + (1.0 - L) * sstep(0.765, 0.74, r)
    # three opaque black dust lanes: theta + 1.6 ln r = k*2pi/3, Gaussian FWHM 0.1 rad, over r 0.78-0.97
    jitter = 0.010 * spiral_noise(r, th, -1.6, 303, size=(64, 1024), beta=1.6, fmin=2.0, ylr=10.0)
    lane = np.zeros_like(r)
    sig = 0.10 / 2.3548
    for kk in range(3):
        d = wrap_pi(th + 1.6 * lr - kk * 2 * math.pi / 3 + jitter)
        lane = np.maximum(lane, np.exp(-0.5 * (d / sig) ** 2))
    dens = unit01(spiral_noise(r, th, -1.6, 304, size=(64, 1024), beta=1.5, fmin=2.0, ylr=14.0))
    lane = lane * sstep(0.765, 0.80, r) * sstep(0.985, 0.945, r) * (0.86 + 0.28 * dens)
    lane = np.clip(lane, 0.0, 1.0)
    L = L * (1.0 - 0.92 * lane)
    # Alpha: the spec's soft inner edge (0 -> 1 over r 0.68-0.72) is drawn as a soft white-to-BLACK edge on an opaque
    # black inner skirt that starts at r 0.60, inside the 8-stud core's silhouette (core r = 4/6.5 = 0.615). Seen from
    # above, the 4.0-4.42-stud gap between the Neon-black core and the hot edge would otherwise show the bright day sky
    # as a blue ring; this way it reads as the void's shadow. Black over the black core is invisible from every angle.
    L = 0.012 + (L - 0.012) * sstep(0.676, 0.712, r)
    A = sstep(0.598, 0.624, r) * (1.0 - sstep(0.86, 1.0, r))
    L = np.clip(L, 0.0, 1.0)
    rgb = np.dstack([L, L, np.minimum(1.0, 1.03 * L)])
    P = rgb * A[..., None]
    return finish("te5_accretion", P.astype(F32), A.astype(F32), dither=True)


# --------------------------------------------------------------------------------------------------------------------
# galaxy helpers (te5_galaxy_floor / _arms / _core).  Arms wind COUNTER-clockwise outward with image +y up:
# theta_arm(r) = theta0 + k*ln(r/r0), k = 1/tan(pitch).  Spin the plane CLOCKWISE (image +y up) for trailing arms.
# The concave (inner) side of such an arm is the +delta side (larger theta at the same radius).
# --------------------------------------------------------------------------------------------------------------------

def arm_delta(r, th, theta0, k, r0):
    return wrap_pi(th - (theta0 + k * np.log(np.maximum(r, 1e-3) / r0))).astype(F32)


def fwhm_profile(d, w):
    return np.exp(-4.0 * math.log(2.0) * (d / w) ** 2).astype(F32)


def arm_points(rng, count, theta0s, k, r0, rr, wfun, spread=0.28):
    pts = []
    for _ in range(count):
        j = rng.integers(len(theta0s))
        r = rng.uniform(*rr)
        d = rng.normal(0.0, spread) * wfun(r)
        t = theta0s[j] + k * math.log(r / r0) + d
        pts.append((r * math.cos(t), r * math.sin(t)))
    return pts


# --------------------------------------------------------------------------------------------------------------------
# 4. te5_galaxy_floor  (1024^2, dais pool 29.6 studs)
# --------------------------------------------------------------------------------------------------------------------

def make_galaxy_floor():
    n = 1024
    x, y, r, th = polar(n)
    k = 1.0 / math.tan(math.radians(16.0))
    r0 = 0.18
    rgl = np.clip((r - r0) / (0.85 - r0), 0.0, 1.0)
    w = 0.18 + (0.35 - 0.18) * rgl                               # arm angular width (FWHM), rad
    La = 0.95 * np.exp(-np.maximum(r - r0, 0.0) / 0.502)         # 0.95 at the bar -> 0.25 at r 0.85
    fil = spiral_noise(r, th, k, 401, size=(512, 2048), along=0.45, beta=1.0, fmin=3.0)
    fil = unit01(fil, 2.0)
    clump = unit01(spiral_noise(r, th, k, 402, size=(256, 512), along=1.6, beta=1.4, fmin=2.0), 1.6)
    wob = 0.05 * spiral_noise(r, th, k, 403, size=(256, 1024), along=0.8, beta=1.4, fmin=2.0)
    arms = np.zeros_like(r); skirt = np.zeros_like(r); lanes = np.zeros_like(r); feath = np.zeros_like(r)
    ain = sstep(0.15, 0.21, r)
    lane_sig = 0.05 / 2.3548
    # feathers: thin spurs that leave each arm's outer (convex) side at a steeper pitch, as in grand-design spirals
    ks = 1.0 / math.tan(math.radians(38.0))
    spur_n = spiral_noise(r, th, ks, 408, size=(64, 512), beta=1.5, fmin=2.0, ylr=6.0)
    spurs = (0.5 + 0.5 * np.cos(13.0 * (th - ks * np.log(np.maximum(r, 1e-3))) + 1.2 * spur_n)) ** 10
    for j in range(2):
        d = arm_delta(r, th, j * math.pi, k, r0) + wob * w
        arms = np.maximum(arms, fwhm_profile(d, w))
        skirt = np.maximum(skirt, fwhm_profile(d, 3.4 * w))
        feath = np.maximum(feath, fwhm_profile(d + 1.25 * w, 1.9 * w))
        dl = d - 0.47 * w                                        # the concave (inner) edge
        lanes = np.maximum(lanes, np.exp(-0.5 * (dl / lane_sig) ** 2))
    arms *= ain; skirt *= ain; feath *= ain * sstep(0.3, 0.45, r)
    lanes *= sstep(0.2, 0.27, r) * sstep(0.88, 0.8, r) * (0.75 + 0.35 * unit01(cart_noise(n, 404, 1.2, 4.0)))
    lanes = np.clip(lanes, 0.0, 1.0)
    # bar along theta = 0, to r 0.18, L 0.85 (slightly fattened where it hands over to the arms)
    bar = 0.85 * np.exp(-(np.abs(x) / 0.185) ** 6) * np.exp(-0.5 * (y / (0.024 + 0.012 * (np.abs(x) / 0.18) ** 2)) ** 2)
    core = np.exp(-0.5 * (r / 0.06) ** 2)
    bulge = 0.5 * np.exp(-0.5 * (r / 0.15) ** 2)
    haze = 0.13 * np.exp(-r / 0.42) * (0.6 + 0.8 * fil)
    armlight = La * (arms * (0.62 + 0.55 * fil) * (0.8 + 0.35 * clump)
                     + 0.62 * skirt * (0.7 + 0.6 * fil)
                     + 0.55 * feath * spurs * (0.6 + 0.8 * fil))
    # knots: 60 bright star-forming clumps along the arms (2-5 px)
    rng = np.random.default_rng(405)
    wf = lambda rr_: 0.18 + 0.17 * min(max((rr_ - r0) / (0.85 - r0), 0), 1)
    kp = arm_points(rng, 60, [0.0, math.pi], k, r0, (0.24, 0.84), wf, spread=0.22)
    knots = gauss_dots(r.shape, [(px_, py_, rng.uniform(1.0, 2.5), rng.uniform(0.8, 1.0)) for px_, py_ in kp], n * SS / 2.0)
    light = screen(bulge, core, bar, armlight + haze, knots)
    base = (11.0 + 3.0 * cart_noise(n, 406, beta=0.6, fmin=8.0).clip(-1.5, 1.5) / 1.5) / 255.0
    L = screen(base, light)
    L = L * (1.0 - lanes) + 0.02 * lanes
    A = 1.0 - sstep(0.86, 1.0, r)
    rgb = np.dstack([L, L, np.minimum(1.0, L * 1.02 + 0.008)])

    def stars(C, A1):
        # 1500 single-pixel stars, L 0.4-1.0, inside r < 0.86 (area-uniform), added after the 2x downsample
        rs = np.random.default_rng(407)
        m = n
        cnt = 0
        while cnt < 1500:
            rr_ = 0.86 * math.sqrt(rs.random()); tt = rs.random() * 2 * math.pi
            i = int((m / 2) - rr_ * math.sin(tt) * (m / 2)); jx = int((m / 2) + rr_ * math.cos(tt) * (m / 2))
            v = 0.4 + 0.6 * rs.random() ** 1.6
            g = C[i, jx, 0]
            if g < v:
                C[i, jx] = (v, v, min(1.0, v * 1.02 + 0.008))
            cnt += 1
        return C, A1

    img = finish("te5_galaxy_floor", (rgb * A[..., None]).astype(F32), A.astype(F32), dither=True, extra=stars)
    a = img[..., 3] / 255.0; g = img[..., 0] / 255.0
    yy, xx = np.mgrid[0:n, 0:n]; rr = np.hypot(xx + 0.5 - n / 2, yy + 0.5 - n / 2) / (n / 2)
    print(f"  galaxy floor mean L (r < 0.86) = {g[rr < 0.86].mean():.3f}  (spec ~0.22)")
    return img


# --------------------------------------------------------------------------------------------------------------------
# 5. te5_galaxy_arms  (1024^2, floating arm layer 21 studs): the same spiral turned 90 deg, pitch 13 deg, arms only
# --------------------------------------------------------------------------------------------------------------------

def make_galaxy_arms():
    n = 1024
    x, y, r, th = polar(n)
    k = 1.0 / math.tan(math.radians(13.0))
    r0 = 0.18
    rgl = np.clip((r - 0.2) / 0.65, 0.0, 1.0)
    w = 0.27 + 0.31 * rgl                                        # FWHM 0.27 -> 0.58 rad: arms, not wires
    fil = unit01(spiral_noise(r, th, k, 501, size=(512, 2048), along=0.45, beta=1.0, fmin=3.0), 2.0)
    feather = spiral_noise(r, th, k, 502, size=(256, 1024), along=1.2, beta=1.3, fmin=2.0)
    wob = 0.06 * spiral_noise(r, th, k, 503, size=(256, 1024), along=0.8, beta=1.4, fmin=2.0)
    prof = np.zeros_like(r); lane = np.zeros_like(r)
    lane_sig = 0.04 / 2.3548
    for j in range(2):
        d = arm_delta(r, th, math.pi / 2 + j * math.pi, k, r0) + wob * w
        wj = w * (1.0 + 0.22 * np.tanh(feather))                # the arm breathes in width along its length
        p = fwhm_profile(d, wj)
        prof = np.maximum(prof, p)
        dl = d - 0.40 * wj                                       # leading (= concave) edge
        lane = np.maximum(lane, np.exp(-0.5 * (dl / lane_sig) ** 2) * sstep(0.12, 0.45, p + 0.3))
    span = sstep(0.13, 0.24, r) * (1.0 - sstep(0.85, 1.0, r))   # arms grow out of the centre; outer 15 % fades
    # alpha = arm profile (1 at the core, Gaussian falloff, cut below 0.05), with filament wisps in the wings
    wisp = prof * (0.5 + 0.7 * fil)
    a_arm = np.maximum(sstep(0.62, 0.9, prof), wisp)            # 1 along the core, wispy Gaussian wings
    a_arm = np.clip((a_arm - 0.05) / 0.95, 0.0, 1.0) * span
    Lw = 0.9 + 0.1 * fil
    # knots
    rng = np.random.default_rng(504)
    wf = lambda rr_: 0.27 + 0.31 * min(max((rr_ - 0.2) / 0.65, 0), 1)
    kp = arm_points(rng, 42, [math.pi / 2, 3 * math.pi / 2], k, r0, (0.26, 0.86), wf, spread=0.18)
    knots = gauss_dots(r.shape, [(px_, py_, rng.uniform(1.2, 2.6), 1.0) for px_, py_ in kp], n * SS / 2.0)
    knots *= (1.0 - sstep(0.85, 0.97, r))
    lane = np.clip(lane * span * sstep(0.2, 0.3, r), 0.0, 1.0)
    white = solid(np.dstack([Lw, Lw, np.minimum(1.0, Lw * 1.01)]), a_arm)
    kn = solid(np.ones((1, 1, 3), F32) * np.asarray([1.0, 1.0, 1.0], F32), knots)
    ink = solid([10, 10, 13], lane)
    P, A = over(ink, over(kn, white))
    return finish("te5_galaxy_arms", P, A, dither=True)


# --------------------------------------------------------------------------------------------------------------------
# 6. te5_galaxy_core  (512^2, inner layer 12 studs): white core + 4 tightly wound thin arms with black lanes
# --------------------------------------------------------------------------------------------------------------------

def make_galaxy_core():
    n = 512
    x, y, r, th = polar(n)
    k = 1.0 / math.tan(math.radians(10.0))
    lr = np.log(np.maximum(r, 1e-3))
    psi = th - k * lr
    d = wrap_pi(4.0 * psi) / 4.0                                 # angular offset to the nearest of the 4 arms
    wob = 0.05 * spiral_noise(r, th, k, 601, size=(256, 1024), along=0.9, beta=1.4, fmin=2.0)
    d = d + wob * 0.2
    breathe = spiral_noise(r, th, k, 604, size=(64, 256), beta=1.4, fmin=2.0, ylr=7.0)
    # arm width set PERPENDICULAR to the arm (r units): 0.016 near the core -> 0.042 at r 0.8, i.e. ~4 -> 11 px. An
    # angular width would make these tightly wound (10 deg) arms sub-pixel hairlines near the centre.
    wp = 0.016 + 0.026 * np.clip((r - 0.1) / 0.7, 0.0, 1.0)
    w = np.minimum(wp / (np.maximum(r, 0.05) * math.sin(math.radians(10.0))), 1.1) * (1.0 + 0.28 * np.tanh(breathe))
    fil = unit01(spiral_noise(r, th, k, 602, size=(256, 2048), along=0.5, beta=1.0, fmin=3.0), 2.0)
    clump = unit01(spiral_noise(r, th, k, 603, size=(64, 256), beta=1.3, fmin=2.0, ylr=9.0), 1.5)
    p = fwhm_profile(d, w)
    # each of the 4 arms has its own length and strength, so the core never reads as concentric rings
    q = 4.0 * psi / (2 * math.pi) + wob * 0.2 * 4.0 / (2 * math.pi)
    j = np.mod(np.floor(q + 0.5), 4).astype(np.int64)
    r_end = np.asarray([0.80, 0.72, 0.78, 0.68], F32)[j]
    gain = np.asarray([1.0, 0.78, 0.92, 0.7], F32)[j]
    span = sstep(0.07, 0.14, r) * sstep(r_end + 0.05, r_end - 0.10, r) * sstep(0.85, 0.80, r)
    a_arm = np.clip((p * gain * (0.72 + 0.4 * fil) * (0.55 + 0.7 * clump) - 0.05) / 0.95, 0.0, 0.9) * span
    # thin black lane on the concave edge: ~1.6 px wide whatever the radius
    lane_sig = (0.0065 / (np.maximum(r, 0.05) * math.sin(math.radians(10.0)))) / 2.3548
    lane = np.exp(-0.5 * ((d - 0.40 * w) / lane_sig) ** 2) * span * sstep(0.14, 0.24, r) * 0.9
    core_a = np.where(r < 0.08, 1.0, np.exp(-((r - 0.08) / 0.075) ** 2) * (1.0 - sstep(0.18, 0.25, r)))
    core_a = np.maximum(core_a, (1.0 - sstep(0.08, 0.25, r)) * 0.0)
    Lw = 0.95 + 0.05 * fil
    arm = solid(np.dstack([Lw, Lw, Lw]), a_arm)
    core = solid([255, 255, 255], core_a.astype(F32))
    ink = solid([10, 10, 13], lane.astype(F32))
    P, A = over(core, over(ink, arm))
    A = A * (1.0 - sstep(0.84, 0.85, r))
    P = P * (1.0 - sstep(0.84, 0.85, r))[..., None]
    return finish("te5_galaxy_core", P.astype(F32), A.astype(F32), dither=True)


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
# 12. te5_moon  (1024^2): a photographic full moon for the camera-facing face sprite (review round 1, art director AD4).
#     North up, the Earth-facing side: maria where the real ones are (Imbrium, Serenitatis, Tranquillitatis, Crisium,
#     Fecunditatis, Nectaris, Nubium, Humorum, Frigoris, Oceanus Procellarum) at grey 95-140, highlands 215-240, ~60
#     craters with lit upper-left rims and shadowed floors (the light comes a little from the upper left, so relief shows
#     on a nearly full moon), rayed Tycho / Copernicus / Kepler, faint limb darkening, a hard alpha edge at r 0.985 with a
#     1.6 % antialias ramp. No ring, no glow (the old te4 moon read as a soap bubble on a billboard).
# --------------------------------------------------------------------------------------------------------------------

def _sph_dir(lat, lon):
    la, lo = math.radians(lat), math.radians(lon)
    return np.array([math.sin(lo) * math.cos(la), math.sin(la), math.cos(lo) * math.cos(la)], dtype=np.float64)


MARIA = [  # (lat, lon, angular radius deg, darkness 0..1): the near side's maria, overlapping so they join up as they do
    (33, -16, 17.0, 1.00), (40, -2, 8.0, 0.9), (28, 17, 10.5, 1.00), (13, 4, 5.0, 0.8), (2, 3, 4.0, 0.7),
    (8.5, 31, 13.0, 0.95), (17, 59, 8.0, 1.00), (-8, 51, 12.0, 0.80), (-2, 40, 6.0, 0.8), (-15, 35, 5.5, 0.85),
    (-21, -17, 11.0, 0.75), (-10, -23, 6.5, 0.7), (-24, -39, 6.5, 0.90), (7, -31, 8.0, 0.75),
    (58, -30, 4.5, 0.55), (57, -5, 4.5, 0.6), (57, 15, 4.5, 0.6), (56, 35, 4.0, 0.5),          # Mare Frigoris
    (20, -55, 15.0, 0.95), (5, -55, 13.0, 0.9), (-5, -45, 10.0, 0.75), (32, -45, 11.0, 0.85), (42, -38, 7.0, 0.8),
    (-12, -58, 8.0, 0.75), (14, -40, 9.0, 0.85),                                                   # Oceanus Procellarum
    (-5, -68, 3.0, 1.0),                                                                          # Grimaldi
]
RAYED = [  # (lat, lon, crater angular radius deg, rays, ray length deg, strength)
    (-43.3, -11.2, 1.45, 26, 55.0, 1.0), (9.6, -20.1, 1.6, 22, 22.0, 0.8), (8.1, -38.0, 0.9, 16, 14.0, 0.55),
    (23.7, -47.4, 0.7, 10, 8.0, 0.5),
]


def make_moon():
    n = 1024
    x, y, r, th = polar(n)
    R = 0.985
    u = np.broadcast_to(np.clip(x / R, -1.0, 1.0), r.shape).astype(np.float64)
    v = np.broadcast_to(np.clip(y / R, -1.0, 1.0), r.shape).astype(np.float64)
    inside = (u * u + v * v) < 1.0
    w = np.sqrt(np.clip(1.0 - u * u - v * v, 0.0, 1.0))
    P3 = np.stack([u, v, w], axis=-1).astype(np.float64)          # the sphere point (unit) seen at each pixel

    def ang(c):
        return np.arccos(np.clip(P3 @ c, -1.0, 1.0))               # angular distance to direction c (rad)
    rng = np.random.default_rng(1201)
    # albedo: highlands with large-scale variation, maria with lobed (not speckled) shores and internal tone
    big = cart_noise(n, 1202, beta=1.8, fmin=2.0)
    mid = cart_noise(n, 1203, beta=1.5, fmin=5.0)
    fine = cart_noise(n, 1204, beta=0.6, fmin=40.0)
    # (a metaball field: overlapping basins merge into the connected dark pattern of the real near side)
    field = np.zeros(r.shape, np.float64)
    for lat, lon, rad_, dark in MARIA:
        c = _sph_dir(lat, lon)
        a = ang(c)
        field += dark * np.exp(-(a / (math.radians(rad_) * 1.12)) ** 2.4)
    field = field + 0.16 * np.tanh(big / 1.0) + 0.06 * np.tanh(mid / 1.2)
    mare = sstep(0.36, 0.62, field) * (0.85 + 0.15 * sstep(0.5, 1.2, field))
    mare = np.clip(mare * (0.9 + 0.15 * unit01(big, 1.6)), 0.0, 1.0)
    high = 0.885 + 0.035 * np.tanh(big / 1.5) + 0.015 * np.tanh(mid / 1.5)    # ~0.83 .. 0.94  (212 .. 240)
    mareL = 0.47 + 0.07 * np.tanh(big / 1.2) + 0.025 * np.tanh(mid / 1.5)     # ~0.37 .. 0.57  (95 .. 145)
    alb = high * (1.0 - mare) + mareL * mare
    # craters: a power-law size spread, more of them in the bright highlands. On a full moon they read mostly as bright
    # rims and slightly darker floors (albedo), with a little relief from light coming from the upper left.
    hmap = np.zeros(r.shape, np.float64)
    cr_list = []
    tries = 0
    while len(cr_list) < 62 and tries < 4000:
        tries += 1
        z = rng.uniform(-1, 1); phi = rng.uniform(-math.pi, math.pi)
        c = np.array([math.sqrt(1 - z * z) * math.sin(phi), z, math.sqrt(1 - z * z) * math.cos(phi)])
        if c[2] < 0.2:
            continue                                                # (the limb and the far side)
        px = int((c[0] * R * 0.5 + 0.5) * (n * SS - 1)); py = int((0.5 - c[1] * R * 0.5) * (n * SS - 1))
        if mare[py, px] > 0.5 and rng.random() < 0.75:
            continue
        rad_ = math.radians(min(5.0, 0.45 * rng.pareto(1.7) + 0.45))
        cr_list.append((c, rad_))
    for c, rad_ in cr_list:
        a = ang(c) / rad_
        sel = a < 2.2
        if not sel.any():
            continue
        d = a[sel]
        bowl = -0.5 * (1.0 - sstep(0.55, 0.95, d))
        rim = 0.30 * np.exp(-((d - 1.0) / 0.14) ** 2)
        ejecta = 0.06 * np.exp(-np.maximum(d - 1.05, 0.0) * 3.0) * sstep(0.95, 1.1, d)
        hmap[sel] += (bowl + rim + ejecta) * rad_ * 4.0
        fresh = 1.0 + 0.6 * (rad_ < math.radians(1.2))              # small young craters are brighter
        alb[sel] = alb[sel] * (1.0 - 0.07 * (1.0 - sstep(0.5, 0.95, d))) + (1.0 - alb[sel]) * 0.10 * fresh * np.exp(-((d - 1.0) / 0.12) ** 2)
    # rays: bright streaks along great circles out of the young craters, plus a soft bright ejecta collar round each
    for lat, lon, crad, nr, rlen, s_ in RAYED:
        c = _sph_dir(lat, lon)
        a = ang(c)
        north = np.array([0.0, 1.0, 0.0])
        e1 = np.cross(north, c); e1 /= np.linalg.norm(e1); e2 = np.cross(c, e1)
        pt = P3 - (P3 @ c)[..., None] * c
        phi = np.arctan2(pt @ e2, pt @ e1)
        cr = math.radians(crad)
        rays = np.zeros(r.shape, np.float64)
        for k in range(nr):
            az = rng.uniform(-math.pi, math.pi)
            wid = math.radians(rng.uniform(0.35, 1.2))
            ln = math.radians(rlen * rng.uniform(0.35, 1.0))
            dphi = np.angle(np.exp(1j * (phi - az)))
            across = np.abs(dphi) * np.sin(np.clip(a, 1e-4, None))
            prof = np.exp(-(across / (wid * (1.0 + a / max(ln, 1e-3)))) ** 2) * sstep(ln, ln * 0.2, a) * sstep(cr * 1.1, cr * 2.2, a)
            rays = np.maximum(rays, prof * rng.uniform(0.55, 1.0))
        collar = np.exp(-((a - cr * 1.6) / (cr * 1.1)) ** 2)
        boost = s_ * (0.55 * rays * (0.75 + 0.25 * unit01(fine, 1.0)) + 0.35 * collar)
        alb = alb + (1.0 - alb) * np.clip(boost, 0, 1)
        hmap += 0.35 * np.exp(-((a / cr - 1.0) / 0.15) ** 2) * cr * 4.0 - 0.35 * (1.0 - sstep(0.5, 0.95, a / cr)) * cr * 4.0
    # relief: bump the sphere normal with the height map's gradient (fading out toward the limb, where foreshortening
    # would exaggerate it); light from the upper left
    gy, gx = np.gradient(hmap)
    k = (n * SS) / 2.0 * 0.6
    fade = sstep(0.05, 0.45, w)
    nx = u - k * gx * fade; ny = v + k * gy * fade; nz = w
    nl = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-9
    nx, ny, nz = nx / nl, ny / nl, nz / nl
    Ld = np.array([-0.42, 0.42, 0.80]); Ld /= np.linalg.norm(Ld)
    base_l = u * Ld[0] + v * Ld[1] + w * Ld[2]
    bump_l = nx * Ld[0] + ny * Ld[1] + nz * Ld[2]
    relief = np.clip(1.0 + 0.85 * (bump_l - base_l), 0.8, 1.14)       # only the relief, not a crescent
    limb = 0.80 + 0.20 * np.power(w, 0.6)                             # the full moon is nearly flat; a touch of limb
    L = alb * relief * limb * (1.0 + 0.02 * np.tanh(fine))
    L = np.clip(L, 0.0, 1.0)
    A = np.clip((R + 0.008 - r) / 0.016, 0.0, 1.0)
    L = np.where(inside, L, 0.6)
    Lf = L.astype(F32)
    rgb = np.dstack([Lf, Lf, np.minimum(1.0, Lf + 3.0 / 255.0)])
    img = finish("te5_moon", (rgb * A[..., None]).astype(F32), A.astype(F32), dither=True)
    g = img[..., 0].astype(np.float64); a8 = img[..., 3]
    print(f"  moon: grey p5/p50/p95 inside = {np.percentile(g[a8 == 255], 5):.0f} / {np.percentile(g[a8 == 255], 50):.0f} / "
          f"{np.percentile(g[a8 == 255], 95):.0f}  ({len(cr_list)} craters)")
    return img


# --------------------------------------------------------------------------------------------------------------------
# 13. te5_star_window  (1024^2): the deep-space window on the clock's movement plate (behind the skeleton dial). An
#     opaque near-black field (alpha 1 to r 0.985), a faint grey Milky-Way band with dust lanes across it, ~2600
#     single-pixel stars and ~70 brighter ones with a soft core, a few with tiny 4-point spikes. Night Brightness 2.0
#     blooms only the brightest stars.
# --------------------------------------------------------------------------------------------------------------------

def make_star_window():
    n = 1024
    x, y, r, th = polar(n)
    # the band: a soft diagonal Milky Way, its own fine structure and two dark dust lanes along it
    ang_ = math.radians(32.0)
    across = np.broadcast_to(x * math.sin(ang_) - y * math.cos(ang_), r.shape) + 0.06 * cart_noise(n, 1301, beta=1.5, fmin=2.0)
    along = np.broadcast_to(x * math.cos(ang_) + y * math.sin(ang_), r.shape)
    band = np.exp(-0.5 * (across / 0.20) ** 2) * (0.75 + 0.25 * np.cos(along * 2.2))
    cloud = unit01(cart_noise(n, 1302, beta=1.25, fmin=3.0), 1.4)
    fil = unit01(cart_noise(n, 1303, beta=0.9, fmin=10.0), 1.2)
    lane = np.exp(-0.5 * ((across - 0.03 + 0.03 * cart_noise(n, 1304, beta=1.6, fmin=2.0)) / 0.025) ** 2)
    lane2 = np.exp(-0.5 * ((across + 0.09) / 0.018) ** 2) * sstep(-0.2, 0.3, along)
    neb = band * (0.10 + 0.14 * cloud * fil) * (1.0 - 0.85 * np.maximum(lane, 0.7 * lane2))
    base = 0.018 + 0.010 * unit01(cart_noise(n, 1305, beta=0.8, fmin=6.0), 1.0)
    # brighter stars: soft cores (2-4 px at SS) drawn at SS; more of them inside the band
    rng = np.random.default_rng(1306)
    pts = []
    while len(pts) < 70:
        rr_ = 0.97 * math.sqrt(rng.random()); tt = rng.random() * 2 * math.pi
        px_, py_ = rr_ * math.cos(tt), rr_ * math.sin(tt)
        acr = px_ * math.sin(ang_) - py_ * math.cos(ang_)
        if rng.random() > 0.35 + 0.65 * math.exp(-0.5 * (acr / 0.22) ** 2):
            continue
        pts.append((px_, py_, rng.uniform(1.2, 3.2), rng.uniform(0.55, 1.0)))
    bright = gauss_dots(r.shape, pts, n * SS / 2.0)
    # spikes on the five brightest
    spikes = np.zeros_like(r)
    for px_, py_, rad_, val in sorted(pts, key=lambda p: -p[3] * p[2])[:5]:
        dx = (x - px_) * (n * SS / 2.0); dy = (y - py_) * (n * SS / 2.0)
        ln = 14.0 * rad_
        spikes = np.maximum(spikes, val * 0.8 * (np.exp(-np.abs(dx) / ln) * np.exp(-(dy / 0.9) ** 2)
                                                + np.exp(-np.abs(dy) / ln) * np.exp(-(dx / 0.9) ** 2)))
    L = screen(base + neb, bright, spikes)
    A = np.clip((0.985 + 0.008 - r) / 0.016, 0.0, 1.0)
    rgb = np.dstack([L, L, np.minimum(1.0, L * 1.02 + 0.006)]).astype(F32)

    def stars(C, A1):
        rs = np.random.default_rng(1307)
        m = n
        for _ in range(2600):
            rr_ = 0.975 * math.sqrt(rs.random()); tt = rs.random() * 2 * math.pi
            i = int((m / 2) - rr_ * math.sin(tt) * (m / 2)); jx = int((m / 2) + rr_ * math.cos(tt) * (m / 2))
            vv = 0.25 + 0.75 * rs.random() ** 2.4
            if C[i, jx, 0] < vv:
                C[i, jx] = (vv, vv, min(1.0, vv * 1.02 + 0.006))
        return C, A1

    img = finish("te5_star_window", (rgb * A[..., None]).astype(F32), A.astype(F32), dither=True, extra=stars)
    g = img[..., 0]
    print(f"  star window: mean L inside = {g[img[..., 3] == 255].mean() / 255:.3f}")
    return img


# --------------------------------------------------------------------------------------------------------------------
# 10. te5_stream  (256x64, beam band tiled in U): ink edges, white core with waving filaments
# 11. te5_ribbon  (256x128): ink ribbon, white hairlines, faint waving centre filament
# Image x runs along the beam (U, seamless with period 256 px); y runs across it (v in [-0.5, 0.5]).
# --------------------------------------------------------------------------------------------------------------------

def band_grid(W, H):
    Ws, Hs = W * SS, H * SS
    u = ((np.arange(Ws, dtype=F32) + 0.5) / Ws)[None, :]           # [0, 1) along, one period
    v = ((np.arange(Hs, dtype=F32) + 0.5) / Hs - 0.5)[:, None]     # [-0.5, 0.5] across
    return u, v, Ws, Hs


def lines_x(u, v, centres, half_w_v, aa_v):
    """max-coverage of horizontal-ish lines v = centre(u) with half width half_w_v (v units), AA ramp aa_v."""
    out = np.zeros(np.broadcast(u, v).shape, F32)
    for c in centres:
        d = np.abs(v - c) - half_w_v
        out = np.maximum(out, np.clip(0.5 - d / aa_v, 0.0, 1.0))
    return out


def make_stream():
    W, H = 256, 64
    u, v, Ws, Hs = band_grid(W, H)
    px = 1.0 / H                                                  # one output px in v units
    av = np.abs(v)
    A = np.clip((0.40 - av) / (1.5 * px) + 0.5, 0.0, 1.0)         # alpha 1 inside |v| < 0.40, 1.5 px AA edge
    A = np.broadcast_to(A, (Hs, Ws)).astype(F32)
    core_mix = sstep(0.31 + px, 0.31 - px, av)                    # white core |v| < 0.30, ink 0.32-0.40, 2 px transition
    rng = np.random.default_rng(1001)
    base = np.full((Hs, Ws), 0.80, F32)
    # gentle lengthwise shimmer (integer harmonics only: seamless)
    for m in (1, 2, 3):
        base += 0.025 * np.cos(2 * math.pi * (m * u + rng.random())) * np.cos(2 * math.pi * (v * (2 + m)) + rng.random() * 6)
    fil = np.zeros((Hs, Ws), F32)
    nfil = 6
    for i in range(nfil):
        c0 = -0.24 + 0.48 * (i + 0.5) / nfil + rng.uniform(-0.015, 0.015)
        amp = rng.uniform(0.018, 0.04)
        m = 1                                                     # one wave per 256 px tile (the spec's period)
        ph = rng.random() * 2 * math.pi
        centre = c0 + amp * np.sin(2 * math.pi * m * u + ph)
        lum = 0.85 + 0.15 * (0.5 + 0.5 * np.cos(2 * math.pi * (u * (m + 1)) + ph * 1.3))   # light beads riding along
        d = np.abs(v - centre)
        fil = np.maximum(fil, np.exp(-0.5 * (d / (0.85 * px)) ** 2) * lum)
    fil *= sstep(0.30, 0.27, av)
    Lcore = base + (1.0 - base) * fil
    ink = 12.0 / 255.0
    L = ink + (Lcore - ink) * core_mix
    L = np.clip(L, 0.0, 1.0).astype(F32)
    rgb = np.dstack([L, L, np.minimum(1.0, L + 0.006)])
    return finish_band("te5_stream", rgb, A)


def make_ribbon():
    W, H = 256, 128
    u, v, Ws, Hs = band_grid(W, H)
    px = 1.0 / H
    av = np.abs(v)
    A = np.broadcast_to(np.clip((0.46 - av) / (1.5 * px) + 0.5, 0.0, 1.0), (Hs, Ws)).astype(F32)
    # ink body with +-6-level longitudinal streaks (vary across, drift slowly along; integer harmonics: seamless)
    rng = np.random.default_rng(1101)
    streak = np.zeros((Hs, Ws), F32)
    for i in range(14):
        f = rng.uniform(3, 22)
        ph = rng.random() * 2 * math.pi
        m = rng.integers(1, 3)
        streak += np.cos(2 * math.pi * f * (v + 0.012 * np.sin(2 * math.pi * m * u + rng.random() * 6)) + ph) / math.sqrt(f)
    streak = streak / (np.abs(streak).max() + 1e-6)
    body = (14.0 + 6.0 * streak) / 255.0
    # white hairlines 245, 2 px, centred in |v| 0.40-0.43
    hair = lines_x(u, v, [-0.415, 0.415], 1.0 * px, 1.0 / Hs * 1.0)
    # faint white centre filament, 1 px, L 0.6, waving with the 256 px period
    cen = 0.045 * np.sin(2 * math.pi * u + 0.7)
    fcov = np.clip(0.5 - (np.abs(v - cen) - 0.65 * px) / (1.0 / Hs), 0.0, 1.0)
    L = body * (1 - hair) + (245.0 / 255.0) * hair
    L = L * (1 - fcov * 0.92) + 0.6 * fcov * 0.92
    L = np.clip(L, 0.0, 1.0).astype(F32)
    rgb = np.dstack([L, L, np.minimum(1.0, L + 4.0 / 255.0)])
    return finish_band("te5_ribbon", rgb, A)


def finish_band(name, rgb, A):
    return finish(name, (rgb * A[..., None]).astype(F32), A.astype(F32))


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
               "te5_engraving", "te5_halo", "te5_hairspring", "te5_stream", "te5_ribbon", "te5_moon", "te5_star_window"]


def sheet_overview():
    """All 13 textures over the dark and the sky background (tiles 400 px; beams tiled 2x along U)."""
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
             ("te5_hairspring", (256, 160, 512, 352), 2), ("te5_accretion", (600, 40, 1000, 300), 1),
             ("te5_galaxy_floor", (380, 380, 780, 640), 1), ("te5_galaxy_arms", (100, 300, 500, 560), 1),
             ("te5_galaxy_core", (160, 160, 352, 352), 2), ("te5_halo", (256, 0, 512, 256), 1),
             ("te5_stream", (0, 0, 256, 64), 3), ("te5_ribbon", (0, 0, 256, 128), 2),
             ("te5_moon", (300, 300, 700, 560), 1), ("te5_star_window", (380, 380, 636, 636), 1)]
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
    chapter ring + te5_dial_inlay, the open skeleton centre, the dark sub-dial + te5_subdial. Day (Brightness 1.6/1.4)
    over the sky and night (2.6/2.2, bloom) over the night sky."""
    S = 15.4                                   # px per stud
    W, H = 520, 520
    cx = cy = W / 2
    out = []
    for mode in ("day", "night"):
        cp = Comp(W, H, BG_SKY if mode == "day" else (20, 22, 30))
        cp.disc(cx, cy, 12.2 * S, 14.0 * S, (176, 180, 190) if mode == "day" else (120, 124, 134))   # bezel
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
    """The dais stack at in-game scale: engraving (40) on the plaza, dark base (29.6) + te5_galaxy_floor, the floating
    arms (21, +0.42) and core (12, +0.66) at their relative spins after t seconds, silver rim (31.1), the balance wheel
    hairspring (3.8). Top-down and from a 32-degree camera, by day and by night."""
    S = 13.0                                   # px per stud
    out = []
    eng = load("te5_engraving"); flo = load("te5_galaxy_floor"); arm = load("te5_galaxy_arms")
    cor = load("te5_galaxy_core"); hs = load("te5_hairspring")
    for mode in ("day", "night"):
        for view in ("top", "persp"):
            W, H = 600, 600 if view == "top" else 380
            ground = SAND if mode == "day" else NIGHT_GROUND
            cp = Comp(W, H, ground)
            cx, cy = W / 2, H / 2 if view == "top" else H * 0.52
            elev = 90 if view == "top" else 32
            day = mode == "day"
            layers = [(eng, 40.0, 2.5, 1.2 if day else 2.0, 0.0), ]
            for img, dia, rate, br, lift in [(eng, 40.0, 2.5, 1.2 if day else 2.0, 0.0),
                                             (None, 29.6, 0, 0, 0.06),
                                             (flo, 29.6, -6.0, 1.3 if day else 2.4, 0.15),
                                             (None, 31.1, 0, 0, 0.9),
                                             (arm, 21.0, 9.0, 1.4 if day else 2.4, 0.42),
                                             (cor, 12.0, -16.0, 1.5 if day else 2.6, 0.66),
                                             (hs, 3.8, 40.0, 1.4 if day else 2.2, 2.27)]:
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
    B5 ribbon (WHITE and the spec's Color 12,12,16), each with the spec's Wrap repeat count."""
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
                 ("te5_ribbon", "B5 ribbon WHITE (te5)", (248, 249, 255), 1.0, 2.2, 0.9, 8, 180),
                 ("te5_ribbon", "B5 ribbon Color 12,12,16 (spec)", (12, 12, 16), 1.0, 2.2, 0.9, 8, 250)]
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
# manifest.json (read by tools/preview: 'file' is relative to this folder; uploadedId is filled on the Mac after upload)
# --------------------------------------------------------------------------------------------------------------------

MANIFEST = [
    ("te5_dial_inlay", "dialInlay", "dialOuter", "1024x1024",
     "Inlaid Roman numerals, minute track and inner ring on the solid dark chapter ring (C3 inlay plane, 24.4 studs)",
     "C3 SurfaceGui Face=Back, image +y toward XII. r 1 = 12.2 studs. White 250 strokes, 2 px ink (10,10,14, 0.9). "
     "Radial numerals (tops outward, XII upright), IIII at 4 as on clock dials. Half-hour 4-point stars, tip radius 0.025."),
    ("te5_subdial", "subdial", "dialInner", "512x512",
     "Engraved guilloche face of the 6.5-stud sub-dial at the clock centre (C6)",
     "C6 Face=Left. 24-circle rosette (alpha 0.85, no ink) kept off r < 0.15, which the hub stack covers anyway."),
    ("te5_accretion", "accretion", "galaxy4", "1024x1024",
     "Opaque swirling accretion disc around the void (V2, 13-stud plane, Top+Bottom GUIs)",
     "Streaks and the 3 dust lanes wind CLOCKWISE outward (image +y up): turn the image COUNTER-clockwise (as seen on "
     "the Top face) for trailing streaks -- verify the sign of 'dir' in the preview. Opaque BLACK inner skirt r 0.60-0.68 "
     "(inside / under the 8-stud core's silhouette at r 0.615) so the bright day sky never shows between the core and the "
     "white-hot edge; the spec's soft inner edge (0.68-0.72) is drawn as white fading into that black."),
    ("te5_galaxy_floor", "galaxyFloor", "galaxy4", "1024x1024",
     "Dark galaxy pool on the dais base (D2, 29.6 studs), the day-readable dark stage with white arms",
     "Barred 2-arm spiral, arms wind COUNTER-clockwise outward (image +y up): a CLOCKWISE spin of the image makes them "
     "trail (spec rate -6 deg/s; verify the Top-face orientation in the preview). Opaque to r 0.86. Mean L 0.218."),
    ("te5_galaxy_arms", "galaxyArms", "galaxy4", "1024x1024",
     "Floating arm layer above the pool for parallax (D3, 21 studs)",
     "Same winding as the floor, turned 90 deg, pitch 13. Arms are opaque white along their cores with wispy wings and a "
     "black lane on the concave (= leading for a counter-clockwise spin) edge. The spec spins D3 at +9 deg/s against "
     "D2's -6: counter-rotating layers (strong parallax); its arms then lead rather than trail."),
    ("te5_galaxy_core", "galaxyCore", "ornate", "512x512",
     "Bright core layer under the feet (D4, 12 studs)",
     "White core + 4 tightly wound (10 deg) arms with black lanes, same winding as the floor; each arm has its own length "
     "(0.68-0.80) and strength so it reads as a vortex, not rings."),
    ("te5_engraving", "engraving", "gring", "1024x1024",
     "Engraved clock ring on the ground around the dais (D5, 40 studs)",
     "White 240, 2 px ink (20). Numeral strokes are the spec's height-scaled thick/thin plus 12 / 25 % so the thin "
     "serifs stay ~2.7 px for the grazing ground view."),
    ("te5_halo", "halo", "rim", "512x512",
     "Rim-only halo: moon halo billboard (13 studs) and night bezel corona (C10, 40 studs)",
     "White; alpha 0 below r 0.66, 0.95 at 0.74, 0.35 at 0.82, 0.10 at 0.90, 0 at 1.0 (monotone cubic, dithered). "
     "Tint with ImageColor3 (236,240,248)."),
    ("te5_hairspring", "hairspring", "swirl", "512x512",
     "Hairspring spiral on the balance wheel under the feet (D8)",
     "9-turn Archimedean spiral r 0.12 -> 0.92 that eases out of the collet (r 0.10), terminal stud at the outer end."),
    ("te5_stream", "stream", "line", "256x64",
     "Palm stream beams B1 (silver) and B3 (ink, via Beam Color)",
     "Beam texture: image x runs ALONG the beam (seamless every 256 px, TextureMode Wrap), y across. White core with 6 "
     "waving filaments, ink edges. Color WHITE = silver stream with ink edges; Color (18,18,24) = all-ink stream."),
    ("te5_ribbon", "ribbon", "line", "256x128",
     "Equinox-style ink ribbon beam B5 from the void into the dais",
     "Beam texture (x along, seamless 256 px). Ink body (14,14,18 +-6), white hairlines at |v| 0.415, faint waving centre "
     "filament. The white hairlines need a LIGHT Beam Color: use WHITE with te5_ribbon. The spec's B5 Color (12,12,16) "
     "multiplies them to black (keep (12,12,16) only for the 'line' fallback)."),
    ("te5_moon", "moon", "moon", "1024x1024",
     "Photographic full-moon face for the moon's camera-facing sprite (review round 1, AD4; 9-stud BillboardGui)",
     "North up, Earth-facing side: maria at grey 95-145 where the real ones are, highlands 212-240, ~60 craters with "
     "lit upper-left rims and shadowed floors, rayed Tycho/Copernicus/Kepler/Aristarchus, faint limb darkening. Hard "
     "alpha edge at r 0.985 (1.6 % ramp), no ring, no glow. With it uploaded the module swaps the white ball + craters "
     "+ halo for a 6-stud grey core 4.4 studs behind this sprite; until then (fallback) it keeps the geometry moon."),
    ("te5_star_window", "starWindow", "galaxy4", "1024x1024",
     "Deep-space window on the clock's solid movement plate behind the skeleton dial (review round 1, AD1)",
     "Opaque near-black field (alpha 1 to r 0.985), faint grey Milky-Way band at 32 deg with dust lanes, ~2600 "
     "single-pixel stars and ~70 soft brighter ones (5 with tiny spikes). Turns with the centre wheel (+6 deg/s). "
     "Until uploaded it falls back to the pass-4 galaxy (galaxy4), drawn dimmer."),
]


def write_manifest():
    entries = []
    for name, key, fb, size, purpose, notes in MANIFEST:
        entries.append({"name": name, "file": name + ".png", "repoPath": "textures/te5/surfaces/" + name + ".png",
                        "texKey": key, "fallbackTexKey": fb, "size": size, "layout": "None", "purpose": purpose,
                        "notes": notes, "uploadedId": None})
    with open(os.path.join(OUT, "manifest.json"), "w") as f:
        json.dump(entries, f, indent=1, ensure_ascii=False)
        f.write("\n")
    return entries


def _radial_mean(img, ch, rs, n):
    yy, xx = np.mgrid[0:n, 0:n]
    rr = np.hypot(xx + 0.5 - n / 2, yy + 0.5 - n / 2) / (n / 2)
    return [float(img[..., ch][np.abs(rr - r) < 0.004].mean()) / 255.0 for r in rs]


def check():
    """Numerical spec checks on the written PNGs. Returns a list of failures (empty = all good)."""
    fails = []
    def ok(cond, msg):
        print(("  ok   " if cond else "  FAIL ") + msg)
        if not cond:
            fails.append(msg)
    sizes = {"te5_dial_inlay": (1024, 1024), "te5_subdial": (512, 512), "te5_accretion": (1024, 1024),
             "te5_galaxy_floor": (1024, 1024), "te5_galaxy_arms": (1024, 1024), "te5_galaxy_core": (512, 512),
             "te5_engraving": (1024, 1024), "te5_halo": (512, 512), "te5_hairspring": (512, 512),
             "te5_stream": (256, 64), "te5_ribbon": (256, 128), "te5_moon": (1024, 1024), "te5_star_window": (1024, 1024)}
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
    return fails


def make_sheets():
    os.makedirs(SHEETS, exist_ok=True)
    paths = []
    for fn in (sheet_overview, sheet_zoom, insitu_clock, insitu_dais, insitu_void, insitu_halo_beams):
        t0 = time.time()
        paths += fn()
        print(f"sheet {fn.__name__}: {time.time() - t0:.1f}s")
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
job("te5_hairspring", make_hairspring)
job("te5_stream", make_stream)
job("te5_ribbon", make_ribbon)
job("te5_moon", make_moon)
job("te5_star_window", make_star_window)


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
