#!/usr/bin/env node
// Smoke test: renders the fixtures headless and probes pixels where known things must appear, so a change that flips a
// convention (face mapping, Neon glow, day/night) fails loudly. Run: node tools/preview/test/smoke.mjs
import fs from 'node:fs';
import path from 'node:path';
import { TextureResolver, textureStrings, PREVIEW_DIR } from '../lib/textures.mjs';
import { openPreviewPage } from '../lib/browser.mjs';

const FIX = path.join(PREVIEW_DIR, 'fixtures');
const resolver = new TextureResolver({ useTe5: false });
const { browser, page, urlFor } = await openPreviewPage();
let failed = 0;
const check = (name, ok, detail) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}${detail ? '  ' + detail : ''}`); if (!ok) failed++; };
const lum = (c) => 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];

async function render(file, views, extra = {}) {
	const snap = JSON.parse(fs.readFileSync(path.join(FIX, file), 'utf8'));
	const textures = { __unknown__: urlFor(resolver.unknown) };
	for (const s of textureStrings(snap)) textures[s] = urlFor(resolver.resolve(s).file);
	const res = await page.evaluate((a) => window.PREVIEW.render(a), { snapshot: snap, textures, views, env: 'auto', size: [640, 360], labels: false, sheet: false, ...extra });
	return res;
}
const probe = (i, pts) => page.evaluate(([i, pts]) => window.PREVIEW.probe(i, pts), [i, pts]);

try {
	// day: the snapshot camera looks from -Z toward +Z, so the cube's Front (-Z) label faces it; the 'back' preset sees Back (+Z)
	let r = await render('all_elements.json', ['cam', 'back', 'top']);
	check('day fixture renders', r.images.length === 3, `${r.particles} particles, ${r.warnings.length} warnings`);
	let [front, neon, sky] = await probe(0, [[-10, 3.2, -10.02], [-6.6 + 3, 2.2, 6], [0, 60, 200]]);
	check('FaceCube Front face is blue (FRONT = -Z)', front.rgb && front.rgb[2] > front.rgb[0] + 60, JSON.stringify(front.rgb));
	// (Studio's day sky is cyan-blue, ~(117, 189, 204), under grey-white cumulus: at least one probe must hit clear sky)
	const daySky = (await probe(0, [[-200, 60, 200], [-100, 60, 200], [0, 60, 200], [100, 60, 200], [200, 60, 200], [0, 120, 200]])).filter((p) => p.rgb);
	check('day sky is cyan-blue', daySky.some((p) => p.rgb[2] > 150 && p.rgb[2] > p.rgb[0] + 50), JSON.stringify(daySky.map((p) => p.rgb)));
	let [back] = await probe(1, [[-10, 3.2, -5.98]]);
	check('FaceCube Back face is red (BACK = +Z)', back.rgb && back.rgb[0] > back.rgb[2] + 60, JSON.stringify(back.rgb));
	let [top] = await probe(2, [[-10, 5.01, -8]]);
	check('FaceCube Top face is green', top.rgb && top.rgb[1] > top.rgb[0] + 30 && top.rgb[1] > top.rgb[2] + 20, JSON.stringify(top.rgb));
	// the white Neon ball glows (near white at its centre), the black Neon ball stays dark
	const balls = JSON.parse(fs.readFileSync(path.join(FIX, 'all_elements.json'), 'utf8')).parts.filter((p) => p.material === 'Neon');
	const nb = await probe(1, balls.map((p) => [p.cf[0], p.cf[1], p.cf[2]]));
	check('white Neon glows', nb[0].rgb && lum(nb[0].rgb) > 235, JSON.stringify(nb[0].rgb));
	check('black Neon stays dark (bloom from the white one spills a little)', nb[1].rgb && lum(nb[1].rgb) < 70, JSON.stringify(nb[1].rgb));
	// night: dark sky, the GUI labels stay as bright as by day (LightInfluence 0)
	r = await render('all_elements_night.json', ['cam']);
	// (Studio's night clouds are lit grey, ~120-150: the gaps between them are black, and nothing in the sky is white)
	const nightSky = await probe(0, [[-200, 60, 200], [-100, 60, 200], [0, 60, 200], [100, 60, 200], [200, 60, 200], [0, 120, 200]]);
	[front] = await probe(0, [[-10, 3.2, -10.02]]);
	const skyL = nightSky.filter((p) => p.rgb).map((p) => lum(p.rgb));
	check('night sky is dark between grey clouds', skyL.length && Math.min(...skyL) < 60 && Math.max(...skyL) < 200, JSON.stringify(skyL.map(Math.round)));
	check('unlit SurfaceGui keeps its colour at night', front.rgb && front.rgb[2] > 120, JSON.stringify(front.rgb));
	// graded: the ColorCorrection effect desaturates the grass
	r = await render('all_elements_graded.json', ['cam']);
	const [grass] = await probe(0, [[40, 0, 0]]);
	check('ColorCorrection desaturates', grass.rgb && Math.max(...grass.rgb) - Math.min(...grass.rgb) < 60, JSON.stringify(grass.rgb));
} finally {
	await browser.close();
}
console.log(failed ? `${failed} check(s) failed` : 'all checks passed');
process.exit(failed ? 1 : 0);
