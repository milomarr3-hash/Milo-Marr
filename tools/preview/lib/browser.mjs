// Headless Chromium (Playwright) with WebGL through SwiftShader, serving the preview page, three.js and texture files from
// disk through request interception (no server, nothing leaves the machine).
import fs from 'node:fs';
import path from 'node:path';
import { PREVIEW_DIR } from './textures.mjs';

const TYPES = { '.js': 'text/javascript', '.mjs': 'text/javascript', '.html': 'text/html', '.png': 'image/png', '.jpg': 'image/jpeg', '.json': 'application/json' };
export const ORIGIN = 'http://preview.local';

function findChromium() {
	const roots = [process.env.PLAYWRIGHT_BROWSERS_PATH, '/opt/pw-browsers'].filter(Boolean);
	for (const r of roots) {
		if (!fs.existsSync(r)) continue;
		for (const d of fs.readdirSync(r).sort().reverse()) {
			for (const exe of ['chrome-linux/chrome', 'chrome-linux/headless_shell']) {
				const p = path.join(r, d, exe);
				if (d.startsWith('chromium') && fs.existsSync(p)) return p;
			}
		}
	}
	return null;
}

export async function openPreviewPage({ verbose = false } = {}) {
	const { chromium } = await import('playwright');
	const args = ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--enable-webgl', '--disable-gpu-sandbox'];
	let browser;
	try {
		browser = await chromium.launch({ args });
	} catch (e) {
		const exe = findChromium();
		if (!exe) throw e;
		browser = await chromium.launch({ args, executablePath: exe });
	}
	const page = await browser.newPage({ viewport: { width: 640, height: 360 } });
	const files = []; // /fs/<n> -> absolute path (texture files)
	page.on('console', (m) => { if (verbose || m.type() === 'error') console.log(`[page ${m.type()}] ${m.text()}`); });
	page.on('pageerror', (e) => console.error('[page error]', e.message));
	await page.route(ORIGIN + '/**', async (route) => {
		const url = new URL(route.request().url());
		// /web and /three serve only inside their folders; /fs/<n> serves only files the renderer registered (textures)
		let file = null;
		const inside = (base, rel) => { const f = path.resolve(base, '.' + path.posix.normalize('/' + decodeURIComponent(rel))); return f.startsWith(base + path.sep) ? f : null; };
		if (url.pathname.startsWith('/web/')) file = inside(path.join(PREVIEW_DIR, 'web'), url.pathname.slice(5));
		else if (url.pathname.startsWith('/three/')) file = inside(path.join(PREVIEW_DIR, 'node_modules', 'three'), url.pathname.slice(7));
		else if (url.pathname.startsWith('/fs/')) file = files[Number(url.pathname.slice(4))] || null;
		if (!file || !fs.existsSync(file)) return route.fulfill({ status: 404, body: 'not found' });
		return route.fulfill({ status: 200, contentType: TYPES[path.extname(file)] || 'application/octet-stream', body: fs.readFileSync(file) });
	});
	await page.goto(ORIGIN + '/web/page.html');
	await page.waitForFunction(() => window.PREVIEW_READY === true, null, { timeout: 30000 });
	const urlFor = (absFile) => {
		let i = files.indexOf(absFile);
		if (i < 0) { files.push(absFile); i = files.length - 1; }
		return `${ORIGIN}/fs/${i}`;
	};
	return { browser, page, urlFor };
}
