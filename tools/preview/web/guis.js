// SurfaceGuis, BillboardGuis and Decals -> textured quads.
// SurfaceGui faces (part-local): Front = -Z, Back = +Z, Right = +X, Left = -X, Top = +Y, Bottom = -Y. The GUI canvas is laid
// on the face as you would see it from outside: Front -> canvas right = -X, up = +Y; Back -> right = +X; Right -> right = -Z;
// Left -> right = +Z; Top -> right = -X, up = +Z (the Front face folded back); Bottom -> right = -X, up = -Z.
// SurfaceGuis are single-sided (seen only from outside the face) and clip to the face; they draw with normal alpha blending,
// colour = image * ImageColor3 * (LightInfluence 0: Brightness, 1: the scene light). BillboardGuis face the camera plane, sit at
// host + StudsOffset (camera space: x right, y up, z toward the camera) + StudsOffsetWorldSpace, Size in studs.
import * as THREE from 'three';
import { cfMatrix, cfPos, srgb, NORMAL, enumName } from 'preview/rbx.js';

const FACE = { // [normal, right, up, wIndex, hIndex, depthIndex]
	Front: [[0, 0, -1], [-1, 0, 0], [0, 1, 0], 0, 1, 2], Back: [[0, 0, 1], [1, 0, 0], [0, 1, 0], 0, 1, 2],
	Right: [[1, 0, 0], [0, 0, -1], [0, 1, 0], 2, 1, 0], Left: [[-1, 0, 0], [0, 0, 1], [0, 1, 0], 2, 1, 0],
	Top: [[0, 1, 0], [-1, 0, 0], [0, 0, 1], 0, 2, 1], Bottom: [[0, -1, 0], [-1, 0, 0], [0, 0, -1], 0, 2, 1],
};

const VERT = /* glsl */`
attribute vec2 cuv;
varying vec2 vUv; varying vec2 vCuv;
#ifdef BILLBOARD
uniform vec3 uCenter; uniform vec3 uOffset; uniform vec3 uWorldOffset;
#endif
void main() {
	vUv = uv; vCuv = cuv;
#ifdef BILLBOARD
	vec3 r = vec3(viewMatrix[0][0], viewMatrix[1][0], viewMatrix[2][0]);
	vec3 u = vec3(viewMatrix[0][1], viewMatrix[1][1], viewMatrix[2][1]);
	vec3 b = vec3(viewMatrix[0][2], viewMatrix[1][2], viewMatrix[2][2]);
	vec3 c = uCenter + uWorldOffset + r * uOffset.x + u * uOffset.y + b * uOffset.z;
	vec3 wp = c + r * position.x + u * position.y;
	gl_Position = projectionMatrix * viewMatrix * vec4(wp, 1.0);
#else
	gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
#endif
}`;
// ImageRectOffset / ImageRectSize (uRect: uv origin and size of the cropped rect; z = 0: the whole image) and a UICorner
// (uCorner: radius as a fraction of the image's side; 0.5 = a circle)
const CROP_GLSL = /* glsl */`
uniform vec4 uRect; uniform float uCorner;
vec2 cropUv(vec2 uv) { return uRect.z > 0.0 ? uRect.xy + uv * uRect.zw : uv; }
bool outsideCorner(vec2 uv) {
	if (uCorner <= 0.0) return false;
	vec2 q = abs(uv - 0.5) - (0.5 - uCorner);
	return length(max(q, 0.0)) > uCorner;
}`;
const FRAG = /* glsl */`
uniform sampler2D map; uniform vec3 uColor; uniform float uOpacity; uniform float uClip; uniform float uSolid; uniform float uBoost;
varying vec2 vUv; varying vec2 vCuv;
${CROP_GLSL}
void main() {
	if (uClip > 0.5 && (vCuv.x < 0.0 || vCuv.x > 1.0 || vCuv.y < 0.0 || vCuv.y > 1.0)) discard;
	if (outsideCorner(vUv)) discard;
	vec4 t = uSolid > 0.5 ? vec4(1.0) : texture2D(map, cropUv(vUv));
	float a = t.a * uOpacity;
	if (a < 0.002) discard;
	// uColor = ImageColor3 x (lit: the scene light | unlit: 1); uBoost = the unlit Brightness. Calibrated on the pass-4
	// captures, Brightness lifts the light texels (they bloom) but the dark ink edges of the lightdark textures stay
	// dark: over the clock's black disc they read black in Studio, not grey (as a plain multiply would make them)
	float ts = pow(max(dot(t.rgb, vec3(0.2126, 0.7152, 0.0722)), 0.0), 1.0 / 2.2);
	vec3 c = t.rgb * uColor * mix(1.0, uBoost, smoothstep(0.25, 0.75, ts));
	// Faint light texels count for much less in Studio than in a linear blend (as if GUIs were blended in gamma space):
	// the dial textures' soft glows (Brightness 3-3.4) leave the clock's black disc pure black in the pass-4 captures.
	// Emulated with an equivalent alpha a^2.2 for light texels; dark texels keep their alpha (the galaxy floor's dark
	// disc reads lighter in Studio, not darker, so a full gamma-space blend would overshoot there).
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	a = mix(a, pow(a, 2.2), smoothstep(0.02, 0.25, l));
	gl_FragColor = vec4(c, a);
}`;

