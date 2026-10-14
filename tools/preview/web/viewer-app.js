// The interactive viewer (viewer.html): the same renderer as the headless PNGs, with an orbit camera, view presets,
// day/night, a timeline over the embedded snapshots, and drag-and-drop of more snapshot JSON files.
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { Preview } from 'preview/preview.js';
import { viewCamera, wearerFrame } from 'preview/views.js';

const $ = (id) => document.getElementById(id);
const DATA = JSON.parse($('preview-data').textContent);
const snaps = DATA.snapshots.slice();
const state = { i: 0, env: 'auto', bloom: true, particles: true, props: true, playing: false, view: 'front34' };

const canvas = $('view');
const holder = $('stage');
const pv = new Preview(canvas, { width: 800, height: 450 });
const controls = new OrbitControls(pv.camera, canvas);
controls.enableDamping = true;
controls.dampingFactor = 0.12;
controls.maxDistance = 600;
let dirty = true;
controls.addEventListener('change', () => { dirty = true; });

const textures = { ...DATA.textures, __unknown__: DATA.unknown };

function fitSize() {
	const r = holder.getBoundingClientRect();
	const dpr = Math.min(window.devicePixelRatio || 1, 1.5);
	const w = Math.max(64, Math.round(r.width * dpr)), h = Math.max(64, Math.round(r.height * dpr));
	if (w !== pv.size[0] || h !== pv.size[1]) { pv.setSize(w, h); dirty = true; }
}
new ResizeObserver(fitSize).observe(holder);

function clockText(ct) {
	const h = Math.floor(ct), m = Math.round((ct - h) * 60) % 60;
	return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

function setView(name) {
	state.view = name;
	const v = viewCamera(name, snaps[state.i]);
	pv.camera.position.copy(v.position);
	pv.camera.up.set(0, 1, 0);
	pv.camera.fov = v.fov;
	controls.target.copy(v.target);
	controls.update();
	for (const b of document.querySelectorAll('[data-view]')) b.setAttribute('aria-pressed', String(b.dataset.view === name));
	dirty = true;
}

function load(i, keepCamera = true) {
	state.i = Math.max(0, Math.min(snaps.length - 1, i));
	const s = snaps[state.i];
	const hide = state.particles ? [] : ['particles'];
	const info = pv.build(s, { env: state.env, props: state.props, hide });
	if (!keepCamera) setView(state.view);
	const st = pv.envState;
	$('scrub').value = String(state.i);
	$('scenario').textContent = s.scenario || 'snapshot';
	$('frame').textContent = `f${s.frame ?? '?'}`;
	$('time').textContent = `${(s.t ?? 0).toFixed(2)} s`;
	$('clock').textContent = `${clockText(st.clockTime)} ${st.isDay ? 'day' : 'night'}`;
	$('quality').textContent = s.quality || 'high';
	$('count').textContent = `${info.particles} particles`;
	const wl = $('warnings');
	wl.replaceChildren(...info.warnings.map((w) => { const li = document.createElement('li'); li.textContent = w; return li; }));
	$('warn-count').textContent = info.warnings.length ? `${info.warnings.length} note${info.warnings.length > 1 ? 's' : ''}` : 'no notes';
	$('warn-box').hidden = !info.warnings.length;
	for (const t of document.querySelectorAll('.tick')) t.setAttribute('aria-current', String(Number(t.dataset.i) === state.i));
	dirty = true;
}

function buildTicks() {
	const row = $('ticks');
	const n = snaps.length;
	const every = Math.max(1, Math.ceil(n / 12));
	row.replaceChildren(...snaps.map((s, i) => {
		const b = document.createElement('button');
		b.className = 'tick';
		b.type = 'button';
		b.dataset.i = String(i);
		b.title = `${s.scenario || ''} t=${(s.t ?? 0).toFixed(2)} s`;
		const first = i > 0 && snaps[i - 1].scenario !== s.scenario; // a new scenario starts here
		if (first) b.classList.add('first');
		b.textContent = i % every === 0 || first ? `${first ? String(s.scenario || '').split('_')[0] + ' ' : ''}${(s.t ?? 0).toFixed(1)}` : '';
		b.addEventListener('click', () => load(i));
		return b;
	}));
	const scrub = $('scrub');
	scrub.max = String(Math.max(0, n - 1));
	scrub.disabled = n < 2;
}

function sortSnaps() {
	snaps.sort((a, b) => String(a.scenario).localeCompare(String(b.scenario)) || (a.t ?? 0) - (b.t ?? 0));
}

// ------------------------------------------------------------------------------------------------- controls
$('scrub').addEventListener('input', (e) => load(Number(e.target.value)));
for (const b of document.querySelectorAll('[data-view]')) b.addEventListener('click', () => setView(b.dataset.view));
for (const b of document.querySelectorAll('[data-env]')) b.addEventListener('click', () => {
	state.env = b.dataset.env;
	for (const x of document.querySelectorAll('[data-env]')) x.setAttribute('aria-pressed', String(x === b));
	load(state.i);
});
const toggle = (id, key) => $(id).addEventListener('change', (e) => { state[key] = e.target.checked; if (key === 'bloom') dirty = true; else load(state.i); });
toggle('opt-bloom', 'bloom'); toggle('opt-particles', 'particles'); toggle('opt-props', 'props');

let playTimer = null;
function step() {
	if (!state.playing) return;
	const a = snaps[state.i], next = (state.i + 1) % snaps.length, b = snaps[next];
	const dt = b && a && b.scenario === a.scenario && b.t > a.t ? Math.min(2, Math.max(0.25, b.t - a.t)) : 1;
	playTimer = setTimeout(() => { load(next); step(); }, dt * 1000);
}
$('play').addEventListener('click', () => {
	state.playing = !state.playing;
	$('play').setAttribute('aria-pressed', String(state.playing));
	$('play').textContent = state.playing ? 'Pause' : 'Play';
	clearTimeout(playTimer);
	step();
});

async function addFiles(files) {
	let added = 0;
	for (const f of files) {
		try {
			const s = JSON.parse(await f.text());
			if (s && s.version === 1 && Array.isArray(s.parts)) { snaps.push(s); added++; }
		} catch { /* not a snapshot */ }
	}
	$('drop-note').textContent = added ? `Added ${added} snapshot${added > 1 ? 's' : ''}. Unknown textures draw as soft dots.` : 'Those files are not snapshot JSON (tools/harness/SNAPSHOT.md).';
	if (added) { sortSnaps(); buildTicks(); load(snaps.length - 1, false); }
}
$('open').addEventListener('change', (e) => addFiles([...e.target.files]));
holder.addEventListener('dragover', (e) => { e.preventDefault(); holder.classList.add('drag'); });
holder.addEventListener('dragleave', () => holder.classList.remove('drag'));
holder.addEventListener('drop', (e) => { e.preventDefault(); holder.classList.remove('drag'); addFiles([...e.dataTransfer.files]); });

// ------------------------------------------------------------------------------------------------- start
function frame() {
	if (controls.update()) dirty = true;
	if (dirty) { dirty = false; pv.renderCurrent({ bloom: state.bloom, target: controls.target }); }
	requestAnimationFrame(frame);
}
(async () => {
	$('status').textContent = 'Loading textures';
	await pv.loadTextures(textures);
	sortSnaps();
	buildTicks();
	fitSize();
	load(Math.min(snaps.length - 1, DATA.start || 0), false);
	$('status').textContent = '';
	requestAnimationFrame(frame);
})();
void THREE; void wearerFrame;
