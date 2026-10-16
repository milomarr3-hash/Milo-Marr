-- AuraRNG Studio install kit | 02_chunk_01_of_12.luau | step 2: piece 1 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (151582 bytes, checksum 322184148).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "02_chunk_01_of_12.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-151582-322184148-12-938307881"
local NEW_LEN, NEW_SUM = 151582, 322184148
local BEFORE_LEN, BEFORE_SUM, BEFORE_NAME = 35000, 489406639, "the pass-4 live version"
local SES = game:GetService("ScriptEditorService")
local SS = game:GetService("ServerStorage")

-- checksum of a text, the same one the repo tools print: x = (x * 131 + byte) % 1000000007 over its bytes
local function sum(s)
	local x = 0
	for i = 1, #s do
		x = (x * 131 + string.byte(s, i)) % 1000000007
	end
	return x
end

-- every result is one line: OK, FAIL or STOP, this file's name, then what happened
local function say(word, msg)
	return word .. " " .. FILE .. ": " .. msg
end

-- the module to install into (nil if it is missing)
local function findTarget()
	local o = game:GetService(TARGET[1])
	for i = 2, #TARGET do
		o = o and o:FindFirstChild(TARGET[i])
	end
	return o
end

-- which version a text is, by its length and checksum
local function describe(len, cs)
	if len == NEW_LEN and cs == NEW_SUM then
		return "the NEW version"
	elseif len == BEFORE_LEN and cs == BEFORE_SUM then
		return BEFORE_NAME
	end
	return "an unknown version"
end

local N = 12
local LENS = { 13269, 13222, 13287, 13307, 13252, 13232, 13230, 13284, 13301, 13300, 13204, 5694 }
local SUMS = { 882737169, 754366057, 266404745, 785979457, 290862805, 645616522, 300795074, 332029237, 56580994, 674174262, 959073682, 306083532 }

-- the temporary holder ServerStorage.AuraRNG_Install: one StringValue per piece of the new source
local function chunkName(i)
	return string.format("chunk_%02d", i)
end
local function chunkFile(i)
	return string.format("%02d_chunk_%02d_of_%02d.luau", i + 1, i, N)
end
local function holder()
	local h = SS:FindFirstChild("AuraRNG_Install")
	if h and h:GetAttribute("RunId") == RUN then
		return h
	end
	return nil
end
local function chunkOk(h, i)
	local v = h:FindFirstChild(chunkName(i))
	return v ~= nil and v:IsA("StringValue") and #v.Value == LENS[i] and sum(v.Value) == SUMS[i]
end