// Depth from SurfaceGuis. In Studio the black Void disc of pass 4's clock stays pure black although silver mist particles
// drift behind it, and BillboardGuis that cross a SurfaceGui plane get cut (the "white wedge" on the pass-4 moon): what is
// behind the solid part of a SurfaceGui does not show through. So each SurfaceGui also writes depth where its image is
// nearly opaque (an invisible copy drawn right after it), and particles, beams and billboards drawn later are hidden there.
// (Roblox may cut on the whole quad, which this does not do: see tools/preview/FIDELITY.md.)
const OCC_FRAG = /* glsl */`
uniform sampler2D map; uniform float uOpacity; uniform float uClip; uniform float uSolid;
varying vec2 vUv; varying vec2 vCuv;
${CROP_GLSL}
void main() {
	if (uClip > 0.5 && (vCuv.x < 0.0 || vCuv.x > 1.0 || vCuv.y < 0.0 || vCuv.y > 1.0)) discard;
	if (outsideCorner(vUv)) discard;
	vec4 t = uSolid > 0.5 ? vec4(1.0) : texture2D(map, cropUv(vUv));
	if (t.a * uOpacity < 0.6) discard;
	gl_FragColor = vec4(0.0);
}`;
export const OCCLUDE_ALPHA = 0.6;
function occluderMaterial(src) {
	return new THREE.ShaderMaterial({
		vertexShader: VERT, fragmentShader: OCC_FRAG, transparent: true, depthWrite: true, depthTest: true, colorWrite: false,
		side: THREE.FrontSide, polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: -2,
		uniforms: { map: src.uniforms.map, uOpacity: src.uniforms.uOpacity, uClip: src.uniforms.uClip, uSolid: src.uniforms.uSolid,
			uRect: src.uniforms.uRect, uCorner: src.uniforms.uCorner },
	});
}

function guiMaterial(tex, color, opacity, { billboard = false, clip = true, alwaysOnTop = false, solid = false, depthWrite = false, boost = 1,
	rect = null, corner = 0 } = {}) {
	const m = new THREE.ShaderMaterial({
		vertexShader: VERT, fragmentShader: FRAG, transparent: true, depthWrite, depthTest: !alwaysOnTop,
		side: THREE.FrontSide, defines: billboard ? { BILLBOARD: '' } : {},
		polygonOffset: !billboard, polygonOffsetFactor: -1, polygonOffsetUnits: -2,
		uniforms: {
			map: { value: tex }, uColor: { value: color }, uOpacity: { value: opacity }, uClip: { value: clip ? 1 : 0 }, uBoost: { value: boost },
			uSolid: { value: solid ? 1 : 0 }, uRect: { value: rect || new THREE.Vector4(0, 0, 0, 0) }, uCorner: { value: corner },
			uCenter: { value: new THREE.Vector3() }, uOffset: { value: new THREE.Vector3() }, uWorldOffset: { value: new THREE.Vector3() },
		},
	});
	return m;
}

// one image's rectangle in canvas pixels (UDim2 [sx, ox, sy, oy], AnchorPoint) -> {x, y, w, h} (top-left origin)
function rect(im, cw, ch) {
	const s = im.size || [1, 0, 1, 0], p = im.position || [0, 0, 0, 0], a = im.anchor || [0, 0];
	const w = s[0] * cw + s[1], h = s[2] * ch + s[3];
	return { x: p[0] * cw + p[1] - a[0] * w, y: p[2] * ch + p[3] - a[1] * h, w, h };
}

