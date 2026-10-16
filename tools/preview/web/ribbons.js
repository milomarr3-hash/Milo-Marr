// Beams and Trails -> ribbons.
// Beam: a cubic Bezier from Attachment0 to Attachment1: P0 = a0, P1 = a0 + a0.X * CurveSize0, P2 = a1 - a1.X * CurveSize1,
// P3 = a1 (Roblox curves beams along each attachment's local X axis). Segments straight pieces; width lerps Width0 -> Width1.
// FaceCamera: the ribbon turns about its own line to face the camera. Otherwise its surface normal follows the attachments'
// Y axes (UpVector), i.e. a beam between two default attachments lies flat, facing up. (Verify in Studio if a build relies
// on non-FaceCamera beams.)
// Texture: U runs along the beam from a0 to a1, V across. Stretch -> the texture repeats TextureLength times over the whole
// beam; Wrap / Static -> one repeat every TextureLength studs. TextureSpeed scrolls it (repeats per second).
// Colour/Transparency sequences are sampled along the beam; Brightness multiplies; LightEmission 1 = additive, 0 = normal
// alpha blending (in between: partly additive); LightInfluence 1 = lit by the scene light.
// Trail: drawn from the harness's attachment history (positions every 0.1 s): each sample is a cross-section from a0 to a1;
// Color/Transparency/WidthScale over the segment's age; Lifetime cuts it off.
import * as THREE from 'three';
import { cfPos, cfAxis, srgb, numSeq, colSeq, enumName } from 'preview/rbx.js';

const VERT = /* glsl */`
attribute vec4 rgba;
varying vec2 vUv; varying vec4 vC;
void main() { vUv = uv; vC = rgba; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`;
const FRAG = /* glsl */`
uniform sampler2D map; uniform float uLE; uniform float uSolid;
varying vec2 vUv; varying vec4 vC;
void main() {
	vec4 t = uSolid > 0.5 ? vec4(1.0) : texture2D(map, vUv);
	float a = t.a * vC.a;
	if (a < 0.001) discard;
	// faint light texels count for less, as for GUIs (guis.js): the soft edges of the pass-4 line textures leave thin
	// lines in the Studio captures, not broad glowing bands
	float l = dot(t.rgb * vC.rgb, vec3(0.2126, 0.7152, 0.0722));
	a = mix(a, pow(a, 2.2), smoothstep(0.02, 0.25, l));
	gl_FragColor = vec4(t.rgb * vC.rgb * a, a * (1.0 - uLE));
}`;
export function ribbonMaterial(tex, lightEmission) {
	return new THREE.ShaderMaterial({
		vertexShader: VERT, fragmentShader: FRAG, transparent: true, depthWrite: false, side: THREE.DoubleSide,
		blending: THREE.CustomBlending, blendSrc: THREE.OneFactor, blendDst: THREE.OneMinusSrcAlphaFactor,
		blendSrcAlpha: THREE.OneFactor, blendDstAlpha: THREE.OneMinusSrcAlphaFactor,
		uniforms: { map: { value: tex }, uLE: { value: Math.min(Math.max(lightEmission || 0, 0), 1) }, uSolid: { value: tex ? 0 : 1 } },
	});
}

function bezier(p0, p1, p2, p3, t, out = new THREE.Vector3()) {
	const u = 1 - t;
	return out.set(0, 0, 0).addScaledVector(p0, u * u * u).addScaledVector(p1, 3 * u * u * t).addScaledVector(p2, 3 * u * t * t).addScaledVector(p3, t * t * t);
}

function writeGeometry(geo, pos, uv, rgba, center) {
	const n = pos.length / 3;
	const P = new Float32Array(pos.length);
	for (let i = 0; i < n; i++) { P[i * 3] = pos[i * 3] - center.x; P[i * 3 + 1] = pos[i * 3 + 1] - center.y; P[i * 3 + 2] = pos[i * 3 + 2] - center.z; }
	geo.setAttribute('position', new THREE.BufferAttribute(P, 3));
	geo.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
	geo.setAttribute('rgba', new THREE.Float32BufferAttribute(rgba, 4));
	const idx = [];
	for (let i = 0; i < n / 2 - 1; i++) { const a = i * 2; idx.push(a, a + 1, a + 2, a + 1, a + 3, a + 2); }
	geo.setIndex(idx);
	geo.computeBoundingSphere();
}