local K = 1
-- piece 1 of 12 of the new source (13269 bytes, checksum 882737169, long bracket level 1)
local DATA = [=[
--[[
	AuraFX.TheEnd — 『 THE END 』 worn (1 in 1,000,000,000). Midnight of the universe, worn: black, white and silver only.
	Pass 2 (2026-10-13), Milo: "scale it up so much bigger", "the light flashes are annoying": a colossal look built from
	steady light — glowing HDR layers (SurfaceGui / BillboardGui Brightness) and soft additive particles over dark smoke —
	with NO pulses, strobes or flicker: everything turns, drifts or rises slowly and evenly.
	Pass 3 (2026-10-13), Milo's brief ("a cinematic, cosmic phenomenon", KEEP THE CLOCK): the pair became two opposite
	energies (a cloudy silver moon; a black void with a brilliant white core and fragments of light at its edge) joined by
	curved ribbons of light circling the wearer, and three scales of fine detail drift round everything.
	Pass 4 (2026-10-13), Milo: "ultra realistic, just like equinox ... go all out": photographic orbs, the clock rebuilt as
	fine-line dials stacked in depth, five 3D orbit rings of beams, a photographic galaxy underfoot, and an assembly on equip.
	Pass 5 (2026-10-14), Milo: "it needs so much more work, add depth, so much better particle effects, less transparency and
	more feel toward the build. Go all out, take your time and build it so much better." — "Make it amazing!"
	"The Last Clock": the aura is now a machine of ~360 solid parts (opaque: they write depth, so things pass in front of
	and behind each other for real), about 26 studs deep, in black steel, silver and white lume.
	  the clock      a skeleton pocket watch 28 studs across standing 8 studs beyond the wearer, always on the far side from
	                 whoever is watching (each viewer's own camera, through a soft spring, so it never blocks the owner's
	                 view and swings round to show its thickness; for the owner it steps back until XII is in the frame):
	                 a fluted silver bezel 2.4 deep, a dark chapter ring with inlaid white numerals and raised lume plots,
	                 an openwork star rete, a guilloché sub-dial, seven toothed gears turning at meshed rates behind and in
	                 front of the dial (their teeth break the rim at 1:30, 4, 8 and 10:30), hands locked at twelve while the
	                 seconds hand sweeps, a crown and bow on top. A ring of time-dust glints turns round it with the hands,
	                 metal shards break off at eleven and fly into the void, and a corona rings it at night.
	  the armillary  three gimballed rings of fine silver wire round the wearer — a precessing meridian, a satin equator
	                 band with twelve lume hours, the ecliptic at 23.4° — joined by pins, with eight time shards riding the
	                 ecliptic.
	  the balance    a moon (a photographic full moon on an opaque disc that turns to face you) and a pure-black void hang
	                 on an invisible beam on the viewer's left and right and rock slowly like scales. The void is a black
	                 hole: a hairline photon ring hugging its silhouette, a soft horizon glow, the lensed disc (a bright band
	                 arching over the shadow and a thinner one under it), a small brilliant four-point heart, an opaque
	                 accretion disc tilted toward the viewer (its near half crosses in front of the core), dense ink smoke
	                 boiling off it and matter spiralling into it. Dust and grey smoke drift off the moon; its own key light
	                 rims the wearer at night.
	  the streams    a silver stream arcs from the moon into one palm and an ink stream from the void into the other (the
	                 palms drink them in).
	  the wearer     burns with it: silver wisps rise off the shoulders and back, and sparks stream up the body.
	  the dais       a dark galaxy pool 30 studs across with white arms inside a raised fluted silver rim, two floating arm
	                 layers turning against it, an engraved clock-ring stage 56 studs across round it (numerals 3 studs tall,
	                 an inked minute track), a balance wheel swinging under the feet with a vortex of streaks climbing into
	                 it, starlight twinkles and black ash rising, a mist bank round the rim when standing on the ground. It
	                 stays put for jumps, lies along a slope and floats under a flyer.
	  the air        a field of slow four-point sparkles, smaller glints, and big slow bokeh drifting between the camera and
	                 the wearer (three scales).
	Equip (~6 s, mechanical, no flash): the void condenses, the moon rises out of the floor, the rings unfold up round the
	wearer (for the owner's close camera they wait flat on the dais until the hands lock), the bezel sweeps round from
	twelve, the gears slide out and spin down, the hands spin in and lock at twelve, the dais rim rises in a wave, the crown
	drops on, the shards settle on their ring; the wearer's own screen dims and cools meanwhile. After that everything
	turns, sways or drifts at a steady pace: no pulses, strobes or flicker, ever.
	Day reads by value (dark steel, black void and dark pool against white lume, silver metal and an ink contour; one
	Highlight keeps the metal neutral under the cyan sky); night glows softly through GUI Brightness above the Bloom threshold.
	Past ~110 studs the particles stop and the fine detail is dropped; low quality builds 150 parts. Flags: CONFIG below (a
	ModuleScript attribute with the same name and type overrides each one in Studio).
	Spec: docs/the-end/pass5-spec.md. Build notes and decisions: docs/the-end/pass5-build-notes.md.
	Textures: aura_work/tex4/make_theend_tex4.py (ids in aura_work/tex4/uploaded.md); aura_work/tex3/make_theend_tex3.py (ids in aura_work/tex3/uploaded.md) + the AuraCinema kit / _VFXLib (VFX Studio).
	Pass 5 textures: textures/te5/ (TEX5 below; until they are uploaded each one falls back to a pass-4 texture).
]]

local TEX = {
	-- pass 2 (aura_work/tex3)
	sigil = "rbxassetid://75027519125121", hands = "rbxassetid://93759864716353", shards = "rbxassetid://113607571698621",
	flare = "rbxassetid://93291601851916", streak = "rbxassetid://115797014411278", galaxy = "rbxassetid://125411838674546",
	gring = "rbxassetid://82989578201256", void = "rbxassetid://81195317493584",
	softGlow = "rbxassetid://90101855061498", rim = "rbxassetid://121599880739521",
	-- pass 1 (aura_work/tex)
	spark = "rbxassetid://109765380822041", ash = "rbxassetid://91995992047091",
	-- AuraCinema kit + _VFXLib (VFX Studio / Euphoric RNG auras)
	glow = "rbxassetid://88172507927269", glint = "rbxassetid://16956515291", sparkles = "rbxassetid://115317702570755", -- (4x4)
	puff = "rbxassetid://17062535921", mist = "rbxassetid://13826565206", -- (4x4 each)
	swirl = "rbxassetid://17086022111", ornate = "rbxassetid://14591895021",
	swirlRing = "rbxassetid://17087733793", pillar = "rbxassetid://3029306948",
	-- pass 4 (aura_work/tex4)
	moon = "rbxassetid://105160126126488", voidOrb = "rbxassetid://98346126355034", line = "rbxassetid://111152711897982",
	tick = "rbxassetid://99880756430819", dialOuter = "rbxassetid://138970147678654", dialMid = "rbxassetid://79447855638088",
	dialInner = "rbxassetid://134434932210706", hands4 = "rbxassetid://120547039021938", galaxy4 = "rbxassetid://91068008644782",
}
-- pass 5 (textures/te5/surfaces, textures/te5/particles): filled in on the Mac after upload. "" = not uploaded yet;
-- "rbxassetid://123", "123" and the number 123 all work. Until a key is filled in (or if its upload fails to load in the
-- game) it falls back to a pass-4 texture (FALLBACK), so the aura always looks complete.
local TEX5 = {
	dialInlay = "", subdial = "", accretion = "", galaxyFloor = "", galaxyArms = "", galaxyCore = "", engraving = "",
	halo = "", stream = "", moon = "", starWindow = "",
	shards5 = "", smoke5 = "", mote = "", glint5 = "", bokeh = "", streak5 = "", ash5 = "",
	-- (pass 5.1) a star that blooms, holds and shrinks out over its life; lit volumetric smoke; curling wisps; a hot fleck
	-- with a hairline tail; a glitter cluster whose grains swell and fade on their own phases
	twinkle = "", billow = "", wisp = "", spark5 = "", stardust = "",
}
-- (pass 5.1: te5_ash is a tumbling ember flake, 16 frames, and te5_shards a ray-traced steel blade tumbling)
local TEX5_LAYOUT = { shards5 = { "Grid4x4", "Loop" }, smoke5 = { "Grid4x4", "OneShot" }, ash5 = { "Grid4x4", "Loop" },
	twinkle = { "Grid4x4", "OneShot" }, billow = { "Grid4x4", "OneShot" }, wisp = { "Grid4x4", "OneShot" },
	stardust = { "Grid4x4", "Loop" } }
local FALLBACK = { -- key -> { pass-4 TEX key, flipbook layout, mode }
	dialInlay = { "dialOuter" }, subdial = { "dialInner" }, accretion = { "galaxy4" }, galaxyFloor = { "galaxy4" },
	galaxyArms = { "galaxy4" }, galaxyCore = { "ornate" }, engraving = { "gring" }, halo = { "rim" },
	stream = { "line" }, moon = { "moon" }, starWindow = { "galaxy4" },
	shards5 = { "ash", "None", "Loop" }, smoke5 = { "puff", "Grid4x4", "OneShot" }, mote = { "glow" }, glint5 = { "glint" },
	bokeh = { "glow" }, streak5 = { "spark" }, ash5 = { "ash", "None", "Loop" },
	twinkle = { "sparkles", "Grid4x4", "OneShot" }, billow = { "puff", "Grid4x4", "OneShot" }, wisp = { "puff", "Grid4x4", "OneShot" },
	spark5 = { "spark" }, stardust = { "sparkles", "Grid4x4", "Loop" },
}
-- (te4_moon is a 512² moon disc, radius 152 px, inside a glow ring. Drawn as the face of the moon's disc it is cropped to
-- the moon itself and rounded, so no white ring or square corner shows round the face; te5_moon is drawn whole)
local CROP = { moon = { Vector2.new(104, 104), Vector2.new(304, 304) } }
local warned = {}
local function warnOnce(key, msg)
	if not warned[key] then
		warned[key] = true
		warn(msg)
	end
end
-- a TEX5 value -> a content id, or nil (not filled in, or not an asset id: then the fallback is used and we say so once).
-- "pending:<key>" is the preview renderer's placeholder for a te5 PNG that is not uploaded yet (tools/); it is never
-- shipped: roblox/install/make_payloads.py refuses a module that still holds one.
local function idOf(v, key)
	if type(v) == "number" and v == v and v >= 1 and v < 1e18 then v = string.format("%d", math.floor(v)) end
	if type(v) ~= "string" then return nil end
	v = string.match(v, "^%s*(.-)%s*$")
	if v == "" then return nil end
	if string.match(v, "^%d+$") then return "rbxassetid://" .. v end
	if string.match(v, "^rbxassetid://%d+$") or string.match(v, "^rbxasset://") or string.match(v, "^rbxthumb://")
		or string.match(v, "^pending:%w+$") then
		return v
	end
	warnOnce("tex5:" .. tostring(key), string.format("TheEnd: TEX5.%s = %q is not an asset id; using the pass-4 fallback", tostring(key), v))
	return nil
end
local failed = {} -- te5 keys whose upload did not load in this game (ContentProvider said so): they use the fallback
-- T(key) -> id, flipbook layout name, flipbook mode name (layout "None" when it is not a flipbook). Accepts a TEX5 key or
-- a pass-4 TEX key. The layout comes from whichever texture is used, because a fallback can be laid out differently.
local function T(key)
	local id = not failed[key] and idOf(TEX5[key], key)
	if id then
		local l = TEX5_LAYOUT[key]
		return id, l and l[1] or "None", l and l[2] or "Loop"
	end
	local f = FALLBACK[key]
	if f then return TEX[f[1]], f[2] or "None", f[3] or "Loop" end
	local t = TEX[key]
	if not t then warnOnce("texkey:" .. tostring(key), "TheEnd: no texture called " .. tostring(key)) end
	return t or "", "None", "Loop"
end
local function isTe5(key) return not failed[key] and idOf(TEX5[key], key) ~= nil end
-- every live image, beam and emitter that uses a te5 key, so a texture that fails to load can be swapped for its fallback;
-- fixUps[o](o) puts back what the build chose because the te5 texture was there (a colour, a brightness, a size). (The
-- hook gets the object as its argument: a weak-keyed entry whose value held its own key would never be collected)
local texUsers = setmetatable({}, { __mode = "k" })
local fixUps = setmetatable({}, { __mode = "k" })
local usedKeys = {} -- (te5 keys some build on this client draws: only those are asked for)
local function applyTex(o, key)
	local id, layout, mode = T(key)
	if o:IsA("ImageLabel") then
		o.Image = id
		local c = CROP[key]
		if c then
			local fb = not isTe5(key)
			o.ImageRectOffset, o.ImageRectSize = fb and c[1] or Vector2.zero, fb and c[2] or Vector2.zero
		end
	elseif o:IsA("Beam") then
		o.Texture = id
	elseif o:IsA("ParticleEmitter") then
		o.Texture = id
		o.FlipbookLayout = Enum.ParticleFlipbookLayout[layout]
		if layout ~= "None" then o.FlipbookMode = Enum.ParticleFlipbookMode[mode] end
	end
	if TEX5[key] then
		texUsers[o] = key
		usedKeys[key] = true
	end
end
-- ask the engine for the te5 textures a build actually draws, once each (in the background: never blocks require or
-- build; a low-quality build never asks for the six textures only high quality uses, so a phone does not hold them). One
-- that does not load (wrong id, still in moderation, rejected) is reported and swapped for its pass-4 fallback everywhere,
-- for every key that shares its id. A slow phone or a cold cache can time out: that id is asked for once more 20 s later
-- before anything is swapped.
local preloadUsed
do
	local asked, keysOf, retried, dead = {}, {}, {}, {}
]=]

local function main()
	if game:GetService("RunService"):IsRunning() then
		return say("STOP", "Studio is in Play mode. Stop Play, then run this again in Edit mode. Nothing changed.")
	end
	if #DATA ~= LENS[K] or sum(DATA) ~= SUMS[K] then
		return say("FAIL", string.format("piece %d arrived changed (%d bytes, checksum %d; it should be %d bytes, checksum %d): the text of this payload was altered when it was sent. Nothing stored. Send the file again exactly as it is (tabs, spaces, blank lines and the last line all count).",
			K, #DATA, sum(DATA), LENS[K], SUMS[K]))
	end
	if not findTarget() then
		return say("FAIL", TARGET_NAME .. " was not found. Nothing stored.")
	end
	local h = holder()
	if not h then
		return say("FAIL", "no install holder for this payload set. Run 01_backup.luau of this same set first.")
	end
	for i = 1, K - 1 do
		if not chunkOk(h, i) then
			return say("FAIL", string.format("piece %d is missing or damaged: run %s first (pieces go in order). Nothing stored.", i, chunkFile(i)))
		end
	end
	local v = h:FindFirstChild(chunkName(K))
	local again = v ~= nil
	if v and not v:IsA("StringValue") then
		v:Destroy()
		v = nil
	end
	if not v then
		v = Instance.new("StringValue")
		v.Name = chunkName(K)
	end
	v.Value = DATA
	v.Parent = h
	if #v.Value ~= LENS[K] or sum(v.Value) ~= SUMS[K] then
		return say("FAIL", string.format("the StringValue changed piece %d (%d bytes stored of %d). Tell Milo; nothing was installed.", K, #v.Value, LENS[K]))
	end
	local have = 0
	for i = 1, N do
		if chunkOk(h, i) then
			have += 1
		end
	end
	return say("OK", string.format("piece %d/%d stored%s (%d bytes, checksum %d). The holder has %d/%d. Next: %s",
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "14_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