// quad corners for an image rect, in "canvas studs" (x right, y up, origin at the canvas centre) + uv + canvas uv
function pushQuad(arr, r, cw, ch, W, H, rotDeg) {
	const cx = r.x + r.w / 2, cy = r.y + r.h / 2;
	const toStud = (px, py) => [(px / cw - 0.5) * W, (0.5 - py / ch) * H];
	const ang = THREE.MathUtils.degToRad(rotDeg || 0); // GuiObject.Rotation is clockwise on screen (pixel y points down)
	const ca = Math.cos(ang), sa = Math.sin(ang);
	const corners = [[-1, -1, 0, 0], [1, -1, 1, 0], [1, 1, 1, 1], [-1, 1, 0, 1]]; // (x, y up) + uv
	const out = corners.map(([sx, sy, u, v]) => {
		// corner in pixels relative to the centre (y down in pixels), rotated
		const dx = (sx * r.w) / 2, dy = (-sy * r.h) / 2;
		const px = cx + dx * ca - dy * sa, py = cy + dx * sa + dy * ca;
		const [x, y] = toStud(px, py);
		return { x, y, u, v, cu: px / cw, cv: py / ch };
	});
	for (const i of [0, 1, 2, 0, 2, 3]) arr.push(out[i]);
}

export function buildGuis(snapshot, ctx) {
	const group = new THREE.Group();
	group.name = 'guis';
	const billboards = [];
	for (const g of snapshot.guis || []) {
		if (g.enabled === false) continue;
		const host = ctx.partById(g.hostId), att = g.hostAttachmentId != null ? ctx.attById(g.hostAttachmentId) : null;
		if (!host && !att) { ctx.warn(`${g.kind} ${g.path}: no host`); continue; }
		const li = g.lightInfluence || 0, bright = g.brightness == null ? 1 : g.brightness;
		const items = [];
		for (const im of g.images || []) {
			if (im.visible === false || !im.image) continue;
			items.push({ kind: 'image', im, z: im.zIndex || 1 });
		}
		for (const tx of g.texts || []) {
			if (tx.visible === false || !tx.text) continue;
			items.push({ kind: 'text', im: tx, z: tx.zIndex || 1 });
		}
		// background frames of the images (BackgroundTransparency < 1)
		for (const im of g.images || []) {
			if (im.visible !== false && im.backgroundTransparency != null && im.backgroundTransparency < 1) items.push({ kind: 'bg', im, z: (im.zIndex || 1) - 0.5 });
		}
		if (!items.length) continue;
		items.sort((a, b) => a.z - b.z);

		if (g.kind === 'SurfaceGui') {
			const face = FACE[enumName(g.face, 'Front')] || FACE.Front;
			const size = host.size;
			const W = size[face[3]], H = size[face[4]], D = size[face[5]] / 2;
			const pps = g.pixelsPerStud || 50;
			const sizing = enumName(g.sizingMode, 'FixedSize');
			const cw = sizing === 'PixelsPerStud' || !g.canvas ? W * pps : g.canvas[0];
			const ch = sizing === 'PixelsPerStud' || !g.canvas ? H * pps : g.canvas[1];
			const n = new THREE.Vector3(...face[0]), rgt = new THREE.Vector3(...face[1]), up = new THREE.Vector3(...face[2]);
			const m = host.matrix;
			const normalW = n.clone().transformDirection(m);
			const lightK = li > 0 ? ctx.lightAt(normalW) : 1;
			const centerLocal = n.clone().multiplyScalar(D + 0.004);
			const center = centerLocal.clone().applyMatrix4(m);
			const mats = [], verts = [];
			for (const it of items) {
				const r = rect(it.im, cw, ch);
				const before = verts.length;
				pushQuad(verts, r, cw, ch, W, H, it.im.rotation);
				mats.push({ it, start: before, count: verts.length - before });
			}
			const pos = [], uv = [], cuv = [];
			for (const v of verts) {
				const lp = centerLocal.clone().addScaledVector(rgt, v.x).addScaledVector(up, v.y).applyMatrix4(m).sub(center);
				pos.push(lp.x, lp.y, lp.z); uv.push(v.u, v.v); cuv.push(v.cu, v.cv);
			}
			const geo = new THREE.BufferGeometry();
			geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
			geo.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
			geo.setAttribute('cuv', new THREE.Float32BufferAttribute(cuv, 2));
			const materials = mats.map(({ it, start, count }, i) => {
				geo.addGroup(start, count, i);
				return itemMaterial(it, bright, li, lightK, ctx, { clip: true, alwaysOnTop: !!g.alwaysOnTop, canvasW: cw, canvasH: ch });
			});
			const mesh = new THREE.Mesh(geo, materials);
			mesh.position.copy(center);
			mesh.name = g.path;
			mesh.renderOrder = g.alwaysOnTop ? 50 : 0;
			mesh.frustumCulled = false;
			group.add(mesh);
			if (!g.alwaysOnTop && ctx.guiDepth !== false) { // same sort position, created after -> drawn right after the GUI
				const occ = new THREE.Mesh(geo, materials.map((mt) => (mt.uniforms && mt.uniforms.map ? occluderMaterial(mt) : new THREE.MeshBasicMaterial({ visible: false }))));
				occ.position.copy(center);
				occ.name = g.path + ' (depth)';
				occ.renderOrder = mesh.renderOrder;
				occ.frustumCulled = false;
				group.add(occ);
			}
		} else {
			// BillboardGui
			const sz = g.sizeStuds || [4, 4];
			if (g.sizeOffsetPx && (g.sizeOffsetPx[0] || g.sizeOffsetPx[1])) ctx.warn(`BillboardGui ${g.path}: pixel size offsets (${g.sizeOffsetPx}) are ignored (they stay constant on screen in Roblox)`, 'bbpx');
			if (!g.sizeStuds) ctx.warn(`BillboardGui ${g.path}: no stud size (pixel-sized billboards are drawn 4 studs wide)`);
			const W = Math.max(sz[0], 1e-3), H = Math.max(sz[1], 1e-3);
			const cw = W * 50, ch = H * 50; // pixel offsets inside a billboard: ~50 px per stud
			const verts = [], mats = [];
			for (const it of items) {
				const r = rect(it.im, cw, ch);
				const before = verts.length;
				pushQuad(verts, r, cw, ch, W, H, it.im.rotation);
				mats.push({ it, start: before, count: verts.length - before });
			}
			const geo = new THREE.BufferGeometry();
			geo.setAttribute('position', new THREE.Float32BufferAttribute(verts.flatMap((v) => [v.x, v.y, 0]), 3));
			geo.setAttribute('uv', new THREE.Float32BufferAttribute(verts.flatMap((v) => [v.u, v.v]), 2));
			geo.setAttribute('cuv', new THREE.Float32BufferAttribute(verts.flatMap((v) => [v.cu, v.cv]), 2));
			const centerW = att ? cfPos(att.worldCf) : new THREE.Vector3().setFromMatrixPosition(host.matrix);
			const lightK = li > 0 ? ctx.lightAt(null) : 1;
			const materials = mats.map(({ it, start, count }, i) => {
				geo.addGroup(start, count, i);
				const mat = itemMaterial(it, bright, li, lightK, ctx, { billboard: true, clip: false, alwaysOnTop: !!g.alwaysOnTop, canvasW: cw, canvasH: ch });
				mat.uniforms.uCenter.value.copy(centerW);
				mat.uniforms.uOffset.value.set(...(g.studsOffset || [0, 0, 0]));
				mat.uniforms.uWorldOffset.value.set(...(g.studsOffsetWorldSpace || [0, 0, 0]));
				return mat;
			});
			const mesh = new THREE.Mesh(geo, materials);
			mesh.frustumCulled = false;
			mesh.name = g.path;
			mesh.renderOrder = g.alwaysOnTop ? 60 : 0;
			const off = new THREE.Vector3(...(g.studsOffset || [0, 0, 0])), woff = new THREE.Vector3(...(g.studsOffsetWorldSpace || [0, 0, 0]));
			const maxD = g.maxDistance == null ? Infinity : g.maxDistance;
			// per view: the sorting position (with the camera-space offset) and MaxDistance
			billboards.push((camera) => {
				const q = camera.quaternion;
				const p = centerW.clone().add(woff).add(off.clone().applyQuaternion(q));
				mesh.position.copy(p);
				mesh.updateMatrixWorld();
				mesh.visible = camera.position.distanceTo(centerW) <= maxD;
			});
			group.add(mesh);
		}
	}
	// decals on parts (Decal / Texture): a lit image over the whole face
	for (const rec of ctx.parts()) {
		for (const d of rec.p.decals || []) {
			if (!d.texture) continue;
			const face = FACE[enumName(d.face, 'Front')] || FACE.Front;
			const size = rec.size, W = size[face[3]], H = size[face[4]], D = size[face[5]] / 2;
			const n = new THREE.Vector3(...face[0]), rgt = new THREE.Vector3(...face[1]), up = new THREE.Vector3(...face[2]);
			const c0 = n.clone().multiplyScalar(D + 0.003);
			const center = c0.clone().applyMatrix4(rec.matrix);
			const pos = [];
			for (const [x, y] of [[-1, -1], [1, -1], [1, 1], [-1, -1], [1, 1], [-1, 1]]) {
				const p = c0.clone().addScaledVector(rgt, (x * W) / 2).addScaledVector(up, (y * H) / 2).applyMatrix4(rec.matrix).sub(center);
				pos.push(p.x, p.y, p.z);
			}
			const geo = new THREE.BufferGeometry();
			geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
			geo.setAttribute('uv', new THREE.Float32BufferAttribute([0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1], 2));
			geo.setAttribute('cuv', new THREE.Float32BufferAttribute([0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1].map((v) => v * 0.5 + 0.25), 2));
			const col = srgb(d.color || [255, 255, 255]).multiplyScalar(ctx.lightAt(n.clone().transformDirection(rec.matrix)));
			const mesh = new THREE.Mesh(geo, guiMaterial(ctx.tex(d.texture, 'clamp'), col, 1 - (d.transparency || 0), { clip: false }));
			mesh.position.copy(center);
			group.add(mesh);
		}
	}
	return { group, update: (camera) => billboards.forEach((f) => f(camera)) };
}