export function buildBeams(snapshot, ctx) {
	const group = new THREE.Group();
	group.name = 'beams';
	const updaters = [];
	for (const b of snapshot.beams || []) {
		if (b.enabled === false) continue;
		const A0 = ctx.attById(b.a0), A1 = ctx.attById(b.a1);
		if (!A0 || !A1) { ctx.warn(`Beam ${b.path}: missing attachment`); continue; }
		const p0 = cfPos(A0.worldCf), p3 = cfPos(A1.worldCf);
		const x0 = cfAxis(A0.worldCf, 0), x1 = cfAxis(A1.worldCf, 0), y0 = cfAxis(A0.worldCf, 1), y1 = cfAxis(A1.worldCf, 1);
		const p1 = p0.clone().addScaledVector(x0, b.curve0 || 0), p2 = p3.clone().addScaledVector(x1, -(b.curve1 || 0));
		const N = Math.max(1, Math.round(b.segments || 10));
		const sub = Math.max(1, Math.ceil(48 / N));
		// sample points: the Bezier at segment ends, straight in between
		const ends = [];
		for (let i = 0; i <= N; i++) ends.push(bezier(p0, p1, p2, p3, i / N));
		const pts = [], ts = [];
		for (let i = 0; i < N; i++) for (let j = 0; j < sub; j++) { pts.push(ends[i].clone().lerp(ends[i + 1], j / sub)); ts.push((i + j / sub) / N); }
		pts.push(ends[N].clone()); ts.push(1);
		const tang = pts.map((p, i) => {
			const a = pts[Math.max(0, i - 1)], c = pts[Math.min(pts.length - 1, i + 1)];
			const d = c.clone().sub(a);
			return d.lengthSq() > 1e-12 ? d.normalize() : x0.clone();
		});
		const arc = [0];
		for (let i = 1; i < pts.length; i++) arc.push(arc[i - 1] + pts[i].distanceTo(pts[i - 1]));
		const total = arc[arc.length - 1] || 1;
		const mode = enumName(b.textureMode, 'Stretch');
		const len = b.textureLength || 1, speed = b.textureSpeed || 0;
		const lightK = (b.lightInfluence || 0) > 0 ? ctx.lightAt(null) : 1;
		const k = (b.brightness == null ? 1 : b.brightness) * (1 - (b.lightInfluence || 0)) + lightK * (b.lightInfluence || 0);
		const uAt = (i) => (mode === 'Stretch' ? ts[i] * len : arc[i] / len) - speed * (snapshot.t || 0);
		const colors = ts.map((t) => {
			const c = srgb(colSeq(b.color, t)).multiplyScalar(k);
			return [c.r, c.g, c.b, (1 - numSeq(b.transparency, t)[0]) * (1 - (b.localTransparencyModifier || 0))];
		});
		const tex = b.texture ? ctx.tex(b.texture, 'repeatU') : null;
		const mat = ribbonMaterial(tex, b.lightEmission);
		const geo = new THREE.BufferGeometry();
		const mesh = new THREE.Mesh(geo, mat);
		mesh.name = b.path;
		mesh.frustumCulled = false;
		const center = bezier(p0, p1, p2, p3, 0.5);
		mesh.position.copy(center);
		group.add(mesh);
		const zoff = b.zOffset || 0;
		let lastCam = null;
		const update = (camera) => {
			const cp = camera.position;
			if (lastCam && lastCam.equals(cp) && b.faceCamera) return;
			lastCam = cp.clone();
			const pos = [], uv = [], rgba = [];
			for (let i = 0; i < pts.length; i++) {
				const t = ts[i], w = (b.width0 + (b.width1 - b.width0) * t) / 2;
				let side;
				if (b.faceCamera) side = new THREE.Vector3().crossVectors(tang[i], cp.clone().sub(pts[i])).normalize();
				else {
					const nrm = y0.clone().lerp(y1, t).normalize();
					side = new THREE.Vector3().crossVectors(tang[i], nrm);
					if (side.lengthSq() < 1e-8) side.crossVectors(tang[i], new THREE.Vector3(0, 0, 1));
					side.normalize();
				}
				const p = pts[i].clone();
				if (zoff) p.addScaledVector(cp.clone().sub(p).normalize(), zoff);
				const a = p.clone().addScaledVector(side, -w), c = p.clone().addScaledVector(side, w);
				pos.push(a.x, a.y, a.z, c.x, c.y, c.z);
				const u = uAt(i);
				uv.push(u, 0, u, 1);
				rgba.push(...colors[i], ...colors[i]);
			}
			writeGeometry(geo, pos, uv, rgba, center);
		};
		updaters.push(update);
	}
	return { group, update: (camera) => updaters.forEach((f) => f(camera)) };
}

