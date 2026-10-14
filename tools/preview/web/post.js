// Post-processing, in Roblox's order of things:
//   1. the scene renders into an HDR buffer (half float, 4x MSAA); GUI Brightness, Neon and particle Brightness go above 1;
//   2. Bloom like the place's Lighting.Bloom (Intensity 1, Size 24, Threshold 2): only the part of a pixel ABOVE the threshold
//      (by its brightest channel, so coloured Neon glows too) is blurred and added back;
//   3. tone mapping (Khronos "neutral": keeps hues, rolls off highlights) + sRGB;
//   4. Highlights: a mask of the adornee's parts (depth-tested against the opaque scene for DepthMode Occluded, not tested
//      for AlwaysOnTop) -> FillColor blended over the parts at 1 - FillTransparency, and an outline ring round the mask in
//      OutlineColor at 1 - OutlineTransparency (normal blending, so ink outlines read on a bright sky);
//   5. ColorCorrectionEffects the module created (Brightness, Contrast, Saturation, TintColor).
import * as THREE from 'three';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { FullScreenQuad } from 'three/addons/postprocessing/Pass.js';
import { srgb } from 'preview/rbx.js';

const HIGHPASS = /* glsl */`
uniform sampler2D tDiffuse; uniform float luminosityThreshold; uniform float smoothWidth;
varying vec2 vUv;
void main() {
	vec4 texel = texture2D(tDiffuse, vUv);
	float m = max(texel.r, max(texel.g, texel.b));
	float k = max(m - luminosityThreshold, 0.0) / max(m, 1e-4);
	k = k * smoothstep(0.0, smoothWidth, m - luminosityThreshold);
	gl_FragColor = vec4(texel.rgb * k, 1.0);
}`;
const QUAD_VERT = /* glsl */`varying vec2 vUv; void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`;
const HIGHLIGHT_FRAG = /* glsl */`
uniform sampler2D tDiffuse; uniform sampler2D tMask; uniform vec2 uTexel; uniform float uRadius;
uniform vec3 uFill; uniform vec3 uOutline; uniform float uFillA; uniform float uOutlineA;
varying vec2 vUv;
void main() {
	vec4 c = texture2D(tDiffuse, vUv);
	float m = texture2D(tMask, vUv).r;
	float d = m;
	for (int i = 0; i < 16; i++) {
		float a = float(i) * 0.39269908;
		vec2 o = vec2(cos(a), sin(a)) * uTexel;
		d = max(d, texture2D(tMask, vUv + o * uRadius).r);
		d = max(d, texture2D(tMask, vUv + o * uRadius * 0.5).r);
	}
	vec3 col = mix(c.rgb, uFill, uFillA * m);
	col = mix(col, uOutline, uOutlineA * clamp(d - m, 0.0, 1.0));
	gl_FragColor = vec4(col, 1.0);
}`;
const CC_FRAG = /* glsl */`
uniform sampler2D tDiffuse; uniform float uB; uniform float uC; uniform float uS; uniform vec3 uTint;
varying vec2 vUv;
void main() {
	vec3 c = texture2D(tDiffuse, vUv).rgb;
	c += uB;
	c = (c - 0.5) * (1.0 + uC) + 0.5;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, 1.0 + uS);
	c *= uTint;
	gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}`;
const COPY_FRAG = /* glsl */`uniform sampler2D tDiffuse; varying vec2 vUv; void main() { gl_FragColor = vec4(texture2D(tDiffuse, vUv).rgb, 1.0); }`;

// mip weights (sum 1) for a Roblox Bloom Size in px at 1080p
export function bloomWeights(size) {
	const sig = [6, 20, 56, 144, 350], s = Math.max(2, size || 24);
	const w = sig.map((x) => Math.exp(-0.5 * (Math.log2(x / s) / 0.9) ** 2));
	w[0] = Math.max(w[0], 0.35); // the tight core round each bright line
	const t = w.reduce((a, b) => a + b, 0);
	return w.map((x) => x / t);
}

