// BaseParts -> meshes. Shapes follow Roblox's conventions:
//   Block     box of Size.
//   Ball      sphere, diameter = the smallest Size component (Roblox keeps balls uniform).
//   Cylinder  axis along the part's local X (length Size.X, diameter min(Size.Y, Size.Z)).
//   Wedge     WedgePart: rectangular bottom (-Y) and back (+Z) faces; the slope runs from the top-back edge down to the
//             bottom-front edge, so the sloped face looks toward -Z (Front) and up. Triangles on the Left/Right faces.
//   CornerWedge CornerWedgePart: square bottom; its apex is above the (+X, +Z) corner (vertical faces Right and Back,
//             slopes facing Front and Left).  (From memory of Roblox's meshes - verify in Studio if a build depends on it.)
//   Mesh      MeshPart / union: the fake film meshes (rbxassetid://7000000000N, or by name) get procedural stand-ins
//             (RingG ring, Dial disc, Astrolabe openwork ring, Hand, Gear, Moon / SmoothSphere spheres); anything else is
//             a bounding-box placeholder with an amber wireframe so it is obvious it is not the real mesh.
import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';
import { cfMatrix, srgb, enumName, lastName } from 'preview/rbx.js';

// ------------------------------------------------------------------------------------------------- unit geometries
const G = {};
function unit(kind) {
	if (G[kind]) return G[kind];
	let g;
	switch (kind) {
		case 'Block': g = new THREE.BoxGeometry(1, 1, 1); break;
		case 'Ball': g = new THREE.SphereGeometry(0.5, 48, 32); break;
		case 'Cylinder': g = new THREE.CylinderGeometry(0.5, 0.5, 1, 48); g.rotateZ(-Math.PI / 2); break; // axis Y -> X
		case 'Wedge': g = wedgeGeometry(); break;
		case 'CornerWedge': g = cornerWedgeGeometry(); break;
		case 'Rounded': g = new RoundedBoxGeometry(1, 1, 1, 3, 0.12); break;
		case 'Head': g = new RoundedBoxGeometry(1, 1, 1, 4, 0.3); break;
		default: g = new THREE.BoxGeometry(1, 1, 1);
	}
	g.userData.shared = true;
	G[kind] = g;
	return g;
}
function fromTris(vs) {
	// vs: triangle corners [x, y, z] in counter-clockwise order seen from outside (flat shading: nothing shared)
	const g = new THREE.BufferGeometry();
	g.setAttribute('position', new THREE.Float32BufferAttribute(vs.flat(), 3));
	g.computeVertexNormals();
	return g;
}
function wedgeGeometry() {
	const h = 0.5;
	const b0 = [-h, -h, -h], b1 = [h, -h, -h], b2 = [h, -h, h], b3 = [-h, -h, h]; // bottom (front edge b0-b1)
	const t2 = [h, h, h], t3 = [-h, h, h]; // top-back edge
	return fromTris([
		b0, b1, b2, b0, b2, b3, // bottom (-Y)
		b3, b2, t2, b3, t2, t3, // back (+Z)
		b0, t3, t2, b0, t2, b1, // slope (normal (0, 1, -1): faces Front and up)
		b0, b3, t3, // left triangle (-X)
		b1, t2, b2, // right triangle (+X)
	]);
}
function cornerWedgeGeometry() {
	const h = 0.5;
	const b0 = [-h, -h, -h], b1 = [h, -h, -h], b2 = [h, -h, h], b3 = [-h, -h, h], apex = [h, h, h];
	return fromTris([
		b0, b1, b2, b0, b2, b3, // bottom
		b1, apex, b2, // right (+X), vertical
		b3, b2, apex, // back (+Z), vertical
		b0, apex, b1, // slope facing Front (-Z) and up
		b0, b3, apex, // slope facing Left (-X) and up
	]);
}

