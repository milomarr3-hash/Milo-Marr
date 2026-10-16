// ParticleEmitters, re-simulated statistically for one instant T (= snapshot.t).
// Births sit on a lattice (particle k is born at (k + jitter_k) / Rate) and every particle's random draws come from a hash
// of (emitter path, k), so a render is reproducible and particles keep their identity from frame to frame. A particle is
// alive when T - birth < its lifetime. When the harness recorded the host's history (CFrame + Enabled every 0.1 s), a particle
// is only born while the emitter was enabled and it starts where the host was at its birth (orbiting orbs leave real wakes);
// without history the emitter is assumed to have run forever at its current place (steady state).
// Spawn: from an Attachment = a point; from a part = its Shape (Box / Sphere / Disc / Cylinder), ShapeStyle (Volume /
// Surface), ShapeInOut, ShapePartial (disc: inner radius fraction; cylinder: top radius fraction; sphere: fraction of the
// polar angle from the EmissionDirection pole). Disc and Cylinder are aligned with EmissionDirection (in the host's axes).
// Motion: velocity = EmissionDirection (Sphere / Cylinder: radial) * Speed, spread by SpreadAngle, then Acceleration (world)
// and Drag (speed halves every 1/Drag seconds). LockedToPart particles ride along with the host's current CFrame.
// Size / Transparency (with envelopes) / Color / Squash are sampled at age / lifetime; flipbooks pick their frame by mode.
// Drawn as instanced camera-facing quads (FacingCamera, FacingCameraWorldUp, VelocityParallel, VelocityPerpendicular),
// sorted back to front within each emitter; LightEmission 1 = additive, 0 = normal blending.
import * as THREE from 'three';
import { cfPos, srgb, numSeq, numSeqR, colSeq, range, hashStr, hash2, rng, enumName, NORMAL } from 'preview/rbx.js';

const VERT = /* glsl */`
attribute vec3 iPos; attribute vec3 iVel; attribute vec2 iSize; attribute float iRot; attribute vec4 iColor; attribute vec4 iUV;
uniform float uMode; uniform float uZOff;
varying vec2 vUv; varying vec4 vColor;
void main() {
	vec3 camRight = vec3(viewMatrix[0][0], viewMatrix[1][0], viewMatrix[2][0]);
	vec3 camUp = vec3(viewMatrix[0][1], viewMatrix[1][1], viewMatrix[2][1]);
	vec3 c = iPos;
	vec3 toCam = cameraPosition - c; float dist = max(length(toCam), 1e-4); toCam /= dist;
	vec2 sz = iSize;
	if (uZOff != 0.0) { float nd = max(dist - uZOff, 0.05); c = cameraPosition - toCam * nd; sz *= nd / dist; }
	vec3 R = camRight, U = camUp;
	vec3 v = length(iVel) > 1e-5 ? normalize(iVel) : vec3(0.0, 1.0, 0.0);
	if (uMode > 0.5 && uMode < 1.5) { U = vec3(0.0, 1.0, 0.0); vec3 r = cross(U, toCam); R = length(r) > 1e-4 ? normalize(r) : camRight; }
	else if (uMode > 1.5 && uMode < 2.5) { U = v; vec3 r = cross(U, toCam); R = length(r) > 1e-4 ? normalize(r) : camRight; }
	else if (uMode > 2.5) { vec3 a = abs(v.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0); R = normalize(cross(a, v)); U = cross(v, R); }
	float cr = cos(iRot), sr = sin(iRot);
	vec2 q = position.xy * sz;
	vec2 rq = vec2(q.x * cr + q.y * sr, -q.x * sr + q.y * cr);
	vec3 wp = c + R * rq.x + U * rq.y;
	vUv = iUV.xy + uv * iUV.zw;
	vColor = iColor;
	gl_Position = projectionMatrix * viewMatrix * vec4(wp, 1.0);
}`;
const FRAG = /* glsl */`
uniform sampler2D map; uniform float uLE;
varying vec2 vUv; varying vec4 vColor;
void main() {
	vec4 t = texture2D(map, vUv);
	float a = t.a * vColor.a;
	if (a < 0.002) discard;
	gl_FragColor = vec4(t.rgb * vColor.rgb * a, a * (1.0 - uLE));
}`;

const ORIENT = { FacingCamera: 0, FacingCameraWorldUp: 1, VelocityParallel: 2, VelocityPerpendicular: 3 };
const GRID = { Grid2x2: 2, Grid4x4: 4, Grid8x8: 8 };
const AXIS_INDEX = (v) => (v[0] ? 0 : v[1] ? 1 : 2);