export class Post {
	constructor(renderer, w, h) {
		this.renderer = renderer;
		this.w = w; this.h = h;
		const hdr = { type: THREE.HalfFloatType, samples: 4 };
		this.sceneRT = new THREE.WebGLRenderTarget(w, h, hdr);
		this.ldrA = new THREE.WebGLRenderTarget(w, h, { type: THREE.HalfFloatType });
		this.ldrB = new THREE.WebGLRenderTarget(w, h, { type: THREE.HalfFloatType });
		this.maskRT = new THREE.WebGLRenderTarget(w, h, { samples: 4 });
		this.bloom = new UnrealBloomPass(new THREE.Vector2(w, h), 1, 0.5, 2);
		this.bloom.materialHighPassFilter.fragmentShader = HIGHPASS;
		this.bloom.materialHighPassFilter.needsUpdate = true;
		this.output = new OutputPass();
		this.quad = new FullScreenQuad();
		this.hlMat = new THREE.ShaderMaterial({
			vertexShader: QUAD_VERT, fragmentShader: HIGHLIGHT_FRAG, depthTest: false, depthWrite: false,
			uniforms: {
				tDiffuse: { value: null }, tMask: { value: null }, uTexel: { value: new THREE.Vector2(1 / w, 1 / h) }, uRadius: { value: 2 },
				uFill: { value: new THREE.Color() }, uOutline: { value: new THREE.Color() }, uFillA: { value: 0 }, uOutlineA: { value: 0 },
			},
		});
		this.ccMat = new THREE.ShaderMaterial({
			vertexShader: QUAD_VERT, fragmentShader: CC_FRAG, depthTest: false, depthWrite: false,
			uniforms: { tDiffuse: { value: null }, uB: { value: 0 }, uC: { value: 0 }, uS: { value: 0 }, uTint: { value: new THREE.Vector3(1, 1, 1) } },
		});
		this.copyMat = new THREE.ShaderMaterial({ vertexShader: QUAD_VERT, fragmentShader: COPY_FRAG, depthTest: false, depthWrite: false, uniforms: { tDiffuse: { value: null } } });
		this.depthMat = new THREE.MeshBasicMaterial({ colorWrite: false });
		this.maskMat = new THREE.MeshBasicMaterial({ color: 0xffffff, depthWrite: false, depthFunc: THREE.LessEqualDepth });
		this.maskTopMat = new THREE.MeshBasicMaterial({ color: 0xffffff, depthWrite: false, depthTest: false });
	}

	setSize(w, h) {
		if (w === this.w && h === this.h) return;
		this.w = w; this.h = h;
		for (const rt of [this.sceneRT, this.ldrA, this.ldrB, this.maskRT]) rt.setSize(w, h);
		this.bloom.setSize(w, h);
		this.hlMat.uniforms.uTexel.value.set(1 / w, 1 / h);
	}

	// opts: { bloom: { intensity, size, threshold } | null, highlights: [{ layer, fill, fillA, outline, outlineA, top }], cc: {...} | null }
	render(scene, camera, opts = {}) {
		const r = this.renderer;
		r.setRenderTarget(this.sceneRT);
		r.setClearColor(0x000000, 1);
		r.clear(true, true, true);
		r.render(scene, camera);
		if (opts.bloom) {
			// Roblox's Bloom adds the energy ABOVE Threshold back once (Intensity 1 = 1x), blurred over about Size px at
			// 1080p. UnrealBloomPass's mips blur ~6, 20, 56, 144 and 350 px (at 1080p): weight them so the total is
			// Intensity and most of it sits near Size (calibrated on the pass-4 Studio captures: the Brightness-3.4 dial
			// lines keep a thin halo and the black between them stays black; the stock mix was ~3.5x too strong and wide)
			this.bloom.threshold = opts.bloom.threshold;
			this.bloom.strength = opts.bloom.intensity;
			this.bloom.radius = 0;
			this.bloom.compositeMaterial.uniforms.bloomFactors.value = bloomWeights(opts.bloom.size);
			this.bloom.render(r, null, this.sceneRT, 0, false);
		}
		this.output.render(r, this.ldrA, this.sceneRT);
		let src = this.ldrA, dst = this.ldrB;
		for (const h of opts.highlights || []) {
			this.renderMask(scene, camera, h);
			const u = this.hlMat.uniforms;
			u.tDiffuse.value = src.texture; u.tMask.value = this.maskRT.texture;
			u.uFill.value.copy(h.fill); u.uOutline.value.copy(h.outline); u.uFillA.value = h.fillA; u.uOutlineA.value = h.outlineA;
			u.uRadius.value = Math.max(1.5, this.h / 360);
			this.quad.material = this.hlMat;
			r.setRenderTarget(dst); this.quad.render(r);
			[src, dst] = [dst, src];
		}
		if (opts.cc) {
			const u = this.ccMat.uniforms;
			u.tDiffuse.value = src.texture; u.uB.value = opts.cc.brightness; u.uC.value = opts.cc.contrast; u.uS.value = opts.cc.saturation;
			u.uTint.value.set(...opts.cc.tint);
			this.quad.material = this.ccMat;
			r.setRenderTarget(dst); this.quad.render(r);
			[src, dst] = [dst, src];
		}
		this.copyMat.uniforms.tDiffuse.value = src.texture;
		this.quad.material = this.copyMat;
		r.setRenderTarget(null);
		this.quad.render(r);
	}