function itemMaterial(it, bright, li, lightK, ctx, opts) {
	const im = it.im;
	// lit part (LightInfluence): the scene light on every texel; unlit part: Brightness, applied to the light texels only
	// (see the fragment shader). Solid frames and text keep the plain multiply.
	const lit = lightK * li, unlit = 1 - li;
	if (it.kind === 'bg') {
		return guiMaterial(null, srgb(im.backgroundColor || [255, 255, 255]).multiplyScalar(bright * unlit + lit), 1 - im.backgroundTransparency, { ...opts, solid: true });
	}
	if (it.kind === 'text') {
		return guiMaterial(textTexture(im.text), srgb(im.color || [255, 255, 255]).multiplyScalar(bright * unlit + lit), 1 - (im.transparency || 0), opts);
	}
	// k(texel) = lit + unlit * (1 .. Brightness): written as uColor = colour x (lit + unlit), uBoost scaling the unlit share
	const base = lit + unlit;
	const boost = base > 0 ? (lit + unlit * bright) / base : 1;
	const tex = ctx.tex(im.image, 'clamp');
	// ImageRectOffset / ImageRectSize in image pixels (top-left origin; the textures load with flipY, v up)
	let crop = null;
	const rs = im.rectSize, ro = im.rectOffset || [0, 0];
	const iw = tex && tex.image && tex.image.width, ih = tex && tex.image && tex.image.height;
	if (rs && rs[0] > 0 && rs[1] > 0 && iw && ih) crop = new THREE.Vector4(ro[0] / iw, 1 - (ro[1] + rs[1]) / ih, rs[0] / iw, rs[1] / ih);
	// UICorner: CornerRadius scale is relative to the image's shorter side (0.5 and up: round)
	let corner = 0;
	if (im.corner) {
		const r = rect(im, opts.canvasW || 100, opts.canvasH || 100);
		const side = Math.max(Math.min(r.w, r.h), 1e-6);
		corner = Math.min(0.5, im.corner[0] + (im.corner[1] || 0) / side);
	}
	return guiMaterial(tex, srgb(im.color || [255, 255, 255]).multiplyScalar(base), 1 - (im.transparency || 0), { ...opts, boost, rect: crop, corner });
}

// TextLabels: drawn TextScaled-style in a bold sans (the snapshot carries no font), white, tinted by TextColor3
const TEXT = new Map();
function textTexture(text) {
	if (TEXT.has(text)) return TEXT.get(text);
	const cv = document.createElement('canvas');
	cv.width = 512; cv.height = 256;
	const g = cv.getContext('2d');
	let fs = 220;
	g.font = `bold ${fs}px "Liberation Sans", Arial, sans-serif`;
	while (fs > 10 && g.measureText(text).width > 480) { fs -= 6; g.font = `bold ${fs}px "Liberation Sans", Arial, sans-serif`; }
	g.fillStyle = '#fff'; g.textAlign = 'center'; g.textBaseline = 'middle';
	g.fillText(text, 256, 132);
	const t = new THREE.CanvasTexture(cv);
	t.colorSpace = THREE.SRGBColorSpace;
	TEXT.set(text, t);
	return t;
}
