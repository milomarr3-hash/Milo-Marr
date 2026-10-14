// The world around the aura, approximating Milo's place from the real Studio captures: a tropical island plaza at y = 0
// (light green grass, sand plaza and paths, palm trees, torch posts), a bright cyan-blue sky with soft cumulus by day, a
// black sky with dark grey clouds and stars by night. Lighting is Roblox-like: a sun (or moon) key light from ClockTime,
// sky ambient (image based, from the same sky), an OutdoorAmbient-style fill, soft shadows, light fog far away.
import * as THREE from 'three';
import { srgb, smooth, rng, clamp } from 'preview/rbx.js';

const C = (r, g, b) => srgb([r, g, b]);

// palette by time of day (sRGB 0..255, sampled from the captures)
const DAY = {
	// measured in the day captures (032409, 032102, 032240): blue sky median (117, 189, 204), p25 (96, 182, 201), p75
	// (145, 194, 207); cloud tops ~(200, 205, 202) (Roblox's clouds are a soft grey-white, not paper white)
	zenith: C(88, 176, 200), mid: C(117, 189, 204), horizon: C(160, 202, 210), below: C(150, 170, 178),
	cloudLit: C(214, 218, 215), cloudShade: C(150, 164, 176), cover: 0.6, stars: 0,
	fog: C(178, 212, 226), fogNear: 320, fogFar: 2600,
};
const DUSK = {
	zenith: C(40, 64, 120), mid: C(150, 120, 140), horizon: C(240, 160, 110), below: C(90, 80, 90),
	cloudLit: C(250, 190, 160), cloudShade: C(90, 80, 100), cover: 0.55, stars: 0.2,
	fog: C(170, 130, 120), fogNear: 260, fogFar: 2000,
};
const NIGHT = {
	// measured in the night captures (032418, 032041): black between the clouds, cloud bodies ~(117, 117, 108), the
	// brightest cloud edges ~(155-210); the place's night clouds are the day layer, lit grey
	zenith: C(3, 4, 7), mid: C(6, 7, 11), horizon: C(18, 19, 24), below: C(14, 15, 18),
	cloudLit: C(150, 149, 144), cloudShade: C(44, 44, 46), cover: 0.6, stars: 1,
	fog: C(10, 11, 14), fogNear: 180, fogFar: 1300,
};

// The renderer's tone curve (preview.js TONE). Sky and fog colours above are what Studio DISPLAYS, so they are pushed
// through the inverse curve before rendering ("filmic" = the Narkowicz ACES fit; "neutral" is linear below ~0.76).
function invFilmic(y) {
	y = Math.min(Math.max(y, 0), 0.995);
	const a = 2.51 - 2.43 * y, b = 0.03 - 0.59 * y, c = -0.14 * y;
	return (-b + Math.sqrt(b * b - 4 * a * c)) / (2 * a);
}
function displayed(col, tone) {
	if (tone !== 'filmic') return col.clone();
	return new THREE.Color(invFilmic(col.r), invFilmic(col.g), invFilmic(col.b));
}

// Lighting per tone curve, calibrated against the real Studio captures of pass 4 (tools/preview/FIDELITY.md):
// day grass ~(160, 220, 96), sand ~(243, 227, 185); night (no aura light) grass ~(98, 158, 41), lit sand ~(225, 199, 147)
const LIGHTS = {
	filmic: {
		sunDay: 3.4, hemiDay: 1.0, hemiDaySky: C(230, 234, 240), hemiDayGround: C(176, 168, 140), envDay: 0.45,
		moon: 1.3, moonColor: C(226, 226, 222), hemiNight: 1.4, hemiNightSky: C(208, 206, 198), hemiNightGround: C(96, 92, 80), envNight: 0.5,
		nightDesat: 0.08, light: [0.45, 1],
	},
	neutral: {
		sunDay: 2.35, hemiDay: 0.8, hemiDaySky: C(228, 236, 250), hemiDayGround: C(176, 170, 146), envDay: 0.5,
		moon: 0.5, moonColor: C(176, 190, 228), hemiNight: 1.15, hemiNightSky: C(150, 160, 188), hemiNightGround: C(58, 62, 60), envNight: 0.8,
		nightDesat: 0.32, light: [0.32, 1],
	},
};
// Roblox-like sun path: rises at +X at 6:00, highest at 12:00 (tilted 23.5 deg toward +Z), sets at -X at 18:00.
// (Approximate: the real direction depends on Lighting.GeographicLatitude, which the snapshot does not carry.)
export function sunDirection(clockTime) {
	const a = ((clockTime - 6) / 12) * Math.PI, tilt = THREE.MathUtils.degToRad(23.5);
	return new THREE.Vector3(Math.cos(a), Math.sin(a) * Math.cos(tilt), Math.sin(a) * Math.sin(tilt)).normalize();
}

