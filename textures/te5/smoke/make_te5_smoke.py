#!/usr/bin/env python3
# THE END (1 in 1,000,000,000) -- equipped aura, pass 5 "The Last Clock" -- texture group "smoke" (prototype)
import argparse, json, math, os, sys, time
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.dirname(os.path.abspath(__file__))
F32 = np.float32


def sstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def gblur(a, sigma):
    if sigma <= 0:
        return a.astype(F32)
    r = int(math.ceil(sigma * 3.0))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2).astype(F32)
    k /= k.sum()
    out = a.astype(F32)
    for ax in (0, 1):
        pad = [(0, 0)] * out.ndim
        pad[ax] = (r, r)
        p = np.pad(out, pad, mode="constant")
        acc = np.zeros_like(out)
        n = out.shape[ax]
        for i, w in enumerate(k):
            sl = [slice(None)] * out.ndim
            sl[ax] = slice(i, i + n)
            acc += w * p[tuple(sl)]
        out = acc
    return out


def rot3(seed):
    """A random rotation matrix (deterministic)."""
    rng = np.random.default_rng(seed)
    q = rng.standard_normal(4)
    q /= np.linalg.norm(q)
    a, b, c, d = q
    return np.array([[a*a+b*b-c*c-d*d, 2*(b*c-a*d), 2*(b*d+a*c)],
                     [2*(b*c+a*d), a*a-b*b+c*c-d*d, 2*(c*d-a*b)],
                     [2*(b*d-a*c), 2*(c*d+a*b), a*a-b*b-c*c+d*d]], F32)


class Vol:
    """Periodic band-limited 3D noise (spectral synthesis), mean 0, std 1. Looked up trilinearly in voxel units."""

    def __init__(self, seed, n=128, fmin=6.0, fmax=12.0):
        rng = np.random.default_rng(seed)
        f1 = np.fft.fftfreq(n) * n
        f2 = np.fft.rfftfreq(n) * n
        f = np.sqrt(f1[:, None, None] ** 2 + f1[None, :, None] ** 2 + f2[None, None, :] ** 2)
        amp = sstep(fmin * 0.6, fmin, f) * (1.0 - sstep(fmax, fmax * 1.5, f))
        spec = (rng.standard_normal(amp.shape) + 1j * rng.standard_normal(amp.shape)) * amp
        v = np.fft.irfftn(spec, s=(n, n, n), axes=(0, 1, 2))
        v = (v - v.mean()) / (v.std() + 1e-12)
        self.n, self.m = n, n + 1
        self.fc = 0.5 * (fmin + fmax)          # centre frequency, cycles per period
        self.flat = np.pad(v.astype(F32), ((0, 1), (0, 1), (0, 1)), mode="wrap").ravel()

    def at(self, u, v, w):
        """u, v, w = x, y, z in voxel units (any range: the volume wraps)."""
        n, m, fl = self.n, self.m, self.flat
        x0 = np.floor(u)
        y0 = np.floor(v)
        z0 = np.floor(w)
        fx = (u - x0).astype(F32)
        fy = (v - y0).astype(F32)
        fz = (w - z0).astype(F32)
        i = ((z0.astype(np.int32) % n) * m + (y0.astype(np.int32) % n)) * m + (x0.astype(np.int32) % n)
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

    def sample(self, X, Y, Z, freq, R, off):
        """noise at points (cell units) with 'freq' features (cycles) per cell, rotated by R, offset 'off' (periods)."""
        k = freq / self.fc * self.n
        u = (R[0, 0] * X + R[0, 1] * Y + R[0, 2] * Z) * k + off[0] * self.n
        v = (R[1, 0] * X + R[1, 1] * Y + R[1, 2] * Z) * k + off[1] * self.n
        w = (R[2, 0] * X + R[2, 1] * Y + R[2, 2] * Z) * k + off[2] * self.n
        return self.at(u, v, w)


