// Snapshot JSON (tools/harness/SNAPSHOT.md) -> a three.js scene that looks as close as practical to Roblox Studio.
// Used by the headless renderer (render.mjs -> page.html) and by the interactive viewer (viewer.html).
import * as THREE from 'three';
import { Environment, dayFactor } from 'preview/env.js';
import { buildParts, buildCharacters, buildMannequin } from 'preview/parts.js';
import { buildGuis } from 'preview/guis.js';
import { buildBeams, buildTrails } from 'preview/ribbons.js';
import { buildEmitters } from 'preview/particles.js';
import { Post, effectOptions, highlightOptions } from 'preview/post.js';
import { viewCamera, wearerFrame, DEFAULT_VIEWS } from 'preview/views.js';
import { cfPos, srgb } from 'preview/rbx.js';

export { DEFAULT_VIEWS };

// Tone curves. "filmic" (default) is the Narkowicz ACES fit: calibrated against the real Studio captures of pass 4, Roblox's
// curve behaves like it (the day/night colour ratios of sand, grass and leaves only agree once its shoulder is undone).
// "neutral" is Khronos PBR Neutral (keeps hues; the renderer's first calibration).
THREE.ShaderChunk.tonemapping_pars_fragment = THREE.ShaderChunk.tonemapping_pars_fragment.replace(
	'vec3 CustomToneMapping( vec3 color ) { return color; }',
	`vec3 CustomToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	return clamp( ( color * ( 2.51 * color + 0.03 ) ) / ( color * ( 2.43 * color + 0.59 ) + 0.14 ), 0.0, 1.0 );
}`);
export const TONE = { filmic: THREE.CustomToneMapping, neutral: THREE.NeutralToneMapping };

function disposeTree(o) {
	o.traverse((x) => {
		if (x.geometry && !x.geometry.userData.shared) x.geometry.dispose?.();
		const ms = Array.isArray(x.material) ? x.material : x.material ? [x.material] : [];
		for (const m of ms) m.dispose?.();
	});
}

export class Preview {
	constructor(canvas, { width = 1280, height = 720 } = {}) {
		this.canvas = canvas;
		this.renderer = new THREE.WebGLRenderer({ canvas, antialias: false, preserveDrawingBuffer: true, alpha: false, powerPreference: 'high-performance' });
		this.renderer.setPixelRatio(1);
		this.renderer.setSize(width, height, false);
		this.renderer.toneMapping = THREE.NeutralToneMapping;
		this.renderer.toneMappingExposure = 1;
		this.renderer.outputColorSpace = THREE.SRGBColorSpace;
		this.renderer.shadowMap.enabled = true;
		this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
		this.env = new Environment(this.renderer);
		this.post = new Post(this.renderer, width, height);
		this.scene = new THREE.Scene();
		this.scene.add(this.env.group);
		this.env.group.traverse((o) => { if (o.isMesh && o !== this.env.sky) o.layers.enable(1); });
		this.camera = new THREE.PerspectiveCamera(70, width / height, 0.1, 20000);
		this.textures = new Map(); // key (the string in the snapshot) -> { clamp, repeatU }
		this.loader = new THREE.TextureLoader();
		this.warnings = [];
		this.warned = new Set();
		this.aura = null;
		this.size = [width, height];
		this.blank = new THREE.DataTexture(new Uint8Array([255, 255, 255, 255]), 1, 1);
		this.blank.needsUpdate = true;
	}

	warn(msg, key) {
		const k = key || msg;
		if (this.warned.has(k)) return;
		this.warned.add(k);
		this.warnings.push(msg);
	}

	setSize(w, h) {
		this.size = [w, h];
		this.renderer.setSize(w, h, false);
		this.post.setSize(w, h);
		this.camera.aspect = w / h;
		this.camera.updateProjectionMatrix();
	}

	// urls: { key: url } for every texture string in the snapshot; unknown keys should already map to a stand-in
	async loadTextures(urls) {
		const jobs = [];
		for (const [key, url] of Object.entries(urls)) {
			if (this.textures.has(key) && this.textures.get(key).url === url) continue;
			jobs.push(this.loader.loadAsync(url).then((t) => {
				t.colorSpace = THREE.SRGBColorSpace;
				t.anisotropy = 8;
				t.wrapS = t.wrapT = THREE.ClampToEdgeWrapping;
				const r = t.clone();
				r.wrapS = THREE.RepeatWrapping;
				r.needsUpdate = true;
				this.textures.set(key, { url, clamp: t, repeatU: r });
			}).catch(() => this.warn(`texture ${key} failed to load (${url})`)));
		}
		await Promise.all(jobs);
	}