// 0 = night, 1 = day, with dawn/dusk in between
export function dayFactor(clockTime) {
	const ct = ((clockTime % 24) + 24) % 24;
	return smooth(5.7, 7.0, ct) * (1 - smooth(17.3, 18.6, ct));
}

function lerpPalette(day, dusk) {
	// day 0..1 and "dusk" weight (near the transitions) -> one palette
	const out = {};
	for (const k of Object.keys(DAY)) {
		const a = NIGHT[k], b = DAY[k], d = DUSK[k];
		if (a instanceof THREE.Color) out[k] = a.clone().lerp(b, day).lerp(d, dusk);
		else out[k] = (a + (b - a) * day) * (1 - dusk) + d * dusk;
	}
	return out;
}

const SKY_VERT = /* glsl */`
varying vec3 vDir;
void main() {
	vec4 wp = modelMatrix * vec4(position, 1.0);
	vDir = wp.xyz - cameraPosition;
	gl_Position = projectionMatrix * viewMatrix * wp;
	gl_Position.z = gl_Position.w; // on the far plane
}`;
const SKY_FRAG = /* glsl */`
uniform vec3 uZenith, uMid, uHorizon, uBelow, uCloudLit, uCloudShade, uSunColor;
uniform vec3 uSun, uMoon;
uniform float uCover, uStars, uSunAmt, uMoonAmt, uClouds;
varying vec3 vDir;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float hash3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float a = 0.5, s = 0.0;
	for (int i = 0; i < 6; i++) { s += a * vnoise(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; }
	return s;
}
void main() {
	vec3 d = normalize(vDir);
	float h = d.y;
	vec3 col;
	if (h >= 0.0) {
		col = mix(uHorizon, uMid, smoothstep(0.0, 0.22, h));
		col = mix(col, uZenith, smoothstep(0.22, 0.95, h));
		float sd = max(dot(d, uSun), 0.0);
		col += uSunColor * uSunAmt * (pow(sd, 900.0) * 30.0 + pow(sd, 48.0) * 0.5 + pow(sd, 6.0) * 0.1);
		float md = max(dot(d, uMoon), 0.0);
		col += vec3(0.75, 0.8, 0.9) * uMoonAmt * (smoothstep(0.99955, 0.9997, md) * 1.6 + pow(md, 60.0) * 0.06);
		// stars
		vec3 sp = floor(d * 420.0);
		float st = step(0.9975, hash3(sp)) * hash3(sp + 7.0);
		col += vec3(st) * uStars * smoothstep(0.05, 0.3, h) * 0.9;
		// cumulus on a plane high above
		if (uClouds > 0.5) {
			// a layer of cumulus: low-frequency billows (domain-warped fbm), crisp tops, grey bellies
			vec2 uv = d.xz / (h + 0.12) * 0.24 + vec2(3.1, 7.4);
			vec2 w = vec2(fbm(uv * 0.45 + 4.0), fbm(uv * 0.45 + 9.0));
			float n = fbm(uv * 0.85 + w * 1.1);
			float t0 = 1.0 - uCover;
			float cov = smoothstep(t0, t0 + 0.07, n);
			float thick = smoothstep(t0, t0 + 0.32, n);
			vec2 sdir = normalize(uSun.xz + vec2(1e-4));
			float n2 = fbm((uv + sdir * 0.07) * 0.85 + w * 1.1);
			float lit = clamp(0.55 + (n - n2) * 7.0, 0.0, 1.0);
			float shade = clamp(thick * 0.85 - lit * 0.35 + 0.15, 0.0, 1.0);
			vec3 cc = mix(uCloudLit, uCloudShade, shade);
			float fade = smoothstep(0.0, 0.1, h);
			col = mix(col, cc, cov * fade * 0.98);
		}
	} else {
		col = mix(uHorizon, uBelow, smoothstep(0.0, -0.25, h));
	}
	gl_FragColor = vec4(col, 1.0);
}`;

