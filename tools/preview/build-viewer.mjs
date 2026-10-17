#!/usr/bin/env node
// Builds tools/preview/viewer.html: one self-contained page (snapshots + textures inlined as data, the renderer bundled in)
// that loads three.js from jsDelivr (pinned) and can be published as a web page or opened from disk.
//
//   node tools/preview/build-viewer.mjs --snapshot FILE_OR_DIR [--snapshot ...] [--out tools/preview/viewer.html]
//        [--title "THE END Aura Viewer"] [--max-tex 512] [--start N] [--standalone] [--tex5 DIR | --no-tex5]
//
// --standalone adds <!doctype html> + <html>/<head>/<body> for opening from disk; without it the file is the page
// fragment the artifact publisher wraps itself. Keep it under ~10 MB (textures are downscaled to --max-tex px).
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import * as esbuild from 'esbuild';
import { TextureResolver, textureStrings, PREVIEW_DIR, REPO_DIR } from './lib/textures.mjs';

const THREE_VERSION = JSON.parse(fs.readFileSync(path.join(PREVIEW_DIR, 'node_modules', 'three', 'package.json'), 'utf8')).version;

function parseArgs(argv) {
	const a = { snapshots: [], out: path.join(PREVIEW_DIR, 'viewer.html'), title: 'THE END Aura Viewer', maxTex: 512, start: 0, standalone: false,
		tex5: path.join(REPO_DIR, 'textures', 'te5') };
	for (let i = 0; i < argv.length; i++) {
		const k = argv[i], v = () => argv[++i];
		if (k === '--snapshot' || k === '-s') a.snapshots.push(v());
		else if (k === '--out' || k === '-o') a.out = v();
		else if (k === '--title') a.title = v();
		else if (k === '--max-tex') a.maxTex = Number(v());
		else if (k === '--start') a.start = Number(v());
		else if (k === '--standalone') a.standalone = true;
		else if (k === '--tex5') a.tex5 = v();
		else if (k === '--no-tex5') a.tex5 = null;
		else if (k.endsWith('.json')) a.snapshots.push(k);
		else throw new Error(`unknown option ${k}`);
	}
	return a;
}

function listSnapshots(inputs) {
	const out = [];
	const walk = (p) => { const st = fs.statSync(p); if (st.isDirectory()) for (const f of fs.readdirSync(p).sort()) walk(path.join(p, f)); else if (p.endsWith('.json')) out.push(p); };
	for (const i of inputs) walk(i);
	return out;
}

// numbers to ~5 significant digits keep the JSON small without visible change
const slim = (key, v) => (typeof v === 'number' && !Number.isInteger(v) ? Number(v.toPrecision(6)) : v);

// downscale PNGs (python3 + PIL); falls back to the original bytes
function encodeTextures(files, maxSide) {
	const script = `
import sys, json, io, base64
from PIL import Image
out = {}
for f in json.load(sys.stdin):
    im = Image.open(f).convert("RGBA")
    if max(im.size) > ${maxSide}:
        s = ${maxSide} / max(im.size)
        im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
    b = io.BytesIO(); im.save(b, "PNG", optimize=True)
    out[f] = base64.b64encode(b.getvalue()).decode()
print(json.dumps(out))`;
	try {
		const res = execFileSync('python3', ['-I', '-c', script], { input: JSON.stringify(files), maxBuffer: 256 * 1024 * 1024 });
		return JSON.parse(res.toString());
	} catch (e) {
		console.warn(`python3/PIL unavailable (${e.message.split('\n')[0]}): embedding textures at full size`);
		return Object.fromEntries(files.map((f) => [f, fs.readFileSync(f).toString('base64')]));
	}
}

async function main() {
	const args = parseArgs(process.argv.slice(2));
	const files = listSnapshots(args.snapshots);
	if (!files.length) throw new Error('give at least one --snapshot FILE_OR_DIR');
	const snaps = files.map((f) => JSON.parse(fs.readFileSync(f, 'utf8')));
	const resolver = new TextureResolver({ te5Dir: args.tex5 || undefined, useTe5: !!args.tex5 });
	const keys = [...new Set(snaps.flatMap(textureStrings))];
	const fileOf = {};
	for (const k of keys) { const r = resolver.resolve(k); fileOf[k] = r.file; if (r.warning) console.log(`  warning: ${r.warning}`); }
	const uniq = [...new Set([...Object.values(fileOf), resolver.unknown])];
	const enc = encodeTextures(uniq, args.maxTex);
	const textures = Object.fromEntries(keys.map((k) => [k, `data:image/png;base64,${enc[fileOf[k]]}`]));
	const data = { title: args.title, built: new Date().toISOString().slice(0, 10), start: args.start, snapshots: snaps, textures, unknown: `data:image/png;base64,${enc[resolver.unknown]}` };

	const bundle = await esbuild.build({
		entryPoints: [path.join(PREVIEW_DIR, 'web', 'viewer-app.js')], bundle: true, format: 'esm', write: false, minify: true,
		external: ['three', 'three/addons/*'], alias: { preview: path.join(PREVIEW_DIR, 'web') }, target: 'es2020', legalComments: 'none',
	});
	const app = bundle.outputFiles[0].text;
	const cdn = `https://cdn.jsdelivr.net/npm/three@${THREE_VERSION}`;
	const importmap = JSON.stringify({ imports: { three: `${cdn}/build/three.module.js`, 'three/addons/': `${cdn}/examples/jsm/` } });
	const esc = (s) => s.replace(/</g, '\\u003c');
	let html = fs.readFileSync(path.join(PREVIEW_DIR, 'web', 'viewer.template.html'), 'utf8')
		.replace('__TITLE__', () => args.title.replace(/</g, '&lt;'))
		.replace('__HEADING__', () => args.title.replace(/</g, '&lt;'))
		.replace('__IMPORTMAP__', () => importmap)
		.replace('__DATA__', () => esc(JSON.stringify(data, slim)))
		.replace('__APP__', () => app.replace(/<\/script/gi, '<\\/script'));
	if (args.standalone) {
		const cut = html.indexOf('<div id="app">');
		html = `<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n${html.slice(0, cut)}</head>\n<body>\n${html.slice(cut)}</body>\n</html>\n`;
	}
	fs.writeFileSync(args.out, html);
	const mb = Buffer.byteLength(html) / 1048576;
	console.log(`${path.relative(process.cwd(), args.out)}: ${snaps.length} snapshot(s), ${uniq.length} textures, ${mb.toFixed(2)} MB${mb > 10 ? '  (over 10 MB: lower --max-tex or use fewer snapshots)' : ''}`);
}

main().catch((e) => { console.error(e.message); process.exit(2); });
