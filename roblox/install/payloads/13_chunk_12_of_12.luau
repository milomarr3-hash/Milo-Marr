-- AuraRNG Studio install kit | 13_chunk_12_of_12.luau | step 13: piece 12 of 12
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (148303 bytes, checksum 731942170).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "13_chunk_12_of_12.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-148303-731942170-12-824555251"
local NEW_LEN, NEW_SUM = 148303, 731942170
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
local LENS = { 13300, 13224, 13240, 13242, 13194, 13235, 13276, 13235, 13290, 13298, 13282, 2487 }
local SUMS = { 825733820, 782681153, 524531706, 656635892, 998587156, 867606918, 526087852, 254541497, 6651690, 395645774, 897444566, 313496838 }

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

local K = 12
-- piece 12 of 12 of the new source (2487 bytes, checksum 313496838, long bracket level 0)
local DATA = [[
		if destroyed or on == visible then return end
		visible = on
		if on then
			-- (parented again by the next update, together with that frame's positions; after a long hide it fades back in
			-- instead of popping, and the body's wisps and sparks wait a second)
			st.pendingRoot = true
			st.shownAt = os.clock()
			st.lastO = nil -- (the distance walked while hidden is not a speed)
			if st.hiddenAt and st.shownAt - st.hiddenAt > 0.5 then
				st.revealA, st.snap = 0, true
				if nq >= 0 then applyNight(nightStep()) end -- (dusk may have passed meanwhile; the reveal starts from nothing)
			end
		else
			root.Parent = nil
			st.pendingRoot = false
			st.hiddenAt = os.clock()
			if not remote then ownerHub = nil end -- (other wearers no longer step back for a clock you cannot see)
			st.footOk = false
			if grade then
				-- (never left on top of a cutscene or a hidden aura)
				st.gradeOut = true
				gradeTo(GRADE_OFF, 0.4, true)
			end
		end
		refreshEmitters()
		refreshLights()
	end

	function fx.setDetail(isNear)
		if destroyed then return end
		near = isNear
		if isNear then st.pendingGroups = true else setGroups() end -- (shown again by the next update, at fresh positions)
		refreshEmitters()
		refreshLights()
	end

	function fx.destroy()
		if destroyed then return end
		destroyed = true
		if grade then gradeTo(GRADE_OFF, 0.8, true) end -- (the screen eases back instead of snapping)
		if ctx.isLocal then
			ownGone, ownGoneChar[1] = os.clock(), char -- (a respawn's rebuild within seconds is not an equip: no grade)
			ownerHub = nil
		end
		for h = 1, 4 do
			for _, hp in ipairs(holders[h]) do hp[1]:Destroy() end -- (also the groups hidden by far LOD or the near rule)
		end
		root:Destroy()
		for _, o in ipairs(charStuff) do o:Destroy() end
		for _, tb in ipairs({ charStuff, act, actParts, acf, PP, solids, images, brights, emitters, emitNight, beams, clockParts, ghostParts, ringParts,
			ghostGuis, gearData }) do
			table.clear(tb)
		end
		nAct = 0
	end

	applyNight(nightStep())
	root.Parent = ctx.container
	preloadUsed() -- (the te5 textures this build draws, asked for once each, in the background)
	if CONFIG.DEBUG then
		local nb, ng = 0, 0
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then ng += 1 elseif d:IsA("Beam") then nb += 1 end
		end
		print(string.format("TheEnd: %d parts (%d moved), %d emitters, %d GUIs, %d beams", NP, nAct, #emitters, ng, nb))
	end
	return fx
end

return End
]]

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