function skyMaterial() {
	return new THREE.ShaderMaterial({
		vertexShader: SKY_VERT, fragmentShader: SKY_FRAG, side: THREE.BackSide, depthWrite: false, depthTest: true, fog: false,
		uniforms: {
			uZenith: { value: new THREE.Color() }, uMid: { value: new THREE.Color() }, uHorizon: { value: new THREE.Color() },
			uBelow: { value: new THREE.Color() }, uCloudLit: { value: new THREE.Color() }, uCloudShade: { value: new THREE.Color() },
			uSunColor: { value: new THREE.Color(1, 0.95, 0.85) }, uSun: { value: new THREE.Vector3(0, 1, 0) },
			uMoon: { value: new THREE.Vector3(0, 1, 0) }, uCover: { value: 0.5 }, uStars: { value: 0 }, uSunAmt: { value: 1 },
			uMoonAmt: { value: 0 }, uClouds: { value: 1 },
		},
	});
}

// ------------------------------------------------------------------------------------------------- the ground
const GROUND_SIZE = 512; // studs covered by the painted ground texture (centred on the world origin; 8 px per stud)
function paintGround(day) {
	const N = 4096, cv = document.createElement('canvas');
	cv.width = cv.height = N;
	const g = cv.getContext('2d');
	const px = N / GROUND_SIZE; // pixels per stud
	const P = (x, z) => [N / 2 + x * px, N / 2 + z * px];
	g.fillStyle = 'rgb(146,216,80)';
	g.fillRect(0, 0, N, N);
	// soft mottling in the grass (large scale only, the place's grass is flat and clean)
	const r = rng(91);
	for (let i = 0; i < 900; i++) {
		const [x, y] = [r() * N, r() * N], rad = (8 + r() * 40) * px;
		const gr = g.createRadialGradient(x, y, 0, x, y, rad);
		const c = r() < 0.5 ? 'rgba(170,226,104,0.22)' : 'rgba(118,190,80,0.2)';
		gr.addColorStop(0, c); gr.addColorStop(1, 'rgba(0,0,0,0)');
		g.fillStyle = gr; g.fillRect(x - rad, y - rad, rad * 2, rad * 2);
	}
	// sand: a plaza round the origin and paths leading away (as in the captures)
	g.lineCap = 'round'; g.lineJoin = 'round';
	const sand = 'rgb(246,212,138)', edge = 'rgb(228,190,118)';
	const paths = [[8, 300], [97, 300], [188, 300], [262, 300], [320, 120]];
	for (const [ang, len] of paths) {
		const a = THREE.MathUtils.degToRad(ang), w = 11;
		const [x0, y0] = P(0, 0), [x1, y1] = P(Math.cos(a) * len, Math.sin(a) * len);
		g.strokeStyle = edge; g.lineWidth = (w + 1.6) * px; g.beginPath(); g.moveTo(x0, y0); g.lineTo(x1, y1); g.stroke();
		g.strokeStyle = sand; g.lineWidth = w * px; g.beginPath(); g.moveTo(x0, y0); g.lineTo(x1, y1); g.stroke();
	}
	const [cx, cy] = P(0, 0);
	g.fillStyle = edge; g.beginPath(); g.arc(cx, cy, 31 * px, 0, Math.PI * 2); g.fill();
	g.fillStyle = sand; g.beginPath(); g.arc(cx, cy, 30 * px, 0, Math.PI * 2); g.fill();
	// fine sand grain and grass speckle
	const img = g.getImageData(0, 0, N, N), d = img.data, rr = rng(5);
	for (let i = 0; i < d.length; i += 4) {
		const n = (rr() - 0.5) * 10;
		d[i] = clamp(d[i] + n, 0, 255); d[i + 1] = clamp(d[i + 1] + n, 0, 255); d[i + 2] = clamp(d[i + 2] + n * 0.8, 0, 255);
	}
	g.putImageData(img, 0, 0);
	const tex = new THREE.CanvasTexture(cv);
	tex.colorSpace = THREE.SRGBColorSpace;
	tex.anisotropy = 8;
	tex.generateMipmaps = true;
	tex.minFilter = THREE.LinearMipmapLinearFilter;
	return tex;
}