class CurlVol:
    """A periodic divergence-free velocity field (curl of a band-limited vector potential), RMS speed 1.
    Period = 1 cell unit; 'fmin..fmax' cycles per cell."""

    def __init__(self, seed, n=64, fmin=2.0, fmax=4.0):
        rng = np.random.default_rng(seed)
        f1 = np.fft.fftfreq(n) * n
        f2 = np.fft.rfftfreq(n) * n
        KZ, KY, KX = np.meshgrid(f1, f1, f2, indexing="ij")
        f = np.sqrt(KX ** 2 + KY ** 2 + KZ ** 2)
        amp = sstep(fmin * 0.6, fmin, f) * (1.0 - sstep(fmax, fmax * 1.5, f))
        A = [(rng.standard_normal(amp.shape) + 1j * rng.standard_normal(amp.shape)) * amp for _ in range(3)]
        Ax, Ay, Az = A
        I2p = 2j * np.pi
        # curl = (dAz/dy - dAy/dz, dAx/dz - dAz/dx, dAy/dx - dAx/dy)
        Vx = I2p * (KY * Az - KZ * Ay)
        Vy = I2p * (KZ * Ax - KX * Az)
        Vz = I2p * (KX * Ay - KY * Ax)
        comps = [np.fft.irfftn(V, s=(n, n, n), axes=(0, 1, 2)) for V in (Vx, Vy, Vz)]
        rms = math.sqrt(sum(float((c ** 2).mean()) for c in comps))
        self.n, self.m = n, n + 1
        self.flat = [np.pad((c / rms).astype(F32), ((0, 1), (0, 1), (0, 1)), mode="wrap").ravel() for c in comps]

    def at(self, X, Y, Z, scale=1.0, off=(0.0, 0.0, 0.0)):
        n, m = self.n, self.m
        u = (X * scale + off[0]) * n
        v = (Y * scale + off[1]) * n
        w = (Z * scale + off[2]) * n
        x0 = np.floor(u)
        y0 = np.floor(v)
        z0 = np.floor(w)
        fx = (u - x0).astype(F32)
        fy = (v - y0).astype(F32)
        fz = (w - z0).astype(F32)
        i = ((z0.astype(np.int32) % n) * m + (y0.astype(np.int32) % n)) * m + (x0.astype(np.int32) % n)
        out = []
        for fl in self.flat:
            c0 = fl[i] + (fl[i + 1] - fl[i]) * fx
            c1 = fl[i + m] + (fl[i + m + 1] - fl[i + m]) * fx
            c0 += (c1 - c0) * fy
            c2 = fl[i + m * m] + (fl[i + m * m + 1] - fl[i + m * m]) * fx
            c3 = fl[i + m * m + m] + (fl[i + m * m + m + 1] - fl[i + m * m + m]) * fx
            c2 += (c3 - c2) * fy
            c0 += (c2 - c0) * fz
            out.append(c0)
        return out


# --------------------------------------------------------------------------------------------------------------------
# flow maps: where the smoke at x (frame k) was at t = 0 (backward advection through a velocity field, composed frame by
# frame on a G^3 grid over the cell cube [-0.5, 0.5]^3)
# --------------------------------------------------------------------------------------------------------------------


def grid_interp(Phi, G, X, Y, Z):
    """Trilinear lookup of a (3, G, G, G) [comp, z, y, x] grid map at points X, Y, Z (cell units), clamped."""
    def idx(c):
        q = np.clip((c + 0.5) * G - 0.5, 0.0, G - 1.0001)
        i0 = np.floor(q).astype(np.int32)
        return i0, (q - i0).astype(F32)
    ix, fx = idx(X)
    iy, fy = idx(Y)
    iz, fz = idx(Z)
    out = []
    for c in range(3):
        g = Phi[c]
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


def flow_maps(times, vel, G=64, substeps=4):
    """times: increasing frame times. vel(X, Y, Z, t) -> (u, v, w). Returns a list of (3, G, G, G) maps (material
    position of the smoke at each grid point at that frame's time)."""
    g = ((np.arange(G) + 0.5) / G - 0.5).astype(F32)
    Z, Y, X = np.meshgrid(g, g, g, indexing="ij")
    maps = []
    prev, tprev = None, 0.0
    for t in times:
        # trace back from t to tprev (RK2, substeps)
        px, py, pz = X.copy(), Y.copy(), Z.copy()
        h = (t - tprev) / substeps
        tc = t
        for _ in range(substeps):
            u1 = vel(px, py, pz, tc)
            mx, my, mz = px - 0.5 * h * u1[0], py - 0.5 * h * u1[1], pz - 0.5 * h * u1[2]
            u2 = vel(mx, my, mz, tc - 0.5 * h)
            px, py, pz = px - h * u2[0], py - h * u2[1], pz - h * u2[2]
            tc -= h
        if prev is None:
            cur = np.stack([px, py, pz]).astype(F32)
        else:
            cur = np.stack(grid_interp(prev, G, px, py, pz)).astype(F32)
        maps.append(cur)
        prev, tprev = cur, t
    return maps


def interp_matrix(S, G, flip):
    """(S, G) linear interpolation weights from a cell-centred G grid over [-0.5, 0.5] to S output pixels
    (flip: output index 0 = coordinate +0.5, i.e. image rows run top to bottom)."""
    c = (np.arange(S) + 0.5) / S - 0.5
    if flip:
        c = -c
    q = np.clip((c + 0.5) * G - 0.5, 0.0, G - 1.0001)
    i0 = np.floor(q).astype(int)
    f = q - i0
    W = np.zeros((S, G), F32)
    W[np.arange(S), i0] = 1.0 - f
    W[np.arange(S), i0 + 1] += f
    return W


