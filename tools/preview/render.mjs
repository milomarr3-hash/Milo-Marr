#!/usr/bin/env node
// Aura preview renderer: harness snapshot JSON -> PNG renders that look as close as practical to Roblox Studio.
//
//   node tools/preview/render.mjs --snapshot FILE_OR_DIR [--snapshot ...] [--views cam,studio,front34,back,side,top,far,closeup]
//        [--env auto|day|night] [--clock HOURS] [--out DIR] [--size 1280x720|game] [--ss 1|2] [--props on|off]
//        [--labels on|off] [--sheet on|off] [--bloom on|off] [--max-particles N] [--tex5 DIR | --no-tex5]
//        [--texmap FILE] [--hide parts,guis,beams,trails,particles,lights,characters,env] [--tone filmic|neutral] [--verbose]
//
// A directory renders every *.json under it (e.g. a harness run's snapshots/ folder). Output: OUT/<scenario>_f<frame>_<view>.png
// plus OUT/<scenario>_f<frame>_sheet.png (all views on one page). See tools/preview/README.md.
import fs from 'node:fs';
import path from 'node:path';
import { TextureResolver, textureStrings, PREVIEW_DIR, REPO_DIR } from './lib/textures.mjs';
import { openPreviewPage } from './lib/browser.mjs';

const DEFAULT_VIEWS = 'cam,front34,back,side,top,far';

function parseArgs(argv) {
	const a = { snapshots: [], views: DEFAULT_VIEWS, env: 'auto', clock: null, out: path.join(PREVIEW_DIR, 'out'), size: '1280x720', ss: 1,
		props: true, labels: true, sheet: true, bloom: true, maxParticles: 6000, hide: '', tex5: path.join(REPO_DIR, 'textures', 'te5'), texmap: null, verbose: false };
	const onoff = (v) => !/^(off|false|0|no)$/i.test(v);
	for (let i = 0; i < argv.length; i++) {
		const k = argv[i], v = () => { if (i + 1 >= argv.length) throw new Error(`${k} needs a value`); return argv[++i]; };
		switch (k) {
			case '--snapshot': case '-s': a.snapshots.push(v()); break;
			case '--views': a.views = v(); break;
			case '--env': a.env = v(); break;
			case '--clock': a.clock = Number(v()); break;
			case '--out': case '-o': a.out = v(); break;
			case '--size': a.size = v(); break;
			case '--ss': a.ss = Number(v()); break;
			case '--props': a.props = onoff(v()); break;
			case '--labels': a.labels = onoff(v()); break;
			case '--sheet': a.sheet = onoff(v()); break;
			case '--bloom': a.bloom = onoff(v()); break;
			case '--max-particles': a.maxParticles = Number(v()); break;
			case '--hide': a.hide = v(); break;
			case '--tone': a.tone = v(); break;
			case '--tex5': a.tex5 = v(); break;
			case '--no-tex5': a.tex5 = null; break;
			case '--texmap': a.texmap = v(); break;
			case '--verbose': case '-v': a.verbose = true; break;
			case '--help': case '-h': a.help = true; break;
			default:
				if (k.endsWith('.json') && !k.startsWith('-')) a.snapshots.push(k);
				else throw new Error(`unknown option ${k}`);
		}
	}
	if (!['auto', 'day', 'night'].includes(a.env)) throw new Error('--env must be auto, day or night');
	if (a.size !== 'game') {
		const m = /^(\d+)x(\d+)$/.exec(a.size);
		if (!m) throw new Error('--size must look like 1280x720 (or "game": 1280 wide at the snapshot viewport\'s aspect)');
		a.wh = [Number(m[1]), Number(m[2])];
	}
	return a;
}

// --size game: 1280 wide at the aspect of the client viewport the harness recorded (Studio's 1920x913 by default)
function gameSize(snap) {
	const vp = (snap.camera && snap.camera.viewport) || [1920, 913];
	return [1280, Math.round((1280 * vp[1]) / vp[0] / 2) * 2];
}

