// Texture strings in a snapshot -> local PNG files.
// Order: texmap.json "strings" (exact string) -> "pending:<texKey>" / "te5:<name>" (te5 manifests, else the pass-4 fallback)
// -> the asset id's digits in texmap.json "ids" or in a te5 manifest entry's id -> the neutral soft dot (with a warning).
import fs from 'node:fs';
import path from 'node:path';

const HERE = path.dirname(new URL(import.meta.url).pathname);
export const PREVIEW_DIR = path.resolve(HERE, '..');
export const REPO_DIR = path.resolve(PREVIEW_DIR, '..', '..');

// every texture string a snapshot refers to
export function textureStrings(snap) {
	const s = new Set();
	const add = (v) => { if (typeof v === 'string' && v.trim()) s.add(v); };
	for (const p of snap.parts || []) for (const d of p.decals || []) add(d.texture);
	for (const b of snap.beams || []) add(b.texture);
	for (const t of snap.trails || []) add(t.texture);
	for (const g of snap.guis || []) for (const im of g.images || []) add(im.image);
	for (const e of snap.emitters || []) add(e.texture);
	return [...s];
}

// te5 manifests: textures/te5/<group>/manifest.json (an array of entries, or an object holding one; entries carry
// name, file, texKey and maybe id / assetId / uploaded)
export function readTe5(dir) {
	const out = [];
	if (!dir || !fs.existsSync(dir)) return out;
	for (const g of fs.readdirSync(dir)) {
		const mf = path.join(dir, g, 'manifest.json');
		if (!fs.existsSync(mf)) continue;
		let m;
		try { m = JSON.parse(fs.readFileSync(mf, 'utf8')); } catch (e) { console.warn(`te5: cannot parse ${mf}: ${e.message}`); continue; }
		let entries = Array.isArray(m) ? m : null;
		if (!entries) for (const v of Object.values(m)) if (Array.isArray(v) && v.length && typeof v[0] === 'object' && v[0].file) { entries = v; break; }
		if (!entries && typeof m === 'object') entries = Object.entries(m).filter(([, v]) => v && typeof v === 'object' && v.file).map(([k, v]) => ({ name: k, ...v }));
		for (const e of entries || []) {
			if (!e || !e.file) continue;
			const file = path.resolve(path.join(dir, g), e.file);
			const id = String(e.id || e.assetId || e.uploaded || e.rbxassetid || '').replace(/\D/g, '');
			out.push({ name: e.name || path.basename(e.file, '.png'), texKey: e.texKey || null, file, id: id || null, group: g });
		}
	}
	return out;
}

export class TextureResolver {
	constructor({ texmapPath = path.join(PREVIEW_DIR, 'texmap.json'), te5Dir = path.join(REPO_DIR, 'textures', 'te5'), useTe5 = true } = {}) {
		this.base = path.dirname(texmapPath);
		this.map = JSON.parse(fs.readFileSync(texmapPath, 'utf8'));
		this.te5 = useTe5 ? readTe5(te5Dir) : [];
		this.unknown = path.resolve(this.base, this.map.unknown || 'standins/unknown.png');
	}
	file(rel) { return path.resolve(this.base, rel); }
	byId(digits) {
		if (this.map.ids && this.map.ids[digits]) return { file: this.file(this.map.ids[digits]), how: 'id' };
		const t = this.te5.find((e) => e.id === digits);
		if (t) return { file: t.file, how: 'te5 id' };
		return null;
	}
	// -> { file, how, warning? }
	resolve(str) {
		const s = String(str).trim();
		if (this.map.strings && this.map.strings[s]) return { file: this.file(this.map.strings[s]), how: 'string' };
		let m = /^pending:(.+)$/.exec(s) || /^te5:(.+)$/.exec(s);
		if (m) {
			const key = m[1];
			const t = this.te5.find((e) => e.texKey === key) || this.te5.find((e) => e.name === key || e.name === 'te5_' + key);
			if (t && fs.existsSync(t.file)) return { file: t.file, how: 'te5' };
			const fb = (this.map.pendingFallback || {})[key];
			const id = fb && (this.map.names || {})[fb];
			if (id && this.map.ids[id]) return { file: this.file(this.map.ids[id]), how: 'fallback', warning: `te5 texture "${key}" not found: using its pass-4 fallback "${fb}"` };
			return { file: this.unknown, how: 'unknown', warning: `te5 texture "${key}" not found and has no fallback` };
		}
		m = /(\d{5,})/.exec(s);
		if (m) {
			const r = this.byId(m[1]);
			if (r && fs.existsSync(r.file)) return r;
			if (r) return { file: this.unknown, how: 'unknown', warning: `texture ${s} maps to a missing file ${path.relative(REPO_DIR, r.file)}` };
		}
		return { file: this.unknown, how: 'unknown', warning: `unknown texture ${s}: drawn as a neutral soft dot` };
	}
}
