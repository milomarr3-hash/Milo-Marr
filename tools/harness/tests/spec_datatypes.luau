-- MODE: script
-- EXPECT clean
-- Unit spec for the mock datatypes (run: python3 tools/harness/run_aura.py --script tools/harness/tests/spec_datatypes.luau).
-- Expected values follow Roblox's documented conventions (right-handed, +Y up, LookVector = -Z column,
-- CFrame.Angles = Rx * Ry * Rz, fromOrientation = Ry * Rx * Rz). Every failed check is an error in the report.
local rad, pi = math.rad, math.pi
local checks = 0
local function near(a, b, eps)
	eps = eps or 1e-6
	if typeof(a) == "number" then return math.abs(a - b) <= eps end
	if typeof(a) == "Vector3" then return (a - b).Magnitude <= eps end
	if typeof(a) == "CFrame" then return a:FuzzyEq(b, eps) end
	if typeof(a) == "Color3" then return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) <= eps end
	return a == b
end
local function check(cond, what)
	checks += 1
	if not cond then error("CHECK FAILED: " .. what, 2) end
end
local function eq(a, b, what, eps) check(near(a, b, eps), string.format("%s: got %s, expected %s", what, tostring(a), tostring(b))) end
local function throws(fn, substr, what)
	local ok, e = pcall(fn)
	check(not ok, what .. ": expected an error")
	check(string.find(tostring(e), substr, 1, true) ~= nil, string.format("%s: error '%s' should mention '%s'", what, tostring(e), substr))
end

-- Vector3 ----------------------------------------------------------------------------------------------------------
local a, b = Vector3.new(1, 2, 3), Vector3.new(4, 5, 6)
eq(a + b, Vector3.new(5, 7, 9), "add")
eq(b - a, Vector3.new(3, 3, 3), "sub")
eq(a * 2, Vector3.new(2, 4, 6), "mul scalar")
eq(2 * a, Vector3.new(2, 4, 6), "scalar mul")
eq(a * b, Vector3.new(4, 10, 18), "componentwise mul")
eq(b / 2, Vector3.new(2, 2.5, 3), "div")
eq(-a, Vector3.new(-1, -2, -3), "unm")
eq(a:Dot(b), 32, "dot")
eq(Vector3.xAxis:Cross(Vector3.yAxis), Vector3.zAxis, "cross x*y = z")
eq(Vector3.new(3, 4, 0).Magnitude, 5, "magnitude")
eq(Vector3.new(3, 4, 0).Unit, Vector3.new(0.6, 0.8, 0), "unit")
eq(a:Lerp(b, 0.5), Vector3.new(2.5, 3.5, 4.5), "lerp")
eq(a:Min(b, Vector3.new(0, 9, 9)), Vector3.new(0, 2, 3), "min")
eq(a:Max(b), b, "max")
eq(Vector3.xAxis:Angle(Vector3.yAxis), pi / 2, "angle")
check(a:FuzzyEq(Vector3.new(1, 2, 3 + 1e-7)), "fuzzyeq")
check(a == Vector3.new(1, 2, 3), "value equality")
check(typeof(a) == "Vector3", "typeof Vector3")
check(type(a) == "userdata", "type() of a Vector3 is userdata like Roblox")
check(a.x == 1 and a.magnitude == a.Magnitude, "deprecated lowercase members")
eq(Vector3.FromNormalId(Enum.NormalId.Front), Vector3.new(0, 0, -1), "FromNormalId Front")
throws(function() return a + 1 end, "Vector3 expected", "Vector3 + number")
throws(function() return a.W end, "W is not a valid member of Vector3", "unknown member")
throws(function() a.X = 5 end, "readonly", "Vector3 is immutable")
throws(function() return Vector3.new({}) end, "number expected", "bad constructor arg")
check(tostring(Vector3.new(1, 2.5, -3)) == "1, 2.5, -3", "tostring Vector3: " .. tostring(Vector3.new(1, 2.5, -3)))