# --------------------------------------------------------------------------------------------------------------------
# the volume renderer: orthographic, camera on +z looking down -z; slices front (z = +zh) to back. Lights: a key light
# from the upper front left (shadow march toward it), a rim light from behind (forward scattering: thin edges glow), a
# soft sky term from above, a little ambient. Beer-Lambert absorption; alpha = 1 - transmittance.
# --------------------------------------------------------------------------------------------------------------------


def shift_zero(a, dy, dx):
    """out[r, c] = a[r + dy, c + dx] (bilinear, zero outside)."""
    H, W = a.shape
    iy, ix = int(math.floor(dy)), int(math.floor(dx))
    fy, fx = dy - iy, dx - ix
    pad = max(abs(iy), abs(ix)) + 2
    p = np.zeros((H + 2 * pad, W + 2 * pad), F32)
    p[pad:pad + H, pad:pad + W] = a

    def win(oy, ox):
        return p[pad + oy:pad + oy + H, pad + ox:pad + ox + W]
    top = win(iy, ix) * (1 - fx) + win(iy, ix + 1) * fx
    bot = win(iy + 1, ix) * (1 - fx) + win(iy + 1, ix + 1) * fx
    return top * (1 - fy) + bot * fy


class Light:
    def __init__(self, key=(-0.45, 0.72, 0.53), rim=(0.35, 0.45, -0.82), k_int=1.0, rim_int=0.9, sky_int=0.35,
                 amb=0.06, sigma_key=1.0, sigma_rim=1.0, sigma_sky=0.35, ms=((1.0, 1.0), (0.45, 0.4), (0.22, 0.16))):
        self.key = np.asarray(key, float) / np.linalg.norm(key)
        self.rim = np.asarray(rim, float) / np.linalg.norm(rim)
        self.k_int, self.rim_int, self.sky_int, self.amb = k_int, rim_int, sky_int, amb
        self.sigma_key, self.sigma_rim, self.sigma_sky = sigma_key, sigma_rim, sigma_sky
        self.ms = ms   # multiple-scattering octaves: (weight, extinction factor)


def render_volume(density_slice, S, NZ, zh, sigma, light, jitter_seed=0):
    """density_slice(i, z) -> (S, S) density for slice i at depth z (cell units, z from +zh down to -zh).
    Returns premultiplied luminance P and alpha A (S, S)."""
    dz = 2.0 * zh / NZ
    rng = np.random.default_rng(jitter_seed)
    zs = [zh - (i + 0.5) * dz for i in range(NZ)]
    D = np.empty((NZ, S, S), F32)
    for i, z in enumerate(zs):
        D[i] = density_slice(i, z)
    # rim light: from behind (light.rim z < 0), so its shadow march runs back to front
    L2 = light.rim
    ds2 = dz / abs(L2[2])
    dy2, dx2 = -L2[1] / abs(L2[2]) * dz * S, L2[0] / abs(L2[2]) * dz * S
    Trim = np.empty((NZ, S, S), np.float16)
    tau = np.zeros((S, S), F32)
    for i in range(NZ - 1, -1, -1):
        tau = shift_zero(tau, dy2, dx2) + D[i] * (0.5 * ds2)
        Trim[i] = np.exp(-sigma * light.sigma_rim * tau)
        tau += D[i] * (0.5 * ds2)
    # key light (front) + view, front to back
    L = light.key
    ds = dz / L[2]
    dy, dx = -L[1] / L[2] * dz * S, L[0] / L[2] * dz * S
    tau = np.zeros((S, S), F32)
    T = np.ones((S, S), F32)
    P = np.zeros((S, S), F32)
    dpx = 1.0 / S
    for i in range(NZ):
        d = D[i]
        tau = shift_zero(tau, dy, dx) + d * (0.5 * ds)
        tk = sigma * light.sigma_key * tau
        key = sum(w * np.exp(-e * tk) for w, e in light.ms)
        tau += d * (0.5 * ds)
        # sky from above: optical depth straight up through a softened copy of this slice
        db = gblur(d, 3.0) if light.sky_int > 0 else None
        up = np.cumsum(db, axis=0) - 0.5 * db
        sky = np.exp(-sigma * light.sigma_sky * up * dpx)
        Lin = light.k_int * key + light.rim_int * Trim[i].astype(F32) + light.sky_int * sky + light.amb
        a = 1.0 - np.exp(-sigma * d * dz)
        P += T * a * Lin
        T *= 1.0 - a
    return P, 1.0 - T