// ------------------------------------------------------------------------------------------------- props (for scale)
function std(c, rough = 0.8, extra = {}) { return new THREE.MeshStandardMaterial({ color: C(...c), roughness: rough, metalness: 0, ...extra }); }
function palm(rand) {
	const g = new THREE.Group();
	const trunkM = std([196, 150, 98]), ringM = std([168, 124, 80]), leafM = std([86, 176, 72], 0.85), leafM2 = std([70, 150, 62], 0.85);
	const lean = (rand() - 0.5) * 0.5, segs = 7, segH = 3.1;
	let p = new THREE.Vector3(0, 0, 0), dir = new THREE.Vector3(lean, 1, (rand() - 0.5) * 0.4).normalize();
	for (let i = 0; i < segs; i++) {
		const r0 = 1.25 - i * 0.07;
		const geo = new THREE.CylinderGeometry(r0 - 0.07, r0, segH, 10);
		const m = new THREE.Mesh(geo, i % 2 ? ringM : trunkM);
		const mid = p.clone().addScaledVector(dir, segH / 2);
		m.position.copy(mid);
		m.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), dir);
		g.add(m);
		p.addScaledVector(dir, segH * 0.98);
		dir.x += lean * 0.18; dir.normalize();
	}
	const top = p.clone();
	const nut = new THREE.Mesh(new THREE.IcosahedronGeometry(1.4, 0), std([150, 104, 60]));
	nut.position.copy(top).add(new THREE.Vector3(0, -0.6, 0)); g.add(nut);
	const nLeaves = 8;
	for (let i = 0; i < nLeaves; i++) {
		const a = (i / nLeaves) * Math.PI * 2 + rand() * 0.3;
		const leaf = new THREE.Group();
		for (let k = 0; k < 4; k++) { // a drooping frond in 4 pieces
			const len = 3.2, w = 2.6 - k * 0.45;
			const piece = new THREE.Mesh(new THREE.BoxGeometry(w, 0.25, len), k % 2 ? leafM2 : leafM);
			const droop = 0.18 + k * 0.32;
			piece.position.set(0, -Math.sin(droop) * len * k * 0.8, len * (k + 0.5) * 0.92);
			piece.rotation.x = droop;
			leaf.add(piece);
		}
		leaf.position.copy(top);
		leaf.rotation.y = a;
		leaf.rotation.x = -0.25;
		g.add(leaf);
	}
	g.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
	return g;
}
function torch() {
	const g = new THREE.Group();
	const post = new THREE.Mesh(new THREE.CylinderGeometry(0.45, 0.55, 7, 10), std([150, 98, 58]));
	post.position.y = 3.5; g.add(post);
	for (const y of [2, 4.6]) { const band = new THREE.Mesh(new THREE.CylinderGeometry(0.6, 0.6, 0.35, 10), std([230, 200, 120])); band.position.y = y; g.add(band); }
	const cup = new THREE.Mesh(new THREE.CylinderGeometry(0.9, 0.6, 0.8, 10), std([120, 78, 46])); cup.position.y = 7.3; g.add(cup);
	const flame = new THREE.Mesh(new THREE.OctahedronGeometry(0.75, 0), new THREE.MeshBasicMaterial({ color: C(255, 214, 40).multiplyScalar(2.2) }));
	flame.position.y = 8.3; flame.scale.set(0.8, 1.3, 0.8); g.add(flame);
	g.traverse((o) => { if (o.isMesh && o !== flame) { o.castShadow = true; o.receiveShadow = true; } });
	return g;
}
function bush(rand) {
	const g = new THREE.Group();
	const m = std([60 + rand() * 30, 150 + rand() * 40, 70 + rand() * 20], 0.9, { flatShading: true });
	for (let i = 0; i < 4; i++) {
		const b = new THREE.Mesh(new THREE.IcosahedronGeometry(1.6 + rand() * 1.6, 0), m);
		b.position.set((rand() - 0.5) * 3.5, 1 + rand() * 0.8, (rand() - 0.5) * 3.5);
		b.castShadow = b.receiveShadow = true;
		g.add(b);
	}
	return g;
}