-- CFrame -------------------------------------------------------------------------------------------------------------
local I = CFrame.identity
eq(I.LookVector, Vector3.new(0, 0, -1), "identity look")
eq(CFrame.Angles(0, rad(90), 0).LookVector, Vector3.new(-1, 0, 0), "yaw +90 looks -X")
eq(CFrame.Angles(rad(90), 0, 0).LookVector, Vector3.new(0, 1, 0), "pitch +90 looks up")
eq(CFrame.Angles(0, 0, rad(90)).RightVector, Vector3.new(0, 1, 0), "roll +90 right goes up")
local c = CFrame.new(1, 2, 3) * CFrame.Angles(0.3, -0.7, 1.1)
local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = c:GetComponents()
eq(x, 1, "components x") eq(z, 3, "components z")
eq(Vector3.new(r00, r10, r20), c.RightVector, "column 0 = RightVector")
eq(Vector3.new(-r02, -r12, -r22), c.LookVector, "LookVector = -Z column")
eq(c.ZVector, -c.LookVector, "ZVector")
-- Angles == Rx * Ry * Rz
eq(CFrame.Angles(0.3, -0.7, 1.1), CFrame.Angles(0.3, 0, 0) * CFrame.Angles(0, -0.7, 0) * CFrame.Angles(0, 0, 1.1), "Angles order XYZ")
eq(CFrame.fromOrientation(0.3, -0.7, 1.1), CFrame.Angles(0, -0.7, 0) * CFrame.Angles(0.3, 0, 0) * CFrame.Angles(0, 0, 1.1), "fromOrientation order YXZ")
eq(CFrame.fromEulerAnglesYXZ(0.3, -0.7, 1.1), CFrame.fromOrientation(0.3, -0.7, 1.1), "YXZ == orientation")
eq(CFrame.fromEulerAngles(0.3, -0.7, 1.1, Enum.RotationOrder.ZYX), CFrame.Angles(0, 0, 1.1) * CFrame.Angles(0, -0.7, 0) * CFrame.Angles(0.3, 0, 0), "fromEulerAngles ZYX")
do
	local rx, ry, rz = CFrame.Angles(0.3, -0.7, 1.1):ToEulerAnglesXYZ()
	eq(rx, 0.3, "ToEulerAnglesXYZ x") eq(ry, -0.7, "ToEulerAnglesXYZ y") eq(rz, 1.1, "ToEulerAnglesXYZ z")
	local ox, oy, oz = CFrame.fromOrientation(0.3, -0.7, 1.1):ToOrientation()
	eq(ox, 0.3, "ToOrientation x") eq(oy, -0.7, "ToOrientation y") eq(oz, 1.1, "ToOrientation z")
	for _, order in ipairs(Enum.RotationOrder:GetEnumItems()) do
		local q = CFrame.fromEulerAngles(0.2, 0.4, -0.5, order)
		local e1, e2, e3 = q:ToEulerAngles(order)
		eq(CFrame.fromEulerAngles(e1, e2, e3, order), q, "ToEulerAngles round trip " .. order.Name, 1e-5)
	end
end
eq(CFrame.fromAxisAngle(Vector3.yAxis, 0.8), CFrame.Angles(0, 0.8, 0), "fromAxisAngle Y")
do
	local axis, ang = CFrame.fromAxisAngle(Vector3.new(1, 2, 3).Unit, 1.2):ToAxisAngle()
	eq(axis, Vector3.new(1, 2, 3).Unit, "ToAxisAngle axis", 1e-5) eq(ang, 1.2, "ToAxisAngle angle", 1e-5)
end
eq(c * c:Inverse(), I, "c * c^-1 = I", 1e-6)
local d = CFrame.new(-4, 1, 9) * CFrame.Angles(1, 0.2, -0.4)
eq(c:ToObjectSpace(d), c:Inverse() * d, "ToObjectSpace")
eq(c * c:ToObjectSpace(d), d, "ToWorldSpace(ToObjectSpace)")
eq(c:ToWorldSpace(d), c * d, "ToWorldSpace")
local p = Vector3.new(3, -2, 7)
eq(c:PointToObjectSpace(c:PointToWorldSpace(p)), p, "point round trip")
eq(c:PointToWorldSpace(p), c * p, "PointToWorldSpace = c * v")
eq(c:VectorToWorldSpace(p), c.Rotation * p, "VectorToWorldSpace ignores position")
eq(c:VectorToObjectSpace(c:VectorToWorldSpace(p)), p, "vector round trip")
eq((c + Vector3.new(1, 1, 1)).Position, c.Position + Vector3.new(1, 1, 1), "CFrame + Vector3")
eq((c - Vector3.new(1, 1, 1)).Position, c.Position - Vector3.new(1, 1, 1), "CFrame - Vector3")
do
	local look = CFrame.lookAt(Vector3.zero, Vector3.new(10, 0, 0))
	eq(look.LookVector, Vector3.xAxis, "lookAt +X") eq(look.RightVector, Vector3.zAxis, "lookAt +X right = +Z")
	eq(CFrame.new(Vector3.zero, Vector3.new(10, 0, 0)), look, "CFrame.new(pos, lookAt)")
	eq(CFrame.lookAlong(Vector3.new(1, 2, 3), Vector3.new(0, 0, 5)).LookVector, Vector3.zAxis, "lookAlong")
	check(CFrame.lookAt(Vector3.zero, Vector3.new(0, 10, 0)).LookVector:FuzzyEq(Vector3.yAxis), "lookAt straight up is still valid")
end
eq(CFrame.new(0, 0, 0, 0, math.sin(pi / 4), 0, math.cos(pi / 4)), CFrame.Angles(0, pi / 2, 0), "quaternion constructor")
eq(CFrame.fromMatrix(Vector3.zero, Vector3.zAxis, Vector3.yAxis), CFrame.Angles(0, -pi / 2, 0), "fromMatrix derives Z = X x Y")
do
	local a0 = CFrame.new(0, 0, 0)
	local a1 = CFrame.new(10, 0, 0) * CFrame.Angles(0, pi / 2, 0)
	local m = a0:Lerp(a1, 0.5)
	eq(m.Position, Vector3.new(5, 0, 0), "lerp position")
	eq(m.Rotation, CFrame.Angles(0, pi / 4, 0), "lerp rotation slerps", 1e-6)
	eq(a0:Lerp(a1, 0), a0, "lerp 0") eq(a0:Lerp(a1, 1), a1, "lerp 1", 1e-6)
