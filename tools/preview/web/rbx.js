// Roblox conventions -> three.js. Both are right-handed with +Y up and the camera looking down -Z, so Roblox world
// coordinates are used as-is (1 three.js unit = 1 stud). A Roblox CFrame arrives as GetComponents():
// [px, py, pz, r00, r01, r02, r10, r11, r12, r20, r21, r22] (rotation row-major; columns = Right, Up, Back).
import * as THREE from 'three';

export function cfMatrix(cf, out = new THREE.Matrix4()) {
	return out.set(
		cf[3], cf[4], cf[5], cf[0],
		cf[6], cf[7], cf[8], cf[1],
		cf[9], cf[10], cf[11], cf[2],
		0, 0, 0, 1);
}
export const cfPos = (cf, out = new THREE.Vector3()) => out.set(cf[0], cf[1], cf[2]);
// column i of the rotation: 0 = RightVector (+X), 1 = UpVector (+Y), 2 = back (+Z, = -LookVector)
export const cfAxis = (cf, i, out = new THREE.Vector3()) => out.set(cf[3 + i], cf[6 + i], cf[9 + i]);
export const cfLook = (cf, out = new THREE.Vector3()) => out.set(-cf[5], -cf[8], -cf[11]);

// local direction of a NormalId (Front = -Z, as Roblox)
export const NORMAL = {
	Right: [1, 0, 0], Left: [-1, 0, 0], Top: [0, 1, 0], Bottom: [0, -1, 0], Back: [0, 0, 1], Front: [0, 0, -1],
};
export const enumName = (v, dflt) => (v == null ? dflt : String(v).split('.').pop());

// Roblox colours are sRGB 0..255 (floats allowed); three.js works in linear sRGB
export function srgb(c, out = new THREE.Color()) {
	if (!c) return out.setRGB(1, 1, 1);
	return out.setRGB(c[0] / 255, c[1] / 255, c[2] / 255, THREE.SRGBColorSpace);
}
export const lin = (v) => (v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4));

// NumberSequence [[t, v, e], ...] (or a plain number) at time t -> [value, envelope]
export function numSeq(seq, t) {
	if (seq == null) return [0, 0];
	if (typeof seq === 'number') return [seq, 0];
	if (!Array.isArray(seq) || seq.length === 0) return [0, 0];
	if (!Array.isArray(seq[0])) return [seq[0], 0];
	if (t <= seq[0][0]) return [seq[0][1], seq[0][2] || 0];
	for (let i = 1; i < seq.length; i++) {
		const b = seq[i];
		if (t <= b[0]) {
			const a = seq[i - 1], u = b[0] > a[0] ? (t - a[0]) / (b[0] - a[0]) : 0;
			return [a[1] + (b[1] - a[1]) * u, (a[2] || 0) + ((b[2] || 0) - (a[2] || 0)) * u];
		}
	}
	const z = seq[seq.length - 1];
	return [z[1], z[2] || 0];
}
// value with a per-particle random r in [0,1) applied to the envelope
export const numSeqR = (seq, t, r) => { const [v, e] = numSeq(seq, t); return v + e * (2 * r - 1); };

// ColorSequence [[t, r, g, b], ...] (or [r, g, b]) at t -> [r, g, b] 0..255 (interpolated in sRGB, as Roblox)
export function colSeq(seq, t) {
	if (seq == null) return [255, 255, 255];
	if (!Array.isArray(seq[0])) return seq;
	if (t <= seq[0][0]) return seq[0].slice(1, 4);
	for (let i = 1; i < seq.length; i++) {
		const b = seq[i];
		if (t <= b[0]) {
			const a = seq[i - 1], u = b[0] > a[0] ? (t - a[0]) / (b[0] - a[0]) : 0;
			return [a[1] + (b[1] - a[1]) * u, a[2] + (b[2] - a[2]) * u, a[3] + (b[3] - a[3]) * u];
		}
	}
	return seq[seq.length - 1].slice(1, 4);
}
export const range = (r, dflt = 0) => (r == null ? [dflt, dflt] : typeof r === 'number' ? [r, r] : [r[0], r.length > 1 ? r[1] : r[0]]);

// deterministic randomness (renders are reproducible and particles keep their identity across frames)
export function hashStr(s) {
	let h = 2166136261 >>> 0;
	for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0; }
	return h >>> 0;
}
export function hash2(a, b) {
	let h = (a ^ Math.imul(b + 0x9e3779b9, 0x85ebca6b)) >>> 0;
	h = Math.imul(h ^ (h >>> 16), 0x7feb352d) >>> 0;
	h = Math.imul(h ^ (h >>> 15), 0x846ca68b) >>> 0;
	return (h ^ (h >>> 16)) >>> 0;
}
export function rng(seed) {
	let s = seed >>> 0;
	return () => {
		s = (s + 0x6d2b79f5) >>> 0;
		let t = s;
		t = Math.imul(t ^ (t >>> 15), t | 1);
		t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
		return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
	};
}

export const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
export const smooth = (a, b, x) => { const t = clamp((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t); };
export const lastName = (path) => (path ? String(path).split('.').pop() : '');