function buildProps() {
	const g = new THREE.Group(), r = rng(1234);
	const onPath = (x, z) => {
		const a = (Math.atan2(z, x) * 180) / Math.PI;
		return [8, 97, 188, 262, 320].some((p) => Math.abs(((a - p + 540) % 360) - 180) < 9);
	};
	// palms in a loose ring well outside the aura (60-150 studs), torches round the plaza edge further out
	for (let i = 0; i < 22; i++) {
		const a = r() * Math.PI * 2, d = 62 + r() * 95, x = Math.cos(a) * d, z = Math.sin(a) * d;
		if (onPath(x, z)) continue;
		const p = palm(r); p.position.set(x, 0, z); p.rotation.y = r() * 6.28; p.scale.setScalar(0.9 + r() * 0.35); g.add(p);
	}
	for (let i = 0; i < 10; i++) {
		const a = (i / 10) * Math.PI * 2 + 0.2, d = 56, x = Math.cos(a) * d, z = Math.sin(a) * d;
		const t = torch(); t.position.set(x, 0, z); g.add(t);
	}
	for (let i = 0; i < 26; i++) {
		const a = r() * Math.PI * 2, d = 48 + r() * 110, x = Math.cos(a) * d, z = Math.sin(a) * d;
		if (onPath(x, z)) continue;
		const b = bush(r); b.position.set(x, 0, z); g.add(b);
	}
	return g;
}

// ------------------------------------------------------------------------------------------------- the environment
export class Environment {
	constructor(renderer) {
		this.renderer = renderer;
		this.group = new THREE.Group();
		this.group.name = 'environment';
		this.skyMat = skyMaterial();
		this.sky = new THREE.Mesh(new THREE.SphereGeometry(9000, 48, 24), this.skyMat);
		this.sky.frustumCulled = false;
		this.sky.renderOrder = -1000;
		this.sky.onBeforeRender = (r, s, cam) => { this.sky.position.copy(cam.position); this.sky.updateMatrixWorld(); };
		this.group.add(this.sky);

		this.groundTex = paintGround();
		const gm = new THREE.MeshStandardMaterial({ map: this.groundTex, roughness: 0.96, metalness: 0 });
		this.ground = new THREE.Mesh(new THREE.PlaneGeometry(GROUND_SIZE, GROUND_SIZE), gm);
		this.ground.rotation.x = -Math.PI / 2;
		this.ground.receiveShadow = true;
		this.group.add(this.ground);
		this.farGround = new THREE.Mesh(new THREE.CircleGeometry(16000, 64), new THREE.MeshStandardMaterial({ color: C(146, 212, 92), roughness: 1 }));
		this.farGround.rotation.x = -Math.PI / 2;
		this.farGround.position.y = -0.03;
		this.farGround.receiveShadow = false;
		this.group.add(this.farGround);

		this.props = buildProps();
		this.group.add(this.props);

		this.sun = new THREE.DirectionalLight(0xffffff, 1);
		this.sun.castShadow = true;
		this.sun.shadow.mapSize.set(2048, 2048);
		this.sun.shadow.bias = -0.0004;
		this.sun.shadow.normalBias = 0.04;
		this.sun.shadow.radius = 3;
		const sc = this.sun.shadow.camera;
		sc.left = -90; sc.right = 90; sc.top = 90; sc.bottom = -90; sc.near = 1; sc.far = 600;
		this.group.add(this.sun, this.sun.target);
		this.hemi = new THREE.HemisphereLight(0xffffff, 0x808080, 0.5);
		this.group.add(this.hemi);

		// the reflection/ambient environment comes from a sky-only scene (Roblox reflects the skybox, not the world)
		this.envScene = new THREE.Scene();
		this.envSkyMat = skyMaterial();
		this.envSky = new THREE.Mesh(new THREE.SphereGeometry(900, 48, 24), this.envSkyMat);
		this.envScene.add(this.envSky);
		this.pmrem = new THREE.PMREMGenerator(renderer);
		this.envRT = null;
		this.key = null;
	}

	// scenery never hides the aura: props whose bounds cross the camera -> target line (or sit on the camera) are hidden
	clearLineOfSight(from, to) {
		if (!this.props.visible) return;
		const seg = new THREE.Line3(from, to), p = new THREE.Vector3();
		for (const o of this.props.children) {
			if (!o.userData.sphere) {
				const b = new THREE.Box3().setFromObject(o);
				o.userData.sphere = b.getBoundingSphere(new THREE.Sphere());
			}
			const s = o.userData.sphere;
			seg.closestPointToPoint(s.center, true, p);
			o.visible = p.distanceTo(s.center) > s.radius * 0.8 + 1.5;
		}
	}

