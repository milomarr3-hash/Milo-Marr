-- datatypes: Vector3, Vector2, CFrame, Color3, UDim/UDim2, NumberRange, NumberSequence(+Keypoint),
-- ColorSequence(+Keypoint), Rect, TweenInfo, Random, BrickColor, Ray, Region3, RaycastParams/Result, OverlapParams,
-- PhysicalProperties, Faces, Axes, Font, DateTime, Content, Vector3int16/Vector2int16, typeof().
-- Values are frozen tables (writes error like Roblox's immutable datatypes) with a per-type metatable.
do
	local sqrt, abs, floor, ceil, sin, cos, atan2, acos, asin = math.sqrt, math.abs, math.floor, math.ceil, math.sin, math.cos, math.atan2, math.acos, math.asin
	local mmin, mmax, huge, pi = math.min, math.max, math.huge, math.pi
	local format, freeze, nativeTypeof = string.format, table.freeze, H.nativeTypeof

	local TYPEOF = {}
	H.TYPEOF = TYPEOF
	local D -- instance data registry (filled in by instance.luau)

	local function typeof(v)
		local t = nativeTypeof(v)
		if t == "table" then
			local mt = getmetatable(v)
			local n = TYPEOF[mt]
			if n then return n end
			if H.INST_DATA and H.INST_DATA[v] then return "Instance" end
		end
		return t
	end
	H.typeof = typeof
	-- Roblox's type() says "userdata" for engine values
	function H.robloxType(v)
		local t = nativeTypeof(v)
		if t == "table" then
			if TYPEOF[getmetatable(v)] or (H.INST_DATA and H.INST_DATA[v]) then return "userdata" end
		end
		return t
	end

	local function err(msg) error(msg, 0) end
	H.err = err
	local function badArg(i, fname, expected, v)
		err(format("invalid argument #%d to '%s' (%s expected, got %s)", i, fname, expected, typeof(v)))
	end
	H.badArg = badArg
	local function numArg(v, i, fname, default)
		if v == nil then
			if default ~= nil then return default end
			return 0
		end
		local t = nativeTypeof(v)
		if t == "number" then return v end
		if t == "string" then
			local n = tonumber(v)
			if n then return n end
		end
		badArg(i, fname, "number", v)
		return 0
	end
	H.numArg = numArg
	local function fmtn(n)
		if n == floor(n) and abs(n) < 1e15 then return format("%d", n) end
		return format("%.7g", n)
	end
	H.fmtn = fmtn

	local function makeType(name, getters, methods)
		local mt = {}
		TYPEOF[mt] = name
		mt.__index = function(_, k)
			local m = methods[k]
			if m ~= nil then return m end
			local g = getters[k]
			if g then return g(_) end
			err(format("%s is not a valid member of %s", tostring(k), name))
			return nil
		end
		mt.__newindex = function(_, k)
			err(format("%s cannot be assigned to", tostring(k)))
		end
		mt.__lt = function() err(format("attempt to compare %s", name)) end
		mt.__le = mt.__lt
		mt.__len = function() err(format("attempt to get length of a %s value", name)) end
		mt.__call = function() err(format("attempt to call a %s value", name)) end
		mt.__concat = function(a, b) err(format("attempt to concatenate %s with %s", typeof(a), typeof(b))) end
		return mt
	end
	H.makeType = makeType

	--------------------------------------------------------------------------------------------- Vector3
	local V3G, V3M = {}, {}
	local V3 = makeType("Vector3", V3G, V3M)
	H.V3MT = V3
	local function v3(x, y, z) return freeze(setmetatable({ X = x, Y = y, Z = z }, V3)) end
	H.v3 = v3
	local function isV3(v) return getmetatable(v) == V3 end
	H.isV3 = isV3
	local function checkV3(v, i, fname) if getmetatable(v) ~= V3 then badArg(i, fname, "Vector3", v) end return v end

	V3G.Magnitude = function(v) return sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
	V3G.Unit = function(v)
		local m = sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		return v3(v.X / m, v.Y / m, v.Z / m) -- (zero vector: NaN, like Roblox)
	end
	V3G.magnitude, V3G.unit = V3G.Magnitude, V3G.Unit
	V3G.x = function(v) return v.X end
	V3G.y = function(v) return v.Y end
	V3G.z = function(v) return v.Z end
	function V3M.Dot(a, b) checkV3(b, 1, "Dot") return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
	function V3M.Cross(a, b)
		checkV3(b, 1, "Cross")
		return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
	end
	function V3M.Lerp(a, b, t)
		checkV3(b, 1, "Lerp")
		t = numArg(t, 2, "Lerp")
		return v3(a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t, a.Z + (b.Z - a.Z) * t)
	end
	V3M.lerp = V3M.Lerp
	function V3M.Abs(a) return v3(abs(a.X), abs(a.Y), abs(a.Z)) end
	function V3M.Ceil(a) return v3(ceil(a.X), ceil(a.Y), ceil(a.Z)) end
	function V3M.Floor(a) return v3(floor(a.X), floor(a.Y), floor(a.Z)) end
	function V3M.Sign(a) return v3(math.sign(a.X), math.sign(a.Y), math.sign(a.Z)) end
	function V3M.Max(a, ...)
		local x, y, z = a.X, a.Y, a.Z
		for i = 1, select("#", ...) do
			local b = checkV3(select(i, ...), i, "Max")
			x, y, z = mmax(x, b.X), mmax(y, b.Y), mmax(z, b.Z)
		end
		return v3(x, y, z)
	end
	function V3M.Min(a, ...)
		local x, y, z = a.X, a.Y, a.Z
		for i = 1, select("#", ...) do
			local b = checkV3(select(i, ...), i, "Min")
			x, y, z = mmin(x, b.X), mmin(y, b.Y), mmin(z, b.Z)
		end
		return v3(x, y, z)
	end
	function V3M.FuzzyEq(a, b, eps)
		checkV3(b, 1, "FuzzyEq")
		eps = eps or 1e-5
		local dx, dy, dz = a.X - b.X, a.Y - b.Y, a.Z - b.Z
		return dx * dx + dy * dy + dz * dz <= eps * eps * mmax(1, a.X * a.X + a.Y * a.Y + a.Z * a.Z)
	end
	function V3M.Angle(a, b, axis)
		checkV3(b, 1, "Angle")
		local ma = sqrt(a.X * a.X + a.Y * a.Y + a.Z * a.Z)
		local mb = sqrt(b.X * b.X + b.Y * b.Y + b.Z * b.Z)
		if ma == 0 or mb == 0 then return 0 end
		local d = (a.X * b.X + a.Y * b.Y + a.Z * b.Z) / (ma * mb)
		local ang = acos(mmax(-1, mmin(1, d)))
		if axis then
			checkV3(axis, 2, "Angle")
			local cx, cy, cz = a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X
			if cx * axis.X + cy * axis.Y + cz * axis.Z < 0 then ang = -ang end
		end
		return ang
	end

	local function binErr(i, expected, v) err(format("invalid argument #%d (%s expected, got %s)", i, expected, typeof(v))) end
	H.binErr = binErr
	V3.__add = function(a, b)
		if getmetatable(a) ~= V3 then binErr(1, "Vector3", a) end
		if getmetatable(b) ~= V3 then binErr(2, "Vector3", b) end
		return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
	end
	V3.__sub = function(a, b)
		if getmetatable(a) ~= V3 then binErr(1, "Vector3", a) end
		if getmetatable(b) ~= V3 then binErr(2, "Vector3", b) end
		return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
	end
	V3.__mul = function(a, b)
		if nativeTypeof(a) == "number" then
			if getmetatable(b) ~= V3 then binErr(2, "Vector3", b) end
			return v3(a * b.X, a * b.Y, a * b.Z)
		end
		if getmetatable(a) ~= V3 then binErr(1, "Vector3", a) end
		if nativeTypeof(b) == "number" then return v3(a.X * b, a.Y * b, a.Z * b) end
		if getmetatable(b) == V3 then return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z) end
		binErr(2, "Vector3 or number", b)
		return nil
	end
	V3.__div = function(a, b)
		if nativeTypeof(a) == "number" then
			if getmetatable(b) ~= V3 then binErr(2, "Vector3", b) end
			return v3(a / b.X, a / b.Y, a / b.Z)
		end
		if getmetatable(a) ~= V3 then binErr(1, "Vector3", a) end
		if nativeTypeof(b) == "number" then return v3(a.X / b, a.Y / b, a.Z / b) end
		if getmetatable(b) == V3 then return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z) end
		binErr(2, "Vector3 or number", b)
		return nil
	end
	V3.__idiv = function(a, b)
		local q = V3.__div(a, b)
		return v3(floor(q.X), floor(q.Y), floor(q.Z))
	end
	V3.__unm = function(a) return v3(-a.X, -a.Y, -a.Z) end
	V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
	V3.__tostring = function(a) return fmtn(a.X) .. ", " .. fmtn(a.Y) .. ", " .. fmtn(a.Z) end

	local Vector3 = {
		new = function(x, y, z) return v3(numArg(x, 1, "new"), numArg(y, 2, "new"), numArg(z, 3, "new")) end,
		zero = v3(0, 0, 0), one = v3(1, 1, 1), xAxis = v3(1, 0, 0), yAxis = v3(0, 1, 0), zAxis = v3(0, 0, 1),
	}
	local NORMALS = { Right = v3(1, 0, 0), Top = v3(0, 1, 0), Back = v3(0, 0, 1), Left = v3(-1, 0, 0), Bottom = v3(0, -1, 0), Front = v3(0, 0, -1) }
	H.NORMALS = NORMALS
	function Vector3.FromNormalId(id)
		local item = H.coerceEnum("NormalId", id)
		if not item then badArg(1, "FromNormalId", "Enum.NormalId", id) end
		return NORMALS[item.Name]
	end
	function Vector3.FromAxis(a)
		local item = H.coerceEnum("Axis", a)
		if not item then badArg(1, "FromAxis", "Enum.Axis", a) end
		return ({ X = Vector3.xAxis, Y = Vector3.yAxis, Z = Vector3.zAxis })[item.Name]
	end
	H.Vector3 = freeze(Vector3)

	--------------------------------------------------------------------------------------------- Vector2
	local V2G, V2M = {}, {}
	local V2 = makeType("Vector2", V2G, V2M)
	local function v2(x, y) return freeze(setmetatable({ X = x, Y = y }, V2)) end
	H.v2 = v2
	local function checkV2(v, i, fname) if getmetatable(v) ~= V2 then badArg(i, fname, "Vector2", v) end return v end
	V2G.Magnitude = function(v) return sqrt(v.X * v.X + v.Y * v.Y) end
	V2G.Unit = function(v) local m = sqrt(v.X * v.X + v.Y * v.Y) return v2(v.X / m, v.Y / m) end
	V2G.magnitude, V2G.unit = V2G.Magnitude, V2G.Unit
	V2G.x = function(v) return v.X end
	V2G.y = function(v) return v.Y end
	function V2M.Dot(a, b) checkV2(b, 1, "Dot") return a.X * b.X + a.Y * b.Y end
	function V2M.Cross(a, b) checkV2(b, 1, "Cross") return a.X * b.Y - a.Y * b.X end
	function V2M.Lerp(a, b, t) checkV2(b, 1, "Lerp") t = numArg(t, 2, "Lerp") return v2(a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t) end
	V2M.lerp = V2M.Lerp
	function V2M.Abs(a) return v2(abs(a.X), abs(a.Y)) end
	function V2M.Ceil(a) return v2(ceil(a.X), ceil(a.Y)) end
	function V2M.Floor(a) return v2(floor(a.X), floor(a.Y)) end
	function V2M.Sign(a) return v2(math.sign(a.X), math.sign(a.Y)) end
	function V2M.Max(a, ...) local x, y = a.X, a.Y for i = 1, select("#", ...) do local b = checkV2(select(i, ...), i, "Max") x, y = mmax(x, b.X), mmax(y, b.Y) end return v2(x, y) end
	function V2M.Min(a, ...) local x, y = a.X, a.Y for i = 1, select("#", ...) do local b = checkV2(select(i, ...), i, "Min") x, y = mmin(x, b.X), mmin(y, b.Y) end return v2(x, y) end
	function V2M.FuzzyEq(a, b, eps) checkV2(b, 1, "FuzzyEq") eps = eps or 1e-5 return abs(a.X - b.X) <= eps and abs(a.Y - b.Y) <= eps end
	function V2M.Angle(a, b, signed)
		checkV2(b, 1, "Angle")
		local ang = atan2(a.X * b.Y - a.Y * b.X, a.X * b.X + a.Y * b.Y)
		return signed and ang or abs(ang)
	end
	V2.__add = function(a, b) if getmetatable(a) ~= V2 then binErr(1, "Vector2", a) end if getmetatable(b) ~= V2 then binErr(2, "Vector2", b) end return v2(a.X + b.X, a.Y + b.Y) end
	V2.__sub = function(a, b) if getmetatable(a) ~= V2 then binErr(1, "Vector2", a) end if getmetatable(b) ~= V2 then binErr(2, "Vector2", b) end return v2(a.X - b.X, a.Y - b.Y) end
	V2.__mul = function(a, b)
		if nativeTypeof(a) == "number" then if getmetatable(b) ~= V2 then binErr(2, "Vector2", b) end return v2(a * b.X, a * b.Y) end
		if getmetatable(a) ~= V2 then binErr(1, "Vector2", a) end
		if nativeTypeof(b) == "number" then return v2(a.X * b, a.Y * b) end
		if getmetatable(b) == V2 then return v2(a.X * b.X, a.Y * b.Y) end
		binErr(2, "Vector2 or number", b)
		return nil
	end
	V2.__div = function(a, b)
		if nativeTypeof(a) == "number" then if getmetatable(b) ~= V2 then binErr(2, "Vector2", b) end return v2(a / b.X, a / b.Y) end
		if getmetatable(a) ~= V2 then binErr(1, "Vector2", a) end
		if nativeTypeof(b) == "number" then return v2(a.X / b, a.Y / b) end
		if getmetatable(b) == V2 then return v2(a.X / b.X, a.Y / b.Y) end
		binErr(2, "Vector2 or number", b)
		return nil
	end
	V2.__idiv = function(a, b) local q = V2.__div(a, b) return v2(floor(q.X), floor(q.Y)) end
	V2.__unm = function(a) return v2(-a.X, -a.Y) end
	V2.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
	V2.__tostring = function(a) return fmtn(a.X) .. ", " .. fmtn(a.Y) end
	H.Vector2 = freeze({
		new = function(x, y) return v2(numArg(x, 1, "new"), numArg(y, 2, "new")) end,
		zero = v2(0, 0), one = v2(1, 1), xAxis = v2(1, 0), yAxis = v2(0, 1),
	})
	H.isV2 = function(v) return getmetatable(v) == V2 end

	--------------------------------------------------------------------------------------------- CFrame
	-- stored as { X, Y, Z, r00, r01, r02, r10, r11, r12, r20, r21, r22 } (rotation row-major in the array part)
	local CFG, CFM = {}, {}
	local CF = makeType("CFrame", CFG, CFM)
	H.CFMT = CF
	local function cf(x, y, z, a, b, c, d, e, f, g, h, i)
		return freeze(setmetatable({ X = x, Y = y, Z = z, a, b, c, d, e, f, g, h, i }, CF))
	end
	H.cf = cf
	local function isCF(v) return getmetatable(v) == CF end
	H.isCF = isCF
	local function checkCF(v, i, fname) if getmetatable(v) ~= CF then badArg(i, fname, "CFrame", v) end return v end
	local IDENT = cf(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)

	local function mul(A, B)
		local a1, a2, a3, a4, a5, a6, a7, a8, a9 = A[1], A[2], A[3], A[4], A[5], A[6], A[7], A[8], A[9]
		local b1, b2, b3, b4, b5, b6, b7, b8, b9 = B[1], B[2], B[3], B[4], B[5], B[6], B[7], B[8], B[9]
		local bx, by, bz = B.X, B.Y, B.Z
		return cf(
			a1 * bx + a2 * by + a3 * bz + A.X, a4 * bx + a5 * by + a6 * bz + A.Y, a7 * bx + a8 * by + a9 * bz + A.Z,
			a1 * b1 + a2 * b4 + a3 * b7, a1 * b2 + a2 * b5 + a3 * b8, a1 * b3 + a2 * b6 + a3 * b9,
			a4 * b1 + a5 * b4 + a6 * b7, a4 * b2 + a5 * b5 + a6 * b8, a4 * b3 + a5 * b6 + a6 * b9,
			a7 * b1 + a8 * b4 + a9 * b7, a7 * b2 + a8 * b5 + a9 * b8, a7 * b3 + a8 * b6 + a9 * b9)
	end
	H.cfMul = mul
	local function inverse(A)
		local a1, a2, a3, a4, a5, a6, a7, a8, a9 = A[1], A[2], A[3], A[4], A[5], A[6], A[7], A[8], A[9]
		local x, y, z = A.X, A.Y, A.Z
		return cf(-(a1 * x + a4 * y + a7 * z), -(a2 * x + a5 * y + a8 * z), -(a3 * x + a6 * y + a9 * z),
			a1, a4, a7, a2, a5, a8, a3, a6, a9)
	end
	local function pointToWorld(A, v)
		local x, y, z = v.X, v.Y, v.Z
		return v3(A[1] * x + A[2] * y + A[3] * z + A.X, A[4] * x + A[5] * y + A[6] * z + A.Y, A[7] * x + A[8] * y + A[9] * z + A.Z)
	end
	local function pointToObject(A, v)
		local x, y, z = v.X - A.X, v.Y - A.Y, v.Z - A.Z
		return v3(A[1] * x + A[4] * y + A[7] * z, A[2] * x + A[5] * y + A[8] * z, A[3] * x + A[6] * y + A[9] * z)
	end
	local function vecToWorld(A, v)
		local x, y, z = v.X, v.Y, v.Z
		return v3(A[1] * x + A[2] * y + A[3] * z, A[4] * x + A[5] * y + A[6] * z, A[7] * x + A[8] * y + A[9] * z)
	end
	local function vecToObject(A, v)
		local x, y, z = v.X, v.Y, v.Z
		return v3(A[1] * x + A[4] * y + A[7] * z, A[2] * x + A[5] * y + A[8] * z, A[3] * x + A[6] * y + A[9] * z)
	end

	-- rotation helpers
	local function rotX(a) local c, s = cos(a), sin(a) return 1, 0, 0, 0, c, -s, 0, s, c end
	local function rotY(a) local c, s = cos(a), sin(a) return c, 0, s, 0, 1, 0, -s, 0, c end
	local function rotZ(a) local c, s = cos(a), sin(a) return c, -s, 0, s, c, 0, 0, 0, 1 end
	local function m3mul(a1, a2, a3, a4, a5, a6, a7, a8, a9, b1, b2, b3, b4, b5, b6, b7, b8, b9)
		return a1 * b1 + a2 * b4 + a3 * b7, a1 * b2 + a2 * b5 + a3 * b8, a1 * b3 + a2 * b6 + a3 * b9,
			a4 * b1 + a5 * b4 + a6 * b7, a4 * b2 + a5 * b5 + a6 * b8, a4 * b3 + a5 * b6 + a6 * b9,
			a7 * b1 + a8 * b4 + a9 * b7, a7 * b2 + a8 * b5 + a9 * b8, a7 * b3 + a8 * b6 + a9 * b9
	end
	local AXROT = { X = rotX, Y = rotY, Z = rotZ }
	-- R = R_first * R_second * R_third for an order like "XYZ" (Roblox's RotationOrder naming)
	local function eulerMatrix(order, rx, ry, rz)
		local ang = { X = rx, Y = ry, Z = rz }
		local o1, o2, o3 = order:sub(1, 1), order:sub(2, 2), order:sub(3, 3)
		local a = { AXROT[o1](ang[o1]) }
		local b = { AXROT[o2](ang[o2]) }
		local m = { m3mul(a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9]) }
		return m3mul(m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9], AXROT[o3](ang[o3]))
	end
	local function angles(rx, ry, rz)
		-- Rx * Ry * Rz, expanded
		local cx, sx, cy, sy, cz, sz = cos(rx), sin(rx), cos(ry), sin(ry), cos(rz), sin(rz)
		return cy * cz, -cy * sz, sy,
			cx * sz + sx * sy * cz, cx * cz - sx * sy * sz, -sx * cy,
			sx * sz - cx * sy * cz, sx * cz + cx * sy * sz, cx * cy
	end
	H.anglesMatrix = angles
	local IDX = { X = 0, Y = 1, Z = 2 }
	local function toEuler(A, order)
		-- Tait-Bryan decomposition of R = R_i(a) R_j(b) R_k(c); returns rx, ry, rz
		local i, j, k = IDX[order:sub(1, 1)], IDX[order:sub(2, 2)], IDX[order:sub(3, 3)]
		local function R(r, c) return A[r * 3 + c + 1] end
		local even = (i == 0 and j == 1) or (i == 1 and j == 2) or (i == 2 and j == 0)
		local s = even and 1 or -1
		local b = asin(mmax(-1, mmin(1, s * R(i, k))))
		local a, c
		if abs(R(i, k)) < 0.9999999 then
			a = atan2(-s * R(j, k), R(k, k))
			c = atan2(-s * R(i, j), R(i, i))
		else
			-- gimbal lock: put everything into the first angle
			a = atan2(s * R(k, j), R(j, j))
			c = 0
		end
		local out = {}
		out[i], out[j], out[k] = a, b, c
		return out[0], out[1], out[2]
	end
	local function toQuat(A)
		local m00, m01, m02, m10, m11, m12, m20, m21, m22 = A[1], A[2], A[3], A[4], A[5], A[6], A[7], A[8], A[9]
		local tr = m00 + m11 + m22
		local w, x, y, z
		if tr > 0 then
			local s = sqrt(tr + 1) * 2
			w = 0.25 * s; x = (m21 - m12) / s; y = (m02 - m20) / s; z = (m10 - m01) / s
		elseif m00 > m11 and m00 > m22 then
			local s = sqrt(1 + m00 - m11 - m22) * 2
			w = (m21 - m12) / s; x = 0.25 * s; y = (m01 + m10) / s; z = (m02 + m20) / s
		elseif m11 > m22 then
			local s = sqrt(1 + m11 - m00 - m22) * 2
			w = (m02 - m20) / s; x = (m01 + m10) / s; y = 0.25 * s; z = (m12 + m21) / s
		else
			local s = sqrt(1 + m22 - m00 - m11) * 2
			w = (m10 - m01) / s; x = (m02 + m20) / s; y = (m12 + m21) / s; z = 0.25 * s
		end
		return x, y, z, w
	end
	local function quatMatrix(x, y, z, w)
		local n = sqrt(x * x + y * y + z * z + w * w)
		if n == 0 then return 1, 0, 0, 0, 1, 0, 0, 0, 1 end
		x, y, z, w = x / n, y / n, z / n, w / n
		return 1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w),
			2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w),
			2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)
	end
	local function axisAngle(ax, ay, az, r)
		local m = sqrt(ax * ax + ay * ay + az * az)
		if m == 0 then return 1, 0, 0, 0, 1, 0, 0, 0, 1 end
		ax, ay, az = ax / m, ay / m, az / m
		local c, s = cos(r), sin(r)
		local t = 1 - c
		return t * ax * ax + c, t * ax * ay - s * az, t * ax * az + s * ay,
			t * ax * ay + s * az, t * ay * ay + c, t * ay * az - s * ax,
			t * ax * az - s * ay, t * ay * az + s * ax, t * az * az + c
	end
	local function lookAt(px, py, pz, tx, ty, tz, up)
		local zx, zy, zz = px - tx, py - ty, pz - tz
		local zm = sqrt(zx * zx + zy * zy + zz * zz)
		if zm < 1e-12 then return cf(px, py, pz, 1, 0, 0, 0, 1, 0, 0, 0, 1) end
		zx, zy, zz = zx / zm, zy / zm, zz / zm
		local ux, uy, uz = 0, 1, 0
		if up then ux, uy, uz = up.X, up.Y, up.Z end
		local xx, xy, xz = uy * zz - uz * zy, uz * zx - ux * zz, ux * zy - uy * zx
		local xm = sqrt(xx * xx + xy * xy + xz * xz)
		if xm < 1e-9 then
			-- looking along the up vector: pick another reference axis (Roblox does the same kind of fallback)
			ux, uy, uz = 0, 0, (zy > 0) and 1 or -1
			xx, xy, xz = uy * zz - uz * zy, uz * zx - ux * zz, ux * zy - uy * zx
			xm = sqrt(xx * xx + xy * xy + xz * xz)
		end
		xx, xy, xz = xx / xm, xy / xm, xz / xm
		local yx, yy, yz = zy * xz - zz * xy, zz * xx - zx * xz, zx * xy - zy * xx
		return cf(px, py, pz, xx, yx, zx, xy, yy, zy, xz, yz, zz)
	end

	CFG.Position = function(A) return v3(A.X, A.Y, A.Z) end
	CFG.p = CFG.Position
	CFG.Rotation = function(A) return cf(0, 0, 0, A[1], A[2], A[3], A[4], A[5], A[6], A[7], A[8], A[9]) end
	CFG.LookVector = function(A) return v3(-A[3], -A[6], -A[9]) end
	CFG.RightVector = function(A) return v3(A[1], A[4], A[7]) end
	CFG.UpVector = function(A) return v3(A[2], A[5], A[8]) end
	CFG.XVector = CFG.RightVector
	CFG.YVector = CFG.UpVector
	CFG.ZVector = function(A) return v3(A[3], A[6], A[9]) end
	CFG.lookVector, CFG.rightVector, CFG.upVector = CFG.LookVector, CFG.RightVector, CFG.UpVector
	CFG.x = function(A) return A.X end
	CFG.y = function(A) return A.Y end
	CFG.z = function(A) return A.Z end

	function CFM.Inverse(A) return inverse(A) end
	CFM.inverse = CFM.Inverse
	function CFM.GetComponents(A) return A.X, A.Y, A.Z, A[1], A[2], A[3], A[4], A[5], A[6], A[7], A[8], A[9] end
	CFM.components = CFM.GetComponents
	local function spaceFn(fn, check, tname)
		return function(A, ...)
			local n = select("#", ...)
			if n == 1 then
				local v = ...
				if getmetatable(v) ~= check then badArg(1, tname, check == CF and "CFrame" or "Vector3", v) end
				return fn(A, v)
			end
			local out = table.create(n)
			for i = 1, n do
				local v = select(i, ...)
				if getmetatable(v) ~= check then badArg(i, tname, check == CF and "CFrame" or "Vector3", v) end
				out[i] = fn(A, v)
			end
			return table.unpack(out, 1, n)
		end
	end
	CFM.ToWorldSpace = spaceFn(function(A, B) return mul(A, B) end, CF, "ToWorldSpace")
	CFM.ToObjectSpace = spaceFn(function(A, B) return mul(inverse(A), B) end, CF, "ToObjectSpace")
	CFM.PointToWorldSpace = spaceFn(pointToWorld, V3, "PointToWorldSpace")
	CFM.PointToObjectSpace = spaceFn(pointToObject, V3, "PointToObjectSpace")
	CFM.VectorToWorldSpace = spaceFn(vecToWorld, V3, "VectorToWorldSpace")
	CFM.VectorToObjectSpace = spaceFn(vecToObject, V3, "VectorToObjectSpace")
	CFM.toWorldSpace, CFM.toObjectSpace = CFM.ToWorldSpace, CFM.ToObjectSpace
	CFM.pointToWorldSpace, CFM.pointToObjectSpace = CFM.PointToWorldSpace, CFM.PointToObjectSpace
	CFM.vectorToWorldSpace, CFM.vectorToObjectSpace = CFM.VectorToWorldSpace, CFM.VectorToObjectSpace
	function CFM.ToEulerAnglesXYZ(A) return toEuler(A, "XYZ") end
	function CFM.ToEulerAnglesYXZ(A) return toEuler(A, "YXZ") end
	CFM.toEulerAnglesXYZ, CFM.toEulerAnglesYXZ = CFM.ToEulerAnglesXYZ, CFM.ToEulerAnglesYXZ
	CFM.ToOrientation = CFM.ToEulerAnglesYXZ
	function CFM.ToEulerAngles(A, order)
		local item = order == nil and { Name = "XYZ" } or H.coerceEnum("RotationOrder", order)
		if not item then badArg(1, "ToEulerAngles", "Enum.RotationOrder", order) end
		return toEuler(A, item.Name)
	end
	function CFM.ToAxisAngle(A)
		local x, y, z, w = toQuat(A)
		if w < 0 then x, y, z, w = -x, -y, -z, -w end
		local ang = 2 * acos(mmin(1, w))
		local s = sqrt(mmax(0, 1 - w * w))
		if s < 1e-9 then return v3(1, 0, 0), 0 end
		return v3(x / s, y / s, z / s), ang
	end
	CFM.toAxisAngle = CFM.ToAxisAngle
	function CFM.Lerp(A, B, t)
		checkCF(B, 1, "Lerp")
		t = numArg(t, 2, "Lerp")
		local ax, ay, az, aw = toQuat(A)
		local bx, by, bz, bw = toQuat(B)
		local d = ax * bx + ay * by + az * bz + aw * bw
		if d < 0 then bx, by, bz, bw, d = -bx, -by, -bz, -bw, -d end
		local qx, qy, qz, qw
		if d > 0.9995 then
			qx, qy, qz, qw = ax + (bx - ax) * t, ay + (by - ay) * t, az + (bz - az) * t, aw + (bw - aw) * t
		else
			local th = acos(d)
			local s = sin(th)
			local wa, wb = sin((1 - t) * th) / s, sin(t * th) / s
			qx, qy, qz, qw = ax * wa + bx * wb, ay * wa + by * wb, az * wa + bz * wb, aw * wa + bw * wb
		end
		local r1, r2, r3, r4, r5, r6, r7, r8, r9 = quatMatrix(qx, qy, qz, qw)
		return cf(A.X + (B.X - A.X) * t, A.Y + (B.Y - A.Y) * t, A.Z + (B.Z - A.Z) * t, r1, r2, r3, r4, r5, r6, r7, r8, r9)
	end
	CFM.lerp = CFM.Lerp
	function CFM.Orthonormalize(A)
		local xx, xy, xz = A[1], A[4], A[7]
		local yx, yy, yz = A[2], A[5], A[8]
		local m = sqrt(xx * xx + xy * xy + xz * xz)
		xx, xy, xz = xx / m, xy / m, xz / m
		local zx, zy, zz = xy * yz - xz * yy, xz * yx - xx * yz, xx * yy - xy * yx
		m = sqrt(zx * zx + zy * zy + zz * zz)
		zx, zy, zz = zx / m, zy / m, zz / m
		yx, yy, yz = zy * xz - zz * xy, zz * xx - zx * xz, zx * xy - zy * xx
		return cf(A.X, A.Y, A.Z, xx, yx, zx, xy, yy, zy, xz, yz, zz)
	end
	function CFM.FuzzyEq(A, B, eps)
		checkCF(B, 1, "FuzzyEq")
		eps = eps or 1e-5
		if abs(A.X - B.X) > eps or abs(A.Y - B.Y) > eps or abs(A.Z - B.Z) > eps then return false end
		for i = 1, 9 do if abs(A[i] - B[i]) > eps then return false end end
		return true
	end
	function CFM.AngleBetween(A, B)
		local x, y, z, w = toQuat(mul(inverse(A), B))
		return 2 * acos(mmin(1, abs(w)))
	end

	CF.__mul = function(A, B)
		if getmetatable(A) ~= CF then binErr(1, "CFrame", A) end
		local mb = getmetatable(B)
		if mb == CF then return mul(A, B) end
		if mb == V3 then return pointToWorld(A, B) end
		binErr(2, "CFrame or Vector3", B)
		return nil
	end
	CF.__add = function(A, B)
		if getmetatable(A) ~= CF then binErr(1, "CFrame", A) end
		if getmetatable(B) ~= V3 then binErr(2, "Vector3", B) end
		return cf(A.X + B.X, A.Y + B.Y, A.Z + B.Z, A[1], A[2], A[3], A[4], A[5], A[6], A[7], A[8], A[9])
	end
	CF.__sub = function(A, B)
		if getmetatable(A) ~= CF then binErr(1, "CFrame", A) end
		if getmetatable(B) ~= V3 then binErr(2, "Vector3", B) end
		return cf(A.X - B.X, A.Y - B.Y, A.Z - B.Z, A[1], A[2], A[3], A[4], A[5], A[6], A[7], A[8], A[9])
	end
	CF.__eq = function(A, B)
		if A.X ~= B.X or A.Y ~= B.Y or A.Z ~= B.Z then return false end
		for i = 1, 9 do if A[i] ~= B[i] then return false end end
		return true
	end
	CF.__tostring = function(A)
		local t = { fmtn(A.X), fmtn(A.Y), fmtn(A.Z) }
		for i = 1, 9 do t[#t + 1] = fmtn(A[i]) end
		return table.concat(t, ", ")
	end

	local CFrame = { identity = IDENT }
	function CFrame.new(...)
		local n = select("#", ...)
		if n == 0 then return IDENT end
		local a, b = ...
		if getmetatable(a) == V3 then
			if n == 1 then return cf(a.X, a.Y, a.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1) end
			if getmetatable(b) ~= V3 then badArg(2, "new", "Vector3", b) end
			return lookAt(a.X, a.Y, a.Z, b.X, b.Y, b.Z)
		end
		local v = { ... }
		for i = 1, n do v[i] = numArg(v[i], i, "new") end
		if n <= 3 then return cf(v[1] or 0, v[2] or 0, v[3] or 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) end
		if n == 7 then return cf(v[1], v[2], v[3], quatMatrix(v[4], v[5], v[6], v[7])) end
		if n == 12 then return cf(v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9], v[10], v[11], v[12]) end
		err(format("Invalid number of arguments: %d", n))
		return nil
	end
	function CFrame.lookAt(at, target, up)
		checkV3(at, 1, "lookAt"); checkV3(target, 2, "lookAt")
		if up ~= nil then checkV3(up, 3, "lookAt") end
		return lookAt(at.X, at.Y, at.Z, target.X, target.Y, target.Z, up)
	end
	function CFrame.lookAlong(at, dir, up)
		checkV3(at, 1, "lookAlong"); checkV3(dir, 2, "lookAlong")
		if up ~= nil then checkV3(up, 3, "lookAlong") end
		return lookAt(at.X, at.Y, at.Z, at.X + dir.X, at.Y + dir.Y, at.Z + dir.Z, up)
	end
	function CFrame.Angles(rx, ry, rz)
		return cf(0, 0, 0, angles(numArg(rx, 1, "Angles"), numArg(ry, 2, "Angles"), numArg(rz, 3, "Angles")))
	end
	CFrame.fromEulerAnglesXYZ = CFrame.Angles
	function CFrame.fromEulerAnglesYXZ(rx, ry, rz)
		return cf(0, 0, 0, eulerMatrix("YXZ", numArg(rx, 1, "fromEulerAnglesYXZ"), numArg(ry, 2, "fromEulerAnglesYXZ"), numArg(rz, 3, "fromEulerAnglesYXZ")))
	end
	CFrame.fromOrientation = CFrame.fromEulerAnglesYXZ
	function CFrame.fromEulerAngles(rx, ry, rz, order)
		local item = order == nil and { Name = "XYZ" } or H.coerceEnum("RotationOrder", order)
		if not item then badArg(4, "fromEulerAngles", "Enum.RotationOrder", order) end
		return cf(0, 0, 0, eulerMatrix(item.Name, numArg(rx, 1, "fromEulerAngles"), numArg(ry, 2, "fromEulerAngles"), numArg(rz, 3, "fromEulerAngles")))
	end
	function CFrame.fromAxisAngle(axis, r)
		checkV3(axis, 1, "fromAxisAngle")
		return cf(0, 0, 0, axisAngle(axis.X, axis.Y, axis.Z, numArg(r, 2, "fromAxisAngle")))
	end
	function CFrame.fromMatrix(pos, vx, vy, vz)
		checkV3(pos, 1, "fromMatrix"); checkV3(vx, 2, "fromMatrix"); checkV3(vy, 3, "fromMatrix")
		if vz == nil then
			vz = v3(vx.Y * vy.Z - vx.Z * vy.Y, vx.Z * vy.X - vx.X * vy.Z, vx.X * vy.Y - vx.Y * vy.X)
			local m = sqrt(vz.X * vz.X + vz.Y * vz.Y + vz.Z * vz.Z)
			vz = v3(vz.X / m, vz.Y / m, vz.Z / m)
		else
			checkV3(vz, 4, "fromMatrix")
		end
		return cf(pos.X, pos.Y, pos.Z, vx.X, vy.X, vz.X, vx.Y, vy.Y, vz.Y, vx.Z, vy.Z, vz.Z)
	end
	H.CFrame = freeze(CFrame)
	H.CF_IDENT = IDENT

	--------------------------------------------------------------------------------------------- Color3
	local C3G, C3M = {}, {}
	local C3 = makeType("Color3", C3G, C3M)
	local function c3(r, g, b) return freeze(setmetatable({ R = r, G = g, B = b }, C3)) end
	H.c3 = c3
	H.isC3 = function(v) return getmetatable(v) == C3 end
	C3G.r = function(c) return c.R end
	C3G.g = function(c) return c.G end
	C3G.b = function(c) return c.B end
	local function toHSV(c)
		local r, g, b = c.R, c.G, c.B
		local mx, mn = mmax(r, g, b), mmin(r, g, b)
		local d = mx - mn
		local h = 0
		if d > 0 then
			if mx == r then h = ((g - b) / d) % 6
			elseif mx == g then h = (b - r) / d + 2
			else h = (r - g) / d + 4 end
			h = h / 6
		end
		local s = mx == 0 and 0 or d / mx
		return h, s, mx
	end
	H.toHSV = toHSV
	function C3M.Lerp(a, b, t)
		if getmetatable(b) ~= C3 then badArg(1, "Lerp", "Color3", b) end
		t = numArg(t, 2, "Lerp")
		return c3(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
	end
	C3M.lerp = C3M.Lerp
	C3M.ToHSV = toHSV
	function C3M.ToHex(c)
		local function b(x) return mmax(0, mmin(255, floor(x * 255 + 0.5))) end
		return format("%02X%02X%02X", b(c.R), b(c.G), b(c.B))
	end
	C3.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end
	C3.__tostring = function(c) return fmtn(c.R) .. ", " .. fmtn(c.G) .. ", " .. fmtn(c.B) end
	local function fromHSV(h, s, v)
		h = (h % 1) * 6
		local i = floor(h)
		local f = h - i
		local p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
		i = i % 6
		if i == 0 then return c3(v, t, p) elseif i == 1 then return c3(q, v, p) elseif i == 2 then return c3(p, v, t)
		elseif i == 3 then return c3(p, q, v) elseif i == 4 then return c3(t, p, v) end
		return c3(v, p, q)
	end
	H.Color3 = freeze({
		new = function(r, g, b) return c3(numArg(r, 1, "new"), numArg(g, 2, "new"), numArg(b, 3, "new")) end,
		fromRGB = function(r, g, b)
			r, g, b = numArg(r, 1, "fromRGB"), numArg(g, 2, "fromRGB"), numArg(b, 3, "fromRGB")
			return c3(mmax(0, mmin(255, floor(r))) / 255, mmax(0, mmin(255, floor(g))) / 255, mmax(0, mmin(255, floor(b))) / 255)
		end,
		fromHSV = function(h, s, v) return fromHSV(numArg(h, 1, "fromHSV"), numArg(s, 2, "fromHSV"), numArg(v, 3, "fromHSV")) end,
		fromHex = function(hex)
			if nativeTypeof(hex) ~= "string" then badArg(1, "fromHex", "string", hex) end
			local h = hex:gsub("^#", "")
			if #h == 3 then h = h:sub(1, 1):rep(2) .. h:sub(2, 2):rep(2) .. h:sub(3, 3):rep(2) end
			if #h ~= 6 or not h:match("^%x+$") then err("Unable to convert characters to hex value") end
			return c3(tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255)
		end,
		toHSV = function(c)
			if getmetatable(c) ~= C3 then badArg(1, "toHSV", "Color3", c) end
			return toHSV(c)
		end,
	})

	--------------------------------------------------------------------------------------------- UDim / UDim2
	local UDG, UDM = {}, {}
	local UD = makeType("UDim", UDG, UDM)
	local function udim(s, o) return freeze(setmetatable({ Scale = s, Offset = o }, UD)) end
	H.udim = udim
	UD.__add = function(a, b) if getmetatable(b) ~= UD or getmetatable(a) ~= UD then binErr(2, "UDim", b) end return udim(a.Scale + b.Scale, a.Offset + b.Offset) end
	UD.__sub = function(a, b) if getmetatable(b) ~= UD or getmetatable(a) ~= UD then binErr(2, "UDim", b) end return udim(a.Scale - b.Scale, a.Offset - b.Offset) end
	UD.__unm = function(a) return udim(-a.Scale, -a.Offset) end
	UD.__eq = function(a, b) return a.Scale == b.Scale and a.Offset == b.Offset end
	UD.__tostring = function(a) return fmtn(a.Scale) .. ", " .. fmtn(a.Offset) end
	function UDM.Lerp(a, b, t) return udim(a.Scale + (b.Scale - a.Scale) * t, a.Offset + (b.Offset - a.Offset) * t) end
	H.UDim = freeze({ new = function(s, o) return udim(numArg(s, 1, "new"), floor(numArg(o, 2, "new"))) end })

	local U2G, U2M = {}, {}
	local U2 = makeType("UDim2", U2G, U2M)
	local function udim2(sx, ox, sy, oy) return freeze(setmetatable({ X = udim(sx, ox), Y = udim(sy, oy) }, U2)) end
	H.udim2 = udim2
	H.isUDim2 = function(v) return getmetatable(v) == U2 end
	U2G.Width = function(u) return u.X end
	U2G.Height = function(u) return u.Y end
	function U2M.Lerp(a, b, t)
		if getmetatable(b) ~= U2 then badArg(1, "Lerp", "UDim2", b) end
		t = numArg(t, 2, "Lerp")
		return udim2(a.X.Scale + (b.X.Scale - a.X.Scale) * t, a.X.Offset + (b.X.Offset - a.X.Offset) * t,
			a.Y.Scale + (b.Y.Scale - a.Y.Scale) * t, a.Y.Offset + (b.Y.Offset - a.Y.Offset) * t)
	end
	U2.__add = function(a, b) if getmetatable(b) ~= U2 or getmetatable(a) ~= U2 then binErr(2, "UDim2", b) end return udim2(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset) end
	U2.__sub = function(a, b) if getmetatable(b) ~= U2 or getmetatable(a) ~= U2 then binErr(2, "UDim2", b) end return udim2(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset) end
	U2.__unm = function(a) return udim2(-a.X.Scale, -a.X.Offset, -a.Y.Scale, -a.Y.Offset) end
	U2.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
	U2.__tostring = function(a) return "{" .. tostring(a.X) .. "}, {" .. tostring(a.Y) .. "}" end
	H.UDim2 = freeze({
		new = function(a, b, c, d)
			if getmetatable(a) == UD then
				if getmetatable(b) ~= UD then badArg(2, "new", "UDim", b) end
				return freeze(setmetatable({ X = a, Y = b }, U2))
			end
			return udim2(numArg(a, 1, "new"), floor(numArg(b, 2, "new")), numArg(c, 3, "new"), floor(numArg(d, 4, "new")))
		end,
		fromScale = function(x, y) return udim2(numArg(x, 1, "fromScale"), 0, numArg(y, 2, "fromScale"), 0) end,
		fromOffset = function(x, y) return udim2(0, floor(numArg(x, 1, "fromOffset")), 0, floor(numArg(y, 2, "fromOffset"))) end,
	})

	--------------------------------------------------------------------------------------------- NumberRange
	local NRM = makeType("NumberRange", {}, {})
	local function nrange(a, b) return freeze(setmetatable({ Min = a, Max = b }, NRM)) end
	H.nrange = nrange
	NRM.__eq = function(a, b) return a.Min == b.Min and a.Max == b.Max end
	NRM.__tostring = function(a) return fmtn(a.Min) .. " " .. fmtn(a.Max) .. " " end
	H.NumberRange = freeze({
		new = function(a, b)
			a = numArg(a, 1, "new")
			if b == nil then b = a else b = numArg(b, 2, "new") end
			if b < a then err("NumberRange: invalid range (max must be >= min)") end
			return nrange(a, b)
		end,
	})

	--------------------------------------------------------------------------------------------- NumberSequence
	local NSKM = makeType("NumberSequenceKeypoint", {}, {})
	local function nskp(t, v, e) return freeze(setmetatable({ Time = t, Value = v, Envelope = e }, NSKM)) end
	NSKM.__eq = function(a, b) return a.Time == b.Time and a.Value == b.Value and a.Envelope == b.Envelope end
	NSKM.__tostring = function(a) return fmtn(a.Time) .. " " .. fmtn(a.Value) .. " " .. fmtn(a.Envelope) end
	H.NumberSequenceKeypoint = freeze({
		new = function(t, v, e)
			t, v = numArg(t, 1, "new"), numArg(v, 2, "new")
			e = numArg(e, 3, "new")
			if e < 0 then err("NumberSequenceKeypoint: envelope must be non-negative") end
			return nskp(t, v, e)
		end,
	})
	local NSM = makeType("NumberSequence", {}, {})
	local function checkSeq(kind, kps)
		local n = #kps
		if n < 2 then err(kind .. ": requires at least 2 keypoints") end
		if n > 20 then err(kind .. ": table is too long.") end
		if kps[1].Time ~= 0 or kps[n].Time ~= 1 then err(kind .. " time must start at 0, and end at 1") end
		for i = 2, n do
			if kps[i].Time < kps[i - 1].Time then err(kind .. ": all keypoints must be ordered by time") end
		end
	end
	local function nseq(kps) return freeze(setmetatable({ Keypoints = freeze(kps) }, NSM)) end
	H.nseq = nseq
	NSM.__eq = function(a, b)
		local ka, kb = a.Keypoints, b.Keypoints
		if #ka ~= #kb then return false end
		for i = 1, #ka do if ka[i] ~= kb[i] then return false end end
		return true
	end
	NSM.__tostring = function(a)
		local t = {}
		for _, k in ipairs(a.Keypoints) do t[#t + 1] = tostring(k) end
		return table.concat(t, " ") .. " "
	end
	H.NumberSequence = freeze({
		new = function(a, b)
			if nativeTypeof(a) == "table" and getmetatable(a) == nil then
				local kps = {}
				for i, k in ipairs(a) do
					if getmetatable(k) ~= NSKM then badArg(1, "new", "array of NumberSequenceKeypoints", k) end
					kps[i] = k
				end
				checkSeq("NumberSequence", kps)
				return nseq(kps)
			end
			a = numArg(a, 1, "new")
			if b == nil then b = a else b = numArg(b, 2, "new") end
			return nseq({ nskp(0, a, 0), nskp(1, b, 0) })
		end,
	})

	--------------------------------------------------------------------------------------------- ColorSequence
	local CSKM = makeType("ColorSequenceKeypoint", {}, {})
	local function cskp(t, c) return freeze(setmetatable({ Time = t, Value = c, Envelope = 0 }, CSKM)) end
	CSKM.__eq = function(a, b) return a.Time == b.Time and a.Value == b.Value end
	CSKM.__tostring = function(a) return fmtn(a.Time) .. " " .. fmtn(a.Value.R) .. " " .. fmtn(a.Value.G) .. " " .. fmtn(a.Value.B) .. " 0" end
	H.ColorSequenceKeypoint = freeze({
		new = function(t, c)
			t = numArg(t, 1, "new")
			if getmetatable(c) ~= C3 then badArg(2, "new", "Color3", c) end
			return cskp(t, c)
		end,
	})
	local CSM = makeType("ColorSequence", {}, {})
	local function cseq(kps) return freeze(setmetatable({ Keypoints = freeze(kps) }, CSM)) end
	H.cseq = cseq
	CSM.__eq = NSM.__eq
	CSM.__tostring = NSM.__tostring
	H.ColorSequence = freeze({
		new = function(a, b)
			if getmetatable(a) == C3 then
				if b == nil then b = a end
				if getmetatable(b) ~= C3 then badArg(2, "new", "Color3", b) end
				return cseq({ cskp(0, a), cskp(1, b) })
			end
			if nativeTypeof(a) == "table" and getmetatable(a) == nil then
				local kps = {}
				for i, k in ipairs(a) do
					if getmetatable(k) ~= CSKM then badArg(1, "new", "array of ColorSequenceKeypoints", k) end
					kps[i] = k
				end
				checkSeq("ColorSequence", kps)
				return cseq(kps)
			end
			badArg(1, "new", "Color3 or table", a)
			return nil
		end,
	})

	--------------------------------------------------------------------------------------------- Rect
	local RCG = {}
	local RCM = makeType("Rect", RCG, {})
	local function rect(x0, y0, x1, y1) return freeze(setmetatable({ Min = v2(x0, y0), Max = v2(x1, y1) }, RCM)) end
	RCG.Width = function(r) return r.Max.X - r.Min.X end
	RCG.Height = function(r) return r.Max.Y - r.Min.Y end
	RCM.__eq = function(a, b) return a.Min == b.Min and a.Max == b.Max end
	RCM.__tostring = function(r) return tostring(r.Min) .. ", " .. tostring(r.Max) end
	H.Rect = freeze({
		new = function(a, b, c, d)
			if getmetatable(a) == V2 then
				if getmetatable(b) ~= V2 then badArg(2, "new", "Vector2", b) end
				return rect(a.X, a.Y, b.X, b.Y)
			end
			return rect(numArg(a, 1, "new"), numArg(b, 2, "new"), numArg(c, 3, "new"), numArg(d, 4, "new"))
		end,
	})

	--------------------------------------------------------------------------------------------- TweenInfo
	local TIM = makeType("TweenInfo", {}, {})
	TIM.__tostring = function(t)
		return format("Time:%s DelayTime:%s RepeatCount:%d Reverses:%s EasingDirection:%s EasingStyle:%s", fmtn(t.Time), fmtn(t.DelayTime),
			t.RepeatCount, t.Reverses and "True" or "False", t.EasingDirection.Name, t.EasingStyle.Name)
	end
	H.TweenInfo = freeze({
		new = function(time, style, dir, rep, rev, delay)
			local s = style == nil and H.Enum.EasingStyle.Quad or H.coerceEnum("EasingStyle", style)
			if not s then badArg(2, "new", "Enum.EasingStyle", style) end
			local d = dir == nil and H.Enum.EasingDirection.Out or H.coerceEnum("EasingDirection", dir)
			if not d then badArg(3, "new", "Enum.EasingDirection", dir) end
			if rev ~= nil and nativeTypeof(rev) ~= "boolean" then badArg(5, "new", "boolean", rev) end
			return freeze(setmetatable({ Time = numArg(time, 1, "new", 1), EasingStyle = s, EasingDirection = d,
				RepeatCount = floor(numArg(rep, 4, "new", 0)), Reverses = rev == true, DelayTime = numArg(delay, 6, "new", 0) }, TIM))
		end,
	})

	--------------------------------------------------------------------------------------------- Random
	local RNM = {}
	local RNG = makeType("Random", {}, RNM)
	local M31 = 2147483647
	local function step(r) r._s = (r._s * 48271) % M31 return r._s end
	local function unit(r) return (step(r) - 1) / (M31 - 1) end
	local function newRandom(seed)
		local s = (floor(abs(seed)) % (M31 - 1)) + 1
		local r = setmetatable({ _s = s }, RNG) -- (mutable state: not frozen)
		step(r); step(r)
		return r
	end
	function RNM.NextNumber(r, a, b)
		local u = unit(r)
		if a == nil then return u end
		a, b = numArg(a, 1, "NextNumber"), numArg(b, 2, "NextNumber")
		return a + (b - a) * u
	end
	function RNM.NextInteger(r, a, b)
		a, b = floor(numArg(a, 1, "NextInteger")), floor(numArg(b, 2, "NextInteger"))
		if a > b then err("invalid argument #2 to 'NextInteger' (interval is empty)") end
		return a + floor(unit(r) * (b - a + 1))
	end
	function RNM.NextUnitVector(r)
		local z = unit(r) * 2 - 1
		local t = unit(r) * 2 * pi
		local s = sqrt(1 - z * z)
		return v3(s * cos(t), s * sin(t), z)
	end
	function RNM.Shuffle(r, t)
		for i = #t, 2, -1 do
			local j = 1 + floor(unit(r) * i)
			t[i], t[j] = t[j], t[i]
		end
	end
	function RNM.Clone(r) return setmetatable({ _s = r._s }, RNG) end
	RNG.__newindex = nil
	H.Random = freeze({
		new = function(seed)
			if seed == nil then seed = H.nextSeed() end
			return newRandom(numArg(seed, 1, "new"))
		end,
	})

	--------------------------------------------------------------------------------------------- BrickColor (minimal)
	local PALETTE = {
		{ 1, "White", 242, 243, 243 }, { 194, "Medium stone grey", 163, 162, 165 }, { 199, "Dark stone grey", 99, 95, 98 },
		{ 26, "Black", 27, 42, 53 }, { 1003, "Really black", 17, 17, 17 }, { 1001, "Institutional white", 248, 248, 248 },
		{ 21, "Bright red", 196, 40, 28 }, { 24, "Bright yellow", 245, 205, 48 }, { 28, "Dark green", 40, 127, 71 },
		{ 23, "Bright blue", 13, 105, 172 }, { 1002, "Mid gray", 205, 205, 205 }, { 208, "Light stone grey", 229, 228, 223 },
		{ 1004, "Really red", 255, 0, 0 }, { 1010, "Really blue", 0, 0, 255 }, { 1020, "Lime green", 0, 255, 0 },
		{ 1005, "Deep orange", 255, 176, 0 }, { 1009, "New Yeller", 255, 255, 0 }, { 1013, "Toothpaste", 0, 255, 255 },
		{ 1032, "Hot pink", 255, 0, 191 }, { 1015, "Magenta", 170, 0, 170 }, { 325, "Quill grey", 223, 223, 222 },
		{ 1031, "Royal purple", 98, 37, 209 }, { 192, "Reddish brown", 105, 64, 40 }, { 38, "Dark orange", 160, 95, 53 },
		{ 1012, "Deep blue", 33, 84, 185 }, { 1019, "Cyan", 4, 175, 236 }, { 1022, "Grime", 127, 142, 100 },
	}
	local BCG = {}
	local BCM = makeType("BrickColor", BCG, {})
	BCG.r = function(b) return b.Color.R end
	BCG.g = function(b) return b.Color.G end
	BCG.b = function(b) return b.Color.B end
	BCM.__eq = function(a, b) return a.Number == b.Number end
	BCM.__tostring = function(b) return b.Name end
	local function bc(e) return freeze(setmetatable({ Number = e[1], Name = e[2], Color = c3(e[3] / 255, e[4] / 255, e[5] / 255) }, BCM)) end
	local byName, byNum = {}, {}
	for _, e in ipairs(PALETTE) do byName[e[2]] = e; byNum[e[1]] = e end
	local function nearest(r, g, b)
		local best, bd = PALETTE[2], huge
		for _, e in ipairs(PALETTE) do
			local d = (e[3] / 255 - r) ^ 2 + (e[4] / 255 - g) ^ 2 + (e[5] / 255 - b) ^ 2
			if d < bd then best, bd = e, d end
		end
		return bc(best)
	end
	H.brickFromColor = function(c) return nearest(c.R, c.G, c.B) end
	H.BrickColor = freeze({
		new = function(a, b, c)
			if nativeTypeof(a) == "string" then return bc(byName[a] or PALETTE[2]) end
			if getmetatable(a) == C3 then return nearest(a.R, a.G, a.B) end
			if b ~= nil then return nearest(numArg(a, 1, "new"), numArg(b, 2, "new"), numArg(c, 3, "new")) end
			return bc(byNum[numArg(a, 1, "new")] or PALETTE[2])
		end,
		random = function() return bc(PALETTE[1 + floor(math.random() * #PALETTE)]) end,
		palette = function(i) return bc(PALETTE[1 + (floor(i) % #PALETTE)]) end,
		White = function() return bc(byNum[1]) end, Gray = function() return bc(byNum[194]) end,
		DarkGray = function() return bc(byNum[199]) end, Black = function() return bc(byNum[26]) end,
		Red = function() return bc(byNum[21]) end, Yellow = function() return bc(byNum[24]) end,
		Green = function() return bc(byNum[28]) end, Blue = function() return bc(byNum[23]) end,
	})

	--------------------------------------------------------------------------------------------- Ray, Region3
	local RYG, RYM = {}, {}
	local RY = makeType("Ray", RYG, RYM)
	local function ray(o, d) return freeze(setmetatable({ Origin = o, Direction = d }, RY)) end
	RYG.Unit = function(r) return ray(r.Origin, r.Direction.Unit) end
	function RYM.ClosestPoint(r, p)
		local d = r.Direction.Unit
		local t = mmax(0, (p - r.Origin):Dot(d))
		return r.Origin + d * t
	end
	function RYM.Distance(r, p) return (p - RYM.ClosestPoint(r, p)).Magnitude end
	RY.__tostring = function(r) return "{" .. tostring(r.Origin) .. "}, {" .. tostring(r.Direction) .. "}" end
	H.Ray = freeze({ new = function(o, d) checkV3(o, 1, "new"); checkV3(d, 2, "new") return ray(o, d) end })
	local R3M = makeType("Region3", {}, {})
	H.Region3 = freeze({
		new = function(a, b)
			checkV3(a, 1, "new"); checkV3(b, 2, "new")
			local c = (a + b) / 2
			return freeze(setmetatable({ CFrame = cf(c.X, c.Y, c.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1), Size = b - a }, R3M))
		end,
	})

	--------------------------------------------------------------------------------------------- RaycastParams / OverlapParams / RaycastResult
	local function paramType(name, fields)
		local mt = {}
		TYPEOF[mt] = name
		mt.__index = function(p, k)
			local f = fields[k]
			if f == nil then err(format("%s is not a valid member of %s", tostring(k), name)) end
			local v = rawget(p, "_v")[k]
			if v == nil and f.default ~= nil then return f.default() end
			return v
		end
		mt.__newindex = function(p, k, v)
			local f = fields[k]
			if f == nil or f.method then err(format("%s is not a valid member of %s", tostring(k), name)) end
			rawget(p, "_v")[k] = f.check(v, k)
		end
		mt.__tostring = function() return name end
		return mt
	end
	local function instList(v, k)
		if nativeTypeof(v) ~= "table" or getmetatable(v) ~= nil then err(format("Unable to assign property %s. Array of Instances expected", k)) end
		local out = {}
		for i, x in ipairs(v) do
			if not (H.INST_DATA and H.INST_DATA[x]) then err(format("Unable to assign property %s. Array element %d is not an Instance", k, i)) end
			out[i] = x
		end
		return out
	end
	local function enumCheck(en) return function(v, k)
		local it = H.coerceEnum(en, v)
		if not it then err(format("Unable to assign property %s. Invalid value for enum %s", k, en)) end
		return it
	end end
	local function boolCheck(v, k) if nativeTypeof(v) ~= "boolean" then err(format("Unable to assign property %s. bool expected, got %s", k, typeof(v))) end return v end
	local function strCheck(v, k) if nativeTypeof(v) ~= "string" then err(format("Unable to assign property %s. string expected, got %s", k, typeof(v))) end return v end
	local function numCheck(v, k) if nativeTypeof(v) ~= "number" then err(format("Unable to assign property %s. number expected, got %s", k, typeof(v))) end return v end
	local function addToFilter(p, x)
		local v = rawget(p, "_v")
		local l = v.FilterDescendantsInstances or {}
		if nativeTypeof(x) == "table" and getmetatable(x) == nil then for _, i in ipairs(x) do l[#l + 1] = i end else l[#l + 1] = x end
		v.FilterDescendantsInstances = l
	end
	local RPF = {
		FilterDescendantsInstances = { check = instList, default = function() return {} end },
		FilterType = { check = enumCheck("RaycastFilterType"), default = function() return H.Enum.RaycastFilterType.Exclude end },
		IgnoreWater = { check = boolCheck, default = function() return false end },
		CollisionGroup = { check = strCheck, default = function() return "Default" end },
		RespectCanCollide = { check = boolCheck, default = function() return false end },
		BruteForceAllSlow = { check = boolCheck, default = function() return false end },
		AddToFilter = { method = true, default = function() return addToFilter end },
	}
	local RPM = paramType("RaycastParams", RPF)
	H.RaycastParams = freeze({ new = function() return setmetatable({ _v = {} }, RPM) end })
	H.RaycastParamsMT = RPM
	local OPF = H.shallowCopy(RPF)
	OPF.IgnoreWater = nil
	OPF.MaxParts = { check = numCheck, default = function() return 0 end }
	local OPM = paramType("OverlapParams", OPF)
	H.OverlapParams = freeze({ new = function() return setmetatable({ _v = {} }, OPM) end })
	local RRM = makeType("RaycastResult", {}, {})
	RRM.__tostring = function() return "RaycastResult" end
	function H.raycastResult(inst, pos, normal, material, dist)
		return freeze(setmetatable({ Instance = inst, Position = pos, Normal = normal, Material = material, Distance = dist }, RRM))
	end

	--------------------------------------------------------------------------------------------- misc small types
	local PPM = makeType("PhysicalProperties", {}, {})
	H.PhysicalProperties = freeze({
		new = function(a, b, c, d, e)
			if nativeTypeof(a) ~= "number" then return freeze(setmetatable({ Density = 0.7, Friction = 0.3, Elasticity = 0.5, FrictionWeight = 1, ElasticityWeight = 1 }, PPM)) end
			return freeze(setmetatable({ Density = a, Friction = numArg(b, 2, "new"), Elasticity = numArg(c, 3, "new"), FrictionWeight = numArg(d, 4, "new", 1), ElasticityWeight = numArg(e, 5, "new", 1) }, PPM))
		end,
	})
	local FCM = makeType("Faces", {}, {})
	H.Faces = freeze({ new = function(...)
		local f = { Top = false, Bottom = false, Left = false, Right = false, Back = false, Front = false }
		for i = 1, select("#", ...) do local it = select(i, ...) if nativeTypeof(it) == "table" and it.Name then f[it.Name] = true end end
		return freeze(setmetatable(f, FCM))
	end })
	local AXM = makeType("Axes", {}, {})
	H.Axes = freeze({ new = function(...)
		local f = { X = false, Y = false, Z = false }
		for i = 1, select("#", ...) do local it = select(i, ...) if nativeTypeof(it) == "table" and it.Name then f[it.Name] = true end end
		return freeze(setmetatable(f, AXM))
	end })
	local FNM = makeType("Font", {}, {})
	local function font(family, w, s)
		return freeze(setmetatable({ Family = family, Weight = w or H.Enum.FontWeight.Regular, Style = s or H.Enum.FontStyle.Normal, Bold = false }, FNM))
	end
	H.Font = freeze({
		new = function(family, w, s) if nativeTypeof(family) ~= "string" then badArg(1, "new", "string", family) end return font(family, w, s) end,
		fromEnum = function(e) return font("rbxasset://fonts/families/" .. (e and e.Name or "SourceSansPro") .. ".json") end,
		fromName = function(n, w, s) return font("rbxasset://fonts/families/" .. tostring(n) .. ".json", w, s) end,
		fromId = function(id, w, s) return font("rbxassetid://" .. tostring(id), w, s) end,
	})
	local DTG, DTM = {}, {}
	local DTMT = makeType("DateTime", DTG, DTM)
	local function dt(ms) return freeze(setmetatable({ UnixTimestampMillis = floor(ms) }, DTMT)) end
	DTG.UnixTimestamp = function(d) return floor(d.UnixTimestampMillis / 1000) end
	function DTM.ToIsoDate(d) return os.date("!%Y-%m-%dT%H:%M:%SZ", floor(d.UnixTimestampMillis / 1000)) end
	function DTM.ToUniversalTime(d)
		local t = os.date("!*t", floor(d.UnixTimestampMillis / 1000))
		return { Year = t.year, Month = t.month, Day = t.day, Hour = t.hour, Minute = t.min, Second = t.sec, Millisecond = d.UnixTimestampMillis % 1000 }
	end
	DTM.ToLocalTime = DTM.ToUniversalTime
	function DTM.FormatUniversalTime(d) return DTM.ToIsoDate(d) end
	DTM.FormatLocalTime = DTM.FormatUniversalTime
	H.DateTime = freeze({
		now = function() return dt(H.epochNow() * 1000) end,
		fromUnixTimestamp = function(s) return dt(numArg(s, 1, "fromUnixTimestamp") * 1000) end,
		fromUnixTimestampMillis = function(ms) return dt(numArg(ms, 1, "fromUnixTimestampMillis")) end,
	})
	local CTG = {}
	local CTM = makeType("Content", CTG, {})
	CTG.SourceType = function(c) return c.Uri and H.Enum.ContentSourceType.Uri or H.Enum.ContentSourceType.None end
	CTG.Uri = function() return nil end
	CTG.Object = function() return nil end
	CTM.__eq = function(a, b) return a.Uri == b.Uri end
	CTM.__tostring = function(c) return c.Uri or "" end
	local function content(uri) return freeze(setmetatable({ Uri = uri }, CTM)) end
	H.isContent = function(v) return getmetatable(v) == CTM end
	H.Content = freeze({
		fromUri = function(u) if nativeTypeof(u) ~= "string" then badArg(1, "fromUri", "string", u) end return content(u) end,
		fromAssetId = function(id) return content("rbxassetid://" .. tostring(numArg(id, 1, "fromAssetId"))) end,
		fromObject = function() err("Content.fromObject: EditableImage/EditableMesh are not supported by the harness") end,
		none = content(nil),
	})
	H.contentFromString = function(s) return content(s ~= "" and s or nil) end
	local V3I = makeType("Vector3int16", {}, {})
	H.Vector3int16 = freeze({ new = function(x, y, z) return freeze(setmetatable({ X = floor(numArg(x, 1, "new")), Y = floor(numArg(y, 2, "new")), Z = floor(numArg(z, 3, "new")) }, V3I)) end })
	local V2I = makeType("Vector2int16", {}, {})
	H.Vector2int16 = freeze({ new = function(x, y) return freeze(setmetatable({ X = floor(numArg(x, 1, "new")), Y = floor(numArg(y, 2, "new")) }, V2I)) end })
	local R3I = makeType("Region3int16", {}, {})
	H.Region3int16 = freeze({ new = function(a, b) return freeze(setmetatable({ Min = a, Max = b }, R3I)) end })
	local PWM = makeType("PathWaypoint", {}, {})
	H.PathWaypoint = freeze({ new = function(p, a, l) return freeze(setmetatable({ Position = p, Action = a, Label = l or "" }, PWM)) end })

	-- parse a default value string from the API dump into a datatype value ("" / unknown -> nil)
	function H.parseDefault(ty, s)
		if s == nil or s == "" then
			if ty == "string" or ty == "Content" then return s end
			return nil
		end
		local function nums()
			local t = {}
			for n in s:gmatch("[-%d%.eE+]+") do t[#t + 1] = tonumber(n) end
			return t
		end
		if ty == "number" or ty == "int" then return tonumber(s) end
		if ty == "boolean" then return s == "true" end
		if ty == "string" or ty == "Content" then return s end
		if ty == "Vector3" then local t = nums() return v3(t[1] or 0, t[2] or 0, t[3] or 0) end
		if ty == "Vector2" then local t = nums() return v2(t[1] or 0, t[2] or 0) end
		if ty == "CFrame" then local t = nums() if #t == 12 then return cf(table.unpack(t)) end return IDENT end
		if ty == "Color3" then local t = nums() return c3(t[1] or 0, t[2] or 0, t[3] or 0) end
		if ty == "UDim2" then local t = nums() return udim2(t[1] or 0, t[2] or 0, t[3] or 0, t[4] or 0) end
		if ty == "UDim" then local t = nums() return udim(t[1] or 0, t[2] or 0) end
		if ty == "NumberRange" then local t = nums() return nrange(t[1] or 0, t[2] or t[1] or 0) end
		if ty == "Rect" then local t = nums() return rect(t[1] or 0, t[2] or 0, t[3] or 0, t[4] or 0) end
		if ty == "NumberSequence" then
			local t, k = nums(), {}
			for i = 1, #t - 2, 3 do k[#k + 1] = nskp(t[i], t[i + 1], t[i + 2]) end
			if #k >= 2 then return nseq(k) end
			return nil
		end
		if ty == "ColorSequence" then
			local t, k = nums(), {}
			for i = 1, #t - 4, 5 do k[#k + 1] = cskp(t[i], c3(t[i + 1], t[i + 2], t[i + 3])) end
			if #k >= 2 then return cseq(k) end
			return nil
		end
		if ty:sub(1, 2) == "E:" then
			return H.enumItem(ty:sub(3), s)
		end
		return nil
	end
end