// host CFrame (12 numbers) and Enabled at time tau, from the history [[t, px, py, pz, r00..r22, enabled01], ...]
function historyLookup(hist) {
	const n = hist.length;
	const at = (tau) => {
		if (tau <= hist[0][0]) return 0;
		if (tau >= hist[n - 1][0]) return n - 1;
		let lo = 0, hi = n - 1;
		while (hi - lo > 1) { const m = (lo + hi) >> 1; if (hist[m][0] <= tau) lo = m; else hi = m; }
		return lo;
	};
	return {
		start: hist[0][0],
		enabled: (tau) => tau >= hist[0][0] - 0.05 && hist[at(tau)][13] > 0.5,
		cf: (tau) => {
			const i = at(tau), a = hist[i], b = hist[Math.min(i + 1, n - 1)];
			const u = b[0] > a[0] ? Math.min(Math.max((tau - a[0]) / (b[0] - a[0]), 0), 1) : 0;
			const out = new Array(12);
			for (let k = 0; k < 12; k++) out[k] = a[1 + k] + (b[1 + k] - a[1 + k]) * u;
			return out;
		},
	};
}

const rot3 = (cf, v) => [cf[3] * v[0] + cf[4] * v[1] + cf[5] * v[2], cf[6] * v[0] + cf[7] * v[1] + cf[8] * v[2], cf[9] * v[0] + cf[10] * v[1] + cf[11] * v[2]];
const rot3T = (cf, v) => [cf[3] * v[0] + cf[6] * v[1] + cf[9] * v[2], cf[4] * v[0] + cf[7] * v[1] + cf[10] * v[2], cf[5] * v[0] + cf[8] * v[1] + cf[11] * v[2]];
const xform = (cf, v) => { const r = rot3(cf, v); return [r[0] + cf[0], r[1] + cf[1], r[2] + cf[2]]; };
const norm = (v) => { const l = Math.hypot(v[0], v[1], v[2]) || 1; return [v[0] / l, v[1] / l, v[2] / l]; };
const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
function rotateAbout(v, axis, ang) { // Rodrigues
	const c = Math.cos(ang), s = Math.sin(ang), d = axis[0] * v[0] + axis[1] * v[1] + axis[2] * v[2], k = cross(axis, v);
	return [v[0] * c + k[0] * s + axis[0] * d * (1 - c), v[1] * c + k[1] * s + axis[1] * d * (1 - c), v[2] * c + k[2] * s + axis[2] * d * (1 - c)];
}
function perp(d) {
	const a = Math.abs(d[1]) < 0.9 ? [0, 1, 0] : [1, 0, 0];
	const b = norm(cross(a, d));
	return [b, cross(d, b)];
}
// position and velocity after t seconds with constant acceleration a and drag (speed halves every 1/drag s)
function motion(p0, v0, a, drag, t) {
	if (drag > 1e-6) {
		const k = drag * Math.LN2, e = Math.exp(-k * t);
		const p = [0, 1, 2].map((i) => p0[i] + (a[i] / k) * t + (v0[i] - a[i] / k) * (1 - e) / k);
		const v = [0, 1, 2].map((i) => a[i] / k + (v0[i] - a[i] / k) * e);
		return [p, v];
	}
	return [[0, 1, 2].map((i) => p0[i] + v0[i] * t + 0.5 * a[i] * t * t), [0, 1, 2].map((i) => v0[i] + a[i] * t)];
}

