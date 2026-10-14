-- prelude: the harness namespace, real (wall) clock, JSON encoding and the stdout protocol.
-- Everything the harness shares lives in H (a local, so the aura module can never see it).
local H = {}
do
	H.realClock = os.clock -- real time, for "Lua time per update()" (the module only ever sees virtual time)
	H.nativeTypeof = typeof
	H.nativeType = type

	local format, concat, tostr = string.format, table.concat, tostring
	local floor, huge = math.floor, math.huge

	-- JSON ------------------------------------------------------------------------------------------------
	local NULL = table.freeze({}) -- encodes as JSON null (a nil value would drop the key)
	H.NULL = NULL
	local OBJ = {} -- metatable marking a table that must encode as an object even when empty
	H.JSON_OBJECT = OBJ
	function H.obj(t) return setmetatable(t or {}, OBJ) end

	local escMap = { ['"'] = '\\"', ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }
	local function escStr(s)
		s = s:gsub('[%c"\\]', function(c)
			return escMap[c] or format("\\u%04x", c:byte())
		end)
		return '"' .. s .. '"'
	end
	H.jsonString = escStr

	local function num(n)
		if n ~= n or n == huge or n == -huge then return "null" end
		if n == floor(n) and n > -1e15 and n < 1e15 then return format("%d", n) end
		return format("%.7g", n)
	end
	H.jsonNumber = num

	local encode
	function encode(v, out)
		local t = type(v)
		if v == NULL then
			out[#out + 1] = "null"
		elseif t == "table" then
			local mt = getmetatable(v)
			if mt == OBJ or (v[1] == nil and next(v) ~= nil) then
				out[#out + 1] = "{"
				local first = true
				-- sorted keys keep the output stable (diffable snapshots)
				local keys = {}
				for k in pairs(v) do keys[#keys + 1] = tostr(k) end
				table.sort(keys)
				for _, k in ipairs(keys) do
					local val = v[k]
					if val == nil then val = v[tonumber(k)] end
					if not first then out[#out + 1] = "," end
					first = false
					out[#out + 1] = escStr(k)
					out[#out + 1] = ":"
					encode(val, out)
				end
				out[#out + 1] = "}"
			else
				out[#out + 1] = "["
				for i = 1, #v do
					if i > 1 then out[#out + 1] = "," end
					encode(v[i], out)
				end
				out[#out + 1] = "]"
			end
		elseif t == "number" then
			out[#out + 1] = num(v)
		elseif t == "string" then
			out[#out + 1] = escStr(v)
		elseif t == "boolean" then
			out[#out + 1] = v and "true" or "false"
		elseif v == nil then
			out[#out + 1] = "null"
		else
			out[#out + 1] = escStr(tostr(v))
		end
	end
	function H.json(v)
		local out = {}
		encode(v, out)
		return concat(out)
	end

	-- stdout protocol: one JSON object per line, prefixed so stray output can never be mistaken for a record.
	local rawPrint = print
	H.rawPrint = rawPrint
	function H.emit(kind, data)
		data = data or {}
		data.kind = kind
		rawPrint("@@H " .. H.json(data))
	end

	-- small helpers ---------------------------------------------------------------------------------------
	function H.shallowCopy(t)
		local c = {}
		for k, v in pairs(t) do c[k] = v end
		return c
	end
	function H.round(x, n)
		local m = 10 ^ (n or 3)
		return floor(x * m + 0.5) / m
	end
end
