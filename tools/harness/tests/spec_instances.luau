-- MODE: script
-- EXPECT error: HttpService request attempted
-- EXPECT only-listed
-- Unit spec for the mock Instance model and services (run with --script). Every failed check is an error in the report.
local checks = 0
local function check(cond, what)
	checks += 1
	if not cond then error("CHECK FAILED: " .. what, 2) end
end
local function throws(fn, substr, what)
	local ok, e = pcall(fn)
	check(not ok, what .. ": expected an error")
	check(string.find(tostring(e), substr, 1, true) ~= nil, string.format("%s: error '%s' should mention '%s'", what, tostring(e), substr))
end
local function near(a, b) return math.abs(a - b) < 1e-6 end

-- creation, class info, members
local part = Instance.new("Part")
check(part.ClassName == "Part" and part.Name == "Part", "new Part")
check(part:IsA("BasePart") and part:IsA("Instance") and not part:IsA("Model") and not part:IsA("NotAClass"), "IsA chain")
check(part.Size == Vector3.new(4, 1, 2), "Part default Size " .. tostring(part.Size))
check(part.Anchored == false and part.CanCollide == true and part.Transparency == 0, "BasePart defaults")
check(part.Shape == Enum.PartType.Block, "default Shape")
throws(function() Instance.new("NotAClass") end, 'Unable to create an Instance of type "NotAClass"', "unknown class")
throws(function() Instance.new("BasePart") end, 'Unable to create an Instance of type "BasePart"', "abstract class")
throws(function() Instance.new("Workspace") end, 'Unable to create an Instance of type "Workspace"', "service")
throws(function() part.Transparancy = 1 end, 'Transparancy is not a valid member of Part "Part"', "unknown property write")
throws(function() return part.Foo end, 'Foo is not a valid member of Part "Part"', "unknown property read")
throws(function() part.Size = 5 end, "Unable to assign property Size. Vector3 expected, got number", "wrong type")
throws(function() part.Anchored = 1 end, "bool expected, got number", "bool strict")
throws(function() part.Material = Enum.PartType.Ball end, "PartType", "wrong enum type")
throws(function() part.Material = "Neonn" end, 'Invalid value "Neonn" for enum Material', "bad enum name")
part.Material = "Neon"
check(part.Material == Enum.Material.Neon, "enum by name")
part.Material = 256
check(part.Material == Enum.Material.Plastic, "enum by value")
part.Transparency = "0.5"
check(part.Transparency == 0.5, "numeric string coerces")
throws(function() part.ClassName = "X" end, "read only", "read-only ClassName")
throws(function() workspace.CurrentCamera.ViewportSize = Vector2.new(1, 1) end, "read only", "read-only ViewportSize")
local mp = Instance.new("MeshPart")
throws(function() mp.MeshId = "rbxassetid://1" end, "Script write access is restricted", "MeshPart.MeshId at runtime")
throws(function() part.Destroy() end, "Expected ':' not '.'", "method called with a dot")

-- CFrame-derived properties
part.CFrame = CFrame.new(1, 2, 3) * CFrame.Angles(0, math.rad(90), 0)
check(part.Position == Vector3.new(1, 2, 3), "Position from CFrame")
check(near(part.Orientation.Y, 90), "Orientation Y " .. tostring(part.Orientation))
part.Position = Vector3.new(5, 5, 5)
check(part.CFrame.LookVector:FuzzyEq(Vector3.new(-1, 0, 0)), "Position keeps rotation")
local ball = Instance.new("Part")
ball.Shape = Enum.PartType.Ball
ball.Size = Vector3.new(2, 4, 6)
check(ball.Size == Vector3.new(2, 2, 2), "Ball size is uniform: " .. tostring(ball.Size))