// ------------------------------------------------------------------------------------------------- film mesh stand-ins
// built in a unit box with the mesh's thin axis along Z, then turned so Z lands on the part's thin axis
const FILM_IDS = { '70000000001': 'ring', '70000000002': 'dial', '70000000003': 'astrolabe', '70000000004': 'hand', '70000000005': 'gear', '70000000006': 'sphere', '70000000007': 'sphere' };
function filmKind(p) {
	const id = String(p.meshId || '').replace(/\D/g, '');
	if (FILM_IDS[id]) return FILM_IDS[id];
	const n = (lastName(p.path) + ' ' + lastName(p.parentPath || '')).toLowerCase();
	if (/ringg|bezel|ring/.test(n)) return 'ring';
	if (/astrolabe|rete/.test(n)) return 'astrolabe';
	if (/dial|plate/.test(n)) return 'dial';
	if (/hand/.test(n)) return 'hand';
	if (/gear|cog|wheel/.test(n)) return 'gear';
	if (/moon|sphere|orb|void|ball/.test(n)) return 'sphere';
	return null;
}
function extrudeUnit(shape, bevel = 0.04) {
	const g = new THREE.ExtrudeGeometry(shape, { depth: 1 - 2 * bevel, bevelEnabled: bevel > 0, bevelThickness: bevel, bevelSize: bevel * 0.4, bevelSegments: 2, curveSegments: 64 });
	g.translate(0, 0, -(1 - 2 * bevel) / 2);
	return g;
}
function annulus(R, r, n = 96) {
	const s = new THREE.Shape(); s.absarc(0, 0, R, 0, Math.PI * 2, false);
	const h = new THREE.Path(); h.absarc(0, 0, r, 0, Math.PI * 2, true); s.holes.push(h);
	return s;
}
const FILM = {};
function filmGeometry(kind) {
	if (FILM[kind]) return FILM[kind];
	let g;
	if (kind === 'ring') g = extrudeUnit(annulus(0.5, 0.43), 0.08);
	else if (kind === 'dial') { g = new THREE.CylinderGeometry(0.5, 0.5, 1, 96); g.rotateX(Math.PI / 2); }
	else if (kind === 'astrolabe') {
		const parts = [extrudeUnit(annulus(0.5, 0.46), 0.1), extrudeUnit(annulus(0.3, 0.27), 0.1), extrudeUnit(annulus(0.08, 0.05), 0.1)];
		for (let i = 0; i < 6; i++) {
			const b = new THREE.BoxGeometry(0.02, 0.46, 0.8); b.translate(0, 0.25, 0); b.rotateZ((i * Math.PI) / 3); parts.push(b);
		}
		g = mergeGeoms(parts);
	} else if (kind === 'hand') {
		const s = new THREE.Shape();
		s.moveTo(0, 0.5); s.lineTo(0.35, 0.05); s.lineTo(0.5, -0.25); s.lineTo(0.18, -0.38); s.lineTo(0.25, -0.5);
		s.lineTo(-0.25, -0.5); s.lineTo(-0.18, -0.38); s.lineTo(-0.5, -0.25); s.lineTo(-0.35, 0.05); s.closePath();
		g = extrudeUnit(s, 0.08);
	} else if (kind === 'gear') {
		const s = new THREE.Shape(), teeth = 18;
		for (let i = 0; i <= teeth * 4; i++) {
			const a = (i / (teeth * 4)) * Math.PI * 2, k = i % 4, r = k === 1 || k === 2 ? 0.5 : 0.43;
			if (i === 0) s.moveTo(r * Math.cos(a), r * Math.sin(a)); else s.lineTo(r * Math.cos(a), r * Math.sin(a));
		}
		const hub = new THREE.Path(); hub.absarc(0, 0, 0.07, 0, Math.PI * 2, true); s.holes.push(hub);
		for (let i = 0; i < 5; i++) { // openwork: five windows between spokes
			const a0 = (i / 5) * Math.PI * 2 + 0.16, a1 = ((i + 1) / 5) * Math.PI * 2 - 0.16, w = new THREE.Path();
			w.absarc(0, 0, 0.35, a0, a1, false); w.absarc(0, 0, 0.13, a1, a0, true); w.closePath(); s.holes.push(w);
		}
		g = extrudeUnit(s, 0.08);
	} else g = new THREE.SphereGeometry(0.5, 64, 40);
	g.userData.shared = true;
	FILM[kind] = g;
	return g;
}
function mergeGeoms(list) {
	// minimal merge (position + normal) without the addons' BufferGeometryUtils dependency on index layouts
	const pos = [], nor = [];
	for (let g of list) {
		g = g.index ? g.toNonIndexed() : g;
		if (!g.attributes.normal) g.computeVertexNormals();
		pos.push(...g.attributes.position.array); nor.push(...g.attributes.normal.array);
	}
	const out = new THREE.BufferGeometry();
	out.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
	out.setAttribute('normal', new THREE.Float32BufferAttribute(nor, 3));
	return out;
}
// rotation taking the stand-in's Z (thin) and Y (long, for hands) axes onto the part's axes
function filmBasis(kind, p) {
	const ms = p.meshSize || p.size, s = p.size;
	const dims = [0, 1, 2].sort((a, b) => (ms[a] - ms[b]) || (s[a] - s[b]));
	const thin = dims[0], long = dims[2];
	const m = new THREE.Matrix4();
	const ax = (i) => new THREE.Vector3(i === 0 ? 1 : 0, i === 1 ? 1 : 0, i === 2 ? 1 : 0);
	let yAxis = kind === 'hand' ? long : dims[1];
	if (yAxis === thin) yAxis = dims[1];
	const z = ax(thin), y = ax(yAxis), x = new THREE.Vector3().crossVectors(y, z);
	m.makeBasis(x, y, z);
	return m;
}