// spawn point (host-local) and the outward direction for one particle
function spawn(e, size, rnd, isPoint) {
	const axis = NORMAL[enumName(e.emissionDirection, 'Top')] || NORMAL.Top;
	if (isPoint) return [[0, 0, 0], axis];
	const shape = enumName(e.shape, 'Box'), style = enumName(e.shapeStyle, 'Volume'), inout = enumName(e.shapeInOut, 'Outward');
	const partial = e.shapePartial == null ? 1 : Math.min(Math.max(e.shapePartial, 0), 1);
	const ai = AXIS_INDEX(axis), others = [0, 1, 2].filter((i) => i !== ai);
	const unitv = (i) => [i === 0 ? 1 : 0, i === 1 ? 1 : 0, i === 2 ? 1 : 0];
	const B = unitv(others[0]), Cc = unitv(others[1]);
	const hb = size[others[0]] / 2, hc = size[others[1]] / 2, ha = size[ai] / 2;
	let p, out;
	if (shape === 'Sphere') {
		const tmax = partial * Math.PI, ct = 1 - rnd() * (1 - Math.cos(tmax)), st = Math.sqrt(Math.max(0, 1 - ct * ct)), ph = rnd() * Math.PI * 2;
		const d = [0, 1, 2].map((i) => axis[i] * ct + (B[i] * Math.cos(ph) + Cc[i] * Math.sin(ph)) * st);
		const r = style === 'Surface' ? 1 : Math.cbrt(rnd());
		p = [d[0] * r * size[0] / 2, d[1] * r * size[1] / 2, d[2] * r * size[2] / 2];
		out = d;
	} else if (shape === 'Disc') {
		const r = style === 'Surface' ? 1 : Math.sqrt(partial * partial + rnd() * (1 - partial * partial));
		const ph = rnd() * Math.PI * 2;
		p = [0, 1, 2].map((i) => B[i] * r * Math.cos(ph) * hb + Cc[i] * r * Math.sin(ph) * hc);
		out = axis;
	} else if (shape === 'Cylinder') {
		const u = rnd(), h = (u - 0.5) * 2 * ha, rs = 1 + (partial - 1) * u;
		const r = (style === 'Surface' ? 1 : Math.sqrt(rnd())) * rs, ph = rnd() * Math.PI * 2;
		p = [0, 1, 2].map((i) => axis[i] * h + B[i] * r * Math.cos(ph) * hb + Cc[i] * r * Math.sin(ph) * hc);
		out = norm([0, 1, 2].map((i) => B[i] * Math.cos(ph) + Cc[i] * Math.sin(ph)));
	} else { // Box
		if (style === 'Surface') {
			const areas = [size[1] * size[2], size[0] * size[2], size[0] * size[1]];
			let pick = rnd() * (areas[0] + areas[1] + areas[2]), f = 0;
			while (f < 2 && pick > areas[f]) { pick -= areas[f]; f++; }
			p = [0, 1, 2].map((i) => (rnd() - 0.5) * size[i]);
			p[f] = (rnd() < 0.5 ? -0.5 : 0.5) * size[f];
		} else p = [0, 1, 2].map((i) => (rnd() - 0.5) * size[i]);
		out = axis;
	}
	const sign = inout === 'Inward' ? -1 : inout === 'InAndOut' ? (rnd() < 0.5 ? -1 : 1) : 1;
	return [p, out.map((x) => x * sign)];
}