end
throws(function() return c * 2 end, "CFrame or Vector3 expected", "CFrame * number")
throws(function() return c.Foo end, "Foo is not a valid member of CFrame", "CFrame unknown member")
check(typeof(c) == "CFrame", "typeof CFrame")

-- Color3 -------------------------------------------------------------------------------------------------------------
local col = Color3.fromRGB(255, 128, 0)
eq(col.G, 128 / 255, "fromRGB")
eq(Color3.fromHex("#FF8000"), col, "fromHex")
check(col:ToHex() == "FF8000", "ToHex " .. col:ToHex())
do
	local h, s, v = Color3.fromHSV(0.6, 0.5, 0.8):ToHSV()
	eq(h, 0.6, "hsv h", 1e-6) eq(s, 0.5, "hsv s", 1e-6) eq(v, 0.8, "hsv v", 1e-6)
end
eq(Color3.new(0, 0, 0):Lerp(Color3.new(1, 1, 1), 0.25), Color3.new(0.25, 0.25, 0.25), "color lerp")

-- sequences / ranges ------------------------------------------------------------------------------------------------
local ns = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2, 0.1), NumberSequenceKeypoint.new(1, 1) })
check(#ns.Keypoints == 3 and ns.Keypoints[2].Envelope == 0.1, "NumberSequence keypoints")
check(NumberSequence.new(0.5).Keypoints[2].Value == 0.5, "NumberSequence.new(n)")
throws(function() NumberSequence.new({ NumberSequenceKeypoint.new(0, 1) }) end, "at least 2 keypoints", "1 keypoint")
throws(function() NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.9, 1) }) end, "end at 1", "last time 0.9")
throws(function() NumberSequence.new({ NumberSequenceKeypoint.new(0.1, 1), NumberSequenceKeypoint.new(1, 1) }) end, "start at 0", "first time 0.1")
throws(function()
	NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 1), NumberSequenceKeypoint.new(0.4, 1), NumberSequenceKeypoint.new(1, 1) })
end, "ordered by time", "unordered")
do
	local many = {}
	for i = 0, 20 do many[#many + 1] = NumberSequenceKeypoint.new(i / 20, 0) end
	throws(function() NumberSequence.new(many) end, "too long", "21 keypoints")
end
throws(function() NumberSequenceKeypoint.new(0, 1, -1) end, "envelope", "negative envelope")
local cs = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0, 0, 0))
check(cs.Keypoints[2].Value == Color3.new(0, 0, 0), "ColorSequence two colours")
throws(function() ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new()) }) end, "at least 2 keypoints", "ColorSequence 1 keypoint")
check(NumberRange.new(2).Max == 2, "NumberRange single")
throws(function() NumberRange.new(5, 1) end, "invalid range", "NumberRange min > max")

-- UDim2 / Vector2 / Rect / TweenInfo / Random ----------------------------------------------------------------------
local u = UDim2.new(0.5, 10, 1, -5)
check(u.X.Scale == 0.5 and u.X.Offset == 10 and u.Height.Offset == -5, "UDim2 fields")
check(UDim2.fromScale(1, 1) == UDim2.new(1, 0, 1, 0), "fromScale")
check(UDim2.fromOffset(4, 6) + UDim2.fromScale(1, 0) == UDim2.new(1, 4, 0, 6), "UDim2 add")
eq(Vector2.new(3, 4).Magnitude, 5, "Vector2 magnitude")
check(Rect.new(0, 0, 10, 5).Width == 10, "Rect width")
local ti = TweenInfo.new(2, Enum.EasingStyle.Sine)
check(ti.EasingDirection == Enum.EasingDirection.Out and ti.Time == 2, "TweenInfo defaults")
local r1, r2 = Random.new(42), Random.new(42)
check(r1:NextNumber() == r2:NextNumber(), "Random is deterministic per seed")
for _ = 1, 50 do
	local n = r1:NextInteger(3, 5)
	check(n >= 3 and n <= 5, "NextInteger range")
end
throws(function() r1:NextInteger(5, 3) end, "interval is empty", "NextInteger empty")

-- Enum -------------------------------------------------------------------------------------------------------------
check(Enum.PartType.Ball.Value == 0 and Enum.PartType.Block.Value == 1, "enum values from the API dump")
check(tostring(Enum.Material.Neon) == "Enum.Material.Neon", "enum tostring")
check(Enum.Material.Neon:IsA("Material"), "EnumItem:IsA")
check(Enum.PartType:FromName("Cylinder") == Enum.PartType.Cylinder, "FromName")
check(typeof(Enum.PartType.Ball) == "EnumItem" and typeof(Enum.PartType) == "Enum" and typeof(Enum) == "Enums", "enum typeof")
throws(function() return Enum.PartType.Sphere end, "Sphere is not a valid member", "unknown enum item")
throws(function() return Enum.NotAnEnum end, "NotAnEnum is not a valid member", "unknown enum")

print(string.format("spec_datatypes: %d checks passed", checks))