// ------------------------------------------------------------------------------------------------- materials
const MAT = {
	Plastic: [0.72, 0], SmoothPlastic: [0.42, 0], Metal: [0.34, 0.86], DiamondPlate: [0.4, 0.8], Foil: [0.24, 0.92],
	CorrodedMetal: [0.7, 0.55], Glass: [0.05, 0], Ice: [0.18, 0], Glacier: [0.25, 0], Marble: [0.3, 0], Granite: [0.6, 0],
	Slate: [0.82, 0], Concrete: [0.92, 0], Wood: [0.8, 0], WoodPlanks: [0.8, 0], Brick: [0.92, 0], Pebble: [0.9, 0],
	Cobblestone: [0.9, 0], Fabric: [0.96, 0], Sand: [1, 0], Grass: [0.95, 0], Rock: [0.85, 0], Basalt: [0.85, 0],
	CeramicTiles: [0.3, 0], Rubber: [0.85, 0], Leather: [0.6, 0], Plaster: [0.9, 0], Snow: [0.9, 0], Salt: [0.8, 0],
};
export const NEON_GAIN = 2.6; // Neon is self-lit: white Neon sits above the place's Bloom threshold (2) and glows

const FORCEFIELD_VERT = /* glsl */`
varying vec3 vN; varying vec3 vV;
void main() {
	vec4 wp = modelMatrix * vec4(position, 1.0);
	vN = normalize(mat3(modelMatrix) * normal); vV = normalize(cameraPosition - wp.xyz);
	gl_Position = projectionMatrix * viewMatrix * wp;
}`;
const FORCEFIELD_FRAG = /* glsl */`
uniform vec3 uColor; uniform float uOpacity;
varying vec3 vN; varying vec3 vV;
void main() {
	float f = 1.0 - abs(dot(normalize(vN), normalize(vV)));
	float a = (0.12 + 1.2 * pow(f, 2.2)) * uOpacity;
	gl_FragColor = vec4(uColor * a, 0.0); // additive shimmer, as Roblox's ForceField material
}`;

export function partMaterial(p, opts = {}) {
	const matName = enumName(p.material, 'Plastic');
	const T = 1 - (1 - (p.transparency || 0)) * (1 - (p.localTransparencyModifier || 0));
	const color = srgb(p.color);
	const R = Math.min(Math.max(p.reflectance || 0, 0), 1);
	const transparent = T > 0.001;
	const common = { transparent, opacity: 1 - T, depthWrite: !transparent, side: THREE.FrontSide };
	if (matName === 'Neon') {
		// Roblox Neon: unlit, a little lighter and more saturated than the colour, blooms
		const hsl = {}; color.getHSL(hsl);
		const c = new THREE.Color().setHSL(hsl.h, Math.min(1, hsl.s * 1.12), hsl.l);
		return new THREE.MeshBasicMaterial({ color: c.multiplyScalar(NEON_GAIN), ...common, fog: true });
	}
	if (matName === 'ForceField') {
		return new THREE.ShaderMaterial({
			vertexShader: FORCEFIELD_VERT, fragmentShader: FORCEFIELD_FRAG, transparent: true, depthWrite: false,
			blending: THREE.CustomBlending, blendSrc: THREE.OneFactor, blendDst: THREE.OneFactor,
			uniforms: { uColor: { value: color.clone().multiplyScalar(1.6) }, uOpacity: { value: 1 - T } },
		});
	}
	let [rough, metal] = MAT[matName] || [0.6, 0];
	metal = Math.max(metal, R);
	rough = rough * (1 - R) + 0.06 * R;
	if (matName === 'Glass') {
		return new THREE.MeshPhysicalMaterial({
			color, roughness: rough, metalness: metal, envMapIntensity: 1.6, ...common,
			opacity: transparent ? Math.max(0.12, 1 - T) : 1, clearcoat: 0.6, clearcoatRoughness: 0.05,
		});
	}
	return new THREE.MeshStandardMaterial({ color, roughness: rough, metalness: metal, envMapIntensity: 1 + R, ...common });
}

