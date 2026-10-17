#!/usr/bin/env node
// Writes fixture snapshots (SHARED SNAPSHOT CONTRACT + the harness extensions) that exercise every element the preview
// draws, laid out round a wearer at the origin who faces -Z:
//   z = +16  shapes: Block, Ball, Cylinder (axis X), Wedge, CornerWedge, an unknown Mesh (placeholder)
//   z = +26  film-mesh stand-ins: RingG, Dial, Astrolabe, Hand, Gear, Moon (fake ids rbxassetid://7000000000N)
//   z = +6   materials on balls: Plastic, SmoothPlastic, Metal, Neon, Glass, Foil, ForceField, Reflectance, Transparency
//   z = -8   a cube with a labelled SurfaceGui on all six faces; a second one turned 45 deg
//   z = -16  a galaxy SurfaceGui on a floor plate's Top face (Brightness 2.6 -> blooms)
//   beams    an arc (FaceCamera, Wrap arrows), a flat ground beam (no FaceCamera, Stretch arrows), a white->black additive column
//   guis     BillboardGuis: plain, StudsOffset toward/away from the camera, AlwaysOnTop behind a wall
//   emitters Box volume sparkles (flipbook), Sphere surface streaks (VelocityParallel, drag), Disc ring (ShapePartial),
//            Cylinder cone, an Attachment point puffing dark smoke, a LockedToPart mist; a PointLight; a Highlight on a
//            metal model (ink outline); a Trail with history; a ColorCorrection in the "graded" variant.
// Run: node tools/preview/fixtures/make_fixtures.mjs  (writes tools/preview/fixtures/*.json)
import fs from 'node:fs';
import path from 'node:path';

const OUT = path.dirname(new URL(import.meta.url).pathname);

// ---------------------------------------------------------------- tiny CFrame helpers (Roblox component order)
const rx = (a) => [[1, 0, 0], [0, Math.cos(a), -Math.sin(a)], [0, Math.sin(a), Math.cos(a)]];
const ry = (a) => [[Math.cos(a), 0, Math.sin(a)], [0, 1, 0], [-Math.sin(a), 0, Math.cos(a)]];
const rz = (a) => [[Math.cos(a), -Math.sin(a), 0], [Math.sin(a), Math.cos(a), 0], [0, 0, 1]];
const mul = (A, B) => A.map((r, i) => [0, 1, 2].map((j) => r[0] * B[0][j] + r[1] * B[1][j] + r[2] * B[2][j]));
const I = [[1, 0, 0], [0, 1, 0], [0, 0, 1]];
const deg = Math.PI / 180;
// CFrame.new(x, y, z) * CFrame.Angles(ax, ay, az)   (degrees)
function CF(x, y, z, ax = 0, ay = 0, az = 0) {
	const R = mul(mul(rx(ax * deg), ry(ay * deg)), rz(az * deg));
	return [x, y, z, ...R[0], ...R[1], ...R[2]];
}
// CFrame.fromMatrix(pos, right, up)
function fromMatrix(p, X, Y) {
	const Z = [X[1] * Y[2] - X[2] * Y[1], X[2] * Y[0] - X[0] * Y[2], X[0] * Y[1] - X[1] * Y[0]];
	return [p[0], p[1], p[2], X[0], Y[0], Z[0], X[1], Y[1], Z[1], X[2], Y[2], Z[2]];
}
const seq = (...pts) => pts.map((p) => (p.length === 2 ? [p[0], p[1], 0] : p));
const cseq = (...pts) => pts;