	tex(key, mode = 'clamp') {
		const e = this.textures.get(key) || this.textures.get('__unknown__');
		if (!e) return this.blank;
		if (!this.textures.has(key)) this.warn(`texture "${key}" has no image: drawn as a neutral soft dot`, 'tex:' + key);
		return e[mode] || e.clamp;
	}

	// build the scene for one snapshot. opts: { env: 'auto'|'day'|'night', clock, props, maxPerEmitter }
	build(snapshot, opts = {}) {
		if (this.aura) { this.scene.remove(this.aura); disposeTree(this.aura); }
		this.warnings = []; this.warned = new Set();
		this.snapshot = snapshot;
		const aura = new THREE.Group();
		aura.name = 'aura';
		this.aura = aura;
		this.renderer.toneMapping = TONE[opts.tone || 'filmic'] ?? THREE.CustomToneMapping;
		this.env.tone = opts.tone || 'filmic';
		const clock = opts.clock != null ? opts.clock : (snapshot.clockTime ?? 14);
		const { body } = wearerFrame(snapshot);
		const groundY = snapshot.wearer && snapshot.wearer.ground ? snapshot.wearer.ground[1] : 0;
		const st = this.env.apply({ mode: opts.env || 'auto', clockTime: clock, focus: body, groundY, props: opts.props !== false });
		this.envState = st;
		this.scene.environment = this.env.envMap;
		this.scene.environmentIntensity = this.env.envIntensity;
		this.scene.fog = this.env.fog;

		const atts = new Map((snapshot.attachments || []).map((a) => [a.id, a]));
		const self = this;
		let partsRes;
		const keyDir = st.isDay ? st.sunDir : st.moonDir;
		const ctx = {
			warn: (m, k) => self.warn(m, k),
			tex: (k, mode) => (k ? self.tex(k, mode) : self.tex('__unknown__', mode)),
			partById: (id) => (id == null ? null : partsRes.byId.get(id)),
			attById: (id) => (id == null ? null : atts.get(id) || null),
			parts: () => partsRes.byId.values(),
			lightAt: (n) => self.env.light * (n ? 0.65 + 0.45 * Math.max(0, n.dot(keyDir)) : 1),
		};
		const inWorld = snapshot.auraInWorld !== false;
		partsRes = buildParts(inWorld ? snapshot : { ...snapshot, parts: [] }, ctx);
		aura.add(partsRes.group);
		const chars = snapshot.characters && snapshot.characters.length ? buildCharacters(snapshot)
			: snapshot.wearer && snapshot.wearer.cf ? buildMannequin(snapshot.wearer) : new THREE.Group();
		aura.add(chars);
		this.dynamic = [];
		if (inWorld) {
			const guis = buildGuis(snapshot, ctx); aura.add(guis.group); this.dynamic.push(guis.update);
			const beams = buildBeams(snapshot, ctx); aura.add(beams.group); this.dynamic.push(beams.update);
			const trails = buildTrails(snapshot, ctx); aura.add(trails.group); this.dynamic.push(trails.update);
			const em = buildEmitters(snapshot, ctx, { maxPerEmitter: opts.maxPerEmitter }); aura.add(em.group); this.dynamic.push(em.update);
			this.particleCount = em.total;
			for (const l of snapshot.lights || []) {
				if (l.enabled === false) continue;
				const host = l.hostAttachmentId != null ? atts.get(l.hostAttachmentId) : null;
				const rec = host ? null : partsRes.byId.get(l.hostId);
				const pos = host ? cfPos(host.worldCf) : rec ? new THREE.Vector3().setFromMatrixPosition(rec.matrix) : null;
				if (!pos) continue;
				// Roblox lights fade smoothly to nothing at Range; Brightness ~ how strongly they light what is near
				const light = new THREE.PointLight(srgb(l.color), (l.brightness ?? 1) * 2.4, l.range || 8, 0);
				light.position.copy(pos);
				if (l.class !== 'PointLight') this.warn(`${l.class} drawn as a PointLight`, 'light:' + l.class);
				aura.add(light);
			}
		} else this.particleCount = 0;
		// layers: 1 = opaque things that hide a Highlight (DepthMode Occluded); 2.. = each Highlight's adornee
		aura.traverse((o) => { if (o.isMesh && o.userData.opaque) o.layers.enable(1); });
		const hls = (snapshot.highlights || []).filter((h) => h.enabled !== false);
		let li = 0;
		this.highlights = highlightOptions(inWorld ? snapshot : { highlights: [] }, (h) => {
			if (li >= 29) return null;
			const layer = 2 + li++;
			const ap = h.adorneePath || '';
			let n = 0;
			partsRes.group.traverse((o) => {
				if (!o.isMesh || o.userData.partId == null) return;
				const p = partsRes.byId.get(o.userData.partId).p;
				if (p.path === ap || p.path.startsWith(ap + '.') || (h.adorneeId != null && p.id === h.adorneeId)) { o.layers.enable(layer); n++; }
			});
			if (!n) this.warn(`Highlight ${h.path}: nothing visible under ${ap}`);
			return layer;
		});
		if (hls.length > 31) this.warn(`${hls.length} Highlights: Roblox draws at most 31 per client`);
		const fx = effectOptions(snapshot, (m, k) => this.warn(m, k));
		if (this.env.nightGrade > 0.01) { // Roblox nights read grey: mild desaturation on top of any ColorCorrection
			fx.cc = fx.cc || { brightness: 0, contrast: 0, saturation: 0, tint: [1, 1, 1] };
			fx.cc.saturation -= this.env.nightGrade;
		}
		this.fx = fx;
		// reflections: every lit material gets the sky map explicitly, so metal keeps strong reflections while the sky's
		// diffuse light stays modest (scene.environmentIntensity would scale both)
		const envMap = this.env.envMap, day = st.isDay;
		aura.traverse((o) => {
			const ms = Array.isArray(o.material) ? o.material : o.material ? [o.material] : [];
			for (const m of ms) {
				if (!m.isMeshStandardMaterial) continue;
				m.envMap = envMap;
				const shiny = m.metalness > 0.3;
				m.envMapIntensity = (shiny ? 1.0 : this.env.envIntensity) * (m.userData.envBoost || 1);
				m.needsUpdate = true;
			}
		});
		const hide = new Set(opts.hide || []);
		for (const g of aura.children) if (hide.has(g.name)) g.visible = false;
		if (hide.has('lights')) aura.children.forEach((o) => { if (o.isLight) o.visible = false; });
		this.env.props.visible = opts.props !== false && !hide.has('env');
		this.scene.add(aura);
		return { warnings: this.warnings, particles: this.particleCount, day: st.isDay };
	}