export function buildEmitters(snapshot, ctx, opts = {}) {
	const group = new THREE.Group();
	group.name = 'particles';
	const T = snapshot.t || 0;
	const maxPer = opts.maxPerEmitter || 6000;
	const meshes = [];
	let total = 0;
	for (const e of snapshot.emitters || []) {
		const hist = e.hostHistory && e.hostHistory.length ? historyLookup(e.hostHistory) : null;
		if (!e.enabled && !hist && !(e.bursts && e.bursts.length)) continue;
		const isPoint = e.hostAttachmentId != null;
		let curCf = null, size = e.hostSize || [1, 1, 1];
		if (isPoint) { const a = ctx.attById(e.hostAttachmentId); if (a) curCf = a.worldCf; }
		else { const h = ctx.partById(e.hostId); if (h) { curCf = h.p.cf; size = e.hostSize || h.size; } }
		if (!curCf && hist) curCf = hist.cf(T);
		if (!curCf) { ctx.warn(`ParticleEmitter ${e.path}: no host`); continue; }
		const ts = e.timeScale == null ? 1 : e.timeScale;
		const [la, lb] = range(e.lifetime, 1), [sa, sb] = range(e.speed, 0), [ra, rb] = range(e.rotation, 0), [rsa, rsb] = range(e.rotSpeed, 0);
		const spread = e.spreadAngle || [0, 0];
		const acc = e.acceleration || [0, 0, 0], drag = e.drag || 0;
		const locked = !!e.lockedToPart;
		const n = GRID[enumName(e.flipbookLayout, 'None')] || 1, frames = n * n;
		const fbMode = enumName(e.flipbookMode, 'Loop');
		const [fra, frb] = range(e.flipbookFramerate, 1);
		const li = e.lightInfluence || 0;
		const lightK = li > 0 ? ctx.lightAt(null) : 1;
		const kBright = (e.brightness == null ? 1 : e.brightness) * (1 - li) + lightK * li;
		const seed = hashStr(e.path || String(meshes.length));
		const rate = (e.rate || 0) * ts, Lmax = Math.max(la, lb) / Math.max(ts, 1e-4);
		// births to consider: the lattice in [T - Lmax, T], plus bursts
		const births = [];
		if (rate > 0) {
			const k0 = Math.floor((T - Lmax) * rate) - 1, k1 = Math.floor(T * rate);
			const count = k1 - k0 + 1;
			const alive = count * ((la + lb) / 2) / Math.max(la, lb, 1e-4); // expected live particles
			const step = Math.max(1, Math.ceil(alive / maxPer));
			if (step > 1) ctx.warn(`ParticleEmitter ${e.path}: ~${Math.round(alive)} live particles, drawing 1 in ${step}`, 'thin:' + e.path);
			for (let k = k0; k <= k1; k++) {
				if (step > 1 && ((k % step) + step) % step !== 0) continue;
				births.push([k, null]);
			}
		}
		for (const [bt, cnt] of e.bursts || []) for (let i = 0; i < cnt; i++) births.push([1e7 + Math.round(bt * 1000) * 1000 + i, bt]);

		const P = [], V = [], S = [], RO = [], CO = [], UV = [];
		const halfFrames = 2 * (frames - 1);
		for (const [k, burstT] of births) {
			const rnd = rng(hash2(seed, k >>> 0));
			const tau = burstT != null ? burstT : (k + rnd()) / rate;
			if (tau > T) continue;
			if (hist ? !hist.enabled(tau) : (!e.enabled && burstT == null)) continue;
			const L = la + (lb - la) * rnd();
			const age = (T - tau) * ts;
			if (age >= L || age < 0) continue;
			const f = L > 0 ? age / L : 0;
			const cfB = hist ? hist.cf(tau) : curCf;
			let [pLocal, dLocal] = spawn(e, size, rnd, isPoint);
			// spread: random turns about two axes perpendicular to the direction
			const [b1, b2] = perp(norm(dLocal));
			const ax = ((rnd() * 2 - 1) * spread[0] * Math.PI) / 180, ay = ((rnd() * 2 - 1) * spread[1] * Math.PI) / 180;
			dLocal = rotateAbout(rotateAbout(norm(dLocal), b1, ax), b2, ay);
			const speed = sa + (sb - sa) * rnd();
			let pos, vel;
			if (locked) {
				const aLocal = rot3T(curCf, acc);
				const [pl, vl] = motion(pLocal, dLocal.map((x) => x * speed), aLocal, drag, age);
				pos = xform(curCf, pl); vel = rot3(curCf, vl);
			} else {
				const p0 = xform(cfB, pLocal), v0 = rot3(cfB, dLocal).map((x) => x * speed);
				[pos, vel] = motion(p0, v0, acc, drag, age);
			}
			const rS = rnd(), rT = rnd(), rQ = rnd();
			const sz = Math.max(0, numSeqR(e.size, f, rS));
			let sx = sz, sy = sz;
			if (e.squash) {
				const q = numSeqR(e.squash, f, rQ);
				const g = Math.pow(2, Math.max(-3, Math.min(3, q)));
				sx = sz / g; sy = sz * g;
			}
			const alpha = (1 - Math.min(Math.max(numSeqR(e.transparency, f, rT), 0), 1)) * (1 - Math.min(Math.max(e.localTransparencyModifier || 0, 0), 1));
			if (alpha <= 0.002 || sz <= 1e-4) continue;
			const c = srgb(colSeq(e.color, f)).multiplyScalar(kBright);
			const rot = ((ra + (rb - ra) * rnd()) + (rsa + (rsb - rsa) * rnd()) * age) * Math.PI / 180;
			let frame = 0;
			if (frames > 1) {
				const fr = fra + (frb - fra) * rnd(), st = e.flipbookStartRandom ? Math.floor(rnd() * frames) : 0;
				if (fbMode === 'OneShot') frame = Math.min(frames - 1, Math.floor(f * frames));
				else if (fbMode === 'Random') frame = Math.floor(rnd() * frames);
				else if (fbMode === 'PingPong') { const i = Math.floor(st + age * fr) % Math.max(halfFrames, 1); frame = i < frames ? i : halfFrames - i; }
				else frame = Math.floor(st + age * fr) % frames;
			}
			const col = frame % n, row = Math.floor(frame / n);
			P.push(...pos); V.push(...vel); S.push(sx, sy); RO.push(rot); CO.push(c.r, c.g, c.b, alpha);
			UV.push(col / n, 1 - (row + 1) / n, 1 / n, 1 / n);
		}
		const count = RO.length;
		if (!count) continue;
		total += count;
		const geo = new THREE.InstancedBufferGeometry();
		geo.setAttribute('position', new THREE.Float32BufferAttribute([-0.5, -0.5, 0, 0.5, -0.5, 0, 0.5, 0.5, 0, -0.5, 0.5, 0], 3));
		geo.setAttribute('uv', new THREE.Float32BufferAttribute([0, 0, 1, 0, 1, 1, 0, 1], 2));
		geo.setIndex([0, 1, 2, 0, 2, 3]);
		const src = { P: new Float32Array(P), V: new Float32Array(V), S: new Float32Array(S), R: new Float32Array(RO), C: new Float32Array(CO), U: new Float32Array(UV) };
		const dst = { P: new Float32Array(P.length), V: new Float32Array(V.length), S: new Float32Array(S.length), R: new Float32Array(RO.length), C: new Float32Array(CO.length), U: new Float32Array(UV.length) };
		const attrs = {
			P: new THREE.InstancedBufferAttribute(dst.P, 3), V: new THREE.InstancedBufferAttribute(dst.V, 3), S: new THREE.InstancedBufferAttribute(dst.S, 2),
			R: new THREE.InstancedBufferAttribute(dst.R, 1), C: new THREE.InstancedBufferAttribute(dst.C, 4), U: new THREE.InstancedBufferAttribute(dst.U, 4),
		};
		geo.setAttribute('iPos', attrs.P); geo.setAttribute('iVel', attrs.V); geo.setAttribute('iSize', attrs.S);
		geo.setAttribute('iRot', attrs.R); geo.setAttribute('iColor', attrs.C); geo.setAttribute('iUV', attrs.U);
		geo.instanceCount = count;
		const tex = e.texture ? ctx.tex(e.texture, 'clamp') : ctx.tex('', 'clamp');
		const mat = new THREE.ShaderMaterial({
			vertexShader: VERT, fragmentShader: FRAG, transparent: true, depthWrite: false, side: THREE.DoubleSide,
			blending: THREE.CustomBlending, blendSrc: THREE.OneFactor, blendDst: THREE.OneMinusSrcAlphaFactor,
			blendSrcAlpha: THREE.OneFactor, blendDstAlpha: THREE.OneMinusSrcAlphaFactor,
			uniforms: {
				map: { value: tex }, uLE: { value: Math.min(Math.max(e.lightEmission || 0, 0), 1) },
				uMode: { value: ORIENT[enumName(e.orientation, 'FacingCamera')] || 0 }, uZOff: { value: e.zOffset || 0 },
			},
		});
		const mesh = new THREE.Mesh(geo, mat);
		mesh.frustumCulled = false;
		mesh.name = e.path;
		const cen = new THREE.Vector3();
		for (let i = 0; i < count; i++) cen.x += src.P[i * 3] / count, cen.y += src.P[i * 3 + 1] / count, cen.z += src.P[i * 3 + 2] / count;
		mesh.position.copy(cen);
		group.add(mesh);
		const order = new Uint32Array(count).map((_, i) => i);
		const d2 = new Float32Array(count);
		const sort = (cam) => {
			const cx = cam.position.x, cy = cam.position.y, cz = cam.position.z;
			for (let i = 0; i < count; i++) { const dx = src.P[i * 3] - cx, dy = src.P[i * 3 + 1] - cy, dz = src.P[i * 3 + 2] - cz; d2[i] = dx * dx + dy * dy + dz * dz; }
			order.sort((a, b) => d2[b] - d2[a]);
			for (let j = 0; j < count; j++) {
				const i = order[j];
				dst.P.set(src.P.subarray(i * 3, i * 3 + 3), j * 3); dst.V.set(src.V.subarray(i * 3, i * 3 + 3), j * 3);
				dst.S.set(src.S.subarray(i * 2, i * 2 + 2), j * 2); dst.R[j] = src.R[i];
				dst.C.set(src.C.subarray(i * 4, i * 4 + 4), j * 4); dst.U.set(src.U.subarray(i * 4, i * 4 + 4), j * 4);
			}
			for (const a of Object.values(attrs)) a.needsUpdate = true;
		};
		meshes.push(sort);
	}
	return { group, total, update: (camera) => meshes.forEach((f) => f(camera)) };
}