// ------------------------------------------------------------------------------------------------- build
const WIRE = new THREE.LineBasicMaterial({ color: 0xffb020, transparent: true, opacity: 0.9 });

// returns { group, byId: Map(id -> record { p, matrix, size, mesh }) }
export function buildParts(snapshot, ctx) {
	const group = new THREE.Group();
	group.name = 'parts';
	const byId = new Map();
	for (const p of snapshot.parts || []) {
		const matrix = cfMatrix(p.cf);
		const rec = { p, matrix, size: p.size, mesh: null };
		byId.set(p.id, rec);
		const T = 1 - (1 - (p.transparency || 0)) * (1 - (p.localTransparencyModifier || 0));
		if (T >= 0.999) continue;
		const shape = p.specialMesh ? specialShape(p, ctx) : (p.shape || 'Block');
		let geo, basis = null, scale = new THREE.Vector3(...p.size), placeholder = false;
		if (shape === 'Ball') { const d = Math.min(...p.size); scale.set(d, d, d); geo = unit('Ball'); }
		else if (shape === 'Cylinder') { const d = Math.min(p.size[1], p.size[2]); scale.set(p.size[0], d, d); geo = unit('Cylinder'); }
		else if (shape === 'Ellipsoid') geo = unit('Ball');
		else if (shape === 'Mesh') {
			const kind = filmKind(p);
			if (kind) { geo = filmGeometry(kind); basis = filmBasis(kind, p); rec.film = kind; }
			else { geo = unit('Block'); placeholder = true; ctx.warn(`mesh ${p.meshId || '(none)'} on ${p.path}: drawn as a bounding box placeholder`); }
		} else geo = unit(['Block', 'Wedge', 'CornerWedge'].includes(shape) ? shape : 'Block');
		const mat = partMaterial(p);
		if (placeholder && mat.opacity !== undefined) { mat.transparent = true; mat.opacity = Math.min(mat.opacity, 0.45); mat.depthWrite = false; }
		const mesh = new THREE.Mesh(geo, mat);
		mesh.name = p.path;
		mesh.matrixAutoUpdate = false;
		const m = matrix.clone();
		if (basis) {
			// size in the stand-in's frame: x/y/z extents along the axes the basis maps them to
			const sx = new THREE.Vector3(1, 0, 0).applyMatrix4(basis), sy = new THREE.Vector3(0, 1, 0).applyMatrix4(basis), sz = new THREE.Vector3(0, 0, 1).applyMatrix4(basis);
			const pick = (v) => Math.abs(v.x) * p.size[0] + Math.abs(v.y) * p.size[1] + Math.abs(v.z) * p.size[2];
			let lx = pick(sx), ly = pick(sy), lz = pick(sz);
			if (rec.film === 'ring' || rec.film === 'dial' || rec.film === 'gear' || rec.film === 'astrolabe') { const d = Math.min(lx, ly); lx = ly = d; }
			if (rec.film === 'sphere') { const d = Math.min(lx, ly, lz); lx = ly = lz = d; }
			m.multiply(basis).multiply(new THREE.Matrix4().makeScale(lx, ly, lz));
		} else m.multiply(new THREE.Matrix4().makeScale(scale.x, scale.y, scale.z));
		mesh.matrix.copy(m);
		mesh.castShadow = p.castShadow === true && !mat.transparent;
		mesh.receiveShadow = !mat.transparent;
		mesh.userData.partId = p.id;
		mesh.userData.opaque = !mat.transparent;
		group.add(mesh);
		rec.mesh = mesh;
		if (placeholder) {
			const wire = new THREE.LineSegments(new THREE.EdgesGeometry(unit('Block')), WIRE);
			wire.matrixAutoUpdate = false; wire.matrix.copy(m); group.add(wire);
		}
		if (p.textureId) ctx.warn(`MeshPart TextureID ${p.textureId} on ${p.path} is not drawn (no UVs in the preview)`, 'meshtex');
	}
	return { group, byId };
}