export function buildTrails(snapshot, ctx) {
	const group = new THREE.Group();
	group.name = 'trails';
	const updaters = [];
	const T = snapshot.t || 0;
	for (const tr of snapshot.trails || []) {
		if (tr.enabled === false) continue;
		const hist = (tr.history || []).filter((h) => T - h[0] >= 0 && T - h[0] <= (tr.lifetime || 2));
		const A0 = ctx.attById(tr.a0), A1 = ctx.attById(tr.a1);
		const samples = hist.map((h) => ({ age: T - h[0], a: new THREE.Vector3(h[1], h[2], h[3]), b: new THREE.Vector3(h[4], h[5], h[6]) }));
		if (A0 && A1) samples.push({ age: 0, a: cfPos(A0.worldCf), b: cfPos(A1.worldCf) });
		samples.sort((x, y) => x.age - y.age);
		if (samples.length < 2) { ctx.warn(`Trail ${tr.path}: no movement history in the snapshot, not drawn`, 'trail'); continue; }
		const L = tr.lifetime || 2;
		const mode = enumName(tr.textureMode, 'Stretch'), len = tr.textureLength || 1;
		const lightK = (tr.lightInfluence || 0) > 0 ? ctx.lightAt(null) : 1;
		const k = (tr.brightness == null ? 1 : tr.brightness) * (1 - (tr.lightInfluence || 0)) + lightK * (tr.lightInfluence || 0);
		const mat = ribbonMaterial(tr.texture ? ctx.tex(tr.texture, 'repeatU') : null, tr.lightEmission);
		const geo = new THREE.BufferGeometry();
		const mesh = new THREE.Mesh(geo, mat);
		mesh.frustumCulled = false;
		const center = samples[0].a.clone().lerp(samples[0].b, 0.5);
		mesh.position.copy(center);
		group.add(mesh);
		updaters.push((camera) => {
			const pos = [], uv = [], rgba = [];
			let arc = 0;
			for (let i = 0; i < samples.length; i++) {
				const s = samples[i], f = Math.min(1, s.age / L);
				const mid = s.a.clone().lerp(s.b, 0.5);
				const ws = numSeq(tr.widthScale == null ? 1 : tr.widthScale, f)[0];
				let a, b;
				if (tr.faceCamera) {
					const nb = samples[Math.min(samples.length - 1, i + 1)], pb = samples[Math.max(0, i - 1)];
					const dir = nb.a.clone().lerp(nb.b, 0.5).sub(pb.a.clone().lerp(pb.b, 0.5)).normalize();
					const side = new THREE.Vector3().crossVectors(dir, camera.position.clone().sub(mid)).normalize();
					const w = s.a.distanceTo(s.b) * ws / 2;
					a = mid.clone().addScaledVector(side, -w); b = mid.clone().addScaledVector(side, w);
				} else {
					a = mid.clone().lerp(s.a, ws); b = mid.clone().lerp(s.b, ws);
				}
				if (i > 0) arc += mid.distanceTo(samples[i - 1].a.clone().lerp(samples[i - 1].b, 0.5));
				pos.push(a.x, a.y, a.z, b.x, b.y, b.z);
				const u = mode === 'Stretch' ? f * len : arc / len;
				uv.push(u, 0, u, 1);
				const c = srgb(colSeq(tr.color, f)).multiplyScalar(k), al = 1 - numSeq(tr.transparency, f)[0];
				rgba.push(c.r, c.g, c.b, al, c.r, c.g, c.b, al);
			}
			writeGeometry(geo, pos, uv, rgba, center);
		});
	}
	return { group, update: (camera) => updaters.forEach((f) => f(camera)) };
}