function listSnapshots(inputs) {
	const out = [];
	const walk = (p) => {
		const st = fs.statSync(p);
		if (st.isDirectory()) for (const f of fs.readdirSync(p).sort()) walk(path.join(p, f));
		else if (p.endsWith('.json')) out.push(p);
	};
	for (const i of inputs) walk(i);
	return out;
}

async function main() {
	const args = parseArgs(process.argv.slice(2));
	if (args.help || !args.snapshots.length) {
		const lines = fs.readFileSync(new URL(import.meta.url), 'utf8').split('\n').slice(1);
		console.log(lines.slice(0, lines.findIndex((l) => !l.startsWith('//'))).map((l) => l.replace(/^\/\/ ?/, '')).join('\n'));
		process.exit(args.help ? 0 : 2);
	}
	const files = listSnapshots(args.snapshots);
	if (!files.length) throw new Error('no snapshot .json files found');
	const resolver = new TextureResolver({ texmapPath: args.texmap || undefined, te5Dir: args.tex5 || undefined, useTe5: !!args.tex5 });
	if (resolver.te5.length) console.log(`te5: ${resolver.te5.length} textures from manifests in ${path.relative(process.cwd(), args.tex5)}`);
	fs.mkdirSync(args.out, { recursive: true });
	const views = args.views.split(/,(?=\s*[a-zA-Z])/).map((s) => s.trim()).filter(Boolean); // (orbit:AZ,EL,DIST keeps its commas)
	const t0 = Date.now();
	const { browser, page, urlFor } = await openPreviewPage({ verbose: args.verbose });
	let failures = 0;
	try {
		for (const f of files) {
			const snap = JSON.parse(fs.readFileSync(f, 'utf8'));
			const textures = { __unknown__: urlFor(resolver.unknown) };
			const texWarn = [];
			for (const s of textureStrings(snap)) {
				const r = resolver.resolve(s);
				textures[s] = urlFor(r.file);
				if (r.warning) texWarn.push(r.warning);
			}
			const base = (snap.scenario ? `${snap.scenario}_f${String(snap.frame ?? 0).padStart(5, '0')}` : path.basename(f, '.json')).replace(/[^\w@.=-]+/g, '_');
			const t1 = Date.now();
			let res;
			try {
				res = await page.evaluate((a) => window.PREVIEW.render(a), {
					snapshot: snap, textures, views, env: args.env, clock: args.clock, size: args.wh || gameSize(snap), ss: args.ss, props: args.props,
					labels: args.labels, sheet: args.sheet, maxPerEmitter: args.maxParticles, bloom: args.bloom,
					hide: args.hide.split(',').map((x) => x.trim()).filter(Boolean), tone: args.tone,
				});
			} catch (e) {
				failures++;
				console.error(`${path.relative(process.cwd(), f)}: render failed: ${e.message}`);
				continue;
			}
			const written = [];
			for (const im of res.images) {
				const name = typeof im.view === 'string' ? im.view : 'view';
				const out = path.join(args.out, `${base}_${name.replace(/[^\w.-]+/g, '_')}.png`);
				fs.writeFileSync(out, Buffer.from(im.png.split(',')[1], 'base64'));
				written.push(out);
			}
			if (res.sheet) {
				const out = path.join(args.out, `${base}_sheet.png`);
				fs.writeFileSync(out, Buffer.from(res.sheet.split(',')[1], 'base64'));
				written.push(out);
			}
			console.log(`${path.relative(process.cwd(), f)} -> ${written.length} png in ${((Date.now() - t1) / 1000).toFixed(1)}s (${res.particles} particles)`);
			for (const w of [...new Set(texWarn)]) console.log(`  warning: ${w}`);
			for (const w of res.warnings) console.log(`  warning: ${w}`);
		}
	} finally {
		await browser.close();
	}
	console.log(`done: ${files.length} snapshot(s) in ${((Date.now() - t0) / 1000).toFixed(1)}s -> ${path.relative(process.cwd(), args.out) || '.'}`);
	process.exit(failures ? 1 : 0);
}

main().catch((e) => { console.error(e.message); process.exit(2); });
