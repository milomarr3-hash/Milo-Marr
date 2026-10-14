-- AuraRNG Studio install kit | 08_chunk_07_of_07.luau | step 8: piece 7 of 7
-- Target ReplicatedStorage.AuraFX.TheEnd. Made by roblox/install/make_payloads.py from roblox/ReplicatedStorage/AuraFX/TheEnd.lua (82580 bytes, checksum 413068034).
-- Run in Roblox Studio in EDIT mode (Studio MCP execute_luau with datamodel_type "Edit", or paste into the Command Bar).
-- Send the text exactly as it is: it checks itself. It returns one line starting with OK, FAIL or STOP.
local FILE = "08_chunk_07_of_07.luau"
local TARGET = { "ReplicatedStorage", "AuraFX", "TheEnd" }
local TARGET_NAME = "ReplicatedStorage.AuraFX.TheEnd"
local RUN = "TheEnd-82580-413068034-7-175648338"
local NEW_LEN, NEW_SUM = 82580, 413068034
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

local N = 7
local LENS = { 13394, 13390, 13386, 13387, 13372, 13337, 2314 }
local SUMS = { 747760660, 546838554, 282322451, 777563289, 713911797, 449542432, 103059902 }

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

local K = 7
-- piece 7 of 7 of the new source (2314 bytes, checksum 103059902, long bracket level 0)
local DATA = [[
			if (not bokehNear and camDist < 9) or (bokehNear and camDist > 10) then
				bokehNear = not bokehNear
				refreshEmitters()
			end
		end
		if isGrounded ~= grounded then
			grounded = isGrounded
			refreshEmitters()
		end
		-- body-anchored fallback: the owner sees through the clock while it stands between the camera and the head
		if not VIEWER and ctx.isLocal then
			local head = O + Vector3.new(0, 2, 0)
			local nz = K.LookVector
			local d0, d1 = (camPos - K.Position):Dot(nz), (head - K.Position):Dot(nz)
			local cross = false
			if d0 * d1 < 0 then
				local hit = camPos + (head - camPos) * (d0 / (d0 - d1))
				cross = (hit - K.Position).Magnitude < 14
			end
			if cross ~= ltmOn then
				ltmOn = cross
				for _, p in ipairs(clockParts) do p.LocalTransparencyModifier = cross and 0.5 or 0 end
			end
		end
		nightClock += dt
		if nightClock >= CONFIG.NIGHT_INTERVAL then
			nightClock = 0
			local q = nightStep()
			if q ~= nq then
				-- (at most 0.05 per tick, so dusk never steps)
				if q > nq + 0.05 then q = math.floor((nq + 0.05) * 20 + 0.5) / 20
				elseif q < nq - 0.05 then q = math.floor((nq - 0.05) * 20 + 0.5) / 20 end
				applyNight(q)
			end
		end
	end

	function fx.setVisible(on)
		if destroyed then return end
		visible = on
		root.Parent = on and ctx.container or nil
		refreshEmitters()
		refreshLights()
	end

	function fx.setDetail(isNear)
		if destroyed then return end
		near = isNear
		setGroups()
		refreshEmitters()
		refreshLights()
	end

	function fx.destroy()
		if destroyed then return end
		destroyed = true
		root:Destroy()
		if gradeConn then gradeConn:Disconnect() end
		if gradeIn then gradeIn:Cancel() end
		if gradeOut then gradeOut:Cancel() end
		if grade then
			grade:Destroy()
			grade = nil
		end
		for _, o in ipairs(charStuff) do o:Destroy() end
		table.clear(charStuff)
		table.clear(act)
		table.clear(actParts)
		table.clear(acf)
		nAct = 0
	end

	applyNight(nightStep())
	root.Parent = ctx.container
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
		K, N, again and " again" or "", LENS[K], SUMS[K], have, N, K < N and chunkFile(K + 1) or "09_apply.luau"))
end

local ok, res = pcall(main)
if not ok then
	return say("FAIL", "Lua error: " .. tostring(res))
end
return res