	// render one view into the canvas. view: preset name or { position, target, up, fov }
	renderView(view, { bloom = true } = {}) {
		const v = typeof view === 'string' ? viewCamera(view, this.snapshot) : view;
		const cam = this.camera;
		cam.fov = v.fov || 70;
		cam.aspect = this.size[0] / this.size[1];
		cam.position.copy(v.position);
		cam.up.copy(v.up || new THREE.Vector3(0, 1, 0));
		cam.lookAt(v.target);
		cam.updateProjectionMatrix();
		cam.updateMatrixWorld();
		this.env.clearLineOfSight(cam.position, v.target);
		for (const f of this.dynamic) f(cam);
		this.post.render(this.scene, cam, { bloom: bloom ? this.fx.bloom : null, highlights: this.highlights, cc: this.fx.cc });
		return v;
	}
}

// render with this.camera as it is (the viewer's orbit controls move it)
Preview.prototype.renderCurrent = function ({ bloom = true, target = null } = {}) {
	const cam = this.camera;
	if (target) this.env.clearLineOfSight(cam.position, target);
	cam.aspect = this.size[0] / this.size[1];
	cam.updateProjectionMatrix();
	cam.updateMatrixWorld();
	for (const f of this.dynamic) f(cam);
	this.post.render(this.scene, cam, { bloom: bloom ? this.fx.bloom : null, highlights: this.highlights, cc: this.fx.cc });
};

// -------------------------------------------------------------------------------------------------- headless entry
// labels + a contact sheet are drawn with a 2D canvas over the WebGL output
export function caption(snapshot, view, st, quality) {
	const ct = st.clockTime, hh = Math.floor(ct), mm = Math.round((ct - hh) * 60);
	const clock = `${String(hh).padStart(2, '0')}:${String(mm % 60).padStart(2, '0')}`;
	return `${snapshot.scenario || 'snapshot'}  f${snapshot.frame ?? '?'}  t=${(snapshot.t ?? 0).toFixed(2)}s  |  ${view}  |  ${st.isDay ? 'day' : 'night'} ${clock}  |  ${quality || snapshot.quality || 'high'}`;
}

export function drawLabel(ctx2d, text, w) {
	ctx2d.font = `${Math.max(12, Math.round(w / 90))}px "Liberation Sans", Arial, sans-serif`;
	const pad = 6, tw = ctx2d.measureText(text).width, th = Math.max(12, Math.round(w / 90)) + 8;
	ctx2d.fillStyle = 'rgba(0,0,0,0.55)';
	ctx2d.fillRect(8, 8, tw + pad * 2, th);
	ctx2d.fillStyle = '#fff';
	ctx2d.textBaseline = 'middle';
	ctx2d.fillText(text, 8 + pad, 8 + th / 2 + 1);
}

export function dayOf(clockTime) { return dayFactor(clockTime) >= 0.5; }