	// mode: 'day' | 'night' | 'auto'; clockTime 0..24; focus = Vector3 (the wearer) for the shadow camera
	apply({ mode = 'auto', clockTime = 14, focus = new THREE.Vector3(), groundY = 0, props = true }) {
		let ct = clockTime;
		if (mode === 'day' && dayFactor(ct) < 0.99) ct = 14;
		if (mode === 'night' && dayFactor(ct) > 0.01) ct = 0;
		const day = dayFactor(ct);
		const dusk = Math.max(0, 1 - Math.abs(day - 0.5) * 2) * 0.85;
		const pal = lerpPalette(day, dusk);
		const sunDir = sunDirection(ct);
		const moonDir = sunDir.clone().negate();
		if (moonDir.y < 0.25) { moonDir.y = 0.25 + Math.abs(moonDir.y) * 0.5; moonDir.normalize(); }
		this.state = { clockTime: ct, day, dusk, sunDir, moonDir, isDay: day >= 0.5 };

		const tone = this.tone === 'neutral' ? 'neutral' : 'filmic', L = LIGHTS[tone];
		for (const k of ['zenith', 'mid', 'horizon', 'below', 'cloudLit', 'cloudShade', 'fog']) pal[k] = displayed(pal[k], tone);
		for (const m of [this.skyMat, this.envSkyMat]) {
			const u = m.uniforms;
			u.uZenith.value.copy(pal.zenith); u.uMid.value.copy(pal.mid); u.uHorizon.value.copy(pal.horizon); u.uBelow.value.copy(pal.below);
			u.uCloudLit.value.copy(pal.cloudLit); u.uCloudShade.value.copy(pal.cloudShade); u.uCover.value = pal.cover;
			u.uStars.value = pal.stars; u.uSun.value.copy(sunDir); u.uMoon.value.copy(moonDir);
			u.uSunAmt.value = smooth(-0.05, 0.1, sunDir.y) * (0.4 + 0.6 * day); u.uMoonAmt.value = 1 - day;
		}
		this.envSkyMat.uniforms.uStars.value = 0;
		this.envSkyMat.uniforms.uBelow.value.copy(pal.horizon).lerp(pal.below, 0.5);

		// key light: the sun by day, the moon by night (never both)
		const sunUp = smooth(-0.02, 0.18, sunDir.y);
		const key = day >= 0.5 ? sunDir : moonDir;
		const keyInt = day >= 0.5 ? L.sunDay * sunUp : L.moon;
		const keyCol = day >= 0.5 ? C(255, 244, 228).lerp(C(255, 170, 110), dusk) : L.moonColor.clone();
		this.sun.color.copy(keyCol);
		this.sun.intensity = keyInt;
		this.sun.position.copy(focus).addScaledVector(key, 300);
		this.sun.target.position.copy(focus);
		this.sun.target.updateMatrixWorld();
		this.sun.shadow.radius = day >= 0.5 ? 3 : 5;
		// OutdoorAmbient-style fill
		this.hemi.color.copy(day >= 0.5 ? L.hemiDaySky : L.hemiNightSky);
		this.hemi.groundColor.copy(day >= 0.5 ? L.hemiDayGround : L.hemiNightGround);
		this.hemi.intensity = day >= 0.5 ? L.hemiDay : L.hemiNight;
		this.envIntensity = day >= 0.5 ? L.envDay : L.envNight;
		this.nightGrade = (1 - day) * L.nightDesat; // a mild desaturation in post at night (preview.js)
		// overall light level (for LightInfluence on GUIs, beams and particles)
		this.light = L.light[0] + (L.light[1] - L.light[0]) * day;

		this.fog = new THREE.Fog(pal.fog, pal.fogNear, pal.fogFar);
		this.ground.position.y = groundY;
		this.farGround.position.y = groundY - 0.03;
		this.farGround.material.color.copy(C(146, 212, 92));
		this.props.visible = props;
		if (this.props.position.y !== groundY) { this.props.position.y = groundY; this.props.children.forEach((o) => { o.userData.sphere = null; }); }

		// re-bake the environment map only when the sky changed
		const key2 = [mode, ct.toFixed(2), tone].join('|');
		if (key2 !== this.key) {
			this.key = key2;
			if (this.envRT) this.envRT.dispose();
			this.envSkyMat.uniforms.uClouds.value = 1;
			this.envRT = this.pmrem.fromScene(this.envScene, 0.02, 0.1, 2000);
		}
		this.envMap = this.envRT.texture;
		return this.state;
	}
}