-- hierarchy
local folder = Instance.new("Folder")
folder.Name = "F"
part.Parent = folder
check(part.Parent == folder and folder:FindFirstChild("Part") == part and folder.Part == part, "parent + child lookup")
check(#folder:GetChildren() == 1 and folder:FindFirstChildOfClass("Part") == part and folder:FindFirstChildWhichIsA("BasePart") == part, "child queries")
local att = Instance.new("Attachment")
att.Position = Vector3.new(0, 1, 0)
att.Parent = part
check(#folder:GetDescendants() == 2, "descendants")
check(att.WorldPosition:FuzzyEq(part.CFrame * Vector3.new(0, 1, 0)), "Attachment.WorldPosition")
folder.Parent = workspace
check(part:GetFullName() == "Workspace.F.Part", "GetFullName " .. part:GetFullName())
check(part:IsDescendantOf(workspace) and workspace:IsAncestorOf(att), "IsDescendantOf / IsAncestorOf")
throws(function() folder.Parent = part end, "circular reference", "circular parent")
local seen = {}
folder.ChildAdded:Connect(function(c) seen[#seen + 1] = c.Name end)
local extra = Instance.new("Part")
extra.Name = "Extra"
extra.Parent = folder
task.wait()
check(seen[1] == "Extra", "ChildAdded fired (deferred)")

-- deferred events wait for a resumption point: not even a task.spawn'ed thread finishing runs them early
do
	local f2 = Instance.new("Folder")
	f2.Parent = workspace
	local fired = false
	f2.ChildAdded:Connect(function() fired = true end)
	Instance.new("Folder").Parent = f2
	task.spawn(function() end)
	check(fired == false, "deferred handler must not run in the middle of the script")
	task.wait()
	check(fired == true, "deferred handler ran at the resumption point")
end

-- clone remaps references inside the cloned tree
local m = Instance.new("Model")
local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
local p0 = Instance.new("Part")
a0.Parent, a1.Parent, p0.Parent = p0, p0, m
local beam = Instance.new("Beam")
beam.Attachment0, beam.Attachment1 = a0, a1
beam.Parent = p0
throws(function() beam.Attachment0 = p0 end, "Attachment expected, got Part", "instance ref class check")
local m2 = m:Clone()
local beam2 = m2:FindFirstChild("Beam", true)
check(beam2 and beam2.Attachment0 ~= a0 and beam2.Attachment0:IsDescendantOf(m2), "clone remaps refs")
p0.Archivable = false
check(m:Clone():FindFirstChild("Part") == nil, "Archivable false is not cloned")

-- destroy locks the parent and disconnects
local conn = extra.Changed:Connect(function() end)
extra:Destroy()
check(extra.Parent == nil and not conn.Connected, "destroy: parent nil, connections dropped")
throws(function() extra.Parent = workspace end, "The Parent property of Extra is locked", "parent locked after Destroy")
extra:Destroy() -- (destroying twice is allowed)

-- attributes
part:SetAttribute("Speed", 3)
check(part:GetAttribute("Speed") == 3 and part:GetAttributes().Speed == 3, "attributes")
throws(function() part:SetAttribute("Bad Name", 1) end, "invalid characters", "attribute name")
throws(function() part:SetAttribute("Ref", part) end, "not a supported attribute type", "attribute type")

-- WaitForChild with and without a timeout
check(folder:WaitForChild("Part") == part, "WaitForChild existing")
check(folder:WaitForChild("Nope", 0.5) == nil, "WaitForChild timeout returns nil")
task.delay(0.2, function()
	local late = Instance.new("Folder")
	late.Name = "Late"
	late.Parent = folder
end)
check(folder:WaitForChild("Late").Name == "Late", "WaitForChild resumes when the child arrives")

-- virtual time and the task library
local t0 = os.clock()
local waited = task.wait(0.5)
check(near(os.clock() - t0, waited) and waited >= 0.5 and waited < 0.55, "task.wait advances virtual time: " .. waited)
local order = {}
task.delay(0.1, function() order[#order + 1] = "delay" end)
task.defer(function() order[#order + 1] = "defer" end)
task.spawn(function() order[#order + 1] = "spawn" end)
task.wait(0.2)
check(table.concat(order, ",") == "spawn,defer,delay", "task ordering: " .. table.concat(order, ","))
check(time() > 100 and tick() > 1.7e9, "time() and tick() are virtual")

-- tweens interpolate over virtual time
local tp = Instance.new("Part")
tp.Transparency = 0
local tw = game:GetService("TweenService"):Create(tp, TweenInfo.new(1, Enum.EasingStyle.Linear), { Transparency = 1 })
local done = false
tw.Completed:Connect(function(state) done = state == Enum.PlaybackState.Completed end)
tw:Play()
task.wait(0.5)
check(tp.Transparency > 0.4 and tp.Transparency < 0.6, "tween halfway: " .. tp.Transparency)
task.wait(0.6)
check(tp.Transparency == 1 and done, "tween completes and fires Completed")
throws(function() game:GetService("TweenService"):Create(beam, TweenInfo.new(1), { Transparency = NumberSequence.new(1) }) end,
	"not a data type that can be tweened", "NumberSequence is not tweenable")
throws(function() game:GetService("TweenService"):Create(tp, TweenInfo.new(1), { Transparancy = 1 }) end, "no property named", "tween unknown prop")

-- services
check(game:GetService("Workspace") == workspace and game:GetService("RunService"):IsClient(), "services")
throws(function() game:GetService("NotAService") end, "is not a valid Service name", "bad service")
local hrp = game:GetService("Players").LocalPlayer.Character.HumanoidRootPart
check(hrp.Size == Vector3.new(2, 2, 1) and hrp.Parent:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15, "R15 character")
check(hrp.Parent:FindFirstChild("RightHand"):FindFirstChild("RightGripAttachment") ~= nil, "grip attachment")
local params = RaycastParams.new()
params.FilterDescendantsInstances = { hrp.Parent }
local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -20, 0), params)
check(hit and near(hit.Position.Y, 0) and hit.Instance.Name == "Plaza", "raycast hits the plaza")
check(workspace:Raycast(Vector3.new(0, 100, 0), Vector3.new(0, -50, 0)) == nil, "raycast too short misses")
throws(function() workspace:BulkMoveTo({ part }, {}) end, "same number of elements", "BulkMoveTo mismatch")
throws(function() workspace:BulkMoveTo({ folder }, { CFrame.new() }) end, "is not a BasePart", "BulkMoveTo non-part")
throws(function() game:GetService("HttpService"):GetAsync("http://example.com") end, "Http requests are not enabled", "HTTP is off")
check(game:GetService("HttpService"):JSONDecode('{"a":[1,2,{"b":true}]}').a[3].b == true, "JSONDecode")
local film = game:GetService("ReplicatedStorage"):FindFirstChild("AuraCinema")
check(film and film.Assets.TheEnd.RingG:IsA("MeshPart") and film.Assets.TheEnd.Oblivion.Moon.Size.X > 9, "fake film meshes")

print(string.format("spec_instances: %d checks passed", checks))