	renderMask(scene, camera, h) {
		const r = this.renderer, oldAuto = r.autoClear, oldMask = camera.layers.mask;
		r.autoClear = false;
		r.setRenderTarget(this.maskRT);
		r.setClearColor(0x000000, 0);
		r.clear(true, true, true);
		const oldOverride = scene.overrideMaterial;
		if (!h.top) { // depth of everything opaque, so hidden bits of the adornee drop out of the mask (DepthMode Occluded)
			camera.layers.set(1);
			scene.overrideMaterial = this.depthMat;
			r.render(scene, camera);
		}
		camera.layers.set(h.layer);
		scene.overrideMaterial = h.top ? this.maskTopMat : this.maskMat;
		r.render(scene, camera);
		scene.overrideMaterial = oldOverride;
		camera.layers.mask = oldMask;
		r.autoClear = oldAuto;
	}
}

// the snapshot's effects -> post options (ColorCorrection compounds; a BloomEffect the module made overrides the place's)
export function effectOptions(snapshot, warn) {
	let cc = null, bloom = { intensity: 1, size: 24, threshold: 2 };
	for (const e of snapshot.effects || []) {
		const p = e.props || {};
		if (p.Enabled === false) continue;
		if (e.class === 'ColorCorrectionEffect') {
			cc = cc || { brightness: 0, contrast: 0, saturation: 0, tint: [1, 1, 1] };
			cc.brightness += p.Brightness || 0; cc.contrast += p.Contrast || 0; cc.saturation += p.Saturation || 0;
			const t = p.TintColor || [255, 255, 255];
			cc.tint = cc.tint.map((v, i) => v * (t[i] / 255));
		} else if (e.class === 'BloomEffect') {
			bloom = { intensity: p.Intensity ?? 1, size: p.Size ?? 24, threshold: p.Threshold ?? 2 };
		} else warn(`${e.class} is not drawn by the preview`, 'fx:' + e.class);
	}
	return { cc, bloom };
}

export function highlightOptions(snapshot, layerOf) {
	const out = [];
	for (const h of snapshot.highlights || []) {
		if (h.enabled === false) continue;
		const layer = layerOf(h);
		if (layer == null) continue;
		out.push({
			layer, top: String(h.depthMode || '').endsWith('AlwaysOnTop'),
			fill: new THREE.Color((h.fillColor || [255, 255, 255])[0] / 255, (h.fillColor || [255, 255, 255])[1] / 255, (h.fillColor || [255, 255, 255])[2] / 255),
			outline: new THREE.Color((h.outlineColor || [255, 255, 255])[0] / 255, (h.outlineColor || [255, 255, 255])[1] / 255, (h.outlineColor || [255, 255, 255])[2] / 255),
			fillA: 1 - (h.fillTransparency ?? 0.5), outlineA: 1 - (h.outlineTransparency ?? 0),
		});
	}
	return out;
}
export { srgb };
