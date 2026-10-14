// Camera presets, relative to the wearer (body centre = HumanoidRootPart + hover; "front" = where the wearer faces).
//   cam      the snapshot's own camera (Workspace.CurrentCamera: CFrame + vertical FieldOfView)
//   front    straight in front, looking at the face          front34  45 deg off the front, a little above
//   back     behind and above: the owner's usual game camera  side     from the wearer's right
//   top      high above, looking down                         far      130 studs away (LOD / silhouette check)
//   closeup  15 studs from the body                           orbit:AZ,EL,DIST[,TARGETY]  any angle (degrees, studs)
//   studio   the camera of the real pass-4 Studio captures     subject:F,R,U,ZOOM  Roblox's Custom camera (see below)
// Roblox's default FieldOfView (70, vertical) is used for the presets.
import * as THREE from 'three';
import { cfPos, cfAxis, cfLook } from 'preview/rbx.js';

export const PRESETS = {
	front: { az: 0, el: 8, d: 46, ty: 5 },
	front34: { az: 45, el: 12, d: 48, ty: 5 },
	back: { az: 180, el: 14, d: 36, ty: 4.5 },
	side: { az: 90, el: 6, d: 46, ty: 5 },
	top: { az: 25, el: 62, d: 56, ty: 2 },
	far: { az: 30, el: 7, d: 130, ty: 6 },
	closeup: { az: 18, el: 4, d: 15, ty: 1.5 },
};
// Roblox's own Custom camera, as the Mac session set it up for the real pass-4 Studio captures (032409 day, 032418 night,
// 032533 reveal): CameraSubject focus = HumanoidRootPart + (0, 1.5, 0), Camera Min/MaxZoomDistance = 40, and the camera
// CFrame set once to look from front * 38 + right * 8 + up * 1. (tools/harness/run_aura.py --camera studio is the same.)
export const SUBJECT_PRESETS = { studio: { f: 38, r: 8, u: 1, zoom: 40 } };
export const DEFAULT_VIEWS = ['cam', 'front34', 'back', 'side', 'top', 'far'];

export function wearerFrame(snapshot) {
	const w = snapshot.wearer || {};
	const cf = w.cf || [0, 3, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1];
	const body = cfPos(cf).add(new THREE.Vector3(0, w.hover || 0, 0));
	const look = cfLook(cf); look.y = 0;
	if (look.lengthSq() < 1e-6) look.set(0, 0, -1);
	look.normalize();
	const right = new THREE.Vector3().crossVectors(look, new THREE.Vector3(0, 1, 0)).normalize();
	return { body, look, right };
}

// -> { position, target, up, fov, name }
export function viewCamera(name, snapshot) {
	const { body, look, right } = wearerFrame(snapshot);
	if (name === 'cam') {
		const c = snapshot.camera;
		if (!c || !c.cf) return viewCamera('back', snapshot);
		const pos = cfPos(c.cf);
		return { name, position: pos, target: pos.clone().add(cfLook(c.cf).multiplyScalar(10)), up: cfAxis(c.cf, 1), fov: c.fov || 70 };
	}
	const sp = SUBJECT_PRESETS[name] || (name.startsWith('subject:') ? (([f, r, u, zoom]) => ({ f, r, u, zoom }))(name.slice(8).split(',').map(Number)) : null);
	if (sp) {
		const w = snapshot.wearer || {};
		const focus = cfPos(w.cf || [0, 3, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]).add(new THREE.Vector3(0, 1.5, 0));
		const dir = look.clone().multiplyScalar(sp.f).addScaledVector(right, sp.r).add(new THREE.Vector3(0, sp.u, 0)).normalize();
		return { name, position: focus.clone().addScaledVector(dir, sp.zoom), target: focus, up: new THREE.Vector3(0, 1, 0), fov: 70 };
	}
	let p = PRESETS[name];
	if (!p && name.startsWith('orbit:')) {
		const [az, el, d, ty] = name.slice(6).split(',').map(Number);
		p = { az: az || 0, el: el || 0, d: d || 40, ty: Number.isFinite(ty) ? ty : 4 };
	}
	if (!p) throw new Error(`unknown view "${name}" (try ${Object.keys(PRESETS).join(', ')}, studio, cam, orbit:AZ,EL,DIST, subject:F,R,U,ZOOM)`);
	const az = THREE.MathUtils.degToRad(p.az), el = THREE.MathUtils.degToRad(p.el);
	const horiz = look.clone().multiplyScalar(Math.cos(az)).addScaledVector(right, Math.sin(az));
	const dir = horiz.multiplyScalar(Math.cos(el)).add(new THREE.Vector3(0, Math.sin(el), 0));
	const target = body.clone().add(new THREE.Vector3(0, p.ty, 0));
	return { name, position: target.clone().addScaledVector(dir, p.d), target, up: new THREE.Vector3(0, 1, 0), fov: 70 };
}