// ---------------------------------------------------------------- the scene
function build({ clockTime = 14, graded = false, scenario = 'fixture_all' } = {}) {
	let nextId = 1;
	const parts = [], atts = [], beams = [], guis = [], emitters = [], lights = [], highlights = [], trails = [], effects = [];
	const ROOT = 'Workspace.Fixture';
	function part(name, size, cf, o = {}) {
		const p = {
			id: nextId++, path: `${o.parent || ROOT}.${name}`, class: o.class || 'Part', shape: o.shape || 'Block', size, cf,
			color: o.color || [200, 200, 205], material: o.material || 'SmoothPlastic', transparency: o.transparency ?? 0,
			localTransparencyModifier: 0, reflectance: o.reflectance || 0, meshId: o.meshId || null, textureId: null,
			parentPath: o.parent || ROOT, castShadow: o.castShadow ?? true,
		};
		if (o.meshSize) p.meshSize = o.meshSize;
		parts.push(p);
		return p;
	}
	function att(name, host, worldCf) {
		const a = { id: nextId++, path: `${host ? host.path : ROOT}.${name}`, hostId: host ? host.id : null, worldCf };
		atts.push(a);
		return a;
	}
	const image = (img, o = {}) => ({ image: img, color: o.color || [255, 255, 255], transparency: o.transparency ?? 0, rotation: o.rotation || 0,
		size: o.size || [1, 0, 1, 0], position: o.position || [0, 0, 0, 0], anchor: [0, 0], visible: true, zIndex: 1, backgroundTransparency: 1 });
	function surface(host, face, imgs, o = {}) {
		guis.push({ kind: 'SurfaceGui', path: `${host.path}.SurfaceGui${face}`, hostId: host.id, face, canvas: o.canvas || [512, 512], sizeStuds: null,
			studsOffset: null, studsOffsetWorldSpace: null, brightness: o.brightness ?? 1, lightInfluence: o.lightInfluence ?? 0,
			alwaysOnTop: false, enabled: true, maxDistance: null, images: imgs, sizingMode: 'FixedSize', pixelsPerStud: 50, texts: o.texts || [] });
	}
	function billboard(host, size, imgs, o = {}) {
		guis.push({ kind: 'BillboardGui', path: `${host.path}.BillboardGui${guis.length}`, hostId: host.id, face: null, canvas: null, sizeStuds: size,
			studsOffset: o.offset || [0, 0, 0], studsOffsetWorldSpace: o.worldOffset || [0, 0, 0], brightness: o.brightness ?? 1,
			lightInfluence: 0, alwaysOnTop: !!o.top, enabled: true, maxDistance: o.maxDistance ?? null, images: imgs, texts: [] });
	}
	function emitter(host, o) {
		const e = {
			path: `${host.path}.ParticleEmitter${emitters.length}`, hostId: host.worldCf ? null : host.id, hostAttachmentId: host.worldCf ? host.id : null,
			enabled: true, texture: o.texture, rate: o.rate, lifetime: o.lifetime || [1, 1], speed: o.speed || [0, 0], spreadAngle: o.spread || [0, 0],
			emissionDirection: o.dir || 'Top', shape: o.shape || 'Box', shapeStyle: o.style || 'Volume', shapeInOut: o.inout || 'Outward',
			shapePartial: o.partial ?? 1, size: o.size, transparency: o.transparency || seq([0, 0], [1, 0]), color: o.color || cseq([0, 255, 255, 255], [1, 255, 255, 255]),
			lightEmission: o.le ?? 1, lightInfluence: o.li ?? 0, brightness: o.brightness ?? 1, acceleration: o.acc || [0, 0, 0], drag: o.drag || 0,
			lockedToPart: !!o.locked, rotation: o.rotation || [0, 0], rotSpeed: o.rotSpeed || [0, 0], zOffset: 0, orientation: o.orientation || 'FacingCamera',
			flipbookLayout: o.layout || 'None', flipbookMode: o.mode || 'Loop', squash: o.squash || null, timeScale: 1,
			flipbookFramerate: o.framerate || [1, 1], flipbookStartRandom: false, hostSize: host.size || null,
		};
		emitters.push(e);
		return e;
	}

	// shapes (identity orientation, so the conventions show: the wedge slope faces -Z, the cylinder lies along X)
	const xs = [-24, -15, -6, 3, 12, 21];
	part('Block', [4, 4, 4], CF(xs[0], 2, 16));
	part('Ball', [4, 4, 4], CF(xs[1], 2, 16), { shape: 'Ball' });
	part('Cylinder', [6, 4, 4], CF(xs[2], 2, 16), { shape: 'Cylinder' });
	part('Wedge', [4, 4, 4], CF(xs[3], 2, 16), { shape: 'Wedge', class: 'WedgePart', color: [90, 140, 220] });
	part('CornerWedge', [4, 4, 4], CF(xs[4], 2, 16), { shape: 'CornerWedge', class: 'CornerWedgePart', color: [220, 140, 90] });
	part('UnknownMesh', [4, 4, 4], CF(xs[5], 2, 16), { shape: 'Mesh', class: 'MeshPart', meshId: 'rbxassetid://1234567890' });

	// film-mesh stand-ins (fake ids, sizes as the harness's fake AuraCinema assets)
	part('RingG', [10, 10, 0.9], CF(-22, 6, 26), { shape: 'Mesh', class: 'MeshPart', meshId: 'rbxassetid://70000000001', meshSize: [2.86, 2.86, 0.22], material: 'Metal', color: [176, 180, 190] });
	part('Dial', [0.5, 8, 8], CF(-10, 5, 26), { shape: 'Mesh', class: 'MeshPart', meshId: 'rbxassetid://70000000002', meshSize: [0.11, 2.44, 2.44], color: [48, 50, 56] });
	part('Astrolabe', [8, 0.4, 8], CF(0, 1, 26, 0, 0, 0), { shape: 'Mesh', class: 'MeshPart', meshId: 'rbxassetid://70000000003', meshSize: [4.2, 0.12, 4.2], material: 'Metal', color: [176, 180, 190] });
	part('Hand', [0.6, 7, 0.25], CF(9, 5, 26), { shape: 'Mesh', class: 'MeshPart', meshId: 'rbxassetid://70000000004', meshSize: [0.16, 2.3, 0.06], material: 'Metal', color: [218, 220, 228] });
	part('Gear', [6, 6, 0.8], CF(17, 5, 26), { shape: 'Mesh', class: 'MeshPart', meshId: 'rbxassetid://70000000005', meshSize: [1, 1, 0.15], material: 'Metal', color: [60, 62, 68] });
	part('Moon', [5, 5, 5], CF(27, 4, 26), { shape: 'Mesh', class: 'MeshPart', meshId: 'rbxassetid://70000000006', meshSize: [2, 2, 2], color: [230, 230, 235] });

	// materials
	const mats = [['Plastic', {}], ['SmoothPlastic', {}], ['Metal', { color: [205, 208, 215] }], ['Neon', { color: [248, 249, 255] }],
		['Neon', { color: [10, 10, 14], name: 'NeonBlack' }], ['Glass', { transparency: 0.4, color: [210, 225, 235] }], ['Foil', { color: [205, 208, 215] }],
		['ForceField', { color: [220, 230, 255] }], ['SmoothPlastic', { reflectance: 0.6, name: 'Reflect' }], ['SmoothPlastic', { transparency: 0.5, name: 'Half' }]];
	mats.forEach(([m, o], i) => {
		const x = -29 + i * 6.4 + (i >= 5 ? 1.5 : 0);
		part(o.name || m, [3.6, 3.6, 3.6], CF(Math.abs(x) < 3 ? x + 3 : x, 2.2, 6), { shape: 'Ball', material: m, color: o.color || [200, 200, 205], transparency: o.transparency, reflectance: o.reflectance });
	});

	// labelled cubes (SurfaceGui on every face)
	const cube = part('FaceCube', [4, 4, 4], CF(-10, 3, -8), { color: [60, 60, 66] });
	for (const f of ['Front', 'Back', 'Top', 'Bottom', 'Left', 'Right']) surface(cube, f, [image('fixture:face_' + f.toLowerCase())]);
	const cube2 = part('FaceCube45', [4, 4, 4], CF(10, 3, -8, 0, 45, 0), { color: [60, 60, 66] });
	for (const f of ['Front', 'Top', 'Right']) surface(cube2, f, [image('fixture:face_' + f.toLowerCase())]);

	// a floor plate with a glowing galaxy on its Top face, and a rotated ImageLabel inset
	const plate = part('GalaxyPlate', [12, 0.1, 12], CF(0, 0.06, -17), { transparency: 1 });
	surface(plate, 'Top', [image('rbxassetid://91068008644782'), image('fixture:face_top', { size: [0.2, 0, 0.2, 0], position: [0.4, 0, 0.05, 0], rotation: 30 })], { brightness: 2.6, canvas: [1024, 1024] });

	// beams
	const anchor = part('BeamAnchor', [1, 1, 1], CF(0, 0, 0), { transparency: 1 });
	const a0 = att('ArcA0', anchor, fromMatrix([-21, 9, -3], [0, 1, 0], [-1, 0, 0]));
	const a1 = att('ArcA1', anchor, fromMatrix([-5, 9, -3], [0, -1, 0], [1, 0, 0]));
	beams.push({ path: `${ROOT}.ArcBeam`, a0: a0.id, a1: a1.id, curve0: 7, curve1: 7, width0: 1.2, width1: 1.2, segments: 20, faceCamera: true,
		texture: 'fixture:arrow_strip', textureMode: 'Wrap', textureLength: 3, textureSpeed: 0, color: cseq([0, 255, 255, 255], [1, 255, 255, 255]),
		transparency: seq([0, 0], [1, 0]), lightEmission: 0, lightInfluence: 0, brightness: 1, zOffset: 0, enabled: true });
	const g0 = att('FlatA0', anchor, CF(4, 0.25, -26)), g1 = att('FlatA1', anchor, CF(22, 0.25, -26));
	beams.push({ path: `${ROOT}.FlatBeam`, a0: g0.id, a1: g1.id, curve0: 0, curve1: 0, width0: 2.5, width1: 2.5, segments: 1, faceCamera: false,
		texture: 'fixture:arrow_strip', textureMode: 'Stretch', textureLength: 3, textureSpeed: 0, color: cseq([0, 255, 255, 255], [1, 255, 255, 255]),
		transparency: seq([0, 0], [1, 0]), lightEmission: 0, lightInfluence: 1, brightness: 1, zOffset: 0, enabled: true });
	const c0 = att('ColA0', anchor, CF(27, 0.5, -4)), c1 = att('ColA1', anchor, CF(27, 15, -4));
	beams.push({ path: `${ROOT}.ColumnBeam`, a0: c0.id, a1: c1.id, curve0: 0, curve1: 0, width0: 3, width1: 0.5, segments: 4, faceCamera: true,
		texture: 'rbxassetid://3029306948', textureMode: 'Stretch', textureLength: 1, textureSpeed: 0.25,
		color: cseq([0, 255, 255, 255], [1, 40, 40, 44]), transparency: seq([0, 0], [0.8, 0.3], [1, 1]),
		lightEmission: 1, lightInfluence: 0, brightness: 3, zOffset: 0, enabled: true });

	// billboards
	const bbHost = part('BillboardHost', [1, 1, 1], CF(-26, 10, 2), { transparency: 1 });
	billboard(bbHost, [5, 5], [image('rbxassetid://16956515291')], { brightness: 3 });
	billboard(bbHost, [8, 8], [image('rbxassetid://90101855061498', { transparency: 0.3 })], { brightness: 1.2, offset: [0, 0, -3] });
	const wall = part('Wall', [6, 6, 0.5], CF(26, 3, 10), { color: [120, 90, 70] });
	const behind = part('BehindWall', [1, 1, 1], CF(26, 3, 14), { transparency: 1 });
	billboard(behind, [3, 3], [image('rbxassetid://105160126126488')], { top: true, brightness: 1.2 });
	billboard(behind, [3, 3], [image('rbxassetid://98346126355034')], { worldOffset: [0, 4.5, 0], brightness: 1.5 });
	void wall;

	// emitters
	const boxHost = part('BoxEmitter', [6, 2, 6], CF(-24, 3, -18), { transparency: 1 });
	emitter(boxHost, { texture: 'rbxassetid://115317702570755', rate: 30, lifetime: [2, 3], size: seq([0, 1, 0.3], [1, 1, 0.3]), layout: 'Grid4x4', mode: 'OneShot',
		transparency: seq([0, 0], [1, 0]), brightness: 2.4, rotation: [0, 360] });
	const sphHost = part('SphereEmitter', [4, 4, 4], CF(-12, 4, -22), { shape: 'Ball', transparency: 1 });
	emitter(sphHost, { texture: 'rbxassetid://109765380822041', rate: 40, lifetime: [1, 1.6], speed: [4, 6], drag: 1, shape: 'Sphere', style: 'Surface',
		orientation: 'VelocityParallel', size: seq([0, 0.6], [1, 0.2]), transparency: seq([0, 0], [0.7, 0.2], [1, 1]), brightness: 2.5 });
	const discHost = part('DiscEmitter', [10, 0.2, 10], CF(0, 0.2, -27), { transparency: 1 });
	emitter(discHost, { texture: 'rbxassetid://88172507927269', rate: 80, lifetime: [2, 3], speed: [2, 3], acc: [0, 1, 0], shape: 'Disc', partial: 0.7,
		size: seq([0, 0.5], [1, 0]), transparency: seq([0, 1], [0.2, 0], [1, 0.4]), brightness: 2.2 });
	const cylHost = part('CylinderEmitter', [4, 6, 4], CF(12, 4, -22), { transparency: 1 });
	emitter(cylHost, { texture: 'rbxassetid://88172507927269', rate: 60, lifetime: [1.5, 2], speed: [0.5, 1], shape: 'Cylinder', partial: 0.1,
		size: seq([0, 0.4], [1, 0.4]), color: cseq([0, 200, 220, 255], [1, 255, 255, 255]), brightness: 1.6 });
	const pt = att('SmokePoint', anchor, CF(23, 6, -18));
	pt.size = null;
	emitter(pt, { texture: 'rbxassetid://17062535921', rate: 6, lifetime: [3, 4], speed: [1, 2], spread: [180, 180], size: seq([0, 2], [1, 5]),
		layout: 'Grid4x4', mode: 'OneShot', transparency: seq([0, 1], [0.25, 0.3], [1, 1]), color: cseq([0, 14, 14, 19], [1, 14, 14, 19]), le: 0,
		rotation: [0, 360], rotSpeed: [-30, 30], drag: 0.5 });
	const mistHost = part('MistEmitter', [8, 3, 8], CF(-26, 2, -6), { transparency: 1 });
	emitter(mistHost, { texture: 'rbxassetid://13826565206', rate: 3, lifetime: [5, 6], size: seq([0, 5], [1, 8]), layout: 'Grid4x4', mode: 'Loop', framerate: [2, 3],
		transparency: seq([0, 1], [0.3, 0.6], [0.7, 0.6], [1, 1]), color: cseq([0, 205, 209, 220], [1, 205, 209, 220]), le: 0.3, locked: true });

	// a point light near the floor
	const lamp = part('Lamp', [0.6, 0.6, 0.6], CF(0, 3, -10), { shape: 'Ball', material: 'Neon', color: [225, 232, 248], castShadow: false });
	lights.push({ class: 'PointLight', hostId: lamp.id, color: [225, 232, 248], brightness: 2, range: 16, enabled: true, path: `${lamp.path}.PointLight`, shadows: false });

	// a highlighted metal model (pass-5 style: neutral silver fill + ink outline)
	const H = `${ROOT}.Hilite`;
	part('RingTop', [6, 1, 1], CF(-28, 5, -8), { parent: H, material: 'Metal', color: [176, 180, 190] });
	part('RingLeft', [1, 5, 1], CF(-30.5, 3, -8), { parent: H, material: 'Metal', color: [176, 180, 190] });
	part('RingRight', [1, 5, 1], CF(-25.5, 3, -8), { parent: H, material: 'Metal', color: [176, 180, 190] });
	highlights.push({ path: `${H}.Highlight`, adorneePath: H, fillColor: [205, 208, 215], fillTransparency: 0.55, outlineColor: [10, 10, 14],
		outlineTransparency: 0.35, depthMode: 'Occluded', enabled: true });

	// a trail with history: a helix rising round (14, y, 4)
	const T = 8;
	const hist = [];
	for (let t = T - 2; t <= T + 1e-6; t += 0.1) {
		const a = t * 2.4, x = 18 + Math.cos(a) * 3, z = -4 + Math.sin(a) * 3, y = 3 + (t - (T - 2)) * 3;
		hist.push([+t.toFixed(2), x, y - 0.5, z, x, y + 0.5, z]);
	}
	const last = hist[hist.length - 1];
	const ta0 = att('TrailA0', anchor, CF(last[1], last[2], last[3])), ta1 = att('TrailA1', anchor, CF(last[4], last[5], last[6]));
	trails.push({ path: `${ROOT}.Trail`, a0: ta0.id, a1: ta1.id, enabled: true, texture: '', textureMode: 'Stretch', textureLength: 1, lifetime: 1.5,
		minLength: 0.1, maxLength: 0, widthScale: seq([0, 1], [1, 0.2]), color: cseq([0, 255, 255, 255], [1, 120, 120, 130]),
		transparency: seq([0, 0], [1, 1]), lightEmission: 1, lightInfluence: 0, brightness: 2.5, faceCamera: false, history: hist });

	if (graded) effects.push({ class: 'ColorCorrectionEffect', path: 'Workspace.Camera.TheEndReveal', parentPath: 'Workspace.Camera',
		props: { Brightness: -0.1, Contrast: 0.15, Saturation: -0.75, TintColor: [232, 238, 255] } });

	return {
		version: 1, scenario, frame: Math.round(T * 60), t: T, clockTime, quality: 'high', auraInWorld: true,
		camera: { cf: CF(0, 16, -50, 12, 180, 0), fov: 70, viewport: [1920, 913], cameraType: 'Custom' },
		wearer: { cf: CF(0, 3, 0), hover: 2, glide: 0, legLen: 3, ground: [0, 0, 0], isLocal: true, rig: 'R15', alpha: 1 },
		parts, attachments: atts, beams, guis, emitters, trails, lights, highlights, effects,
	};
}

const write = (name, snap) => { fs.writeFileSync(path.join(OUT, name), JSON.stringify(snap)); console.log('wrote', path.join('tools/preview/fixtures', name)); };
write('all_elements.json', build());
write('all_elements_night.json', build({ clockTime: 0, scenario: 'fixture_all_night' }));
write('all_elements_graded.json', build({ graded: true, scenario: 'fixture_all_graded' }));