function specialShape(p, ctx) {
	const t = enumName(p.specialMesh.meshType, 'Brick');
	if (t === 'Sphere') return 'Ellipsoid';
	if (t === 'Cylinder') return 'Cylinder';
	if (t === 'Wedge') return 'Wedge';
	if (t === 'Brick') return 'Block';
	if (t === 'FileMesh') { ctx.warn(`SpecialMesh FileMesh ${p.specialMesh.meshId} on ${p.path}: placeholder box`, 'filemesh'); return 'Mesh'; }
	return p.shape || 'Block';
}

// ------------------------------------------------------------------------------------------------- characters
// the posed rig from the harness (snapshot.characters[].parts: name, size, cf, color, transparency)
export function buildCharacters(snapshot) {
	const group = new THREE.Group();
	group.name = 'characters';
	for (const ch of snapshot.characters || []) {
		for (const bp of ch.parts || []) {
			if ((bp.transparency || 0) >= 0.999 || bp.name === 'HumanoidRootPart') continue;
			const isHead = bp.name === 'Head';
			const mesh = new THREE.Mesh(unit(isHead ? 'Head' : 'Rounded'), new THREE.MeshStandardMaterial({ color: srgb(bp.color), roughness: 0.5, metalness: 0 }));
			mesh.matrixAutoUpdate = false;
			mesh.matrix.copy(cfMatrix(bp.cf)).multiply(new THREE.Matrix4().makeScale(...bp.size));
			mesh.castShadow = mesh.receiveShadow = true;
			mesh.userData.opaque = true;
			group.add(mesh);
			if (isHead) { // eyes and a smile on the face (-Z), so you can tell which way the character looks
				const fm = new THREE.MeshBasicMaterial({ color: 0x18181c });
				for (const [x, y, w, h] of [[-0.2, 0.1, 0.1, 0.2], [0.2, 0.1, 0.1, 0.2], [0, -0.2, 0.36, 0.06]]) {
					const f = new THREE.Mesh(new THREE.PlaneGeometry(w, h), fm);
					f.matrixAutoUpdate = false;
					f.matrix.copy(cfMatrix(bp.cf)).multiply(new THREE.Matrix4().makeTranslation(x * bp.size[0], y * bp.size[1], -bp.size[2] / 2 - 0.01)).multiply(new THREE.Matrix4().makeRotationY(Math.PI));
					group.add(f);
				}
			}
		}
	}
	return group;
}

// fallback when the snapshot has no posed rig: a plain R15 stand (body centre = HRP + hover, soles at -legLen)
export function buildMannequin(wearer) {
	const cf = wearer.cf, hover = wearer.hover || 0, legLen = wearer.legLen || 3;
	const base = cfMatrix(cf).premultiply(new THREE.Matrix4().makeTranslation(0, hover, 0));
	const lean = new THREE.Matrix4().makeRotationX(THREE.MathUtils.degToRad(-18 * (wearer.glide || 0)));
	base.multiply(lean);
	const skin = [234, 199, 158], shirt = [242, 153, 38], pants = [26, 26, 31];
	const leg = (legLen - 0.8) / 2;
	const P = [
		['Head', [1.2, 1.2, 1.2], [0, 2.2, 0], skin], ['UpperTorso', [2, 1.6, 1], [0, 0.8, 0], shirt], ['LowerTorso', [2, 0.4, 1], [0, -0.2, 0], shirt],
		['LeftUpperArm', [1, 1.17, 1], [-1.5, 1.0, 0], skin], ['RightUpperArm', [1, 1.17, 1], [1.5, 1.0, 0], skin],
		['LeftLowerArm', [1, 1.05, 1], [-1.5, -0.1, 0], skin], ['RightLowerArm', [1, 1.05, 1], [1.5, -0.1, 0], skin],
		['LeftUpperLeg', [1, leg, 1], [-0.5, -0.4 - leg / 2, 0], pants], ['RightUpperLeg', [1, leg, 1], [0.5, -0.4 - leg / 2, 0], pants],
		['LeftLowerLeg', [1, leg, 1], [-0.5, -0.4 - leg * 1.5, 0], pants], ['RightLowerLeg', [1, leg, 1], [0.5, -0.4 - leg * 1.5, 0], pants],
	];
	const parts = P.map(([name, size, pos, color]) => {
		const m = base.clone().multiply(new THREE.Matrix4().makeTranslation(...pos));
		const e = m.elements;
		return { name, size, color, transparency: 0, cf: [e[12], e[13], e[14], e[0], e[4], e[8], e[1], e[5], e[9], e[2], e[6], e[10]] };
	});
	return buildCharacters({ characters: [{ parts }] });
}
